<script lang="ts">
	import { page } from '$app/stores';
	import ArrowRight from 'lucide-svelte/icons/arrow-right';
	import LockKeyhole from 'lucide-svelte/icons/lock-keyhole';
	import CatalogMetricBar from '$lib/components/catalogo/CatalogMetricBar.svelte';
	import AuthorPortrait from '$lib/components/public/AuthorPortrait.svelte';
	import { isSectionVisible, type SectionVisibilityMap } from '$lib/secciones-publicas';
	import type { PageData } from './$types';

	let { data } = $props<{ data: PageData }>();

	const visibility = $derived(
		(($page.data as { sectionVisibility?: SectionVisibilityMap }).sectionVisibility ??
			{}) as SectionVisibilityMap
	);
	const laboratorioVisible = $derived(isSectionVisible(visibility, 'laboratorio'));
	const datacion = $derived.by(() => {
		const inicio = data.stats.datacionInicio;
		const fin = data.stats.datacionFin;
		if (inicio === null && fin === null) return '—';
		if (inicio === fin || fin === null) return String(inicio);
		if (inicio === null) return String(fin);
		return `${inicio}–${fin}`;
	});
</script>

<section class="relative flex min-h-[68vh] items-center overflow-hidden py-16">
	<div class="pointer-events-none absolute inset-0 hidden lg:block" aria-hidden="true">
		<div class="absolute left-0 top-1/2 grid w-32 -translate-y-1/2 gap-3 opacity-60">
			<span class="h-px w-20 bg-[color:var(--primary)]"></span>
			<span class="h-px w-12 bg-[color:var(--border)]"></span>
			<span class="h-px w-28 bg-[color:var(--border)]"></span>
			<span class="h-px w-16 bg-[color:var(--primary)]"></span>
			<span class="h-px w-24 bg-[color:var(--border)]"></span>
		</div>
		<div class="absolute right-0 top-1/2 grid w-32 -translate-y-1/2 justify-items-end gap-3 opacity-60">
			<span class="h-px w-24 bg-[color:var(--border)]"></span>
			<span class="h-px w-16 bg-[color:var(--primary)]"></span>
			<span class="h-px w-28 bg-[color:var(--border)]"></span>
			<span class="h-px w-12 bg-[color:var(--border)]"></span>
			<span class="h-px w-20 bg-[color:var(--primary)]"></span>
		</div>
	</div>

	<div class="relative mx-auto flex w-full max-w-4xl flex-col items-center text-center">
		<p class="text-[11px] font-semibold tracking-[0.22em] text-[color:var(--primary)]">METADRAMA</p>
		<h1 class="font-display mt-3 text-4xl font-semibold leading-tight text-[color:var(--gray-900)] md:text-6xl">
			VERSOLOGÍA
		</h1>
		<p class="mt-4 max-w-2xl text-sm leading-6 text-[color:var(--muted-foreground)] md:text-base">
			Base de datos y herramientas de estilometría estrófica para el verso dramático
		</p>
		<div class="mt-9 grid w-full max-w-3xl gap-2 sm:grid-cols-[1fr_auto]">
			<input
				type="text"
				placeholder="Buscar por título de obra o autor"
				class="w-full border border-[color:var(--border)] bg-white px-4 py-3.5 text-sm text-[color:var(--foreground)] shadow-sm outline-none transition-shadow focus:border-[color:var(--primary)] focus:ring-2 focus:ring-[color:var(--primary)]/15"
			/>
			<button
				type="button"
				class="border border-[color:var(--primary)] bg-[color:var(--primary)] px-8 py-3.5 text-xs font-semibold tracking-[0.08em] text-white transition-opacity hover:opacity-85"
			>
				BUSCAR
			</button>
		</div>
	</div>
</section>

<section
	class="-mx-4 overflow-hidden border-y border-[color:var(--gray-800)] bg-[color:var(--gray-900)] text-white md:-mx-6"
