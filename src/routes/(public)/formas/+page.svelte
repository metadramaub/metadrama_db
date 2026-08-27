<script lang="ts">
	import type { PublicFormSummary } from '$lib/metrica/formas-publicas.types';
	import { metricStructuralLevelLabel } from '$lib/metrica/catalogo';
	import CatalogFilterGroup from '$lib/components/metrica/catalogo/CatalogFilterGroup.svelte';
	import PublicFormSummaryCard from '$lib/components/metrica/catalogo/PublicFormSummaryCard.svelte';
	import PublicHelpDialog from '$lib/components/public/PublicHelpDialog.svelte';
	import PublicResourceHeader from '$lib/components/public/PublicResourceHeader.svelte';
	import {
		compararFormas,
		laFormaCoincide,
		normalizarBusqueda,
		ORDENES_DE_FORMAS,
		type OrdenFormas
	} from '$lib/metrica/orden-formas';
	import { renderInlineMarkdown } from '$lib/utils/markdown';
	import ArrowRight from 'lucide-svelte/icons/arrow-right';
	import Search from 'lucide-svelte/icons/search';
	import X from 'lucide-svelte/icons/x';

	/**
	 * Catálogo de formas. Todo lo que se lee aquí sale del catálogo métrico: si algo está mal
	 * dicho, se corrige allí y esta página cambia sola.
	 */
	const { data } = $props<{ data: { formas: PublicFormSummary[] } }>();
	type NivelEstructural = PublicFormSummary['nivelEstructural'];

	let busqueda = $state('');
	let nivel = $state<NivelEstructural | null>(null);
	let tradicion = $state<string | null>(null);
	let rima = $state<string | null>(null);
	let ayudaAbierta = $state(false);

	/** Los valores que de verdad hay, no una lista escrita a mano que pueda quedarse vieja. */
	const valoresUnicos = (elegir: (forma: PublicFormSummary) => string[]): string[] =>
		[...new Set(data.formas.flatMap(elegir) as string[])].sort((a, b) => a.localeCompare(b, 'es'));

	const tradiciones = $derived(valoresUnicos((forma) => forma.tradiciones));
	const rimas = $derived(valoresUnicos((forma) => forma.tiposRima));
	const niveles = $derived(
		[...new Set<NivelEstructural>(
			data.formas
				.filter((forma: PublicFormSummary) => forma.tipoRegistro === 'forma')
				.map((forma: PublicFormSummary) => forma.nivelEstructural)
		)].sort((a, b) =>
			metricStructuralLevelLabel(a).localeCompare(metricStructuralLevelLabel(b), 'es')
		)
	);

	const normalizar = normalizarBusqueda;

	let orden = $state<OrdenFormas>('alfabetico');

	const filtradas = $derived.by(() => {
		const termino = normalizar(busqueda.trim());
		return data.formas
			.filter((forma: PublicFormSummary) => {
				if (nivel && forma.nivelEstructural !== nivel) return false;
				if (tradicion && !forma.tradiciones.includes(tradicion)) return false;
				if (rima && !forma.tiposRima.includes(rima)) return false;
				return laFormaCoincide(forma, termino);
			})
			.sort((a: PublicFormSummary, b: PublicFormSummary) =>
				compararFormas(a, b, { orden, termino })
			);
	});

	const hayFiltro = $derived(Boolean(busqueda.trim() || nivel || tradicion || rima));

	function limpiar() {
		busqueda = '';
		nivel = null;
		tradicion = null;
		rima = null;
		orden = 'alfabetico';
	}

	// Los tramos sin forma no son formas comparables y van aparte, no mezclados en la lista.
	const formas = $derived(
		filtradas.filter((forma: PublicFormSummary) => forma.tipoRegistro === 'forma')
	);
	const sinForma = $derived(
		filtradas.filter((forma: PublicFormSummary) => forma.tipoRegistro !== 'forma')
	);
	const totalFormas = $derived(
		data.formas.filter((forma: PublicFormSummary) => forma.tipoRegistro === 'forma').length
	);
	const totalSinForma = $derived(data.formas.length - totalFormas);
</script>

<svelte:head>
	<title>Catálogo de formas · Versología</title>
	<meta
		name="description"
		content="Las formas métricas del verso dramático español, con sus arquitecturas, esquemas y rasgos."
	/>
</svelte:head>

