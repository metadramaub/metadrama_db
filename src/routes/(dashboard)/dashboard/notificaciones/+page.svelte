<script lang="ts">
	import ActivityList from '$lib/components/dashboard/ActivityList.svelte';
	import Button from '$lib/components/ui/button.svelte';
	import SegmentedChoice from '$lib/components/ui/segmented-choice.svelte';
	import { pushToast } from '$lib/stores/toast';
	import type { PageData } from './$types';

	let { data } = $props<{ data: PageData }>();
	let markingSeen = $state(false);
	let filter = $state('all');
	const options = [
		{ id: 'all', label: 'Toda' },
		{ id: 'assignments', label: 'Asignaciones' },
		{ id: 'state_change', label: 'Cambios de estado' },
		{ id: 'comment', label: 'Comentarios' }
	];

	const items = $derived(data.notifications.filter((item) =>
		filter === 'all' || item.type === filter ||
		(filter === 'assignments' && (item.type === 'assigned_editor' || item.type === 'assigned_review'))
	));

	async function markRecentAsSeen() {
		if (markingSeen) return;
		markingSeen = true;
		try {
			const response = await fetch('/api/dashboard/activity/mark-seen', { method: 'POST' });
			if (!response.ok) {
				const body = await response.json().catch(() => ({}));
				pushToast('error', body.message ?? 'No se pudo marcar la actividad como vista.');
				return;
			}
			pushToast('success', 'Actividad reciente marcada como vista.');
			window.dispatchEvent(new CustomEvent('dashboard-activity-seen'));
		} catch {
			pushToast('error', 'No se pudo marcar la actividad como vista.');
		} finally {
			markingSeen = false;
		}
	}
</script>

<section class="max-w-4xl space-y-4">
	<header class="flex flex-wrap items-center justify-between gap-3">
		<div>
			<h1 class="font-display text-3xl text-[color:var(--gray-900)]">Actividad reciente</h1>
			<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">Últimos 7 días.</p>
		</div>
		{#if data.notifications.length}
			<Button variant="ghost" onclick={markRecentAsSeen} loading={markingSeen}>Marcar actividad como vista</Button>
		{/if}
	</header>

	{#if data.notifications.length}
		<SegmentedChoice items={options} value={filter} tone="neutral" ariaLabel="Tipo de actividad"
			onChange={(id) => (filter = id ?? 'all')} />
	{/if}

	<ActivityList {items} empty={filter === 'all' ? 'Sin actividad en los últimos 7 días.' : 'Sin actividad de este tipo.'} />
</section>