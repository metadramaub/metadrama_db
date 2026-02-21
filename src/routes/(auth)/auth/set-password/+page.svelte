<script lang="ts">
	import { goto } from '$app/navigation';
	import Button from '$lib/components/ui/button.svelte';
	import { getSupabaseBrowserClient } from '$lib/services/supabase';
	import type { PageData } from './$types';

	let { data } = $props<{ data: PageData }>();

	let password = $state('');
	let confirmPassword = $state('');
	let saving = $state(false);
	let errorMessage = $state<string | null>(null);

	function validatePasswordInput(): string | null {
		if (password.length < 12) {
			return 'La contraseña debe tener al menos 12 caracteres.';
		}
		if (password !== confirmPassword) {
			return 'Las contraseñas no coinciden.';
		}
		return null;
	}

	async function onSubmit(event: SubmitEvent) {
		event.preventDefault();
		errorMessage = null;

		const validationError = validatePasswordInput();
		if (validationError) {
			errorMessage = validationError;
			return;
		}

		saving = true;
		try {
			const supabase = getSupabaseBrowserClient();
			const { error: updateError } = await supabase.auth.updateUser({ password });
			if (updateError) {
				errorMessage = updateError.message;
				return;
			}

			const { error: signOutError } = await supabase.auth.signOut();
			if (signOutError) {
				errorMessage = signOutError.message;
				return;
			}

			await goto('/login?auth=password_set');
		} catch (error) {
			errorMessage = error instanceof Error ? error.message : 'No se pudo actualizar la contraseña.';
		} finally {
			saving = false;
		}
	}
</script>

<div class="flex min-h-screen items-center justify-center bg-[color:var(--background)] p-6">
	<div class="w-full max-w-md">
		<div class="card p-6">
			<h1 class="font-display mb-1 text-3xl">CREAR CONTRASEÑA</h1>
			<p class="mb-1 text-sm text-[color:var(--muted-foreground)]">
				Define tu contraseña para activar el acceso editorial.
			</p>
			{#if data.email}
				<p class="mb-6 text-xs text-[color:var(--muted-foreground)]">Cuenta: {data.email}</p>
			{:else}
				<div class="mb-6"></div>
			{/if}

			<form class="space-y-4" onsubmit={onSubmit}>
				<label class="block text-sm">
					<span class="mb-1 block">Nueva contraseña</span>
					<input
						type="password"
						bind:value={password}
						required
						minlength={12}
						class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
					/>
				</label>

				<label class="block text-sm">
					<span class="mb-1 block">Repetir contraseña</span>
					<input
						type="password"
						bind:value={confirmPassword}
						required
						minlength={12}
						class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
					/>
				</label>

				{#if errorMessage}
					<p class="text-sm text-[color:var(--danger)]">{errorMessage}</p>
				{/if}

				<Button type="submit" class="w-full" disabled={saving}>
					{#if saving}Guardando...{:else}Guardar contraseña{/if}
				</Button>
			</form>
		</div>
	</div>
</div>
