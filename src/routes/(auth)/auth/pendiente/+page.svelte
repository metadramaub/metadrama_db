<script lang="ts">
	import { goto } from '$app/navigation';
	import Button from '$lib/components/ui/button.svelte';
	import { getSupabaseBrowserClient } from '$lib/services/supabase';
	import type { PageData } from './$types';

	let { data } = $props<{ data: PageData }>();

	let signingOut = $state(false);
	let errorMessage = $state<string | null>(null);

	async function retryDashboardAccess() {
		await goto('/dashboard/obras?scope=mine');
	}

	async function closeSession() {
		signingOut = true;
		errorMessage = null;
		try {
			const supabase = getSupabaseBrowserClient();
			const { error } = await supabase.auth.signOut();
			if (error) {
				errorMessage = error.message;
				return;
			}
			await goto('/login');
		} catch (error) {
			errorMessage = error instanceof Error ? error.message : 'No se pudo cerrar sesión.';
		} finally {
			signingOut = false;
		}
	}
</script>

<div class="flex min-h-screen items-center justify-center bg-[color:var(--background)] p-6">
	<div class="w-full max-w-2xl">
		<div class="card p-6">
			<h1 class="font-display mb-2 text-3xl">ACCESO PENDIENTE</h1>
			<p class="text-sm text-[color:var(--muted-foreground)]">
				El usuario ya fue autenticado, pero todavía no tiene perfil editorial asignado en la base de
				datos.
			</p>
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">
				Pasa este UUID al admin para crear la fila en <code>public.editores</code>.
			</p>

			<div class="mt-5 grid gap-3 rounded border border-[color:var(--border)] bg-white p-4 text-sm">
				<div>
					<div class="text-xs font-semibold text-[color:var(--muted-foreground)]">UUID usuario</div>
					<div class="break-all font-mono">{data.userId}</div>
				</div>
				<div>
					<div class="text-xs font-semibold text-[color:var(--muted-foreground)]">Email</div>
					<div class="break-all font-mono">{data.email || 'sin email'}</div>
				</div>
			</div>

			{#if errorMessage}
				<p class="mt-4 text-sm text-[color:var(--danger)]">{errorMessage}</p>
			{/if}

			<div class="mt-6 flex flex-wrap gap-3">
				<Button variant="secondary" onclick={retryDashboardAccess}>Reintentar acceso</Button>
				<Button variant="ghost" onclick={closeSession} disabled={signingOut}>
					{#if signingOut}Cerrando...{:else}Cerrar sesión{/if}
				</Button>
			</div>
		</div>
	</div>
</div>
