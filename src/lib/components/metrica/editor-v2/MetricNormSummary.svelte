<script lang="ts">
	import type { MetricNormFact } from './norm-summary';

	/**
	 * La norma, leída como la lee quien está anotando.
	 *
	 * Tres cosas y en este orden: **qué está fijado** —y por tanto no hay que pensar—, **qué declara
	 * el pasaje** que tiene delante, y **qué admite la forma** sin exigirlo. Y una cuarta al pie, que
	 * es la que cierra la frase: qué hacer con lo que no cabe en ninguna de las tres.
	 *
	 * *Lo que se ha ido de aquí:* la rejilla verso a verso, que es buena en la ficha pública y en el
	 * demarcador —donde se compara una forma con otra— y aquí competía con el formulario; y la
	 * enumeración de lo que el desplegable ya ofrece, que era la mitad del recuadro. Si la rima se
	 * elige, lo que hace falta saber es **que se elige y con qué criterio**, no cuáles son las ocho
	 * disposiciones: esas están tres centímetros más abajo.
	 */
	const props = $props<{
		facts: MetricNormFact[];
		catalogHref: string;
	}>();

	const fijadas = $derived(props.facts.filter((fact: MetricNormFact) => !fact.estado));
	const delPasaje = $derived(
		props.facts.filter((fact: MetricNormFact) => fact.estado === 'pasaje')
	);
	const admitidas = $derived(
		props.facts.filter((fact: MetricNormFact) => fact.estado === 'admite')
	);

	let abierta = $state(false);
	/** Qué hay dentro, para que plegada no sea una caja muda. */
	const resumen = $derived.by(() => {
		const trozos: string[] = [];
		if (fijadas.length > 0) trozos.push(`${fijadas.length} fijados`);
		if (delPasaje.length > 0) trozos.push(`${delPasaje.length} del pasaje`);
		if (admitidas.length > 0) trozos.push(`${admitidas.length} admitidos`);
		return trozos.join(' · ');
	});
</script>

<div class="border border-[color:var(--border)] bg-[color:var(--gray-50)] text-sm">
	<!--
		**Plegada de partida, y con una línea que dice lo que hay dentro.**

		La norma se consulta al empezar con una forma que no se domina, no en cada secuencia: quien
		anota cincuenta quintillas seguidas la lee una vez. Abierta siempre, ocupaba media pantalla
		por encima de lo único que hay que hacer, que son las respuestas.

		Lo que se queda fuera es lo que se necesita sin abrirla: **el enlace a la ficha**, que va a
		otro sitio y no a este recuadro, y cuántos datos hay de cada clase, para que plegada no sea
		una caja muda.
	-->
	<div class="flex flex-wrap items-center justify-between gap-x-4 gap-y-1 px-3 py-2">
		<button
			type="button"
			class="flex min-w-0 items-center gap-1.5 text-left hover:text-[color:var(--foreground)]"
			aria-expanded={abierta}
			onclick={() => (abierta = !abierta)}
		>
			<svg
				class={`h-3 w-3 shrink-0 text-[color:var(--muted-foreground)] transition-transform ${
					abierta ? 'rotate-90' : ''
				}`}
				viewBox="0 0 12 12"
				fill="none"
				aria-hidden="true"
			>
				<path d="M4 2.5 8 6l-4 3.5" stroke="currentColor" stroke-width="1.5" />
			</svg>
			<span class="text-xs uppercase tracking-wide text-[color:var(--muted-foreground)]">
				La norma
			</span>
			{#if !abierta && resumen}
				<span class="truncate text-xs text-[color:var(--muted-foreground)]">· {resumen}</span>
			{/if}
		</button>
		<a class="link-action shrink-0 text-xs" href={props.catalogHref} target="_blank" rel="noreferrer">
			Ver ficha completa ↗
		</a>
	</div>

	{#if abierta}
		<div class="space-y-3 border-t border-[color:var(--border)] px-3 py-2.5">
			{#if fijadas.length > 0}
				<div>
					<span class="text-xs uppercase tracking-wide text-[color:var(--muted-foreground)]">
						Ya está fijado
					</span>
					<!--
						**Una rejilla, no una fila que envuelve.**

						Cada dato lleva su nombre encima, y eso estaba bien; lo que descuadraba era el
						`flex-wrap`: «extensión · unidades completas de 5 versos» es cuatro veces más ancho
						que «medida · 11», así que cada renglón partía por un sitio distinto y las
						etiquetas no caían nunca en la misma vertical. En columnas se leen las etiquetas
						en línea y se salta a la que interesa.
					-->
					<div class="mt-1 grid gap-x-6 gap-y-2 sm:grid-cols-2 lg:grid-cols-3">
						{#each fijadas as fact (`${fact.label}:${fact.value}`)}
							<span class="block min-w-0">
								<span class="block text-xs text-[color:var(--muted-foreground)]">
									{fact.label.toLocaleLowerCase('es').replace(/ fijas?$/, '')}
								</span>
								<span>{fact.value}</span>
							</span>
						{/each}
					</div>
				</div>
			{/if}

			{#if delPasaje.length > 0}
				<div class="border-t border-[color:var(--border)] pt-2.5">
					<span class="text-xs uppercase tracking-wide text-[color:var(--muted-foreground)]">
						Lo dice el pasaje que anotas
					</span>
					<div class="mt-1 grid gap-x-6 gap-y-2 sm:grid-cols-2 lg:grid-cols-3">
						{#each delPasaje as fact (`${fact.label}:${fact.value}`)}
							<span class="block min-w-0">
								<span class="block text-xs text-[color:var(--muted-foreground)]">
									{fact.label.toLocaleLowerCase('es')}
								</span>
								<span>{fact.value}</span>
							</span>
						{/each}
					</div>
				</div>
			{/if}

			{#if admitidas.length > 0}
				<p class="text-xs text-[color:var(--muted-foreground)]">
					Admite además: {admitidas
						.map((fact: MetricNormFact) => `${fact.label.toLocaleLowerCase('es')} (${fact.value})`)
						.join(', ')}.
				</p>
			{/if}

			{#if props.facts.length === 0}
				<p class="text-[color:var(--muted-foreground)]">
					La arquitectura no fija aquí más datos que los que se responden abajo.
				</p>
			{/if}
		</div>
	{/if}
</div>
