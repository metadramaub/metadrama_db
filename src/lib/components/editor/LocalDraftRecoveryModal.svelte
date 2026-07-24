<script lang="ts">
	import Button from '$lib/components/ui/button.svelte';

	const props = $props<{
		open: boolean;
		savedAt?: string | null;
		onDiscard: () => void;
		onRestore: () => void;
	}>();

	const savedAtLabel = $derived.by(() => {
		if (!props.savedAt) return '';
		const date = new Date(props.savedAt);
		if (Number.isNaN(date.getTime())) return '';
		return date.toLocaleString('es-ES');
	});
</script>

{#if props.open}
	<div class="fixed inset-0 z-[60] flex items-center justify-center bg-black/50 p-4">
		<div class="card w-full max-w-md p-5">
			<h3 class="text-lg font-semibold">Borrador local disponible</h3>
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">
				Hay cambios no guardados en Supabase que se conservaron en este navegador.
			</p>
			{#if savedAtLabel}
				<p class="mt-1 text-xs text-[color:var(--muted-foreground)]">
					Última actualización local: {savedAtLabel}
				</p>
			{/if}
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">
				Recuperarlos no modifica la base de datos hasta que pulses Guardar.
			</p>
			<div class="mt-4 flex flex-wrap justify-end gap-2">
				<Button variant="danger" onclick={props.onDiscard}>Descartar borrador</Button>
				<Button variant="success" onclick={props.onRestore}>Recuperar borrador</Button>
			</div>
		</div>
	</div>
{/if}
