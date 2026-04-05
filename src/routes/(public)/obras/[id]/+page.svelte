<script lang="ts">
	import { onMount } from 'svelte';
	import Mail from 'lucide-svelte/icons/mail';
	import Tabs from '$lib/components/ui/tabs.svelte';
	import CiteWorkButton from '$lib/components/ficha/CiteWorkButton.svelte';
	import PublicMetricBarcode from '$lib/components/ficha/PublicMetricBarcode.svelte';
	import MetricDistributionPie from '$lib/components/ficha/MetricDistributionPie.svelte';
	import SequenceDetailModal from '$lib/components/ficha/SequenceDetailModal.svelte';
	import OrcidIcon from '$lib/components/icons/OrcidIcon.svelte';
	import type { SequenceModalPayload } from '$lib/types/public-ficha.types';
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

	let activeTab = $state<TabId>('estructura');
	let metricViewMode = $state<MetricViewMode>('obra_completa');
	let pieValueMode = $state<PieValueMode>('percent');
	let selectedSequenceId = $state<string | null>(null);
	let showDateSource = $state(false);
	let dateSourceWrapEl = $state<HTMLDivElement | null>(null);

	type ResolvedPublicSequence = ResolvedSequenceStructure<SequenceModalPayload>;

	const ficha = $derived(data.ficha);
	const obra = $derived(ficha.obra);
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
		resolveSequenceStructures({
			secuencias: secuenciasOrdenadas,
			jornadas,
			cuadros
		})
	);
	const totalVersos = $derived.by(() => {
		const fromObra = obra.total_versos ?? 0;
		const fromJornadas = jornadas.reduce((max, jornada) => Math.max(max, jornada.v_fin), 0);
		const fromSecuencias = secuenciasOrdenadas.reduce((max, secuencia) => Math.max(max, secuencia.v_fin), 0);
		return Math.max(1, fromObra, fromJornadas, fromSecuencias);
	});

	const tabs = [
		{ id: 'estructura', label: 'Estructura métrica' },
		{ id: 'observaciones', label: 'Observaciones' }
	];

	const datacionLabel = $derived(`${obra.fecha_inicio_trad ?? '--'} - ${obra.fecha_fin_trad ?? '--'}`);
	const hasFuenteFecha = $derived((obra.fuente_fecha ?? '').trim().length > 0);
	const variantesLabel = $derived((obra.variantes_titulo ?? []).join(' | '));
	const updatedAtAbsolute = $derived.by(() => {
		if (!obra.updated_at) return 'sin fecha';
		const date = new Date(obra.updated_at);
		if (Number.isNaN(date.valueOf())) return 'sin fecha';
		return new Intl.DateTimeFormat('es-ES', {
			dateStyle: 'medium',
			timeStyle: 'short'
		}).format(date);
	});
	const autorFichaNombre = $derived((obra.autor_ficha_publico ?? '').trim() || 'No indicado');
	const autorFichaEmail = $derived((obra.autor_ficha_email_publico ?? '').trim());
	const autorFichaEmailHref = $derived.by(() =>
		autorFichaEmail ? `mailto:${autorFichaEmail}` : null
	);
	const autorFichaOrcidUrl = $derived.by(() => normalizeOrcidUrl(obra.autor_ficha_orcid_publico));

	const jornadaMarkers = $derived.by(() =>
		jornadas.map((jornada) => jornada.v_fin).filter((marker) => marker > 0 && marker < totalVersos)
	);
	const cuadroMarkers = $derived.by(() =>
		cuadros.map((cuadro) => cuadro.v_fin).filter((marker) => marker > 0 && marker < totalVersos)
	);
	const cuadroMarkersByJornada = $derived.by(() => {
		const map = new Map<string, number[]>();
		for (const jornada of jornadas) {
			const markers = cuadros
				.filter((cuadro) => cuadro.jornada_id === jornada.jornada_id)
				.map((cuadro) => cuadro.v_fin);
			map.set(jornada.jornada_id, markers);
		}
		return map;
	});

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

	const secuenciasByJornada = $derived.by(() => {
		const byJornada = new Map<string, SequenceModalPayload[]>();
		for (const item of resolvedPublicSequences) {
			if (!item.jornada.jornadaId) continue;
			const current = byJornada.get(item.jornada.jornadaId) ?? [];
			current.push(item.sequence);
			byJornada.set(item.jornada.jornadaId, current);
		}
		return byJornada;
	});

	const selectedSequenceIndex = $derived.by(() => {
		if (!selectedSequenceId) return -1;
		return resolvedPublicSequences.findIndex(
			(item) => item.sequence.secuencia_id === selectedSequenceId
		);
	});
	const selectedSequenceStructure = $derived.by((): ResolvedPublicSequence | null => {
		if (selectedSequenceIndex < 0) return null;
		return resolvedPublicSequences[selectedSequenceIndex] ?? null;
	});
	const selectedSequence = $derived.by(() => {
		return selectedSequenceStructure?.sequence ?? null;
	});

	function openSequenceModal(secuenciaId: string) {
		selectedSequenceId = secuenciaId;
	}

	function closeSequenceModal() {
		selectedSequenceId = null;
	}

	function openPrevSequence() {
		if (selectedSequenceIndex <= 0) return;
		selectedSequenceId =
			resolvedPublicSequences[selectedSequenceIndex - 1]?.sequence.secuencia_id ?? null;
	}

	function openNextSequence() {
		if (
			selectedSequenceIndex < 0 ||
			selectedSequenceIndex >= resolvedPublicSequences.length - 1
		) {
			return;
		}
		selectedSequenceId =
			resolvedPublicSequences[selectedSequenceIndex + 1]?.sequence.secuencia_id ?? null;
	}

	function toggleDateSource() {
		showDateSource = !showDateSource;
	}

	function normalizeOrcidUrl(orcid: string | null | undefined): string | null {
		const value = (orcid ?? '').trim();
		if (!value) return null;
		if (/^https?:\/\//i.test(value)) return value;
		const id = value
			.replace(/^https?:\/\/(www\.)?orcid\.org\//i, '')
			.replace(/^(www\.)?orcid\.org\//i, '');
		return id ? `https://orcid.org/${id}` : null;
	}

	function handleDateSourceDocumentMouseDown(event: MouseEvent) {
		if (!showDateSource) return;
		const target = event.target;
		if (!(target instanceof Node)) return;
		if (dateSourceWrapEl?.contains(target)) return;
		showDateSource = false;
	}

	function handleDateSourceEscape(event: KeyboardEvent) {
		if (event.key !== 'Escape') return;
		showDateSource = false;
	}

	onMount(() => {
		document.addEventListener('mousedown', handleDateSourceDocumentMouseDown);
		document.addEventListener('keydown', handleDateSourceEscape);
		return () => {
			document.removeEventListener('mousedown', handleDateSourceDocumentMouseDown);
			document.removeEventListener('keydown', handleDateSourceEscape);
		};
	});
</script>

<section class="space-y-6">
	<nav class="text-xs font-semibold tracking-[0.06em] text-[color:var(--muted-foreground)]">
		<a href="/obras" class="underline-offset-2 hover:underline">Catalogo</a>
		<span class="mx-2">></span>
		<span class="text-[color:var(--gray-800)]">{obra.titulo}</span>
	</nav>

	<header class="card p-4 md:p-5">
		<div class="flex flex-wrap items-start justify-between gap-4">
			<div class="min-w-0">
				<h1 class="font-display text-3xl text-[color:var(--gray-900)] md:text-4xl">{obra.titulo}</h1>
				{#if variantesLabel}
					<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">{variantesLabel}</p>
				{/if}
				<div class="mt-3 flex flex-wrap items-center gap-2 text-sm">
					<span class="font-semibold text-[color:var(--gray-900)]">Autoría:</span>
					{#if ficha.autoria.autores.length === 0}
						<span class="text-[color:var(--muted-foreground)]">No indicada</span>
					{:else}
						{#each ficha.autoria.autores as autor, index (autor.autor_id)}
							{#if index > 0}
								<span class="text-[color:var(--muted-foreground)]">·</span>
							{/if}
							<a class="underline-offset-2 hover:underline" href={`/autores/${autor.autor_id}`}
								>{autor.nombre_completo}</a
							>
						{/each}
					{/if}
					{#if (ficha.autoria.informe_url ?? '').trim().length > 0}
						<a
							class="inline-flex items-center border border-[color:var(--border)] bg-white px-2 py-1 text-xs font-semibold tracking-[0.03em] hover:bg-[color:var(--muted)]"
							href={ficha.autoria.informe_url ?? '#'}
							target="_blank"
							rel="noreferrer noopener"
							aria-label="Abrir informe externo de autoría"
						>
							Informe
						</a>
					{/if}
				</div>
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
				Esta obra esta publicada en flujo editorial, pero no visible sin login.
			</div>
		{/if}

		<div class="mt-4 grid gap-3 md:grid-cols-2 xl:grid-cols-4">
			<div class="border border-[color:var(--border)] bg-white p-3 text-sm">
				<div class="text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
					Datacion tradicional
				</div>
				<div class="mt-1 flex items-center gap-2 font-semibold">
					<span>{datacionLabel}</span>
					{#if hasFuenteFecha}
						<div class="group relative inline-block" bind:this={dateSourceWrapEl}>
							<button
								type="button"
								class="inline-flex h-5 w-5 items-center justify-center border border-[color:var(--border)] bg-white text-[11px] font-semibold"
								aria-label="Mostrar fuente bibliográfica de datación"
								onclick={toggleDateSource}
							>
								i
							</button>
							<div
								class={`absolute left-0 top-[calc(100%+6px)] z-50 w-80 border border-[color:var(--border)] bg-white p-3 text-xs shadow-md ${showDateSource ? 'block' : 'hidden group-hover:block group-focus-within:block'}`}
							>
								<div class="mb-1 text-[11px] font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
									Fuente de fecha
								</div>
								<div class="space-y-1 text-[color:var(--gray-800)]">
									{@html renderMarkdown(obra.fuente_fecha ?? '')}
								</div>
							</div>
						</div>
					{/if}
				</div>
			</div>

			<div class="border border-[color:var(--border)] bg-white p-3 text-sm">
				<div class="text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
					Genero dramatico
				</div>
				<div class="mt-1 font-semibold">{obra.genero_term ?? '--'}</div>
			</div>

			<div class="border border-[color:var(--border)] bg-white p-3 text-sm">
				<div class="text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
					Total de versos
				</div>
				<div class="mt-1 font-semibold">{totalVersos} vv.</div>
			</div>

			<div class="border border-[color:var(--border)] bg-white p-3 text-sm">
				<div class="text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
					Ficha
				</div>
				<div class="mt-1 space-y-1">
					<p class="flex flex-wrap items-center gap-2">
						<strong>Autor:</strong>
						<span>{autorFichaNombre}</span>
						{#if autorFichaEmailHref}
							<a
								class="inline-flex h-6 w-6 items-center justify-center rounded border border-[color:var(--border)] text-[color:var(--gray-700)] hover:bg-[color:var(--muted)]"
								href={autorFichaEmailHref}
								aria-label={`Enviar email a ${autorFichaNombre}`}
								title={autorFichaEmail}
							>
								<Mail size={14} aria-hidden="true" />
							</a>
						{/if}
						{#if autorFichaOrcidUrl}
							<a
								class="inline-flex h-6 w-6 items-center justify-center rounded border border-[color:var(--border)] text-[color:var(--gray-700)] hover:bg-[color:var(--muted)]"
								href={autorFichaOrcidUrl}
								target="_blank"
								rel="noreferrer noopener"
								aria-label={`Abrir ORCID de ${autorFichaNombre}`}
								title="Abrir ORCID"
							>
								<OrcidIcon size={14} />
							</a>
						{/if}
					</p>
					<p>
						<strong>Ultima mod.:</strong> {updatedAtAbsolute} ({formatRelative(obra.updated_at)})
					</p>
				</div>
			</div>
		</div>

		<div class="mt-4 border border-[color:var(--border)] bg-white p-3">
			<div class="mb-1 text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
				Edicion base usada por el editor
			</div>
			{#if (obra.edicion ?? '').trim().length > 0}
				<div class="space-y-2 text-sm">{@html renderMarkdown(obra.edicion ?? '')}</div>
			{:else}
				<p class="text-sm text-[color:var(--muted-foreground)]">Sin dato.</p>
			{/if}
		</div>
	</header>

	<Tabs tabs={tabs} active={activeTab} onChange={(id) => (activeTab = id as TabId)} />

	{#if activeTab === 'estructura'}
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
					<PublicMetricBarcode
						segments={secuenciasOrdenadas}
						totalVerses={totalVersos}
						jornadaMarkers={jornadaMarkers}
						cuadroMarkers={cuadroMarkers}
						colorByForma={colorByForma}
						onOpenSequence={openSequenceModal}
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
					<div class="space-y-4">
						{#each jornadas as jornada (jornada.jornada_id)}
							<div class="border border-[color:var(--border)] bg-white p-3">
								<h3 class="mb-2 text-sm font-semibold">
									Jornada {jornada.jornada_num} (vv. {jornada.v_ini}-{jornada.v_fin})
								</h3>
								<PublicMetricBarcode
									segments={secuenciasByJornada.get(jornada.jornada_id) ?? []}
									totalVerses={totalVersos}
									rangeStart={jornada.v_ini}
									rangeEnd={jornada.v_fin}
									cuadroMarkers={cuadroMarkersByJornada.get(jornada.jornada_id) ?? []}
									colorByForma={colorByForma}
									onOpenSequence={openSequenceModal}
								/>
							</div>
						{/each}
					</div>
				{/if}
			</div>

			<MetricDistributionPie
				items={ficha.metrica.distribucion_formas}
				colorByForma={colorByForma}
				valueMode={pieValueMode}
			/>
		</section>
	{:else}
		<section class="space-y-4">
			<div class="card p-4">
				<h2 class="text-lg font-semibold">Otras observaciones</h2>
				{#if (obra.observaciones ?? '').trim().length > 0}
					<div class="mt-3 space-y-2 text-sm">{@html renderMarkdown(obra.observaciones ?? '')}</div>
				{:else}
					<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">Sin observaciones publicadas.</p>
				{/if}
			</div>

			<div class="card p-4">
				<h2 class="text-lg font-semibold">Bibliografía específica</h2>
				{#if (obra.bibliografia ?? '').trim().length > 0}
					<div class="mt-3 space-y-2 text-sm">{@html renderMarkdown(obra.bibliografia ?? '')}</div>
				{:else}
					<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">
						Sin bibliografía específica publicada.
					</p>
				{/if}
			</div>
		</section>
	{/if}

	<SequenceDetailModal
		open={selectedSequence !== null}
		secuencia={selectedSequence}
		structure={selectedSequenceStructure}
		index={Math.max(selectedSequenceIndex, 0)}
		total={secuenciasOrdenadas.length}
		canPrev={selectedSequenceIndex > 0}
		canNext={selectedSequenceIndex >= 0 && selectedSequenceIndex < secuenciasOrdenadas.length - 1}
		onClose={closeSequenceModal}
		onPrev={openPrevSequence}
		onNext={openNextSequence}
	/>
</section>

