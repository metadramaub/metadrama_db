<script lang="ts">
	import { invalidateAll } from '$app/navigation';
	import { untrack } from 'svelte';
	import ChevronLeft from 'lucide-svelte/icons/chevron-left';
	import ChevronRight from 'lucide-svelte/icons/chevron-right';
	import Pencil from 'lucide-svelte/icons/pencil';
	import Trash2 from 'lucide-svelte/icons/trash-2';
	import Button from '$lib/components/ui/button.svelte';
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import CollapsibleGroup from '$lib/components/ui/collapsible-group.svelte';
	import RangeConsistencyAlert from '$lib/components/editor/RangeConsistencyAlert.svelte';
	import UnsavedChangesModal from '$lib/components/editor/UnsavedChangesModal.svelte';
	import {
		analyzeSequenceRangeConsistency,
		collectRangeConsistencyIds
	} from '$lib/utils/range-consistency';
	import type {
		MetricCatalogConfiguration,
		MetricCatalogDomainRow,
		MetricCatalogForEditor,
		MetricCatalogForm,
		MetricCatalogPageData
	} from '$lib/metrica/catalogo';
	import { metricFormLabel } from '$lib/metrica/catalogo';
	import { pushToast } from '$lib/stores/toast';
	import MetricSandboxLegacyFields from './MetricSandboxLegacyFields.svelte';
	import MetricSequenceEditor from './MetricSequenceEditor.svelte';
	import type { MetricUnitDraft } from './editor-model';
	import { draftFromRows } from './sequence-draft';
	import type {
		MetricDeviationDraft,
		MetricSequenceDraft,
		MetricSequenceEditorState
	} from './sequence-draft';

	/**
	 * Laboratorio del editor de secuencias. Todo lo de este archivo es desechable: los
	 * escenarios de prueba, la tabla que los recorre, la réplica del panel de producción y
	 * las llamadas a `/api/metrica/editor-pruebas`. El formulario en sí vive en
	 * `MetricSequenceEditor`, que no sabe nada de esto y se moverá tal cual al editor de obras.
	 */
	const props = $props<{ data: MetricCatalogPageData }>();

	type PendingSequenceAction =
		| { kind: 'close' }
		| { kind: 'new' }
		| { kind: 'open'; target: MetricCatalogDomainRow };

	let selectedScenarioId = $state<string | null>(
		untrack(() => String(props.data.editorSandbox.scenarios[0]?.escenario_id ?? '') || null)
	);
	let showNewScenario = $state(false);
	let scenarioName = $state('');
	let scenarioDescription = $state('');
	let scenarioSaving = $state(false);
	let sequenceSaving = $state(false);
	/** El borrador de partida. El editor se queda con él y devuelve el vivo. */
	let openDraft = $state<MetricSequenceDraft | null>(null);
	/** Cambia con cada apertura para remontar el editor con el borrador nuevo. */
	let openToken = $state(0);
	let editorState = $state<MetricSequenceEditorState | null>(null);
	let baselineToken = $state(-1);
	let draftBaseline = $state('');
	let errorMessage = $state('');
	let formFilter = $state('');
	let formFilterDraft = $state('');
	let pendingAction = $state<PendingSequenceAction | null>(null);

	/**
	 * El resto del formulario de secuencia tal como está en producción. Se ve siempre: el
	 * editor está obligado a rellenarlo, y la prueba consiste justamente en comprobar
	 * cuánto ocupa la parte métrica dentro del panel completo. Que en el laboratorio no
	 * guarde nada no es motivo para esconderlo.
	 */
	const LEGACY_RAIL_ITEMS = [
		// Las tres caracterizaciones —por rango, personajes y las demás— son un solo destino:
		// se rellenan seguidas y separarlas en el mapa alarga el menú sin orientar mejor.
		{ id: 'caracterizaciones', label: 'Caracterizaciones y personajes' },
		{ id: 'sinopsis', label: 'Sinopsis argumental' },
		{ id: 'comentarios', label: 'Comentarios internos' }
	];

	/** El catálogo que necesita el editor: sin escenarios, sin estadísticas, sin demarcador. */
	const catalog = $derived<MetricCatalogForEditor>({
		forms: props.data.forms,
		configurations: props.data.configurations,
		lengthRules: props.data.lengthRules,
		domain: props.data.domain
	});

	const scenarios = $derived(props.data.editorSandbox.scenarios);
	const selectedScenario = $derived(
		scenarios.find(
			(row: MetricCatalogDomainRow) => String(row.escenario_id) === selectedScenarioId
		) ?? null
	);
	const scenarioSequences = $derived(
		props.data.editorSandbox.sequences
			.filter((row: MetricCatalogDomainRow) => String(row.escenario_id) === selectedScenarioId)
			.sort(
				(a: MetricCatalogDomainRow, b: MetricCatalogDomainRow) => Number(a.orden) - Number(b.orden)
			)
	);
	const activeForms = $derived(
		props.data.forms
			.filter((form: MetricCatalogForm) => form.activo)
			.sort((a: MetricCatalogForm, b: MetricCatalogForm) => a.nombre.localeCompare(b.nombre, 'es'))
	);

	const orderedSequences = $derived(
		[...scenarioSequences].sort(
			(a: MetricCatalogDomainRow, b: MetricCatalogDomainRow) =>
				Number(a.v_ini) - Number(b.v_ini) || Number(a.v_fin) - Number(b.v_fin)
		)
	);
	const filteredSequences = $derived(
		formFilter
			? orderedSequences.filter((row: MetricCatalogDomainRow) => String(row.forma_id) === formFilter)
			: orderedSequences
	);
	const formFilterItems = $derived(
		activeForms.map((form: MetricCatalogForm) => ({ id: form.forma_id, label: metricFormLabel(form) }))
	);
	const sequenceOverlapIssues = $derived(
		analyzeSequenceRangeConsistency(
			orderedSequences.map((row: MetricCatalogDomainRow) => ({
				secuencia_id: String(row.secuencia_prueba_id),
				v_ini: Number(row.v_ini),
				v_fin: Number(row.v_fin)
			}))
		)
	);
	const sequenceOverlapIds = $derived(collectRangeConsistencyIds(sequenceOverlapIssues));
	const scenarioLastVerse = $derived(
		orderedSequences.reduce(
			(maximum: number, row: MetricCatalogDomainRow) => Math.max(maximum, Number(row.v_fin)),
			0
		)
	);
	const declaredVerses = $derived(
		filteredSequences.reduce(
			(total: number, row: MetricCatalogDomainRow) =>
				total + (Number(row.v_fin) - Number(row.v_ini) + 1),
			0
		)
	);
	const versesDifference = $derived(
		scenarioLastVerse === 0 ? null : scenarioLastVerse - declaredVerses
	);

	const liveDraft = $derived(editorState?.draft ?? null);
	const draftDirty = $derived(
		liveDraft !== null && draftBaseline !== '' && JSON.stringify(liveDraft) !== draftBaseline
	);
	const editingIndex = $derived(
		openDraft?.secuencia_prueba_id
			? orderedSequences.findIndex(
					(row: MetricCatalogDomainRow) =>
						String(row.secuencia_prueba_id) === openDraft?.secuencia_prueba_id
				)
			: -1
	);
	const previousSequence = $derived(editingIndex > 0 ? orderedSequences[editingIndex - 1] : null);
	const nextSequence = $derived(
		editingIndex >= 0 && editingIndex < orderedSequences.length - 1
			? orderedSequences[editingIndex + 1]
			: null
	);

	$effect(() => {
		if (
			selectedScenarioId &&
			!scenarios.some(
				(row: MetricCatalogDomainRow) => String(row.escenario_id) === selectedScenarioId
			)
		) {
			selectedScenarioId = String(scenarios[0]?.escenario_id ?? '') || null;
		}
	});

	/**
	 * El editor avisa de su estado en cada cambio. La primera vez tras abrir fija la
	 * referencia para saber si hay cambios sin guardar: es su borrador ya normalizado, no el
	 * crudo que se le pasó, así que abrir una secuencia no la marca como sucia.
	 */
	function handleEditorState(state: MetricSequenceEditorState) {
		editorState = state;
		if (baselineToken !== openToken) {
			draftBaseline = JSON.stringify(state.draft);
			baselineToken = openToken;
		}
	}

	function cleanText(value: string): string | null {
		const cleaned = value.trim();
		return cleaned || null;
	}

	function formLabel(id: string): string {
		return props.data.forms.find((form: MetricCatalogForm) => form.forma_id === id)?.nombre ?? id;
	}

	function configurationLabel(id: string): string {
		return (
			props.data.configurations.find(
				(configuration: MetricCatalogConfiguration) => configuration.arquitectura_id === id
			)?.nombre ?? id
		);
	}

	function openNewSequence() {
		if (!selectedScenarioId) return;
		const previous = scenarioSequences.at(-1);
		const nextVerse = previous ? Number(previous.v_fin) + 1 : 1;
		openDraft = {
			secuencia_prueba_id: null,
			escenario_id: selectedScenarioId,
			// El laboratorio nunca anota una secuencia real: eso es la anotación en sombra.
			secuencia_id: null,
			orden:
				scenarioSequences.reduce(
					(max: number, row: MetricCatalogDomainRow) => Math.max(max, Number(row.orden)),
					0
				) + 1,
			v_ini: nextVerse,
			v_fin: nextVerse,
			forma_id: '',
			arquitectura_id: '',
			observaciones: '',
			unidades: [],
			elecciones: [],
			desviaciones: []
		};
		openToken += 1;
		errorMessage = '';
	}

	function openSequence(row: MetricCatalogDomainRow) {
		openDraft = draftFromRows(row, {
			units: props.data.editorSandbox.units,
			choices: props.data.editorSandbox.choices,
			deviations: props.data.editorSandbox.deviations
		});
		openToken += 1;
		errorMessage = '';
	}

	/**
	 * Salir de una secuencia con cambios pendientes pregunta antes, como en producción: es
	 * parte de lo que se está midiendo, porque el formulario nuevo es mucho más largo.
	 */
	function requestNewSequence() {
		if (draftDirty) {
			pendingAction = { kind: 'new' };
			return;
		}
		openNewSequence();
	}

	function requestOpenSequence(row: MetricCatalogDomainRow) {
		if (String(row.secuencia_prueba_id) === openDraft?.secuencia_prueba_id) return;
		if (draftDirty) {
			pendingAction = { kind: 'open', target: row };
			return;
		}
		openSequence(row);
	}

	function closeSequence() {
		openDraft = null;
		editorState = null;
		draftBaseline = '';
	}

	function requestCloseSequence() {
		if (draftDirty) {
			pendingAction = { kind: 'close' };
			return;
		}
		closeSequence();
	}

	function runPendingAction() {
		const action = pendingAction;
		pendingAction = null;
		if (!action) return;
		if (action.kind === 'close') closeSequence();
		else if (action.kind === 'new') openNewSequence();
		else openSequence(action.target);
	}

	async function savePendingAction() {
		await saveSequence();
		if (errorMessage) return;
		runPendingAction();
	}

	async function callApi(body: Record<string, unknown>) {
		const response = await fetch('/api/metrica/editor-pruebas', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify(body)
		});
		const payload = await response.json().catch(() => ({}));
		if (!response.ok) {
			throw new Error(payload.message ?? 'No se pudo completar la operación.');
		}
		return payload;
	}

	async function createScenario() {
		if (!scenarioName.trim() || scenarioSaving) return;
		scenarioSaving = true;
		errorMessage = '';
		try {
			const payload = await callApi({
				action: 'create_scenario',
				nombre: scenarioName.trim(),
				descripcion: cleanText(scenarioDescription)
			});
			selectedScenarioId = String(payload.scenario.escenario_id);
			scenarioName = '';
			scenarioDescription = '';
			showNewScenario = false;
			pushToast('success', 'Escenario de prueba creado.');
			await invalidateAll();
		} catch (error) {
			errorMessage = error instanceof Error ? error.message : 'No se pudo crear el escenario.';
		} finally {
			scenarioSaving = false;
		}
	}

	async function deleteScenario() {
		if (!selectedScenarioId || !selectedScenario || scenarioSaving) return;
		if (
			!window.confirm(
				`¿Eliminar el escenario «${String(selectedScenario.nombre)}» y todas sus pruebas?`
			)
		) {
			return;
		}
		scenarioSaving = true;
		try {
			await callApi({ action: 'delete_scenario', escenario_id: selectedScenarioId });
			selectedScenarioId = null;
			closeSequence();
			pushToast('success', 'Escenario eliminado.');
			await invalidateAll();
		} catch (error) {
			errorMessage = error instanceof Error ? error.message : 'No se pudo eliminar el escenario.';
		} finally {
			scenarioSaving = false;
		}
	}

	async function saveSequence() {
		const draft = liveDraft;
		// Ojo: `error` es nulo cuando la secuencia está lista, así que no vale `??`.
		const validation = editorState ? editorState.error : 'No hay ninguna secuencia abierta.';
		if (validation || !draft || sequenceSaving) {
			if (validation) errorMessage = validation;
			return;
		}
		sequenceSaving = true;
		errorMessage = '';
		try {
			const payload = await callApi({
				action: 'save_sequence',
				...draft,
				arquitectura_id: draft.arquitectura_id || null,
				observaciones: cleanText(draft.observaciones),
				unidades: draft.unidades.map((unit: MetricUnitDraft) => ({
					...unit,
					etiqueta: cleanText(unit.etiqueta),
					observaciones: cleanText(unit.observaciones)
				})),
				desviaciones: draft.desviaciones.map((deviation: MetricDeviationDraft) => ({
					...deviation,
					observaciones: cleanText(deviation.observaciones)
				}))
			});
			draft.secuencia_prueba_id = String(payload.secuencia_prueba_id);
			draftBaseline = JSON.stringify(draft);
			pushToast('success', 'Secuencia métrica de prueba guardada.');
			await invalidateAll();
		} catch (error) {
			errorMessage = error instanceof Error ? error.message : 'No se pudo guardar la secuencia.';
		} finally {
			sequenceSaving = false;
		}
	}

	async function deleteSequenceById(sequenceId: string) {
		if (!sequenceId || sequenceSaving) return;
		if (!window.confirm('¿Eliminar esta secuencia métrica de prueba?')) return;
		sequenceSaving = true;
		try {
			await callApi({ action: 'delete_sequence', secuencia_prueba_id: sequenceId });
			if (openDraft?.secuencia_prueba_id === sequenceId) closeSequence();
			pushToast('success', 'Secuencia de prueba eliminada.');
			await invalidateAll();
		} catch (error) {
			errorMessage = error instanceof Error ? error.message : 'No se pudo eliminar la secuencia.';
		} finally {
			sequenceSaving = false;
		}
	}
