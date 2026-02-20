<script lang="ts">
	import { navigating } from '$app/stores';
	import { onDestroy, onMount } from 'svelte';
	import favicon from '$lib/assets/favicon.svg';
	import SceneLoader from '$lib/components/ui/scene-loader.svelte';
	import Toast from '$lib/components/ui/toast.svelte';
	import { endSceneLoad, startSceneLoad, type SceneLoadToken } from '$lib/stores/scene-loader';
	import '../app.css';

	let { children } = $props();

	const ACCESS_KEY = 'metadrama_preview_access';
	const ACCESS_PASSWORD = 'metadrama*ub';

	let unlocked = $state(false);
	let password = $state('');
	let accessError = $state('');
	let routeLoadingToken = $state<SceneLoadToken | null>(null);

	onMount(() => {
		unlocked = window.sessionStorage.getItem(ACCESS_KEY) === 'ok';
	});

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

	function submitAccess(event: SubmitEvent) {
		event.preventDefault();
		if (password === ACCESS_PASSWORD) {
			unlocked = true;
			accessError = '';
			password = '';
			window.sessionStorage.setItem(ACCESS_KEY, 'ok');
			return;
		}
		accessError = 'Contraseña incorrecta.';
	}
</script>

<svelte:head>
	<link rel="icon" href={favicon} />
	<link rel="preconnect" href="https://fonts.googleapis.com" />
	<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous" />
	<link
		href="https://fonts.googleapis.com/css2?family=Bona+Nova:wght@400;700&family=Inter:wght@400;500;600;700;800&display=swap"
		rel="stylesheet"
	/>
</svelte:head>

{@render children()}

{#if !unlocked}
	<div class="fixed inset-0 z-[100] flex items-center justify-center bg-[color:var(--gray-950)] p-4">
		<section class="w-full max-w-md border border-[color:var(--border)] bg-white p-6">
			<h1 class="font-display text-2xl text-[color:var(--gray-900)]">WEB EN CONSTRUCCIÓN</h1>
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">Introduce contraseña para continuar.</p>

			<form class="mt-5 space-y-3" onsubmit={submitAccess}>
				<label class="block text-sm">
					<span class="mb-1 block">Contraseña</span>
					<input
						type="password"
						bind:value={password}
						class="w-full border border-[color:var(--border)] bg-white px-3 py-2"
						autocomplete="off"
						required
					/>
				</label>
				{#if accessError}
					<p class="text-sm text-[color:var(--danger)]">{accessError}</p>
				{/if}
				<button
					type="submit"
					class="w-full border border-[color:var(--primary)] bg-[color:var(--primary)] px-3 py-2 text-sm font-semibold text-[color:var(--primary-foreground)]"
				>
					Entrar
				</button>
			</form>
		</section>
	</div>
{/if}

<SceneLoader />
<Toast />
