<script lang="ts">
	import { browser } from '$app/environment';
	import { beforeNavigate, goto, invalidateAll } from '$app/navigation';
	import type { RealtimeChannel } from '@supabase/supabase-js';
	import { onDestroy, onMount } from 'svelte';
	import { get } from 'svelte/store';
	import type { PageData } from './$types';
	import type { Tables } from '$lib/types/database.types';
	import Tabs from '$lib/components/ui/tabs.svelte';
	import DatosObraTab from '$lib/components/editor/DatosObraTab.svelte';
	import EstructuraTab from '$lib/components/editor/EstructuraTab.svelte';
	import SecuenciasTab from '$lib/components/editor/SecuenciasTab.svelte';
	import AutoriaTab from '$lib/components/editor/AutoriaTab.svelte';
	import AnalisisTab from '$lib/components/editor/AnalisisTab.svelte';
	import RevisionTab from '$lib/components/editor/RevisionTab.svelte';
	import { getSupabaseBrowserClient } from '$lib/services/supabase';
	import {
		currentObraStore,
		setConflict,
		setCurrentObra,
		setDirty,
		setSaving,
		type ObraDirtyScope
	} from '$lib/stores/currentObra';
	import { pushToast } from '$lib/stores/toast';

	let { data } = $props<{ data: PageData }>();

	let currentTab = $state('datos');
	const tabs = [
		{ id: 'datos', label: 'Datos de la obra' },
		{ id: 'estructura', label: 'Estructura' },
		{ id: 'secuencias', label: 'Secuencias' },
		{ id: 'autoria', label: 'Autoria' },
		{ id: 'analisis', label: 'Analisis' },
		{ id: 'revision', label: 'Revision' }
	];

	const vocabByCategory = $derived.by(() => {
		const grouped = new Map<string, Tables<'vocabularios'>[]>();
		for (const term of data.vocabularios as Tables<'vocabularios'>[]) {
			const existing = grouped.get(term.categoria) ?? [];
			existing.push(term as Tables<'vocabularios'>);
			grouped.set(term.categoria, existing);
		}
		grouped.forEach((items) =>
			items.sort(
				(a: Pick<Tables<'vocabularios'>, 'orden'>, b: Pick<Tables<'vocabularios'>, 'orden'>) =>
					(a.orden ?? 999) - (b.orden ?? 999)
			)
		);
		return grouped;
	});

	const generoOptions = $derived(vocabByCategory.get('genero') ?? []);
	const estadoOptions = $derived(vocabByCategory.get('estado') ?? []);
	const certezaOptions = $derived(vocabByCategory.get('certeza_editor') ?? []);
	const estadoRevisionOptions = $derived(vocabByCategory.get('estado_revision') ?? []);
	const estrofaOptions = $derived(vocabByCategory.get('estrofa_tipo') ?? []);
	const metroOptions = $derived(vocabByCategory.get('metro') ?? []);
	const obraLive = $derived(($currentObraStore.obra ?? data.obra) as Tables<'obras'>);
	const canEditContent = $derived(Boolean(data.capabilities?.canEditContent));
	const canComment = $derived(Boolean(data.capabilities?.canComment));
	let jornadasLive = $state<Tables<'jornadas'>[]>([]);
	let cuadrosLive = $state<Tables<'cuadros'>[]>([]);

	let channel: RealtimeChannel | null = null;
	const UNSAVED_CHANGES_MESSAGE = 'Hay cambios sin guardar en esta pestana.';
	let showUnsavedChangesModal = $state(false);
	let pendingTabChange: string | null = null;
	let pendingRouteChange: string | null = null;
	let bypassUnsavedGuard = false;
	const jornadaIds = $derived(
		new Set((jornadasLive as Tables<'jornadas'>[]).map((jornada) => jornada.jornada_id))
	);
	const rangoIds = $derived(new Set((data.rangos as Tables<'rangos'>[]).map((rango) => rango.rango_id)));

	function getCurrentDirtyScope(): ObraDirtyScope | null {
		if (currentTab === 'datos' || currentTab === 'autoria' || currentTab === 'analisis') {
			return currentTab;
		}
		return null;
	}

	function hasPendingChanges() {
		const scope = getCurrentDirtyScope();
		if (!scope) return false;
		const state = get(currentObraStore);
		const dirtyByScope = state.dirtyByScope[scope];
		const savingByScope = state.savingByScope[scope];
		return Boolean(dirtyByScope) && !Boolean(savingByScope);
	}

	function openUnsavedChangesModal({
		tabChange = null,
		routeChange = null
	}: {
		tabChange?: string | null;
		routeChange?: string | null;
	}) {
		pendingTabChange = tabChange;
		pendingRouteChange = routeChange;
		showUnsavedChangesModal = true;
	}

	function handleTabChange(nextTab: string) {
		if (nextTab === currentTab) return;
		if (hasPendingChanges()) {
			openUnsavedChangesModal({ tabChange: nextTab });
			return;
		}
		currentTab = nextTab;
	}

	function cancelUnsavedChangesModal() {
		showUnsavedChangesModal = false;
		pendingTabChange = null;
		pendingRouteChange = null;
	}

	async function confirmUnsavedChangesModal() {
		const currentScope = getCurrentDirtyScope();
		if (currentScope) {
			setDirty(false, currentScope);
			setSaving(false, currentScope);
		}

		const nextTab = pendingTabChange;
		const nextRoute = pendingRouteChange;
		cancelUnsavedChangesModal();

		if (nextTab) {
			currentTab = nextTab;
			return;
		}
		if (!nextRoute) return;

		bypassUnsavedGuard = true;
		try {
			await goto(nextRoute);
		} finally {
			bypassUnsavedGuard = false;
		}
	}

	function onExternalChange(payload: { table: string; jornada_id?: string | null; rango_id?: string | null }) {
		const dirty = get(currentObraStore).dirty;
		if (payload.table === 'cuadros' && payload.jornada_id && !jornadaIds.has(payload.jornada_id)) {
			return;
		}
		if (payload.table === 'rangos_autores' && payload.rango_id && !rangoIds.has(payload.rango_id)) {
			return;
		}
		if (dirty) {
			setConflict(true);
			pushToast('info', 'Otro editor guardo cambios; tu proximo guardado sobrescribira.');
			return;
		}
		void invalidateAll();
	}

	function handleStructureChange(payload: {
		jornadas: Tables<'jornadas'>[];
		cuadros: Tables<'cuadros'>[];
	}) {
		jornadasLive = [...payload.jornadas];
		cuadrosLive = [...payload.cuadros];
	}

	beforeNavigate((navigation) => {
		if (!browser) return;
		if (bypassUnsavedGuard) return;
		if (!navigation.to) return;
		if (!hasPendingChanges()) return;
		const sameDestination =
			navigation.to.url.pathname === window.location.pathname &&
			navigation.to.url.search === window.location.search &&
			navigation.to.url.hash === window.location.hash;
		if (sameDestination) return;
		navigation.cancel();
		const route = `${navigation.to.url.pathname}${navigation.to.url.search}${navigation.to.url.hash}`;
		openUnsavedChangesModal({ routeChange: route });
	});

	onMount(() => {
		if (!browser) return;
		const handleBeforeUnload = (event: BeforeUnloadEvent) => {
			if (!hasPendingChanges()) return;
			event.preventDefault();
			event.returnValue = '';
		};
		window.addEventListener('beforeunload', handleBeforeUnload);

		const supabase = getSupabaseBrowserClient();
		channel = supabase
			.channel(`obra-${data.obra.obra_id}`)
			.on(
				'postgres_changes',
				{
					event: '*',
					schema: 'public',
					table: 'obras',
					filter: `obra_id=eq.${data.obra.obra_id}`
				},
				() => onExternalChange({ table: 'obras' })
			)
			.on(
				'postgres_changes',
				{
					event: '*',
					schema: 'public',
					table: 'jornadas',
					filter: `obra_id=eq.${data.obra.obra_id}`
				},
				() => onExternalChange({ table: 'jornadas' })
			)
			.on(
				'postgres_changes',
				{
					event: '*',
					schema: 'public',
					table: 'rangos',
					filter: `obra_id=eq.${data.obra.obra_id}`
				},
				() => onExternalChange({ table: 'rangos' })
			)
			.on(
				'postgres_changes',
				{
					event: '*',
					schema: 'public',
					table: 'secuencias_metricas',
					filter: `obra_id=eq.${data.obra.obra_id}`
				},
				() => onExternalChange({ table: 'secuencias_metricas' })
			)
			.on(
				'postgres_changes',
				{
					event: '*',
					schema: 'public',
					table: 'comentarios_internos',
					filter: `obra_id=eq.${data.obra.obra_id}`
				},
				() => onExternalChange({ table: 'comentarios_internos' })
			)
			.on(
				'postgres_changes',
				{
					event: '*',
					schema: 'public',
					table: 'cuadros'
				},
				(payload) =>
					onExternalChange({
						table: 'cuadros',
						jornada_id:
							(payload.new as { jornada_id?: string } | null)?.jornada_id ??
							(payload.old as { jornada_id?: string } | null)?.jornada_id ??
							null
					})
			)
			.on(
				'postgres_changes',
				{
					event: '*',
					schema: 'public',
					table: 'rangos_autores'
				},
				(payload) =>
					onExternalChange({
						table: 'rangos_autores',
						rango_id:
							(payload.new as { rango_id?: string } | null)?.rango_id ??
							(payload.old as { rango_id?: string } | null)?.rango_id ??
							null
					})
			)
			.subscribe();

		return () => {
			window.removeEventListener('beforeunload', handleBeforeUnload);
		};
	});

	$effect(() => {
		setCurrentObra(data.obra);
	});

	$effect(() => {
		jornadasLive = [...data.jornadas];
		cuadrosLive = [...data.cuadros];
	});

	onDestroy(() => {
		if (!channel) return;
		const supabase = getSupabaseBrowserClient();
		void supabase.removeChannel(channel);
		channel = null;
	});
