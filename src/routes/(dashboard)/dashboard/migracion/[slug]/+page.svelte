<script lang="ts">
	import type { PageData } from './$types';

	let { data } = $props<{ data: PageData }>();
</script>

<section class="space-y-4">
	<header class="flex flex-wrap items-baseline justify-between gap-2">
		<div>
			<h1 class="font-display text-3xl">MIGRACIÓN MÉTRICA</h1>
			<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">{data.informe.titulo}</p>
		</div>
		<a
			href="/dashboard/migracion"
			class="text-sm text-[color:var(--muted-foreground)] underline-offset-2 hover:text-[color:var(--foreground)] hover:underline"
		>
			Todos los informes
		</a>
	</header>

	<!-- El fragmento lo escribe `npm run migracion:informe` desde el Markdown del informe: aquí no
	     se pinta ningún dato de la base, solo el texto ya compuesto. -->
	<article class="informe card max-w-4xl p-6 text-[0.95rem] leading-7">
		{@html data.informe.html}
	</article>
</section>

<style>
	.informe :global(h2) {
		margin: 2rem 0 0.5rem;
		font-size: 1.15rem;
		font-weight: 600;
		border-bottom: 1px solid var(--border);
		padding-bottom: 0.25rem;
	}
	.informe :global(h2:first-child),
	.informe :global(p:first-child) {
		margin-top: 0;
	}
	.informe :global(h3) {
		margin: 1.5rem 0 0.4rem;
		font-size: 1rem;
		font-weight: 600;
	}
	.informe :global(p) {
		margin: 0.75rem 0;
		max-width: 46rem;
	}
	.informe :global(ul),
	.informe :global(ol) {
		margin: 0.75rem 0;
		padding-left: 1.4rem;
		max-width: 46rem;
	}
	.informe :global(ul) {
		list-style: disc;
	}
	.informe :global(ol) {
		list-style: decimal;
	}
	.informe :global(li) {
		margin: 0.3rem 0;
	}
	.informe :global(a) {
		color: var(--accent);
		text-decoration: underline;
	}
	.informe :global(code) {
		background: var(--muted);
		border: 1px solid var(--border);
		padding: 0.05rem 0.3rem;
		font-size: 0.85em;
	}
	/* Las tablas del informe son anchas —una fila por secuencia— y no deben empujar la página. */
	.informe :global(table) {
		display: block;
		overflow-x: auto;
		border-collapse: collapse;
		margin: 0.8rem 0 1.4rem;
		font-size: 0.85rem;
	}
	.informe :global(th),
	.informe :global(td) {
		border: 1px solid var(--border);
		padding: 0.3rem 0.5rem;
		text-align: left;
		vertical-align: top;
	}
	.informe :global(th) {
		background: var(--muted);
	}
</style>
