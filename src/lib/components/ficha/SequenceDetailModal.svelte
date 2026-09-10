<script lang="ts">
	// Lectura editorial de una secuencia: identidad, construcción, observación y contexto.
	import { ArrowLeft, ArrowRight, ChevronDown, X } from 'lucide-svelte';
	import { portal } from '$lib/actions/portal';
	import type {
		PublicFichaComentarioPublico,
		PublicFichaEsquemaRima,
		SequenceModalPayload
	} from '$lib/types/public-ficha.types';
	import { renderMarkdown } from '$lib/utils/markdown';
	import { enunciationPassageLabel, enunciationType } from '$lib/metrica/enunciation';
	import type {
		ResolvedSequenceStructure,
		SequenceStructureTramo
	} from '$lib/utils/sequence-structure';
	import {
		buildSequenceMetreCoverage,
		buildSequenceRhymeSchemeOccurrences,
		formatMetricCount
	} from '$lib/components/metrica/metric-distribution';

	type SequenceModalStructure = ResolvedSequenceStructure<SequenceModalPayload>;

	interface MetricPart {
		key: string;
		label: string;
		vIni: number | null;
		vFin: number | null;
		schemes: string[];
		order: number;
	}

	interface FeatureGroup {
		label: string;
		values: string[];
	}

	const props = $props<{
		open: boolean;
		secuencia: SequenceModalPayload | null;
		structure: SequenceModalStructure | null;
		comentariosPublicos?: PublicFichaComentarioPublico[];
		index: number;
		total: number;
		canPrev: boolean;
		canNext: boolean;
		previousLabel?: string | null;
		nextLabel?: string | null;
		onClose: () => void;
		onPrev: () => void;
		onNext: () => void;
	}>();

	let dialogElement: HTMLDivElement | undefined = $state();

	$effect(() => {
		if (!props.open) return;
		const previouslyFocused = document.activeElement instanceof HTMLElement
			? document.activeElement
			: null;
		const previousOverflow = document.body.style.overflow;
		document.body.style.overflow = 'hidden';
		requestAnimationFrame(() => dialogElement?.focus());

		const handleKeydown = (event: KeyboardEvent) => {
			if (event.key === 'Escape') {
				event.preventDefault();
				props.onClose();
			} else if (event.key === 'ArrowLeft' && props.canPrev) {
				event.preventDefault();
				props.onPrev();
			} else if (event.key === 'ArrowRight' && props.canNext) {
				event.preventDefault();
				props.onNext();
			}
		};
		document.addEventListener('keydown', handleKeydown);

		return () => {
			document.removeEventListener('keydown', handleKeydown);
			document.body.style.overflow = previousOverflow;
			previouslyFocused?.focus();
		};
	});

	function formatJornadaLabel() {
		if (props.structure) return props.structure.jornada.label;
		if (props.secuencia?.jornada_num !== null && props.secuencia?.jornada_num !== undefined) {
			return `Jornada ${props.secuencia.jornada_num}`;
		}
		return 'Sin dato';
	}

	function formatCuadroLabel(cuadroNum: number | null) {
		return cuadroNum === null ? 'Sin cuadro' : `Cuadro ${cuadroNum}`;
	}

	function formatCuadroSummary() {
		if (props.structure) {
			if (!props.structure.spansMultipleCuadros) return props.structure.startingCuadro.label;
			return `${props.structure.startingCuadro.label} → ${props.structure.endingCuadro.label}`;
		}
		if (props.secuencia?.cuadro_num !== null && props.secuencia?.cuadro_num !== undefined) {
			return formatCuadroLabel(props.secuencia.cuadro_num);
		}
		return 'Sin dato';
	}

	function formatTramoLabel(tramo: SequenceStructureTramo) {
		return `${formatCuadroLabel(tramo.cuadroNum)} · vv. ${tramo.vIni}–${tramo.vFin}`;
	}

	function humanize(value: string) {
		const text = value.replaceAll('_', ' ').trim();
		return text.length > 0 ? `${text.charAt(0).toLocaleUpperCase('es')}${text.slice(1)}` : 'Sin dato';
	}

	function formatIntervencionValue(value: string | null) {
		if (value === null) return 'Sin dato';
		if (value === 'sin_intervencion') return 'No';
		if (value === 'exclusiva') return 'Exclusiva';
		if (value === 'compartida') return 'Compartida';
		return humanize(value);
	}

	function formatNullableBoolean(value: boolean | null) {
		if (value === null) return 'Sin dato';
		return value ? 'Sí' : 'No';
	}

	function partKey(row: PublicFichaEsquemaRima, label: string) {
		if (row.realizacion_seccion_id) return `realizacion:${row.realizacion_id ?? row.eleccion_id}`;
		return `tratada:${row.realizacion_id ?? row.eleccion_id}:${row.seccion_id ?? label}`;
	}

	function buildMetricParts(sequence: SequenceModalPayload): MetricPart[] {
		const grouped = new Map<string, MetricPart>();
		for (const row of sequence.esquemas_rima ?? []) {
			const label = (row.realizacion_seccion_nombre ?? row.seccion_nombre ?? '').trim();
			if (!label) continue;
			const key = partKey(row, label);
			const isMaterialPart = Boolean(row.realizacion_seccion_id);
			const current = grouped.get(key) ?? {
				key,
				label,
				vIni: isMaterialPart ? row.realizacion_v_ini : null,
				vFin: isMaterialPart ? row.realizacion_v_fin : null,
				schemes: [],
				order:
					row.realizacion_seccion_orden ??
					row.seccion_orden ??
					row.realizacion_orden ??
					Number.MAX_SAFE_INTEGER
			};
			const notation = (row.notacion ?? row.nombre ?? '').trim();
			if (notation && !current.schemes.includes(notation)) current.schemes.push(notation);
			grouped.set(key, current);
		}

		const parts = [...grouped.values()].sort(
			(a, b) =>
				(a.vIni ?? Number.MAX_SAFE_INTEGER) - (b.vIni ?? Number.MAX_SAFE_INTEGER) ||
				a.order - b.order ||
				a.label.localeCompare(b.label, 'es')
		);
		const totals = new Map<string, number>();
		for (const part of parts) totals.set(part.label, (totals.get(part.label) ?? 0) + 1);
		const seen = new Map<string, number>();
		return parts.map((part) => {
			if ((totals.get(part.label) ?? 0) < 2) return part;
			const position = (seen.get(part.label) ?? 0) + 1;
			seen.set(part.label, position);
			return { ...part, label: `${part.label} ${position}` };
		});
	}

	function buildFeatureGroups(sequence: SequenceModalPayload): FeatureGroup[] {
		const grouped = new Map<string, Set<string>>();
		for (const row of sequence.rasgos ?? []) {
			const values = grouped.get(row.rasgo_nombre) ?? new Set<string>();
			values.add(row.valor_nombre);
			grouped.set(row.rasgo_nombre, values);
		}
		return [...grouped.entries()].map(([label, values]) => ({ label, values: [...values] }));
	}

	const metricForm = $derived(props.secuencia?.forma_nombre.trim() || 'Secuencia métrica');
	const metricArchitecture = $derived.by(() => {
		const architecture = props.secuencia?.arquitectura_nombre.trim() ?? '';
		if (!architecture || architecture.toLocaleLowerCase('es') === metricForm.toLocaleLowerCase('es')) {
			return null;
		}
		return architecture;
	});
	const schemes = $derived(
		props.secuencia ? buildSequenceRhymeSchemeOccurrences(props.secuencia) : []
	);
	const metres = $derived(props.secuencia ? buildSequenceMetreCoverage(props.secuencia) : []);
	const varieties = $derived.by(() => {
		const names = new Set((props.secuencia?.variedades ?? []).map((row) => row.variedad_nombre));
		return [...names];
	});
	const metricParts = $derived(props.secuencia ? buildMetricParts(props.secuencia) : []);
	const features = $derived(props.secuencia ? buildFeatureGroups(props.secuencia) : []);
	const deviations = $derived(props.secuencia?.desviaciones ?? []);
	const enunciationRanges = $derived(
		(props.secuencia?.caracterizaciones_rango ?? []).filter((item) =>
			enunciationType(item.tipo_caracterizacion_rango_term) !== null
		)
	);
	const otherRanges = $derived(
		(props.secuencia?.caracterizaciones_rango ?? []).filter(
			(item) => enunciationType(item.tipo_caracterizacion_rango_term) === null
		)
	);
	const hasObservedData = $derived(features.length > 0 || deviations.length > 0);
	const hasMetricDetail = $derived(
		schemes.length > 0 || metres.length > 0 || varieties.length > 0 || metricParts.length > 0
	);
	const synopsis = $derived((props.secuencia?.sinopsis ?? '').trim());
	const publicComments = $derived(props.comentariosPublicos ?? []);
	const hasEditorialContent = $derived(synopsis.length > 0 || publicComments.length > 0);
	const editorialHeading = $derived(
		synopsis.length > 0 && publicComments.length > 0
			? 'Sinopsis y notas'
			: synopsis.length > 0
				? 'Sinopsis'
				: 'Notas públicas'
	);
