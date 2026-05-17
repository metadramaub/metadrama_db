<script lang="ts">
	import { goto } from '$app/navigation';
	import Button from '$lib/components/ui/button.svelte';
	import { pushToast } from '$lib/stores/toast';
	import { formatRelative } from '$lib/utils/formatters';
	import type { PageData } from './$types';

	let { data } = $props<{ data: PageData }>();

	const isAdminOrIp = $derived(['admin', 'ip'].includes(data.profile.roleTerm));
	let markingSeen = $state(false);

	function openNotification(item: PageData['notifications'][number]) {
		void goto(item.targetUrl ?? `/dashboard/obras/${item.obraId}?tab=${item.tab}`);
	}

	async function markRecentAsSeen() {
		if (markingSeen) return;
		markingSeen = true;
		try {
			const response = await fetch('/api/dashboard/activity/mark-seen', {
				method: 'POST'
			});
			if (!response.ok) {
				const body = await response.json().catch(() => ({}));
				pushToast('error', body.message ?? 'No se pudo marcar la actividad como vista.');
				return;
			}
			pushToast('success', 'Actividad reciente marcada como vista.');
			window.dispatchEvent(new CustomEvent('dashboard-activity-seen'));
		} finally {
			markingSeen = false;
		}
	}
</script>

<section>
	<div class="mb-4 flex flex-wrap items-end justify-between gap-3">
		<div>
			<h1 class="font-display text-3xl">ACTIVIDAD RECIENTE</h1>
			<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
				Cambios de los últimos 7 días.
			</p>
		</div>
		<div class="flex flex-wrap gap-2">
			<Button variant="ghost" onclick={markRecentAsSeen} disabled={markingSeen}>Marcar actividad como vista</Button>
		</div>
	</div>
</section>

<section class="space-y-4">
	<article class="card p-4">
		<h2 class="mb-3 text-lg font-semibold">Obras asignadas para edición</h2>
		{#if data.groups.assignedEditor.length === 0}
			<p class="text-sm text-[color:var(--muted-foreground)]">Sin novedades.</p>
		{:else}
			<ul class="space-y-2 text-sm">
				{#each data.groups.assignedEditor as item}
					<li class="flex items-start justify-between gap-2 border-b border-[color:var(--border)] pb-2 last:border-b-0 last:pb-0">
						<div class="min-w-0">
							<button class="group text-left" onclick={() => openNotification(item)}>
								<span class="underline-offset-2 group-hover:underline">{item.obraTitulo}</span>
							</button>
							<p class="text-xs text-[color:var(--gray-500)]">{item.description}</p>
						</div>
						<span class="shrink-0 text-xs text-[color:var(--muted-foreground)]">{formatRelative(item.eventAt)}</span>
					</li>
				{/each}
			</ul>
		{/if}
	</article>

	<article class="card p-4">
		<h2 class="mb-3 text-lg font-semibold">Obras asignadas para revisión</h2>
		{#if data.groups.assignedReview.length === 0}
			<p class="text-sm text-[color:var(--muted-foreground)]">Sin novedades.</p>
		{:else}
			<ul class="space-y-2 text-sm">
				{#each data.groups.assignedReview as item}
					<li class="flex items-start justify-between gap-2 border-b border-[color:var(--border)] pb-2 last:border-b-0 last:pb-0">
						<div class="min-w-0">
							<button class="group text-left" onclick={() => openNotification(item)}>
								<span class="underline-offset-2 group-hover:underline">{item.obraTitulo}</span>
							</button>
							<p class="text-xs text-[color:var(--gray-500)]">{item.description}</p>
						</div>
						<span class="shrink-0 text-xs text-[color:var(--muted-foreground)]">{formatRelative(item.eventAt)}</span>
					</li>
				{/each}
			</ul>
		{/if}
	</article>

	<article class="card p-4">
		<h2 class="mb-3 text-lg font-semibold">Cambios de estado</h2>
		{#if data.groups.stateChanges.length === 0}
			<p class="text-sm text-[color:var(--muted-foreground)]">Sin novedades.</p>
		{:else}
			<ul class="space-y-2 text-sm">
				{#each data.groups.stateChanges as item}
					<li class="flex items-start justify-between gap-2 border-b border-[color:var(--border)] pb-2 last:border-b-0 last:pb-0">
						<div class="min-w-0">
							<button class="group text-left" onclick={() => openNotification(item)}>
								<span class="underline-offset-2 group-hover:underline">{item.obraTitulo}</span>
							</button>
							<p class="text-xs text-[color:var(--gray-500)]">{item.description}</p>
						</div>
						<span class="shrink-0 text-xs text-[color:var(--muted-foreground)]">{formatRelative(item.eventAt)}</span>
					</li>
				{/each}
			</ul>
		{/if}
	</article>

	<article class="card p-4">
		<h2 class="mb-3 text-lg font-semibold">Comentarios recientes</h2>
		{#if data.groups.comments.length === 0}
			<p class="text-sm text-[color:var(--muted-foreground)]">Sin novedades.</p>
		{:else}
			<ul class="space-y-2 text-sm">
				{#each data.groups.comments as item}
					<li class="flex items-start justify-between gap-2 border-b border-[color:var(--border)] pb-2 last:border-b-0 last:pb-0">
						<div class="min-w-0">
							<button class="group text-left" onclick={() => openNotification(item)}>
								<span class="underline-offset-2 group-hover:underline">{item.obraTitulo}</span>
							</button>
							<p class="text-xs text-[color:var(--gray-500)]">{item.description}</p>
						</div>
						<span class="shrink-0 text-xs text-[color:var(--muted-foreground)]">{formatRelative(item.eventAt)}</span>
					</li>
				{/each}
			</ul>
		{/if}
	</article>

	{#if isAdminOrIp}
		<article class="card p-4">
			<h2 class="mb-3 text-lg font-semibold">Secuencias con certeza baja/media</h2>
			{#if data.groups.lowMediumCertainty.length === 0}
				<p class="text-sm text-[color:var(--muted-foreground)]">Sin alertas.</p>
			{:else}
				<ul class="space-y-2 text-sm">
					{#each data.groups.lowMediumCertainty as item}
						<li class="flex items-start justify-between gap-2 border-b border-[color:var(--border)] pb-2 last:border-b-0 last:pb-0">
							<div class="min-w-0">
								<button class="group text-left" onclick={() => openNotification(item)}>
									<span class="underline-offset-2 group-hover:underline">{item.obraTitulo}</span>
								</button>
								<p class="text-xs text-[color:var(--gray-500)]">
									{item.description}
									{#if item.badgeCount}
										<span
											class="ml-2 inline-flex min-w-6 items-center justify-center rounded-full border border-[color:var(--primary)] bg-[color:var(--primary)] px-2 py-0.5 text-[10px] font-semibold leading-none text-[color:var(--primary-foreground)]"
										>
											{item.badgeCount}
										</span>
									{/if}
								</p>
							</div>
							<span class="shrink-0 text-xs text-[color:var(--muted-foreground)]">{formatRelative(item.eventAt)}</span>
						</li>
					{/each}
				</ul>
			{/if}
		</article>
	{/if}
</section>
