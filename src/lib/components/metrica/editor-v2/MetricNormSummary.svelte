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
		<p>
			<span class="text-xs uppercase tracking-wide text-[color:var(--muted-foreground)]">
				Ya está fijado
			</span><br />
			<span class="text-[color:var(--muted-foreground)]">
				<!-- Bajo un rótulo que ya dice «ya está fijado», repetir «medida fija» o «partes fijas»
				     en cada etiqueta sobra: la palabra la pone el rótulo. -->
				{fijadas
					.map((fact: MetricNormFact) => {
						const etiqueta = fact.label.toLocaleLowerCase('es').replace(/ fijas?$/, '');
						return `${etiqueta}: ${fact.value}`;
					})
					.join(' · ')}
			</span>
		</p>
	{/if}

	{#if delPasaje.length > 0}
		<p>
			<span class="text-xs uppercase tracking-wide text-[color:var(--muted-foreground)]">
				Lo dice el pasaje que anotas
			</span><br />
			{#each delPasaje as fact (`${fact.label}:${fact.value}`)}
				<span class="block">
					<span class="font-medium">{fact.label}</span>
					<span class="text-[color:var(--muted-foreground)]"> · {fact.value}</span>
				</span>
			{/each}
		</p>
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
		el único sitio donde se separan las dos cosas que se confunden: **una excepción es una
		respuesta legítima** —otra de las que la norma admite, en algunas unidades— y **una desviación
		es un apartamiento**, un verso que no rima donde la forma lo exige.
	-->
	<p class="border-t border-[color:var(--border)] pt-2 text-xs text-[color:var(--muted-foreground)]">
		Lo que no encaje en nada de esto no es otra respuesta: se registra como desviación.
		<a class="link-action ml-1" href={props.catalogHref} target="_blank" rel="noreferrer">
			Ver la ficha completa ↗
		</a>
	</p>
</div>
