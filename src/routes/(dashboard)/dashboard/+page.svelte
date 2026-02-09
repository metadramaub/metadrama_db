<script lang="ts">
	import type { PageData } from './$types';
	import { formatRelative } from '$lib/utils/formatters';
	import Button from '$lib/components/ui/button.svelte';
	import { goto } from '$app/navigation';

	let { data } = $props<{ data: PageData }>();
</script>

<section>
	<h1 class="text-3xl font-semibold">Hola, {data.profile.nombreCompleto}</h1>
	<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">Estas son tus obras activas y su estado.</p>

	<div class="mt-6 grid gap-4 lg:grid-cols-2 xl:grid-cols-3">
		{#if data.cards.length === 0}
			<div class="card p-4 text-sm text-[color:var(--muted-foreground)]">
				No tienes obras asignadas en este momento.
			</div>
		{:else}
			{#each data.cards as card}
				<article class="card p-4">
					<div class="mb-2 flex items-start justify-between gap-2">
						<h2 class="text-lg font-semibold">{card.titulo}</h2>
						<span class="rounded-full bg-[color:var(--muted)] px-2 py-1 text-xs">{card.estadoTerm}</span>
					</div>
					<p class="mb-2 text-xs text-[color:var(--muted-foreground)]">
						Última modificación: {formatRelative(card.updatedAt)}
					</p>
					<div class="mb-3">
						<div class="mb-1 flex items-center justify-between text-xs">
							<span>Completitud</span>
							<span>{card.progreso}%</span>
						</div>
						<div class="h-2 rounded-full bg-[color:var(--muted)]">
							<div class="h-2 rounded-full bg-[color:var(--primary)]" style={`width: ${card.progreso}%`}></div>
						</div>
					</div>
					<Button class="w-full" onclick={() => goto(`/dashboard/obras/${card.obraId}`)}>
						Continuar edición
					</Button>
				</article>
			{/each}
		{/if}
	</div>
</section>

{#if data.allObrasSummary.length > 0}
	<section class="mt-8">
		<div class="mb-3 flex items-center justify-between">
			<h2 class="text-xl font-semibold">Resumen general</h2>
			<Button variant="secondary" onclick={() => goto('/dashboard/obras')}>
				Ir al listado completo
			</Button>
		</div>
		<div class="card overflow-hidden">
			<table class="min-w-full text-left text-sm">
				<thead class="bg-[color:var(--muted)]">
					<tr>
						<th class="px-3 py-2">Título</th>
						<th class="px-3 py-2">Estado ID</th>
						<th class="px-3 py-2">Actualizado</th>
					</tr>
				</thead>
				<tbody>
					{#each data.allObrasSummary as obra}
						<tr class="border-t border-[color:var(--border)]">
							<td class="px-3 py-2">{obra.titulo}</td>
							<td class="px-3 py-2">{obra.estado}</td>
							<td class="px-3 py-2">{formatRelative(obra.updated_at)}</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	</section>
{/if}
