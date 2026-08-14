<script lang="ts">
	import type { PublicFormSummary } from '$lib/metrica/formas-publicas.types';
	import { metricStructuralLevelLabel } from '$lib/metrica/catalogo';
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

	const normalizar = (texto: string) =>
		texto
			.normalize('NFD')
			.replace(/[̀-ͯ]/g, '')
			.toLocaleLowerCase('es');

	const filtradas = $derived.by(() => {
		const termino = normalizar(busqueda.trim());
		return data.formas.filter((forma: PublicFormSummary) => {
			if (nivel && forma.nivelEstructural !== nivel) return false;
			if (tradicion && !forma.tradiciones.includes(tradicion)) return false;
			if (rima && !forma.tiposRima.includes(rima)) return false;
			if (!termino) return true;
			return [forma.nombre, forma.definicion ?? '', ...forma.denominaciones].some((campo) =>
				normalizar(campo).includes(termino)
			);
		});
	});

	const hayFiltro = $derived(Boolean(busqueda.trim() || nivel || tradicion || rima));

	function limpiar() {
		busqueda = '';
		nivel = null;
		tradicion = null;
		rima = null;
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

<section class="mx-auto w-full max-w-5xl px-4 py-10">
	<header class="max-w-3xl">
		<h1 class="font-display text-3xl">Catálogo de formas</h1>
		<p class="mt-3 leading-7 text-[color:var(--muted-foreground)]">
			Cada forma con sus arquitecturas, sus esquemas métricos y de rima, sus secciones y los
			rasgos que admite. Es la misma descripción que usa el demarcador para identificar un
			pasaje, así que lo que se lee aquí es exactamente lo que el sistema sabe.
		</p>
	</header>

	<section
		class="mt-8 border border-[color:var(--border)] bg-[color:var(--gray-50)] p-5"
		aria-labelledby="filtros-formas"
	>
		<div class="flex flex-wrap items-start justify-between gap-3">
			<div>
				<h2
					id="filtros-formas"
					class="text-xs font-semibold uppercase tracking-[0.08em] text-[color:var(--gray-700)]"
				>
					Filtrar formas
				</h2>
				<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
					Combina la búsqueda con una estructura, una tradición y un régimen de rima.
				</p>
			</div>
			{#if hayFiltro}
				<button
					type="button"
					class="inline-flex items-center gap-1.5 text-xs font-medium text-[color:var(--muted-foreground)] underline decoration-[color:var(--gray-300)] underline-offset-4 hover:text-[color:var(--foreground)]"
					onclick={limpiar}
				>
					<X size={13} aria-hidden="true" />
					Quitar filtros
				</button>
			{/if}
		</div>

		<label class="relative mt-4 block">
			<span class="sr-only">Buscar una forma</span>
			<Search
				size={17}
				class="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-[color:var(--muted-foreground)]"
				aria-hidden="true"
			/>
			<input
				type="search"
				class="h-12 w-full border border-[color:var(--border)] bg-white pl-10 pr-4 text-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[color:var(--primary)]"
				placeholder="Buscar por nombre, definición o denominación…"
				bind:value={busqueda}
			/>
		</label>

		<div class="mt-5 grid gap-5 border-t border-[color:var(--border)] pt-4 md:grid-cols-3">
			{#if niveles.length > 1}
				<fieldset>
					<legend class="text-[0.68rem] font-semibold uppercase tracking-[0.07em] text-[color:var(--muted-foreground)]">
						Estructura
					</legend>
					<div class="mt-2 flex flex-wrap gap-2">
						{#each niveles as valor (valor)}
							<button
								type="button"
								class={`min-h-9 border px-3 py-2 text-sm leading-4 transition focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[color:var(--primary)] ${
									nivel === valor
										? 'border-[color:var(--gray-900)] bg-[color:var(--gray-900)] text-white'
										: 'border-[color:var(--gray-300)] bg-white hover:border-[color:var(--gray-500)]'
								}`}
								aria-pressed={nivel === valor}
								onclick={() => (nivel = nivel === valor ? null : valor)}
							>
								{metricStructuralLevelLabel(valor)}
							</button>
						{/each}
					</div>
				</fieldset>
			{/if}
			{#if tradiciones.length > 1}
				<fieldset>
					<legend class="text-[0.68rem] font-semibold uppercase tracking-[0.07em] text-[color:var(--muted-foreground)]">
						Tradición
					</legend>
					<div class="mt-2 flex flex-wrap gap-2">
						{#each tradiciones as valor (valor)}
							<button
								type="button"
								class={`min-h-9 border px-3 py-2 text-sm leading-4 transition focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[color:var(--primary)] ${
									tradicion === valor
										? 'border-[color:var(--gray-900)] bg-[color:var(--gray-900)] text-white'
										: 'border-[color:var(--gray-300)] bg-white hover:border-[color:var(--gray-500)]'
								}`}
								aria-pressed={tradicion === valor}
								onclick={() => (tradicion = tradicion === valor ? null : valor)}
							>
								{valor}
							</button>
						{/each}
					</div>
				</fieldset>
			{/if}
			{#if rimas.length > 1}
				<fieldset>
					<legend class="text-[0.68rem] font-semibold uppercase tracking-[0.07em] text-[color:var(--muted-foreground)]">
						Rima
					</legend>
					<div class="mt-2 flex flex-wrap gap-2">
						{#each rimas as valor (valor)}
							<button
								type="button"
								class={`min-h-9 border px-3 py-2 text-sm leading-4 transition focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[color:var(--primary)] ${
									rima === valor
										? 'border-[color:var(--gray-900)] bg-[color:var(--gray-900)] text-white'
										: 'border-[color:var(--gray-300)] bg-white hover:border-[color:var(--gray-500)]'
								}`}
								aria-pressed={rima === valor}
								onclick={() => (rima = rima === valor ? null : valor)}
							>
								{valor}
							</button>
						{/each}
					</div>
				</fieldset>
			{/if}
		</div>

		<p
			class="mt-4 border-t border-[color:var(--border)] pt-3 text-sm text-[color:var(--muted-foreground)]"
			aria-live="polite"
		>
			<span class="font-medium text-[color:var(--foreground)]">{formas.length}</span>{hayFiltro
				? ` de ${totalFormas}`
				: ''}
			{formas.length === 1 ? ' forma' : ' formas'}{sinForma.length > 0
				? ` · ${sinForma.length}${hayFiltro ? ` de ${totalSinForma}` : ''} ${sinForma.length === 1 ? 'tramo sin forma' : 'tramos sin forma'}`
				: ''}
		</p>
	</section>

	<ul class="mt-8 space-y-3">
		{#each formas as forma (forma.slug)}
			<li>
				<a
					class="group block border border-[color:var(--border)] bg-white p-5 transition hover:border-[color:var(--gray-300)] hover:bg-[color:var(--gray-50)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[color:var(--primary)]"
					href="/formas/{forma.slug}"
				>
					<div class="flex items-start justify-between gap-5">
						<div class="min-w-0">
							<p class="text-[0.66rem] font-semibold uppercase tracking-[0.08em] text-[color:var(--muted-foreground)]">
							{metricStructuralLevelLabel(forma.nivelEstructural)}
							</p>
							<h2 class="mt-1 font-display text-xl leading-tight">{forma.nombre}</h2>
						</div>
						<div class="flex shrink-0 items-center gap-3">
						{#if forma.arquitecturas > 0}
							<span class="border border-[color:var(--border)] bg-white px-2 py-1 text-xs text-[color:var(--muted-foreground)]">
								{forma.arquitecturas}
								{forma.arquitecturas === 1 ? 'arquitectura' : 'arquitecturas'}
							</span>
						{/if}
							<ArrowRight
								size={17}
								class="text-[color:var(--gray-400)] transition-transform group-hover:translate-x-1 group-hover:text-[color:var(--foreground)]"
								aria-hidden="true"
							/>
						</div>
					</div>
					{#if forma.definicion}
						<p class="mt-3 max-w-3xl leading-7 text-[color:var(--gray-700)]">
							{@html renderInlineMarkdown(forma.definicion)}
						</p>
					{/if}
					{#if forma.denominaciones.length > 0}
						<p class="mt-3 border-l-2 border-[color:var(--gray-200)] pl-3 text-sm text-[color:var(--muted-foreground)]">
							<span class="font-medium text-[color:var(--gray-700)]">También</span>
							· {forma.denominaciones.join(' · ')}
						</p>
					{/if}
					{#if forma.tradiciones.length > 0 || forma.tiposRima.length > 0}
						<div class="mt-4 flex flex-wrap gap-x-6 gap-y-2 border-t border-[color:var(--border)] pt-3 text-xs">
							{#if forma.tradiciones.length > 0}
								<p>
									<span class="mr-2 uppercase tracking-[0.07em] text-[color:var(--muted-foreground)]">Tradición</span>
									<span class="font-medium">{forma.tradiciones.join(' · ')}</span>
								</p>
							{/if}
							{#if forma.tiposRima.length > 0}
								<p>
									<span class="mr-2 uppercase tracking-[0.07em] text-[color:var(--muted-foreground)]">Rima</span>
									<span class="font-medium">{forma.tiposRima.join(' · ')}</span>
								</p>
							{/if}
						</div>
					{/if}
				</a>
			</li>
		{:else}
			<li class="border border-[color:var(--border)] py-10 text-center text-[color:var(--muted-foreground)]">
				Ninguna forma coincide con la búsqueda.
			</li>
		{/each}
	</ul>

	{#if sinForma.length > 0}
		<section class="mt-12">
			<h2 class="font-display text-2xl">Tramos sin forma</h2>
			<p class="mt-2 max-w-3xl leading-7 text-[color:var(--muted-foreground)]">
				No son formas comparables con las anteriores: son la salida que se elige cuando el
				pasaje no responde a ninguna norma reconocible, y por eso no compiten con ellas.
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
