<script lang="ts">
	import type {
		PublicArchitecture,
		PublicFormDetail,
		PublicRhymeLink,
		PublicFormRelation,
		PublicRepetition,
		PublicSchemePart,
		PublicRhymeScheme,
		PublicScheme,
		PublicSourceClaim,
		PublicTrait
	} from '$lib/metrica/formas-publicas.types';
	import { metricStructuralLevelLabel } from '$lib/metrica/catalogo';
	import PublicFormSectionTree from '$lib/components/metrica/PublicFormSectionTree.svelte';
	import { renderInlineMarkdown, stripMarkdown } from '$lib/utils/markdown';

	/**
	 * Ficha de una forma, generada del catálogo. No hay texto redactado aquí: si algo falta o
	 * se lee mal, falta o está mal en el catálogo. Es justamente lo que esta página sirve para
	 * detectar.
	 */
	const { data } = $props<{ data: { forma: PublicFormDetail } }>();
	const forma = $derived(data.forma);

	function extension(arquitectura: PublicArchitecture): string | null {
		const { unidadMin: min, unidadMax: max } = arquitectura;
		if (min == null && max == null) return 'serie abierta';
		if (min != null && max != null) {
			return min === max ? `${min} versos` : `de ${min} a ${max} versos`;
		}
		return min != null ? `desde ${min} versos` : `hasta ${max} versos`;
	}

	/**
	 * Qué pasa con la rima de una repetición a la siguiente. Es lo que la notación no puede
	 * decir: `[aA]…` y `[-a]…` se escriben igual, pero la silva estrena rima en cada pareado
	 * y el romance mantiene una sola asonancia. Lo dice el enlace, o su ausencia.
	 */
	function comportamientoDeLaRima(esquema: PublicRhymeScheme): string | null {
		if (esquema.enlaces.length === 0) {
			return esquema.cicla ? 'Cada repetición estrena rimas nuevas.' : null;
		}
		return null;
	}

	/**
	 * Agrupa la rima por la parte de la que es. Las de la unidad van primero y sin rótulo; las
	 * de una sección, bajo su nombre, porque «ABBA o ABAB» solo se entiende si se sabe que es
	 * de los cuartetos.
	 */
	function agruparRima(
		esquemas: PublicRhymeScheme[]
	): { clave: string; parte: string | null; esquemas: PublicRhymeScheme[] }[] {
		const grupos: { clave: string; parte: string | null; esquemas: PublicRhymeScheme[] }[] = [];
		const porParte = new Map<string, (typeof grupos)[number]>();
		for (const esquema of esquemas) {
			const clave = esquema.deLaSeccion ?? '__unidad__';
			const grupo = porParte.get(clave);
			if (grupo) grupo.esquemas.push(esquema);
			else {
				const nuevo = { clave, parte: esquema.deLaSeccion, esquemas: [esquema] };
				porParte.set(clave, nuevo);
				grupos.push(nuevo);
			}
		}
		return grupos;
	}

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

	/**
	 * «Fronte, versos 1-6». Los nombres vienen en slug del catálogo y se leen en castellano.
	 *
	 * Solo se enumeran cuando el esquema tiene **más de una** parte, que es cuando decir dónde
	 * empieza cada una añade algo. Una sola parte que abarca el esquema entero repite el rótulo
	 * bajo el que ya está —«Terceto, versos 1-6» dentro de «Tercetos»— y además invita a
	 * contarlos desde el principio de la forma, cuando en el soneto son los versos 9 a 14.
	 */
	function describirParte(parte: PublicSchemePart): string {
		const nombre = parte.nombre.replaceAll('_', ' ');
		const legible = nombre.charAt(0).toUpperCase() + nombre.slice(1);
		return parte.desde === parte.hasta
			? `${legible}, verso ${parte.desde}`
			: `${legible}, versos ${parte.desde}-${parte.hasta}`;
	}

	function describirEnlace(enlace: PublicRhymeLink, cicla: boolean): string {
		const bloque = cicla ? 'repetición' : 'bloque';
		const destino =
			enlace.desplazamiento > 0
				? `${bloque} siguiente`
				: enlace.desplazamiento < 0
					? `${bloque} anterior`
					: `mismo ${bloque}`;
		if (enlace.desde === enlace.hasta && enlace.desplazamiento !== 0) {
			return `El verso ${enlace.desde} conserva su rima en cada ${bloque}.`;
		}
		return `La rima del verso ${enlace.desde} vuelve en el verso ${enlace.hasta} del ${destino}.`;
	}

	function nombreRepeticion(repeticion: PublicRepetition): string {
		if (repeticion.tipo === 'estribillo') {
			if (repeticion.slug.endsWith('_total')) return 'Repetición total del estribillo';
			if (repeticion.slug.endsWith('_parcial')) return 'Repetición parcial del estribillo';
			if (repeticion.slug.endsWith('_implicita')) return 'Repetición implícita del estribillo';
		}
		const nombre = repeticion.slug.replaceAll('_', ' ');
		return nombre.charAt(0).toUpperCase() + nombre.slice(1);
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
			{forma.tipoRegistro === 'forma' ? 'Forma' : 'Tramo sin forma'} · {metricStructuralLevelLabel(forma.nivelEstructural)}{forma.tradiciones.length > 0
				? ` · tradición ${forma.tradiciones.join(' y ').toLowerCase()}`
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
					<section class="border border-[color:var(--border)] p-5">
						<div class="flex flex-wrap items-baseline gap-x-3 gap-y-1">
							<h3 class="font-display text-xl">{arquitectura.nombre}</h3>
							{#if arquitectura.principal}
								<span class="text-xs uppercase tracking-wide text-[color:var(--primary)]">
									principal
								</span>
							{/if}
							<span class="text-sm text-[color:var(--muted-foreground)]">
								{extension(arquitectura)}{arquitectura.modalidad
									? ` · ${arquitectura.modalidad}`
									: ''}
							</span>
						</div>

						{#if arquitectura.descripcion}
							<p class="mt-2 max-w-3xl leading-7">{@html renderInlineMarkdown(arquitectura.descripcion)}</p>
						{/if}

						{#if arquitectura.denominaciones.length > 0}
							<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">
								También: {arquitectura.denominaciones.join(' · ')}
							</p>
						{/if}

						{#if arquitectura.esquemasMetricos.length > 0 || arquitectura.esquemasRima.length > 0}
							<div class="mt-4 grid gap-4 sm:grid-cols-2">
								{#if arquitectura.esquemasMetricos.length > 0}
									<div>
										<h4 class="text-sm font-semibold">Medida</h4>
										<ul class="mt-1 space-y-1 text-sm">
											{#each arquitectura.esquemasMetricos as esquema, i (`${esquema.nombre}:${i}`)}
												<li>
													{esquema.nombre}
													{#if esquema.descripcion}
														<span class="block text-[color:var(--muted-foreground)]">
															{@html renderInlineMarkdown(esquema.descripcion)}
														</span>
													{/if}
												</li>
											{/each}
										</ul>
									</div>
								{/if}
								{#if arquitectura.esquemasRima.length > 0}
									<div>
										<h4 class="text-sm font-semibold">Rima</h4>
										<ul class="mt-1 space-y-1 text-sm">
										{#each agruparRima(arquitectura.esquemasRima) as grupo (grupo.clave)}
												{#if grupo.parte}
													<li class="pt-2 text-xs uppercase tracking-wide text-[color:var(--muted-foreground)]">
														{grupo.parte}
													</li>
												{/if}
											{#each grupo.esquemas as esquema (esquema.id)}
													<li class={grupo.parte ? 'pl-3' : ''}>
														<details class="group">
															<summary
																class="cursor-pointer list-none marker:content-none hover:underline"
															>
																<span class="font-mono">{esquema.notacion ?? '—'}</span>
																<span class="text-[color:var(--muted-foreground)]">
																	{esquema.nombre}{esquema.denominaciones.length > 0
																		? ` · también ${esquema.denominaciones.join(', ')}`
																		: ''}
																</span>
															</summary>
															<div class="mt-1 space-y-1 text-[color:var(--muted-foreground)]">
																{#if esquema.descripcion}
																	<p>{@html renderInlineMarkdown(esquema.descripcion)}</p>
																{/if}
																{#if esquema.partes.length > 1}
																	<p>{esquema.partes.map(describirParte).join(' · ')}</p>
																{/if}
																{#if esquema.restricciones.length > 0}
																	<!-- La norma de un esquema abierto: lo que acota la
																	     disposición sin fijarla. Va como lista porque
																	     son condiciones que se cumplen todas. -->
																	<ul class="ml-4 list-disc space-y-0.5">
																		{#each esquema.restricciones as restriccion, i (i)}
																			<li>
																				{restriccion.texto}
																				{#if !restriccion.obligatoria}
																					<span class="opacity-70">(no siempre)</span>
																				{/if}
																			</li>
																		{/each}
																	</ul>
																{/if}
													{#each esquema.partes.filter((p: PublicSchemePart) => p.nota) as parte (`${parte.nombre}:${parte.desde}:${parte.hasta}`)}
																	<p>{@html renderInlineMarkdown(parte.nota ?? '')}</p>
																{/each}
																{#each esquema.enlaces as enlace, i (i)}
																	<p>
																		{@html renderInlineMarkdown(
																			enlace.nota ?? describirEnlace(enlace, esquema.cicla)
																		)}
																	</p>
																{/each}
																{#if comportamientoDeLaRima(esquema)}
																	<p>{comportamientoDeLaRima(esquema)}</p>
																{/if}
															</div>
														</details>
													</li>
												{/each}
											{/each}
										</ul>
									</div>
								{/if}
							</div>
						{/if}

						{#if arquitectura.secciones.length > 0}
							<div class="mt-5">
								<h4 class="text-sm font-semibold">Partes</h4>
								<PublicFormSectionTree sections={arquitectura.secciones} />
							</div>
						{/if}

						{#if arquitectura.variedades.length > 0}
							<div class="mt-5">
								<h4 class="text-sm font-semibold">Variedades</h4>
								<ul class="mt-1 space-y-1 text-sm">
									{#each arquitectura.variedades as variedad, i (`${variedad.nombre}:${i}`)}
										<li>
											{variedad.nombre}
											{#if variedad.descripcion}
												<span class="block text-[color:var(--muted-foreground)]">
													{@html renderInlineMarkdown(variedad.descripcion)}
												</span>
											{/if}
										</li>
									{/each}
								</ul>
							</div>
						{/if}

						{#if arquitectura.repeticiones.length > 0}
							<div class="mt-5">
								<h4 class="text-sm font-semibold">Repetición</h4>
								<ul class="mt-1 space-y-2 text-sm">
									{#each arquitectura.repeticiones as repeticion, i (`${repeticion.regla}:${i}`)}
										<li>
											<span class="font-medium">{nombreRepeticion(repeticion)}</span>
											{#if repeticion.modalidad}
												<span class="text-[color:var(--muted-foreground)]">
													· {repeticion.modalidad}
												</span>
											{/if}
											<span class="block text-[color:var(--muted-foreground)]">
												{@html renderInlineMarkdown(repeticion.regla)}
											</span>
											{#if repeticion.descripcion}
												<span class="block text-[color:var(--muted-foreground)]">
													{@html renderInlineMarkdown(repeticion.descripcion)}
												</span>
											{/if}
										</li>
									{/each}
								</ul>
							</div>
						{/if}

						{#if arquitectura.rasgos.length > 0}
							<div class="mt-5">
								<h4 class="text-sm font-semibold">Rasgos que admite</h4>
								<ul class="mt-1 space-y-1 text-sm">
									{#each arquitectura.rasgos as rasgo, i (`${rasgo.nombre}:${rasgo.valor ?? ''}:${i}`)}
										<li>
											{rasgo.nombre}{rasgo.valor ? `: ${rasgo.valor}` : ''}
											{#if rasgo.modalidad}
												<span class="text-[color:var(--muted-foreground)]">
													· {rasgo.modalidad}
												</span>
											{/if}
											{#if rasgo.nota}
												<span class="block text-[color:var(--muted-foreground)]">{@html renderInlineMarkdown(rasgo.nota)}</span>
											{/if}
										</li>
									{/each}
								</ul>
							</div>
						{/if}

					</section>
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
