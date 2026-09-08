<script lang="ts">
	import { invalidateAll } from '$app/navigation';
	import { page } from '$app/stores';
	import DoorOpenIcon from 'lucide-svelte/icons/door-open';
	import { FOOTER_SECTIONS, PUBLIC_NAV } from '$lib/config/navigation';
	import type { NavGroup, NavItem } from '$lib/config/navigation';
	import { isSectionVisible } from '$lib/secciones-publicas';
	import type { SectionVisibilityMap } from '$lib/secciones-publicas';
	import type { User } from '@supabase/supabase-js';

	let { children, data } = $props<{
		children: unknown;
		data: { sectionVisibility?: SectionVisibilityMap; user?: User | null };
	}>();
	let mobileOpen = $state(false);
	let resourcesOpen = $state(false);
	let projectOpen = $state(false);
	let loggingOut = $state(false);
	let logoutConfirmOpen = $state(false);

	const pathname = $derived($page.url.pathname);
	const isLoggedIn = $derived(Boolean(data.user));
	const isCatalogMock = $derived(
		pathname === '/mockup/catalogo' || pathname.startsWith('/mockup/catalogo/')
	);

	// Mapeo href -> seccion_id para las entradas de nav controlables por flag.
	// Una entrada sin mapeo (proyecto, recursos, etc.) siempre se muestra.
	const HREF_TO_SECTION: Record<string, string> = {
		'/obras': 'catalogo',
		'/autores': 'autores',
		'/laboratorio': 'laboratorio',
		'/recursos/demarcador': 'demarcador',
		'/recursos/catalogo-metrico': 'formas'
	};

	function navItemVisible(href: string | undefined): boolean {
		if (!href) return true;
		const seccionId = HREF_TO_SECTION[href];
		if (!seccionId) return true; // sin flag asociado: siempre visible
		const visibility = data.sectionVisibility;
		if (!visibility) return true; // sin datos cargados: no ocultar de más
		return isSectionVisible(visibility, seccionId);
	}

	// Filtra grupos de nav: oculta items controlados por flag apagado, y oculta el
	// grupo entero si se queda sin items.
	const visibleNav = $derived.by((): NavGroup[] => {
		return PUBLIC_NAV.map((group) => {
			if (group.items) {
				const items = group.items.filter((item: NavItem) => navItemVisible(item.href));
				return { ...group, items };
			}
			return group;
		}).filter((group) => {
			if (group.items) return group.items.length > 0;
			return navItemVisible(group.href);
		});
	});

	// Mismo filtro de flags para el footer: quita links a páginas apagadas y oculta
	// la sección de footer si se queda vacía.
	const visibleFooter = $derived.by(() =>
		FOOTER_SECTIONS.map((section) => ({
			...section,
			links: section.links.filter((link) => navItemVisible(link.href))
		})).filter((section) => section.links.length > 0)
	);

	function isActive(href: string) {
		if (href === '/') return pathname === '/';
		return pathname === href || pathname.startsWith(`${href}/`);
	}

	function requestLogout() {
		logoutConfirmOpen = true;
	}

	async function onLogout() {
		if (loggingOut) return;
		loggingOut = true;

		try {
			const { getSupabaseBrowserClient } = await import('$lib/services/supabase');
			const supabase = getSupabaseBrowserClient();
			const { error } = await supabase.auth.signOut();

			if (error) {
				console.error('No se pudo cerrar sesión', error);
				return;
			}

			mobileOpen = false;
			logoutConfirmOpen = false;
			await invalidateAll();
		} catch (error) {
			console.error('No se pudo cerrar sesión', error);
		} finally {
			loggingOut = false;
		}
	}
</script>

