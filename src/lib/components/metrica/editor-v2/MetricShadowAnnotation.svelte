<script lang="ts">
	import { invalidateAll } from '$app/navigation';
	import { untrack } from 'svelte';
	import Button from '$lib/components/ui/button.svelte';
	import UnsavedChangesModal from '$lib/components/editor/UnsavedChangesModal.svelte';
	import { pushToast } from '$lib/stores/toast';
	import type {
		MetricCatalogDomainRow,
		MetricCatalogForEditor,
		MetricCatalogPageData
	} from '$lib/metrica/catalogo';
	import {
		shadowAgreement,
		SHADOW_RESOLUTION_LABEL,
		type ShadowAnswer,
		type ShadowAnnotationData,
		type ShadowCandidateWork,
		type ShadowSequence,
		type ShadowWork
	} from '$lib/metrica/anotacion-en-sombra';
	import MetricSequenceEditor from './MetricSequenceEditor.svelte';
	import { draftFromRows } from './sequence-draft';
	import type { MetricUnitDraft } from './editor-model';
	import type {
		MetricDeviationDraft,
		MetricSequenceDraft,
		MetricSequenceEditorState
	} from './sequence-draft';

	/**
	 * Anotación en sombra: fase 0 de la migración. Se anota con el modelo nuevo sobre
	 * secuencias **reales**, sin que producción se entere. La secuencia real no cambia ni una
	 * columna: todo lo anotado cuelga de la prueba.
	 *
	 * No hay pantalla de comparación lado a lado: para eso se abre el editor de la obra en otra
	 * pestaña. Lo que sí vive aquí es el recuento de acuerdo, que es lo que decide cuándo
	 * termina la fase y no se puede sacar mirando obra por obra.
	 */
	const props = $props<{ data: MetricCatalogPageData & { shadow: ShadowAnnotationData } }>();

	const shadow = $derived(props.data.shadow);

	let selectedWorkId = $state<string | null>(
		untrack(() => props.data.shadow.works[0]?.obraId ?? null)
	);
	let showWorkPicker = $state(false);
	let workSearch = $state('');
	let workSaving = $state(false);
	let sequenceSaving = $state(false);
	let openDraft = $state<MetricSequenceDraft | null>(null);
	let openSequenceId = $state<string | null>(null);
	/** Respuestas por unidad de la secuencia abierta: las aplica el editor al materializarlas. */
	let openUnitAnswers = $state<{ grupo_eleccion_id: string; opcion_eleccion_id: string }[]>([]);
	let openToken = $state(0);
	let editorState = $state<MetricSequenceEditorState | null>(null);
	let baselineToken = $state(-1);
	let draftBaseline = $state('');
	let errorMessage = $state('');
	let pendingClose = $state(false);

	const catalog = $derived<MetricCatalogForEditor>({
		forms: props.data.forms,
		configurations: props.data.configurations,
		lengthRules: props.data.lengthRules,
		domain: props.data.domain
	});

	const selectedWork = $derived(
		(shadow.works as ShadowWork[]).find((work: ShadowWork) => work.obraId === selectedWorkId) ??
			null
	);
	const workSequences = $derived(
		shadow.sequences
			.filter((sequence: ShadowSequence) => sequence.obraId === selectedWorkId)
			.sort((a: ShadowSequence, b: ShadowSequence) => a.vIni - b.vIni)
	);

	/**
	 * El recuento que decide la fase: de lo anotado en los dos modelos, cuánto coincide. Se
	 * calcula sobre todas las obras abiertas, no sobre la que se está mirando.
	 */
	const tally = $derived.by(() => {
		const counts = { total: 0, pendiente: 0, coincide: 0, difiere: 0, sin_propuesta: 0 };
		for (const sequence of shadow.sequences) {
			counts.total += 1;
			counts[shadowAgreement(sequence)] += 1;
		}
		return counts;
	});

	const candidates = $derived(
		shadow.candidates.filter((work: ShadowCandidateWork) => {
			if (work.abierta) return false;
			const term = workSearch.trim().toLocaleLowerCase('es');
			if (!term) return true;
			return (
				work.titulo.toLocaleLowerCase('es').includes(term) ||
				work.formas.some((forma) => forma.toLocaleLowerCase('es').includes(term))
			);
		})
	);

	const liveDraft = $derived(editorState?.draft ?? null);
	const draftDirty = $derived(
		liveDraft !== null && draftBaseline !== '' && JSON.stringify(liveDraft) !== draftBaseline
	);
	const openSequence = $derived(
		workSequences.find((sequence: ShadowSequence) => sequence.secuenciaId === openSequenceId) ??
			null
	);

	$effect(() => {
		const works = shadow.works as ShadowWork[];
		if (selectedWorkId && !works.some((work: ShadowWork) => work.obraId === selectedWorkId)) {
			selectedWorkId = works[0]?.obraId ?? null;
		}
	});

	function handleEditorState(state: MetricSequenceEditorState) {
		editorState = state;
		if (baselineToken !== openToken) {
			draftBaseline = JSON.stringify(state.draft);
			baselineToken = openToken;
		}
	}

	function cleanText(value: string): string | null {
		return value.trim() || null;
	}

	const AGREEMENT_LABEL: Record<string, string> = {
		pendiente: 'Sin anotar',
		coincide: 'Coincide',
		difiere: 'Difiere',
		sin_propuesta: 'Sin correspondencia'
	};

	function resolutionLabel(sequence: ShadowSequence): string {
		return SHADOW_RESOLUTION_LABEL[sequence.via] ?? String(sequence.via);
	}

	function agreementClass(sequence: ShadowSequence): string {
		switch (shadowAgreement(sequence)) {
			case 'coincide':
				return 'text-emerald-700';
			case 'difiere':
				return 'text-amber-700';
			case 'sin_propuesta':
				return 'text-[color:var(--muted-foreground)]';
			default:
				return 'text-[color:var(--muted-foreground)]';
		}
	}

	/**
	 * Abrir una secuencia real no empieza en blanco: si ya se anotó, se recupera; si no, el
	 * formulario se propone solo desde `estrofa_tipo_id`. El editor revisa, no reanota.
	 */
	function openRealSequence(sequence: ShadowSequence) {
		const saved = props.data.editorSandbox.sequences.find(
			(row: MetricCatalogDomainRow) => String(row.secuencia_id ?? '') === sequence.secuenciaId
		);
		if (saved) {
			// Ya anotada: lo guardado manda, no se vuelve a proponer nada.
			openUnitAnswers = [];
			openDraft = draftFromRows(saved, {
				units: props.data.editorSandbox.units,
				choices: props.data.editorSandbox.choices,
				deviations: props.data.editorSandbox.deviations
			});
		} else {
			// El término legado no solo dice la forma: `romance_o-e` dice además la asonancia.
			// Esas respuestas llegan contestadas para que el editor las revise, no las repita.
			// Las de ámbito unidad se dejan para cuando el formulario haya materializado sus
			// unidades: aquí todavía no existen y no habría dónde colgarlas.
			const todas = sequence.respuestas as ShadowAnswer[];
			const respuestas = todas.filter(
				(respuesta: ShadowAnswer) => respuesta.alcance === 'secuencia'
			);
			openUnitAnswers = todas
				.filter((respuesta: ShadowAnswer) => respuesta.alcance === 'unidad')
				.map((respuesta: ShadowAnswer) => ({
					grupo_eleccion_id: respuesta.grupoEleccionId,
					opcion_eleccion_id: respuesta.opcionEleccionId
				}));
			openDraft = {
				anotacion_id: null,
				escenario_id: null,
				secuencia_id: sequence.secuenciaId,
				orden: 1,
				v_ini: sequence.vIni,
				v_fin: sequence.vFin,
				forma_id: sequence.formaPropuestaId ?? '',
				arquitectura_id: sequence.arquitecturaPropuestaId ?? '',
				observaciones: '',
				unidades: [],
				elecciones: respuestas.map((respuesta: ShadowAnswer) => ({
					realizacion_id: null,
					grupo_eleccion_id: respuesta.grupoEleccionId,
					opcion_eleccion_id: respuesta.opcionEleccionId,
					valor_texto: null,
					observaciones: null
				})),
				desviaciones: []
			};
		}
		openSequenceId = sequence.secuenciaId;
		openToken += 1;
		errorMessage = '';
	}

	function closeEditor() {
		openDraft = null;
		openSequenceId = null;
		openUnitAnswers = [];
		editorState = null;
		draftBaseline = '';
	}

	function requestCloseEditor() {
		if (draftDirty) {
			pendingClose = true;
			return;
		}
		closeEditor();
	}

	async function callApi(body: Record<string, unknown>) {
		const response = await fetch('/api/metrica/editor-pruebas', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify(body)
		});
		const payload = await response.json().catch(() => ({}));
		if (!response.ok) throw new Error(payload.message ?? 'No se pudo completar la operación.');
		return payload;
	}

	async function openWork(obraId: string) {
		if (workSaving) return;
		workSaving = true;
		errorMessage = '';
		try {
			await callApi({ action: 'open_work', obra_id: obraId, nota: null });
			selectedWorkId = obraId;
			showWorkPicker = false;
			workSearch = '';
			pushToast('success', 'Obra abierta a la anotación en sombra.');
			await invalidateAll();
		} catch (error) {
			errorMessage = error instanceof Error ? error.message : 'No se pudo abrir la obra.';
		} finally {
			workSaving = false;
		}
	}

	async function closeWork(obraId: string, titulo: string) {
		if (workSaving) return;
		if (
			!window.confirm(
				`¿Retirar «${titulo}» de la anotación en sombra?\n\nLo ya anotado no se borra: la obra deja de poder anotarse con el modelo nuevo.`
			)
		) {
			return;
		}
		workSaving = true;
		try {
			await callApi({ action: 'close_work', obra_id: obraId });
			if (openSequenceId && openSequence?.obraId === obraId) closeEditor();
			pushToast('success', 'Obra retirada de la anotación en sombra.');
			await invalidateAll();
		} catch (error) {
			errorMessage = error instanceof Error ? error.message : 'No se pudo cerrar la obra.';
		} finally {
			workSaving = false;
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
			draft.anotacion_id = String(payload.anotacion_id);
			draftBaseline = JSON.stringify(draft);
			pushToast('success', 'Anotación en sombra guardada.');
			await invalidateAll();
		} catch (error) {
			errorMessage = error instanceof Error ? error.message : 'No se pudo guardar la anotación.';
		} finally {
			sequenceSaving = false;
		}
	}

	async function deleteShadow(sequence: ShadowSequence) {
		if (!sequence.pruebaId || sequenceSaving) return;
		if (!window.confirm('¿Descartar la anotación nueva de esta secuencia? La secuencia real no se toca.')) {
			return;
		}
		sequenceSaving = true;
		try {
			await callApi({ action: 'delete_sequence', anotacion_id: sequence.pruebaId });
			if (openSequenceId === sequence.secuenciaId) closeEditor();
			pushToast('success', 'Anotación descartada.');
			await invalidateAll();
		} catch (error) {
			errorMessage = error instanceof Error ? error.message : 'No se pudo descartar la anotación.';
		} finally {
			sequenceSaving = false;
		}
	}
