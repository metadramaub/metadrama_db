<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import type { EditorProfile } from '$lib/types/obra.types';

	const props = $props<{
		profile: EditorProfile;
		notificationsUnreadCount?: number;
		collapsed?: boolean;
		onToggle?: () => void;
	}>();

	type IconComponent = any;

	let loggingOut = $state(false);
	let icons = $state<{
		arrowLeft: IconComponent | null;
		bell: IconComponent | null;
		bookOpenText: IconComponent | null;
		circleHelp: IconComponent | null;
		doorOpen: IconComponent | null;
		home: IconComponent | null;
		libraryBig: IconComponent | null;
		listChecks: IconComponent | null;
		panelLeftClose: IconComponent | null;
		panelLeftOpen: IconComponent | null;
		settings: IconComponent | null;
		userRound: IconComponent | null;
	}>({
		arrowLeft: null,
		bell: null,
		bookOpenText: null,
		circleHelp: null,
		doorOpen: null,
		home: null,
		libraryBig: null,
		listChecks: null,
		panelLeftClose: null,
		panelLeftOpen: null,
		settings: null,
		userRound: null
	});
	let iconsLoadFailed = $state(false);

	const collapsed = $derived(Boolean(props.collapsed));
	const unreadCount = $derived(props.notificationsUnreadCount ?? 0);
	const compactUnreadCountLabel = $derived((props.notificationsUnreadCount ?? 0) > 99 ? '99+' : String(props.notificationsUnreadCount ?? 0));
	const ArrowLeftIcon = $derived(icons.arrowLeft);
	const BellIcon = $derived(icons.bell);
	const BookOpenTextIcon = $derived(icons.bookOpenText);
	const CircleHelpIcon = $derived(icons.circleHelp);
	const DoorOpenIcon = $derived(icons.doorOpen);
	const HomeIcon = $derived(icons.home);
	const LibraryBigIcon = $derived(icons.libraryBig);
	const ListChecksIcon = $derived(icons.listChecks);
	const PanelLeftCloseIcon = $derived(icons.panelLeftClose);
	const PanelLeftOpenIcon = $derived(icons.panelLeftOpen);
	const SettingsIcon = $derived(icons.settings);
	const UserRoundIcon = $derived(icons.userRound);

	const isAdminIp = $derived(
		props.profile.roleTerm === 'admin' || props.profile.roleTerm === 'ip'
	);

	onMount(() => {
		let cancelled = false;

		void (async () => {
			try {
				const [
					arrowLeftModule,
					bellModule,
					bookOpenTextModule,
					circleHelpModule,
					doorOpenModule,
					homeModule,
					libraryBigModule,
					listChecksModule,
					panelLeftCloseModule,
					panelLeftOpenModule,
					settingsModule,
					userRoundModule
				] = await Promise.all([
					import('lucide-svelte/icons/arrow-left'),
					import('lucide-svelte/icons/bell'),
					import('lucide-svelte/icons/book-open-text'),
					import('lucide-svelte/icons/circle-help'),
					import('lucide-svelte/icons/door-open'),
					import('lucide-svelte/icons/home'),
					import('lucide-svelte/icons/library-big'),
					import('lucide-svelte/icons/list-checks'),
					import('lucide-svelte/icons/panel-left-close'),
					import('lucide-svelte/icons/panel-left-open'),
					import('lucide-svelte/icons/settings'),
					import('lucide-svelte/icons/user-round')
				]);

				if (cancelled) return;

				icons = {
					arrowLeft: arrowLeftModule.default,
					bell: bellModule.default,
					bookOpenText: bookOpenTextModule.default,
					circleHelp: circleHelpModule.default,
					doorOpen: doorOpenModule.default,
					home: homeModule.default,
					libraryBig: libraryBigModule.default,
					listChecks: listChecksModule.default,
					panelLeftClose: panelLeftCloseModule.default,
					panelLeftOpen: panelLeftOpenModule.default,
					settings: settingsModule.default,
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
		const { getSupabaseBrowserClient } = await import('$lib/services/supabase');
		const supabase = getSupabaseBrowserClient();
		await supabase.auth.signOut();
		await goto('/login');
		loggingOut = false;
	}
</script>

<aside
	class={`flex h-full w-full flex-col border-b border-[color:var(--border)] bg-white p-4 md:h-screen md:w-full md:overflow-x-visible md:overflow-y-auto md:border-b-0 md:border-r md:transition-[padding] md:duration-200 ${
		collapsed ? 'md:items-center md:px-2' : 'md:items-stretch md:px-4'
	}`}
>
	<div class={`flex w-full items-center justify-between gap-3 ${collapsed ? 'md:justify-center' : ''}`}>
		<div class={collapsed ? 'md:hidden' : ''}>
			<div class="mb-1 text-xs uppercase tracking-[0.08em] text-[color:var(--muted-foreground)]">
				VERSOLOGÍA
			</div>
			<h1 class="font-display text-2xl text-[color:var(--foreground)]">DASHBOARD</h1>
		</div>

		<button
			type="button"
			class="hidden h-10 w-10 shrink-0 items-center justify-center bg-transparent text-[color:var(--muted-foreground)] transition-colors hover:bg-[color:var(--muted)] hover:text-[color:var(--foreground)] md:inline-flex"
			aria-label={collapsed ? 'Expandir panel lateral' : 'Colapsar panel lateral'}
			aria-expanded={!collapsed}
			aria-controls="dashboard-sidebar-nav"
			title={collapsed ? 'Expandir panel lateral' : 'Colapsar panel lateral'}
			onclick={() => props.onToggle?.()}
		>
			{#if collapsed && PanelLeftOpenIcon}
				<PanelLeftOpenIcon size={18} aria-hidden="true" />
			{:else if !collapsed && PanelLeftCloseIcon}
				<PanelLeftCloseIcon size={18} aria-hidden="true" />
			{:else if ArrowLeftIcon}
				<ArrowLeftIcon size={18} aria-hidden="true" class={collapsed ? 'rotate-180' : ''} />
			{:else}
				<span class="inline-block h-4 w-4 shrink-0" aria-hidden="true"></span>
			{/if}
		</button>
	</div>

	<div
		class={`mt-4 w-full border border-[color:var(--border)] bg-[color:var(--muted)] p-3 ${
			collapsed ? 'md:hidden' : ''
		}`}
	>
		<div class="font-medium">{props.profile.nombreCompleto}</div>
		<div class="text-sm text-[color:var(--muted-foreground)]">Rol: {props.profile.roleTerm}</div>
	</div>

	<nav id="dashboard-sidebar-nav" class="mt-6 flex min-h-0 w-full flex-1 flex-col gap-2 text-sm">
		<a
			class={`flex items-center gap-2 px-3 py-2 text-[color:var(--foreground)] transition-colors hover:bg-[color:var(--muted)] ${
				collapsed ? 'md:h-11 md:w-11 md:self-center md:justify-center md:px-0' : ''
			}`}
			href="/dashboard"
			aria-label="Inicio"
			title="Inicio"
		>
			{#if HomeIcon}
				<HomeIcon size={16} aria-hidden="true" />
			{:else}
				<span class="inline-block h-4 w-4 shrink-0" aria-hidden="true"></span>
			{/if}
			<span class={collapsed ? 'md:sr-only' : ''}>Inicio</span>
		</a>

		<a
			class={`relative flex items-center gap-2 px-3 py-2 text-[color:var(--foreground)] transition-colors hover:bg-[color:var(--muted)] ${
				collapsed ? 'md:h-11 md:w-11 md:self-center md:justify-center md:px-0' : ''
			}`}
			href="/dashboard/notificaciones"
			aria-label="Actividad reciente"
			title="Actividad reciente"
		>
			<span class="relative inline-flex h-4 w-4 shrink-0 items-center justify-center">
				{#if BellIcon}
					<BellIcon size={16} aria-hidden="true" />
				{:else}
					<span class="inline-block h-4 w-4 shrink-0" aria-hidden="true"></span>
				{/if}
			</span>
			{#if collapsed}
				<span
					class="absolute right-1 top-1 hidden min-w-[1.1rem] items-center justify-center border border-[color:var(--primary)] bg-[color:var(--primary)] px-1 py-0 text-[10px] leading-none text-[color:var(--primary-foreground)] md:inline-flex"
				>
					{compactUnreadCountLabel}
				</span>
			{/if}
			<span class={collapsed ? 'md:sr-only' : ''}>Actividad reciente</span>
			<span
				class={`ml-auto border border-[color:var(--primary)] bg-[color:var(--primary)] px-2 py-0.5 text-xs text-[color:var(--primary-foreground)] ${
					collapsed ? 'md:hidden' : ''
				}`}
			>
				{unreadCount}
			</span>
		</a>

		<a
			class={`flex items-center gap-2 px-3 py-2 text-[color:var(--foreground)] transition-colors hover:bg-[color:var(--muted)] ${
				collapsed ? 'md:h-11 md:w-11 md:self-center md:justify-center md:px-0' : ''
			}`}
			href="/dashboard/obras"
			aria-label="Obras"
			title="Obras"
		>
			{#if BookOpenTextIcon}
				<BookOpenTextIcon size={16} aria-hidden="true" />
			{:else}
				<span class="inline-block h-4 w-4 shrink-0" aria-hidden="true"></span>
			{/if}
			<span class={collapsed ? 'md:sr-only' : ''}>Obras</span>
		</a>

		<a
			class={`flex items-center gap-2 px-3 py-2 text-[color:var(--foreground)] transition-colors hover:bg-[color:var(--muted)] ${
				collapsed ? 'md:h-11 md:w-11 md:self-center md:justify-center md:px-0' : ''
			}`}
			href="/dashboard/autores"
			aria-label="Autores"
			title="Autores"
		>
			{#if UserRoundIcon}
				<UserRoundIcon size={16} aria-hidden="true" />
			{:else}
				<span class="inline-block h-4 w-4 shrink-0" aria-hidden="true"></span>
			{/if}
			<span class={collapsed ? 'md:sr-only' : ''}>Autores</span>
		</a>

		<a
			class={`flex items-center gap-2 px-3 py-2 text-[color:var(--foreground)] transition-colors hover:bg-[color:var(--muted)] ${
				collapsed ? 'md:h-11 md:w-11 md:self-center md:justify-center md:px-0' : ''
			}`}
			href="/dashboard/vocabularios"
			aria-label="Vocabularios"
			title="Vocabularios"
		>
			{#if LibraryBigIcon}
				<LibraryBigIcon size={16} aria-hidden="true" />
			{:else}
				<span class="inline-block h-4 w-4 shrink-0" aria-hidden="true"></span>
			{/if}
			<span class={collapsed ? 'md:sr-only' : ''}>Vocabularios</span>
		</a>

		{#if isAdminIp}
			<a
				class={`flex items-center gap-2 px-3 py-2 text-[color:var(--foreground)] transition-colors hover:bg-[color:var(--muted)] ${
					collapsed ? 'md:h-11 md:w-11 md:self-center md:justify-center md:px-0' : ''
				}`}
				href="/dashboard/demarcador"
				aria-label="Auditor del demarcador"
				title="Auditor del demarcador"
			>
				{#if ListChecksIcon}
					<ListChecksIcon size={16} aria-hidden="true" />
				{:else}
					<span class="inline-block h-4 w-4 shrink-0" aria-hidden="true"></span>
				{/if}
				<span class={collapsed ? 'md:sr-only' : ''}>Demarcador</span>
			</a>

			<a
				class={`flex items-center gap-2 px-3 py-2 text-[color:var(--foreground)] transition-colors hover:bg-[color:var(--muted)] ${
					collapsed ? 'md:h-11 md:w-11 md:self-center md:justify-center md:px-0' : ''
				}`}
				href="/dashboard/publicacion"
				aria-label="Publicación"
				title="Publicación"
			>
				{#if SettingsIcon}
					<SettingsIcon size={16} aria-hidden="true" />
				{:else}
					<span class="inline-block h-4 w-4 shrink-0" aria-hidden="true"></span>
				{/if}
				<span class={collapsed ? 'md:sr-only' : ''}>Publicación</span>
			</a>
		{/if}

		<a
			class={`flex items-center gap-2 px-3 py-2 text-[color:var(--foreground)] transition-colors hover:bg-[color:var(--muted)] ${
				collapsed ? 'md:h-11 md:w-11 md:self-center md:justify-center md:px-0' : ''
			}`}
			href="/dashboard/guia"
			aria-label="Guia de uso"
			title="Guia de uso"
		>
			{#if CircleHelpIcon}
				<CircleHelpIcon size={16} aria-hidden="true" />
			{:else}
				<span class="inline-block h-4 w-4 shrink-0" aria-hidden="true"></span>
			{/if}
			<span class={collapsed ? 'md:sr-only' : ''}>Guia de uso</span>
		</a>
	</nav>

	<div class="mt-4 flex w-full flex-col border-t border-[color:var(--border)] pt-4">
		<a
			class={`flex w-full items-center gap-2 bg-transparent px-3 py-2 text-[color:var(--foreground)] transition-colors hover:bg-[color:var(--muted)] ${
				collapsed ? 'md:h-11 md:w-11 md:self-center md:justify-center md:px-0' : 'justify-start'
			}`}
			href="/"
			aria-label="Volver a la web"
			title="Volver a la web"
		>
			{#if ArrowLeftIcon}
				<ArrowLeftIcon size={16} aria-hidden="true" />
			{:else}
				<span class="inline-block h-4 w-4 shrink-0" aria-hidden="true"></span>
			{/if}
			<span class={collapsed ? 'md:sr-only' : ''}>Volver a la web</span>
		</a>

		<button
			type="button"
			class={`mt-2 flex w-full items-center gap-2 bg-transparent px-3 py-2 text-[color:var(--foreground)] transition-colors hover:bg-[color:var(--muted)] disabled:cursor-not-allowed disabled:opacity-50 ${
				collapsed ? 'md:h-11 md:w-11 md:self-center md:justify-center md:px-0' : 'justify-start'
			}`}
			onclick={onLogout}
			disabled={loggingOut}
			aria-label="Cerrar sesion"
			title="Cerrar sesion"
		>
			{#if DoorOpenIcon}
				<DoorOpenIcon size={16} aria-hidden="true" />
			{:else}
				<span class="inline-block h-4 w-4 shrink-0" aria-hidden="true"></span>
			{/if}
			<span class={collapsed ? 'md:sr-only' : ''}>Cerrar sesion</span>
		</button>

		{#if iconsLoadFailed}
			<p class={`mt-2 text-xs text-[color:var(--muted-foreground)] ${collapsed ? 'md:hidden' : ''}`}>
				Iconos no disponibles temporalmente.
			</p>
		{/if}
	</div>
</aside>
