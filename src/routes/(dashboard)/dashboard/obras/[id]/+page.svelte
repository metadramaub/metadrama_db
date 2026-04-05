<script lang="ts">
	import { browser } from '$app/environment';
	import { beforeNavigate, goto, invalidateAll } from '$app/navigation';
	import type { RealtimeChannel } from '@supabase/supabase-js';
	import { onDestroy, onMount, tick } from 'svelte';
	import { get } from 'svelte/store';
	import { page } from '$app/stores';
	import type { PageData } from './$types';
	import type { Tables } from '$lib/types/database.types';
	import Tabs from '$lib/components/ui/tabs.svelte';
	import DatosObraTab from '$lib/components/editor/DatosObraTab.svelte';
	import EstructuraTab from '$lib/components/editor/EstructuraTab.svelte';
	import SecuenciasTab from '$lib/components/editor/SecuenciasTab.svelte';
	import AutoriaTab from '$lib/components/editor/AutoriaTab.svelte';
	import ObservacionesTab from '$lib/components/editor/ObservacionesTab.svelte';
	import RevisionTab from '$lib/components/editor/RevisionTab.svelte';
	import InternalCommentsPanel from '$lib/components/editor/InternalCommentsPanel.svelte';
	import { getSupabaseBrowserClient } from '$lib/services/supabase';
	import {
		currentObraStore,
		setConflict,
		setCurrentObra,
		setDirty,
		setSaving,
		type ObraDirtyScope
	} from '$lib/stores/currentObra';
	import { runInternalSceneTransition } from '$lib/stores/scene-loader';
	import { pushToast } from '$lib/stores/toast';

	let { data } = $props<{ data: PageData }>();

	const TAB_IDS = ['datos', 'estructura', 'secuencias', 'autoria', 'observaciones', 'revision'] as const;
	type TabId = (typeof TAB_IDS)[number];
	const validTabs = new Set<string>(TAB_IDS);

	function resolveTab(rawValue: string | null | undefined): TabId {
		if (!rawValue) return 'datos';
		const normalized = rawValue.trim().toLowerCase();
		return validTabs.has(normalized) ? (normalized as TabId) : 'datos';
	}

	function syncTabInUrl(tab: TabId) {
		if (!browser) return;
		const url = new URL(window.location.href);
		url.searchParams.set('tab', tab);
		window.history.replaceState(window.history.state, '', url.toString());
	}

	let currentTab = $state<TabId>(resolveTab(get(page).url.searchParams.get('tab')));
	const tabs = [
		{ id: 'datos', label: 'Datos de la obra' },
		{ id: 'estructura', label: 'Estructura' },
		{ id: 'secuencias', label: 'Secuencias' },
		{ id: 'autoria', label: 'Autoría' },
		{ id: 'observaciones', label: 'Observaciones' },
		{ id: 'revision', label: 'Revisión' }
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
	const estrofaOptions = $derived(vocabByCategory.get('estrofa_tipo') ?? []);
	const caracterizacionRangoOptions = $derived(vocabByCategory.get('caracterizacion_rango') ?? []);
	const obraLive = $derived.by(() => {
		const storeObra = $currentObraStore.obra as Tables<'obras'> | null;
		if (storeObra && storeObra.obra_id === data.obra.obra_id) {
			return storeObra;
		}
		return data.obra as Tables<'obras'>;
	});
	const canEditContent = $derived(Boolean(data.capabilities?.canEditContent));
	const canComment = $derived(Boolean(data.capabilities?.canComment));
	let jornadasLive = $state<Tables<'jornadas'>[]>([]);
	let cuadrosLive = $state<Tables<'cuadros'>[]>([]);
	let secuenciasLive = $state<Tables<'secuencias_metricas'>[]>([]);

	let channel: RealtimeChannel | null = null;
	const UNSAVED_CHANGES_MESSAGE = 'Hay cambios sin guardar en esta pestaña.';
	let showUnsavedChangesModal = $state(false);
	let pendingTabChange: string | null = null;
	let pendingRouteChange: string | null = null;
	let bypassUnsavedGuard = false;
	let revisionHasPendingChanges = $state(false);
	const jornadaIds = $derived(
		new Set((jornadasLive as Tables<'jornadas'>[]).map((jornada) => jornada.jornada_id))
	);

	function getCurrentDirtyScope(): ObraDirtyScope | null {
		if (currentTab === 'datos' || currentTab === 'autoria' || currentTab === 'observaciones') {
			return currentTab;
		}
		return null;
	}

	function hasPendingChanges() {
		if (currentTab === 'revision') {
			return revisionHasPendingChanges;
		}
		const scope = getCurrentDirtyScope();
		if (!scope) return false;
		const state = get(currentObraStore);
		const dirtyByScope = state.dirtyByScope[scope];
		const savingByScope = state.savingByScope[scope];
		return Boolean(dirtyByScope) && !Boolean(savingByScope);
	}

	function handleRevisionPendingChangesChange(pending: boolean) {
		revisionHasPendingChanges = pending;
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
		void applyInternalTabChange(nextTab);
	}

	function cancelUnsavedChangesModal() {
		showUnsavedChangesModal = false;
		pendingTabChange = null;
		pendingRouteChange = null;
	}

	async function confirmUnsavedChangesModal() {
		if (currentTab === 'revision') {
			revisionHasPendingChanges = false;
		}
		const currentScope = getCurrentDirtyScope();
		if (currentScope) {
			setDirty(false, currentScope);
			setSaving(false, currentScope);
		}

		const nextTab = pendingTabChange;
		const nextRoute = pendingRouteChange;
		cancelUnsavedChangesModal();

		if (nextTab) {
			await applyInternalTabChange(nextTab);
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

	async function applyInternalTabChange(nextTab: string) {
		const resolved = resolveTab(nextTab);
		await runInternalSceneTransition(async () => {
			await tick();
			currentTab = resolved;
			syncTabInUrl(resolved);
			await tick();
		});
	}

	function onExternalChange(payload: { table: string; jornada_id?: string | null }) {
		const dirty = get(currentObraStore).dirty;
		if (payload.table === 'cuadros' && payload.jornada_id && !jornadaIds.has(payload.jornada_id)) {
			return;
		}
		if (dirty) {
			setConflict(true);
			pushToast('info', 'Otro editor guardó cambios; tu próximo guardado sobrescribirá.');
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

	function handleSecuenciasChange(payload: Tables<'secuencias_metricas'>[]) {
		secuenciasLive = [...payload];
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
					table: 'atribuciones'
				},
				(payload) => {
					const next = (payload.new as { obra_id?: string | null; jornada_id?: string | null } | null) ?? {};
					const prev = (payload.old as { obra_id?: string | null; jornada_id?: string | null } | null) ?? {};
					const obraId = next.obra_id ?? prev.obra_id ?? null;
					const jornadaId = next.jornada_id ?? prev.jornada_id ?? null;
					if (obraId === data.obra.obra_id || (jornadaId && jornadaIds.has(jornadaId))) {
						onExternalChange({ table: 'atribuciones' });
					}
				}
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
			.subscribe();

		return () => {
			window.removeEventListener('beforeunload', handleBeforeUnload);
		};
	});

	$effect(() => {
		setCurrentObra(data.obra);
	});

	$effect(() => {
		currentTab = resolveTab($page.url.searchParams.get('tab'));
	});

	$effect(() => {
		jornadasLive = [...data.jornadas];
		cuadrosLive = [...data.cuadros];
		secuenciasLive = [...data.secuencias];
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
		<div class="mt-2 flex flex-wrap items-center gap-2 text-sm text-[color:var(--muted-foreground)]">
			<span>Estado actual:</span>
			<span class="border border-[color:var(--border)] bg-[color:var(--muted)] px-2 py-1 text-xs">
				{data.estadoTerm}
			</span>
			<span class="text-xs">ID obra: {obraLive.obra_id}</span>
		</div>
	</div>

	{#if !canEditContent}
		<div class="mb-4 border border-[color:var(--border)] bg-[color:var(--gray-50)] px-3 py-2 text-sm">
			{#if canComment}
				Modo revisión: contenido en solo lectura. Puedes dejar comentarios internos en las pestañas que tengan panel de comentarios.
			{:else}
				Modo solo lectura: no tienes permisos de edición ni revisión en esta obra.
			{/if}
		</div>
	{/if}

	{#if $currentObraStore.conflict}
		<div class="mb-4 border border-amber-300 bg-amber-50 px-3 py-2 text-sm text-amber-900">
			Se detectaron cambios externos en esta obra.
		</div>
	{/if}

	<div class="mb-4">
		<Tabs tabs={tabs} active={currentTab} onChange={handleTabChange} />
	</div>

	{#if currentTab === 'datos'}
		<DatosObraTab
			obra={obraLive}
			generoOptions={generoOptions}
			readOnly={!canEditContent}
			canComment={canComment}
		/>
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
			secuenciasInitial={secuenciasLive}
			jornadasInitial={jornadasLive}
			cuadrosInitial={cuadrosLive}
			estrofaOptions={estrofaOptions}
			certezaOptions={certezaOptions}
			caracterizacionRangoOptions={caracterizacionRangoOptions}
			readOnly={!canEditContent}
			canComment={canComment}
			onSecuenciasChange={handleSecuenciasChange}
		/>
	{:else if currentTab === 'autoria'}
		<AutoriaTab
			obraId={obraLive.obra_id}
			obra={obraLive}
			roleTerm={data.profile.roleTerm}
			readOnly={!canEditContent}
			canComment={canComment}
		/>
	{:else if currentTab === 'observaciones'}
		<ObservacionesTab
			obraId={obraLive.obra_id}
			observacionesInitial={obraLive.observaciones ?? ''}
			bibliografiaInitial={obraLive.bibliografia ?? ''}
			readOnly={!canEditContent}
			canComment={canComment}
		/>
	{:else}
		<RevisionTab
			obraId={obraLive.obra_id}
			obra={obraLive}
			profile={data.profile}
			estadoTerm={data.estadoTerm}
			estadoOptions={estadoOptions}
			jornadas={jornadasLive}
			cuadros={cuadrosLive}
			secuencias={secuenciasLive}
			autoriaAdoptadaCount={data.autoriaAdoptadaCount}
			editorAsignadoNombre={data.editorAsignadoNombre}
			assignedReviewer={data.assignedReviewer}
			capabilities={data.capabilities}
			onPendingChangesChange={handleRevisionPendingChangesChange}
		/>
	{/if}
</section>

{#if showUnsavedChangesModal}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
		<div class="card w-full max-w-md p-5">
			<h3 class="text-lg font-semibold">Cambios sin guardar</h3>
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">{UNSAVED_CHANGES_MESSAGE}</p>
			<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
				Si continúas, perderás los cambios no guardados.
			</p>
			<div class="mt-4 flex justify-end gap-2">
				<button
					type="button"
					class="border border-[color:var(--border)] px-3 py-2 text-sm"
					onclick={cancelUnsavedChangesModal}
				>
					Seguir editando
				</button>
				<button
					type="button"
					class="border border-[color:var(--danger)] bg-[color:var(--danger)] px-3 py-2 text-sm text-[color:var(--danger-foreground)]"
					onclick={() => void confirmUnsavedChangesModal()}
				>
					Salir sin guardar
				</button>
			</div>
		</div>
	</div>
{/if}

