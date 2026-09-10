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
							<!-- **El cuadro se dice con palabras y se sitúa con una raya.** Un número de diez
							     píxeles pegado a la banda de color no se lee: se lee «Cuadro 3». La raya de la
							     derecha marca dónde cae el corte cuando cae en mitad de la secuencia, que es lo
							     único que el texto no puede decir por sí solo. -->
							<td class="metric-scheme__cuadro-celda">
								{#each banda.filter((t) => t.abre && t.numero !== null) as tramo (tramo.numero)}
									<!-- **La etiqueta va a la altura del corte.** Puesta arriba de la fila caía
									     dentro del cuadro anterior, que es lo contrario de lo que dice. -->
									<span class="metric-scheme__cuadro-texto" style={`top:${tramo.desde * 100}%`}>
										<span class="metric-scheme__cuadro-nombre">Cuadro {tramo.numero}</span>
										{#if tramo.verso !== null && tramo.verso !== entrada.v_ini}
											<span class="metric-scheme__cuadro-verso">desde el v. {tramo.verso}</span>
										{/if}
									</span>
								{/each}
								<span class="metric-scheme__regla">
									{#each banda as tramo, i (i)}
										<span
											class="metric-scheme__regla-tramo"
											class:abre={tramo.abre}
											class:suelto={tramo.numero === null}
											style={`top:${tramo.desde * 100}%;height:${tramo.alto * 100}%`}
										></span>
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

	/* La columna del cuadro no lleva borde inferior: es lo que hace continua la raya. */
	.metric-scheme__cuadro-celda {
		position: relative;
		/* `width: 1%` con `nowrap` es lo que hace que una columna ocupe **lo que mide su texto**:
		   con un ancho fijo, la columna del detalle —que va al 100 %— la estrujaba y «Cuadro»
		   partía en dos líneas. */
		width: 1%;
		/* La etiqueta va posicionada en absoluto, así que **ya no da ancho a la columna**: hay que
		   reservarlo aquí o el texto se sale por la izquierda. */
		min-width: 8.5rem;
		white-space: nowrap;
		padding: 0.3rem 1.6rem 0.3rem 0;
		vertical-align: top;
		border-bottom: 0 !important;
	}

	.metric-scheme__cuadro-texto {
		position: absolute;
		right: 1.6rem;
		display: flex;
		flex-direction: column;
		gap: 0.05rem;
		text-align: right;
		white-space: nowrap;
	}

	.metric-scheme__cuadro-nombre {
		font-size: 0.6875rem;
		font-weight: 600;
		letter-spacing: 0.06em;
		text-transform: uppercase;
	}

	.metric-scheme__cuadro-verso {
		font-size: 0.6875rem;
		color: var(--muted-foreground);
		font-variant-numeric: tabular-nums;
	}

	/* La raya vive en el borde derecho de la columna y va de fila en fila sin cortarse. */
	/* La raya va **separada de la banda de color**: pegadas parecían dos bandas de lo mismo. */
	.metric-scheme__regla {
		position: absolute;
		top: 0;
		right: 0.8rem;
		bottom: 0;
		width: 1px;
	}

	/* **La línea es la misma en todo el recorrido del cuadro.** Antes solo se oscurecía el trozo
	   donde abría, así que se leía como una raya suelta en vez de como algo que cubre todas esas
	   secuencias. Lo que marca el corte es el travesaño, no el tono. */
	.metric-scheme__regla-tramo {
		position: absolute;
		left: 0;
		width: 100%;
		background: var(--gray-800, currentColor);
	}

	/* Un pasaje fuera de todo cuadro no lleva línea. */
	.metric-scheme__regla-tramo.suelto {
		background: transparent;
	}

	.metric-scheme__regla-tramo.abre::before {
		content: '';
		position: absolute;
		top: 0;
		left: -3px;
		width: 7px;
		height: 1px;
		background: var(--gray-800, currentColor);
	}
</style>