</script>

{#if props.open && props.secuencia}
	<div
		use:portal
		class="fixed inset-0 z-[120] flex items-end justify-center sm:items-center sm:p-6 lg:p-10"
	>
		<button
			type="button"
			class="absolute inset-0"
			style="background: rgba(15, 15, 15, 0.78); backdrop-filter: blur(2px);"
			aria-label="Cerrar detalle de secuencia"
			onclick={props.onClose}
		></button>

		<div
			bind:this={dialogElement}
			class="relative z-[1] grid h-dvh w-full grid-rows-[auto_minmax(0,1fr)_auto] overflow-hidden bg-[color:var(--background)] shadow-2xl outline-none sm:h-auto sm:max-h-[calc(100dvh-3rem)] sm:rounded-xl sm:border sm:border-[color:var(--border)]"
			style="max-width: 56rem;"
			role="dialog"
			aria-modal="true"
			aria-labelledby="sequence-modal-title"
			tabindex="-1"
		>
			<header class="flex items-start justify-between gap-4 border-b border-t-4 border-[color:var(--border)] border-t-[color:var(--primary)] bg-white px-5 py-4 sm:px-8 sm:py-6">
				<div class="min-w-0">
					<p class="mb-2 flex flex-wrap items-center gap-x-2 gap-y-1 text-[0.7rem] font-semibold uppercase tracking-[0.07em] text-[color:var(--muted-foreground)]">
						<span class="text-[color:var(--primary)]">Secuencia {props.index + 1} de {props.total}</span>
						<span aria-hidden="true">·</span>
						<span>{formatJornadaLabel()}</span>
						<span aria-hidden="true">·</span>
						<span>{formatCuadroSummary()}</span>
					</p>
					<h2 id="sequence-modal-title" class="leading-tight tracking-[-0.01em]">
						<span class="block text-xl font-semibold text-[color:var(--foreground)] sm:text-2xl">{metricForm}</span>
						{#if metricArchitecture}
							<span class="mt-1 block text-sm font-medium tracking-normal text-[color:var(--muted-foreground)] sm:text-base">{metricArchitecture}</span>
						{/if}
					</h2>
					<p class="mt-1.5 text-sm text-[color:var(--muted-foreground)]">
						Versos {props.secuencia.v_ini}–{props.secuencia.v_fin} · {props.secuencia.n_versos}
						{props.secuencia.n_versos === 1 ? 'verso' : 'versos'}
					</p>
				</div>
				<button
					type="button"
					class="grid h-10 w-10 shrink-0 place-items-center rounded-full border border-transparent text-[color:var(--muted-foreground)] transition-[color,background-color,border-color,box-shadow] hover:border-[color:var(--border)] hover:bg-[color:var(--gray-100)] hover:text-[color:var(--foreground)] hover:shadow-sm active:bg-[color:var(--gray-200)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[color:var(--primary)]"
					style="display: flex; align-items: center; justify-content: center; padding: 0;"
					aria-label="Cerrar"
					onclick={props.onClose}
				>
					<X class="h-5 w-5" aria-hidden="true" />
				</button>
			</header>

			<div class="overflow-y-auto overscroll-contain px-5 sm:px-8">
				<section class="border-b border-[color:var(--border)] py-6 sm:py-7">
					<h3 class="mb-4 text-base font-semibold">Construcción métrica</h3>

					{#if hasMetricDetail}
						<dl class="divide-y divide-[color:var(--border)] rounded-lg border border-[color:var(--border)] bg-white text-sm">
							{#if metres.length > 0}
								<div class="grid gap-2 px-4 py-3.5 sm:grid-cols-[9rem_1fr] sm:gap-5">
									<dt class="font-medium text-[color:var(--muted-foreground)]">{metres.length === 1 ? 'Metro' : 'Metros'}</dt>
									<dd class="space-y-1">
										{#each metres as metre (metre.label)}
											<div class="flex flex-wrap items-baseline justify-between gap-3 leading-6">
												<span>{metre.label}</span>
												<span class="rounded-full bg-[color:var(--muted)] px-2 py-0.5 text-xs text-[color:var(--muted-foreground)]">{metre.versos} vv.</span>
											</div>
										{/each}
									</dd>
								</div>
							{/if}

							{#if schemes.length > 0}
								<div class="grid gap-2 px-4 py-3.5 sm:grid-cols-[9rem_1fr] sm:gap-5">
									<dt class="font-medium text-[color:var(--muted-foreground)]">{schemes.length === 1 ? 'Esquema de rima' : 'Esquemas de rima'}</dt>
									<dd class="space-y-2">
										{#each schemes as scheme (`${scheme.unidad}:${scheme.label}`)}
											<div class="flex flex-wrap items-baseline justify-between gap-3 leading-6">
												<span class="font-mono font-medium tracking-wide">{scheme.label}</span>
												{#if scheme.cantidad > 1 || schemes.length > 1}
													<span class="rounded-full bg-[color:var(--muted)] px-2 py-0.5 text-xs text-[color:var(--muted-foreground)]">{formatMetricCount(scheme)}</span>
												{/if}
											</div>
										{/each}
									</dd>
								</div>
							{/if}

							{#if varieties.length > 0}
								<div class="grid gap-2 px-4 py-3.5 sm:grid-cols-[9rem_1fr] sm:gap-5">
									<dt class="font-medium text-[color:var(--muted-foreground)]">{varieties.length === 1 ? 'Variedad' : 'Variedades'}</dt>
									<dd>{varieties.join(' · ')}</dd>
								</div>
							{/if}
						</dl>

						{#if metricParts.length > 0}
							<ol class="mt-4 grid gap-2 sm:grid-cols-2" aria-label="Partes de la construcción métrica">
								{#each metricParts as part (part.key)}
									<li class="rounded-r-md border-l-2 border-[color:var(--primary)] bg-[color:var(--muted)] px-3.5 py-3 text-sm">
										<div class="flex flex-wrap items-baseline justify-between gap-2">
											<strong class="font-semibold">{part.label}</strong>
											{#if part.vIni !== null && part.vFin !== null}
												<span class="text-xs text-[color:var(--muted-foreground)]">vv. {part.vIni}–{part.vFin}</span>
											{/if}
										</div>
										{#if part.schemes.length > 0}
											<p class="mt-1 font-mono text-xs tracking-wide">{part.schemes.join(' · ')}</p>
										{/if}
									</li>
								{/each}
							</ol>
						{/if}
					{:else}
						<p class="text-sm text-[color:var(--muted-foreground)]">
							No hay otros datos de construcción para esta secuencia.
						</p>
					{/if}
				</section>

				{#if hasObservedData}
					<section class="border-b border-[color:var(--border)] py-6">
						<h3 class="mb-4 text-base font-semibold">Lo observado</h3>
						{#if features.length > 0}
							<dl class="space-y-3 text-sm">
								{#each features as feature (feature.label)}
									<div class="grid gap-1 sm:grid-cols-[11rem_1fr] sm:gap-4">
										<dt class="text-[color:var(--muted-foreground)]">{feature.label}</dt>
										<dd>{feature.values.join(' · ')}</dd>
									</div>
								{/each}
							</dl>
						{/if}

						{#if deviations.length > 0}
							<ul class:mt-5={features.length > 0} class="space-y-3">
								{#each deviations as deviation, deviationIndex (`${deviation.v_ini}:${deviation.v_fin}:${deviation.dimension}:${deviationIndex}`)}
									<li class="border-l-2 border-[color:var(--orange)] pl-3 text-sm">
										<div class="flex flex-wrap items-start justify-between gap-2">
											<div>
												<p class="text-xs uppercase tracking-[0.05em] text-[color:var(--muted-foreground)]">
													Desviación · {humanize(deviation.dimension)}
												</p>
												<p class="font-semibold">{humanize(deviation.relacion_norma)}</p>
											</div>
											<span class="text-xs text-[color:var(--muted-foreground)]">vv. {deviation.v_ini}–{deviation.v_fin}</span>
										</div>
										{#if deviation.observaciones?.trim()}
											<p class="mt-1.5 text-[color:var(--muted-foreground)]">{deviation.observaciones}</p>
										{/if}
									</li>
								{/each}
							</ul>
						{/if}
					</section>
				{/if}

				<details class="group border-b border-[color:var(--border)]" open>
					<summary class="flex min-h-16 cursor-pointer list-none items-center justify-between gap-4 py-4 text-sm font-semibold [&::-webkit-details-marker]:hidden">
						<span>Contexto dramático</span>
						<ChevronDown class="h-4 w-4 text-[color:var(--muted-foreground)] transition-transform group-open:rotate-180" aria-hidden="true" />
					</summary>
					<div class="pb-6 text-sm">
						<div class="grid gap-7 sm:grid-cols-2 sm:gap-10">
							<section>
								<h4 class="mb-3 text-[0.68rem] font-semibold uppercase tracking-[0.07em] text-[color:var(--muted-foreground)]">Intervenciones</h4>
								<dl class="space-y-3">
									<div><dt class="text-xs text-[color:var(--muted-foreground)]">De personajes femeninos</dt><dd>{formatIntervencionValue(props.secuencia.intervencion_personajes_femeninos)}</dd></div>
									<div><dt class="text-xs text-[color:var(--muted-foreground)]">De figuras de donaire</dt><dd>{formatIntervencionValue(props.secuencia.intervencion_figuras_donaire)}</dd></div>
									<div><dt class="text-xs text-[color:var(--muted-foreground)]">De personajes sobrenaturales</dt><dd>{formatIntervencionValue(props.secuencia.intervencion_personajes_sobrenaturales)}</dd></div>
								</dl>
							</section>

							<section>
								<h4 class="mb-3 text-[0.68rem] font-semibold uppercase tracking-[0.07em] text-[color:var(--muted-foreground)]">Otras caracterizaciones</h4>
								<dl class="space-y-3">
									<div><dt class="text-xs text-[color:var(--muted-foreground)]">Versos partidos entre intervenciones</dt><dd>{formatNullableBoolean(props.secuencia.versos_partidos)}</dd></div>
									<div><dt class="text-xs text-[color:var(--muted-foreground)]">Cambio de espacio al inicio</dt><dd>{formatNullableBoolean(props.secuencia.inaugura_espacio)}</dd></div>
									<div><dt class="text-xs text-[color:var(--muted-foreground)]">Evento sobrenatural</dt><dd>{formatNullableBoolean(props.secuencia.evento_sobrenatural)}</dd></div>
								</dl>
							</section>
						</div>

						{#if props.structure?.tramos && props.structure.tramos.length > 1}
							<h4 class="mb-2 mt-6 text-[0.68rem] font-semibold uppercase tracking-[0.07em] text-[color:var(--muted-foreground)]">Tramos por cuadro</h4>
							<ol class="border-l border-[color:var(--border)] pl-4">
								{#each props.structure.tramos as tramo}
									<li class="py-1.5">{formatTramoLabel(tramo)}</li>
								{/each}
							</ol>
						{/if}

						{#if enunciationRanges.length > 0}
							<section class="mt-6">
								<h4 class="mb-3 text-[0.68rem] font-semibold uppercase tracking-[0.07em] text-[color:var(--muted-foreground)]">Enunciación</h4>
								<ol class="grid gap-2 sm:grid-cols-2">
									{#each enunciationRanges as caracterizacion (caracterizacion.caracterizacion_rango_id)}
										<li class="rounded-lg border border-[color:var(--border)] bg-white px-4 py-3.5">
											<div class="flex flex-wrap items-baseline justify-between gap-2">
								<strong class="font-semibold">{enunciationPassageLabel(caracterizacion.tipo_caracterizacion_rango_term)}</strong>
												<span class="rounded-full bg-[color:var(--muted)] px-2 py-0.5 text-xs text-[color:var(--muted-foreground)]">vv. {caracterizacion.v_ini}–{caracterizacion.v_fin}</span>
											</div>
											{#if caracterizacion.observaciones?.trim()}
												<p class="mt-2 leading-5 text-[color:var(--muted-foreground)]">{caracterizacion.observaciones}</p>
											{/if}
										</li>
									{/each}
								</ol>
							</section>
						{/if}

						{#if otherRanges.length > 0}
							<div class="mt-6">
								<h4 class="mb-2 text-sm font-semibold">Otras anotaciones por rango</h4>
								<ol class="border-l border-[color:var(--border)] pl-4">
									{#each otherRanges as caracterizacion (caracterizacion.caracterizacion_rango_id)}
										<li class="py-2">
											<div class="flex flex-wrap items-baseline justify-between gap-2">
												<span class="font-semibold">{caracterizacion.tipo_caracterizacion_rango_term}</span>
												<span class="text-xs text-[color:var(--muted-foreground)]">vv. {caracterizacion.v_ini}–{caracterizacion.v_fin}</span>
											</div>
											{#if caracterizacion.observaciones?.trim()}
												<p class="mt-1 text-[color:var(--muted-foreground)]">{caracterizacion.observaciones}</p>
											{/if}
										</li>
									{/each}
								</ol>
							</div>
						{/if}
					</div>
				</details>

				{#if hasEditorialContent}
					<details class="group" open>
						<summary class="flex min-h-16 cursor-pointer list-none items-center justify-between gap-4 py-4 text-sm font-semibold [&::-webkit-details-marker]:hidden">
							<span>{editorialHeading}</span>
							<ChevronDown class="h-4 w-4 text-[color:var(--muted-foreground)] transition-transform group-open:rotate-180" aria-hidden="true" />
						</summary>
						<div class="space-y-5 pb-6 text-sm leading-6">
							{#if synopsis}
								<section class="max-w-[46rem] text-[color:var(--gray-700)]">
									<div class="space-y-2">{@html renderMarkdown(synopsis)}</div>
								</section>
							{/if}

							{#if publicComments.length > 0}
								<section>
									<h4 class="mb-2 font-semibold">{synopsis ? 'Aclaraciones públicas' : 'Notas públicas'}</h4>
									<div class="space-y-3">
										{#each publicComments as comment (comment.comentario_id)}
											<div class="border-l-2 border-[color:var(--border)] pl-3">
												<div class="space-y-1">{@html renderMarkdown(comment.comentario)}</div>
												{#if comment.nombre_editor}
													<p class="mt-1 text-xs text-[color:var(--muted-foreground)]">Autoría de ficha: {comment.nombre_editor}</p>
												{/if}
											</div>
										{/each}
									</div>
								</section>
							{/if}
						</div>
					</details>
				{/if}
			</div>

			<footer class="grid grid-cols-2 border-t border-[color:var(--border)] bg-white">
				<button
					type="button"
					class="flex min-h-16 items-center gap-3 px-5 text-left text-sm transition-colors hover:bg-[color:var(--muted)] focus-visible:z-10 focus-visible:outline focus-visible:outline-2 focus-visible:outline-inset focus-visible:outline-[color:var(--primary)] disabled:cursor-default disabled:opacity-40 sm:px-8"
					disabled={!props.canPrev}
					onclick={props.onPrev}
				>
					<ArrowLeft class="h-4 w-4 shrink-0" aria-hidden="true" />
					<span class="min-w-0">
						<span class="block text-[0.65rem] uppercase tracking-[0.05em] text-[color:var(--muted-foreground)]">Anterior</span>
						<span class="block truncate font-semibold">{props.previousLabel ?? 'Primera secuencia'}</span>
					</span>
				</button>
				<button
					type="button"
					class="flex min-h-16 items-center justify-end gap-3 border-l border-[color:var(--border)] px-5 text-right text-sm transition-colors hover:bg-[color:var(--muted)] focus-visible:z-10 focus-visible:outline focus-visible:outline-2 focus-visible:outline-inset focus-visible:outline-[color:var(--primary)] disabled:cursor-default disabled:opacity-40 sm:px-8"
					disabled={!props.canNext}
					onclick={props.onNext}
				>
					<span class="min-w-0">
						<span class="block text-[0.65rem] uppercase tracking-[0.05em] text-[color:var(--muted-foreground)]">Siguiente</span>
						<span class="block truncate font-semibold">{props.nextLabel ?? 'Última secuencia'}</span>
					</span>
					<ArrowRight class="h-4 w-4 shrink-0" aria-hidden="true" />
				</button>
			</footer>
		</div>
	</div>
{/if}