>
	<div
		class="mx-auto grid w-full max-w-7xl gap-10 px-4 py-14 md:px-6 lg:grid-cols-[0.8fr_1.2fr] lg:items-center lg:py-16"
	>
		<div>
			<p class="text-[11px] font-semibold tracking-[0.18em] text-[color:var(--primary)]">
				CÓDIGO DE BARRAS MÉTRICO
			</p>
			<h2 class="font-display mt-3 max-w-lg text-3xl leading-tight md:text-4xl">
				La secuencia métrica de una obra
			</h2>
			<p class="mt-5 max-w-xl text-sm leading-7 text-[color:var(--gray-300)]">
				Cada barra representa las formas métricas en el orden en que aparecen y conserva la
				extensión relativa de cada tramo. Las marcas verticales indican las divisiones en
				jornadas y cuadros.
			</p>
		</div>

		<div class="border border-white/15 bg-white p-5 text-[color:var(--foreground)] shadow-2xl md:p-7">
			{#if data.featuredObra}
				<div class="flex flex-wrap items-start justify-between gap-4">
					<div>
						<p class="text-[10px] font-semibold tracking-[0.16em] text-[color:var(--primary)]">
							UNA OBRA DEL CORPUS
						</p>
						<h3 class="font-display mt-2 text-2xl text-[color:var(--gray-900)]">
							{data.featuredObra.titulo}
						</h3>
					</div>
					<a
						href={`/obras/${data.featuredObra.slug}`}
						class="inline-flex h-9 w-9 items-center justify-center border border-[color:var(--border)] transition-colors hover:border-[color:var(--primary)] hover:text-[color:var(--primary)]"
						aria-label={`Abrir ${data.featuredObra.titulo}`}
					>
						<ArrowRight size={16} aria-hidden="true" />
					</a>
				</div>
				{#if data.featuredObra.tramos.length > 0}
					<div class="mt-7">
						<CatalogMetricBar
							tramos={data.featuredObra.tramos}
							jornadas={data.featuredObra.jornadas_tramos}
							cuadros={data.featuredObra.cuadros_tramos}
							totalVersos={data.featuredObra.total_versos}
							height={28}
						/>
					</div>
				{:else}
					<p class="mt-7 border-t border-[color:var(--border)] pt-5 text-xs text-[color:var(--muted-foreground)]">
						La visualización métrica de esta obra está en preparación.
					</p>
				{/if}
			{:else}
				<div class="flex min-h-40 flex-col justify-between">
					<div class="flex items-center justify-between gap-4">
						<p class="text-[10px] font-semibold tracking-[0.16em] text-[color:var(--primary)]">
							SECUENCIA MÉTRICA
						</p>
						<span
							class="border border-[color:var(--border)] px-2 py-1 text-[10px] tracking-[0.12em] text-[color:var(--muted-foreground)]"
						>
							EN PREPARACIÓN
						</span>
					</div>
					<div class="space-y-3" aria-hidden="true">
						<div class="h-5 w-full bg-[color:var(--gray-100)]"></div>
						<div class="grid grid-cols-[1fr_0.45fr_0.75fr_0.3fr] gap-1">
							<span class="h-2 bg-[color:var(--gray-300)]"></span>
							<span class="h-2 bg-[color:var(--primary)]"></span>
							<span class="h-2 bg-[color:var(--gray-700)]"></span>
							<span class="h-2 bg-[color:var(--gray-300)]"></span>
						</div>
					</div>
					<p class="text-xs text-[color:var(--muted-foreground)]">
						Aquí aparecerá una visualización real al publicarse las primeras obras.
					</p>
				</div>
			{/if}
		</div>
	</div>
</section>

<section class="py-16 md:py-20">
	<div>
		<p class="text-[11px] font-semibold tracking-[0.18em] text-[color:var(--primary)]">
			EXPLORA VERSOLOGÍA
		</p>
		<h2 class="font-display mt-2 text-3xl text-[color:var(--gray-900)] md:text-4xl">
			El corpus y sus herramientas
		</h2>
	</div>

	<div class="mt-10 grid gap-4 lg:grid-flow-row-dense lg:grid-cols-12">
		<a
			href="/obras"
			class="group flex min-h-80 flex-col justify-between overflow-hidden border border-[color:var(--border)] bg-white p-6 transition-colors hover:border-[color:var(--gray-500)] lg:col-span-8 lg:row-span-2 md:p-8"
		>
			<div class="flex items-start justify-between gap-4">
				<div>
					<p class="text-[10px] font-semibold tracking-[0.16em] text-[color:var(--primary)]">OBRAS</p>
					<h3 class="font-display mt-3 max-w-lg text-3xl leading-tight text-[color:var(--gray-900)]">
						Obras con perfil métrico
					</h3>
				</div>
				<ArrowRight class="transition-transform group-hover:translate-x-1" size={18} aria-hidden="true" />
			</div>

			<div>
				{#if data.featuredObra?.tramos.length}
					<div class="mb-5">
						<CatalogMetricBar
							tramos={data.featuredObra.tramos}
							jornadas={data.featuredObra.jornadas_tramos}
							cuadros={data.featuredObra.cuadros_tramos}
							totalVersos={data.featuredObra.total_versos}
							height={18}
						/>
					</div>
				{/if}
				<p class="max-w-xl text-sm leading-6 text-[color:var(--muted-foreground)]">
					Consulta la ficha, la estructura y el perfil métrico de cada texto publicado.
				</p>
			</div>
		</a>

		<a
			href="/autores"
			class="group flex min-h-64 flex-col justify-between overflow-hidden border border-[color:var(--border)] bg-[color:var(--muted)] p-6 transition-colors hover:border-[color:var(--gray-500)] lg:col-span-4 md:p-8"
		>
			<div class="flex items-start justify-between gap-4">
				<div>
					<p class="text-[10px] font-semibold tracking-[0.16em] text-[color:var(--primary)]">AUTORES</p>
					<h3 class="font-display mt-3 text-2xl text-[color:var(--gray-900)]">Perfiles de dramaturgos</h3>
				</div>
				<ArrowRight class="transition-transform group-hover:translate-x-1" size={18} aria-hidden="true" />
			</div>

			{#if data.autores.length > 0}
				<div class="mt-8 flex items-end">
					{#each data.autores as autor, index (autor.slug)}
						<div
							class={`relative h-20 w-20 overflow-hidden rounded-full border-4 border-[color:var(--muted)] bg-[color:var(--gray-100)] ${index > 0 ? '-ml-4' : ''}`}
							title={autor.nombre_completo}
						>
							<AuthorPortrait src={autor.imagen_wikidata?.url} alt={autor.nombre_completo} />
						</div>
					{/each}
				</div>
			{:else}
				<p class="mt-8 text-sm text-[color:var(--muted-foreground)]">
					Los perfiles aparecerán con las primeras obras publicadas.
				</p>
			{/if}
		</a>

		<a
			href="/recursos/catalogo-metrico"
			class="group flex min-h-52 flex-col justify-between border border-[color:var(--border)] bg-[color:var(--primary)] p-6 text-white transition-colors hover:border-[color:var(--gray-900)] lg:col-span-4"
		>
			<div class="flex items-start justify-between gap-3">
				<p class="text-[10px] font-semibold tracking-[0.16em]">CATÁLOGO MÉTRICO</p>
				<ArrowRight class="transition-transform group-hover:translate-x-1" size={18} aria-hidden="true" />
			</div>
			<div>
				<p class="font-display text-4xl tracking-[0.12em]">ABBA</p>
				<h3 class="font-display mt-3 text-xl">Aprende sobre métrica</h3>
				<p class="mt-2 text-xs leading-5 text-white/80">
					Formas, estructuras, metros y esquemas de rima.
				</p>
			</div>
		</a>

		<a
			href="/recursos/demarcador"
			class="group flex min-h-64 flex-col justify-between border border-[color:var(--primary)] bg-white p-6 transition-colors hover:border-[color:var(--gray-900)] lg:col-span-5"
		>
			<div class="flex items-start justify-between gap-3">
				<p class="text-[10px] font-semibold tracking-[0.16em] text-[color:var(--primary)]">
					DEMARCADOR
				</p>
				<ArrowRight class="transition-transform group-hover:translate-x-1" size={18} aria-hidden="true" />
			</div>
			<div>
				<div class="mb-5 flex flex-wrap gap-2 text-[9px] font-semibold tracking-[0.12em] text-[color:var(--gray-600)]">
					<span class="border border-[color:var(--border)] px-2 py-1">EXTENSIÓN</span>
					<span class="border border-[color:var(--border)] px-2 py-1">METRO</span>
					<span class="border border-[color:var(--border)] px-2 py-1">RIMA</span>
				</div>
				<h3 class="font-display text-2xl text-[color:var(--gray-900)]">Identifica una forma métrica</h3>
				<p class="mt-2 max-w-xl text-xs leading-5 text-[color:var(--muted-foreground)]">
					Responde a preguntas breves sobre los rasgos de un pasaje y contrasta las formas
					que mejor encajan.
				</p>
			</div>
		</a>

		<a
			href="/recursos/guia"
			class="group flex min-h-44 flex-col justify-between border border-[color:var(--border)] bg-[color:var(--muted)] p-6 transition-colors hover:border-[color:var(--gray-500)] lg:col-span-3"
		>
			<div class="flex items-start justify-between gap-3">
				<p class="text-[10px] font-semibold tracking-[0.16em] text-[color:var(--primary)]">
					GUÍA DE USO
				</p>
				<ArrowRight class="transition-transform group-hover:translate-x-1" size={16} aria-hidden="true" />
			</div>
			<div>
				<h3 class="font-display text-xl text-[color:var(--gray-900)]">Metodología e interpretación</h3>
				<p class="mt-2 text-xs leading-5 text-[color:var(--muted-foreground)]">
					Criterios del corpus y claves para interpretar los datos y las visualizaciones.
				</p>
			</div>
		</a>

		<div
			class="group relative flex min-h-56 flex-col justify-between border border-[color:var(--gray-800)] bg-[color:var(--gray-900)] p-6 text-white lg:col-span-4"
		>
			{#if laboratorioVisible}
				<a class="absolute inset-0" href="/laboratorio" aria-label="Abrir el laboratorio"></a>
			{/if}
			<div class="flex items-start justify-between gap-3">
				<p class="text-[10px] font-semibold tracking-[0.16em] text-[color:var(--gray-300)]">LABORATORIO</p>
				{#if laboratorioVisible}
					<ArrowRight class="transition-transform group-hover:translate-x-1" size={18} aria-hidden="true" />
				{:else}
					<LockKeyhole size={17} aria-hidden="true" />
				{/if}
			</div>
			<div>
				<h3 class="font-display text-xl">Laboratorio</h3>
				<p class="mt-2 text-xs leading-5 text-[color:var(--gray-300)]">
					Comparación y visualización experimental.
				</p>
			</div>
		</div>
	</div>
</section>

{#if data.stats.obras > 0}
	<section
		class="-mx-4 border-y border-[color:var(--gray-800)] bg-[color:var(--gray-900)] px-4 py-14 text-white md:-mx-6 md:px-6"
	>
		<h2 class="font-display mb-10 text-2xl">El corpus en cifras</h2>
		<div class="grid gap-8 sm:grid-cols-2 lg:grid-cols-5">
			<div>
				<p class="font-display text-4xl">
					{data.stats.obras.toLocaleString('es-ES')}
				</p>
				<p class="mt-2 text-xs font-semibold tracking-[0.12em] text-[color:var(--gray-400)]">OBRAS</p>
			</div>
			<div>
				<p class="font-display text-4xl">
					{data.stats.autores.toLocaleString('es-ES')}
				</p>
				<p class="mt-2 text-xs font-semibold tracking-[0.12em] text-[color:var(--gray-400)]">AUTORES</p>
			</div>
			<div>
				<p class="font-display text-4xl">
					{data.stats.versos.toLocaleString('es-ES')}
				</p>
				<p class="mt-2 text-xs font-semibold tracking-[0.12em] text-[color:var(--gray-400)]">VERSOS</p>
			</div>
			<div>
				<p class="font-display text-4xl">
					{data.stats.formas.toLocaleString('es-ES')}
				</p>
				<p class="mt-2 text-xs font-semibold tracking-[0.12em] text-[color:var(--gray-400)]">
					FORMAS MÉTRICAS
				</p>
			</div>
			<div>
				<p class="font-display text-4xl">{datacion}</p>
				<p class="mt-2 text-xs font-semibold tracking-[0.12em] text-[color:var(--gray-400)]">
					DATACIÓN DEL CORPUS
				</p>
			</div>
		</div>
	</section>
{/if}
