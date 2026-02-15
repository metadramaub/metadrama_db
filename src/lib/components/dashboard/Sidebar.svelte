<script lang="ts">
	import ArrowLeft from 'lucide-svelte/icons/arrow-left';
	import Bell from 'lucide-svelte/icons/bell';
	import BookOpenText from 'lucide-svelte/icons/book-open-text';
	import DoorOpen from 'lucide-svelte/icons/door-open';
	import Home from 'lucide-svelte/icons/home';
	import LibraryBig from 'lucide-svelte/icons/library-big';
	import UserRound from 'lucide-svelte/icons/user-round';
	import { goto } from '$app/navigation';
	import { getSupabaseBrowserClient } from '$lib/services/supabase';
	import Button from '$lib/components/ui/button.svelte';
	import type { EditorProfile } from '$lib/types/obra.types';

	const props = $props<{
		profile: EditorProfile;
		misObrasCount?: number;
		notificationsUnreadCount?: number;
	}>();

	let loggingOut = $state(false);

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
			<Home size={16} />
			Inicio
		</a>
		<a
			class="flex items-center gap-2 border border-[color:var(--border)] px-3 py-2 hover:bg-[color:var(--muted)]"
			href="/dashboard/notificaciones"
		>
			<Bell size={16} />
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
			<BookOpenText size={16} />
			Obras
			<span
				class="ml-auto border border-[color:var(--primary)] bg-[color:var(--primary)] px-2 py-0.5 text-xs text-[color:var(--primary-foreground)]"
			>
				{props.misObrasCount ?? 0}
			</span>
		</a>
		<a
			class="flex items-center gap-2 border border-[color:var(--border)] px-3 py-2 hover:bg-[color:var(--muted)]"
			href="/dashboard/autores"
		>
			<UserRound size={16} />
			Autores
		</a>
		<a
			class="flex items-center gap-2 border border-[color:var(--border)] px-3 py-2 hover:bg-[color:var(--muted)]"
			href="/dashboard/vocabularios"
		>
			<LibraryBig size={16} />
			Vocabularios
		</a>
	</nav>

	<div class="mt-4 border-t border-[color:var(--border)] pt-4">
		<Button variant="ghost" class="mb-2 w-full justify-start gap-2" onclick={() => goto('/')}>
			<ArrowLeft size={16} />
			Volver a la web
		</Button>
		<Button variant="ghost" class="w-full justify-start gap-2" onclick={onLogout} disabled={loggingOut}>
			<DoorOpen size={16} />
			Cerrar sesión
		</Button>
	</div>
</aside>
