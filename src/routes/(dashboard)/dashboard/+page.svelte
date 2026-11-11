<script lang="ts">
	import { invalidate } from '$app/navigation';
	import { onMount } from 'svelte';
	import { ArrowRight } from 'lucide-svelte';
	import ActivityList from '$lib/components/dashboard/ActivityList.svelte';
	import { formatRelative } from '$lib/utils/formatters';
	import type { PageData } from './$types';

	let { data } = $props<{ data: PageData }>();
	const assigned = $derived(data.assignedEditorObras.filter((obra) => obra.estadoTerm !== 'publicado'));
	const estados: Record<string, string> = {
		borrador: 'Borrador', vista_previa: 'Vista previa', listo_para_publicar: 'Lista para publicar'
	};

	onMount(() => {
		const refresh = () => void invalidate('dashboard:home');
		window.addEventListener('dashboard-obras-updated', refresh);
		return () => window.removeEventListener('dashboard-obras-updated', refresh);
	});
</script>

<section class="max-w-4xl space-y-7">
	<header>
		<h1 class="font-display text-3xl text-[color:var(--gray-900)]">Inicio</h1>
		<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">Hola, {data.profile.nombreCompleto}</p>
	</header>

	{#if data.overview}
		{@const summary = data.overview}
		<section>
			<div class="flex flex-wrap items-baseline justify-between gap-2">
				<h2 class="text-lg font-semibold">Obras</h2>
				<a class="text-sm underline underline-offset-2" href="/dashboard/obras?scope=all">Todas las obras</a>
			</div>
			<ul class="mt-3 grid grid-cols-1 gap-2 border-y border-[color:var(--border)] py-3 sm:grid-cols-3">
				{#each [
					{ tipo: 'sin_ficha', label: 'Sin ficha', count: summary.sinFicha },
					{ tipo: 'basica', label: 'Fichas básicas', count: summary.basicas },
					{ tipo: 'completa', label: 'Fichas completas', count: summary.completas }
				] as item (item.tipo)}
					<li>
						<a class="flex items-baseline gap-2 px-2 py-1 hover:bg-[color:var(--muted)]" href={`/dashboard/obras?scope=all&tipo=${item.tipo}`}>
							<span class="text-xl font-semibold tabular-nums">{item.count}</span>
							<span class="text-sm">{item.label}</span>
						</a>
					</li>
				{/each}
			</ul>
			<div class="mt-3 flex flex-wrap gap-x-5 gap-y-2 text-sm">
				<a class="underline underline-offset-2" href="/dashboard/obras?scope=all&editor=sin_asignar">Sin asignar ({summary.sinAsignar})</a>
				{#if summary.estadoListo}
					<a class="underline underline-offset-2" href={`/dashboard/obras?scope=all&estado=${summary.estadoListo}`}>Listas para publicar ({summary.listas})</a>
				{/if}
			</div>
		</section>

	{/if}

	{#if assigned.length || !data.overview}
		<section>
			<div class="flex flex-wrap items-baseline justify-between gap-2">
				<h2 class="text-lg font-semibold">Continuar edición</h2>
				<a class="text-sm underline underline-offset-2" href="/dashboard/obras?scope=mine">Mis obras</a>
			</div>
			{#if assigned.length}
				<ul class="mt-2 divide-y divide-[color:var(--border)]">
					{#each assigned.slice(0, 8) as obra (obra.obraId)}
						<li>
							<a class="flex flex-wrap items-center gap-x-3 gap-y-1 px-2 py-3 text-sm hover:bg-[color:var(--muted)]" href={`/dashboard/obras/${obra.obraId}`}>
								<span class="mr-auto">
									<span class="block font-medium">{obra.titulo}</span>
									{#if obra.updatedAt}<span class="text-xs text-[color:var(--muted-foreground)]">Última modificación {formatRelative(obra.updatedAt)}</span>{/if}
								</span>
								<span class="text-xs text-[color:var(--muted-foreground)]">{estados[obra.estadoTerm] ?? obra.estadoTerm}</span>
								<ArrowRight size={16} aria-hidden="true" />
							</a>
						</li>
					{/each}
				</ul>
			{:else}
				<p class="py-3 text-sm text-[color:var(--muted-foreground)]">No tienes obras pendientes de edición.</p>
			{/if}
		</section>
	{/if}

	{#if data.overview}
		<section>
			<div class="flex flex-wrap items-baseline justify-between gap-2">
				<h2 class="text-lg font-semibold">Últimos cambios</h2>
				<a class="text-sm underline underline-offset-2" href="/dashboard/notificaciones">Ver actividad reciente</a>
			</div>
			<ActivityList items={data.recentActivity} empty="Sin actividad en los últimos 7 días." />
		</section>
	{/if}

	{#if data.publishedAssignedSummary.total}
		<section>
			<h2 class="text-lg font-semibold">Mis obras publicadas ({data.publishedAssignedSummary.total})</h2>
			<ul class="mt-2 divide-y divide-[color:var(--border)] text-sm">
				{#each data.publishedAssignedSummary.items as obra (obra.obraId)}
					<li class="px-2 py-2">
						<a class="font-medium underline-offset-2 hover:underline" href={`/dashboard/obras/${obra.obraId}`}>{obra.titulo}</a>
					</li>
				{/each}
			</ul>
		</section>
	{/if}

	<nav aria-label="Recursos editoriales" class="flex flex-wrap gap-x-5 gap-y-2 border-t border-[color:var(--border)] pt-3 text-sm">
		<a class="underline underline-offset-2" href="/dashboard/guia">Guía editorial</a>
		{#if data.informesMigracion > 0}
			<a class="underline underline-offset-2" href="/dashboard/migracion">Informes de migración ({data.informesMigracion})</a>
		{/if}
	</nav>
</section>