</script>

<section class="space-y-5">
	<div class="border-l-4 border-sky-500 bg-sky-50 p-5 text-sm leading-6 text-sky-950">
		<h2 class="font-semibold">Laboratorio del editor de secuencias</h2>
		<p class="mt-1 max-w-5xl">
			Estos escenarios no son obras y no aparecen en el dashboard de producción. El formulario
			métrico es el mismo componente que se llevará al editor de obras cuando se apruebe; lo
			que cambia aquí es solo la ventana que lo abre. El resto de la secuencia
			—caracterizaciones, intervención de personajes, sinopsis— se ve entero y en su sitio,
			marcado como «réplica»: no guarda nada todavía, pero ocupa lo que ocupará en
			producción, que es lo que hay que poder juzgar.
		</p>
	</div>

	<div
		class="flex flex-col gap-3 border border-[color:var(--border)] bg-[color:var(--card)] p-4 lg:flex-row lg:items-end"
	>
		<label class="min-w-0 flex-1">
			<span class="form-label">Escenario de prueba</span>
			<select
				class="mt-1 h-10 w-full border border-[color:var(--border)] bg-white px-3 text-sm"
				value={selectedScenarioId ?? ''}
				onchange={(event) => {
					selectedScenarioId = event.currentTarget.value || null;
					closeSequence();
				}}
			>
				<option value="">Seleccionar escenario</option>
				{#each scenarios as scenario (String(scenario.escenario_id))}
					<option value={String(scenario.escenario_id)}>{String(scenario.nombre)}</option>
				{/each}
			</select>
		</label>
		<div class="flex gap-2">
			<Button variant="secondary" onclick={() => (showNewScenario = !showNewScenario)}>
				{showNewScenario ? 'Cancelar' : 'Nuevo escenario'}
			</Button>
			{#if selectedScenario}
				<Button variant="danger" onclick={deleteScenario} disabled={scenarioSaving}>
					Eliminar escenario
				</Button>
			{/if}
		</div>
	</div>

	{#if showNewScenario}
		<div class="grid gap-3 border border-[color:var(--border)] bg-[color:var(--card)] p-4">
			<label class="form-field">
				<span class="form-label">Nombre *</span>
				<input class="h-10 border border-[color:var(--border)] px-3" bind:value={scenarioName} />
			</label>
			<label class="form-field">
				<span class="form-label">Qué quieres comprobar</span>
				<textarea
					class="min-h-24 border border-[color:var(--border)] p-3"
					bind:value={scenarioDescription}
				></textarea>
			</label>
			<div>
				<Button
					variant="success"
					onclick={createScenario}
					disabled={scenarioSaving || !scenarioName.trim()}
				>
					{scenarioSaving ? 'Creando…' : 'Crear escenario'}
				</Button>
			</div>
		</div>
	{/if}

	{#if errorMessage && !openDraft}
		<p class="border-l-4 border-red-500 bg-red-50 p-3 text-sm text-red-900">{errorMessage}</p>
	{/if}

	{#if selectedScenario}
		<div class="flex flex-wrap items-end justify-between gap-3 pb-1 pt-2">
			<div>
				<h3 class="text-lg font-semibold">Secuencias métricas</h3>
				<p class="text-xs text-[color:var(--muted-foreground)]">
					{String(selectedScenario.nombre)} · {orderedSequences.length}
					{orderedSequences.length === 1 ? 'secuencia' : 'secuencias'}
				</p>
			</div>
			<div class="flex flex-wrap items-end gap-2">
				<div class="w-56">
					<CheckDropdown
						multiple={false}
						search={true}
						allowSingleClear={true}
						closeOnSelect={false}
						placeholder="Filtrar por forma"
						items={formFilterItems}
						selectedIds={formFilterDraft ? [formFilterDraft] : []}
						onChange={(ids) => {
							formFilterDraft = ids[0] ?? '';
						}}
					/>
				</div>
				<Button variant="secondary" onclick={() => (formFilter = formFilterDraft)}>Filtrar</Button>
				<Button
					variant="ghost"
					onclick={() => {
						formFilterDraft = '';
						formFilter = '';
					}}
					disabled={!formFilter && !formFilterDraft}
				>
					Limpiar
				</Button>
				<Button variant="primary-soft" onclick={requestNewSequence}>Nueva secuencia</Button>
			</div>
		</div>

		<RangeConsistencyAlert issues={sequenceOverlapIssues} />

		<div class="card overflow-x-auto">
			<table class="min-w-full text-left text-sm">
				<thead class="bg-[color:var(--muted)]">
					<tr>
						<th class="sticky top-0 z-10 bg-[color:var(--muted)] px-3 py-2">#</th>
						<th class="sticky top-0 z-10 bg-[color:var(--muted)] px-3 py-2">V_ini</th>
						<th class="sticky top-0 z-10 bg-[color:var(--muted)] px-3 py-2">V_fin</th>
						<th class="sticky top-0 z-10 bg-[color:var(--muted)] px-3 py-2">N_versos</th>
						<th class="sticky top-0 z-10 bg-[color:var(--muted)] px-3 py-2">Forma</th>
						<th class="sticky top-0 z-10 w-28 bg-[color:var(--muted)] px-3 py-2">
							<span class="sr-only">Acciones</span>
						</th>
					</tr>
				</thead>
				<tbody>
					{#each filteredSequences as sequence, index (String(sequence.secuencia_prueba_id))}
						<tr
							class={`border-t ${
								sequenceOverlapIds.has(String(sequence.secuencia_prueba_id))
									? 'border-[color:var(--danger)] bg-red-50'
									: 'border-[color:var(--border)]'
							} ${
								openDraft?.secuencia_prueba_id === String(sequence.secuencia_prueba_id)
									? 'bg-[color:var(--muted)]'
									: ''
							}`}
						>
							<td class="px-3 py-2">{index + 1}</td>
							<td class="px-3 py-2">{Number(sequence.v_ini)}</td>
							<td class="px-3 py-2">{Number(sequence.v_fin)}</td>
							<td class="px-3 py-2">{Number(sequence.v_fin) - Number(sequence.v_ini) + 1}</td>
							<td class="px-3 py-2">
								<span class="block">{formLabel(String(sequence.forma_id))}</span>
								{#if sequence.arquitectura_id}
									<span class="block text-xs text-[color:var(--muted-foreground)]">
										{configurationLabel(String(sequence.arquitectura_id))}
									</span>
								{/if}
							</td>
							<td class="px-3 py-2">
								<div class="flex items-center justify-end gap-1">
									<button
										type="button"
										class="p-1 text-[color:var(--muted-foreground)] hover:text-[color:var(--success)] disabled:opacity-40"
										aria-label="Editar secuencia"
										onclick={() => requestOpenSequence(sequence)}
										disabled={sequenceSaving}
									>
										<Pencil size={16} />
									</button>
									<button
										type="button"
										class="p-1 text-[color:var(--muted-foreground)] hover:text-[color:var(--danger)] disabled:opacity-40"
										aria-label="Eliminar secuencia"
										onclick={() => void deleteSequenceById(String(sequence.secuencia_prueba_id))}
										disabled={sequenceSaving}
									>
										<Trash2 size={16} />
									</button>
								</div>
							</td>
						</tr>
					{:else}
						<tr>
							<td class="px-3 py-4 text-[color:var(--muted-foreground)]" colspan={6}>
								{orderedSequences.length === 0
									? 'Este escenario todavía no tiene secuencias.'
									: 'Sin secuencias para este filtro.'}
							</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>

		<div class="card grid p-4 sm:grid-cols-3 sm:divide-x sm:divide-[color:var(--border)]">
			<div class="px-3 py-1 sm:first:pl-0">
				<p class="text-xs text-[color:var(--muted-foreground)]">Último verso del escenario</p>
				<p class="text-base font-semibold">{scenarioLastVerse === 0 ? '--' : scenarioLastVerse}</p>
			</div>
			<div class="px-3 py-1">
				<p class="text-xs text-[color:var(--muted-foreground)]">Versos declarados (filtrado)</p>
				<p class="text-base font-semibold">{declaredVerses}</p>
			</div>
			<div class="px-3 py-1">
				<p class="text-xs text-[color:var(--muted-foreground)]">Diferencia</p>
				<p
					class={`text-base font-semibold ${
						versesDifference === null
							? 'text-[color:var(--muted-foreground)]'
							: versesDifference === 0
								? 'text-[color:var(--foreground)]'
								: 'text-[color:var(--danger)]'
					}`}
				>
					{#if versesDifference === null}
						--
					{:else if versesDifference > 0}
						+{versesDifference}
					{:else}
						{versesDifference}
					{/if}
				</p>
			</div>
		</div>
	{:else if !showNewScenario}
		<div class="border border-dashed border-[color:var(--border)] p-8 text-center">
			<h3 class="font-semibold">Crea el primer escenario de prueba</h3>
		</div>
	{/if}
</section>

{#if openDraft}
	<div class="fixed inset-0 z-40 flex items-start justify-center bg-black/50 p-4">
		<div
			class="flex max-h-[92vh] w-full max-w-6xl flex-col overflow-hidden border border-[color:var(--border)] bg-[color:var(--gray-50)]"
			inert={sequenceSaving}
			aria-busy={sequenceSaving}
		>
			<div class="border-b border-[color:var(--border)] bg-white px-5 py-3">
				<div class="flex flex-wrap items-center justify-between gap-3">
					<div class="flex min-w-0 items-center gap-3">
						<h3 class="text-base font-semibold">
							{openDraft.secuencia_prueba_id ? 'Editar secuencia' : 'Nueva secuencia'}
						</h3>
						{#if liveDraft}
							{@const verses = liveDraft.v_fin - liveDraft.v_ini + 1}
							<span class="whitespace-nowrap text-sm text-[color:var(--muted-foreground)]">
								vv. {liveDraft.v_ini}–{liveDraft.v_fin} · {verses}
								{verses === 1 ? 'verso' : 'versos'}
							</span>
						{/if}
						{#if editingIndex >= 0}
							<div class="flex items-center gap-1">
								<button
									type="button"
									class="p-1 text-[color:var(--muted-foreground)] hover:text-[color:var(--foreground)] disabled:opacity-30"
									aria-label="Secuencia anterior"
									onclick={() => previousSequence && requestOpenSequence(previousSequence)}
									disabled={!previousSequence || sequenceSaving}
								>
									<ChevronLeft size={18} />
								</button>
								<span class="whitespace-nowrap text-sm text-[color:var(--muted-foreground)]">
									{editingIndex + 1} / {orderedSequences.length}
								</span>
								<button
									type="button"
									class="p-1 text-[color:var(--muted-foreground)] hover:text-[color:var(--foreground)] disabled:opacity-30"
									aria-label="Secuencia siguiente"
									onclick={() => nextSequence && requestOpenSequence(nextSequence)}
									disabled={!nextSequence || sequenceSaving}
								>
									<ChevronRight size={18} />
								</button>
							</div>
						{/if}
						<!-- Lo que falta se ve antes de pulsar Guardar, no después del aviso. -->
						{#if editorState && editorState.total > 0}
							<span
								class={`whitespace-nowrap text-sm ${
									editorState.answered < editorState.total
										? 'text-[color:var(--primary)]'
										: 'text-[color:var(--muted-foreground)]'
								}`}
							>
								{editorState.answered} de {editorState.total}
								{editorState.total === 1 ? 'respuesta' : 'respuestas'}
							</span>
						{/if}
					</div>
					<div class="flex items-center gap-2">
						{#if draftDirty}
							<span class="text-xs text-[color:var(--muted-foreground)]">Cambios sin guardar</span>
						{/if}
						{#if openDraft.secuencia_prueba_id}
							<Button
								variant="danger"
								onclick={() => void deleteSequenceById(openDraft!.secuencia_prueba_id as string)}
								disabled={sequenceSaving}
							>
								Eliminar
							</Button>
						{/if}
						<Button variant="secondary" onclick={requestCloseSequence} disabled={sequenceSaving}>
							Cerrar
						</Button>
						<Button
							variant="success"
							onclick={() => void saveSequence()}
							disabled={sequenceSaving}
							loading={sequenceSaving}
							loadingLabel="Guardando…"
						>
							Guardar
						</Button>
					</div>
				</div>
				{#if errorMessage}
					<p class="mt-2 border-l-4 border-red-500 bg-red-50 p-2 text-sm text-red-900">
						{errorMessage}
					</p>
				{/if}
			</div>

			<div class="min-h-0 flex-1 overflow-y-auto">
				{#key openToken}
					<MetricSequenceEditor
						{catalog}
						initialDraft={openDraft}
						onStateChange={handleEditorState}
						bodyExtra={legacySequenceFields}
						extraRailItems={LEGACY_RAIL_ITEMS}
					/>
				{/key}
			</div>
		</div>
	</div>
{/if}

{#snippet legacySequenceFields()}
	<CollapsibleGroup id="caracterizaciones" title="Caracterizaciones y personajes">
		<MetricSandboxLegacyFields block="caracterizaciones" />
	</CollapsibleGroup>
	<CollapsibleGroup id="sinopsis" title="Sinopsis argumental">
		<MetricSandboxLegacyFields block="sinopsis" />
	</CollapsibleGroup>
	<CollapsibleGroup id="comentarios" title="Comentarios internos">
		<MetricSandboxLegacyFields block="comentarios" />
	</CollapsibleGroup>
{/snippet}

<UnsavedChangesModal
	open={Boolean(pendingAction)}
	message={pendingAction?.kind === 'new'
		? 'La secuencia actual tiene cambios sin guardar. ¿Quieres guardarlos antes de crear otra?'
		: pendingAction?.kind === 'open'
			? 'La secuencia actual tiene cambios sin guardar. ¿Quieres guardarlos antes de cambiar de secuencia?'
			: 'La secuencia actual tiene cambios sin guardar. ¿Quieres guardarlos antes de cerrar?'}
	discardLabel="Continuar sin guardar"
	saving={sequenceSaving}
	onCancel={() => (pendingAction = null)}
	onDiscard={runPendingAction}
	onSave={savePendingAction}
/>
