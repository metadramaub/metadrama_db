<script lang="ts">
	import Tabs from '$lib/components/ui/tabs.svelte';
	import Breadcrumb from '$lib/components/ui/Breadcrumb.svelte';
	import CiteWorkButton from '$lib/components/ficha/CiteWorkButton.svelte';
	import MetricBarcode from '$lib/components/metrica/MetricBarcode.svelte';
	import MetricDistributionPie from '$lib/components/metrica/MetricDistributionPie.svelte';
	import SequenceDetailModal from '$lib/components/ficha/SequenceDetailModal.svelte';
	import FichaAutoriaBlock from '$lib/components/ficha/FichaAutoriaBlock.svelte';
	import { secuenciasToBarSegments } from '$lib/components/ficha/ficha-metric-adapter';
	import { isSectionVisible, FICHA_SECTION_IDS } from '$lib/secciones-publicas';
	import type { SequenceModalPayload, PublicFichaComentarioPublico } from '$lib/types/public-ficha.types';
	import { formatRelative } from '$lib/utils/formatters';
	import { renderMarkdown } from '$lib/utils/markdown';
	import { colorForMetricKey } from '$lib/utils/metric-colors';
	import {
		resolveSequenceStructures,
		type ResolvedSequenceStructure
	} from '$lib/utils/sequence-structure';
	import type { PageData } from './$types';

	let { data } = $props<{ data: PageData }>();

	type TabId = 'estructura' | 'observaciones';
	type MetricViewMode = 'obra_completa' | 'por_jornadas';
	type PieValueMode = 'percent' | 'absolute';
	type ResolvedPublicSequence = ResolvedSequenceStructure<SequenceModalPayload>;

	let activeTab = $state<TabId>('estructura');
	let metricViewMode = $state<MetricViewMode>('obra_completa');
	let pieValueMode = $state<PieValueMode>('percent');
	let selectedSequenceId = $state<string | null>(null);

	const ficha = $derived(data.ficha);
	const obra = $derived(ficha.obra);

	// --- Visibilidad de secciones (resuelve el pendiente B: ocultar, no vaciar) ---
	const show = (id: string) => isSectionVisible(data.sectionVisibility ?? {}, id);
	const showAutoria = $derived(show(FICHA_SECTION_IDS.autoria));
	const showFuentes = $derived(show(FICHA_SECTION_IDS.fuentes));
	const showMetrica = $derived(show(FICHA_SECTION_IDS.metrica));
	const showObservaciones = $derived(show(FICHA_SECTION_IDS.observaciones));
	const showBibliografia = $derived(show(FICHA_SECTION_IDS.bibliografia));
	const showComentarios = $derived(show(FICHA_SECTION_IDS.comentarios));

	// --- Estructura métrica ---
	const jornadas = $derived.by(() =>
		[...ficha.estructura.jornadas].sort((a, b) => a.jornada_num - b.jornada_num)
	);
	const cuadros = $derived.by(() =>
		[...ficha.estructura.cuadros].sort((a, b) => a.v_ini - b.v_ini || a.cuadro_num - b.cuadro_num)
	);
	const secuenciasOrdenadas = $derived.by(() =>
		[...ficha.metrica.secuencias].sort((a, b) => a.v_ini - b.v_ini)
	);
	const resolvedPublicSequences = $derived.by(() =>
		resolveSequenceStructures({ secuencias: secuenciasOrdenadas, jornadas, cuadros })
	);
	const totalVersos = $derived.by(() => {
		const fromObra = obra.total_versos ?? 0;
		const fromJornadas = jornadas.reduce((max, j) => Math.max(max, j.v_fin), 0);
		const fromSecuencias = secuenciasOrdenadas.reduce((max, s) => Math.max(max, s.v_fin), 0);
		return Math.max(1, fromObra, fromJornadas, fromSecuencias);
	});
	const estructuraResumen = $derived.by(() => {
		const parts = [
			jornadas.length === 1 ? '1 jornada' : `${jornadas.length} jornadas`,
			cuadros.length === 1 ? '1 cuadro' : `${cuadros.length} cuadros`
		];
		if (secuenciasOrdenadas.length > 0) {
			parts.push(
				secuenciasOrdenadas.length === 1
					? '1 secuencia métrica'
					: `${secuenciasOrdenadas.length} secuencias métricas`
			);
		}
		return parts.join(' · ');
	});

	const tabs = [
		{ id: 'estructura', label: 'Estructura métrica' },
		{ id: 'observaciones', label: 'Observaciones' }
	];

	const datacionLabel = $derived(`${obra.fecha_inicio_trad ?? '--'} - ${obra.fecha_fin_trad ?? '--'}`);
	const variantesLabel = $derived((obra.variantes_titulo ?? []).join(' | '));
	const updatedAtAbsolute = $derived.by(() => {
		if (!obra.updated_at) return 'sin fecha';
		const date = new Date(obra.updated_at);
		if (Number.isNaN(date.valueOf())) return 'sin fecha';
		return new Intl.DateTimeFormat('es-ES', { dateStyle: 'medium', timeStyle: 'short' }).format(date);
	});

	// Colores por forma (compartidos entre barcode y pie).
	const colorByForma = $derived.by(() => {
		const map: Record<string, string> = {};
		for (const item of ficha.metrica.distribucion_formas) {
			map[item.forma] = colorForMetricKey(item.forma);
		}
		for (const secuencia of secuenciasOrdenadas) {
			if (!map[secuencia.estrofa_forma_term]) {
				map[secuencia.estrofa_forma_term] = colorForMetricKey(secuencia.estrofa_forma_term);
			}
		}
		return map;
	});

	// Adaptación a segmentos genéricos del barcode (incluye subtipos como subsegments).
	const barSegments = $derived.by(() => secuenciasToBarSegments(secuenciasOrdenadas));

	const jornadaMarkers = $derived.by(() =>
		jornadas.map((j) => j.v_fin).filter((m) => m > 0 && m < totalVersos)
	);
	const cuadroMarkers = $derived.by(() =>
		cuadros.map((c) => c.v_fin).filter((m) => m > 0 && m < totalVersos)
	);

	const segmentsByJornada = $derived.by(() => {
		const map = new Map<string, ReturnType<typeof secuenciasToBarSegments>>();
		for (const item of resolvedPublicSequences) {
			if (!item.jornada.jornadaId) continue;
			const current = map.get(item.jornada.jornadaId) ?? [];
			current.push(secuenciasToBarSegments([item.sequence])[0]);
			map.set(item.jornada.jornadaId, current);
		}
		return map;
	});
	const cuadroMarkersByJornada = $derived.by(() => {
		const map = new Map<string, number[]>();
		for (const jornada of jornadas) {
			map.set(
				jornada.jornada_id,
				cuadros.filter((c) => c.jornada_id === jornada.jornada_id).map((c) => c.v_fin)
			);
		}
		return map;
	});

	// --- Modal de secuencia ---
	const selectedSequenceIndex = $derived.by(() => {
		if (!selectedSequenceId) return -1;
		return resolvedPublicSequences.findIndex((i) => i.sequence.secuencia_id === selectedSequenceId);
	});
	const selectedSequenceStructure = $derived.by((): ResolvedPublicSequence | null =>
		selectedSequenceIndex < 0 ? null : (resolvedPublicSequences[selectedSequenceIndex] ?? null)
	);
	const selectedSequence = $derived.by(() => selectedSequenceStructure?.sequence ?? null);

	const comentariosPublicos = $derived<PublicFichaComentarioPublico[]>(
		ficha.comentarios_publicos ?? []
	);
	const comentariosPorSecuencia = $derived.by(() => {
		const map = new Map<string, PublicFichaComentarioPublico[]>();
		for (const c of comentariosPublicos) {
			if (!c.secuencia_id) continue;
			const cur = map.get(c.secuencia_id) ?? [];
			cur.push(c);
			map.set(c.secuencia_id, cur);
		}
		return map;
	});
	const selectedSequenceComments = $derived.by(() =>
		selectedSequenceId ? (comentariosPorSecuencia.get(selectedSequenceId) ?? []) : []
	);

	function openSequenceModal(id: string) {
		selectedSequenceId = id;
	}
	function closeSequenceModal() {
		selectedSequenceId = null;
	}
	function openPrevSequence() {
		if (selectedSequenceIndex <= 0) return;
		selectedSequenceId = resolvedPublicSequences[selectedSequenceIndex - 1]?.sequence.secuencia_id ?? null;
	}
	function openNextSequence() {
		if (selectedSequenceIndex < 0 || selectedSequenceIndex >= resolvedPublicSequences.length - 1) return;
		selectedSequenceId = resolvedPublicSequences[selectedSequenceIndex + 1]?.sequence.secuencia_id ?? null;
	}

	const hasObservaciones = $derived((obra.observaciones ?? '').trim().length > 0);
	const hasBibliografia = $derived((obra.bibliografia ?? '').trim().length > 0);
