<script lang="ts">
	import { browser } from '$app/environment';
	import { page } from '$app/stores';
	import { onMount } from 'svelte';
	import type { RealtimeChannel } from '@supabase/supabase-js';
	import Sidebar from '$lib/components/dashboard/Sidebar.svelte';
	import Breadcrumb, { type BreadcrumbItem } from '$lib/components/ui/Breadcrumb.svelte';
	import type { LayoutData } from './$types';

	const SIDEBAR_COLLAPSED_STORAGE_KEY = 'dashboard-sidebar-collapsed';
	const INDICATORS_CACHE_TTL_MS = 30_000;

	let { data, children } = $props<{ data: LayoutData; children: () => unknown }>();

	let notificationsUnreadCount = $state(0);
	let refreshInFlight = false;
	let refreshTimer: ReturnType<typeof setTimeout> | null = null;
	let lastIndicatorsFetchAt = 0;
	let channel: RealtimeChannel | null = null;
	let sidebarCollapsed = $state(false);

	const breadcrumbs = $derived.by((): BreadcrumbItem[] => {
		const pathSegments = $page.url.pathname.split('/').filter(Boolean);
		const obraTitle = ($page.data as { obra?: { titulo?: string } } | undefined)?.obra?.titulo?.trim();
		const authorName = ($page.data as { autor?: { nombre_completo?: string } } | undefined)?.autor?.nombre_completo?.trim();
		const isObraDetailPath =
			pathSegments.length >= 3 && pathSegments[0] === 'dashboard' && pathSegments[1] === 'obras';
		const isAuthorDetailPath =
			pathSegments.length >= 3 && pathSegments[0] === 'dashboard' && pathSegments[1] === 'autores';

		return pathSegments.map((segment, index): BreadcrumbItem => {
			// href acumulativo hasta este segmento (el último lo deja sin href = activo).
			const href = '/' + pathSegments.slice(0, index + 1).join('/');
			if (isObraDetailPath && index === 2 && obraTitle) {
				return { label: obraTitle, preserveCase: true, href };
			}
			if (isAuthorDetailPath && index === 2 && authorName) {
				return { label: authorName, preserveCase: true, href };
			}
			return { label: segment.replaceAll('-', ' '), href };
		});
	});

	function readSidebarCollapsedPreference(): boolean | null {
		if (!browser) return null;

		try {
			const raw = window.localStorage.getItem(SIDEBAR_COLLAPSED_STORAGE_KEY);
			if (raw === 'true') return true;
			if (raw === 'false') return false;
		} catch (error) {
			console.error('No se pudo leer la preferencia del panel lateral', error);
		}

		return null;
	}

	function persistSidebarCollapsedPreference(nextValue: boolean) {
		sidebarCollapsed = nextValue;
		if (!browser) return;

		try {
			window.localStorage.setItem(SIDEBAR_COLLAPSED_STORAGE_KEY, nextValue ? 'true' : 'false');
		} catch (error) {
			console.error('No se pudo guardar la preferencia del panel lateral', error);
		}
	}

	function toggleSidebarCollapsed() {
		persistSidebarCollapsedPreference(!sidebarCollapsed);
	}

	async function refreshIndicators(options: { force?: boolean } = {}) {
		if (!browser || refreshInFlight) return;
		if (!options.force && Date.now() - lastIndicatorsFetchAt < INDICATORS_CACHE_TTL_MS) return;
		refreshInFlight = true;
		try {
			const response = await fetch('/api/dashboard/indicators');
			if (!response.ok) return;
			const payload = await response.json();
			notificationsUnreadCount = payload.notificationsUnreadCount ?? notificationsUnreadCount;
			lastIndicatorsFetchAt = Date.now();
		} finally {
			refreshInFlight = false;
		}
	}

	function scheduleIndicatorsRefresh(options: { force?: boolean } = { force: true }) {
		if (!browser) return;
		const force = options.force ?? true;
		if (refreshTimer) {
			clearTimeout(refreshTimer);
		}
		refreshTimer = setTimeout(() => {
			void refreshIndicators({ force });
		}, 400);
	}

	onMount(() => {
		if (!browser) return;
		let disposed = false;
		let cleanupChannel: (() => void) | null = null;

		const storedSidebarPreference = readSidebarCollapsedPreference();
		if (storedSidebarPreference !== null) {
			sidebarCollapsed = storedSidebarPreference;
		}

		const handleActivitySeen = () => {
			scheduleIndicatorsRefresh();
		};
		const handleObrasUpdated = () => {
			scheduleIndicatorsRefresh();
		};
		const handleRealtimeChange = () => {
			scheduleIndicatorsRefresh();
		};
		window.addEventListener('dashboard-activity-seen', handleActivitySeen);
		window.addEventListener('dashboard-notifications-seen', handleActivitySeen);
		window.addEventListener('dashboard-obras-updated', handleObrasUpdated);

		void (async () => {
			const { getSupabaseBrowserClient } = await import('$lib/services/supabase');
			if (disposed) return;

			const supabase = getSupabaseBrowserClient();
			channel = supabase
				.channel(`dashboard-indicators-${data.profile.userId}`)
				.on('postgres_changes', { event: '*', schema: 'public', table: 'obras' }, handleRealtimeChange)
				.on(
					'postgres_changes',
					{ event: '*', schema: 'public', table: 'obras_revisores' },
					handleRealtimeChange
				)
				.on(
					'postgres_changes',
					{ event: '*', schema: 'public', table: 'comentarios_internos' },
					handleRealtimeChange
				)
				.on(
					'postgres_changes',
					{ event: '*', schema: 'public', table: 'dashboard_activity_state' },
					handleRealtimeChange
				)
				.subscribe();
			cleanupChannel = () => {
				if (!channel) return;
				void supabase.removeChannel(channel);
				channel = null;
			};
			void refreshIndicators({ force: true });
		})();

		return () => {
			disposed = true;
			window.removeEventListener('dashboard-activity-seen', handleActivitySeen);
			window.removeEventListener('dashboard-notifications-seen', handleActivitySeen);
			window.removeEventListener('dashboard-obras-updated', handleObrasUpdated);
			if (refreshTimer) {
				clearTimeout(refreshTimer);
				refreshTimer = null;
			}
			cleanupChannel?.();
		};
	});
</script>

<div
	class={`grid min-h-screen grid-cols-1 md:h-screen md:overflow-hidden md:transition-[grid-template-columns] md:duration-200 ${
		sidebarCollapsed ? 'md:grid-cols-[5rem_1fr]' : 'md:grid-cols-[18rem_1fr]'
	}`}
>
	<Sidebar
		profile={data.profile}
		notificationsUnreadCount={notificationsUnreadCount}
		collapsed={sidebarCollapsed}
		onToggle={toggleSidebarCollapsed}
	/>
	<main class="min-w-0 bg-[color:var(--background)] p-6 md:h-screen md:overflow-y-auto">
		<div class="mb-4 pb-3">
			<Breadcrumb
				items={breadcrumbs.length === 0 ? [{ label: 'Dashboard', href: '/dashboard' }] : breadcrumbs}
			/>
		</div>
		{@render children()}
	</main>
</div>
