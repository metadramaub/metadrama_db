<script lang="ts">
	import Button from '$lib/components/ui/button.svelte';

	const props = $props<{
		open: boolean;
		message?: string;
		detail?: string;
		discardLabel?: string;
		saving?: boolean;
		onCancel: () => void;
		onDiscard: () => void;
		onSave?: () => void | Promise<void>;
	}>();
</script>

{#if props.open}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
		<div class="card w-full max-w-md p-5">
			<h3 class="text-lg font-semibold">Cambios sin guardar</h3>
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">
				{props.message ?? 'Hay cambios sin guardar en este panel.'}
			</p>
			{#if props.detail}
				<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">{props.detail}</p>
			{/if}
			<div class="mt-5 grid grid-cols-1 gap-2 sm:grid-cols-2">
				<Button class="w-full" variant="secondary" onclick={props.onCancel} disabled={props.saving}>
					Seguir editando
				</Button>
				<Button class="w-full" variant="danger" onclick={props.onDiscard} disabled={props.saving}>
					{props.discardLabel ?? 'Descartar cambios'}
				</Button>
				{#if props.onSave}
					<Button
						class="w-full sm:col-span-2"
						variant="success"
						onclick={() => void props.onSave?.()}
						loading={props.saving}
						loadingLabel="Guardando…"
					>
						Guardar y continuar
					</Button>
				{/if}
			</div>
		</div>
	</div>
{/if}