</script>

<section class="space-y-6">
	<Breadcrumb
		items={[
			{ label: 'Catálogo', href: '/obras' },
			{ label: obra.titulo, preserveCase: true }
		]}
	/>

	<header class="card p-4 md:p-5">
		<div class="flex flex-wrap items-start justify-between gap-4 border-b border-[color:var(--border)] pb-4">
			<div class="min-w-0 flex-1">
				<h1 class="font-display text-3xl text-[color:var(--gray-900)] md:text-4xl">{obra.titulo}</h1>
				{#if variantesLabel}
					<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">{variantesLabel}</p>
				{/if}

				{#if showAutoria}
					<FichaAutoriaBlock autoria={ficha.autoria} showFuentes={showFuentes} />
				{/if}
			</div>

			<CiteWorkButton
				titulo={obra.titulo}
				autorFicha={obra.autor_ficha_publico}
				updatedAt={obra.updated_at}
				obraPath={`/obras/${obra.obra_id}`}
			/>
		</div>

		{#if data.canSeeAllPublished && !obra.visible_publico}
			<div class="mt-4 border border-[color:var(--border)] bg-[color:var(--muted)] p-3 text-sm text-[color:var(--muted-foreground)]">
				Esta obra está publicada en flujo editorial, pero no visible sin login.
			</div>
		{/if}

		<dl class="mt-4 grid gap-x-6 gap-y-4 text-sm md:grid-cols-2 xl:grid-cols-3">
			<div>
				<dt class="text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
					Datación tradicional
				</dt>
				<dd class="mt-1 font-semibold">{datacionLabel}</dd>
			</div>
			<div>
				<dt class="text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
					Género dramático
				</dt>
				<dd class="mt-1 font-semibold">{obra.genero_term ?? '--'}</dd>
			</div>
			<div>
				<dt class="text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
					Total de versos
				</dt>
				<dd class="mt-1 font-semibold">{totalVersos} vv.</dd>
			</div>
			<div>
				<dt class="text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
					Estructura registrada
				</dt>
				<dd class="mt-1 font-semibold">{estructuraResumen}</dd>
			</div>
			<div>
				<dt class="text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
					Última modificación
				</dt>
				<dd class="mt-1 font-semibold">{updatedAtAbsolute}</dd>
				<dd class="text-xs text-[color:var(--muted-foreground)]">{formatRelative(obra.updated_at)}</dd>
			</div>
		</dl>

		{#if (obra.edicion ?? '').trim().length > 0}
			<div class="mt-4 border-t border-[color:var(--border)] pt-4">
				<div class="mb-1 text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
					Edición base usada por el editor
				</div>
				<div class="space-y-2 text-sm">{@html renderMarkdown(obra.edicion ?? '')}</div>
			</div>
		{/if}
	</header>

	<Tabs tabs={tabs} active={activeTab} onChange={(id) => (activeTab = id as TabId)} />

	{#if activeTab === 'estructura'}
		{#if showMetrica}
			<section class="space-y-4">
				<div class="card p-4">
					<div class="mb-3 flex flex-wrap items-center justify-between gap-3">
						<div class="flex flex-wrap items-center gap-2">
							<button
								type="button"
								class={`border px-3 py-2 text-xs font-semibold tracking-[0.05em] ${metricViewMode === 'obra_completa' ? 'border-[color:var(--gray-800)] bg-[color:var(--gray-800)] text-white' : 'border-[color:var(--border)] bg-white text-[color:var(--gray-800)]'}`}
								onclick={() => (metricViewMode = 'obra_completa')}
							>
								Obra completa
							</button>
							<button
								type="button"
								class={`border px-3 py-2 text-xs font-semibold tracking-[0.05em] ${metricViewMode === 'por_jornadas' ? 'border-[color:var(--gray-800)] bg-[color:var(--gray-800)] text-white' : 'border-[color:var(--border)] bg-white text-[color:var(--gray-800)]'}`}
								onclick={() => (metricViewMode = 'por_jornadas')}
							>
								Por jornadas
							</button>
						</div>
						<div class="flex flex-wrap items-center gap-2">
							<span class="text-xs text-[color:var(--muted-foreground)]">Perfil métrico:</span>
							<button
								type="button"
								class={`border px-2 py-1 text-xs font-semibold ${pieValueMode === 'percent' ? 'border-[color:var(--gray-800)] bg-[color:var(--gray-800)] text-white' : 'border-[color:var(--border)] bg-white text-[color:var(--gray-800)]'}`}
								onclick={() => (pieValueMode = 'percent')}
							>
								%
							</button>
							<button
								type="button"
								class={`border px-2 py-1 text-xs font-semibold ${pieValueMode === 'absolute' ? 'border-[color:var(--gray-800)] bg-[color:var(--gray-800)] text-white' : 'border-[color:var(--border)] bg-white text-[color:var(--gray-800)]'}`}
								onclick={() => (pieValueMode = 'absolute')}
							>
								Nº versos
							</button>
						</div>
					</div>

					{#if secuenciasOrdenadas.length === 0}
						<p class="text-sm text-[color:var(--muted-foreground)]">
							No hay secuencias métricas registradas para esta obra.
						</p>
					{:else if metricViewMode === 'obra_completa'}
						<MetricBarcode
							segments={barSegments}
							totalVerses={totalVersos}
							jornadaMarkers={jornadaMarkers}
							cuadroMarkers={cuadroMarkers}
							colorByForma={colorByForma}
							onOpenSegment={openSequenceModal}
							showSubsegments
						/>
						<div class="mt-2 flex flex-wrap items-center gap-4 text-xs text-[color:var(--muted-foreground)]">
							<span class="inline-flex items-center gap-2">
								<span class="inline-block h-3 w-[2px] bg-[color:var(--gray-900)]"></span>
								Corte de jornada
							</span>
							<span class="inline-flex items-center gap-2">
								<span class="inline-block h-3 w-3 border-l border-dashed border-[color:var(--gray-500)]"></span>
								Corte de cuadro
							</span>
						</div>
					{:else}
						<div class="space-y-5">
							{#each jornadas as jornada (jornada.jornada_id)}
								<div>
									<h3 class="mb-2 text-sm font-semibold">
										Jornada {jornada.jornada_num} (vv. {jornada.v_ini}-{jornada.v_fin})
									</h3>
									<MetricBarcode
										segments={segmentsByJornada.get(jornada.jornada_id) ?? []}
										totalVerses={totalVersos}
										rangeStart={jornada.v_ini}
										rangeEnd={jornada.v_fin}
										cuadroMarkers={cuadroMarkersByJornada.get(jornada.jornada_id) ?? []}
										colorByForma={colorByForma}
										onOpenSegment={openSequenceModal}
										showSubsegments
									/>
								</div>
							{/each}
						</div>
					{/if}
				</div>

				<MetricDistributionPie
					items={ficha.metrica.distribucion_formas}
					sequences={secuenciasOrdenadas}
					colorByForma={colorByForma}
					valueMode={pieValueMode}
				/>
			</section>
		{/if}
	{:else}
		<section class="space-y-4">
			{#if showObservaciones}
				<div class="card p-4">
					<h2 class="text-lg font-semibold">Otras observaciones</h2>
					{#if hasObservaciones}
						<div class="mt-3 space-y-2 text-sm">{@html renderMarkdown(obra.observaciones ?? '')}</div>
					{:else}
						<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">Sin observaciones publicadas.</p>
					{/if}
				</div>
			{/if}

			{#if showBibliografia}
				<div class="card p-4">
					<h2 class="text-lg font-semibold">Bibliografía específica</h2>
					{#if hasBibliografia}
						<div class="mt-3 space-y-2 text-sm">{@html renderMarkdown(obra.bibliografia ?? '')}</div>
					{:else}
						<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">
							Sin bibliografía específica publicada.
						</p>
					{/if}
				</div>
			{/if}
		</section>
	{/if}

	<SequenceDetailModal
		open={selectedSequence !== null}
		secuencia={selectedSequence}
		structure={selectedSequenceStructure}
		comentariosPublicos={showComentarios ? selectedSequenceComments : []}
		index={Math.max(selectedSequenceIndex, 0)}
		total={secuenciasOrdenadas.length}
		canPrev={selectedSequenceIndex > 0}
		canNext={selectedSequenceIndex >= 0 && selectedSequenceIndex < secuenciasOrdenadas.length - 1}
		onClose={closeSequenceModal}
		onPrev={openPrevSequence}
		onNext={openNextSequence}
	/>
</section>
