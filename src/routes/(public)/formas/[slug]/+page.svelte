<script lang="ts">
	import type { PublicFormDetail, PublicFormRelation } from '$lib/metrica/formas-publicas.types';
	import { metricStructuralLevelLabel } from '$lib/metrica/catalogo';
	import PublicArchitectureCard from '$lib/components/metrica/PublicArchitectureCard.svelte';
	import { renderInlineMarkdown, stripMarkdown } from '$lib/utils/markdown';
	/**
	 * Una enumeración en castellano: comas y una «y» final.
	 *
	 * Se unían todas con « y », y las dos sextinas —las únicas del catálogo con tres tradiciones—
	 * leían «tradición provenzal y italiana y española».
	 */
	const enumerar = (partes: string[]): string =>
		partes.length < 2 ? (partes[0] ?? '') : `${partes.slice(0, -1).join(', ')} y ${partes.at(-1)}`;


	/**
	 * Ficha de una forma, generada del catálogo. No hay texto redactado aquí: si algo falta o se
	 * lee mal, falta o está mal en el catálogo, y esta página sirve justamente para detectarlo.
	 *
	 * La página sitúa la forma —definición, denominaciones, relaciones y fuentes— y delega cada
	 * arquitectura en `PublicArchitectureCard`, que la lee dimensión a dimensión.
	 */
	const { data } = $props<{ data: { forma: PublicFormDetail } }>();
	const forma = $derived(data.forma);

	/**
	 * Cómo se lee una relación entre formas. El catálogo la declara en una dirección, así que
	 * la misma fila dice una cosa desde el origen y otra desde el destino: la copla real está
	 * «compuesta por» quintillas, y la quintilla «entra en la composición de» la copla real.
	 */
	function describirRelacion(relacion: PublicFormRelation): string {
		const desde: Record<string, string> = {
			compuesta_por: 'Se compone de',
			subtipo_de: 'Es un tipo de',
			variante_historica_de: 'Es variante histórica de',
			derivada_de: 'Deriva de',
			sucede_historicamente_a: 'Sucede históricamente a',
			relacionada_con: 'Se relaciona con',
			contrasta_con: 'Contrasta con',
			equivalente_de: 'Equivale a'
		};
		const hacia: Record<string, string> = {
			compuesta_por: 'Entra en la composición de',
			subtipo_de: 'Tiene como tipo',
			variante_historica_de: 'Tiene como variante histórica',
			derivada_de: 'Da origen a',
			sucede_historicamente_a: 'Precede históricamente a',
			relacionada_con: 'Se relaciona con',
			contrasta_con: 'Contrasta con',
			equivalente_de: 'Equivale a'
		};
		const mapa = relacion.esOrigen ? desde : hacia;
		return mapa[relacion.tipo] ?? relacion.tipo.replaceAll('_', ' ');
	}
</script>

<svelte:head>
	<title>{forma.nombre} · Catálogo de formas · Versología</title>
	{#if forma.definicion}
		<meta name="description" content={stripMarkdown(forma.definicion)} />
	{/if}
</svelte:head>

<article class="mx-auto w-full max-w-4xl px-4 py-10">
	<nav class="text-sm text-[color:var(--muted-foreground)]">
		<a class="hover:underline" href="/formas">Catálogo de formas</a>
	</nav>

	<header class="mt-4">
		<h1 class="font-display text-3xl">{forma.nombre}</h1>
		<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">
			{forma.tipoRegistro === 'forma' ? 'Forma' : 'Tramo sin forma'} · {metricStructuralLevelLabel(
				forma.nivelEstructural
			)}{forma.tradiciones.length > 0
				? ` · tradición ${enumerar(forma.tradiciones).toLowerCase()}`
				: ''}{forma.tiposRima.length > 0 ? ` · rima ${forma.tiposRima.join(' o ')}` : ''}
		</p>
		{#if forma.definicion}
			<p class="mt-4 max-w-3xl text-lg leading-8">{@html renderInlineMarkdown(forma.definicion)}</p>
		{:else}
			<p class="mt-4 text-[color:var(--muted-foreground)]">
				Esta forma todavía no tiene definición en el catálogo.
			</p>
		{/if}
	</header>

	{#if forma.denominaciones.length > 0}
		<section class="mt-8">
			<h2 class="font-display text-xl">También llamada</h2>
			<ul class="mt-2 space-y-1">
				{#each forma.denominaciones as nombre (nombre)}
					<li class="leading-7">{nombre}</li>
				{/each}
			</ul>
		</section>
	{/if}

	{#if forma.arquitecturas_.length > 0}
		<section class="mt-10">
			<h2 class="font-display text-2xl">
				{forma.arquitecturas_.length === 1 ? 'Arquitectura' : 'Arquitecturas'}
			</h2>
			<p class="mt-2 max-w-3xl leading-7 text-[color:var(--muted-foreground)]">
				Cada arquitectura es una manera de realizar la forma: su medida, su rima y sus partes.
			</p>

			<div class="mt-6 space-y-8">
				{#each forma.arquitecturas_ as arquitectura (arquitectura.slug)}
					<PublicArchitectureCard {arquitectura} />
				{/each}
			</div>
		</section>
	{/if}

	{#if forma.relaciones.length > 0}
		<section class="mt-10">
			<h2 class="font-display text-2xl">Con qué se relaciona</h2>
			<ul class="mt-4 space-y-3">
				{#each forma.relaciones as relacion (`${relacion.slug}:${relacion.tipo}:${relacion.esOrigen}`)}
					<li class="leading-7">
						<span class="text-[color:var(--muted-foreground)]">{describirRelacion(relacion)}</span>
						<a class="underline hover:no-underline" href="/formas/{relacion.slug}">
							{relacion.nombre} · {metricStructuralLevelLabel(relacion.nivelEstructural)}
						</a>
						{#if relacion.nota}
							<span class="block text-sm text-[color:var(--muted-foreground)]">
								{@html renderInlineMarkdown(relacion.nota)}
							</span>
						{/if}
					</li>
				{/each}
			</ul>
		</section>
	{/if}

	{#if forma.fuentes.length > 0}
		<section class="mt-10">
			<h2 class="font-display text-2xl">Lo que dicen las fuentes</h2>
			<ul class="mt-4 space-y-6">
				{#each forma.fuentes as fuente, indice (indice)}
					<li class="border-l-2 border-[color:var(--border)] pl-4">
						<p class="text-sm text-[color:var(--muted-foreground)]">{fuente.cita}</p>
						<ul class="mt-2 space-y-3">
							{#each fuente.afirmaciones as afirmacion, i (i)}
								<li>
									{#if afirmacion.resumen}
										<p class="leading-7">{@html renderInlineMarkdown(afirmacion.resumen)}</p>
									{/if}
									<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
										{afirmacion.localizador ?? 'Sin localizar'}{afirmacion.sobre !== forma.nombre
											? ` · sobre ${afirmacion.sobre}`
											: ''}
									</p>
								</li>
							{/each}
						</ul>
					</li>
				{/each}
			</ul>
		</section>
	{/if}
</article>