{#snippet descripcionCatalogo()}
	<p>
		Este catálogo reúne un amplio repertorio de las formas métricas documentadas en la poesía y
		el teatro en verso españoles hasta las décadas finales del siglo XIX, antes de que se
		intensificara la experimentación métrica. Su cobertura es especialmente detallada para los
		siglos XVI y XVII, núcleo cronológico de METADRAMA; por eso, que una forma no aparezca no
		significa que no exista ni que no esté documentada en otros periodos.
	</p>
	<p>
		El catálogo es la base del análisis métrico del proyecto y se ha construido mediante el
		contraste exhaustivo de seis obras de referencia, cuyos testimonios se han formalizado como
		datos que describen la estructura de cada forma, sus posibles realizaciones y las relaciones
		que mantiene con otras, lo que permite buscar, comparar y analizar computacionalmente el
		dominio métrico dentro de un modelo que se amplía o precisa cuando el corpus plantea casos que
		obligan a volver a las fuentes.
	</p>
	<p>
		El <a
			href="/demarcador"
			class="font-medium text-[color:var(--foreground)] underline decoration-[color:var(--gray-300)] underline-offset-4 hover:decoration-[color:var(--foreground)]"
		>demarcador</a> permite recorrer este conocimiento desde un pasaje concreto, pues contrasta lo
		que se observa en él con los datos del catálogo para proponer las formas y arquitecturas más
		compatibles.
	</p>
{/snippet}

<section class="grid w-full gap-7">
	<PublicResourceHeader
		category="Recurso de consulta"
		title="Catálogo de formas"
		description={descripcionCatalogo}
		onHelp={() => (ayudaAbierta = true)}
	/>

	<section aria-labelledby="filtros-formas">
		<h2 id="filtros-formas" class="sr-only">Buscar y filtrar formas</h2>

		<label class="relative block">
			<span class="sr-only">Buscar una forma</span>
			<Search
				size={19}
				class="pointer-events-none absolute left-4 top-1/2 -translate-y-1/2 text-[color:var(--muted-foreground)]"
				aria-hidden="true"
			/>
			<input
				type="search"
				class="h-14 w-full border border-[color:var(--gray-300)] bg-white pl-12 pr-4 text-base transition-colors placeholder:text-[color:var(--muted-foreground)] focus:border-[color:var(--gray-700)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[color:var(--primary)]"
				placeholder="Buscar por nombre, definición o denominación…"
				bind:value={busqueda}
			/>
		</label>

		<div class="mt-4 flex flex-col items-start gap-3 sm:flex-row sm:justify-between sm:gap-6">
			<div class="w-full min-w-0 space-y-1.5">
			{#if niveles.length > 1}
				<CatalogFilterGroup
					id="filtro-estructura"
					label="Estructura"
					options={niveles.map((valor) => ({
						value: valor,
						label: metricStructuralLevelLabel(valor)
					}))}
					selected={nivel}
					onSelect={(value) => (nivel = value as NivelEstructural | null)}
				/>
			{/if}
			{#if tradiciones.length > 1}
				<CatalogFilterGroup
					id="filtro-tradicion"
					label="Tradición"
					options={tradiciones.map((valor) => ({ value: valor, label: valor }))}
					selected={tradicion}
					onSelect={(value) => (tradicion = value)}
				/>
			{/if}
			{#if rimas.length > 1}
				<CatalogFilterGroup
					id="filtro-rima"
					label="Rima"
					options={rimas.map((valor) => ({ value: valor, label: valor }))}
					selected={rima}
					onSelect={(value) => (rima = value)}
				/>
			{/if}
			</div>
			{#if hayFiltro}
				<button
					type="button"
					class="inline-flex shrink-0 items-center gap-1.5 py-1 text-xs font-medium text-[color:var(--muted-foreground)] underline decoration-[color:var(--gray-300)] underline-offset-4 hover:text-[color:var(--foreground)]"
					onclick={limpiar}
				>
					<X size={13} aria-hidden="true" />
					Restablecer
				</button>
			{/if}
		</div>

		<div class="mt-5 flex flex-col gap-3 border-t border-[color:var(--border)] pt-3 sm:flex-row sm:items-start sm:justify-between">
			<p class="text-sm text-[color:var(--muted-foreground)]" aria-live="polite">
				<span class="font-medium text-[color:var(--foreground)]">{formas.length}</span>{hayFiltro
					? ` de ${totalFormas}`
					: ''}
				{formas.length === 1 ? ' forma' : ' formas'}{sinForma.length > 0
					? ` · ${sinForma.length}${hayFiltro ? ` de ${totalSinForma}` : ''} ${sinForma.length === 1 ? 'tramo sin forma' : 'tramos sin forma'}`
					: ''}
			</p>

			<!-- La búsqueda ordena primero por relevancia; esta elección resuelve los empates. -->
			<div class="sm:max-w-md sm:text-right">
				<label class="flex items-center gap-2 text-sm sm:justify-end">
					<span class="text-[0.68rem] font-semibold uppercase tracking-[0.07em] text-[color:var(--muted-foreground)]">
						Ordenar
					</span>
					<select
						class="h-8 border border-[color:var(--border)] bg-white px-2 text-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[color:var(--primary)]"
						bind:value={orden}
					>
						{#each ORDENES_DE_FORMAS as opcion (opcion.valor)}
							<option value={opcion.valor}>{opcion.etiqueta}</option>
						{/each}
					</select>
				</label>
				{#if orden === 'versos'}
					<p class="mt-1 text-xs text-[color:var(--muted-foreground)]">
						Las series y composiciones de extensión variable van al final.
					</p>
				{/if}
			</div>
		</div>
	</section>

	<ul class="space-y-3">
		{#each formas as forma (forma.slug)}
			<li>
				<PublicFormSummaryCard form={forma} />
			</li>
		{:else}
			<li class="border border-[color:var(--border)] py-10 text-center text-[color:var(--muted-foreground)]">
				Ninguna forma coincide con la búsqueda.
			</li>
		{/each}
	</ul>

	{#if sinForma.length > 0}
		<section>
			<h2 class="font-display text-2xl">Tramos sin forma</h2>
			<p class="mt-2 max-w-3xl leading-7 text-[color:var(--muted-foreground)]">
				Esta sección reúne los casos en que no puede reconocerse una forma métrica: pasajes de
				versificación irregular y versos aislados. Se presentan aparte porque no comparten una
				estructura formal comparable con las formas del catálogo.
			</p>
			<ul class="mt-5 grid gap-3 md:grid-cols-2">
				{#each sinForma as forma (forma.slug)}
					<li>
						<a
							class="group block h-full border border-[color:var(--border)] bg-white p-4 transition hover:border-[color:var(--gray-300)] hover:bg-[color:var(--gray-50)]"
							href="/formas/{forma.slug}"
						>
							<div class="flex items-start justify-between gap-4">
								<h3 class="font-display text-lg">{forma.nombre}</h3>
								<ArrowRight
									size={16}
									class="shrink-0 text-[color:var(--gray-400)] transition-transform group-hover:translate-x-1 group-hover:text-[color:var(--foreground)]"
									aria-hidden="true"
								/>
							</div>
							{#if forma.definicion}
								<p class="mt-1 max-w-3xl leading-6 text-[color:var(--muted-foreground)]">
									{@html renderInlineMarkdown(forma.definicion)}
								</p>
							{/if}
						</a>
					</li>
				{/each}
			</ul>
		</section>
	{/if}
</section>

<PublicHelpDialog
	open={ayudaAbierta}
	title="Cómo consultar el catálogo"
	onClose={() => (ayudaAbierta = false)}
>
	<div class="space-y-6 text-sm leading-6 text-[color:var(--gray-700)]">
		<section>
			<h3 class="font-semibold text-[color:var(--foreground)]">Qué contiene</h3>
			<p class="mt-1">
				El catálogo reúne identidades métricas y describe las realizaciones estructurales que
				admite cada una. Las fichas muestran su organización, sus esquemas, sus partes internas,
				sus rasgos y los nombres documentados por las fuentes.
			</p>
		</section>

		<section>
			<h3 class="font-semibold text-[color:var(--foreground)]">Cómo se ha construido</h3>
			<p class="mt-1">
				Cada ficha se genera a partir del catálogo métrico formalizado con las fuentes
				bibliográficas del proyecto. No es un resumen redactado aparte: el catálogo público, el
				demarcador y el editor de secuencias leen la misma descripción estructurada.
			</p>
		</section>

		<section>
			<h3 class="font-semibold text-[color:var(--foreground)]">Fuentes utilizadas</h3>
			<p class="mt-1">
				El catálogo entero se contrastó de manera exhaustiva con seis monografías seleccionadas
				por su autoridad académica. Cada afirmación bibliográfica de una ficha se vincula con la
				fuente que la sostiene, incluso cuando varias coinciden sustancialmente.
			</p>
			<ul class="mt-3 list-disc space-y-1.5 pl-5">
				<li>
					Morley y Bruerton (1968), <cite>Cronología de las comedias de Lope de Vega</cite>.
				</li>
				<li>Quilis (1969), <cite>Métrica española</cite>.</li>
				<li>Navarro Tomás (1972), <cite>Métrica española</cite>.</li>
				<li>Domínguez Caparrós (2014), <cite>Métrica española</cite>.</li>
				<li>
					Domínguez Caparrós (2016), <cite>Diccionario de métrica española</cite>.
				</li>
				<li>Jauralde Pou (2020), <cite>Métrica española</cite>.</li>
			</ul>
		</section>

		<section>
			<h3 class="font-semibold text-[color:var(--foreground)]">Cómo consultarlo</h3>
			<ul class="mt-1 list-disc space-y-1 pl-5">
				<li>Busca por nombre, definición o denominación alternativa.</li>
				<li>Combina los filtros de estructura, tradición y régimen de rima.</li>
				<li>Abre una ficha para comparar sus arquitecturas y consultar su descripción completa.</li>
				<li>Usa el demarcador si partes de un pasaje y todavía no sabes qué forma puede ser.</li>
			</ul>
		</section>

		<section class="border-t border-[color:var(--border)] pt-5">
			<h3 class="font-semibold text-[color:var(--foreground)]">Vocabulario básico</h3>
			<dl class="mt-3 space-y-3">
				<div class="sm:grid sm:grid-cols-[9rem_1fr] sm:gap-4">
					<dt class="font-medium text-[color:var(--foreground)]">Forma</dt>
					<dd>Identidad métrica reconocible, como el romance, la lira o el soneto.</dd>
				</div>
				<div class="sm:grid sm:grid-cols-[9rem_1fr] sm:gap-4">
					<dt class="font-medium text-[color:var(--foreground)]">Arquitectura</dt>
					<dd>Realización estructural admitida dentro de una forma.</dd>
				</div>
				<div class="sm:grid sm:grid-cols-[9rem_1fr] sm:gap-4">
					<dt class="font-medium text-[color:var(--foreground)]">Esquema métrico</dt>
					<dd>Orden o conjunto de medidas de los versos.</dd>
				</div>
				<div class="sm:grid sm:grid-cols-[9rem_1fr] sm:gap-4">
					<dt class="font-medium text-[color:var(--foreground)]">Esquema de rima</dt>
					<dd>Organización de las correspondencias de rima y de los versos sueltos.</dd>
				</div>
				<div class="sm:grid sm:grid-cols-[9rem_1fr] sm:gap-4">
					<dt class="font-medium text-[color:var(--foreground)]">Sección</dt>
					<dd>Parte interna con una función propia, como la mudanza, la vuelta o el remate.</dd>
				</div>
				<div class="sm:grid sm:grid-cols-[9rem_1fr] sm:gap-4">
					<dt class="font-medium text-[color:var(--foreground)]">Rasgo</dt>
					<dd>Propiedad que puede definir, caracterizar o distinguir una realización.</dd>
				</div>
				<div class="sm:grid sm:grid-cols-[9rem_1fr] sm:gap-4">
					<dt class="font-medium text-[color:var(--foreground)]">Modalidad</dt>
					<dd>Indica si una posibilidad es definitoria, habitual, admitida o excepcional.</dd>
				</div>
				<div class="sm:grid sm:grid-cols-[9rem_1fr] sm:gap-4">
					<dt class="font-medium text-[color:var(--foreground)]">Tradición</dt>
					<dd>Ámbito histórico de procedencia documentado para la forma.</dd>
				</div>
				<div class="sm:grid sm:grid-cols-[9rem_1fr] sm:gap-4">
					<dt class="font-medium text-[color:var(--foreground)]">Denominación</dt>
					<dd>Otro nombre documentado para la misma identidad métrica.</dd>
				</div>
				<div class="sm:grid sm:grid-cols-[9rem_1fr] sm:gap-4">
					<dt class="font-medium text-[color:var(--foreground)]">Tramo sin forma</dt>
					<dd>Pasaje que no responde a una norma métrica reconocible o verso aislado.</dd>
				</div>
			</dl>
		</section>
	</div>
</PublicHelpDialog>
