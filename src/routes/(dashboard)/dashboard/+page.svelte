<script lang="ts">
	import { goto, invalidate } from '$app/navigation';
	import { onMount } from 'svelte';
	import Button from '$lib/components/ui/button.svelte';
	import { formatRelative } from '$lib/utils/formatters';
	import type { PageData } from './$types';

	let { data } = $props<{ data: PageData }>();

	const isAdminOrIp = $derived(['admin', 'ip'].includes(data.profile.roleTerm));

	function openActivity(item: PageData['recentActivity'][number]) {
		void goto(item.targetUrl ?? `/dashboard/obras/${item.obraId}?tab=${item.tab}`);
	}

	onMount(() => {
		const handleObrasUpdated = () => {
			void invalidate('dashboard:home');
		};
		window.addEventListener('dashboard-obras-updated', handleObrasUpdated);
		return () => {
			window.removeEventListener('dashboard-obras-updated', handleObrasUpdated);
		};
	});
</script>

<section>
	<div class="flex flex-wrap items-end justify-between gap-4">
		<div>
			<h1 class="font-display text-3xl">PANEL DE TRABAJO</h1>
			<p class="mt-1 text-sm">Hola, {data.profile.nombreCompleto}</p>
			<p class="mt-5 text-sm text-[color:var(--muted-foreground)]">
				{isAdminOrIp
					? 'Resumen global de la base de datos y de los cambios recientes.'
					: 'Resumen de tus obras asignadas y actividad reciente de tus revisiones.'}
			</p>
		</div>
	</div>

	<div class="mt-2 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
		<article class="card p-4">
			<p class="text-xs text-[color:var(--muted-foreground)]">Total obras</p>
			<p class="mt-1 text-2xl font-semibold">{data.kpis.totalObras}</p>
		</article>
		<article class="card p-4">
			<p class="text-xs text-[color:var(--muted-foreground)]">En borrador</p>
			<p class="mt-1 text-2xl font-semibold">{data.kpis.totalBorrador}</p>
		</article>
		<article class="card p-4">
			<p class="text-xs text-[color:var(--muted-foreground)]">Vista previa / listo para publicar</p>
			<p class="mt-1 text-2xl font-semibold">{data.kpis.totalPreviewListo}</p>
		</article>
		<article class="card p-4">
			<p class="text-xs text-[color:var(--muted-foreground)]">Publicadas</p>
			<p class="mt-1 text-2xl font-semibold">{data.kpis.totalPublicadas}</p>
		</article>
	</div>
</section>

<section class="mt-4">
	<div class="card flex flex-wrap items-start justify-between gap-3 p-4">
		<div>
			<h2 class="text-lg font-semibold">Guía editorial interna</h2>
			<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
				Manual paso a paso para editores y colaboradores del proyecto.
			</p>
		</div>
		<Button variant="secondary" onclick={() => goto('/dashboard/guia')}>Abrir guía de uso</Button>
	</div>
</section>

<section class="mt-8">
	<div class="mb-3 flex items-center justify-between">
		<h2 class="text-xl font-semibold">Últimos cambios</h2>
		<Button variant="ghost" onclick={() => goto('/dashboard/notificaciones')}>Ver toda la actividad reciente</Button>
	</div>
	<div class="card p-4">
		{#if data.recentActivity.length === 0}
			<p class="text-sm text-[color:var(--muted-foreground)]">Sin cambios recientes en la ventana de 7 días.</p>
		{:else}
			<ul class="space-y-2 text-sm">
				{#each data.recentActivity as item}
					<li class="flex flex-wrap items-start justify-between gap-2 border-b border-[color:var(--border)] pb-2 last:border-b-0 last:pb-0">
						<div class="min-w-0">
							<button class="group text-left" onclick={() => openActivity(item)}>
								<span class="underline-offset-2 group-hover:underline">{item.obraTitulo}</span>
							</button>
							<p class="text-xs text-[color:var(--gray-500)]">{item.description}</p>
						</div>
						<span class="shrink-0 text-xs text-[color:var(--muted-foreground)]">{formatRelative(item.eventAt)}</span>
					</li>
				{/each}
			</ul>
		{/if}
	</div>
</section>

{#if !isAdminOrIp}
	<section class="mt-8">
		<h2 class="mb-3 text-xl font-semibold">Continuar edición</h2>
		<div class="grid gap-3 lg:grid-cols-2">
			{#if data.assignedEditorObras.length === 0}
				<div class="card p-4 text-sm text-[color:var(--muted-foreground)]">No tienes obras asignadas actualmente.</div>
			{:else}
				{#each data.assignedEditorObras as obra}
					<article class="card p-4">
						<div class="mb-2 flex items-start justify-between gap-2">
							<h3 class="text-lg font-semibold">{obra.titulo}</h3>
							<span class="border border-[color:var(--border)] bg-[color:var(--muted)] px-2 py-1 text-xs">{obra.estadoTerm}</span>
						</div>
						<p class="mb-3 text-xs text-[color:var(--muted-foreground)]">Última modificación: {formatRelative(obra.updatedAt)}</p>
						{#if obra.estadoTerm === 'borrador'}
							<Button class="w-full" onclick={() => goto(`/dashboard/obras/${obra.obraId}`)}>Continuar edición</Button>
						{:else}
							<p class="text-sm text-[color:var(--muted-foreground)]">
								Tu obra asignada ya no está en borrador. Estado actual: <strong>{obra.estadoTerm}</strong>
							</p>
							<div class="mt-3">
								<Button variant="secondary" class="w-full" onclick={() => goto(`/dashboard/obras/${obra.obraId}`)}>
									Abrir obra
								</Button>
							</div>
						{/if}
					</article>
				{/each}
			{/if}
		</div>
	</section>

	<section class="mt-8">
		<h2 class="mb-3 text-xl font-semibold">Obras publicadas asignadas a ti</h2>
		<div class="card p-4">
			<p class="text-sm">
				Total publicadas bajo tu asignación editorial:
				<strong>{data.publishedAssignedSummary.total}</strong>
			</p>
			{#if data.publishedAssignedSummary.items.length > 0}
				<ul class="mt-3 space-y-1 text-sm">
					{#each data.publishedAssignedSummary.items as item}
						<li>
							<button class="underline-offset-2 hover:underline" onclick={() => goto(`/dashboard/obras/${item.obraId}`)}>
								{item.titulo}
							</button>
							<span class="ml-2 text-xs text-[color:var(--muted-foreground)]">{formatRelative(item.updatedAt)}</span>
						</li>
					{/each}
				</ul>
			{/if}
		</div>
	</section>
{/if}
