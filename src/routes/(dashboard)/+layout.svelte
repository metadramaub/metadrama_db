<script lang="ts">
	import { browser } from '$app/environment';
	import { page } from '$app/stores';
	import { onMount } from 'svelte';
	import type { RealtimeChannel } from '@supabase/supabase-js';
	import Sidebar from '$lib/components/dashboard/Sidebar.svelte';
	import { getSupabaseBrowserClient } from '$lib/services/supabase';
	import type { LayoutData } from './$types';

	let { data, children } = $props<{ data: LayoutData; children: () => unknown }>();

	let notificationsUnreadCount = $state(0);
	let refreshInFlight = false;
	let refreshTimer: ReturnType<typeof setTimeout> | null = null;
	let channel: RealtimeChannel | null = null;

	type BreadcrumbSegment = {
		label: string;
		preserveCase?: boolean;
	};

	const breadcrumbs = $derived.by(() => {
		const pathSegments = $page.url.pathname.split('/').filter(Boolean);
		const obraTitle = ($page.data as { obra?: { titulo?: string } } | undefined)?.obra?.titulo?.trim();
		const authorName = ($page.data as { autor?: { nombre_completo?: string } } | undefined)?.autor?.nombre_completo?.trim();
		const isObraDetailPath =
			pathSegments.length >= 3 && pathSegments[0] === 'dashboard' && pathSegments[1] === 'obras';
		const isAuthorDetailPath =
			pathSegments.length >= 3 && pathSegments[0] === 'dashboard' && pathSegments[1] === 'autores';

		return pathSegments.map((segment, index) => {
			if (isObraDetailPath && index === 2 && obraTitle) {
				return { label: obraTitle, preserveCase: true };
			}
			if (isAuthorDetailPath && index === 2 && authorName) {
				return { label: authorName, preserveCase: true };
			}
			return { label: segment.replaceAll('-', ' ') };
		}) as BreadcrumbSegment[];
	});

	$effect(() => {
		notificationsUnreadCount = data.notificationsUnreadCount ?? 0;
	});

	async function refreshIndicators() {
		if (!browser || refreshInFlight) return;
		refreshInFlight = true;
		try {
			const response = await fetch('/api/dashboard/indicators');
			if (!response.ok) return;
			const payload = await response.json();
			notificationsUnreadCount = payload.notificationsUnreadCount ?? notificationsUnreadCount;
		} finally {
			refreshInFlight = false;
		}
	}

	function scheduleIndicatorsRefresh() {
		if (!browser) return;
		if (refreshTimer) {
			clearTimeout(refreshTimer);
		}
		refreshTimer = setTimeout(() => {
			void refreshIndicators();
		}, 400);
	}

	onMount(() => {
		if (!browser) return;

		const handleActivitySeen = () => {
			scheduleIndicatorsRefresh();
		};
		const handleObrasUpdated = () => {
			scheduleIndicatorsRefresh();
		};
		window.addEventListener('dashboard-activity-seen', handleActivitySeen);
		window.addEventListener('dashboard-notifications-seen', handleActivitySeen);
		window.addEventListener('dashboard-obras-updated', handleObrasUpdated);

		const supabase = getSupabaseBrowserClient();
		channel = supabase
			.channel(`dashboard-indicators-${data.profile.userId}`)
			.on('postgres_changes', { event: '*', schema: 'public', table: 'obras' }, scheduleIndicatorsRefresh)
			.on(
				'postgres_changes',
				{ event: '*', schema: 'public', table: 'obras_revisores' },
				scheduleIndicatorsRefresh
			)
			.on(
				'postgres_changes',
				{ event: '*', schema: 'public', table: 'comentarios_internos' },
				scheduleIndicatorsRefresh
			)
			.on(
				'postgres_changes',
				{ event: '*', schema: 'public', table: 'secuencias_metricas' },
				scheduleIndicatorsRefresh
			)
			.on(
				'postgres_changes',
				{ event: '*', schema: 'public', table: 'dashboard_activity_state' },
				scheduleIndicatorsRefresh
			)
			.subscribe();
		void refreshIndicators();

		return () => {
			window.removeEventListener('dashboard-activity-seen', handleActivitySeen);
			window.removeEventListener('dashboard-notifications-seen', handleActivitySeen);
			window.removeEventListener('dashboard-obras-updated', handleObrasUpdated);
			if (refreshTimer) {
				clearTimeout(refreshTimer);
				refreshTimer = null;
			}
			if (channel) {
				void supabase.removeChannel(channel);
				channel = null;
			}
		};
	});
</script>

<div class="grid min-h-screen md:h-screen md:grid-cols-[18rem_1fr] md:overflow-hidden">
	<Sidebar profile={data.profile} notificationsUnreadCount={notificationsUnreadCount} />
	<main class="min-w-0 bg-[color:var(--background)] p-6 md:h-screen md:overflow-y-auto">
		<div class="mb-4 border-b border-[color:var(--border)] pb-3 text-xs font-semibold tracking-[0.08em] text-[color:var(--muted-foreground)]">
			{#if breadcrumbs.length === 0}
				DASHBOARD
			{:else}
				{breadcrumbs
					.map((segment) => (segment.preserveCase ? segment.label : segment.label.toUpperCase()))
					.join(' / ')}
			{/if}
		</div>
		{@render children()}
	</main>
</div>
