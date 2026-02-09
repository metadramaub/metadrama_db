<script lang="ts">
	import { BookOpenText, DoorOpen, House, LibraryBig, ScrollText, Settings2 } from 'lucide-svelte';
	import { goto } from '$app/navigation';
	import { getSupabaseBrowserClient } from '$lib/services/supabase';
	import Button from '$lib/components/ui/button.svelte';
	import type { EditorProfile } from '$lib/types/obra.types';

	const props = $props<{
		profile: EditorProfile;
		misObrasCount?: number;
	}>();

	let loggingOut = $state(false);
	const canReadAll = ['admin', 'ip', 'revisor'].includes(props.profile.roleTerm);
	const canManageVocab = ['admin', 'ip'].includes(props.profile.roleTerm);

	async function onLogout() {
		loggingOut = true;
		const supabase = getSupabaseBrowserClient();
		await supabase.auth.signOut();
		await goto('/login');
		loggingOut = false;
	}
</script>

<aside class="flex h-full w-72 flex-col border-r border-[color:var(--border)] bg-[#fdf8f1] p-4">
	<div>
		<div class="mb-1 text-xs uppercase tracking-wide text-[color:var(--muted-foreground)]">METADRAMA</div>
		<h1 class="text-2xl font-semibold">Dashboard</h1>
	</div>

	<div class="mt-4 rounded-md border border-[color:var(--border)] bg-white p-3">
		<div class="font-medium">{props.profile.nombreCompleto}</div>
		<div class="text-sm text-[color:var(--muted-foreground)]">Rol: {props.profile.roleTerm}</div>
	</div>

	<nav class="mt-6 flex flex-1 flex-col gap-2 text-sm">
		<a class="flex items-center gap-2 rounded-md px-3 py-2 hover:bg-[#efe5d7]" href="/dashboard">
			<House size={16} />
			Inicio
		</a>
		<a class="flex items-center justify-between rounded-md px-3 py-2 hover:bg-[#efe5d7]" href="/dashboard/obras">
			<span class="flex items-center gap-2">
				<BookOpenText size={16} />
				Mis obras
			</span>
			<span class="rounded-full bg-[color:var(--primary)] px-2 py-0.5 text-xs text-white">
				{props.misObrasCount ?? 0}
			</span>
		</a>

		{#if canReadAll}
			<a class="flex items-center gap-2 rounded-md px-3 py-2 hover:bg-[#efe5d7]" href="/dashboard/obras">
				<LibraryBig size={16} />
				Todas las obras
			</a>
		{/if}

		{#if canManageVocab}
			<a class="flex items-center gap-2 rounded-md px-3 py-2 hover:bg-[#efe5d7]" href="/dashboard/vocabularios">
				<ScrollText size={16} />
				Vocabularios
			</a>
		{/if}
	</nav>

	<div class="mt-4 flex flex-col gap-2 border-t border-[color:var(--border)] pt-4">
		<a class="flex items-center gap-2 rounded-md px-3 py-2 hover:bg-[#efe5d7]" href="/dashboard">
			<Settings2 size={16} />
			Configuración
		</a>
		<Button variant="ghost" class="justify-start gap-2" onclick={onLogout} disabled={loggingOut}>
			<DoorOpen size={16} />
			Cerrar sesión
		</Button>
	</div>
</aside>
