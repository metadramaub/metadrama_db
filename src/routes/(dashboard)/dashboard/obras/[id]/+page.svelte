<script lang="ts">
	import { browser } from '$app/environment';
	import { beforeNavigate, goto, invalidate } from '$app/navigation';
	import type { RealtimeChannel } from '@supabase/supabase-js';
	import { onMount, tick, untrack } from 'svelte';
	import { get } from 'svelte/store';
	import { page } from '$app/stores';
	import type { PageData } from './$types';
	import type { Tables } from '$lib/types/database.types';
	import type { EditorCuadroRow, EditorJornadaRow, EditorSecuenciaRow } from '$lib/types/editor.types';
	import type { AutoriaApiPayload } from '$lib/types/obra.types';
	import { stateAllowsRangeEditing } from '$lib/utils/range-consistency';
	import Button from '$lib/components/ui/button.svelte';
	import Tabs from '$lib/components/ui/tabs.svelte';
	import UnsavedChangesModal from '$lib/components/editor/UnsavedChangesModal.svelte';
	import DatosObraTab from '$lib/components/editor/DatosObraTab.svelte';
	import EstructuraTab from '$lib/components/editor/EstructuraTab.svelte';
	import SecuenciasTab from '$lib/components/editor/SecuenciasTab.svelte';
	import AutoriaTab from '$lib/components/editor/AutoriaTab.svelte';
	import ObservacionesTab from '$lib/components/editor/ObservacionesTab.svelte';
	import RevisionTab from '$lib/components/editor/RevisionTab.svelte';
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
	type GeneralSaveScope = Extract<ObraDirtyScope, 'datos' | 'autoria' | 'observaciones'>;
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
	let datosSaveRequestToken = $state(0);
	let autoriaSaveRequestToken = $state(0);
	let observacionesSaveRequestToken = $state(0);
	let commentsReloadKey = $state(0);
	const focusSecuenciaId = $derived.by(() => {
		const raw = $page.url.searchParams.get('focusSecuenciaId');
		if (!raw) return null;
		const normalized = raw.trim();
		return normalized.length > 0 ? normalized : null;
	});
	const focusJornadaId = $derived.by(() => {
		const raw = $page.url.searchParams.get('focusJornadaId');
		if (!raw) return null;
		const normalized = raw.trim();
		return normalized.length > 0 ? normalized : null;
	});
	const focusCuadroId = $derived.by(() => {
		const raw = $page.url.searchParams.get('focusCuadroId');
		if (!raw) return null;
		const normalized = raw.trim();
		return normalized.length > 0 ? normalized : null;
	});
	const focusComentarioId = $derived.by(() => {
		const raw = $page.url.searchParams.get('focusComentarioId');
		if (!raw) return null;
		const normalized = raw.trim();
		return normalized.length > 0 ? normalized : null;
	});
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
	const currentEstadoTerm = $derived.by(
		() =>
			estadoOptions.find((option) => option.termino_id === obraLive.estado)?.termino ??
			data.estadoTerm
	);
	const canEditRanges = $derived(
		canEditContent && stateAllowsRangeEditing(currentEstadoTerm)
	);
	const canComment = $derived(Boolean(data.capabilities?.canComment));

	// --- Datos públicos precomputados (Fase 2 del plan de precomputación) ---
	const isPublished = $derived(data.estadoTerm.trim().toLowerCase() === 'publicado');
	const canPublishData = $derived(
		data.profile.roleTerm === 'admin' ||
			data.profile.roleTerm === 'ip' ||
			data.obra.editor_asignado === data.profile.userId
	);
	let resumenExiste = $state(untrack(() => data.resumenPublico.existe));
	let resumenSucia = $state(untrack(() => data.resumenPublico.metricaSucia));
	let resumenActualizadoEn = $state<string | null>(
		untrack(() => data.resumenPublico.actualizadoEn)
	);
	let publicandoDatos = $state(false);

	async function publicarDatosPublicos() {
		if (!canPublishData || !isPublished || publicandoDatos) return;
		publicandoDatos = true;
		try {
			const res = await fetch(`/api/obras/${data.obra.obra_id}/publicar-datos`, {
				method: 'POST'
			});
			const body = await res.json().catch(() => ({}));
			if (!res.ok) {
				pushToast('error', body?.message ?? 'No se pudieron actualizar los datos públicos.');
				return;
			}
			resumenExiste = true;
			resumenSucia = Boolean(body.metrica_sucia);
			resumenActualizadoEn = body.actualizado_en ?? null;
			pushToast('success', 'Datos públicos actualizados.');
		} catch {
			pushToast('error', 'No se pudieron actualizar los datos públicos.');
		} finally {
			publicandoDatos = false;
		}
	}
	const generalSaveScope = $derived.by((): GeneralSaveScope | null => {
		if (currentTab === 'datos' || currentTab === 'autoria' || currentTab === 'observaciones') {
			return currentTab;
		}
		return null;
	});
	const showGeneralSave = $derived(Boolean(canEditContent && generalSaveScope));
	const generalSaveDisabled = $derived.by(() => {
		if (!generalSaveScope) return true;
		return Boolean($currentObraStore.savingByScope[generalSaveScope]);
	});
	const generalSaveLoading = $derived.by(() => {
		if (!generalSaveScope) return false;
		return Boolean($currentObraStore.savingByScope[generalSaveScope]);
	});
	let jornadasLive = $state<EditorJornadaRow[]>(untrack(() => [...data.jornadas]));
	let cuadrosLive = $state<EditorCuadroRow[]>(untrack(() => [...data.cuadros]));
	let secuenciasLive = $state<EditorSecuenciaRow[]>(untrack(() => [...data.secuencias]));
	let autoriaGroupCountLive = $state(untrack(() => data.autoriaGroupCount));

	let channel: RealtimeChannel | null = null;
	const UNSAVED_CHANGES_MESSAGE = 'Hay cambios sin guardar en esta pestaña.';
	let showUnsavedChangesModal = $state(false);
	let pendingTabChange: string | null = null;
	let pendingRouteChange: string | null = null;
	let bypassUnsavedGuard = false;
	let revisionHasPendingChanges = $state(false);
	let obraRefreshInFlight = false;
	let obraRefreshQueued = false;
	let obraRefreshTimer: ReturnType<typeof setTimeout> | null = null;
	const jornadaIds = $derived(
		new Set(jornadasLive.map((jornada) => jornada.jornada_id))
	);

	function getCurrentDirtyScope(): ObraDirtyScope | null {
		if (
			currentTab === 'datos' ||
			currentTab === 'estructura' ||
			currentTab === 'secuencias' ||
			currentTab === 'autoria' ||
			currentTab === 'observaciones'
		) {
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

	function handleEditorPendingChangesChange(
		scope: Extract<ObraDirtyScope, 'estructura' | 'secuencias'>,
		pending: boolean
	) {
		setDirty(pending, scope);
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

	async function refreshObra() {
		if (!browser) return;
		if (get(currentObraStore).dirty) {
			if (!$currentObraStore.conflict) {
				setConflict(true);
				pushToast('info', 'Otro editor guardó cambios; tu próximo guardado sobrescribirá.');
			}
			return;
		}
		if (obraRefreshInFlight) {
			obraRefreshQueued = true;
			return;
		}
		obraRefreshInFlight = true;
		try {
			await invalidate(`dashboard:obra:${data.obra.obra_id}`);
		} finally {
			obraRefreshInFlight = false;
			if (obraRefreshQueued) {
				obraRefreshQueued = false;
				scheduleObraRefresh();
			}
		}
	}

	function scheduleObraRefresh() {
		if (!browser) return;
		if (obraRefreshTimer) {
			clearTimeout(obraRefreshTimer);
		}
		obraRefreshTimer = setTimeout(() => {
			obraRefreshTimer = null;
			void refreshObra();
		}, 400);
	}

	function onExternalChange(payload: { table: string; jornada_id?: string | null }) {
		if (payload.table === 'comentarios_internos') {
			commentsReloadKey += 1;
			return;
		}
		const dirty = get(currentObraStore).dirty;
		if (payload.table === 'cuadros' && payload.jornada_id && !jornadaIds.has(payload.jornada_id)) {
			return;
		}
		if (dirty) {
			if (!$currentObraStore.conflict) {
				setConflict(true);
				pushToast('info', 'Otro editor guardó cambios; tu próximo guardado sobrescribirá.');
			}
			return;
		}
		scheduleObraRefresh();
	}

	function handleStructureChange(payload: {
		jornadas: EditorJornadaRow[];
		cuadros: EditorCuadroRow[];
	}) {
		jornadasLive = [...payload.jornadas];
		cuadrosLive = [...payload.cuadros];
		if (resumenExiste) resumenSucia = true;
	}

	function handleSecuenciasChange(payload: EditorSecuenciaRow[]) {
		secuenciasLive = [...payload];
		if (resumenExiste) resumenSucia = true;
	}

	function handleMetricaDirty() {
		if (resumenExiste) resumenSucia = true;
	}

	function handleAutoriaChange(payload: AutoriaApiPayload) {
		autoriaGroupCountLive = payload.grupos.filter(
			(grupo) => grupo.propuestas.length > 0
		).length;
	}

	function requestGeneralSave() {
		if (!canEditContent || !generalSaveScope) return;
		if (generalSaveScope === 'datos') {
			datosSaveRequestToken += 1;
			return;
		}
		if (generalSaveScope === 'autoria') {
			autoriaSaveRequestToken += 1;
			return;
		}
		observacionesSaveRequestToken += 1;
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
		let disposed = false;
		let cleanupChannel: (() => void) | null = null;

		const handleBeforeUnload = (event: BeforeUnloadEvent) => {
			if (!hasPendingChanges()) return;
			event.preventDefault();
			event.returnValue = '';
		};
		window.addEventListener('beforeunload', handleBeforeUnload);

		void (async () => {
			const { getSupabaseBrowserClient } = await import('$lib/services/supabase');
			if (disposed) return;

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
			cleanupChannel = () => {
				if (!channel) return;
				void supabase.removeChannel(channel);
				channel = null;
			};
		})();

		return () => {
			disposed = true;
			window.removeEventListener('beforeunload', handleBeforeUnload);
			if (obraRefreshTimer) {
				clearTimeout(obraRefreshTimer);
				obraRefreshTimer = null;
			}
			cleanupChannel?.();
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
		autoriaGroupCountLive = data.autoriaGroupCount;
	});

	// Resincroniza el estado de datos públicos al recargar (cambio de obra / invalidate).
	$effect(() => {
		resumenExiste = data.resumenPublico.existe;
		resumenSucia = data.resumenPublico.metricaSucia;
		resumenActualizadoEn = data.resumenPublico.actualizadoEn;
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

		{#if canPublishData}
			<div class="mt-3 flex flex-wrap items-center gap-3 border-t border-[color:var(--border)] pt-3">
				{#if !isPublished}
					<span class="text-sm text-[color:var(--muted-foreground)]">
						Datos públicos inactivos hasta que la obra vuelva a estar publicada.
					</span>
				{:else}
					{#if !resumenExiste}
						<span class="inline-flex items-center gap-1.5 text-sm text-[color:var(--muted-foreground)]">
							<span class="h-2 w-2 rounded-full bg-[color:var(--muted-foreground)]"></span>
							Datos públicos sin generar
						</span>
					{:else if resumenSucia}
						<span class="inline-flex items-center gap-1.5 text-sm text-amber-700">
							<span class="h-2 w-2 rounded-full bg-amber-500"></span>
							Hay cambios sin publicar
						</span>
					{:else}
						<span class="inline-flex items-center gap-1.5 text-sm text-emerald-700">
							<span class="h-2 w-2 rounded-full bg-emerald-500"></span>
							Datos públicos al día
						</span>
					{/if}
					{#if resumenActualizadoEn}
						<span class="text-xs text-[color:var(--muted-foreground)]">
							Última actualización: {new Date(resumenActualizadoEn).toLocaleString('es-ES')}
						</span>
					{/if}
					<Button
						variant={resumenSucia || !resumenExiste ? 'success' : 'secondary'}
						onclick={publicarDatosPublicos}
						disabled={publicandoDatos}
					>
						{#if publicandoDatos}
							Actualizando...
						{:else if !resumenExiste}
							Publicar datos públicos
						{:else}
							Actualizar datos públicos
						{/if}
					</Button>
				{/if}
			</div>
		{/if}
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
		<Tabs tabs={tabs} active={currentTab} onChange={handleTabChange}>
			{#snippet actions()}
				{#if showGeneralSave}
					<Button
						variant="success"
						onclick={requestGeneralSave}
						disabled={generalSaveDisabled}
						loading={generalSaveLoading}
						loadingLabel="Guardando…"
					>
						Guardar
					</Button>
				{/if}
			{/snippet}
		</Tabs>
	</div>

	{#if currentTab === 'datos'}
		<DatosObraTab
			obra={obraLive}
			generoOptions={generoOptions}
			saveRequestToken={datosSaveRequestToken}
			readOnly={!canEditContent}
			canComment={canComment}
			focusComentarioId={focusComentarioId}
			commentsReloadKey={commentsReloadKey}
		/>
	{:else if currentTab === 'estructura'}
		<EstructuraTab
			obraId={obraLive.obra_id}
			draftOwnerId={data.profile.userId}
			jornadasInitial={jornadasLive}
			cuadrosInitial={cuadrosLive}
			readOnly={!canEditRanges}
			canComment={canComment}
			focusJornadaId={focusJornadaId}
			focusCuadroId={focusCuadroId}
			focusComentarioId={focusComentarioId}
			commentsReloadKey={commentsReloadKey}
			onStructureChange={handleStructureChange}
			onPendingChangesChange={(pending) =>
				handleEditorPendingChangesChange('estructura', pending)}
		/>
	{:else if currentTab === 'secuencias'}
		<SecuenciasTab
			obraId={obraLive.obra_id}
			draftOwnerId={data.profile.userId}
			secuenciasInitial={secuenciasLive}
			jornadasInitial={jornadasLive}
			cuadrosInitial={cuadrosLive}
			estrofaOptions={estrofaOptions}
			caracterizacionRangoOptions={caracterizacionRangoOptions}
			readOnly={!canEditRanges}
			canComment={canComment}
			focusSecuenciaId={focusSecuenciaId}
			focusComentarioId={focusComentarioId}
			commentsReloadKey={commentsReloadKey}
			catalogoMetrico={data.catalogoMetrico}
			anotacionMetrica={data.anotacionMetrica}
			onSecuenciasChange={handleSecuenciasChange}
			onMetricaDirty={handleMetricaDirty}
			onPendingChangesChange={(pending) =>
				handleEditorPendingChangesChange('secuencias', pending)}
		/>
	{:else if currentTab === 'autoria'}
		<AutoriaTab
			obraId={obraLive.obra_id}
			obra={obraLive}
			roleTerm={data.profile.roleTerm}
			saveRequestToken={autoriaSaveRequestToken}
			readOnly={!canEditContent}
			canComment={canComment}
			focusComentarioId={focusComentarioId}
			commentsReloadKey={commentsReloadKey}
			onAutoriaChange={handleAutoriaChange}
			onMetricaDirty={handleMetricaDirty}
		/>
	{:else if currentTab === 'observaciones'}
		<ObservacionesTab
			obraId={obraLive.obra_id}
			observacionesInitial={obraLive.observaciones ?? ''}
			bibliografiaInitial={obraLive.bibliografia ?? ''}
			saveRequestToken={observacionesSaveRequestToken}
			readOnly={!canEditContent}
			canComment={canComment}
			focusComentarioId={focusComentarioId}
			commentsReloadKey={commentsReloadKey}
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
			autoriaGroupCount={autoriaGroupCountLive}
			editorAsignadoNombre={data.editorAsignadoNombre}
			assignedReviewer={data.assignedReviewer}
			capabilities={data.capabilities}
			focusComentarioId={focusComentarioId}
			commentsReloadKey={commentsReloadKey}
			onPendingChangesChange={handleRevisionPendingChangesChange}
			onNavigateToTab={handleTabChange}
		/>
	{/if}
</section>

<UnsavedChangesModal
	open={showUnsavedChangesModal}
	message={UNSAVED_CHANGES_MESSAGE}
	detail={
		currentTab === 'estructura' || currentTab === 'secuencias'
			? 'Si continúas, los cambios actuales no se guardarán.'
			: 'Si continúas, perderás los cambios no guardados.'
	}
	discardLabel="Salir sin guardar"
	onCancel={cancelUnsavedChangesModal}
	onDiscard={() => void confirmUnsavedChangesModal()}
/>

