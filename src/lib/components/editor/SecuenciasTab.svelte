<script lang="ts">
	import { browser } from '$app/environment';
	import { onDestroy, onMount, untrack } from 'svelte';
	import ChevronLeft from 'lucide-svelte/icons/chevron-left';
	import ChevronRight from 'lucide-svelte/icons/chevron-right';
	import Eye from 'lucide-svelte/icons/eye';
	import Pencil from 'lucide-svelte/icons/pencil';
	import Trash2 from 'lucide-svelte/icons/trash-2';
	import type { Tables } from '$lib/types/database.types';
	import Button from '$lib/components/ui/button.svelte';
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import FieldHelpTooltip from '$lib/components/ui/field-help-tooltip.svelte';
	import MarkdownEditorLite from '$lib/components/ui/markdown-editor-lite.svelte';
	import NullableBooleanChoice from '$lib/components/ui/nullable-boolean-choice.svelte';
	import InternalCommentsPanel from '$lib/components/editor/InternalCommentsPanel.svelte';
	import LocalDraftRecoveryModal from '$lib/components/editor/LocalDraftRecoveryModal.svelte';
	import RangeConsistencyAlert from '$lib/components/editor/RangeConsistencyAlert.svelte';
	import SequenceSynopsisModal from '$lib/components/editor/SequenceSynopsisModal.svelte';
	import UnsavedChangesModal from '$lib/components/editor/UnsavedChangesModal.svelte';
	import { buildSequenceSynopsisGroups } from '$lib/components/editor/sequence-synopsis';
	import { pushToast } from '$lib/stores/toast';
	import type { EditorCuadroRow, EditorJornadaRow, EditorSecuenciaRow } from '$lib/types/editor.types';
	import {
		buildLocalDraftKey,
		createLocalDraftWriter,
		readLocalDraft,
		removeLocalDraft,
		type LocalFormDraft
	} from '$lib/utils/local-form-draft';
	import { displayTerm } from '$lib/utils/vocabulario';
	import MetricSequenceEditor from '$lib/components/metrica/editor-v2/MetricSequenceEditor.svelte';
	import MetricSequenceModal from '$lib/components/metrica/editor-v2/MetricSequenceModal.svelte';
	import { draftFromRows } from '$lib/components/metrica/editor-v2/sequence-draft';
	import type {
		MetricSequenceDraft,
		MetricSequenceEditorState
	} from '$lib/components/metrica/editor-v2/sequence-draft';
	import type { MetricCatalogDomainRow, MetricCatalogForEditor } from '$lib/metrica/catalogo';
	import CaracterizacionesDeLaSecuencia from './secuencias/CaracterizacionesDeLaSecuencia.svelte';
	import DeDondeVieneLaSecuencia from './secuencias/DeDondeVieneLaSecuencia.svelte';
	import type { PropuestaDeSecuencia } from './secuencias/DeDondeVieneLaSecuencia.svelte';
	import CaracterizacionesPorRango from './secuencias/CaracterizacionesPorRango.svelte';
	import {
		analyzeSequenceRangeConsistency,
		collectRangeConsistencyIds
	} from '$lib/utils/range-consistency';

	const props = $props<{
		obraId: string;
		draftOwnerId: string;
		secuenciasInitial: EditorSecuenciaRow[];
		jornadasInitial: EditorJornadaRow[];
		cuadrosInitial: EditorCuadroRow[];
		estrofaOptions: Array<
			Pick<
				Tables<'vocabularios'>,
				'termino_id' | 'termino' | 'etiqueta' | 'termino_padre_id' | 'orden' | 'tipo_forma'
			>
		>;
		caracterizacionRangoOptions: Array<
			Pick<Tables<'vocabularios'>, 'termino_id' | 'termino' | 'etiqueta' | 'termino_padre_id' | 'orden'>
		>;
		readOnly?: boolean;
		canComment?: boolean;
		focusSecuenciaId?: string | null;
		focusComentarioId?: string | null;
		commentsReloadKey?: string | number | null;
		onSecuenciasChange?: (items: EditorSecuenciaRow[]) => void;
		onPendingChangesChange?: (pending: boolean) => void;
		// Señala que cambió algún dato que alimenta obras_resumen pero que NO altera
		// la lista de secuencias: hoy, las caracterizaciones por rango.
		onMetricaDirty?: () => void;
		/** El catálogo métrico. Sin él no hay editor nuevo que montar, y se cae al panel de siempre. */
		catalogoMetrico?: MetricCatalogForEditor | null;
		/** Lo que esta obra ya tiene anotado con el catálogo nuevo, para releerlo al abrir. */
		anotacionMetrica?: {
			secuencias: MetricCatalogDomainRow[];
			unidades: MetricCatalogDomainRow[];
			elecciones: MetricCatalogDomainRow[];
			desviaciones: MetricCatalogDomainRow[];
		} | null;
	}>();

	type IntervencionValue = 'sin_intervencion' | 'exclusiva' | 'compartida';

	type FormState = {
		v_ini: number;
		v_fin: number;
		estrofa_tipo_id: string;
		inaugura_espacio: boolean | null;
		versos_partidos: boolean | null;
		evocacion_metrica: boolean | null;
		evocacion_metrica_texto: string;
		intervencion_personajes_femeninos: IntervencionValue | null;
		intervencion_figuras_donaire: IntervencionValue | null;
		intervencion_personajes_sobrenaturales: IntervencionValue | null;
		sinopsis: string;
	};

	type PendingSidebarAction =
		| { kind: 'close' }
		| { kind: 'new' }
		| { kind: 'sequence'; target: EditorSecuenciaRow };

	type DraftRecovery = {
		key: string;
		draft: LocalFormDraft<FormState>;
	};

	let secuencias = $state(untrack(() => [...props.secuenciasInitial]));
	let sidebarOpen = $state(false);
	let editingId = $state<string | null>(null);
	let filtroEstrofa = $state('');
	let filtroEstrofaDraft = $state('');

	function aplicarFiltroEstrofa() {
		filtroEstrofa = filtroEstrofaDraft;
	}

	function limpiarFiltroEstrofa() {
		filtroEstrofaDraft = '';
		filtroEstrofa = '';
	}
	let deleteTargetId = $state<string | null>(null);
	let deletingSequence = $state(false);
	let sequenceSynopsisModalOpen = $state(false);
	let pendingSidebarAction = $state<PendingSidebarAction | null>(null);
	let draftRecovery = $state<DraftRecovery | null>(null);

	let sidebarSaving = $state(false);
	let sidebarDirty = $state(false);
	let sidebarBaselineSnapshot = $state('');
	let lastReportedPending = false;
	const localDraftWriter = createLocalDraftWriter();
	/** El componente de caracterizaciones, para recargarlo y cerrarlo desde aquí. */
	let caracterizaciones = $state<CaracterizacionesPorRango | null>(null);
	let handledFocusSecuenciaId = $state<string | null>(null);
	function sortEstrofaOptions(options: typeof props.estrofaOptions) {
		return [...options].sort(
			(a, b) => (a.orden ?? Number.MAX_SAFE_INTEGER) - (b.orden ?? Number.MAX_SAFE_INTEGER) ||
				a.termino.localeCompare(b.termino, 'es')
		);
	}

	function normalizeTerm(value: string): string {
		return value
			.normalize('NFD')
			.replaceAll(/\p{M}/gu, '')
			.trim()
			.toLowerCase()
			.replaceAll(/[\s-]+/g, '_');
	}

	const sortedEstrofaOptions = $derived.by(() => sortEstrofaOptions(props.estrofaOptions));
	const estrofaById = $derived.by(
		() =>
			new Map<string, Pick<Tables<'vocabularios'>, 'termino_id' | 'termino' | 'etiqueta' | 'termino_padre_id'>>(
				sortedEstrofaOptions.map(
					(
						option: Pick<Tables<'vocabularios'>, 'termino_id' | 'termino' | 'etiqueta' | 'termino_padre_id'>
					): readonly [string, Pick<Tables<'vocabularios'>, 'termino_id' | 'termino' | 'etiqueta' | 'termino_padre_id'>] => [
						option.termino_id,
						option
					]
				)
			)
	);
	const quintillaRootId = $derived.by(() => {
		const root = sortedEstrofaOptions.find(
			(option) => !option.termino_padre_id && normalizeTerm(option.termino) === 'quintilla'
		);
		return root?.termino_id ?? null;
	});
	const estrofaSelectableOptions = $derived.by(() =>
		sortedEstrofaOptions.filter((option) => {
			if (!quintillaRootId) return true;
			let parentId = option.termino_padre_id;
			while (parentId) {
				if (parentId === quintillaRootId) return false;
				parentId = estrofaById.get(parentId)?.termino_padre_id ?? null;
			}
			return true;
		})
	);
	const estrofaSelectableIds = $derived.by(() => new Set(estrofaSelectableOptions.map((option) => option.termino_id)));
	const estrofaDropdownItems = $derived.by(() =>
		estrofaSelectableOptions.map((option) => ({
			id: option.termino_id,
			label: displayTerm(option),
			parentId: option.termino_padre_id ?? null
		}))
	);
	function toSelectableEstrofaId(termId: string | null | undefined): string {
		if (!termId) return '';
		if (estrofaSelectableIds.has(termId)) return termId;

		let cursor = estrofaById.get(termId) ?? null;
		while (cursor?.termino_padre_id) {
			const parentId = cursor.termino_padre_id;
			if (estrofaSelectableIds.has(parentId)) return parentId;
			cursor = estrofaById.get(parentId) ?? null;
		}

		return '';
	}

	function getSuggestedSecuenciaStart(): number {
		const maxVFin = secuencias.reduce((max, item) => Math.max(max, Number(item.v_fin) || 0), 0);
		return maxVFin > 0 ? maxVFin + 1 : 1;
	}

	function initialForm(): FormState {
		const suggestedStart = getSuggestedSecuenciaStart();
		return {
			v_ini: suggestedStart,
			v_fin: suggestedStart + 1,
			estrofa_tipo_id: '',
			inaugura_espacio: null,
			versos_partidos: null,
			evocacion_metrica: null,
			evocacion_metrica_texto: '',
			intervencion_personajes_femeninos: null,
			intervencion_figuras_donaire: null,
			intervencion_personajes_sobrenaturales: null,
			sinopsis: ''
		};
	}

	let form = $state<FormState>(initialForm());

	function termById(
		options: Array<Pick<Tables<'vocabularios'>, 'termino_id' | 'termino' | 'etiqueta'>>,
		id: string | null
	) {
		if (!id) return 'Pendiente';
		const option = options.find((opt) => opt.termino_id === id);
		return option ? displayTerm(option) : 'Pendiente';
	}

	function sortSecuencias(items: EditorSecuenciaRow[]) {
		return [...items].sort((a, b) => a.v_ini - b.v_ini);
	}

	function sortJornadas(items: EditorJornadaRow[]) {
		return [...items].sort(
			(a, b) => a.v_ini - b.v_ini || a.v_fin - b.v_fin || a.jornada_num - b.jornada_num
		);
	}

	function sortCuadros(items: EditorCuadroRow[]) {
		return [...items].sort((a, b) => a.v_ini - b.v_ini || a.v_fin - b.v_fin || a.cuadro_num - b.cuadro_num);
	}

	function emitSecuenciasChange(nextItems: EditorSecuenciaRow[] = secuencias) {
		props.onSecuenciasChange?.(sortSecuencias(nextItems));
	}

	const jornadasSorted = $derived.by(() => sortJornadas(props.jornadasInitial));
	const cuadrosSorted = $derived.by(() => sortCuadros(props.cuadrosInitial));

	const filteredSecuencias = $derived.by(() => {
		return secuencias
			.filter((secuencia) => !filtroEstrofa || secuencia.estrofa_tipo_id === filtroEstrofa)
			.sort((a, b) => a.v_ini - b.v_ini);
	});
	// Todas las secuencias ordenadas, para numerar y navegar en el panel de edición.
	const orderedSecuencias = $derived.by(() => sortSecuencias(secuencias));
	const sequenceOverlapIssues = $derived.by(() => analyzeSequenceRangeConsistency(secuencias));
	const sequenceOverlapIds = $derived(collectRangeConsistencyIds(sequenceOverlapIssues));
	const editingIndex = $derived.by(() =>
		editingId ? orderedSecuencias.findIndex((item) => item.secuencia_id === editingId) : -1
	);
	const prevSecuencia = $derived.by(() =>
		editingIndex > 0 ? orderedSecuencias[editingIndex - 1] : null
	);
	const nextSecuencia = $derived.by(() =>
		editingIndex >= 0 && editingIndex < orderedSecuencias.length - 1
			? orderedSecuencias[editingIndex + 1]
			: null
	);
	const totalVersosEstructura = $derived.by(() => {
		if (jornadasSorted.length === 0) return null;
		const maxVFin = jornadasSorted.reduce((max, jornada) => Math.max(max, Number(jornada.v_fin) || 0), 0);
		return maxVFin > 0 ? maxVFin : null;
	});
	const totalVersosDeclaradosFiltrados = $derived.by(() =>
		filteredSecuencias.reduce((sum, secuencia) => sum + (Number(secuencia.n_versos) || 0), 0)
	);
	const diferenciaFiltrada = $derived.by(() => {
		if (totalVersosEstructura === null) return null;
		return totalVersosDeclaradosFiltrados - totalVersosEstructura;
	});
	const cuadrosByJornada = $derived.by(() => {
		const grouped = new Map<string, EditorCuadroRow[]>();
		for (const cuadro of cuadrosSorted) {
			const items = grouped.get(cuadro.jornada_id) ?? [];
			items.push(cuadro);
			grouped.set(cuadro.jornada_id, items);
		}
		return grouped;
	});
	const sequenceSynopsisGroups = $derived.by(() =>
		buildSequenceSynopsisGroups({
			secuencias,
			jornadas: jornadasSorted,
			cuadros: cuadrosSorted,
			estrofaOptions: props.estrofaOptions
		})
	);
	const sequenceSynopsisMissingCount = $derived.by(
		() => secuencias.filter((secuencia) => !(secuencia.sinopsis ?? '').trim()).length
	);

	function openSequenceSynopsisModal() {
		sequenceSynopsisModalOpen = true;
	}

	function closeSequenceSynopsisModal() {
		sequenceSynopsisModalOpen = false;
	}

	function sidebarSnapshot(source: FormState = form, sourceEditingId: string | null = editingId): string {
		return JSON.stringify({
			sidebarOpen,
			id: sourceEditingId,
			v_ini: Number(source.v_ini),
			v_fin: Number(source.v_fin),
			estrofa_tipo_id: source.estrofa_tipo_id,
			inaugura_espacio: source.inaugura_espacio,
			versos_partidos: source.versos_partidos,
			evocacion_metrica: source.evocacion_metrica,
			evocacion_metrica_texto: source.evocacion_metrica ? source.evocacion_metrica_texto.trim() : '',
			intervencion_personajes_femeninos: source.intervencion_personajes_femeninos,
			intervencion_figuras_donaire: source.intervencion_figuras_donaire,
			intervencion_personajes_sobrenaturales: source.intervencion_personajes_sobrenaturales,
			sinopsis: source.sinopsis.trim()
		});
	}

	function localDraftKey(sourceEditingId: string | null = editingId): string {
		return buildLocalDraftKey([
			props.draftOwnerId,
			props.obraId,
			'secuencia',
			sourceEditingId ?? 'nueva'
		]);
	}

	function isFormState(value: unknown): value is FormState {
		if (!value || typeof value !== 'object') return false;
		const candidate = value as Partial<FormState>;
		const isIntervencionValue = (intervencion: unknown) =>
			intervencion === null ||
			['sin_intervencion', 'exclusiva', 'compartida'].includes(String(intervencion));
		return (
			Number.isFinite(Number(candidate.v_ini)) &&
			Number.isFinite(Number(candidate.v_fin)) &&
			typeof candidate.estrofa_tipo_id === 'string' &&
			(candidate.inaugura_espacio === null || typeof candidate.inaugura_espacio === 'boolean') &&
			(candidate.versos_partidos === null || typeof candidate.versos_partidos === 'boolean') &&
			(candidate.evocacion_metrica === null || typeof candidate.evocacion_metrica === 'boolean') &&
			typeof candidate.evocacion_metrica_texto === 'string' &&
			isIntervencionValue(candidate.intervencion_personajes_femeninos) &&
			isIntervencionValue(candidate.intervencion_figuras_donaire) &&
			isIntervencionValue(candidate.intervencion_personajes_sobrenaturales) &&
			typeof candidate.sinopsis === 'string'
		);
	}

	function prepareLocalDraftRecovery() {
		draftRecovery = null;
		if (!browser || props.readOnly) return;
		const key = localDraftKey();
		const draft = readLocalDraft<FormState>(key);
		if (!draft) return;
		if (!isFormState(draft.value)) {
			removeLocalDraft(key);
			return;
		}
		if (sidebarSnapshot(draft.value) === sidebarBaselineSnapshot) {
			removeLocalDraft(key);
			return;
		}
		draftRecovery = { key, draft };
	}

	function discardLocalDraft() {
		if (!draftRecovery) return;
		removeLocalDraft(draftRecovery.key);
		draftRecovery = null;
	}

	function restoreLocalDraft() {
		if (!draftRecovery) return;
		form = { ...draftRecovery.draft.value };
		draftRecovery = null;
		pushToast('info', 'Borrador local recuperado. Pulsa Guardar para enviarlo a Supabase.');
	}

	function reportPendingChanges(pending: boolean) {
		if (pending === lastReportedPending) return;
		lastReportedPending = pending;
		props.onPendingChangesChange?.(pending);
	}

	function setSidebarBaselineFromCurrent() {
		sidebarBaselineSnapshot = sidebarSnapshot();
		sidebarDirty = false;
		reportPendingChanges(false);
	}

	function refreshSidebarDirty() {
		if (!sidebarOpen) {
			sidebarDirty = false;
			return false;
		}
		const current = sidebarSnapshot();
		sidebarDirty = current !== sidebarBaselineSnapshot;
		return sidebarDirty;
	}

	function validateForm(showToast = true) {
		if (!Number.isFinite(Number(form.v_ini)) || !Number.isFinite(Number(form.v_fin)) || Number(form.v_ini) > Number(form.v_fin)) {
			if (showToast) pushToast('error', 'Rango de versos inválido');
			return false;
		}
		return true;
	}

	function openNew() {
		if (props.readOnly) return;
		editingId = null;
		form = initialForm();
		caracterizaciones?.cerrarModales();
		sidebarOpen = true;
		pendingSidebarAction = null;
		setSidebarBaselineFromCurrent();
		prepareLocalDraftRecovery();
	}

	function openEdit(secuencia: EditorSecuenciaRow) {
		if (props.readOnly && !props.canComment) return;
		editingId = secuencia.secuencia_id;
		form = {
			v_ini: secuencia.v_ini,
			v_fin: secuencia.v_fin,
			estrofa_tipo_id: toSelectableEstrofaId(secuencia.estrofa_tipo_id),
			inaugura_espacio: secuencia.inaugura_espacio,
			versos_partidos: secuencia.versos_partidos,
			evocacion_metrica: secuencia.evocacion_metrica,
			evocacion_metrica_texto: secuencia.evocacion_metrica_texto ?? '',
			intervencion_personajes_femeninos: secuencia.intervencion_personajes_femeninos as IntervencionValue | null,
			intervencion_figuras_donaire: secuencia.intervencion_figuras_donaire as IntervencionValue | null,
			intervencion_personajes_sobrenaturales:
				secuencia.intervencion_personajes_sobrenaturales as IntervencionValue | null,
			sinopsis: secuencia.sinopsis ?? ''
		};
		caracterizaciones?.cerrarModales();
		sidebarOpen = true;
		pendingSidebarAction = null;
		setSidebarBaselineFromCurrent();
		prepareLocalDraftRecovery();
		// Solo cuesta la consulta si la secuencia venía anotada con el vocabulario viejo.
		if (secuencia.estrofa_tipo_id) void cargarPropuestas();
	}

	function requestOpenNew() {
		if (props.readOnly || sidebarSaving) return;
		if (sidebarOpen && refreshSidebarDirty()) {
			pendingSidebarAction = { kind: 'new' };
			return;
		}
		openNew();
	}

	function requestOpenEdit(secuencia: EditorSecuenciaRow) {
		if (sidebarSaving) return;
		if (sidebarOpen && editingId === secuencia.secuencia_id) return;
		if (!props.readOnly && sidebarOpen && refreshSidebarDirty()) {
			pendingSidebarAction = { kind: 'sequence', target: secuencia };
			return;
		}
		openEdit(secuencia);
	}

	function goToSecuencia(target: EditorSecuenciaRow | null) {
		if (!target || sidebarSaving) return;
		requestOpenEdit(target);
	}

	function performCloseSidebar() {
		localDraftWriter.cancel();
		sidebarOpen = false;
		editingId = null;
		caracterizaciones?.cerrarModales();
		sidebarDirty = false;
		sidebarBaselineSnapshot = '';
		pendingSidebarAction = null;
		draftRecovery = null;
		reportPendingChanges(false);
	}

	function requestCloseSidebar() {
		if (props.readOnly) {
			performCloseSidebar();
			return;
		}
		if (!refreshSidebarDirty()) {
			performCloseSidebar();
			return;
		}
		pendingSidebarAction = { kind: 'close' };
	}

	function cancelPendingSidebarAction() {
		pendingSidebarAction = null;
	}

	function executeSidebarAction(action: PendingSidebarAction) {
		if (action.kind === 'close') {
			performCloseSidebar();
			return;
		}
		if (action.kind === 'new') {
			openNew();
			return;
		}
		openEdit(action.target);
	}

	function discardAndContinue() {
		const action = pendingSidebarAction;
		if (!action) return;
		localDraftWriter.cancel();
		removeLocalDraft(localDraftKey());
		pendingSidebarAction = null;
		executeSidebarAction(action);
	}

	async function saveAndContinue() {
		const action = pendingSidebarAction;
		if (!action) return;
		const saved = await save();
		if (!saved) return;
		pendingSidebarAction = null;
		executeSidebarAction(action);
	}

	async function save(): Promise<boolean> {
		if (!browser) return false;
		if (props.readOnly || sidebarSaving || !sidebarOpen) return false;
		if (!validateForm(true)) return false;

		sidebarSaving = true;
		const currentId = editingId;
		const submittedDraftKey = localDraftKey(currentId);
		const endpoint = currentId
			? `/api/obras/${props.obraId}/secuencias/${currentId}`
			: `/api/obras/${props.obraId}/secuencias`;
		const method = currentId ? 'PATCH' : 'POST';

		let response: Response;
		try {
			response = await fetch(endpoint, {
				method,
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({
					...form,
					estrofa_tipo_id: form.estrofa_tipo_id || null,
					evocacion_metrica_texto: form.evocacion_metrica ? form.evocacion_metrica_texto : null
				})
			});
		} catch {
			sidebarSaving = false;
			pushToast('error', 'No se pudo conectar con el servidor. Los cambios siguen sin guardar.');
			return false;
		}

		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			const message = body.message ?? 'No se pudo guardar la secuencia';
			sidebarSaving = false;
			pushToast('error', message);
			return false;
		}

		const payload = await response.json().catch(() => null);
		if (!payload?.secuencia) {
			sidebarSaving = false;
			pushToast('error', 'El servidor devolvió una respuesta incompleta. Los cambios siguen sin guardar.');
			return false;
		}
		const savedSecuencia = payload.secuencia as EditorSecuenciaRow;
		const savedId = currentId ?? savedSecuencia.secuencia_id;

		if (currentId) {
			const next = secuencias.map((item) => (item.secuencia_id === currentId ? savedSecuencia : item));
			secuencias = next;
			emitSecuenciasChange(next);
			} else {
			const next = sortSecuencias([...secuencias, savedSecuencia]);
			secuencias = next;
			emitSecuenciasChange(next);
			editingId = savedId;
				}

		form = {
			v_ini: savedSecuencia.v_ini,
			v_fin: savedSecuencia.v_fin,
			estrofa_tipo_id: toSelectableEstrofaId(savedSecuencia.estrofa_tipo_id),
			inaugura_espacio: savedSecuencia.inaugura_espacio,
			versos_partidos: savedSecuencia.versos_partidos,
			evocacion_metrica: savedSecuencia.evocacion_metrica,
			evocacion_metrica_texto: savedSecuencia.evocacion_metrica_texto ?? '',
			intervencion_personajes_femeninos:
				savedSecuencia.intervencion_personajes_femeninos as IntervencionValue | null,
			intervencion_figuras_donaire:
				savedSecuencia.intervencion_figuras_donaire as IntervencionValue | null,
			intervencion_personajes_sobrenaturales:
				savedSecuencia.intervencion_personajes_sobrenaturales as IntervencionValue | null,
			sinopsis: savedSecuencia.sinopsis ?? ''
		};

		// ------------------------------------------------------------------ La anotación métrica
		//
		// **Va después de la secuencia y no puede ir antes**: la anotación apunta a una secuencia
		// real, así que necesita que exista. Por eso crear una secuencia la guarda ya como
		// secuencia, y a partir de ahí cada cosa que se cambie se guarda por su lado.
		//
		// *Si esto falla, la secuencia ya está escrita.* No es una pérdida —el rango y las
		// caracterizaciones quedan— pero sí un estado a medias, y el aviso tiene que decirlo con
		// esas palabras para que quien anota sepa que basta con volver a guardar.
		if (usaElEditorNuevo && estadoMetrico) {
			const guardada = await guardarAnotacionMetrica(savedId, estadoMetrico);
			if (!guardada) {
				sidebarSaving = false;
				return false;
			}
		}

		localDraftWriter.cancel();
		removeLocalDraft(submittedDraftKey);
		setSidebarBaselineFromCurrent();
		pushToast('success', currentId ? 'Secuencia actualizada' : 'Secuencia creada');
		if (
			!currentId &&
			filtroEstrofa &&
			savedSecuencia.estrofa_tipo_id !== filtroEstrofa
		) {
			pushToast('info', 'Secuencia creada. Está oculta por los filtros actuales.');
		}
		sidebarSaving = false;
		return true;
	}

	/**
	 * El editor V2 es **el único sitio donde se edita el rango** de una secuencia, así que el
	 * formulario tiene que seguirlo.
	 *
	 * No es un adorno: el guardado de la secuencia manda `form`, y la anotación manda el borrador. Si
	 * se separan, mover el rango en el editor no llegaba a `secuencias_metricas` —se guardaba el
	 * viejo— y la anotación quedaba describiendo otro pasaje. Y de paso lo siguen la cobertura, la
	 * validación y el rango que acota las caracterizaciones.
	 */
	function recibirEstadoMetrico(estado: MetricSequenceEditorState) {
		estadoMetrico = estado;
		const { v_ini, v_fin } = estado.draft;
		if (form.v_ini !== v_ini || form.v_fin !== v_fin) {
			form = { ...form, v_ini, v_fin };
		}
	}

	/**
	 * El borrador vivo del editor métrico, que él devuelve en cada cambio.
	 *
	 * La pestaña no lo toca: solo lo guarda cuando se pulsa Guardar. Quien decide qué es válido es
	 * el propio editor, que además dice por qué no lo es.
	 */
	let estadoMetrico = $state<MetricSequenceEditorState | null>(null);

	/**
	 * De dónde viene cada secuencia que ya estaba anotada con el vocabulario legado.
	 *
	 * **Se pide una vez por obra y solo cuando hace falta**: la primera vez que se abre una secuencia
	 * con término legado. La consulta que la responde deriva el catálogo entero, así que pedirla en
	 * cada visita a la pestaña sería repetir el error que hacía caer `/dashboard/metrica`.
	 */
	let propuestas = $state<Map<string, PropuestaDeSecuencia> | null>(null);
	let propuestasCargando = $state(false);

	async function cargarPropuestas() {
		if (!browser || propuestas || propuestasCargando) return;
		propuestasCargando = true;
		try {
			const respuesta = await fetch(`/api/obras/${props.obraId}/secuencias/propuesta`);
			if (!respuesta.ok) return;
			const carga = await respuesta.json().catch(() => ({ items: [] }));
			propuestas = new Map(
				(carga.items ?? []).map((fila: PropuestaDeSecuencia & { secuencia_id: string }) => [
					String(fila.secuencia_id),
					fila
				])
			);
		} catch {
			// Es un mensaje de ayuda: si no llega, el editor sigue sirviendo igual.
		} finally {
			propuestasCargando = false;
		}
	}

	/** La secuencia abierta, si venía anotada con el vocabulario viejo. */
	const propuestaDeLaAbierta = $derived.by(() => {
		if (!editingId) return null;
		const secuencia = secuencias.find((row) => row.secuencia_id === editingId);
		if (!secuencia?.estrofa_tipo_id) return null;
		return propuestas?.get(editingId) ?? null;
	});

	/** Y si hay que ir a buscarla, para enseñar que se está buscando. */
	const buscandoLaPropuesta = $derived.by(() => {
		if (!editingId || propuestas) return false;
		const secuencia = secuencias.find((row) => row.secuencia_id === editingId);
		return Boolean(secuencia?.estrofa_tipo_id) && propuestasCargando;
	});

	/**
	 * Si hay catálogo que darle al editor nuevo.
	 *
	 * **Todas las obras se anotan con él** desde el 27 de agosto de 2026, así que lo único que puede
	 * faltar es el catálogo mismo: `loadMetricCatalog` devuelve vacío cuando faltan migraciones o
	 * cuando quien mira no puede leer su revisión, que hoy exige ser admin o IP. Sin catálogo, el
	 * editor nuevo no puede pintar nada, y es mejor el panel de siempre que una pantalla en blanco.
	 */
	const usaElEditorNuevo = $derived(Boolean(props.catalogoMetrico));

	/**
	 * El borrador que consume el editor V2.
	 *
	 * Si la secuencia ya tiene anotación, se relee entera —forma, arquitectura, realizaciones,
	 * respuestas y desviaciones— para que guardar la **actualice** en vez de intentar crear una
	 * segunda, que el índice único rechazaría. Si no la tiene, se arranca en blanco con el rango
	 * puesto, que es lo que el editor necesita para dividir el pasaje en unidades.
	 *
	 * *El rango manda siempre sobre lo guardado*: si el editor acaba de moverlo, es ese el que vale.
	 */
	function borradorMetrico(): MetricSequenceDraft {
		const vIni = Number(form.v_ini) || 1;
		const vFin = Number(form.v_fin) || 1;
		const anotada = editingId
			? (props.anotacionMetrica?.secuencias ?? []).find(
					(fila: MetricCatalogDomainRow) => String(fila.secuencia_id) === editingId
				)
			: null;

		if (anotada) {
			const borrador = draftFromRows(anotada, {
				units: props.anotacionMetrica?.unidades ?? [],
				choices: props.anotacionMetrica?.elecciones ?? [],
				deviations: props.anotacionMetrica?.desviaciones ?? []
			});
			return { ...borrador, v_ini: vIni, v_fin: vFin };
		}

		return {
			anotacion_id: null,
			escenario_id: null,
			secuencia_id: editingId,
			// `orden` es obligatorio y en una secuencia real no ordena nada: solo las anotaciones de
			// escenario compiten por él. Se usa el sitio que ocupa en la obra, que al menos se lee.
			orden: editingIndex >= 0 ? editingIndex + 1 : 1,
			v_ini: vIni,
			v_fin: vFin,
			forma_id: '',
			arquitectura_id: '',
			observaciones: '',
			unidades: [],
			elecciones: [],
			desviaciones: []
		};
	}

	/**
	 * Escribe la identidad métrica de una secuencia en las tablas de la anotación.
	 *
	 * Comparte endpoint con el editor de pruebas: `save_sequence` acepta `secuencia_id` —la real— o
	 * `escenario_id`, y la base resuelve una u otra. No hacía falta inventar un camino nuevo.
	 */
	async function guardarAnotacionMetrica(
		secuenciaId: string,
		estado: MetricSequenceEditorState
	): Promise<boolean> {
		if (estado.error) {
			pushToast('error', estado.error);
			return false;
		}
		const borrador: MetricSequenceDraft = estado.draft;
		const limpiar = (valor: string | null | undefined) => {
			const texto = (valor ?? '').trim();
			return texto.length > 0 ? texto : null;
		};

		let respuesta: Response;
		try {
			respuesta = await fetch('/api/metrica/editor-pruebas', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({
					action: 'save_sequence',
					...borrador,
					escenario_id: null,
					secuencia_id: secuenciaId,
					arquitectura_id: borrador.arquitectura_id || null,
					observaciones: limpiar(borrador.observaciones),
					unidades: borrador.unidades.map((unidad) => ({
						...unidad,
						etiqueta: limpiar(unidad.etiqueta),
						observaciones: limpiar(unidad.observaciones)
					})),
					desviaciones: borrador.desviaciones.map((desviacion) => ({
						...desviacion,
						observaciones: limpiar(desviacion.observaciones)
					}))
				})
			});
		} catch {
			pushToast(
				'error',
				'La secuencia se guardó, pero no se pudo conectar para guardar su anotación métrica. Vuelve a guardar.'
			);
			return false;
		}

		if (!respuesta.ok) {
			const cuerpo = await respuesta.json().catch(() => ({}));
			pushToast(
				'error',
				`La secuencia se guardó, pero su anotación métrica no: ${
					cuerpo.details?.[0]?.message ?? cuerpo.message ?? 'error desconocido'
				}. Vuelve a guardar.`
			);
			return false;
		}
		return true;
	}

	function openDelete(secuenciaId: string) {
		if (props.readOnly) return;
		deleteTargetId = secuenciaId;
	}

	async function remove(secuenciaId: string) {
		if (!browser) return;
		if (props.readOnly || deletingSequence) return;
		deletingSequence = true;
		try {
			const response = await fetch(`/api/obras/${props.obraId}/secuencias/${secuenciaId}`, {
				method: 'DELETE'
			});
			if (!response.ok) {
				const body = await response.json().catch(() => ({}));
				pushToast('error', body.message ?? 'No se pudo eliminar la secuencia');
				return;
			}
			const next = secuencias.filter((row) => row.secuencia_id !== secuenciaId);
			secuencias = next;
			emitSecuenciasChange(next);
			if (editingId === secuenciaId) {
				performCloseSidebar();
			}
			pushToast('success', 'Secuencia eliminada');
			deleteTargetId = null;
		} catch {
			pushToast('error', 'No se pudo conectar con el servidor para eliminar la secuencia');
		} finally {
			deletingSequence = false;
		}
	}

	function clearFocusSecuenciaQueryParam() {
		if (!browser) return;
		const currentUrl = new URL(window.location.href);
		if (!currentUrl.searchParams.has('focusSecuenciaId')) return;
		currentUrl.searchParams.delete('focusSecuenciaId');
		window.history.replaceState(window.history.state, '', currentUrl.toString());
	}

	$effect(() => {
		const initialSecuencias = props.secuenciasInitial;
		if (secuencias.length === 0 && initialSecuencias.length > 0) {
			secuencias = [...initialSecuencias];
		}
	});

	$effect(() => {
		const focusSecuenciaId = props.focusSecuenciaId?.trim() ?? '';
		if (!focusSecuenciaId) {
			handledFocusSecuenciaId = null;
			return;
		}
		if (focusSecuenciaId === handledFocusSecuenciaId) return;

		const targetSecuencia = secuencias.find((item) => item.secuencia_id === focusSecuenciaId) ?? null;
		if (targetSecuencia) {
			openEdit(targetSecuencia);
		} else {
			pushToast('info', 'La secuencia enlazada no existe o ya no está disponible.');
		}

		handledFocusSecuenciaId = focusSecuenciaId;
		clearFocusSecuenciaQueryParam();
	});

	$effect(() => {
		const open = sidebarOpen;
		const readOnly = props.readOnly;
		const track = `${form.v_ini}|${form.v_fin}|${form.estrofa_tipo_id}|${form.inaugura_espacio}|${form.versos_partidos}|${form.evocacion_metrica}|${form.evocacion_metrica_texto}|${form.intervencion_personajes_femeninos}|${form.intervencion_figuras_donaire}|${form.intervencion_personajes_sobrenaturales}|${form.sinopsis}|${editingId}`;
		void track;

		if (!open || readOnly) {
			sidebarDirty = false;
			localDraftWriter.cancel();
			reportPendingChanges(false);
			return;
		}

		const currentSnapshot = sidebarSnapshot();
		sidebarDirty = currentSnapshot !== sidebarBaselineSnapshot;
		reportPendingChanges(sidebarDirty);
		if (draftRecovery) {
			localDraftWriter.cancel();
			return;
		}
		if (!sidebarDirty) {
			localDraftWriter.cancel();
			removeLocalDraft(localDraftKey());
			return;
		}
		localDraftWriter.schedule(localDraftKey(), { ...form });
	});

	onDestroy(() => {
		localDraftWriter.flush();
		props.onPendingChangesChange?.(false);
	});

	onMount(() => {
		const flushLocalDraft = () => localDraftWriter.flush();
		window.addEventListener('pagehide', flushLocalDraft);
		return () => window.removeEventListener('pagehide', flushLocalDraft);
	});
