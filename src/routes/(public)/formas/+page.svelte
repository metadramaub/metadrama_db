<script lang="ts">
	import type { PublicFormSummary } from '$lib/metrica/formas-publicas.types';
	import { renderInlineMarkdown } from '$lib/utils/markdown';

	/**
	 * Catálogo de formas. Todo lo que se lee aquí sale del catálogo métrico: si algo está mal
	 * dicho, se corrige allí y esta página cambia sola.
	 */
	const { data } = $props<{ data: { formas: PublicFormSummary[] } }>();

	let busqueda = $state('');
	let tradicion = $state<string | null>(null);
	let rima = $state<string | null>(null);

	/** Los valores que de verdad hay, no una lista escrita a mano que pueda quedarse vieja. */
	const valoresUnicos = (elegir: (forma: PublicFormSummary) => string[]): string[] =>
		[...new Set(data.formas.flatMap(elegir) as string[])].sort((a, b) => a.localeCompare(b, 'es'));

	const tradiciones = $derived(valoresUnicos((forma) => forma.tradiciones));
	const rimas = $derived(valoresUnicos((forma) => forma.tiposRima));

	const normalizar = (texto: string) =>
		texto
			.normalize('NFD')
			.replace(/[̀-ͯ]/g, '')
			.toLocaleLowerCase('es');

	const filtradas = $derived.by(() => {
		const termino = normalizar(busqueda.trim());
		return data.formas.filter((forma: PublicFormSummary) => {
			if (tradicion && !forma.tradiciones.includes(tradicion)) return false;
			if (rima && !forma.tiposRima.includes(rima)) return false;
			if (!termino) return true;
			return [forma.nombre, forma.definicion ?? '', ...forma.denominaciones].some((campo) =>
				normalizar(campo).includes(termino)
			);
		});
	});

	const hayFiltro = $derived(Boolean(busqueda.trim() || tradicion || rima));

	function limpiar() {
		busqueda = '';
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

	<div class="mt-8">
		<label class="block">
			<span class="sr-only">Buscar una forma</span>
			<input
				type="search"
				class="h-11 w-full max-w-md border border-[color:var(--border)] px-3"
				placeholder="Buscar por nombre, definición o denominación…"
				bind:value={busqueda}
			/>
		</label>
		<div class="mt-4 flex flex-wrap items-center gap-x-6 gap-y-3">
			{#if tradiciones.length > 1}
				<div class="flex flex-wrap items-center gap-2">
					<span class="text-sm text-[color:var(--muted-foreground)]">Tradición</span>
					{#each tradiciones as valor (valor)}
						<button
							type="button"
							class={`border px-3 py-1 text-sm transition ${
								tradicion === valor
									? 'border-[color:var(--primary)] bg-[color:var(--primary)] text-[color:var(--gray-50)]'
									: 'border-[color:var(--border)] hover:bg-[color:var(--gray-50)]'
							}`}
							aria-pressed={tradicion === valor}
							onclick={() => (tradicion = tradicion === valor ? null : valor)}
						>
							{valor}
						</button>
					{/each}
				</div>
			{/if}
			{#if rimas.length > 1}
				<div class="flex flex-wrap items-center gap-2">
					<span class="text-sm text-[color:var(--muted-foreground)]">Rima</span>
					{#each rimas as valor (valor)}
						<button
							type="button"
							class={`border px-3 py-1 text-sm transition ${
								rima === valor
									? 'border-[color:var(--primary)] bg-[color:var(--primary)] text-[color:var(--gray-50)]'
									: 'border-[color:var(--border)] hover:bg-[color:var(--gray-50)]'
							}`}
							aria-pressed={rima === valor}
							onclick={() => (rima = rima === valor ? null : valor)}
						>
							{valor}
						</button>
					{/each}
				</div>
			{/if}
			{#if hayFiltro}
				<button type="button" class="link-action link-action--sm" onclick={limpiar}>
					Quitar filtros
				</button>
			{/if}
		</div>

		<p class="mt-3 text-sm text-[color:var(--muted-foreground)]">
			{formas.length}
			{formas.length === 1 ? 'forma' : 'formas'}{sinForma.length > 0
				? ` · ${sinForma.length} ${sinForma.length === 1 ? 'tramo sin forma' : 'tramos sin forma'}`
				: ''}
		</p>
	</div>

	<ul class="mt-6 divide-y divide-[color:var(--border)] border-y border-[color:var(--border)]">
		{#each formas as forma (forma.slug)}
			<li>
				<a class="block py-5 transition hover:bg-[color:var(--gray-50)]" href="/formas/{forma.slug}">
					<div class="flex flex-wrap items-baseline gap-x-3 gap-y-1">
						<h2 class="font-display text-xl">{forma.nombre}</h2>
						<span class="text-xs uppercase tracking-wide text-[color:var(--muted-foreground)]">
							{forma.nivelEstructural}
						</span>
						{#if forma.arquitecturas > 0}
							<span class="text-xs text-[color:var(--muted-foreground)]">
								{forma.arquitecturas}
								{forma.arquitecturas === 1 ? 'arquitectura' : 'arquitecturas'}
							</span>
						{/if}
					</div>
					{#if forma.definicion}
						<p class="mt-1 max-w-3xl leading-6 text-[color:var(--muted-foreground)]">
							{@html renderInlineMarkdown(forma.definicion)}
						</p>
					{/if}
					{#if forma.denominaciones.length > 0}
						<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
							También: {forma.denominaciones.join(' · ')}
						</p>
					{/if}
					{#if forma.tradiciones.length > 0 || forma.tiposRima.length > 0}
						<p class="mt-1 text-xs text-[color:var(--muted-foreground)]">
							{[...forma.tradiciones, ...forma.tiposRima].join(' · ')}
						</p>
					{/if}
				</a>
			</li>
		{:else}
			<li class="py-8 text-[color:var(--muted-foreground)]">
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
			<ul class="mt-4 divide-y divide-[color:var(--border)] border-y border-[color:var(--border)]">
				{#each sinForma as forma (forma.slug)}
					<li>
						<a
							class="block py-4 transition hover:bg-[color:var(--gray-50)]"
							href="/formas/{forma.slug}"
						>
							<h3 class="font-display text-lg">{forma.nombre}</h3>
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