</script>

<section>
	<div class="mb-4">
		<h1 class="text-3xl font-semibold">{obraLive.titulo}</h1>
		<p class="text-sm text-[color:var(--muted-foreground)]">
			Estado actual: {data.estadoTerm}. ID obra: {obraLive.obra_id}
		</p>
	</div>

	{#if !canEditContent}
		<div class="mb-4 rounded-md border border-[color:var(--border)] bg-[#fff8eb] px-3 py-2 text-sm">
			{#if canComment}
				Modo revision: contenido en solo lectura. Puedes comentar desde la pestana Revision.
			{:else}
				Modo solo lectura: no tienes permisos de edicion ni revision en esta obra.
			{/if}
		</div>
	{/if}

	{#if $currentObraStore.conflict}
		<div class="mb-4 rounded-md border border-amber-300 bg-amber-50 px-3 py-2 text-sm text-amber-900">
			Se detectaron cambios externos en esta obra.
		</div>
	{/if}

	<div class="mb-4">
		<Tabs tabs={tabs} active={currentTab} onChange={handleTabChange} />
	</div>

	{#if currentTab === 'datos'}
		<DatosObraTab obra={obraLive} generoOptions={generoOptions} readOnly={!canEditContent} />
	{:else if currentTab === 'estructura'}
		<EstructuraTab
			obraId={obraLive.obra_id}
			jornadasInitial={jornadasLive}
			cuadrosInitial={cuadrosLive}
			certezaOptions={certezaOptions}
			readOnly={!canEditContent}
			canComment={canComment}
			onStructureChange={handleStructureChange}
		/>
	{:else if currentTab === 'secuencias'}
		<SecuenciasTab
			obraId={obraLive.obra_id}
			secuenciasInitial={data.secuencias}
			secuenciasMetrosInitial={data.secuenciasMetros}
			estrofaOptions={estrofaOptions}
			metroOptions={metroOptions}
			estadoRevisionOptions={estadoRevisionOptions}
			certezaOptions={certezaOptions}
			readOnly={!canEditContent}
			canComment={canComment}
		/>
	{:else if currentTab === 'autoria'}
		<AutoriaTab
			obraId={obraLive.obra_id}
			obra={obraLive}
			readOnly={!canEditContent}
		/>
	{:else if currentTab === 'analisis'}
		<AnalisisTab
			obraId={obraLive.obra_id}
			analisisInitial={obraLive.analisis_editor ?? ''}
			bibliografiaInitial={obraLive.bibliografia ?? ''}
			readOnly={!canEditContent}
		/>
	{:else}
		<RevisionTab
			obraId={obraLive.obra_id}
			obra={obraLive}
			profile={data.profile}
			estadoTerm={data.estadoTerm}
			estadoOptions={estadoOptions}
			estadoRevisionOptions={estadoRevisionOptions}
			jornadas={jornadasLive}
			cuadros={cuadrosLive}
			secuencias={data.secuencias}
			rangos={data.rangos}
			editorAsignadoNombre={data.editorAsignadoNombre}
			assignedReviewer={data.assignedReviewer}
			capabilities={data.capabilities}
		/>
	{/if}
</section>

{#if showUnsavedChangesModal}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
		<div class="card w-full max-w-md p-5">
			<h3 class="text-lg font-semibold">Cambios sin guardar</h3>
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">{UNSAVED_CHANGES_MESSAGE}</p>
			<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
				Si continuas, perderas los cambios no guardados.
			</p>
			<div class="mt-4 flex justify-end gap-2">
				<button
					type="button"
					class="rounded-md border border-[color:var(--border)] px-3 py-2 text-sm"
					onclick={cancelUnsavedChangesModal}
				>
					Seguir editando
				</button>
				<button
					type="button"
					class="rounded-md bg-[color:var(--danger)] px-3 py-2 text-sm text-[color:var(--danger-foreground)]"
					onclick={() => void confirmUnsavedChangesModal()}
				>
					Salir sin guardar
				</button>
			</div>
		</div>
	</div>
{/if}
