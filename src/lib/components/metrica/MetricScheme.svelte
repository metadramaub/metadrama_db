<script lang="ts">
	// Esquema métrico de un vistazo, REUTILIZABLE (ficha, y mañana el perfil de autor).
	// Consume MetricSchemeEntry genérico, no PublicFichaSecuencia.
	//
	// Es la lista que las ediciones críticas ponen al principio —«vv. 1-184, redondillas»— y que
	// aquí sale del dato anotado en vez de escribirse a mano. Se lee de arriba abajo y se copia:
	// por eso es una tabla y no un gráfico, y por eso los rangos van alineados a la derecha, que es
	// como se comparan dos números.
	import type { MetricSchemeEntry } from './metric-display.types';
	import { normalizeFormaKey } from '$lib/utils/metric-colors';
	import { bandaDeCuadros, type CuadroRango } from '$lib/metrica/banda-de-cuadros';

	const props = $props<{
		entries: MetricSchemeEntry[];
		colorByForma: Record<string, string>;
		/** Los cuadros con su rango, para dibujar la banda de la izquierda. */
		cuadros?: CuadroRango[];
		/** Agrupar por jornada, que es como se lee una comedia. */
		agrupar?: boolean;
		onOpen?: (id: string) => void;
	}>();

	const agrupar = $derived(props.agrupar !== false);

	const colorDe = (entrada: MetricSchemeEntry) =>
		props.colorByForma[normalizeFormaKey(entrada.colorKey ?? entrada.forma)] ??
		'var(--muted-foreground)';

	const ordenadas = $derived([...props.entries].sort((a, b) => a.v_ini - b.v_ini));

	/** Las entradas repartidas en jornadas, o todas juntas si no se agrupa o no hay jornadas. */
	const grupos = $derived.by(() => {
		if (!agrupar || ordenadas.every((e) => e.jornada == null)) {
			return [{ jornada: null as number | null, entradas: ordenadas }];
		}
		const porJornada = new Map<number | null, MetricSchemeEntry[]>();
		for (const entrada of ordenadas) {
			const clave = entrada.jornada ?? null;
			porJornada.set(clave, [...(porJornada.get(clave) ?? []), entrada]);
		}
		return [...porJornada.entries()]
			.sort((a, b) => (a[0] ?? Infinity) - (b[0] ?? Infinity))
			.map(([jornada, entradas]) => ({ jornada, entradas }));
	});

	const cuadros = $derived((props.cuadros ?? []) as CuadroRango[]);
	const hayBanda = $derived(cuadros.length > 0);

	/** La banda de una fila: en qué cuadro está, y dónde la parte un corte si la parte. */
	const bandaDe = (entrada: MetricSchemeEntry) =>
		bandaDeCuadros(entrada.v_ini, entrada.v_fin, cuadros);

	const rango = (entrada: MetricSchemeEntry) => `${entrada.v_ini}-${entrada.v_fin}`;
</script>

