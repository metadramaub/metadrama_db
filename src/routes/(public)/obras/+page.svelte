<script lang="ts">
	import type { PageData } from './$types';

	let { data } = $props<{ data: PageData }>();

	type Obra = PageData['obras'][number];

	// --- Estado de filtros (cliente; pocas obras => filtrado en memoria) ---
	let textQuery = $state('');
	let selectedAutores = $state<string[]>([]);
	let selectedGeneros = $state<string[]>([]);
	let sortBy = $state<'titulo' | 'autor' | 'fecha' | 'versos' | 'updated'>('titulo');

	const autorOptions = $derived(data.filterOptions.autores);
	const generoOptions = $derived(data.filterOptions.generos);

	function toggle(list: string[], id: string): string[] {
		return list.includes(id) ? list.filter((x) => x !== id) : [...list, id];
	}

	function obraFecha(o: Obra): number {
		return o.fecha_inicio_trad ?? o.fecha_fin_trad ?? Number.POSITIVE_INFINITY;
	}

	const filtered = $derived.by(() => {
		const q = textQuery.trim().toLowerCase();
		let rows = data.obras.filter((o: Obra) => {
			if (q) {
				const hay =
					o.titulo.toLowerCase().includes(q) ||
					o.autoria_autores.some((a: string) => a.toLowerCase().includes(q));
				if (!hay) return false;
			}
			if (selectedAutores.length > 0) {
				if (!o.autoria_autores.some((a: string) => selectedAutores.includes(a))) return false;
			}
			if (selectedGeneros.length > 0) {
				if (!o.genero_term || !selectedGeneros.includes(o.genero_term)) return false;
			}
			return true;
		});

		rows = [...rows].sort((a: Obra, b: Obra) => {
			switch (sortBy) {
				case 'autor':
					return (a.autoria_autores[0] ?? '').localeCompare(b.autoria_autores[0] ?? '', 'es');
				case 'fecha':
					return obraFecha(a) - obraFecha(b);
				case 'versos':
					return (b.total_versos ?? 0) - (a.total_versos ?? 0);
				case 'updated':
					return (b.updated_at ?? '').localeCompare(a.updated_at ?? '');
				case 'titulo':
				default:
					return a.titulo.localeCompare(b.titulo, 'es');
			}
		});
		return rows;
	});

	const hasActiveFilters = $derived(
		textQuery.trim().length > 0 || selectedAutores.length > 0 || selectedGeneros.length > 0
	);

	function clearFilters() {
		textQuery = '';
		selectedAutores = [];
		selectedGeneros = [];
	}

	function datacionLabel(o: Obra): string {
		const ini = o.fecha_inicio_trad ?? '--';
		const fin = o.fecha_fin_trad ?? '--';
		return ini === fin ? String(ini) : `${ini}–${fin}`;
	}
</script>

<section class="space-y-5">
	<header class="flex flex-wrap items-end justify-between gap-3">
		<div>
			<h1 class="font-display text-3xl text-[color:var(--gray-900)]">CATÁLOGO DE OBRAS</h1>
			<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
				{#if data.canSeeAllPublished}
					Vista editorial (admin/IP): incluye obras publicadas no visibles sin login.
				{:else}
					Repertorio métrico del teatro áureo.
				{/if}
			</p>
		</div>
		<div class="text-sm text-[color:var(--muted-foreground)]">
			{filtered.length} de {data.obras.length}
			{data.obras.length === 1 ? 'obra' : 'obras'}
		</div>
	</header>

	<div class="grid gap-5 lg:grid-cols-[260px_1fr]">
		<!-- Panel de filtros -->
		<aside class="space-y-4">
			<div class="card p-4">
				<label class="form-field">
					<span class="form-label">Buscar</span>
					<input
						type="text"
						bind:value={textQuery}
						placeholder="Título o autor…"
						class="w-full border border-[color:var(--border)] px-3 py-2 text-sm"
					/>
				</label>

				<div class="mt-4">
					<span class="form-label">Ordenar por</span>
					<select bind:value={sortBy} class="mt-1 w-full border border-[color:var(--border)] px-2 py-2 text-sm">
						<option value="titulo">Título</option>
						<option value="autor">Autor</option>
						<option value="fecha">Fecha</option>
						<option value="versos">Nº de versos</option>
						<option value="updated">Última actualización</option>
					</select>
				</div>
			</div>

			{#if autorOptions.length > 0}
				<div class="card p-4">
					<div class="form-label mb-2">Autoría</div>
					<div class="max-h-56 space-y-1 overflow-y-auto pr-1">
						{#each autorOptions as opt (opt.id)}
							<label class="flex items-center gap-2 text-sm">
								<input
									type="checkbox"
									checked={selectedAutores.includes(opt.id)}
									onchange={() => (selectedAutores = toggle(selectedAutores, opt.id))}
								/>
								<span>{opt.label}</span>
							</label>
						{/each}
					</div>
				</div>
			{/if}

			{#if generoOptions.length > 0}
				<div class="card p-4">
					<div class="form-label mb-2">Género</div>
					<div class="space-y-1">
						{#each generoOptions as opt (opt.id)}
							<label class="flex items-center gap-2 text-sm">
								<input
									type="checkbox"
									checked={selectedGeneros.includes(opt.id)}
									onchange={() => (selectedGeneros = toggle(selectedGeneros, opt.id))}
								/>
								<span>{opt.label}</span>
							</label>
						{/each}
					</div>
				</div>
			{/if}

			{#if hasActiveFilters}
				<button
					type="button"
					class="w-full border border-[color:var(--border)] px-3 py-2 text-xs font-semibold tracking-[0.06em] hover:bg-[color:var(--muted)]"
					onclick={clearFilters}
				>
					Limpiar filtros
				</button>
			{/if}
		</aside>

		<!-- Resultados -->
		<div class="grid gap-3">
			{#if filtered.length === 0}
				<div class="card p-6 text-sm text-[color:var(--muted-foreground)]">
					{#if data.obras.length === 0}
						No hay obras disponibles para esta vista.
					{:else}
						Ninguna obra coincide con los filtros.
					{/if}
				</div>
			{:else}
				{#each filtered as obra (obra.obra_id)}
					<article class="card p-4">
						<div class="flex flex-wrap items-start justify-between gap-2">
							<div class="min-w-0">
								<h2 class="font-display text-xl">
									<a class="underline-offset-2 hover:underline" href={`/obras/${obra.obra_id}`}>
										{obra.titulo}
									</a>
								</h2>
								<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
									{obra.autoria_autores.length > 0
										? obra.autoria_autores.join(', ')
										: 'Autoría no indicada'}
								</p>
							</div>
							{#if !obra.visible_publico}
								{#if obra.es_obra_asignada}
									<span class="border border-[color:var(--border)] bg-[color:var(--muted)] px-2 py-1 text-xs">
										Tu ficha · aún no visible sin login
									</span>
								{:else if data.canSeeAllPublished}
									<span class="border border-[color:var(--border)] bg-[color:var(--muted)] px-2 py-1 text-xs">
										Solo con login editorial
									</span>
								{/if}
							{/if}
						</div>

						<div class="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-[color:var(--muted-foreground)]">
							<span>Datación: {datacionLabel(obra)}</span>
							{#if obra.genero_term}
								<span>Género: {obra.genero_term}</span>
							{/if}
							{#if obra.total_versos}
								<span>{obra.total_versos} vv.</span>
							{/if}
						</div>
					</article>
				{/each}
			{/if}
		</div>
	</div>
</section>