</script>

<section class="space-y-4">
	<div class="flex flex-wrap items-end justify-between gap-3 pb-3 pt-2">
		<h2 class="text-lg font-semibold">Secuencias métricas</h2>
		<div class="flex flex-wrap items-end gap-2">
			<div class="w-56">
				<CheckDropdown
					multiple={false}
					hierarchical={true}
					collapsibleHierarchy={true}
					disableParentsWithChildren={false}
					closeOnSelect={false}
					showPathInTrigger={true}
					allowSingleClear={true}
					search={true}
					placeholder="Filtrar por estrofa"
					items={estrofaDropdownItems}
					selectedIds={filtroEstrofaDraft ? [filtroEstrofaDraft] : []}
					onChange={(ids) => {
						filtroEstrofaDraft = ids[0] ?? '';
					}}
				/>
			</div>
			<Button variant="secondary" onclick={aplicarFiltroEstrofa}>Filtrar</Button>
			<Button
				variant="ghost"
				onclick={limpiarFiltroEstrofa}
				disabled={!filtroEstrofa && !filtroEstrofaDraft}
			>
				Limpiar
			</Button>
			<Button variant="primary-soft" onclick={requestOpenNew} disabled={props.readOnly}>Nueva secuencia</Button>
		</div>
	</div>

	<RangeConsistencyAlert issues={sequenceOverlapIssues} />

	<div class="lg:grid lg:grid-cols-[15rem_minmax(0,1fr)] lg:gap-4">
		<aside class="secuencias-structure-index hidden lg:sticky lg:top-4 lg:block lg:h-fit lg:self-start">
			<div class="card secuencias-structure-index__head">Índice de estructura</div>
			{#if jornadasSorted.length === 0}
				<p class="card secuencias-structure-index__empty-text">Sin estructura registrada.</p>
			{:else}
				<ul class="card secuencias-structure-list">
					{#each jornadasSorted as jornada (jornada.jornada_id)}
						<li class="secuencias-structure-list__item">
							<p class="secuencias-structure-list__jornada">
								Jornada {jornada.jornada_num}
								<span>(vv. {jornada.v_ini}-{jornada.v_fin})</span>
							</p>
							{#if (cuadrosByJornada.get(jornada.jornada_id)?.length ?? 0) > 0}
								<ul class="secuencias-structure-sublist">
									{#each cuadrosByJornada.get(jornada.jornada_id) ?? [] as cuadro (cuadro.cuadro_id)}
										<li class="secuencias-structure-sublist__item">
											Cuadro {cuadro.cuadro_num} (vv. {cuadro.v_ini}-{cuadro.v_fin})
										</li>
									{/each}
								</ul>
							{/if}
						</li>
					{/each}
				</ul>
			{/if}
			<div class="card mt-4 space-y-2">
				<Button variant="primary" class="w-full" onclick={openSequenceSynopsisModal}>
					Leer sinopsis completa
				</Button>
				{#if sidebarDirty}
					<p class="text-xs text-[color:var(--muted-foreground)]">
						La sinopsis completa refleja la última versión guardada mientras haya cambios pendientes en el panel lateral.
					</p>
				{/if}
			</div>
			<div class="mt-4 space-y-2">
				<Button variant="primary-soft" class="w-full" onclick={requestOpenNew} disabled={props.readOnly}>
					Nueva secuencia
				</Button>
			</div>
		</aside>

		<div class="space-y-2">
			<div class="card overflow-x-auto">
				<table class="min-w-full text-left text-sm">
					<thead class="bg-[color:var(--muted)]">
						<tr>
							<th class="sticky top-0 z-10 bg-[color:var(--muted)] px-3 py-2">#</th>
							<th class="sticky top-0 z-10 bg-[color:var(--muted)] px-3 py-2">V_ini</th>
							<th class="sticky top-0 z-10 bg-[color:var(--muted)] px-3 py-2">V_fin</th>
							<th class="sticky top-0 z-10 bg-[color:var(--muted)] px-3 py-2">N_versos</th>
							<th class="sticky top-0 z-10 bg-[color:var(--muted)] px-3 py-2">Estrofa</th>
							<th class="sticky top-0 z-10 w-28 bg-[color:var(--muted)] px-3 py-2"><span class="sr-only">Acciones</span></th>
						</tr>
					</thead>
					<tbody>
						{#if filteredSecuencias.length === 0}
							<tr>
								<td class="px-3 py-4 text-[color:var(--muted-foreground)]" colspan={6}>
									Sin secuencias para este filtro.
								</td>
							</tr>
						{:else}
							{#each filteredSecuencias as secuencia, idx}
								<tr
									class={`border-t ${
										sequenceOverlapIds.has(secuencia.secuencia_id)
											? 'border-[color:var(--danger)] bg-red-50'
											: 'border-[color:var(--border)]'
									}`}
								>
									<td class="px-3 py-2">{idx + 1}</td>
									<td class="px-3 py-2">{secuencia.v_ini}</td>
									<td class="px-3 py-2">{secuencia.v_fin}</td>
									<td class="px-3 py-2">{secuencia.n_versos}</td>
									<td class="px-3 py-2">{termById(props.estrofaOptions, secuencia.estrofa_tipo_id)}</td>
									<td class="px-3 py-2">
										<div class="flex items-center justify-end gap-1">
											<button
												type="button"
												class="p-1 text-[color:var(--muted-foreground)] hover:text-[color:var(--success)] disabled:opacity-40"
												aria-label={props.readOnly ? 'Ver secuencia' : 'Editar secuencia'}
												onclick={() => requestOpenEdit(secuencia)}
												disabled={props.readOnly && !props.canComment}
											>
												{#if props.readOnly}<Eye size={16} />{:else}<Pencil size={16} />{/if}
											</button>
											<button
												type="button"
												class="p-1 text-[color:var(--muted-foreground)] hover:text-[color:var(--danger)] disabled:opacity-40"
												aria-label="Eliminar secuencia"
												onclick={() => openDelete(secuencia.secuencia_id)}
												disabled={props.readOnly}
											>
												<Trash2 size={16} />
											</button>
										</div>
									</td>
								</tr>
							{/each}
						{/if}
					</tbody>
				</table>
			</div>
		</div>
	</div>

	<div class="card grid p-4 sm:grid-cols-3 sm:divide-x sm:divide-[color:var(--border)]">
		<div class="px-3 py-1 sm:first:pl-0">
			<p class="text-xs text-[color:var(--muted-foreground)]">Total estructura</p>
			<p class="text-base font-semibold">
				{#if totalVersosEstructura === null}
					--
				{:else}
					{totalVersosEstructura}
				{/if}
			</p>
		</div>
		<div class="px-3 py-1">
			<p class="text-xs text-[color:var(--muted-foreground)]">Versos declarados (filtrado)</p>
			<p class="text-base font-semibold">{totalVersosDeclaradosFiltrados}</p>
		</div>
		<div class="px-3 py-1">
			<p class="text-xs text-[color:var(--muted-foreground)]">Diferencia</p>
			<p
				class={`text-base font-semibold ${
					diferenciaFiltrada === null
						? 'text-[color:var(--muted-foreground)]'
						: diferenciaFiltrada === 0
							? 'text-[color:var(--foreground)]'
							: 'text-[color:var(--danger)]'
				}`}
			>
				{#if diferenciaFiltrada === null}
					--
				{:else if diferenciaFiltrada > 0}
					+{diferenciaFiltrada}
				{:else}
					{diferenciaFiltrada}
				{/if}
			</p>
		</div>
	</div>
	<p class="text-xs text-[color:var(--muted-foreground)]">
		La suma de versos declarados se calcula solo sobre las secuencias visibles por los filtros activos.
	</p>
	<div class="space-y-2 lg:hidden">
		<div class="flex justify-start">
			<Button variant="primary" onclick={openSequenceSynopsisModal}>Leer sinopsis completa</Button>
		</div>
		{#if sidebarDirty}
			<p class="text-xs text-[color:var(--muted-foreground)]">
				La sinopsis completa refleja la última versión guardada mientras haya cambios pendientes en el panel lateral.
			</p>
		{/if}
	</div>
</section>

<SequenceSynopsisModal
	open={sequenceSynopsisModalOpen}
	groups={sequenceSynopsisGroups}
	totalSequences={secuencias.length}
	missingSynopsisCount={sequenceSynopsisMissingCount}
	showSavedVersionNote={sidebarDirty}
	onClose={closeSequenceSynopsisModal}
/>

{#if sidebarOpen}
	<!--
		**Dos contenedores para el mismo formulario.** El editor V2 no cabe en el panel lateral: es una
		rejilla verso a verso, las preguntas de cada unidad y las desviaciones, y trabajar ahí obliga a
		desplazarse tanto que se pierde de vista el pasaje. Por eso las obras abiertas al catálogo
		nuevo se anotan en el modal ancho, el mismo del editor de pruebas.

		Las demás siguen con el panel de siempre hasta que se migren. Durante ese tiempo hay más
		código, no menos, y es a propósito: no se interrumpe a quien está a mitad de una obra.
	-->
	{#if usaElEditorNuevo}
		<MetricSequenceModal
			titulo={editingId ? (props.readOnly ? 'Ver secuencia' : 'Editar secuencia') : 'Nueva secuencia'}
			rango={{ v_ini: Number(form.v_ini) || 1, v_fin: Number(form.v_fin) || 1 }}
			posicion={editingId && editingIndex >= 0
				? { indice: editingIndex + 1, total: orderedSecuencias.length }
				: null}
			alAnterior={() => void goToSecuencia(prevSecuencia)}
			alSiguiente={() => void goToSecuencia(nextSecuencia)}
			hayAnterior={Boolean(prevSecuencia)}
			haySiguiente={Boolean(nextSecuencia)}
			sucio={sidebarDirty}
			guardando={sidebarSaving}
			alEliminar={editingId && !props.readOnly ? () => openDelete(editingId as string) : null}
			alCerrar={requestCloseSidebar}
			alGuardar={() => void save()}
		>
			{#if propuestaDeLaAbierta || buscandoLaPropuesta}
				<div class="px-5 pt-4">
					<DeDondeVieneLaSecuencia
						propuesta={propuestaDeLaAbierta}
						cargando={buscandoLaPropuesta}
					/>
				</div>
			{/if}
			{#key editingId}
				<MetricSequenceEditor
					catalog={props.catalogoMetrico as MetricCatalogForEditor}
					initialDraft={borradorMetrico()}
					onStateChange={recibirEstadoMetrico}
					bodyExtra={restoDelFormulario}
				/>
			{/key}
		</MetricSequenceModal>
	{:else}
	<aside
		class="fixed right-0 top-0 z-40 h-screen w-full max-w-xl overflow-y-auto border-l border-[color:var(--border)] bg-[color:var(--gray-50)] px-5 pb-5 pt-0"
		inert={sidebarSaving}
		aria-busy={sidebarSaving}
	>
		<div class="sticky top-0 z-20 -mx-5 mb-4 flex items-center justify-between gap-3 border-b border-[color:var(--border)] bg-[color:var(--gray-50)] px-5 pb-3 pt-5">
			<div class="flex min-w-0 items-center gap-2">
				<h3 class="text-base font-semibold">
					{#if editingId}
						{props.readOnly ? 'Ver secuencia' : 'Editar secuencia'}
					{:else}
						Nueva secuencia
					{/if}
				</h3>
				{#if editingId && editingIndex >= 0}
					<div class="flex items-center gap-1">
						<button
							type="button"
							class="p-1 text-[color:var(--muted-foreground)] hover:text-[color:var(--foreground)] disabled:opacity-30"
							aria-label="Secuencia anterior"
							onclick={() => void goToSecuencia(prevSecuencia)}
							disabled={!prevSecuencia || sidebarSaving}
						>
							<ChevronLeft size={18} />
						</button>
						<span class="whitespace-nowrap text-sm text-[color:var(--muted-foreground)]">
							{editingIndex + 1} / {orderedSecuencias.length}
						</span>
						<button
							type="button"
							class="p-1 text-[color:var(--muted-foreground)] hover:text-[color:var(--foreground)] disabled:opacity-30"
							aria-label="Secuencia siguiente"
							onclick={() => void goToSecuencia(nextSecuencia)}
							disabled={!nextSecuencia || sidebarSaving}
						>
							<ChevronRight size={18} />
						</button>
					</div>
				{/if}
			</div>
			<div class="flex items-center gap-2">
				{#if sidebarDirty}
					<span class="text-xs text-[color:var(--muted-foreground)]">Cambios sin guardar</span>
				{/if}
				<Button variant="secondary" onclick={requestCloseSidebar} disabled={sidebarSaving}>Cerrar</Button>
				{#if !props.readOnly}
					<Button
						variant="success"
						onclick={() => void save()}
						loading={sidebarSaving}
						loadingLabel="Guardando…"
					>
						Guardar
					</Button>
				{/if}
			</div>
		</div>

		<div class="space-y-3">
			{@render metricaBase()}
			{@render restoDelFormulario()}
		</div>

		{#if editingId}
			<div class="mt-4">
				{#key editingId}
					<InternalCommentsPanel
						obraId={props.obraId}
						canComment={Boolean(props.canComment)}
						title="Comentarios internos de secuencia"
						context={{ secuencia_id: editingId }}
						collapsible={true}
						defaultCollapsed={true}
						collapseLabel="Ver"
						focusComentarioId={props.focusComentarioId}
						reloadKey={props.commentsReloadKey}
					/>
				{/key}
			</div>
		{/if}
	</aside>
	{/if}
	{/if}

	{#if deleteTargetId}
		<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
		<div class="card w-full max-w-md p-5">
			<h3 class="text-lg font-semibold">Eliminar secuencia</h3>
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">Esta acción no se puede deshacer.</p>
			<div class="mt-4 flex justify-end gap-2">
				<Button
					variant="secondary"
					onclick={() => (deleteTargetId = null)}
					disabled={deletingSequence}
				>
					Cancelar
				</Button>
				<Button
					variant="danger"
					disabled={props.readOnly}
					loading={deletingSequence}
					loadingLabel="Eliminando…"
					onclick={() => {
						if (!deleteTargetId) return;
						void remove(deleteTargetId);
					}}
				>
					Eliminar
				</Button>
			</div>
		</div>
	</div>
{/if}

<UnsavedChangesModal
	open={Boolean(pendingSidebarAction)}
	message={
		pendingSidebarAction?.kind === 'new'
			? 'La secuencia actual tiene cambios sin guardar. ¿Quieres guardarlos antes de crear otra?'
			: pendingSidebarAction?.kind === 'sequence'
				? 'La secuencia actual tiene cambios sin guardar. ¿Quieres guardarlos antes de cambiar de secuencia?'
				: 'La secuencia actual tiene cambios sin guardar. ¿Quieres guardarlos antes de cerrar?'
	}
	discardLabel="Continuar sin guardar"
	saving={sidebarSaving}
	onCancel={cancelPendingSidebarAction}
	onDiscard={discardAndContinue}
	onSave={saveAndContinue}
/>

<LocalDraftRecoveryModal
	open={Boolean(draftRecovery)}
	savedAt={draftRecovery?.draft.savedAt}
	onDiscard={discardLocalDraft}
	onRestore={restoreLocalDraft}
/>

<!--
	El cuerpo del formulario, partido en dos porque lo comparten dos contenedores.

	En una obra que todavía se anota con el vocabulario legado, el panel lateral pinta los dos
	seguidos. En una obra abierta al catálogo nuevo, **el editor V2 sustituye a `metricaBase`** y
	`restoDelFormulario` baja debajo de él: lo que no es métrico no cambia por cambiar de vocabulario.
-->
{#snippet metricaBase()}
			<section class="bg-white p-4">
				<h4 class="form-section-title">Métrica base</h4>
				<div class="grid gap-3 sm:grid-cols-2">
					<label class="form-field">
						<span class="form-label">Verso inicial</span>
						<input
							type="number"
							bind:value={form.v_ini}
							disabled={props.readOnly}
							class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
						/>
					</label>
					<label class="form-field">
						<span class="form-label">Verso final</span>
						<input
							type="number"
							bind:value={form.v_fin}
							disabled={props.readOnly}
							class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
						/>
					</label>
				</div>

				<label class="form-field mt-3">
					<span class="form-label">Estrofa</span>
					<CheckDropdown
						class="mt-1"
						multiple={false}
						hierarchical={true}
						collapsibleHierarchy={true}
						disableParentsWithChildren={true}
						showPathInTrigger={true}
						allowSingleClear
						search={true}
						placeholder="Pendiente — seleccionar"
						items={estrofaDropdownItems}
						selectedIds={form.estrofa_tipo_id ? [form.estrofa_tipo_id] : []}
						disabled={props.readOnly}
						onChange={(ids) => {
							const nextId = ids[0] ?? '';
							form = {
								...form,
								estrofa_tipo_id: nextId
							};
						}}
					/>
				</label>
			</section>
{/snippet}

{#snippet restoDelFormulario()}
			<CaracterizacionesPorRango
				bind:this={caracterizaciones}
				obraId={props.obraId}
				secuenciaId={editingId}
				rango={{ v_ini: Number(form.v_ini) || 1, v_fin: Number(form.v_fin) || 1 }}
				opciones={props.caracterizacionRangoOptions}
				readOnly={props.readOnly}
				onMetricaDirty={props.onMetricaDirty}
			/>

			<CaracterizacionesDeLaSecuencia
				valores={{
					intervencion_personajes_femeninos: form.intervencion_personajes_femeninos,
					intervencion_figuras_donaire: form.intervencion_figuras_donaire,
					intervencion_personajes_sobrenaturales: form.intervencion_personajes_sobrenaturales,
					versos_partidos: form.versos_partidos,
					inaugura_espacio: form.inaugura_espacio,
					evocacion_metrica: form.evocacion_metrica,
					evocacion_metrica_texto: form.evocacion_metrica_texto
				}}
				readOnly={props.readOnly}
				alCambiar={(cambio) => (form = { ...form, ...cambio })}
			/>

			<section class="bg-white p-4">
				<h4 class="form-section-title">Sinopsis argumental</h4>
				<label class="form-field">
					<span class="sr-only">Sinopsis argumental</span>
					<MarkdownEditorLite
						rows={3}
						class="mt-1"
						minHeightClass="min-h-28"
						value={form.sinopsis}
						disabled={props.readOnly}
						onChange={(nextValue) => {
							form = {
								...form,
								sinopsis: nextValue
							};
						}}
					/>
				</label>
			</section>

{/snippet}
