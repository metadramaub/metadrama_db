<script lang="ts">
	import { page } from '$app/stores';
	import { isSectionVisible, type SectionVisibilityMap } from '$lib/secciones-publicas';

	// La portada no carga datos propios, pero el layout baja el mapa de secciones. Sin él no
	// se enseña la tarjeta: mejor esconder de más que enlazar a algo que va a fallar.
	const formasVisible = $derived(
		isSectionVisible(
			(($page.data as { sectionVisibility?: SectionVisibilityMap }).sectionVisibility ??
				{}) as SectionVisibilityMap,
			'formas'
		)
	);
</script>

<section class="flex min-h-[74vh] items-center">
	<div class="mx-auto flex w-full max-w-4xl flex-col items-center text-center">
		<h1 class="font-display font-semibold text-3xl leading-tight text-[color:var(--gray-900)] md:text-5xl">
			VERSOLOGÍA
		</h1>
		<p class="mt-3 max-w-2xl text-sm text-[color:var(--muted-foreground)] md:text-base">
			Base de datos y herramientas de estilometría estrófica para el verso dramático
		</p>
		<div class="mt-8 grid w-full max-w-3xl gap-2 sm:grid-cols-[1fr_auto]">
			<input
				type="text"
				placeholder="Buscar por título de obra o autor"
				class="w-full border border-[color:var(--border)] bg-white px-3 py-3 text-sm text-[color:var(--foreground)]"
			/>
			<button
				type="button"
				class="border border-[color:var(--primary)] bg-[color:var(--primary)] px-6 py-3 text-sm font-semibold text-[color:var(--gray-50)]"
			>
				BUSCAR
			</button>
		</div>
	</div>
</section>

<section class="pt-[14vh] pb-16 md:pt-[18vh]">
	<div class="grid gap-5 lg:grid-cols-2 2xl:grid-cols-4">
		<article class="card flex min-h-[20rem] flex-col p-5">
			<h2 class="font-display text-lg leading-tight text-[color:var(--gray-900)]">EXPLORA EL CATÁLOGO DE OBRAS</h2>
			<p class="mt-3 flex-1 text-sm text-[color:var(--muted-foreground)]">
				Consulta el análisis métrico de cada comedia.
			</p>
			<a
				href="/catalogo"
				class="mt-5 border border-[color:var(--primary)] bg-[color:var(--primary)] px-3 py-2 text-center text-xs font-semibold tracking-[0.06em] text-[color:var(--gray-50)]"
			>
				BUSCADOR
			</a>
		</article>

		<article class="card flex min-h-[20rem] flex-col p-5">
			<h2 class="font-display text-lg leading-tight text-[color:var(--gray-900)]">DESCUBRE EL PERFIL MÉTRICO DE CADA AUTOR</h2>
			<p class="mt-3 flex-1 text-sm text-[color:var(--muted-foreground)]">
				Accede a estadísticas de uso de género y metro.
			</p>
			<a
				href="/autores"
				class="mt-5 border border-[color:var(--primary)] bg-[color:var(--primary)] px-3 py-2 text-center text-xs font-semibold tracking-[0.06em] text-[color:var(--gray-50)]"
			>
				AUTORES
			</a>
		</article>

		<article class="card flex min-h-[20rem] flex-col p-5">
			<h2 class="font-display text-lg leading-tight text-[color:var(--gray-900)]">COMPARA Y VISUALIZA PATRONES</h2>
			<p class="mt-3 flex-1 text-sm text-[color:var(--muted-foreground)]">
				Genera gráficas comparativas entre corpus completos y relaciones entre autores.
			</p>
			<a
				href="/laboratorio"
				class="mt-5 border border-[color:var(--primary)] bg-[color:var(--primary)] px-3 py-2 text-center text-xs font-semibold tracking-[0.06em] text-[color:var(--gray-50)]"
			>
				LABORATORIO
			</a>
		</article>

		{#if formasVisible}
			<article class="card flex min-h-[20rem] flex-col p-5">
				<h2 class="font-display text-lg leading-tight text-[color:var(--gray-900)]">
					CONSULTA EL CATÁLOGO DE FORMAS
				</h2>
				<p class="mt-3 flex-1 text-sm text-[color:var(--muted-foreground)]">
					Cada forma métrica con sus arquitecturas, esquemas, rasgos y lo que dicen las fuentes.
				</p>
				<a
					href="/formas"
					class="mt-5 border border-[color:var(--primary)] bg-[color:var(--primary)] px-3 py-2 text-center text-xs font-semibold tracking-[0.06em] text-[color:var(--gray-50)]"
				>
					FORMAS MÉTRICAS
				</a>
			</article>
		{/if}
	</div>
</section>