</script>

<section class="space-y-5">
	<div class="border-l-4 border-amber-500 bg-amber-50 p-5 text-sm leading-6 text-amber-950">
		<h2 class="font-semibold">Anotación en sombra</h2>
		<p class="mt-1 max-w-5xl">
			Aquí se anota con el modelo nuevo sobre secuencias <strong>reales</strong>, para saber si
			aguanta antes de migrar nada. La secuencia real no cambia: lo que se anota cuelga de la
			prueba y no alimenta fichas, buscadores ni resúmenes. El editor de la obra sigue siendo el
			de siempre y puede abrirse en otra pestaña para comparar.
		</p>
		<p class="mt-2 max-w-5xl">
			Al abrir una secuencia por primera vez, el formulario llega propuesto desde su término
			legado. Lo que se prueba no es solo el formulario: también si esa correspondencia acierta.
		</p>
	</div>

	{#if errorMessage}
		<p class="border-l-4 border-red-500 bg-red-50 p-3 text-sm text-red-900">{errorMessage}</p>
	{/if}

	<!-- El recuento que decide la fase. -->
	{#if tally.total > 0}
		<div class="flex flex-wrap gap-6 border border-[color:var(--border)] bg-white p-4">
			<div>
				<p class="text-xs text-[color:var(--muted-foreground)]">Secuencias abiertas</p>
				<p class="text-base font-semibold">{tally.total}</p>
			</div>
			<div>
				<p class="text-xs text-[color:var(--muted-foreground)]">Anotadas</p>
				<p class="text-base font-semibold">{tally.coincide + tally.difiere}</p>
			</div>
			<div>
				<p class="text-xs text-[color:var(--muted-foreground)]">Coinciden con la propuesta</p>
				<p class="text-base font-semibold text-emerald-700">{tally.coincide}</p>
			</div>
			<div>
				<p class="text-xs text-[color:var(--muted-foreground)]">Difieren</p>
				<p class="text-base font-semibold text-amber-700">{tally.difiere}</p>
			</div>
			<div>
				<p class="text-xs text-[color:var(--muted-foreground)]">Sin correspondencia</p>
				<p class="text-base font-semibold">{tally.sin_propuesta}</p>
			</div>
		</div>
	{/if}

	<div class="flex flex-wrap items-end justify-between gap-3">
		<div class="flex flex-wrap items-center gap-2">
			{#each shadow.works as work (work.obraId)}
				<button
					type="button"
					class={`border px-3 py-2 text-left text-sm ${
						work.obraId === selectedWorkId
							? 'border-[color:var(--primary)] bg-white font-semibold'
							: 'border-[color:var(--border)] bg-white text-[color:var(--muted-foreground)]'
					}`}
					onclick={() => (selectedWorkId = work.obraId)}
				>
					<span class="block">{work.titulo}</span>
					<span class="block text-xs font-normal text-[color:var(--muted-foreground)]">
						{work.anotadas} de {work.secuencias} anotadas
					</span>
				</button>
			{/each}
		</div>
		<Button
			variant="secondary"
			onclick={() => (showWorkPicker = !showWorkPicker)}
			disabled={workSaving}
		>
			{showWorkPicker ? 'Cancelar' : 'Abrir una obra'}
		</Button>
	</div>

	{#if showWorkPicker}
		<div class="border border-[color:var(--border)] bg-white p-4">
			<p class="text-sm text-[color:var(--muted-foreground)]">
				Conviene elegir obras por las formas que traen, no por quién las anota: que haya
				villancicos, canciones y tercetos encadenados.
			</p>
			<input
				class="mt-3 h-10 w-full max-w-md border border-[color:var(--border)] px-3 text-sm"
				placeholder="Buscar por título o por forma…"
				bind:value={workSearch}
			/>
			<ul class="mt-3 max-h-80 divide-y divide-[color:var(--border)] overflow-y-auto">
				{#each candidates.slice(0, 40) as work (work.obraId)}
					<li class="flex items-start justify-between gap-4 py-2">
						<div class="min-w-0">
							<p class="text-sm font-medium">{work.titulo}</p>
							<p class="text-xs text-[color:var(--muted-foreground)]">
								{work.secuencias} secuencias · {work.formas.slice(0, 6).join(', ')}
								{#if work.formas.length > 6}…{/if}
							</p>
							{#if work.sinCorrespondencia > 0}
								<p class="text-xs text-amber-700">
									{work.sinCorrespondencia} sin correspondencia en el catálogo
								</p>
							{/if}
						</div>
						<Button
							variant="secondary"
							onclick={() => void openWork(work.obraId)}
							disabled={workSaving}
						>
							Abrir
						</Button>
					</li>
				{:else}
					<li class="py-3 text-sm text-[color:var(--muted-foreground)]">
						No hay obras que coincidan.
					</li>
				{/each}
			</ul>
		</div>
	{/if}

	{#if selectedWork}
		<div class="border border-[color:var(--border)] bg-white">
			<div
				class="flex flex-wrap items-center justify-between gap-3 border-b border-[color:var(--border)] px-4 py-3"
			>
				<h3 class="font-semibold">{selectedWork.titulo}</h3>
				<button
					type="button"
					class="link-action link-action--danger link-action--sm"
					onclick={() => void closeWork(selectedWork!.obraId, selectedWork!.titulo)}
					disabled={workSaving}
				>
					Retirar de la anotación en sombra
				</button>
			</div>
			<div class="overflow-x-auto">
				<table class="w-full text-sm">
					<thead class="bg-[color:var(--gray-50)] text-left">
						<tr>
							<th class="px-4 py-2 font-medium">Versos</th>
							<th class="px-4 py-2 font-medium">Modelo actual</th>
							<th class="px-4 py-2 font-medium">Propuesta del catálogo</th>
							<th class="px-4 py-2 font-medium">Vía</th>
							<th class="px-4 py-2 font-medium">Estado</th>
							<th class="px-4 py-2"></th>
						</tr>
					</thead>
					<tbody class="divide-y divide-[color:var(--border)]">
						{#each workSequences as sequence (sequence.secuenciaId)}
							<tr class={openSequenceId === sequence.secuenciaId ? 'bg-[color:var(--gray-50)]' : ''}>
								<td class="whitespace-nowrap px-4 py-2">
									{sequence.vIni}–{sequence.vFin}
									<span class="text-xs text-[color:var(--muted-foreground)]">
										· {sequence.versos}
									</span>
								</td>
								<td class="px-4 py-2">
									{sequence.terminoLegado ?? '—'}
									{#if sequence.subtipos > 0 || sequence.caracterizaciones > 0}
										<span class="block text-xs text-[color:var(--muted-foreground)]">
											{#if sequence.subtipos > 0}{sequence.subtipos} subtipos{/if}
											{#if sequence.subtipos > 0 && sequence.caracterizaciones > 0} · {/if}
											{#if sequence.caracterizaciones > 0}
												{sequence.caracterizaciones} caracterizaciones
											{/if}
										</span>
									{/if}
								</td>
								<td class="px-4 py-2">
									{#if sequence.formaPropuesta}
										{sequence.formaPropuesta}
										{#if sequence.arquitecturaPropuesta}
											<span class="block text-xs text-[color:var(--muted-foreground)]">
												{sequence.arquitecturaPropuesta}
											</span>
										{/if}
										{#if sequence.motivoRevision}
											<span class="mt-1 block text-xs text-amber-700">
												{sequence.motivoRevision}
											</span>
										{/if}
									{:else}
										<span class="text-[color:var(--muted-foreground)]">
											El término legado no tiene correspondencia
										</span>
									{/if}
								</td>
								<td class="whitespace-nowrap px-4 py-2 text-xs text-[color:var(--muted-foreground)]">
									{resolutionLabel(sequence)}
								</td>
								<td class={`whitespace-nowrap px-4 py-2 ${agreementClass(sequence)}`}>
									{AGREEMENT_LABEL[shadowAgreement(sequence)]}
								</td>
								<td class="whitespace-nowrap px-4 py-2 text-right">
									<button
										type="button"
										class="link-action link-action--sm"
										onclick={() => openRealSequence(sequence)}
									>
										{sequence.pruebaId ? 'Revisar' : 'Anotar'}
									</button>
									{#if sequence.pruebaId}
										<button
											type="button"
											class="link-action link-action--danger link-action--sm ml-3"
											onclick={() => void deleteShadow(sequence)}
											disabled={sequenceSaving}
										>
											Descartar
										</button>
									{/if}
								</td>
							</tr>
						{:else}
							<tr>
								<td class="px-4 py-4 text-[color:var(--muted-foreground)]" colspan="6">
									Esta obra no tiene secuencias métricas registradas.
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		</div>
	{:else}
		<div class="border border-dashed border-[color:var(--border)] bg-white p-6 text-center">
			<h3 class="font-semibold">Todavía no hay ninguna obra abierta</h3>
			<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
				Abre una obra para empezar a anotarla con el modelo nuevo. El editor de siempre sigue
				funcionando igual para todo el mundo.
			</p>
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
						<h3 class="text-base font-semibold">Anotación en sombra</h3>
						{#if openSequence}
							<span class="whitespace-nowrap text-sm text-[color:var(--muted-foreground)]">
								vv. {openSequence.vIni}–{openSequence.vFin} · {openSequence.versos}
								{openSequence.versos === 1 ? 'verso' : 'versos'}
							</span>
							{#if openSequence.terminoLegado}
								<span class="whitespace-nowrap text-sm text-[color:var(--muted-foreground)]">
									Modelo actual: {openSequence.terminoLegado}
								</span>
							{/if}
						{/if}
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
						<Button variant="secondary" onclick={requestCloseEditor} disabled={sequenceSaving}>
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
						initialUnitAnswers={openUnitAnswers}
						onStateChange={handleEditorState}
					/>
				{/key}
			</div>
		</div>
	</div>
{/if}

<UnsavedChangesModal
	open={pendingClose}
	message="Esta anotación tiene cambios sin guardar. ¿Quieres guardarlos antes de cerrar?"
	discardLabel="Continuar sin guardar"
	saving={sequenceSaving}
	onCancel={() => (pendingClose = false)}
	onDiscard={() => {
		pendingClose = false;
		closeEditor();
	}}
	onSave={async () => {
		await saveSequence();
		if (errorMessage) return;
		pendingClose = false;
		closeEditor();
	}}
/>
