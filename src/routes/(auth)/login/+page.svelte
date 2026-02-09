<script lang="ts">
	import { goto } from '$app/navigation';
	import { getSupabaseBrowserClient } from '$lib/services/supabase';
	import Button from '$lib/components/ui/button.svelte';
	import type { PageData } from './$types';

	let { data } = $props<{ data: PageData }>();

	let email = $state('');
	let password = $state('');
	let loading = $state(false);
	let errorMessage = $state<string | null>(null);

	async function onSubmit(event: SubmitEvent) {
		event.preventDefault();
		loading = true;
		errorMessage = null;

		const supabase = getSupabaseBrowserClient();
		const { error } = await supabase.auth.signInWithPassword({
			email,
			password
		});

		loading = false;
		if (error) {
			errorMessage = error.message;
			return;
		}

		await goto(data.redirectTo);
	}
</script>

<div class="flex min-h-screen items-center justify-center p-6">
	<div class="card w-full max-w-md p-6">
		<h1 class="mb-1 text-2xl font-semibold">Acceso de editores</h1>
		<p class="mb-6 text-sm text-[color:var(--muted-foreground)]">Inicia sesión para trabajar en el dashboard.</p>
		<form class="space-y-4" onsubmit={onSubmit}>
			<label class="block text-sm">
				<span class="mb-1 block">Correo electrónico</span>
				<input
					type="email"
					bind:value={email}
					required
					class="w-full rounded-md border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
				/>
			</label>
			<label class="block text-sm">
				<span class="mb-1 block">Contraseña</span>
				<input
					type="password"
					bind:value={password}
					required
					class="w-full rounded-md border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
				/>
			</label>
			{#if errorMessage}
				<p class="text-sm text-[color:var(--danger)]">{errorMessage}</p>
			{/if}
			<Button type="submit" class="w-full" disabled={loading}>
				{#if loading}Entrando...{:else}Entrar{/if}
			</Button>
		</form>
	</div>
</div>
