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
</script>

<div class="space-y-2 border border-[color:var(--border)] bg-[color:var(--gray-50)] px-3 py-2.5 text-sm">
	{#if fijadas.length > 0}
		<div>
			<div class="flex flex-wrap items-baseline justify-between gap-x-4">
				<span class="text-xs uppercase tracking-wide text-[color:var(--muted-foreground)]">
					Ya está fijado
				</span>
				<a
					class="link-action text-xs"
					href={props.catalogHref}
					target="_blank"
					rel="noreferrer"
				>
					Ver ficha completa ↗
				</a>
			</div>
			<!--
				**Cada dato con su nombre encima, y aire entre ellos.**

				Iban seguidos y separados por puntos volados, que es tan sutil que no hay jerarquía: para
				saber qué mide una forma había que leer la línea entera. Así se busca el rótulo y se lee
				el valor.
			-->
			<div class="mt-1 flex flex-wrap gap-x-6 gap-y-1.5">
				{#each fijadas as fact (`${fact.label}:${fact.value}`)}
					<span class="block">
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
		<div class="border-t border-[color:var(--border)] pt-2">
			<span class="text-xs uppercase tracking-wide text-[color:var(--muted-foreground)]">
				Lo dice el pasaje que anotas
			</span>
			<div class="mt-1 flex flex-wrap gap-x-6 gap-y-1.5">
				{#each delPasaje as fact (`${fact.label}:${fact.value}`)}
					<!-- La misma gramática que arriba: el nombre en gris encima, el dato debajo. -->
					<span class="block">
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

	<!--
		**El renglón que cierra la frase.**

		Un recuadro que dice qué admite una forma tiene que decir qué hacer con lo que no admite: sin
		esto, al editor solo le quedan forzar una respuesta que no es la que leyó, o no anotar. Y es
		donde se separan las dos cosas que se confunden: una excepción es una respuesta legítima —otra
		de las que la norma admite— y una desviación es un apartamiento.
	-->
	<p class="text-xs text-[color:var(--muted-foreground)]">
		Lo que no encaje aquí se registra como desviación.
	</p>
</div>