<div class="flex min-h-screen flex-col bg-[color:var(--background)]">
	<header class="border-b border-[color:var(--border)] bg-white">
		<div class="mx-auto flex w-full max-w-7xl items-center gap-4 px-4 py-3 md:px-6">
			<a href="/" class="shrink-0" aria-label="Ir al inicio">
				<img src="/logo-metadrama.webp" alt="MetaDrama" class="h-10 w-auto md:h-11" />
			</a>

			<nav class="ml-auto hidden items-center gap-5 text-[11px] font-semibold tracking-[0.08em] lg:flex">
				{#each visibleNav as group}
					{#if group.items}
						<div class="group relative">
							<button
								type="button"
								class="border-b border-transparent py-2 text-[color:var(--gray-700)] transition-colors hover:text-[color:var(--foreground)]"
							>
								{group.label}
							</button>
							<div
								class="invisible absolute right-0 top-full z-30 mt-2 min-w-[14rem] border border-[color:var(--border)] bg-white opacity-0 transition-all group-focus-within:visible group-focus-within:opacity-100 group-hover:visible group-hover:opacity-100"
							>
								{#each group.items as item}
									<a
										href={item.href}
										class="block border-b border-[color:var(--border)] px-3 py-2 text-[11px] font-semibold tracking-[0.08em] text-[color:var(--gray-700)] transition-colors hover:bg-[color:var(--muted)] hover:text-[color:var(--foreground)] last:border-b-0"
										target={item.external ? '_blank' : undefined}
										rel={item.external ? 'noreferrer noopener' : undefined}
									>
										{item.label}
									</a>
								{/each}
							</div>
						</div>
					{:else if group.href}
						<a
							href={group.href}
							class={`border-b py-2 transition-colors ${isActive(group.href) ? 'border-[color:var(--primary)] text-[color:var(--foreground)]' : 'border-transparent text-[color:var(--gray-700)] hover:text-[color:var(--foreground)]'}`}
						>
							{group.label}
						</a>
					{/if}
				{/each}
				<div class="flex items-center gap-2">
					<a
						href={isLoggedIn ? '/dashboard' : '/login'}
						class="border border-[color:var(--gray-800)] bg-[color:var(--gray-800)] px-3 py-2 text-[11px] font-bold tracking-[0.08em] text-white transition-colors hover:bg-[color:var(--gray-700)]"
					>
						{isLoggedIn ? 'Panel' : 'Acceso editores'}
					</a>
					{#if isLoggedIn}
						<button
							type="button"
							class="inline-flex h-8 w-8 items-center justify-center bg-transparent text-[color:var(--gray-800)] transition-colors hover:text-[color:var(--foreground)] disabled:cursor-not-allowed disabled:opacity-50"
							onclick={requestLogout}
							disabled={loggingOut}
							aria-label="Cerrar sesión"
							title="Cerrar sesión"
						>
							<DoorOpenIcon size={15} aria-hidden="true" />
						</button>
					{/if}
				</div>
			</nav>

			<button
				type="button"
				class="ml-auto border border-[color:var(--border)] px-3 py-2 text-xs font-semibold tracking-[0.08em] lg:hidden"
				onclick={() => (mobileOpen = !mobileOpen)}
				aria-expanded={mobileOpen}
				aria-label="Alternar menú principal"
			>
				MENU
			</button>
		</div>

		{#if mobileOpen}
			<div class="border-t border-[color:var(--border)] bg-white lg:hidden">
				<nav class="mx-auto grid w-full max-w-7xl gap-1 px-4 py-3 text-xs font-semibold tracking-[0.08em] md:px-6">
					{#each visibleNav as group}
						{#if group.items}
							<div class="border border-[color:var(--border)]">
								<button
									type="button"
									class="flex w-full items-center justify-between px-3 py-2 text-left text-[color:var(--foreground)]"
									onclick={() => {
										if (group.label === 'RECURSOS') resourcesOpen = !resourcesOpen;
										if (group.label === 'PROYECTO') projectOpen = !projectOpen;
									}}
								>
									<span>{group.label}</span>
									<span>{group.label === 'RECURSOS' ? (resourcesOpen ? '-' : '+') : projectOpen ? '-' : '+'}</span>
								</button>
								{#if (group.label === 'RECURSOS' && resourcesOpen) || (group.label === 'PROYECTO' && projectOpen)}
									<div class="border-t border-[color:var(--border)]">
										{#each group.items as item}
											<a
												href={item.href}
												class="block border-b border-[color:var(--border)] px-3 py-2 text-[color:var(--gray-700)] last:border-b-0"
												target={item.external ? '_blank' : undefined}
												rel={item.external ? 'noreferrer noopener' : undefined}
												onclick={() => (mobileOpen = false)}
											>
												{item.label}
											</a>
										{/each}
									</div>
								{/if}
							</div>
						{:else if group.href}
							<a
								href={group.href}
								class={`border px-3 py-2 ${isActive(group.href) ? 'border-[color:var(--primary)] text-[color:var(--foreground)]' : 'border-[color:var(--border)] text-[color:var(--gray-700)]'}`}
								onclick={() => (mobileOpen = false)}
							>
								{group.label}
							</a>
						{/if}
					{/each}

					<div class={isLoggedIn ? 'grid grid-cols-[minmax(0,1fr)_auto] gap-1' : ''}>
						<a
							href={isLoggedIn ? '/dashboard' : '/login'}
							class="border border-[color:var(--gray-800)] bg-[color:var(--gray-800)] px-3 py-2 text-center text-white"
							onclick={() => (mobileOpen = false)}
						>
							{isLoggedIn ? 'Panel' : 'Acceso editores'}
						</a>
						{#if isLoggedIn}
							<button
								type="button"
								class="inline-flex h-full min-h-9 w-10 items-center justify-center bg-transparent text-[color:var(--gray-800)] transition-colors hover:text-[color:var(--foreground)] disabled:cursor-not-allowed disabled:opacity-50"
								onclick={requestLogout}
								disabled={loggingOut}
								aria-label="Cerrar sesión"
								title="Cerrar sesión"
							>
								<DoorOpenIcon size={16} aria-hidden="true" />
							</button>
						{/if}
					</div>
				</nav>
			</div>
		{/if}
	</header>

	<main
		class={`mx-auto w-full flex-1 px-4 py-8 md:px-6 md:py-10 ${isCatalogMock ? 'max-w-[1200px]' : 'max-w-7xl'}`}
	>
		{@render children()}
	</main>

	<footer class="border-t border-[color:var(--border)] bg-[color:var(--muted)]">
		<div
			class="mx-auto grid w-full max-w-7xl gap-8 px-4 py-8 md:grid-cols-[minmax(0,2fr)_minmax(16rem,1fr)] md:items-center md:px-6"
		>
			<div class="grid max-w-2xl grid-cols-[auto_1px_minmax(0,1fr)] items-center gap-4 md:gap-5">
				<a href="/" class="inline-block shrink-0" aria-label="Ir a la página de inicio de MetaDrama">
					<img src="/logo-metadrama.webp" alt="MetaDrama" class="h-10 w-auto md:h-12" />
				</a>
				<div class="h-16 bg-[color:var(--primary)]" aria-hidden="true"></div>
				<div class="min-w-0">
					<p class="font-display text-lg tracking-[0.08em] text-[color:var(--foreground)]">
						VERSOLOGÍA
					</p>
					<p class="mt-1 max-w-md text-xs leading-5 text-[color:var(--muted-foreground)]">
						Base de datos y herramientas de estilometría estrófica para el verso dramático
					</p>
				</div>
			</div>

			{#each visibleFooter as section}
				<div class="md:border-l md:border-[color:var(--border)] md:pl-8">
					<h3 class="font-display text-sm text-[color:var(--gray-800)]">{section.title}</h3>
					<div
						class="mt-3 grid grid-cols-2 gap-x-6 gap-y-2 text-xs font-medium tracking-[0.06em] text-[color:var(--gray-700)]"
					>
						{#each section.links as link}
							<a
								href={link.href}
								class="transition-colors hover:text-[color:var(--foreground)]"
								target={link.external ? '_blank' : undefined}
								rel={link.external ? 'noreferrer noopener' : undefined}
							>
								{link.label}
							</a>
						{/each}
					</div>
				</div>
			{/each}
		</div>

		<div class="border-t border-[color:var(--border)]">
			<div
				class="mx-auto grid w-full max-w-7xl gap-8 px-4 py-6 md:px-6 lg:grid-cols-[minmax(0,1fr)_auto] lg:items-center"
			>
				<div class="max-w-2xl text-xs leading-5 text-[color:var(--muted-foreground)]">
					<p class="font-display text-sm text-[color:var(--gray-800)]">PROYECTO DE INVESTIGACIÓN</p>
					<p class="mt-2 text-sm font-medium text-[color:var(--foreground)]">
						Teatro áureo en diacronía: estudio, edición y puesta en escena del verso clásico
					</p>
					<p class="mt-1">
						Proyecto PID2024-161619NA-I00 financiado por MICIU/AEI/10.13039/501100011033 y
						por FEDER, UE.
					</p>
					<p class="mt-2">
						Contenidos bajo
						<a
							href="https://creativecommons.org/licenses/by-nc-sa/4.0/deed.es"
							class="font-medium text-[color:var(--foreground)] underline decoration-[color:var(--border)] underline-offset-4 transition-colors hover:decoration-[color:var(--foreground)]"
							target="_blank"
							rel="noreferrer noopener"
						>
							CC BY-NC-SA 4.0
						</a>.
					</p>
				</div>

				<div class="flex flex-col items-start gap-5 sm:flex-row sm:items-center lg:justify-end">
					<a
						href="https://www.aei.gob.es/sites/default/files/convocatory_info/file/2025-12/PID2024-RC-Texto%2BAnexos-firmado.pdf"
						class="inline-flex transition-opacity hover:opacity-75"
						target="_blank"
						rel="noreferrer noopener"
						aria-label="Consultar la resolución de financiación del proyecto"
					>
						<img
							src="/images/institucional/financiacion-miciu-aei-ue.webp"
							alt="Ministerio de Ciencia, Innovación y Universidades, Unión Europea y Agencia Estatal de Investigación"
							class="h-auto w-full max-w-[21rem]"
						/>
					</a>
					<a
						href="https://www.ub.edu/"
						class="inline-flex transition-opacity hover:opacity-75"
						target="_blank"
						rel="noreferrer noopener"
						aria-label="Visitar el sitio web de la Universitat de Barcelona"
					>
						<img
							src="/images/institucional/logo-ub.svg"
							alt="Universitat de Barcelona"
							class="h-auto w-full max-w-[14rem]"
						/>
					</a>
				</div>
			</div>
		</div>
	</footer>

	{#if logoutConfirmOpen}
		<div
			class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4"
			role="presentation"
		>
			<div
				class="w-full max-w-sm border border-[color:var(--border)] bg-white p-5 shadow-lg"
				role="dialog"
				aria-modal="true"
				aria-labelledby="logout-confirm-title"
			>
				<h2 id="logout-confirm-title" class="font-display text-xl text-[color:var(--foreground)]">
					Cerrar sesión
				</h2>
				<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">
					¿Quieres cerrar sesión?
				</p>
				<div class="mt-5 flex justify-end gap-2">
					<button
						type="button"
						class="border border-[color:var(--border)] bg-white px-3 py-2 text-sm font-medium text-[color:var(--foreground)] transition-colors hover:bg-[color:var(--muted)] disabled:cursor-not-allowed disabled:opacity-50"
						onclick={() => (logoutConfirmOpen = false)}
						disabled={loggingOut}
					>
						Cancelar
					</button>
					<button
						type="button"
						class="border border-[color:var(--gray-800)] bg-[color:var(--gray-800)] px-3 py-2 text-sm font-medium text-white transition-colors hover:bg-[color:var(--gray-700)] disabled:cursor-not-allowed disabled:opacity-50"
						onclick={onLogout}
						disabled={loggingOut}
					>
						{loggingOut ? 'Cerrando...' : 'Cerrar sesión'}
					</button>
				</div>
			</div>
		</div>
	{/if}
</div>
