<script lang="ts">
	let { children } = $props();
</script>

<div class="min-h-screen">
	<header class="border-b border-[color:var(--border)] bg-white/80 backdrop-blur">
		<div class="mx-auto flex max-w-6xl items-center justify-between px-4 py-3">
			<a href="/" class="text-xl font-semibold">METADRAMA</a>
			<nav class="flex gap-4 text-sm">
				<a href="/obras">Obras</a>
				<a href="/autores">Autores</a>
				<a href="/about">Sobre el proyecto</a>
				<a href="/login" class="rounded-md border border-[color:var(--border)] px-2 py-1">Acceder</a>
			</nav>
		</div>
	</header>

	<main class="mx-auto max-w-6xl px-4 py-8">
		{@render children()}
	</main>

	<footer class="mt-10 border-t border-[color:var(--border)] bg-white/60 py-6">
		<div class="mx-auto max-w-6xl px-4 text-sm text-[color:var(--muted-foreground)]">
			METADRAMA · Proyecto académico de análisis métrico del teatro áureo.
		</div>
	</footer>
</div>
