<script lang="ts">
	import type { PageData } from './$types';
	import { formatRelative } from '$lib/utils/formatters';
	import Button from '$lib/components/ui/button.svelte';
	import { goto } from '$app/navigation';

	let { data } = $props<{ data: PageData }>();

	const showAlerts = $derived(['admin', 'ip'].includes(data.profile.roleTerm));
</script>

<section>
	<h1 class="font-display text-3xl">PANEL DE TRABAJO</h1>
	<p class="mt-1 text-sm">Hola, {data.profile.nombreCompleto}</p>
	<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
		{data.cardsScope === 'all'
			? 'Estas son las obras más recientes del repositorio.'
			: 'Estas son tus obras activas y su estado.'}
	</p>

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
						<span class="border border-[color:var(--border)] bg-[color:var(--muted)] px-2 py-1 text-xs">{card.estadoTerm}</span>
					</div>
					<p class="mb-2 text-xs text-[color:var(--muted-foreground)]">
						Última modificación: {formatRelative(card.updatedAt)}
					</p>
					<div class="mb-3">
						<div class="mb-1 flex items-center justify-between text-xs">
							<span>Completitud</span>
							<span>{card.progreso}%</span>
						</div>
						<div class="h-2 border border-[color:var(--border)] bg-[color:var(--muted)]">
							<div class="h-full bg-[color:var(--primary)]" style={`width: ${card.progreso}%`}></div>
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

{#if showAlerts}
	<section class="mt-8">
		<h2 class="mb-3 text-xl font-semibold">Alertas de revisión</h2>
		<div class="grid gap-4 lg:grid-cols-3">
			<article class="card p-4">
				<h3 class="mb-2 font-semibold">Comentarios recientes (72h)</h3>
				{#if data.alerts.recentComments.length === 0}
					<p class="text-sm text-[color:var(--muted-foreground)]">Sin novedades.</p>
				{:else}
					<ul class="space-y-1 text-sm">
						{#each data.alerts.recentComments as item}
							<li>
								<button
									class="text-left underline-offset-2 hover:underline"
									onclick={() => goto(`/dashboard/obras/${item.obra_id}`)}
								>
									{item.titulo} ({item.total})
								</button>
							</li>
						{/each}
					</ul>
				{/if}
			</article>

			<article class="card p-4">
				<h3 class="mb-2 font-semibold">Secuencias con certeza baja/media</h3>
				{#if data.alerts.lowOrMediumCertainty.length === 0}
					<p class="text-sm text-[color:var(--muted-foreground)]">Sin alertas.</p>
				{:else}
					<ul class="space-y-1 text-sm">
						{#each data.alerts.lowOrMediumCertainty as item}
							<li>
								<button
									class="text-left underline-offset-2 hover:underline"
									onclick={() => goto(`/dashboard/obras/${item.obra_id}`)}
								>
									{item.titulo} ({item.total})
								</button>
							</li>
						{/each}
					</ul>
				{/if}
			</article>

			<article class="card p-4">
				<h3 class="mb-2 font-semibold">Cambios de estado (7 días)</h3>
				{#if data.alerts.recentStateChanges.length === 0}
					<p class="text-sm text-[color:var(--muted-foreground)]">Sin cambios recientes.</p>
				{:else}
					<ul class="space-y-1 text-sm">
						{#each data.alerts.recentStateChanges as item}
							<li>
								<button
									class="text-left underline-offset-2 hover:underline"
									onclick={() => goto(`/dashboard/obras/${item.obra_id}`)}
								>
									{item.titulo} - {item.estadoTerm}
								</button>
							</li>
						{/each}
					</ul>
				{/if}
			</article>
		</div>
	</section>
{/if}

{#if data.allObrasSummary.length > 0}
	<section class="mt-8">
		<div class="mb-3 flex items-center justify-between">
			<h2 class="text-xl font-semibold">Resumen general</h2>
			<Button variant="secondary" onclick={() => goto('/dashboard/obras?scope=all')}>
				Ir al listado completo
			</Button>
		</div>
		<div class="card overflow-hidden">
			<table class="min-w-full text-left text-sm">
				<thead class="bg-[color:var(--muted)]">
					<tr>
						<th class="px-3 py-2">Título</th>
						<th class="px-3 py-2">Estado</th>
						<th class="px-3 py-2">Actualizado</th>
					</tr>
				</thead>
				<tbody>
					{#each data.allObrasSummary as obra}
						<tr class="border-t border-[color:var(--border)]">
							<td class="px-3 py-2">{obra.titulo}</td>
							<td class="px-3 py-2">{obra.estadoTerm}</td>
							<td class="px-3 py-2">{formatRelative(obra.updated_at)}</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	</section>
{/if}

