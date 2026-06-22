<script lang="ts">
	import Tabs from '$lib/components/ui/tabs.svelte';
	import Breadcrumb from '$lib/components/ui/Breadcrumb.svelte';
	import CiteWorkButton from '$lib/components/ficha/CiteWorkButton.svelte';
	import MetricBarcode from '$lib/components/metrica/MetricBarcode.svelte';
	import MetricDistributionPie from '$lib/components/metrica/MetricDistributionPie.svelte';
	import SequenceDetailModal from '$lib/components/ficha/SequenceDetailModal.svelte';
	import FichaAutoriaBlock from '$lib/components/ficha/FichaAutoriaBlock.svelte';
	import OrcidIcon from '$lib/components/icons/OrcidIcon.svelte';
	import SequenceSynopsisView from '$lib/components/editor/SequenceSynopsisView.svelte';
	import { secuenciasToBarSegments } from '$lib/components/ficha/ficha-metric-adapter';
	import { buildSequenceSynopsisGroups } from '$lib/components/editor/sequence-synopsis';
	import { isSectionVisible, FICHA_SECTION_IDS } from '$lib/secciones-publicas';
	import type {
		SequenceModalPayload,
		PublicFichaComentarioPublico,
		PublicFichaSinopsisMetricaSecuencia,
		PublicFichaDistribucionForma
	} from '$lib/types/public-ficha.types';
	import { formatRelative } from '$lib/utils/formatters';
	import { renderMarkdown } from '$lib/utils/markdown';
	import { colorForForma } from '$lib/utils/metric-colors';
	import type { MetricDistributionSlice } from '$lib/components/metrica/metric-display.types';
	import {
		resolveSequenceStructures,
		type ResolvedSequenceStructure
	} from '$lib/utils/sequence-structure';
	import type { PageData } from './$types';

	let { data } = $props<{ data: PageData }>();

	type TabId = 'estructura' | 'sinopsis_metrica' | 'observaciones' | 'bibliografia';
	type MetricViewMode = 'obra_completa' | 'por_jornadas';
	type PieValueMode = 'percent' | 'absolute';
	type ResolvedPublicSequence = ResolvedSequenceStructure<SequenceModalPayload>;

	let activeTab = $state<TabId>('estructura');
	let metricViewMode = $state<MetricViewMode>('obra_completa');
	let pieValueMode = $state<PieValueMode>('percent');
	// Forma resaltada al pasar el ratón por la leyenda del pie. Se aísla por grupo
	// ('obra' o el id de jornada) para que en modo por-jornadas solo ilumine el
	// barcode/pie de esa jornada, no los de las demás.
	let hoveredForma = $state<{ groupId: string; forma: string } | null>(null);

	function formaForGroup(groupId: string): string | null {
		return hoveredForma && hoveredForma.groupId === groupId ? hoveredForma.forma : null;
	}
	let selectedSequenceId = $state<string | null>(null);

	const ficha = $derived(data.ficha);
	const obra = $derived(ficha.obra);

	// --- Visibilidad de secciones (resuelve el pendiente B: ocultar, no vaciar) ---
	const show = (id: string) => isSectionVisible(data.sectionVisibility ?? {}, id);
	const showAutoria = $derived(show(FICHA_SECTION_IDS.autoria));
	const showFuentes = $derived(show(FICHA_SECTION_IDS.fuentes));
	const showMetrica = $derived(show(FICHA_SECTION_IDS.metrica));
	const showSinopsisMetrica = $derived(show(FICHA_SECTION_IDS.sinopsisMetrica));
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
	const tabs = $derived.by(() => {
		const items: { id: TabId; label: string }[] = [];
		if (showMetrica) items.push({ id: 'estructura', label: 'Estructura métrica' });
		if (showSinopsisMetrica) items.push({ id: 'sinopsis_metrica', label: 'Sinopsis' });
		if (showObservaciones) items.push({ id: 'observaciones', label: 'Observaciones' });
		if (showBibliografia) items.push({ id: 'bibliografia', label: 'Bibliografía' });
		return items;
	});

	const datacionLabel = $derived.by(() => {
		const inicio = obra.fecha_inicio_trad;
		const fin = obra.fecha_fin_trad;
		if (inicio !== null && fin !== null && inicio === fin) return `${inicio}`;
		if (inicio !== null && fin !== null) return `${inicio} - ${fin}`;
		if (inicio !== null) return `${inicio}`;
		if (fin !== null) return `${fin}`;
		return '--';
	});
	const variantesLabel = $derived((obra.variantes_titulo ?? []).join(' | '));
	const editorOrcid = $derived((obra.autor_ficha_orcid_publico ?? '').trim());
	const editorOrcidHref = $derived.by(() => {
		if (!editorOrcid) return '';
		if (/^https?:\/\//i.test(editorOrcid)) return editorOrcid;
		return `https://orcid.org/${editorOrcid}`;
	});
	const updatedAtAbsolute = $derived.by(() => {
		if (!obra.updated_at) return 'sin fecha';
		const date = new Date(obra.updated_at);
		if (Number.isNaN(date.valueOf())) return 'sin fecha';
		return new Intl.DateTimeFormat('es-ES', { dateStyle: 'medium', timeStyle: 'short' }).format(date);
	});

	// Colores por forma (compartidos entre barcode y pie). Clave = slug estable de
	// la forma raíz; color resuelto por slug + gama (tipo_forma).
	const colorByForma = $derived.by(() => {
		const map: Record<string, string> = {};
		for (const item of ficha.metrica.distribucion_formas) {
			const key = item.forma_slug ?? item.forma;
			if (!map[key]) map[key] = colorForForma({ slug: key, tipoForma: item.forma_tipo_forma });
		}
		for (const secuencia of secuenciasOrdenadas) {
			const key = secuencia.estrofa_forma_slug ?? secuencia.estrofa_forma_term;
			if (!map[key]) map[key] = colorForForma({ slug: key, tipoForma: secuencia.estrofa_tipo_forma });
		}
		return map;
	});

	// Slices de la distribución obra-completa con clave de color (slug) explícita.
	const distribucionFormasSlices = $derived.by(() =>
		ficha.metrica.distribucion_formas.map((item: PublicFichaDistribucionForma) => ({
			forma: item.forma,
			colorKey: item.forma_slug ?? item.forma,
			versos: item.versos,
			porcentaje: item.porcentaje
		}))
	);

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
	function buildMetricDistribution(sequences: SequenceModalPayload[]): MetricDistributionSlice[] {
		const total = sequences.reduce((sum, sequence) => sum + (sequence.n_versos ?? 0), 0);
		// Agrupa por forma raíz usando el slug como clave estable; conserva la
		// etiqueta visible y el tipo_forma (gama) para el color.
		const byForma = new Map<string, { forma: string; colorKey: string; tipoForma: string | null; versos: number }>();
		for (const sequence of sequences) {
			const versos = sequence.n_versos ?? 0;
			if (versos <= 0) continue;
			const colorKey = sequence.estrofa_forma_slug ?? sequence.estrofa_forma_term;
			const current = byForma.get(colorKey);
			if (current) {
				current.versos += versos;
			} else {
				byForma.set(colorKey, {
					forma: sequence.estrofa_forma_term,
					colorKey,
					tipoForma: sequence.estrofa_tipo_forma,
					versos
				});
			}
		}
		return [...byForma.values()]
			.map((entry) => ({
				forma: entry.forma,
				colorKey: entry.colorKey,
				versos: entry.versos,
				porcentaje: total > 0 ? Math.round((entry.versos / total) * 10000) / 100 : 0
			}))
			.sort((a, b) => b.versos - a.versos || a.forma.localeCompare(b.forma, 'es'));
	}
	const metricProfilesByJornada = $derived.by(() =>
		jornadas.map((jornada) => {
			const sequences = resolvedPublicSequences
				.filter((item) => item.jornada.jornadaId === jornada.jornada_id)
				.map((item) => item.sequence);
			return {
				jornada,
				sequences,
				distribution: buildMetricDistribution(sequences)
			};
		})
	);
	const sinopsisMetricaSequences = $derived.by(
		(): PublicFichaSinopsisMetricaSecuencia[] => ficha.sinopsis_metrica?.secuencias ?? []
	);
	// Las secuencias de sinopsis ya traen estrofa_forma_slug/estrofa_tipo_forma
	// desde la RPC, así que el color del borde sale directo (igual que barcode/pie).
	const sinopsisMetricaGroups = $derived.by(() =>
		buildSequenceSynopsisGroups({
			secuencias: sinopsisMetricaSequences,
			jornadas,
			cuadros
		})
	);
	const sinopsisMetricaMissingCount = $derived.by(
		() => sinopsisMetricaSequences.filter((secuencia) => !(secuencia.sinopsis ?? '').trim()).length
	);

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
	const estructuraItems = $derived.by(() => [
		{ label: jornadas.length === 1 ? 'jornada' : 'jornadas', value: jornadas.length },
		{ label: cuadros.length === 1 ? 'cuadro' : 'cuadros', value: cuadros.length },
		{
			label: secuenciasOrdenadas.length === 1 ? 'secuencia métrica' : 'secuencias métricas',
			value: secuenciasOrdenadas.length
		}
	]);

	$effect(() => {
		if (tabs.some((tab) => tab.id === activeTab)) return;
		activeTab = tabs[0]?.id ?? 'estructura';
	});
</script>

<section class="space-y-6">
	<Breadcrumb
		items={[
			{ label: 'Catálogo', href: '/catalogo' },
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
				obraPath={`/obras/${obra.slug}`}
			/>
		</div>

		{#if data.canSeeAllPublished && !obra.visible_publico}
			<div class="mt-4 border border-[color:var(--border)] bg-[color:var(--muted)] p-3 text-sm text-[color:var(--muted-foreground)]">
				Esta obra está publicada en flujo editorial, pero no visible sin login.
			</div>
		{/if}

		<dl class="mt-4 grid gap-x-6 gap-y-4 text-sm md:grid-cols-2 xl:grid-cols-4">
			<div>
				<dt class="text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
					Datación
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
					Estructura
				</dt>
				<dd class="mt-1 flex flex-wrap gap-2">
					{#each estructuraItems as item}
						<span class="border-l-2 border-[color:var(--border)] bg-[color:var(--gray-50)] px-2 py-1">
							<span class="font-semibold">{item.value}</span>
							<span class="text-xs text-[color:var(--muted-foreground)]">{item.label}</span>
						</span>
					{/each}
				</dd>
			</div>
		</dl>

		<dl class="mt-4 flex flex-wrap gap-x-6 gap-y-3 border-t border-[color:var(--border)] pt-3 text-sm">
			{#if obra.autor_ficha_publico}
				<div>
					<dt class="text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
						Editor a cargo
					</dt>
					<dd class="mt-1 flex items-center gap-2 font-semibold">
						<span>{obra.autor_ficha_publico}</span>
						{#if editorOrcidHref}
							<a
								class="inline-flex items-center text-[color:var(--muted-foreground)] transition-colors hover:text-[color:var(--foreground)]"
								href={editorOrcidHref}
								target="_blank"
								rel="noreferrer"
								aria-label={`ORCID de ${obra.autor_ficha_publico}`}
							>
								<OrcidIcon size={15} />
								<span class="sr-only">ORCID</span>
							</a>
						{/if}
					</dd>
				</div>
			{/if}
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
					Edición base usada
				</div>
				<div class="space-y-2 text-sm">{@html renderMarkdown(obra.edicion ?? '')}</div>
			</div>
		{/if}
	</header>

	{#if tabs.length > 0}
		<Tabs tabs={tabs} active={activeTab} onChange={(id) => (activeTab = id as TabId)} />
	{/if}

	{#if activeTab === 'estructura'}
		{#if showMetrica}
			<section class="space-y-4">
				<div class="space-y-3">
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
							highlightedForma={formaForGroup('obra')}
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
										highlightedForma={formaForGroup(jornada.jornada_id)}
										showSubsegments
									/>
								</div>
							{/each}
						</div>
					{/if}
				</div>

				{#if metricViewMode === 'obra_completa'}
					<MetricDistributionPie
						items={distribucionFormasSlices}
						sequences={secuenciasOrdenadas}
						colorByForma={colorByForma}
						valueMode={pieValueMode}
						highlightedForma={formaForGroup('obra')}
						onHoverForma={(forma) => (hoveredForma = forma ? { groupId: 'obra', forma } : null)}
					/>
				{:else}
					<div class="space-y-5">
						{#each metricProfilesByJornada as profile (profile.jornada.jornada_id)}
							<MetricDistributionPie
								title={`Perfil métrico · Jornada ${profile.jornada.jornada_num}`}
								items={profile.distribution}
								sequences={profile.sequences}
								colorByForma={colorByForma}
								valueMode={pieValueMode}
								highlightedForma={formaForGroup(profile.jornada.jornada_id)}
								onHoverForma={(forma) =>
									(hoveredForma = forma ? { groupId: profile.jornada.jornada_id, forma } : null)}
							/>
						{/each}
					</div>
				{/if}
			</section>
		{/if}
	{:else if activeTab === 'sinopsis_metrica'}
		{#if showSinopsisMetrica}
			<section class="space-y-4">
				<div>
					<h2 class="text-lg font-semibold">Sinopsis</h2>
					<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
						{sinopsisMetricaSequences.length} secuencias
						{#if sinopsisMetricaMissingCount > 0}
							· {sinopsisMetricaMissingCount} sin sinopsis
						{/if}
					</p>
				</div>
				<SequenceSynopsisView groups={sinopsisMetricaGroups} colorByForma={colorByForma} />
			</section>
		{/if}
	{:else if activeTab === 'observaciones'}
		{#if showObservaciones}
			<section class="space-y-3 border-t border-[color:var(--border)] pt-4">
				<h2 class="text-lg font-semibold">Otras observaciones</h2>
				{#if hasObservaciones}
					<div class="space-y-2 text-sm leading-7">{@html renderMarkdown(obra.observaciones ?? '')}</div>
				{:else}
					<p class="text-sm text-[color:var(--muted-foreground)]">Sin observaciones publicadas.</p>
				{/if}
			</section>
		{/if}
	{:else if activeTab === 'bibliografia'}
		{#if showBibliografia}
			<section class="space-y-3 border-t border-[color:var(--border)] pt-4">
				<h2 class="text-lg font-semibold">Bibliografía</h2>
				{#if hasBibliografia}
					<div class="space-y-2 text-sm leading-7">{@html renderMarkdown(obra.bibliografia ?? '')}</div>
				{:else}
					<p class="text-sm text-[color:var(--muted-foreground)]">Sin bibliografía publicada.</p>
				{/if}
			</section>
		{/if}
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
