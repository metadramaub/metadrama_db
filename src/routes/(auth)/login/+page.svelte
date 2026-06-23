<script lang="ts">
	import { goto } from '$app/navigation';
	import Button from '$lib/components/ui/button.svelte';
	import type { PageData } from './$types';

	let { data } = $props<{ data: PageData }>();

	let email = $state('');
	let password = $state('');
	let loading = $state(false);
	let errorMessage = $state<string | null>(null);
	const authNotice = $derived.by(() => {
		switch (data.authStatus) {
			case 'password_set':
				return {
					text: 'Contraseña creada correctamente. Ya puedes iniciar sesión.',
					className: 'text-[color:var(--success)]'
				};
			case 'link_error':
				return {
					text: 'El enlace es inválido o ha caducado. Solicita uno nuevo.',
					className: 'text-[color:var(--danger)]'
				};
			case 'session_required':
				return {
					text: 'Necesitas una sesión válida para continuar ese flujo.',
					className: 'text-[color:var(--danger)]'
				};
			default:
				return null;
		}
	});

	async function onSubmit(event: SubmitEvent) {
		event.preventDefault();
		loading = true;
		errorMessage = null;
		try {
			const { getSupabaseBrowserClient } = await import('$lib/services/supabase');
			const supabase = getSupabaseBrowserClient();
			const { error } = await supabase.auth.signInWithPassword({
				email,
				password
			});

			if (error) {
				errorMessage = error.message;
				return;
			}

			await goto(data.redirectTo);
		} catch (error) {
			errorMessage = error instanceof Error ? error.message : 'No se pudo iniciar sesión.';
		} finally {
			loading = false;
		}
	}
</script>

<div class="flex min-h-screen items-center justify-center bg-[color:var(--background)] p-6">
	<div class="w-full max-w-md">
		<a
			href="/"
			class="mb-3 inline-flex border border-[color:var(--border)] px-3 py-2 text-xs font-semibold tracking-[0.06em] text-[color:var(--gray-700)]"
		>
			VOLVER A LA WEB
		</a>

		<div class="card p-6">
			<h1 class="font-display mb-1 text-3xl">LOG IN</h1>
			<p class="mb-6 text-sm text-[color:var(--muted-foreground)]">
				Inicia sesión para trabajar en el dashboard.
			</p>
			{#if authNotice}
				<p class={`mb-4 text-sm ${authNotice.className}`}>{authNotice.text}</p>
			{/if}
			<form class="space-y-4" onsubmit={onSubmit}>
				<label class="block text-sm">
					<span class="mb-1 block">Correo electrónico</span>
					<input
						type="email"
						bind:value={email}
						required
						class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
					/>
				</label>
				<label class="block text-sm">
					<span class="mb-1 block">Contraseña</span>
					<input
						type="password"
						bind:value={password}
						required
						class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
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
</div>
