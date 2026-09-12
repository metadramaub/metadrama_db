<script lang="ts">
	import MetricSequenceFormGroups from './MetricSequenceFormGroups.svelte';
	import MetricAnalysisHeading from './MetricAnalysisHeading.svelte';
	import MetricFormLabel from './MetricFormLabel.svelte';
	import MetricSequencePair from './MetricSequencePair.svelte';
	import type { MetricSequenceFormGroup } from './metric-display.types';
	import type {
		CambioDeSecuenciaEnCuadro,
		SecuenciaPorCortesDeCuadro
	} from '$lib/metrica/analisis-ficha';

	interface CuadroCuts {
		total: number;
		partenSecuencia: number;
		cambiosSecuencia: number;
		sinCobertura: number;
		cambiosDeSecuencia: CambioDeSecuenciaEnCuadro[];
		secuenciasPorCortes: SecuenciaPorCortesDeCuadro[];
	}

	interface JornadaEnds {
		jornada: number;
		abre: string | null;
		abreColorKey: string | null;
		cierra: string | null;
		cierraColorKey: string | null;
	}

	const props = $props<{
		cuts: CuadroCuts;
		jornadas: JornadaEnds[];
		colorByForma: Record<string, string>;
		onOpen: (sequenceId: string) => void;
	}>();
	let detalle = $state<'cambios' | 'cortes' | null>(null);

	function alternarDetalle(nuevo: 'cambios' | 'cortes') {
		detalle = detalle === nuevo ? null : nuevo;
	}

	const textoCortes = (n: number) => `${n} ${n === 1 ? 'corte' : 'cortes'}`;
	const conCortes = $derived(
		props.cuts.secuenciasPorCortes.filter(
			(secuencia: SecuenciaPorCortesDeCuadro) => secuencia.cortes > 0
		)
	);
	const sinCortes = $derived(
		props.cuts.secuenciasPorCortes.filter(
			(secuencia: SecuenciaPorCortesDeCuadro) => secuencia.cortes === 0
		)
	);

	function agruparPorForma(
		secuencias: SecuenciaPorCortesDeCuadro[],
		mostrarTotalCortes: boolean
	): MetricSequenceFormGroup[] {
		const grupos = new Map<string, MetricSequenceFormGroup & { totalCortes: number }>();
		for (const secuencia of secuencias) {
			const existente = grupos.get(secuencia.colorKey);
			const item = {
				id: secuencia.secuencia_id,
				secuencia_id: secuencia.secuencia_id,
				v_ini: secuencia.v_ini,
				v_fin: secuencia.v_fin,
				detalle: mostrarTotalCortes ? textoCortes(secuencia.cortes) : null
			};
			if (existente) {
				existente.items.push(item);
				existente.totalCortes += secuencia.cortes;
			} else {
				grupos.set(secuencia.colorKey, {
					forma: secuencia.forma,
					colorKey: secuencia.colorKey,
					items: [item],
					totalCortes: secuencia.cortes
				});
			}
		}

		return [...grupos.values()]
			.sort(
				(a, b) =>
					b.totalCortes - a.totalCortes ||
					b.items.length - a.items.length ||
					a.forma.localeCompare(b.forma, 'es')
			)
			.map(({ totalCortes, ...grupo }) => ({
				...grupo,
				detalle: mostrarTotalCortes ? textoCortes(totalCortes) : null
			}));
	}

	const gruposConCortes = $derived(agruparPorForma(conCortes, true));
	const gruposSinCortes = $derived(agruparPorForma(sinCortes, false));
</script>

