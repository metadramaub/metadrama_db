<script lang="ts">
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';

	let status = $state('Procesando enlace de acceso...');

	function resolveNextPath(type: string | null): string {
		if (type === 'invite' || type === 'recovery') {
			return '/auth/set-password';
		}
		return '/login';
	}

	onMount(async () => {
		const query = new URLSearchParams(window.location.search);
		const hashRaw = window.location.hash.startsWith('#') ? window.location.hash.slice(1) : '';
		const hash = new URLSearchParams(hashRaw);

		const hashError = hash.get('error') ?? hash.get('error_code');
		if (hashError) {
			await goto('/login?auth=link_error');
			return;
		}

		const accessToken = hash.get('access_token');
		const refreshToken = hash.get('refresh_token');
		const authType = hash.get('type') ?? query.get('type');

		if (!accessToken || !refreshToken) {
			await goto('/login?auth=link_error');
			return;
		}

		status = 'Validando sesión de invitación...';
		const { getSupabaseBrowserClient } = await import('$lib/services/supabase');
		const supabase = getSupabaseBrowserClient();
		const { error } = await supabase.auth.setSession({
			access_token: accessToken,
			refresh_token: refreshToken
		});

		if (error) {
			await goto('/login?auth=link_error');
			return;
		}

		window.location.assign(resolveNextPath(authType));
	});
</script>

<div class="flex min-h-screen items-center justify-center bg-[color:var(--background)] p-6">
	<div class="card w-full max-w-md p-6 text-center">
		<h1 class="font-display text-2xl">ACCESO</h1>
		<p class="mt-3 text-sm text-[color:var(--muted-foreground)]">{status}</p>
	</div>
</div>
