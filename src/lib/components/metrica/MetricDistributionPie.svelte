<script lang="ts">
	// Pie de distribución de formas REUTILIZABLE. Consume MetricDistributionSlice.
	// Leyenda desplegable: forma → arquitectura → respuestas observadas.
	import { ChevronDown, ChevronRight } from 'lucide-svelte';
	import MetricDonut from './MetricDonut.svelte';
	import type { MetricDistributionSlice } from './metric-display.types';
	import {
		buildDistributionGroups,
		formatMetricCount,
		pluralizeMetricUnit,
		type MetricDistributionArchitecture,
		type MetricDistributionDimension,
		type MetricDistributionGroup,
		type MetricDistributionSequence,
		type MetricDistributionValue
	} from './metric-distribution';
	import { normalizeFormaKey } from '$lib/utils/metric-colors';

	const props = $props<{
		items: MetricDistributionSlice[];
		colorByForma: Record<string, string>;
		valueMode: 'percent' | 'absolute';
		title?: string;
		/** Forma (slug/colorKey) a resaltar desde fuera (p.ej. hover en el barcode). */
		highlightedForma?: string | null;
		/** Notifica la forma sobrevolada en la leyenda (null al salir). */
		onHoverForma?: (forma: string | null) => void;
		/** Secuencias para construir el desglose del dominio (opcional). */
		sequences?: MetricDistributionSequence[];
		/** Cuántas arquitecturas tiene cada forma en el catálogo, por slug (la clave de color). */
		arquitecturasPorForma?: Record<string, number>;
	}>();

	let expanded = $state<Record<string, boolean>>({});

	const groups = $derived.by((): MetricDistributionGroup[] => {
		const slices = props.items.filter((i: MetricDistributionSlice) => i.versos > 0);
		const built = buildDistributionGroups(slices, props.sequences ?? []);
		return built.sort(
			(a, b) => b.versos - a.versos || a.forma.localeCompare(b.forma, 'es')
		);
	});

	function groupKey(item: MetricDistributionSlice) {
		return normalizeFormaKey(item.colorKey ?? item.forma);
	}

	// **Rosquilla, lista y código de barras van juntos.** Pasar por una forma en la rosquilla o en
	// la lista la ilumina en los tres sitios y apaga el resto. El resalte llega de fuera
	// (`highlightedForma`); el propio sirve cuando quien usa el componente no lo devuelve.
	let sobrevolada = $state<string | null>(null);
	const highlightedFormaKey = $derived(
		props.highlightedForma ? normalizeFormaKey(props.highlightedForma) : sobrevolada
	);
	const DIMMED_OPACITY = 0.35;
	const isDimmed = (item: MetricDistributionSlice) =>
		highlightedFormaKey !== null && groupKey(item) !== highlightedFormaKey;

	function hoverForma(item: MetricDistributionSlice | null) {
		sobrevolada = item ? groupKey(item) : null;
		props.onHoverForma?.(item ? (item.colorKey ?? item.forma) : null);
	}

	// El aviso de un sector: forma, versos y porcentaje, lo mismo que daba el de ECharts. En HTML y
	// no con `<title>`, que tarda un segundo en salir y no deja poner la forma en negrita.
	let rosquilla = $state<HTMLDivElement | null>(null);
	let aviso = $state<{ item: MetricDistributionGroup; x: number; y: number } | null>(null);

	/** El sector se reconoce por su clave normalizada; hacia fuera se avisa con la del color. */
	function hoverSector(clave: string | null, evento?: PointerEvent) {
		const item = clave ? (groups.find((group) => groupKey(group) === clave) ?? null) : null;
		if (item?.forma !== aviso?.item.forma) hoverForma(item);
		const caja = rosquilla?.getBoundingClientRect();
		aviso =
			item && evento && caja
				? { item, x: evento.clientX - caja.left, y: evento.clientY - caja.top }
				: null;
	}

	function valueLabel(versos: number, porcentaje: number): string {
		return props.valueMode === 'absolute' ? `${versos} vv.` : `${porcentaje.toFixed(2)}%`;
	}

	const porcentajeDe = (parte: number, total: number) =>
		`${(total > 0 ? (parte / total) * 100 : 0).toFixed(2)}%`;

	/**
	 * Un valor de rasgo, en la escala en que se puede contar.
	 *
	 * **Los que caracterizan versos** —la asonancia— siguen el modo del perfil: porcentaje de los
	 * versos de la arquitectura, o versos. **Los que se dicen de la secuencia entera** solo se cuentan
	 * en secuencias, en los dos modos, como los esquemas: «la mayoría de sus versos riman» no dice
	 * cuáles, y dar la suma de versos afirmaría de cada uno lo que solo se dijo del conjunto.
	 */
	function featureLabel(
		item: MetricDistributionValue,
		rasgo: MetricDistributionDimension,
		arquitectura: MetricDistributionArchitecture
	): string {
		const secuencias = formatMetricCount(item);
		if (rasgo.escala === 'verso') {
			const medida =
				props.valueMode === 'absolute'
					? `${item.versos} vv.`
					: porcentajeDe(item.versos, arquitectura.versos);
			return `${medida} en ${secuencias}`;
		}
		if (item.cantidad === arquitectura.secuencias) return secuencias;
		return `${item.cantidad} de ${arquitectura.secuencias} ${pluralizeMetricUnit('secuencia', arquitectura.secuencias)} · ${porcentajeDe(item.cantidad, arquitectura.secuencias)}`;
	}

	/** Los metros cubren versos: siguen el modo del perfil, como la asonancia. */
	const metroLabel = (metro: MetricDistributionValue, arquitectura: MetricDistributionArchitecture) =>
		props.valueMode === 'absolute'
			? `${metro.versos} vv.`
			: porcentajeDe(metro.versos, arquitectura.versos);

	function schemeLabel(item: MetricDistributionValue, items: MetricDistributionValue[]): string {
		const total = items
			.filter((candidate) => candidate.unidad === item.unidad)
			.reduce((sum, candidate) => sum + candidate.cantidad, 0);
		if (item.cantidad === total) return formatMetricCount(item);
		const pluralUnit = pluralizeMetricUnit(item.unidad, total);
		const share = total > 0 ? ((item.cantidad / total) * 100).toFixed(2) : '0.00';
		return `${item.cantidad} de ${total} ${pluralUnit} · ${share}%`;
	}

	/**
	 * **La arquitectura se nombra solo cuando distingue algo.** Si la forma no tiene más que una en
	 * el catálogo —la lira, el soneto, el romance—, «Heptasílaba y endecasílaba» dentro de la lira
	 * repite lo que ya dice «lira», y lo que haya debajo cuelga directamente de la forma. Tampoco se
	 * nombra la de una secuencia sin forma, que se llama igual que ella. Si la forma tiene varias y
	 * la obra usa una, se nombra —dice cuál de ellas es—, pero sin el 100 % que no informa.
	 */
	function nombraArquitecturas(item: MetricDistributionGroup): boolean {
		if (item.arquitecturas.length !== 1) return true;
		const [unica] = item.arquitecturas;
		if (unica.label === item.forma) return false;
		return props.arquitecturasPorForma?.[item.colorKey ?? item.forma] !== 1;
	}

	const tieneRespuestas = (arquitectura: MetricDistributionArchitecture) =>
		arquitectura.esquemas.length > 0 ||
		arquitectura.rasgos.length > 0 ||
		arquitectura.metros.length > 0 ||
		arquitectura.variedades.length > 0;

	function toggle(forma: string) {
		expanded = { ...expanded, [forma]: !expanded[forma] };
	}

	const sectores = $derived(
		groups.map((item) => ({
			clave: groupKey(item),
			valor: item.versos,
			color: props.colorByForma[item.colorKey ?? item.forma] ?? '#9ca3af'
		}))
	);