<section class="space-y-3" aria-labelledby="metric-articulation-title">
	<MetricAnalysisHeading
		id="metric-articulation-title"
		title="Jornadas y cuadros"
		description="Cómo se relacionan los límites dramáticos con el curso de las formas."
	/>
	<div class="space-y-3">
		<div class="rounded-lg border border-[color:var(--border)] bg-white px-4 py-4 sm:px-5">
			<h3 class="font-semibold">Cambios de cuadro</h3>
			<p class="mt-1 text-xs text-[color:var(--muted-foreground)]">
				Solo cambios internos de jornada; los cortes de jornada se cuentan aparte.
			</p>
			{#if props.cuts.total > 0}
				<div class="mt-4 flex gap-5 text-sm">
					<button
						type="button"
						class={`min-w-36 border-b-2 px-1 py-2 text-left transition-colors ${detalle === 'cambios' ? 'border-[color:var(--gray-800)]' : 'border-transparent hover:border-[color:var(--gray-300)]'}`}
						aria-expanded={detalle === 'cambios'}
						onclick={() => alternarDetalle('cambios')}
					>
						<span class="block text-xs text-[color:var(--muted-foreground)]">Cambios de secuencia</span>
						<span class="mt-1 block text-xl font-semibold tabular-nums">{props.cuts.cambiosSecuencia}</span>
					</button>
					<button
						type="button"
						class={`min-w-36 border-b-2 px-1 py-2 text-left transition-colors ${detalle === 'cortes' ? 'border-[color:var(--gray-800)]' : 'border-transparent hover:border-[color:var(--gray-300)]'}`}
						aria-expanded={detalle === 'cortes'}
						onclick={() => alternarDetalle('cortes')}
					>
						<span class="block text-xs text-[color:var(--muted-foreground)]">Parten una secuencia</span>
						<span class="mt-1 block text-xl font-semibold tabular-nums">{props.cuts.partenSecuencia}</span>
					</button>
				</div>
				<p class="mt-3 text-xs text-[color:var(--muted-foreground)]">
					{props.cuts.total} {props.cuts.total === 1 ? 'cambio de cuadro analizado' : 'cambios de cuadro analizados'}
					{#if props.cuts.sinCobertura > 0} · {props.cuts.sinCobertura} sin cobertura métrica{/if}
				</p>

				{#if detalle === 'cambios'}
					<div class="mt-4 border-t border-[color:var(--border)] pt-4">
						<h4 class="text-sm font-semibold">Dónde cambia la secuencia</h4>
						{#if props.cuts.cambiosDeSecuencia.length > 0}
							<ol class="mt-2 divide-y divide-[color:var(--border)]">
								{#each props.cuts.cambiosDeSecuencia as cambio (`${cambio.anterior.secuencia_id}:${cambio.siguiente.secuencia_id}`)}
									<li class="py-3 text-xs first:pt-1 last:pb-0">
										<div class="flex flex-wrap items-center justify-between gap-2">
											<span class="font-medium tabular-nums">Cambio de cuadro en v. {cambio.limite}</span>
											{#if !cambio.cambiaForma}
												<span class="rounded-full bg-[color:var(--muted)] px-2 py-0.5 text-[color:var(--muted-foreground)]">
													Continúa la misma forma
												</span>
											{/if}
										</div>
										<MetricSequencePair anterior={cambio.anterior} siguiente={cambio.siguiente} onOpen={props.onOpen} colorByForma={props.colorByForma} className="mt-2" />
									</li>
								{/each}
							</ol>
						{:else}
							<p class="mt-2 text-xs text-[color:var(--muted-foreground)]">Ningún cambio de cuadro coincide con un cambio de secuencia.</p>
						{/if}
					</div>
				{:else if detalle === 'cortes'}
					<div class="mt-4 border-t border-[color:var(--border)] pt-4">
						<h4 class="text-sm font-semibold">Secuencias ordenadas por cortes</h4>
						<p class="mt-1 text-xs text-[color:var(--muted-foreground)]">De las más partidas a las menos partidas.</p>
						{#if conCortes.length > 0}
							<div class="mt-2">
								<MetricSequenceFormGroups groups={gruposConCortes} colorByForma={props.colorByForma} onOpen={props.onOpen} />
							</div>
						{:else}
							<p class="mt-2 text-xs text-[color:var(--muted-foreground)]">Ninguna secuencia contiene un cambio de cuadro.</p>
						{/if}
						{#if sinCortes.length > 0}
							<details class="group mt-3 border-t border-[color:var(--border)] pt-2">
								<summary class="cursor-pointer py-1.5 text-xs font-medium text-[color:var(--muted-foreground)]">
									Ver {sinCortes.length} {sinCortes.length === 1 ? 'secuencia sin cortes' : 'secuencias sin cortes'}
								</summary>
								<div class="pt-2">
									<MetricSequenceFormGroups groups={gruposSinCortes} colorByForma={props.colorByForma} onOpen={props.onOpen} />
								</div>
							</details>
						{/if}
					</div>
				{/if}
			{:else}
				<p class="mt-4 text-sm text-[color:var(--muted-foreground)]">No hay cambios internos de cuadro anotados.</p>
			{/if}
		</div>

		<div class="rounded-lg border border-[color:var(--border)] bg-white px-4 py-4 sm:px-5">
			<h3 class="font-semibold">Apertura y cierre de las jornadas</h3>
			{#if props.jornadas.length > 0}
				<table class="mt-3 w-full text-sm">
					<thead>
						<tr class="border-b border-[color:var(--border)] text-left text-xs text-[color:var(--muted-foreground)]">
							<th scope="col" class="py-2 pr-3 font-semibold">Jornada</th>
							<th scope="col" class="px-3 py-2 font-semibold">Abre con</th>
							<th scope="col" class="py-2 pl-3 font-semibold">Cierra con</th>
						</tr>
					</thead>
					<tbody>
						{#each props.jornadas as jornada (jornada.jornada)}
							<tr class="border-b border-[color:var(--border)] last:border-b-0">
								<th scope="row" class="py-2.5 pr-3 text-left font-medium">{jornada.jornada}</th>
								<td class="px-3 py-2.5">
									{#if jornada.abre && jornada.abreColorKey}
										<MetricFormLabel forma={jornada.abre} colorKey={jornada.abreColorKey} colorByForma={props.colorByForma} />
									{:else}—{/if}
								</td>
								<td class="py-2.5 pl-3">
									{#if jornada.cierra && jornada.cierraColorKey}
										<MetricFormLabel forma={jornada.cierra} colorKey={jornada.cierraColorKey} colorByForma={props.colorByForma} />
									{:else}—{/if}
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			{:else}
				<p class="mt-4 text-sm text-[color:var(--muted-foreground)]">No hay jornadas anotadas.</p>
			{/if}
		</div>
	</div>
</section>
