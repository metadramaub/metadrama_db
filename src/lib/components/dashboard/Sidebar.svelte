<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { getSupabaseBrowserClient } from '$lib/services/supabase';
	import Button from '$lib/components/ui/button.svelte';
	import type { EditorProfile } from '$lib/types/obra.types';

	const props = $props<{
		profile: EditorProfile;
		notificationsUnreadCount?: number;
	}>();

	type IconComponent = any;

	let loggingOut = $state(false);
	let icons = $state<{
		arrowLeft: IconComponent | null;
		bell: IconComponent | null;
		bookOpenText: IconComponent | null;
		doorOpen: IconComponent | null;
		home: IconComponent | null;
		libraryBig: IconComponent | null;
		userRound: IconComponent | null;
	}>({
		arrowLeft: null,
		bell: null,
		bookOpenText: null,
		doorOpen: null,
		home: null,
		libraryBig: null,
		userRound: null
	});
	let iconsLoadFailed = $state(false);
	const ArrowLeftIcon = $derived(icons.arrowLeft);
	const BellIcon = $derived(icons.bell);
	const BookOpenTextIcon = $derived(icons.bookOpenText);
	const DoorOpenIcon = $derived(icons.doorOpen);
	const HomeIcon = $derived(icons.home);
	const LibraryBigIcon = $derived(icons.libraryBig);
	const UserRoundIcon = $derived(icons.userRound);

	onMount(() => {
		let cancelled = false;

		void (async () => {
			try {
				const [
					arrowLeftModule,
					bellModule,
					bookOpenTextModule,
					doorOpenModule,
					homeModule,
					libraryBigModule,
					userRoundModule
				] = await Promise.all([
					import('lucide-svelte/icons/arrow-left'),
					import('lucide-svelte/icons/bell'),
					import('lucide-svelte/icons/book-open-text'),
					import('lucide-svelte/icons/door-open'),
					import('lucide-svelte/icons/home'),
					import('lucide-svelte/icons/library-big'),
					import('lucide-svelte/icons/user-round')
				]);

				if (cancelled) return;

				icons = {
					arrowLeft: arrowLeftModule.default,
					bell: bellModule.default,
					bookOpenText: bookOpenTextModule.default,
					doorOpen: doorOpenModule.default,
					home: homeModule.default,
					libraryBig: libraryBigModule.default,
					userRound: userRoundModule.default
				};
			} catch (error) {
				if (cancelled) return;
				iconsLoadFailed = true;
				console.error('No se pudieron cargar los iconos del sidebar', error);
			}
		})();

		return () => {
			cancelled = true;
		};
	});

	async function onLogout() {
		loggingOut = true;
		const supabase = getSupabaseBrowserClient();
		await supabase.auth.signOut();
		await goto('/login');
		loggingOut = false;
	}
</script>

<aside
	class="flex h-full w-full flex-col border-b border-[color:var(--border)] bg-white p-4 md:h-screen md:w-72 md:overflow-hidden md:border-b-0 md:border-r"
>
	<div>
		<div class="mb-1 text-xs uppercase tracking-[0.08em] text-[color:var(--muted-foreground)]">METADRAMA</div>
		<h1 class="font-display text-2xl text-[color:var(--foreground)]">DASHBOARD</h1>
	</div>

	<div class="mt-4 border border-[color:var(--border)] bg-[color:var(--muted)] p-3">
		<div class="font-medium">{props.profile.nombreCompleto}</div>
		<div class="text-sm text-[color:var(--muted-foreground)]">Rol: {props.profile.roleTerm}</div>
	</div>

	<nav class="mt-6 flex flex-1 flex-col gap-2 text-sm">
		<a
			class="flex items-center gap-2 border border-[color:var(--border)] px-3 py-2 hover:bg-[color:var(--muted)]"
			href="/dashboard"
		>
			{#if HomeIcon}
				<HomeIcon size={16} aria-hidden="true" />
			{:else}
				<span class="inline-block h-4 w-4 shrink-0" aria-hidden="true"></span>
			{/if}
			Inicio
		</a>
		<a
			class="flex items-center gap-2 border border-[color:var(--border)] px-3 py-2 hover:bg-[color:var(--muted)]"
			href="/dashboard/notificaciones"
		>
			{#if BellIcon}
				<BellIcon size={16} aria-hidden="true" />
			{:else}
				<span class="inline-block h-4 w-4 shrink-0" aria-hidden="true"></span>
			{/if}
			Actividad reciente
			<span
				class="ml-auto border border-[color:var(--primary)] bg-[color:var(--primary)] px-2 py-0.5 text-xs text-[color:var(--primary-foreground)]"
			>
				{props.notificationsUnreadCount ?? 0}
			</span>
		</a>
		<a
			class="flex items-center gap-2 border border-[color:var(--border)] px-3 py-2 hover:bg-[color:var(--muted)]"
			href="/dashboard/obras?scope=mine"
		>
			{#if BookOpenTextIcon}
				<BookOpenTextIcon size={16} aria-hidden="true" />
			{:else}
				<span class="inline-block h-4 w-4 shrink-0" aria-hidden="true"></span>
			{/if}
			Obras
		</a>
		<a
			class="flex items-center gap-2 border border-[color:var(--border)] px-3 py-2 hover:bg-[color:var(--muted)]"
			href="/dashboard/autores"
		>
			{#if UserRoundIcon}
				<UserRoundIcon size={16} aria-hidden="true" />
			{:else}
				<span class="inline-block h-4 w-4 shrink-0" aria-hidden="true"></span>
			{/if}
			Autores
		</a>
		<a
			class="flex items-center gap-2 border border-[color:var(--border)] px-3 py-2 hover:bg-[color:var(--muted)]"
			href="/dashboard/vocabularios"
		>
			{#if LibraryBigIcon}
				<LibraryBigIcon size={16} aria-hidden="true" />
			{:else}
				<span class="inline-block h-4 w-4 shrink-0" aria-hidden="true"></span>
			{/if}
			Vocabularios
		</a>
	</nav>

	<div class="mt-4 border-t border-[color:var(--border)] pt-4">
		<Button variant="ghost" class="mb-2 w-full justify-start gap-2" onclick={() => goto('/')}>
			{#if ArrowLeftIcon}
				<ArrowLeftIcon size={16} aria-hidden="true" />
			{:else}
				<span class="inline-block h-4 w-4 shrink-0" aria-hidden="true"></span>
			{/if}
			Volver a la web
		</Button>
		<Button variant="ghost" class="w-full justify-start gap-2" onclick={onLogout} disabled={loggingOut}>
			{#if DoorOpenIcon}
				<DoorOpenIcon size={16} aria-hidden="true" />
			{:else}
				<span class="inline-block h-4 w-4 shrink-0" aria-hidden="true"></span>
			{/if}
			Cerrar sesión
		</Button>
		{#if iconsLoadFailed}
			<p class="mt-2 text-xs text-[color:var(--muted-foreground)]">Iconos no disponibles temporalmente.</p>
		{/if}
	</div>
</aside>