</script>

<section class="space-y-3">
	<div class="flex items-center justify-between gap-2">
		<h3 class="text-base font-semibold">{props.title ?? 'Perfil métrico'}</h3>
		<p class="text-xs text-[color:var(--muted-foreground)]">
			{props.valueMode === 'percent' ? 'Valores en porcentaje' : 'Valores absolutos'}
		</p>
	</div>

	{#if groups.length === 0}
		<p class="text-sm text-[color:var(--muted-foreground)]">Sin distribución métrica disponible.</p>
	{:else}
		<div class="grid gap-6 md:grid-cols-[14rem_1fr] md:items-start">
			<div class="relative mx-auto h-56 w-56" bind:this={rosquilla}>
				<MetricDonut
					sectores={sectores}
					class="block h-56 w-56"
					resaltada={highlightedFormaKey}
					onHover={hoverSector}
				/>
				{#if aviso}
					<div
						class="pointer-events-none absolute z-10 w-max max-w-[14rem] border border-[color:var(--border)] bg-white px-2 py-1.5 text-[11px] leading-4 text-[color:var(--gray-800)] shadow-sm"
						style={`left:${aviso.x + 12}px;top:${aviso.y + 12}px;`}
						role="tooltip"
					>
						<strong class="block text-[color:var(--gray-900)]">{aviso.item.forma}</strong>
						Versos: {aviso.item.versos}<br />
						Porcentaje: {aviso.item.porcentaje.toFixed(2)}%
					</div>
				{/if}
			</div>

			<ul class="divide-y divide-[color:var(--border)]">
				{#each groups as item (item.forma)}
					{@const nombrar = nombraArquitecturas(item)}
					{@const hasDetails = nombrar ? item.arquitecturas.length > 0 : item.arquitecturas.some(tieneRespuestas)}
					<li
						class="transition-opacity duration-100"
						style:opacity={isDimmed(item) ? DIMMED_OPACITY : 1}
						onpointerenter={() => hoverForma(item)}
						onpointerleave={() => hoverForma(null)}
					>
						<button
							type="button"
							class="flex w-full items-center justify-between gap-3 py-2 text-left text-sm"
							class:cursor-default={!hasDetails}
							onclick={() => hasDetails && toggle(item.forma)}
							onfocus={() => hoverForma(item)}
							onblur={() => hoverForma(null)}
							aria-expanded={hasDetails ? Boolean(expanded[item.forma]) : undefined}
						>
							<span class="flex items-center gap-2">
								<span
									class="inline-block h-3 w-3 rounded-sm"
									style={`background:${props.colorByForma[item.colorKey ?? item.forma] ?? '#9ca3af'};`}
								></span>
								<span class="font-medium">{item.forma}</span>
								{#if hasDetails}
									{#if expanded[item.forma]}
										<ChevronDown class="h-3.5 w-3.5 text-[color:var(--muted-foreground)]" aria-hidden="true" />
									{:else}
										<ChevronRight class="h-3.5 w-3.5 text-[color:var(--muted-foreground)]" aria-hidden="true" />
									{/if}
								{/if}
							</span>
							<span class="text-[color:var(--muted-foreground)]">
								{valueLabel(item.versos, item.porcentaje)}
							</span>
						</button>

						{#if hasDetails && expanded[item.forma]}
							<div class="mb-3 ml-5 space-y-4 border-l border-[color:var(--border)] pl-3">
								{#each item.arquitecturas as arquitectura (arquitectura.slug ?? arquitectura.label)}
									<section class="space-y-2 py-1">
										{#if nombrar}
											<div class="flex items-baseline justify-between gap-3 text-xs">
												<h4 class="font-semibold text-[color:var(--foreground)]">{arquitectura.label}</h4>
												{#if item.arquitecturas.length > 1}
													<span class="text-[color:var(--muted-foreground)]">{valueLabel(arquitectura.versos, arquitectura.porcentaje)}</span>
												{/if}
											</div>
										{/if}

										{#if arquitectura.esquemas.length > 0}
											<div>
												<p class="text-[0.68rem] font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">Esquemas de rima</p>
												<ul>
											{#each arquitectura.esquemas as esquema (`${esquema.unidad}:${esquema.label}`)}
														<li class="flex items-center justify-between gap-3 py-0.5 text-xs text-[color:var(--muted-foreground)]">
															<span class="font-mono text-[color:var(--foreground)]">{esquema.label}</span>
															<span>{schemeLabel(esquema, arquitectura.esquemas)}</span>
														</li>
													{/each}
												</ul>
											</div>
										{/if}

										{#each arquitectura.rasgos as rasgo (rasgo.label)}
											<div>
												<p class="text-[0.68rem] font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">{rasgo.label}</p>
												<ul>
													{#each rasgo.values as value (value.label)}
														<li class="flex items-center justify-between gap-3 py-0.5 text-xs text-[color:var(--muted-foreground)]">
															<span class="text-[color:var(--foreground)]">{value.label}</span>
															<span>{featureLabel(value, rasgo, arquitectura)}</span>
														</li>
													{/each}
												</ul>
											</div>
										{/each}

										{#if arquitectura.metros.length > 0}
											<p class="text-xs text-[color:var(--muted-foreground)]">
												<span class="font-semibold uppercase tracking-[0.06em]">Metros:</span>
												{arquitectura.metros.map((metro) => `${metro.label} (${metroLabel(metro, arquitectura)})`).join(' · ')}
											</p>
										{/if}

										{#if arquitectura.variedades.length > 0}
											<p class="text-xs text-[color:var(--muted-foreground)]">
												<span class="font-semibold uppercase tracking-[0.06em]">Variedades:</span>
												{arquitectura.variedades.map((variedad) => `${variedad.label} (${formatMetricCount(variedad)})`).join(' · ')}
											</p>
										{/if}
									</section>
								{/each}
							</div>
						{/if}
					</li>
				{/each}
			</ul>
		</div>
	{/if}
</section>