<div class="metric-scheme">
	{#each grupos as grupo (grupo.jornada ?? 'sin-jornada')}
		{#if grupo.jornada !== null}
			<h3 class="metric-scheme__jornada">
				Jornada {grupo.jornada}
				<span class="metric-scheme__jornada-rango">
					vv. {grupo.entradas[0]?.v_ini}-{grupo.entradas[grupo.entradas.length - 1]?.v_fin}
				</span>
			</h3>
		{/if}

		<!-- **Cada cosa en su columna.** El color iba pegado delante de los números y los empujaba,
		     así que ninguna columna alineaba con la de arriba: con rangos de tres y de cuatro cifras
		     el desajuste se ve a simple vista. -->
		<table class="metric-scheme__tabla">
			<thead class="sr-only">
				<tr>
					<th scope="col">Cuadro</th>
					<th scope="col">Forma</th>
					<th scope="col">Versos</th>
					<th scope="col">Extensión</th>
					<th scope="col">Nombre</th>
					<th scope="col">Detalle</th>
				</tr>
			</thead>
			<tbody>
				{#each grupo.entradas as entrada (entrada.id)}
					{@const banda = bandaDe(entrada)}
					<tr class="metric-scheme__fila">
						{#if hayBanda}
							<!-- **La banda dice dónde cae el corte, no solo que cayó.** Cuando un cuadro abre en
							     mitad de una tirada, el tramo se parte en la proporción de esa fila: es un
							     porcentaje de su propia altura, así que da igual lo que la fila mida. Entre filas
							     no hay escala de versos, ni debe haberla. -->
							<td class="metric-scheme__banda-celda">
								<span class="metric-scheme__banda">
									{#each banda as tramo, i (i)}
										<span
											class="metric-scheme__banda-tramo"
											class:abre={tramo.abre}
											style={`top:${tramo.desde * 100}%;height:${tramo.alto * 100}%`}
											title={tramo.numero === null
												? 'Fuera de cuadro'
												: tramo.abre
													? `Cuadro ${tramo.numero}, desde el v. ${tramo.verso}`
													: `Cuadro ${tramo.numero}`}
										>
											{#if tramo.abre && tramo.numero !== null}
												<span class="metric-scheme__banda-num">{tramo.numero}</span>
											{/if}
										</span>
									{/each}
								</span>
							</td>
						{/if}
						<td class="metric-scheme__color-celda">
							<span class="metric-scheme__color" style={`background:${colorDe(entrada)}`}></span>
						</td>
						<td class="metric-scheme__versos">vv. {rango(entrada)}</td>
						<td class="metric-scheme__cuantos">({entrada.n_versos})</td>
						<td class="metric-scheme__forma">
							{#if props.onOpen}
								<button type="button" onclick={() => props.onOpen?.(entrada.id)}>
									{entrada.forma}
								</button>
							{:else}
								{entrada.forma}
							{/if}
						</td>
						<td class="metric-scheme__detalle">
							{#if entrada.arquitectura}<span>{entrada.arquitectura}</span>{/if}
							{#if entrada.detalle}<span class="metric-scheme__observado">{entrada.detalle}</span
								>{/if}
						</td>
					</tr>
				{/each}
			</tbody>
		</table>
	{/each}
</div>

<style>
	.metric-scheme {
		display: flex;
		flex-direction: column;
		gap: 1.25rem;
	}

	.metric-scheme__jornada {
		display: flex;
		align-items: baseline;
		gap: 0.5rem;
		font-size: 0.8125rem;
		font-weight: 600;
		letter-spacing: 0.06em;
		text-transform: uppercase;
	}

	.metric-scheme__jornada-rango {
		font-weight: 400;
		letter-spacing: 0;
		text-transform: none;
		color: var(--muted-foreground);
	}

	.metric-scheme__tabla {
		width: 100%;
		border-collapse: collapse;
		font-size: 0.875rem;
	}

	.metric-scheme__fila > td {
		padding: 0.3rem 0.5rem 0.3rem 0;
		vertical-align: baseline;
		border-bottom: 1px solid var(--border);
	}

	.metric-scheme__color-celda {
		width: 1rem;
		padding-right: 0.6rem;
	}

	.metric-scheme__color {
		display: block;
		width: 0.75rem;
		height: 1rem;
	}

	/* Los rangos, en cifras tabulares y a la derecha: es como se comparan dos números. */
	.metric-scheme__versos {
		width: 1%;
		white-space: nowrap;
		text-align: right;
		font-variant-numeric: tabular-nums;
		color: var(--muted-foreground);
	}

	.metric-scheme__cuantos {
		width: 1%;
		white-space: nowrap;
		text-align: right;
		font-size: 0.75rem;
		font-variant-numeric: tabular-nums;
		color: var(--muted-foreground);
	}

	.metric-scheme__forma {
		white-space: nowrap;
		font-weight: 600;
	}

	.metric-scheme__forma button {
		font: inherit;
		color: inherit;
		text-align: left;
		text-decoration: underline;
		text-decoration-color: var(--border);
		text-underline-offset: 0.2em;
		cursor: pointer;
	}

	.metric-scheme__forma button:hover {
		text-decoration-color: currentColor;
	}

	.metric-scheme__detalle {
		width: 100%;
		color: var(--muted-foreground);
	}

	.metric-scheme__detalle span + span::before {
		content: ' · ';
	}

	.metric-scheme__observado {
		font-variant-numeric: tabular-nums;
	}

	/* La banda no lleva borde inferior: es lo que la hace continua de fila a fila. */
	.metric-scheme__banda-celda {
		width: 1.5rem;
		padding: 0 0.5rem 0 0;
		border-bottom: 0 !important;
	}

	.metric-scheme__banda {
		position: relative;
		display: block;
		width: 100%;
		height: 100%;
		min-height: 1.6rem;
	}

	.metric-scheme__banda-tramo {
		position: absolute;
		left: 0;
		width: 100%;
		border-left: 3px solid var(--border);
	}

	/* Donde abre un cuadro, la línea se refuerza y se pone su número: el corte se ve caer
	   exactamente donde cae, aunque sea en mitad de la fila. */
	.metric-scheme__banda-tramo.abre {
		border-left-color: var(--gray-800, currentColor);
		border-top: 1px solid var(--gray-800, currentColor);
	}

	.metric-scheme__banda-num {
		position: absolute;
		top: 0;
		left: 5px;
		font-size: 0.625rem;
		font-weight: 600;
		line-height: 1;
		color: var(--muted-foreground);
	}
</style>
