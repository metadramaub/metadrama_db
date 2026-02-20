<script lang="ts">
	import { onDestroy } from 'svelte';
	import type { Tables } from '$lib/types/database.types';
	import Button from '$lib/components/ui/button.svelte';
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import MarkdownEditorLite from '$lib/components/ui/markdown-editor-lite.svelte';
	import InternalCommentsPanel from '$lib/components/editor/InternalCommentsPanel.svelte';
	import { pushToast } from '$lib/stores/toast';

	const props = $props<{
		obraId: string;
		secuenciasInitial: Tables<'secuencias_metricas'>[];
		estrofaOptions: Array<
			Pick<Tables<'vocabularios'>, 'termino_id' | 'termino' | 'termino_padre_id' | 'orden'>
		>;
		certezaOptions: Array<Pick<Tables<'vocabularios'>, 'termino_id' | 'termino'>>;
		tipoVariacionOptions: Array<
			Pick<Tables<'vocabularios'>, 'termino_id' | 'termino' | 'termino_padre_id' | 'orden'>
		>;
		readOnly?: boolean;
		canComment?: boolean;
		onSecuenciasChange?: (items: Tables<'secuencias_metricas'>[]) => void;
	}>();

	type FormState = {
		v_ini: number;
		v_fin: number;
		estrofa_tipo_id: string;
		inaugura_espacio: boolean;
		versos_partidos: boolean;
		personajes_genero: 'mixto' | 'solo_masculino' | 'solo_femenino';
		personajes_donaire: 'ausente' | 'solo' | 'con_otros';
		personajes_sobrenatural: 'ausente' | 'solo' | 'con_otros';
		certeza_editor: string;
		observaciones: string;
	};

	type VariacionItem = {
		variacion_id: string;
		secuencia_id: string;
		tipo_variacion_id: string;
		tipo_variacion_term: string;
		tipo_variacion_parent_id: string | null;
		v_ini: number;
		v_fin: number;
		observaciones: string | null;
	};

	type VariacionFormState = {
		tipo_variacion_id: string;
		v_ini: number;
		v_fin: number;
		observaciones: string;
	};

	let secuencias = $state([...props.secuenciasInitial]);
	let sidebarOpen = $state(false);
	let editingId = $state<string | null>(null);
	let filtroEstrofa = $state('');
	let filtroCerteza = $state('');
	let deleteTargetId = $state<string | null>(null);
	let showCloseWithoutSavingModal = $state(false);

	let sidebarSaving = $state(false);
	let sidebarDirty = $state(false);
	let sidebarBaselineSnapshot = $state('');
	let autosaveErrorShown = $state(false);
	let lastSidebarSnapshot = $state('');
	let autosaveTimer: ReturnType<typeof setTimeout> | null = null;
	let variaciones = $state<VariacionItem[]>([]);
	let variacionesLoading = $state(false);
	let variacionesRequestCounter = $state(0);
	let variacionModalOpen = $state(false);
	let variacionModalSaving = $state(false);
	let variacionEditingId = $state<string | null>(null);
	let variacionDeleteTargetId = $state<string | null>(null);
	let variacionForm = $state<VariacionFormState>({
		tipo_variacion_id: '',
		v_ini: 1,
		v_fin: 1,
		observaciones: ''
	});

	function sortEstrofaOptions(options: typeof props.estrofaOptions) {
		return [...options].sort(
			(a, b) => (a.orden ?? Number.MAX_SAFE_INTEGER) - (b.orden ?? Number.MAX_SAFE_INTEGER) ||
				a.termino.localeCompare(b.termino, 'es')
		);
	}

	function sortTipoVariacionOptions(options: typeof props.tipoVariacionOptions) {
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

	const defaultCerteza = props.certezaOptions[0]?.termino_id ?? '';
	const defaultEstrofa = sortEstrofaOptions(props.estrofaOptions)[0]?.termino_id ?? '';
	const estrofaDropdownItems = $derived.by(() =>
		sortEstrofaOptions(props.estrofaOptions).map((option) => ({
			id: option.termino_id,
			label: option.termino,
			parentId: option.termino_padre_id ?? null
		}))
	);
	const tipoVariacionDropdownItems = $derived.by(() =>
		sortTipoVariacionOptions(props.tipoVariacionOptions).map((option) => ({
			id: option.termino_id,
			label: option.termino,
			parentId: option.termino_padre_id ?? null
		}))
	);
	const certezaDropdownItems = $derived(
		props.certezaOptions.map((option: Pick<Tables<'vocabularios'>, 'termino_id' | 'termino'>) => ({
			id: option.termino_id,
			label: option.termino
		}))
	);
	const personajesGeneroItems = [
		{ id: 'mixto', label: 'mixto' },
		{ id: 'solo_masculino', label: 'solo_masculino' },
		{ id: 'solo_femenino', label: 'solo_femenino' }
	];
	const personajesRolItems = [
		{ id: 'ausente', label: 'ausente' },
		{ id: 'solo', label: 'solo' },
		{ id: 'con_otros', label: 'con_otros' }
	];
	const tipoVariacionById = $derived.by(
		() =>
			new Map<string, Pick<Tables<'vocabularios'>, 'termino_id' | 'termino'>>(
				props.tipoVariacionOptions.map(
					(
						option: Pick<Tables<'vocabularios'>, 'termino_id' | 'termino'>
					): readonly [string, Pick<Tables<'vocabularios'>, 'termino_id' | 'termino'>] => [
						option.termino_id,
						option
					]
				)
			)
	);
	const irregularTipoVariacionId = $derived.by(() => {
		const parent = props.tipoVariacionOptions.find(
			(
				option: Pick<Tables<'vocabularios'>, 'termino_id' | 'termino' | 'termino_padre_id' | 'orden'>
			) => normalizeTerm(option.termino) === 'irregular'
		);
		return parent?.termino_id ?? null;
	});
	const selectedVariacionTipoTerm = $derived.by(() => {
		const term = tipoVariacionById.get(variacionForm.tipo_variacion_id)?.termino ?? '';
		return normalizeTerm(term);
	});
	const variacionRangeHelperText = $derived.by(() => {
		if (selectedVariacionTipoTerm === 'prosa') {
			return 'Indica entre qué versos aparece la prosa (no numerada). Ej: v_ini=56, v_fin=57 -> prosa entre verso 56 y 57.';
		}
		if (selectedVariacionTipoTerm === 'hipometrico' || selectedVariacionTipoTerm === 'hipermetrico') {
			return 'Esta variación aplica a un solo verso: usa el mismo número en V. ini y V. fin.';
		}
		if (
			selectedVariacionTipoTerm === 'cantado' ||
			selectedVariacionTipoTerm === 'rima_defectuosa' ||
			selectedVariacionTipoTerm === 'laguna'
		) {
			return 'Puedes marcar un solo verso (V. ini = V. fin) o un rango (V. ini < V. fin).';
		}
		return '';
	});

	function getSuggestedSecuenciaStart(): number {
		const maxVFin = secuencias.reduce((max, item) => Math.max(max, Number(item.v_fin) || 0), 0);
		return maxVFin > 0 ? maxVFin + 1 : 1;
	}

	function initialForm(): FormState {
		const suggestedStart = getSuggestedSecuenciaStart();
		return {
			v_ini: suggestedStart,
			v_fin: suggestedStart + 1,
			estrofa_tipo_id: defaultEstrofa,
			inaugura_espacio: false,
			versos_partidos: false,
			personajes_genero: 'mixto',
			personajes_donaire: 'ausente',
			personajes_sobrenatural: 'ausente',
			certeza_editor: defaultCerteza,
			observaciones: ''
		};
	}

	let form = $state<FormState>(initialForm());

	function getDefaultTipoVariacionId() {
		const firstSelectable = sortTipoVariacionOptions(props.tipoVariacionOptions).find(
			(option) => normalizeTerm(option.termino) !== 'irregular'
		);
		return firstSelectable?.termino_id ?? '';
	}

	function initialVariacionForm(): VariacionFormState {
		return {
			tipo_variacion_id: getDefaultTipoVariacionId(),
			v_ini: Number(form.v_ini) || 1,
			v_fin: Number(form.v_ini) || 1,
			observaciones: ''
		};
	}

	function termById(options: Array<Pick<Tables<'vocabularios'>, 'termino_id' | 'termino'>>, id: string | null) {
		if (!id) return '--';
		return options.find((option) => option.termino_id === id)?.termino ?? '--';
	}

	function variacionLabelById(tipoVariacionId: string, fallback = '') {
		const fromVocabulary = tipoVariacionById.get(tipoVariacionId)?.termino ?? '';
		return fromVocabulary || fallback || '--';
	}

	function truncateText(value: string | null, max = 80) {
		const source = (value ?? '').trim();
		if (!source) return '--';
		if (source.length <= max) return source;
		return `${source.slice(0, max - 1)}…`;
	}

	function sortVariaciones(items: VariacionItem[]) {
		return [...items].sort((a, b) => a.v_ini - b.v_ini || a.v_fin - b.v_fin);
	}

	function sortSecuencias(items: Tables<'secuencias_metricas'>[]) {
		return [...items].sort((a, b) => a.v_ini - b.v_ini);
	}

	function emitSecuenciasChange(nextItems: Tables<'secuencias_metricas'>[] = secuencias) {
		props.onSecuenciasChange?.(sortSecuencias(nextItems));
	}

	const filteredSecuencias = $derived.by(() => {
		return secuencias
			.filter((secuencia) => !filtroEstrofa || secuencia.estrofa_tipo_id === filtroEstrofa)
			.filter((secuencia) => !filtroCerteza || secuencia.certeza_editor === filtroCerteza)
			.sort((a, b) => a.v_ini - b.v_ini);
	});

	function clearAutosaveTimer() {
		if (!autosaveTimer) return;
		clearTimeout(autosaveTimer);
		autosaveTimer = null;
	}

	function sidebarSnapshot(): string {
		return JSON.stringify({
			sidebarOpen,
			id: editingId,
			v_ini: Number(form.v_ini),
			v_fin: Number(form.v_fin),
			estrofa_tipo_id: form.estrofa_tipo_id,
			inaugura_espacio: Boolean(form.inaugura_espacio),
			versos_partidos: Boolean(form.versos_partidos),
			personajes_genero: form.personajes_genero,
			personajes_donaire: form.personajes_donaire,
			personajes_sobrenatural: form.personajes_sobrenatural,
			certeza_editor: form.certeza_editor,
			observaciones: form.observaciones.trim()
		});
	}

	function setSidebarBaselineFromCurrent() {
		sidebarBaselineSnapshot = sidebarSnapshot();
		sidebarDirty = false;
		autosaveErrorShown = false;
		lastSidebarSnapshot = sidebarBaselineSnapshot;
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
		if (!Number.isFinite(Number(form.v_ini)) || !Number.isFinite(Number(form.v_fin)) || Number(form.v_ini) >= Number(form.v_fin)) {
			if (showToast) pushToast('error', 'Rango de versos inválido');
			return false;
		}
		if (!form.estrofa_tipo_id) {
			if (showToast) pushToast('error', 'Selecciona estrofa');
			return false;
		}
		if (!form.certeza_editor) {
			if (showToast) pushToast('error', 'Selecciona certeza');
			return false;
		}
		return true;
	}

	function handleAutosaveError(message: string) {
		if (autosaveErrorShown) return;
		autosaveErrorShown = true;
		pushToast('error', message);
	}

	function openNew() {
		if (props.readOnly) return;
		editingId = null;
		form = initialForm();
		variaciones = [];
		variacionDeleteTargetId = null;
		variacionModalOpen = false;
		sidebarOpen = true;
		showCloseWithoutSavingModal = false;
		setSidebarBaselineFromCurrent();
	}

	function openEdit(secuencia: Tables<'secuencias_metricas'>) {
		if (props.readOnly && !props.canComment) return;
		editingId = secuencia.secuencia_id;
		form = {
			v_ini: secuencia.v_ini,
			v_fin: secuencia.v_fin,
			estrofa_tipo_id: secuencia.estrofa_tipo_id ?? defaultEstrofa,
			inaugura_espacio: Boolean(secuencia.inaugura_espacio),
			versos_partidos: Boolean(secuencia.versos_partidos),
			personajes_genero: secuencia.personajes_genero as FormState['personajes_genero'],
			personajes_donaire: secuencia.personajes_donaire as FormState['personajes_donaire'],
			personajes_sobrenatural: secuencia.personajes_sobrenatural as FormState['personajes_sobrenatural'],
			certeza_editor: secuencia.certeza_editor,
			observaciones: secuencia.observaciones ?? ''
		};
		variaciones = [];
		variacionDeleteTargetId = null;
		variacionModalOpen = false;
		sidebarOpen = true;
		showCloseWithoutSavingModal = false;
		setSidebarBaselineFromCurrent();
		void loadVariacionesForCurrentSecuencia();
	}

	function performCloseSidebar() {
		clearAutosaveTimer();
		sidebarOpen = false;
		editingId = null;
		variaciones = [];
		variacionesLoading = false;
		variacionesRequestCounter += 1;
		variacionModalOpen = false;
		variacionEditingId = null;
		variacionDeleteTargetId = null;
		sidebarDirty = false;
		sidebarBaselineSnapshot = '';
		lastSidebarSnapshot = '';
		autosaveErrorShown = false;
		showCloseWithoutSavingModal = false;
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
		showCloseWithoutSavingModal = true;
	}

	function cancelCloseWithoutSaving() {
		showCloseWithoutSavingModal = false;
	}

	function confirmCloseWithoutSaving() {
		performCloseSidebar();
	}

	async function save(source: 'manual' | 'autosave' = 'manual') {
		if (props.readOnly || sidebarSaving || !sidebarOpen) return;
		const showToast = source === 'manual';
		if (!validateForm(showToast)) return;

		sidebarSaving = true;
		const currentId = editingId;
		const endpoint = currentId
			? `/api/obras/${props.obraId}/secuencias/${currentId}`
			: `/api/obras/${props.obraId}/secuencias`;
		const method = currentId ? 'PATCH' : 'POST';

		const response = await fetch(endpoint, {
			method,
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify(form)
		});
		sidebarSaving = false;

		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			const message = body.message ?? 'No se pudo guardar la secuencia';
			if (source === 'manual') {
				pushToast('error', message);
			} else {
				handleAutosaveError(message);
			}
			return;
		}

		const payload = await response.json();
		const savedSecuencia = payload.secuencia as Tables<'secuencias_metricas'>;
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
			void loadVariacionesForCurrentSecuencia();
		}

		form = {
			v_ini: savedSecuencia.v_ini,
			v_fin: savedSecuencia.v_fin,
			estrofa_tipo_id: savedSecuencia.estrofa_tipo_id ?? defaultEstrofa,
			inaugura_espacio: Boolean(savedSecuencia.inaugura_espacio),
			versos_partidos: Boolean(savedSecuencia.versos_partidos),
			personajes_genero: savedSecuencia.personajes_genero as FormState['personajes_genero'],
			personajes_donaire: savedSecuencia.personajes_donaire as FormState['personajes_donaire'],
			personajes_sobrenatural: savedSecuencia.personajes_sobrenatural as FormState['personajes_sobrenatural'],
			certeza_editor: savedSecuencia.certeza_editor,
			observaciones: savedSecuencia.observaciones ?? ''
		};

		setSidebarBaselineFromCurrent();
		autosaveErrorShown = false;
		if (source === 'manual') {
			pushToast('success', currentId ? 'Secuencia actualizada' : 'Secuencia creada');
			if (
				!currentId &&
				(filtroEstrofa || filtroCerteza) &&
				((filtroEstrofa && savedSecuencia.estrofa_tipo_id !== filtroEstrofa) ||
					(filtroCerteza && savedSecuencia.certeza_editor !== filtroCerteza))
			) {
				pushToast('info', 'Secuencia creada. Está oculta por los filtros actuales.');
			}
		}
	}

	function openDelete(secuenciaId: string) {
		if (props.readOnly) return;
		deleteTargetId = secuenciaId;
	}

	async function remove(secuenciaId: string) {
		if (props.readOnly) return;
		const response = await fetch(`/api/obras/${props.obraId}/secuencias/${secuenciaId}`, {
			method: 'DELETE'
		});
		if (!response.ok) {
			pushToast('error', 'No se pudo eliminar la secuencia');
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
	}

	async function loadVariacionesForCurrentSecuencia() {
		if (!editingId) {
			variaciones = [];
			return;
		}
		variacionesLoading = true;
		const requestId = ++variacionesRequestCounter;

		const response = await fetch(`/api/obras/${props.obraId}/secuencias/${editingId}/variaciones`);
		if (requestId !== variacionesRequestCounter) return;
		variacionesLoading = false;

		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudieron cargar las variaciones');
			return;
		}

		const payload = await response.json().catch(() => ({ items: [] }));
		variaciones = sortVariaciones((payload.items ?? []) as VariacionItem[]);
	}

	function validateVariacionForm(showToast = true) {
		if (!editingId) {
			if (showToast) pushToast('error', 'Guarda la secuencia antes de gestionar variaciones');
			return false;
		}
		if (!variacionForm.tipo_variacion_id) {
			if (showToast) pushToast('error', 'Selecciona un tipo de variacion');
			return false;
		}
		if (!tipoVariacionById.has(variacionForm.tipo_variacion_id)) {
			if (showToast) pushToast('error', 'El tipo de variacion seleccionado no es valido');
			return false;
		}

		const vIni = Number(variacionForm.v_ini);
		const vFin = Number(variacionForm.v_fin);
		if (!Number.isFinite(vIni) || !Number.isFinite(vFin)) {
			if (showToast) pushToast('error', 'Versos de variacion invalidos');
			return false;
		}
		if (vIni > vFin) {
			if (showToast) pushToast('error', 'El verso inicial no puede ser mayor que el final');
			return false;
		}
		if (vIni < Number(form.v_ini) || vFin > Number(form.v_fin)) {
			if (showToast) {
				pushToast(
					'error',
					`La variacion debe quedar dentro del rango de la secuencia (${form.v_ini}-${form.v_fin})`
				);
			}
			return false;
		}

		const tipoTerm = selectedVariacionTipoTerm;
		if (tipoTerm === 'irregular') {
			if (showToast) pushToast('error', 'El tipo irregular es solo agrupador');
			return false;
		}
		if (tipoTerm === 'prosa' && vIni >= vFin) {
			if (showToast) pushToast('error', 'En prosa, v_ini debe ser menor que v_fin');
			return false;
		}
		if ((tipoTerm === 'hipometrico' || tipoTerm === 'hipermetrico') && vIni !== vFin) {
			if (showToast) pushToast('error', 'Hipometrico e hipermetrico solo admiten un verso');
			return false;
		}

		return true;
	}

	function openVariacionCreateModal() {
		if (props.readOnly || !editingId) return;
		variacionEditingId = null;
		variacionForm = initialVariacionForm();
		variacionModalOpen = true;
	}

	function openVariacionEditModal(variacion: VariacionItem) {
		if (props.readOnly || !editingId) return;
		variacionEditingId = variacion.variacion_id;
		variacionForm = {
			tipo_variacion_id: variacion.tipo_variacion_id,
			v_ini: variacion.v_ini,
			v_fin: variacion.v_fin,
			observaciones: variacion.observaciones ?? ''
		};
		variacionModalOpen = true;
	}

	function closeVariacionModal() {
		if (variacionModalSaving) return;
		variacionModalOpen = false;
		variacionEditingId = null;
		variacionForm = initialVariacionForm();
	}

	async function saveVariacion() {
		if (props.readOnly || variacionModalSaving || !editingId) return;
		if (!validateVariacionForm(true)) return;

		variacionModalSaving = true;
		const isEditing = Boolean(variacionEditingId);
		const endpoint = isEditing
			? `/api/obras/${props.obraId}/secuencias/${editingId}/variaciones/${variacionEditingId}`
			: `/api/obras/${props.obraId}/secuencias/${editingId}/variaciones`;
		const method = isEditing ? 'PATCH' : 'POST';

		const response = await fetch(endpoint, {
			method,
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({
				tipo_variacion_id: variacionForm.tipo_variacion_id,
				v_ini: Number(variacionForm.v_ini),
				v_fin: Number(variacionForm.v_fin),
				observaciones: variacionForm.observaciones.trim() || null
			})
		});
		variacionModalSaving = false;

		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			const message =
				body.details?.[0]?.message ??
				body.message ??
				(isEditing ? 'No se pudo actualizar la variacion' : 'No se pudo crear la variacion');
			pushToast('error', message);
			return;
		}

		const payload = await response.json();
		const saved = payload.variacion as VariacionItem;
		if (isEditing && variacionEditingId) {
			variaciones = sortVariaciones(
				variaciones.map((item) => (item.variacion_id === variacionEditingId ? saved : item))
			);
		} else {
			variaciones = sortVariaciones([...variaciones, saved]);
		}

		closeVariacionModal();
		pushToast('success', isEditing ? 'Variacion actualizada' : 'Variacion creada');
	}

	function openVariacionDeleteModal(variacionId: string) {
		if (props.readOnly) return;
		variacionDeleteTargetId = variacionId;
	}

	function closeVariacionDeleteModal() {
		variacionDeleteTargetId = null;
	}

	async function removeVariacion(variacionId: string) {
		if (props.readOnly || !editingId) return;
		const response = await fetch(
			`/api/obras/${props.obraId}/secuencias/${editingId}/variaciones/${variacionId}`,
			{
				method: 'DELETE'
			}
		);
		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo eliminar la variacion');
			return;
		}
		variaciones = variaciones.filter((row) => row.variacion_id !== variacionId);
		variacionDeleteTargetId = null;
		pushToast('success', 'Variacion eliminada');
	}

	$effect(() => {
		const open = sidebarOpen;
		const readOnly = props.readOnly;
		const saving = sidebarSaving;
		const track = `${form.v_ini}|${form.v_fin}|${form.estrofa_tipo_id}|${form.inaugura_espacio}|${form.versos_partidos}|${form.personajes_genero}|${form.personajes_donaire}|${form.personajes_sobrenatural}|${form.certeza_editor}|${form.observaciones}|${editingId}`;
		void track;

		if (!open || readOnly) {
			sidebarDirty = false;
			clearAutosaveTimer();
			return;
		}

		const currentSnapshot = sidebarSnapshot();
		if (currentSnapshot !== lastSidebarSnapshot) {
			lastSidebarSnapshot = currentSnapshot;
			autosaveErrorShown = false;
		}

		sidebarDirty = currentSnapshot !== sidebarBaselineSnapshot;
		if (!sidebarDirty) {
			clearAutosaveTimer();
			return;
		}

		if (saving) return;

		if (!validateForm(false)) {
			clearAutosaveTimer();
			return;
		}

		clearAutosaveTimer();
		autosaveTimer = setTimeout(() => {
			void save('autosave');
		}, 10_000);
	});

	onDestroy(() => {
		clearAutosaveTimer();
	});
