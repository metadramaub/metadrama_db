<script lang="ts">
	import { dev } from '$app/environment';
	import { navigating } from '$app/stores';
	import { onDestroy } from 'svelte';
	import SceneLoader from '$lib/components/ui/scene-loader.svelte';
	import Toast from '$lib/components/ui/toast.svelte';
	import { endSceneLoad, startSceneLoad, type SceneLoadToken } from '$lib/stores/scene-loader';
	import { injectAnalytics } from '@vercel/analytics/sveltekit';
	import '../app.css';

	injectAnalytics({ mode: dev ? 'development' : 'production' });

	let { children } = $props();

	let routeLoadingToken = $state<SceneLoadToken | null>(null);

	$effect(() => {
		const activeNavigation = $navigating;

		if (activeNavigation && routeLoadingToken === null) {
			routeLoadingToken = startSceneLoad('route', { delayMs: 150 });
			return;
		}

		if (!activeNavigation && routeLoadingToken !== null) {
			endSceneLoad(routeLoadingToken);
			routeLoadingToken = null;
		}
	});

	onDestroy(() => {
		if (routeLoadingToken === null) return;
		endSceneLoad(routeLoadingToken);
		routeLoadingToken = null;
	});
</script>

<svelte:head>
	<link rel="icon" href="/favicon.svg" type="image/svg+xml" />
	<link rel="preconnect" href="https://fonts.googleapis.com" />
	<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous" />
	<link
		href="https://fonts.googleapis.com/css2?family=Bona+Nova:wght@400;700&family=Inter:wght@400;500;600;700;800&display=swap"
		rel="stylesheet"
	/>
</svelte:head>

{@render children()}

<SceneLoader />
<Toast />
