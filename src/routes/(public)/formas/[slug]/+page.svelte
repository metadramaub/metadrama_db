<script lang="ts">
	import type { PublicFormDetail, PublicFormRelation } from '$lib/metrica/formas-publicas.types';
	import { metricStructuralLevelLabel } from '$lib/metrica/catalogo';
	import PublicArchitectureCard from '$lib/components/metrica/PublicArchitectureCard.svelte';
	import PublicFormNavigation from '$lib/components/metrica/catalogo/PublicFormNavigation.svelte';
	import PublicFormSectionHeader from '$lib/components/metrica/catalogo/PublicFormSectionHeader.svelte';
	import PublicSourceReference from '$lib/components/metrica/catalogo/PublicSourceReference.svelte';
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
	const navigationItems = $derived([
		{ href: '#resumen', label: 'Resumen' },
		...(forma.arquitecturas_.length > 0
			? [{ href: '#arquitecturas', label: 'Arquitecturas' }]
			: []),
		...(forma.relaciones.length > 0 ? [{ href: '#relaciones', label: 'Relaciones' }] : []),
		...(forma.fuentes.length > 0 ? [{ href: '#fuentes', label: 'Fuentes' }] : [])
	]);

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

<article class="w-full">
	<nav class="text-sm text-[color:var(--muted-foreground)]" aria-label="Migas de pan">
		<a class="transition-colors hover:text-[color:var(--foreground)]" href="/formas">
			Catálogo de formas
		</a>
		<span class="mx-2" aria-hidden="true">/</span>
		<span class="text-[color:var(--foreground)]">{forma.nombre}</span>
	</nav>

	<div class="mt-6 lg:grid lg:grid-cols-[12rem_minmax(0,1fr)] lg:items-start lg:gap-10 xl:grid-cols-[14rem_minmax(0,1fr)] xl:gap-12">
		<aside class="sticky top-0 z-20 bg-[color:var(--background)] lg:top-6 lg:z-auto">
			<PublicFormNavigation items={navigationItems} />
		</aside>

		<div class="min-w-0">
			<header id="resumen" class="scroll-mt-20 pt-7 lg:scroll-mt-6 lg:pt-0">
				<p class="text-xs font-semibold uppercase tracking-[0.09em] text-[color:var(--muted-foreground)]">
					{forma.tipoRegistro === 'forma' ? 'Forma métrica' : 'Tramo sin forma'}
					<span class="mx-1.5 text-[color:var(--gray-300)]" aria-hidden="true">·</span>
					{metricStructuralLevelLabel(forma.nivelEstructural)}
				</p>
				<h1 class="mt-3 max-w-4xl font-display text-4xl leading-tight text-[color:var(--gray-900)] md:text-5xl">
					{forma.nombre}
				</h1>

				{#if forma.denominaciones.length > 0}
					<p class="mt-3 text-sm leading-6 text-[color:var(--muted-foreground)]">
						<span class="font-medium text-[color:var(--gray-700)]">Otras denominaciones:</span>
						{forma.denominaciones.join(' · ')}
					</p>
				{/if}

				{#if forma.tradiciones.length > 0 || forma.tiposRima.length > 0}
					<dl class="mt-5 flex flex-wrap gap-x-8 gap-y-3 bg-[color:var(--gray-50)] px-4 py-3 text-sm">
						{#if forma.tradiciones.length > 0}
							<div class="flex items-baseline gap-2">
								<dt class="text-xs font-semibold uppercase tracking-[0.07em] text-[color:var(--muted-foreground)]">
									Tradición
								</dt>
								<dd>{enumerar(forma.tradiciones)}</dd>
							</div>
						{/if}
						{#if forma.tiposRima.length > 0}
							<div class="flex items-baseline gap-2">
								<dt class="text-xs font-semibold uppercase tracking-[0.07em] text-[color:var(--muted-foreground)]">
									Rima
								</dt>
								<dd>{forma.tiposRima.join(' o ')}</dd>
							</div>
						{/if}
					</dl>
				{/if}

				<div class="mt-6 max-w-4xl">
					{#if forma.definicion}
						<p class="text-[1.05rem] leading-8">{@html renderInlineMarkdown(forma.definicion)}</p>
					{:else}
						<p class="leading-7 text-[color:var(--muted-foreground)]">
							Esta forma todavía no tiene definición en el catálogo.
						</p>
					{/if}
				</div>
			</header>

			{#if forma.arquitecturas_.length > 0}
				<section id="arquitecturas" class="mt-10 scroll-mt-20 border-t border-[color:var(--border)] pt-8 lg:scroll-mt-6">
					<PublicFormSectionHeader
						title={forma.arquitecturas_.length === 1 ? 'Arquitectura' : 'Arquitecturas'}
						description="Cada arquitectura describe una configuración posible de la forma y precisa su extensión, su medida, su rima, sus partes y los rasgos que admite."
						count={forma.arquitecturas_.length}
					/>

					<div class="mt-6 space-y-8">
						{#each forma.arquitecturas_ as arquitectura (arquitectura.slug)}
							<PublicArchitectureCard {arquitectura} />
						{/each}
					</div>
				</section>
			{/if}

			{#if forma.relaciones.length > 0}
				<section id="relaciones" class="mt-10 scroll-mt-20 border-t border-[color:var(--border)] pt-8 lg:scroll-mt-6">
					<PublicFormSectionHeader
						title="Relaciones con otras formas"
						description="Vínculos estructurales e históricos declarados en el catálogo."
					/>
					<ul class="mt-5 divide-y divide-[color:var(--border)]">
						{#each forma.relaciones as relacion (`${relacion.slug}:${relacion.tipo}:${relacion.esOrigen}`)}
							<li class="py-4 leading-7">
								<p>
									<span class="text-[color:var(--muted-foreground)]">{describirRelacion(relacion)} </span>
									<a class="font-medium underline underline-offset-4 hover:no-underline" href="/formas/{relacion.slug}">
										{relacion.nombre}
									</a>
									<span class="text-sm text-[color:var(--muted-foreground)]">
										· {metricStructuralLevelLabel(relacion.nivelEstructural)}
									</span>
								</p>
								{#if relacion.nota}
									<p class="mt-1 max-w-3xl text-sm text-[color:var(--muted-foreground)]">
										{@html renderInlineMarkdown(relacion.nota)}
									</p>
								{/if}
							</li>
						{/each}
					</ul>
				</section>
			{/if}

			{#if forma.fuentes.length > 0}
				<section id="fuentes" class="mt-10 scroll-mt-20 border-t border-[color:var(--border)] pt-8 lg:scroll-mt-6">
					<PublicFormSectionHeader
						title="Fuentes bibliográficas"
						description="Testimonios bibliográficos de los que procede la información recogida en la ficha."
					/>
					<ul class="mt-6 space-y-7">
						{#each forma.fuentes as fuente, indice (indice)}
							<li class="grid gap-4 border-l-2 border-[color:var(--gray-300)] pl-5 md:grid-cols-[14rem_minmax(0,1fr)] md:gap-8">
								<PublicSourceReference source={fuente} />
								<ul class="space-y-4">
									{#each fuente.afirmaciones as afirmacion, i (i)}
										<li>
											{#if afirmacion.resumen}
												<p class="max-w-4xl leading-7">{@html renderInlineMarkdown(afirmacion.resumen)}</p>
											{/if}
											<p class="mt-1 text-xs text-[color:var(--muted-foreground)]">
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
		</div>
	</div>
</article>
