<script lang="ts">
	import { invalidate } from '$app/navigation';
	import { onMount } from 'svelte';
	import { ArrowRight } from 'lucide-svelte';
	import ActivityList from '$lib/components/dashboard/ActivityList.svelte';
	import DashboardLinkRow from '$lib/components/dashboard/DashboardLinkRow.svelte';
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

<section class="space-y-6">
	<header class="border-l-2 border-[color:var(--primary)] pl-4">
		<h1 class="font-display text-3xl text-[color:var(--gray-900)]">Inicio</h1>
		<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">Hola, {data.profile.nombreCompleto}</p>
	</header>

	{#if data.overview}
		<section class="bg-[color:var(--gray-900)] px-5 py-5 text-white sm:px-6">
			<div class="flex flex-wrap items-baseline justify-between gap-2">
				<h2 class="font-display text-2xl">Obras del proyecto</h2>
				<a class="inline-flex items-center gap-2 text-sm underline-offset-4 hover:underline" href="/dashboard/obras?scope=all">
					Todas las obras <ArrowRight size={16} aria-hidden="true" />
				</a>
			</div>
			<ul class="mt-4 grid gap-2 sm:grid-cols-3 sm:gap-4">
				{#each [
					{ tipo: 'sin_ficha', label: 'Sin ficha', count: data.overview.sinFicha },
					{ tipo: 'basica', label: 'Fichas básicas', count: data.overview.basicas },
					{ tipo: 'completa', label: 'Fichas completas', count: data.overview.completas }
				] as item (item.tipo)}
					<li>
						<a class="group flex items-center gap-3 border-t border-[color:var(--gray-700)] py-3 hover:bg-[color:var(--gray-800)] sm:flex-wrap"
							href={`/dashboard/obras?scope=all&tipo=${item.tipo}`}>
							<span class="font-display text-3xl tabular-nums">{item.count}</span>
							<span class="text-sm text-[color:var(--gray-300)]">{item.label}</span>
							<ArrowRight class="ml-auto shrink-0 transition-transform group-hover:translate-x-0.5" size={16} aria-hidden="true" />
						</a>
					</li>
				{/each}
			</ul>
		</section>
	{/if}

	<div class="grid items-start gap-6 lg:grid-cols-[minmax(0,3fr)_minmax(16rem,2fr)]">
		<div class="min-w-0 space-y-6">
			<section class="border border-[color:var(--border)] bg-white">
				<header class="flex flex-wrap items-baseline justify-between gap-2 border-b border-[color:var(--border)] px-4 py-3">
					<h2 class="font-display text-xl">Continuar edición</h2>
					<a class="text-sm underline underline-offset-2" href="/dashboard/obras?scope=mine">Mis obras</a>
				</header>
				{#if assigned.length}
					<ul class="divide-y divide-[color:var(--border)]">
						{#each assigned.slice(0, 8) as obra (obra.obraId)}
							<li>
								<DashboardLinkRow href={`/dashboard/obras/${obra.obraId}`}>
									<p class="font-medium">{obra.titulo}</p>
									{#if obra.updatedAt}<p class="text-xs text-[color:var(--muted-foreground)]">Última modificación {formatRelative(obra.updatedAt)}</p>{/if}
									{#snippet detail()}
										<span class="bg-[color:var(--muted)] px-2 py-1 text-xs text-[color:var(--gray-700)]">{estados[obra.estadoTerm] ?? obra.estadoTerm}</span>
									{/snippet}
								</DashboardLinkRow>
							</li>
						{/each}
					</ul>
				{:else}
					<p class="px-4 py-3 text-sm text-[color:var(--muted-foreground)]">No tienes obras pendientes de edición.</p>
				{/if}
			</section>

			{#if data.publishedAssignedSummary.total}
				<section>
					<header class="flex items-center gap-3 border-b border-[color:var(--border)] pb-2">
						<h2 class="font-display text-xl">Mis obras publicadas</h2>
						<span class="bg-[color:var(--muted)] px-2 py-1 text-xs font-semibold tabular-nums">{data.publishedAssignedSummary.total}</span>
					</header>
					<ul class="divide-y divide-[color:var(--border)] text-sm sm:grid sm:grid-cols-2 sm:gap-x-4 sm:divide-y-0">
						{#each data.publishedAssignedSummary.items as obra (obra.obraId)}
							<li class="sm:border-b sm:border-[color:var(--border)]">
								<DashboardLinkRow href={`/dashboard/obras/${obra.obraId}`}><span class="font-medium">{obra.titulo}</span></DashboardLinkRow>
							</li>
						{/each}
					</ul>
				</section>
			{/if}
		</div>

		<aside class="min-w-0 space-y-6">
			{#if data.overview}
				<section class="border-t-2 border-[color:var(--primary)] bg-[color:var(--gray-50)]">
					<h2 class="px-4 pt-3 font-display text-xl">Pendientes del proyecto</h2>
					<ul class="mt-2 divide-y divide-[color:var(--border)]">
						<li>
							<DashboardLinkRow href="/dashboard/obras?scope=all&editor=sin_asignar">
								<span class="font-medium">Obras sin asignar</span>
								{#snippet detail()}<span class="font-display text-xl tabular-nums">{data.overview.sinAsignar}</span>{/snippet}
							</DashboardLinkRow>
						</li>
						{#if data.overview.estadoListo}
							<li>
								<DashboardLinkRow href={`/dashboard/obras?scope=all&estado=${data.overview.estadoListo}`}>
									<span class="font-medium">Listas para publicar</span>
									{#snippet detail()}<span class="font-display text-xl tabular-nums">{data.overview.listas}</span>{/snippet}
								</DashboardLinkRow>
							</li>
						{/if}
					</ul>
				</section>

				<section>
					<header class="flex flex-wrap items-baseline justify-between gap-2 border-b border-[color:var(--border)] pb-2">
						<h2 class="font-display text-xl">Últimos cambios</h2>
						<a class="text-sm underline underline-offset-2" href="/dashboard/notificaciones">Ver actividad</a>
					</header>
					<ActivityList items={data.recentActivity} empty="Sin actividad en los últimos 7 días." />
				</section>
			{/if}

			<nav aria-label="Recursos editoriales" class="border border-[color:var(--border)] bg-white">
				<h2 class="border-b border-[color:var(--border)] px-4 py-3 font-display text-xl">Recursos editoriales</h2>
				<ul class="divide-y divide-[color:var(--border)]">
					<li><DashboardLinkRow href="/dashboard/guia">Guía editorial</DashboardLinkRow></li>
					{#if data.informesMigracion > 0}
						<li>
							<DashboardLinkRow href="/dashboard/migracion">
								Informes de migración
								{#snippet detail()}<span class="bg-[color:var(--muted)] px-2 py-1 text-xs font-semibold tabular-nums">{data.informesMigracion}</span>{/snippet}
							</DashboardLinkRow>
						</li>
					{/if}
				</ul>
			</nav>
		</aside>
	</div>
</section>
