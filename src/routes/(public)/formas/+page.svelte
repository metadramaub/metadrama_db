<script lang="ts">
	import type { PublicFormSummary } from '$lib/metrica/formas-publicas.types';

	/**
	 * Catálogo de formas. Todo lo que se lee aquí sale del catálogo métrico: si algo está mal
	 * dicho, se corrige allí y esta página cambia sola.
	 */
	const { data } = $props<{ data: { formas: PublicFormSummary[] } }>();

	let busqueda = $state('');

	const normalizar = (texto: string) =>
		texto
			.normalize('NFD')
			.replace(/[̀-ͯ]/g, '')
			.toLocaleLowerCase('es');

	const filtradas = $derived.by(() => {
		const termino = normalizar(busqueda.trim());
		if (!termino) return data.formas;
		return data.formas.filter((forma: PublicFormSummary) =>
			[forma.nombre, forma.definicion ?? '', ...forma.denominaciones].some((campo) =>
				normalizar(campo).includes(termino)
			)
		);
	});

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
		<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">
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
							{forma.nivelEstructural}{forma.gradoEspecificacion === 'general'
								? ' · general'
								: ''}
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
							{forma.definicion}
						</p>
					{/if}
					{#if forma.denominaciones.length > 0}
						<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
							También: {forma.denominaciones.join(' · ')}
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
									{forma.definicion}
								</p>
							{/if}
						</a>
					</li>
				{/each}
			</ul>
		</section>
	{/if}
</section>