</script>

<section class="space-y-4">
	<div class="flex items-end justify-between gap-4">
		<div>
			<h2 class="text-xl font-semibold">Secuencias métricas</h2>
			<p class="text-sm text-[color:var(--muted-foreground)]">Ordenadas por verso inicial.</p>
		</div>
	</div>

	<div class="card grid gap-3 p-4 md:grid-cols-2">
		<div class="text-sm">
			<span class="mb-1 block">Filtro por estrofa</span>
			<CheckDropdown
				multiple={false}
				hierarchical={true}
				showPathInTrigger={true}
				allowSingleClear={true}
				search={true}
				placeholder="Todas"
				items={estrofaDropdownItems}
				selectedIds={filtroEstrofa ? [filtroEstrofa] : []}
				onChange={(ids) => {
					filtroEstrofa = ids[0] ?? '';
				}}
			/>
		</div>
		<label class="text-sm">
			<span class="mb-1 block">Filtro por certeza</span>
			<CheckDropdown
				multiple={false}
				allowSingleClear={true}
				search={certezaDropdownItems.length > 8}
				placeholder="Todas"
				items={certezaDropdownItems}
				selectedIds={filtroCerteza ? [filtroCerteza] : []}
				onChange={(ids) => {
					filtroCerteza = ids[0] ?? '';
				}}
			/>
		</label>
	</div>

	<div class="card overflow-x-auto">
		<table class="min-w-full text-left text-sm">
			<thead class="bg-[color:var(--muted)]">
				<tr>
					<th class="px-3 py-2">#</th>
					<th class="px-3 py-2">V_ini</th>
					<th class="px-3 py-2">V_fin</th>
					<th class="px-3 py-2">N_versos</th>
					<th class="px-3 py-2">Estrofa</th>
					<th class="px-3 py-2">Certeza</th>
					<th class="px-3 py-2">Acciones</th>
				</tr>
			</thead>
			<tbody>
				{#if filteredSecuencias.length === 0}
					<tr>
						<td class="px-3 py-4 text-[color:var(--muted-foreground)]" colspan={7}>
							Sin secuencias para este filtro.
						</td>
					</tr>
				{:else}
					{#each filteredSecuencias as secuencia, idx}
						<tr class="border-t border-[color:var(--border)]">
							<td class="px-3 py-2">{idx + 1}</td>
							<td class="px-3 py-2">{secuencia.v_ini}</td>
							<td class="px-3 py-2">{secuencia.v_fin}</td>
							<td class="px-3 py-2">{secuencia.n_versos}</td>
							<td class="px-3 py-2">{termById(props.estrofaOptions, secuencia.estrofa_tipo_id)}</td>
							<td class="px-3 py-2">{termById(props.certezaOptions, secuencia.certeza_editor)}</td>
							<td class="px-3 py-2">
								<div class="flex gap-2">
									<Button
										variant="ghost"
										onclick={() => openEdit(secuencia)}
										disabled={props.readOnly && !props.canComment}
										>{props.readOnly ? 'Ver' : 'Editar'}</Button
									>
									<Button variant="danger" onclick={() => openDelete(secuencia.secuencia_id)} disabled={props.readOnly}
										>Eliminar</Button
									>
								</div>
							</td>
						</tr>
					{/each}
				{/if}
			</tbody>
		</table>
	</div>

	<div class="flex justify-start">
		<Button variant="secondary" onclick={openNew} disabled={props.readOnly}>Nueva secuencia</Button>
	</div>
</section>

{#if sidebarOpen}
	<aside class="fixed right-0 top-0 z-40 h-screen w-full max-w-xl overflow-y-auto border-l border-[color:var(--border)] bg-[color:var(--gray-50)] p-5">
		<div class="sticky top-0 z-10 mb-4 flex items-center justify-between gap-3 bg-[color:var(--gray-50)] pb-3">
			<h3 class="text-lg font-semibold">
				{#if editingId}
					{props.readOnly ? 'Ver secuencia' : 'Editar secuencia'}
				{:else}
					Nueva secuencia
				{/if}
			</h3>
			<div class="flex items-center gap-2">
				<Button variant="secondary" onclick={requestCloseSidebar}>Cerrar</Button>
				{#if !props.readOnly}
					<Button variant="success" onclick={() => void save('manual')} disabled={sidebarSaving}>
						{sidebarSaving ? 'Guardando...' : 'Guardar'}
					</Button>
				{/if}
			</div>
		</div>

		<div class="grid gap-3">
			<div class="grid gap-3 sm:grid-cols-2">
				<label class="text-sm">
					<span class="mb-1 block">Verso inicial</span>
					<input
						type="number"
						bind:value={form.v_ini}
						disabled={props.readOnly}
						class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					/>
				</label>
				<label class="text-sm">
					<span class="mb-1 block">Verso final</span>
					<input
						type="number"
						bind:value={form.v_fin}
						disabled={props.readOnly}
						class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					/>
				</label>
			</div>

				<label class="text-sm">
					<span class="mb-1 block">Estrofa *</span>
				<CheckDropdown
					class="mt-1"
					multiple={false}
					hierarchical={true}
					showPathInTrigger={true}
					allowSingleClear={false}
					search={true}
					placeholder="Seleccionar estrofa"
					items={estrofaDropdownItems}
					selectedIds={form.estrofa_tipo_id ? [form.estrofa_tipo_id] : []}
					disabled={props.readOnly}
					onChange={(ids) => {
						const nextId = ids[0] ?? '';
						if (!nextId) return;
						form = {
							...form,
							estrofa_tipo_id: nextId
						};
					}}
					/>
				</label>

				<div class="rounded-md border border-[color:var(--border)] bg-white p-3">
					<div class="flex flex-wrap items-center justify-between gap-2">
						<h4 class="text-sm font-semibold">Variaciones / irregularidades</h4>
						<Button
							variant="secondary"
							onclick={openVariacionCreateModal}
							disabled={props.readOnly || !editingId}
						>
							Añadir variación
						</Button>
					</div>

					{#if !editingId}
						<p class="mt-2 text-xs text-[color:var(--muted-foreground)]">
							Guarda la secuencia para añadir variaciones.
						</p>
					{:else if variacionesLoading}
						<p class="mt-2 text-xs text-[color:var(--muted-foreground)]">Cargando variaciones...</p>
					{:else if variaciones.length === 0}
						<p class="mt-2 text-xs text-[color:var(--muted-foreground)]">
							Sin variaciones registradas en esta secuencia.
						</p>
					{:else}
						<div class="mt-3 overflow-x-auto">
							<table class="min-w-full text-left text-xs">
								<thead class="bg-[color:var(--muted)]">
									<tr>
										<th class="px-2 py-2">Tipo</th>
										<th class="px-2 py-2">V_ini</th>
										<th class="px-2 py-2">V_fin</th>
										<th class="px-2 py-2">Observaciones</th>
										<th class="px-2 py-2">Acciones</th>
									</tr>
								</thead>
								<tbody>
									{#each variaciones as variacion}
										<tr class="border-t border-[color:var(--border)]">
											<td class="px-2 py-2">
												{variacionLabelById(variacion.tipo_variacion_id, variacion.tipo_variacion_term)}
											</td>
											<td class="px-2 py-2">{variacion.v_ini}</td>
											<td class="px-2 py-2">{variacion.v_fin}</td>
											<td class="max-w-[18rem] px-2 py-2">
												<span class="block truncate text-[color:var(--muted-foreground)]">
													{truncateText(variacion.observaciones)}
												</span>
											</td>
											<td class="px-2 py-2">
												<div class="flex gap-2">
													<Button
														variant="ghost"
														onclick={() => openVariacionEditModal(variacion)}
														disabled={props.readOnly}
													>
														Editar
													</Button>
													<Button
														variant="danger"
														onclick={() => openVariacionDeleteModal(variacion.variacion_id)}
														disabled={props.readOnly}
													>
														Eliminar
													</Button>
												</div>
											</td>
										</tr>
									{/each}
								</tbody>
							</table>
						</div>
					{/if}
				</div>

				<div class="grid gap-3 sm:grid-cols-2">
				<label class="text-sm">
					<span class="mb-1 block">Personajes género</span>
					<CheckDropdown
						multiple={false}
						search={false}
						placeholder="Seleccionar género"
						items={personajesGeneroItems}
						disabled={props.readOnly}
						selectedIds={[form.personajes_genero]}
						onChange={(ids) => {
							const nextGenero = ids[0] as FormState['personajes_genero'] | undefined;
							if (!nextGenero) return;
							form = {
								...form,
								personajes_genero: nextGenero
							};
						}}
					/>
				</label>
				<label class="text-sm">
					<span class="mb-1 block">Donaire</span>
					<CheckDropdown
						multiple={false}
						search={false}
						placeholder="Seleccionar valor"
						items={personajesRolItems}
						disabled={props.readOnly}
						selectedIds={[form.personajes_donaire]}
						onChange={(ids) => {
							const nextDonaire = ids[0] as FormState['personajes_donaire'] | undefined;
							if (!nextDonaire) return;
							form = {
								...form,
								personajes_donaire: nextDonaire
							};
						}}
					/>
				</label>
				<label class="text-sm">
					<span class="mb-1 block">Sobrenatural</span>
					<CheckDropdown
						multiple={false}
						search={false}
						placeholder="Seleccionar valor"
						items={personajesRolItems}
						disabled={props.readOnly}
						selectedIds={[form.personajes_sobrenatural]}
						onChange={(ids) => {
							const nextSobrenatural = ids[0] as FormState['personajes_sobrenatural'] | undefined;
							if (!nextSobrenatural) return;
							form = {
								...form,
								personajes_sobrenatural: nextSobrenatural
							};
						}}
					/>
				</label>
				<label class="text-sm sm:col-span-2">
					<span class="mb-1 block">Certeza</span>
					<CheckDropdown
						multiple={false}
						search={certezaDropdownItems.length > 8}
						placeholder="Seleccionar certeza"
						items={certezaDropdownItems}
						disabled={props.readOnly}
						selectedIds={form.certeza_editor ? [form.certeza_editor] : []}
						onChange={(ids) => {
							const nextCerteza = ids[0] ?? '';
							if (!nextCerteza) return;
							form = {
								...form,
								certeza_editor: nextCerteza
							};
						}}
					/>
				</label>
			</div>

			<div class="text-sm">
				<span class="mb-1 block">Versos partidos</span>
				<label class="inline-flex items-center gap-2">
					<input
						type="checkbox"
						checked={form.versos_partidos}
						disabled={props.readOnly}
						onchange={(event) => {
							form = {
								...form,
								versos_partidos: event.currentTarget.checked
							};
						}}
					/>
					<span class="text-[color:var(--muted-foreground)]">
						{form.versos_partidos ? 'Si' : 'No'}
					</span>
				</label>
			</div>

			<label class="text-sm">
				<span class="mb-1 block">Observaciones públicas</span>
				<MarkdownEditorLite
					rows={3}
					class="mt-1"
					minHeightClass="min-h-28"
					value={form.observaciones}
					disabled={props.readOnly}
					onChange={(nextValue) => {
						form = {
							...form,
							observaciones: nextValue
						};
					}}
				/>
			</label>
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
						collapseLabel="Ver comentarios"
					/>
				{/key}
			</div>
		{/if}
	</aside>
	{/if}

	{#if variacionModalOpen}
		<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
			<div class="card w-full max-w-2xl p-5">
				<h3 class="text-lg font-semibold">
					{variacionEditingId ? 'Editar variación' : 'Añadir variación'}
				</h3>
				<div class="mt-3 grid gap-3">
					<label class="text-sm">
						<span class="mb-1 block">Tipo *</span>
						<CheckDropdown
							multiple={false}
							hierarchical={true}
							showPathInTrigger={true}
							allowSingleClear={false}
							search={tipoVariacionDropdownItems.length > 8}
							placeholder="Seleccionar tipo"
							items={tipoVariacionDropdownItems}
							disabled={props.readOnly || variacionModalSaving}
							disabledIds={irregularTipoVariacionId ? [irregularTipoVariacionId] : []}
							selectedIds={variacionForm.tipo_variacion_id ? [variacionForm.tipo_variacion_id] : []}
							onChange={(ids) => {
								const nextId = ids[0] ?? '';
								if (!nextId) return;
								variacionForm = {
									...variacionForm,
									tipo_variacion_id: nextId
								};
							}}
						/>
					</label>

					<div class="grid gap-3 sm:grid-cols-2">
						<label class="text-sm">
							<span class="mb-1 block">V. ini *</span>
							<input
								type="number"
								bind:value={variacionForm.v_ini}
								disabled={props.readOnly || variacionModalSaving}
								class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
							/>
						</label>
						<label class="text-sm">
							<span class="mb-1 block">V. fin *</span>
							<input
								type="number"
								bind:value={variacionForm.v_fin}
								disabled={props.readOnly || variacionModalSaving}
								class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
							/>
						</label>
					</div>

										{#if variacionRangeHelperText}
						<p class="rounded-md border border-[color:var(--border)] bg-[color:var(--muted)] px-3 py-2 text-xs text-[color:var(--muted-foreground)]">
							{variacionRangeHelperText}
						</p>
					{/if}

					<label class="text-sm">
						<span class="mb-1 block">Observaciones</span>
						<MarkdownEditorLite
							rows={3}
							class="mt-1"
							minHeightClass="min-h-24"
							value={variacionForm.observaciones}
							disabled={props.readOnly || variacionModalSaving}
							onChange={(nextValue) => {
								variacionForm = {
									...variacionForm,
									observaciones: nextValue
								};
							}}
						/>
					</label>
				</div>
				<div class="mt-4 flex justify-end gap-2">
					<Button variant="secondary" onclick={closeVariacionModal}>Cancelar</Button>
					<Button
						variant="success"
						disabled={props.readOnly || variacionModalSaving}
						onclick={() => void saveVariacion()}
					>
						{variacionModalSaving ? 'Guardando...' : 'Guardar'}
					</Button>
				</div>
			</div>
		</div>
	{/if}

	{#if variacionDeleteTargetId}
		<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
			<div class="card w-full max-w-md p-5">
				<h3 class="text-lg font-semibold">Eliminar variación</h3>
				<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">Esta acción no se puede deshacer.</p>
				<div class="mt-4 flex justify-end gap-2">
					<Button variant="secondary" onclick={closeVariacionDeleteModal}>Cancelar</Button>
					<Button
						variant="danger"
						disabled={props.readOnly}
						onclick={() => {
							if (!variacionDeleteTargetId) return;
							void removeVariacion(variacionDeleteTargetId);
						}}
					>
						Eliminar
					</Button>
				</div>
			</div>
		</div>
	{/if}

	{#if deleteTargetId}
		<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
		<div class="card w-full max-w-md p-5">
			<h3 class="text-lg font-semibold">Eliminar secuencia</h3>
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">Esta acción no se puede deshacer.</p>
			<div class="mt-4 flex justify-end gap-2">
				<Button variant="secondary" onclick={() => (deleteTargetId = null)}>Cancelar</Button>
				<Button
					variant="danger"
					disabled={props.readOnly}
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

{#if showCloseWithoutSavingModal}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
		<div class="card w-full max-w-md p-5">
			<h3 class="text-lg font-semibold">Cambios sin guardar</h3>
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">Hay cambios sin guardar en este panel.</p>
			<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">Si continúas, perderás los cambios no guardados.</p>
			<div class="mt-4 flex justify-end gap-2">
				<Button variant="secondary" onclick={cancelCloseWithoutSaving}>Seguir editando</Button>
				<Button variant="danger" onclick={confirmCloseWithoutSaving}>Cerrar sin guardar</Button>
			</div>
		</div>
	</div>
{/if}

