<script lang="ts">
	import Button from '$lib/components/ui/button.svelte';
	import type { ActionData, PageData } from './$types';

	let { data, form } = $props<{ data: PageData; form: ActionData }>();
	const errorMessage = $derived(form?.error ?? null);
	const redirectTo = $derived(form?.redirectTo ?? data.redirectTo);
</script>

<div class="flex min-h-screen items-center justify-center bg-[color:var(--gray-950)] p-4">
	<section class="w-full max-w-md border border-[color:var(--border)] bg-white p-6">
		<h1 class="font-display text-2xl text-[color:var(--gray-900)]">WEB EN CONSTRUCCIÓN</h1>
		<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">
			Introduce contraseña para continuar.
		</p>

		<form class="mt-5 space-y-3" method="POST">
			<input type="hidden" name="redirectTo" value={redirectTo} />
			<label class="block text-sm">
				<span class="mb-1 block">Contraseña</span>
				<input
					type="password"
					name="password"
					class="w-full border border-[color:var(--border)] bg-white px-3 py-2"
					autocomplete="off"
					required
				/>
			</label>
			{#if errorMessage}
				<p class="text-sm text-[color:var(--danger)]">{errorMessage}</p>
			{/if}
			<Button type="submit" class="w-full" disabled={!data.configured}>Entrar</Button>
		</form>
	</section>
</div>
