<script lang="ts">
	import { portal } from '$lib/actions/portal';
	import SequenceSynopsisView from '$lib/components/editor/SequenceSynopsisView.svelte';
	import Button from '$lib/components/ui/button.svelte';
	import type { SequenceSynopsisJornadaGroup } from '$lib/components/editor/sequence-synopsis';

	const props = $props<{
		open: boolean;
		groups: SequenceSynopsisJornadaGroup[];
		totalSequences: number;
		missingSynopsisCount: number;
		showSavedVersionNote?: boolean;
		onClose: () => void;
	}>();

	$effect(() => {
		if (!props.open) return;
		const handleEscape = (event: KeyboardEvent) => {
			if (event.key !== 'Escape') return;
			props.onClose();
		};

		document.addEventListener('keydown', handleEscape);
		return () => {
			document.removeEventListener('keydown', handleEscape);
		};
	});
</script>

{#if props.open}
	<div use:portal class="fixed inset-0 z-[130]">
		<button
			type="button"
			class="absolute inset-0 bg-black/45"
			aria-label="Cerrar"
			onclick={props.onClose}
		></button>

		<div class="absolute inset-0 z-[1] p-4 md:px-10 lg:px-20">
			<div class="h-[calc(100dvh-2rem)] overflow-y-auto border border-[color:var(--border)] bg-[color:var(--gray-50)] shadow-2xl">
				<div class="sticky top-0 z-20 border-b border-[color:var(--border)] bg-white px-5 py-4">
					<div class="flex flex-wrap items-start justify-between gap-3">
						<div class="space-y-2">
							<div>
								<h2 class="text-xl font-semibold">Sinopsis completa</h2>
								<p class="text-sm text-[color:var(--muted-foreground)]">
									{props.totalSequences} secuencias
									{#if props.missingSynopsisCount > 0}
										· {props.missingSynopsisCount} sin sinopsis
									{/if}
								</p>
							</div>

							{#if props.showSavedVersionNote}
								<p class="max-w-3xl rounded-md border border-[color:var(--border)] bg-[color:var(--muted)] px-3 py-2 text-sm text-[color:var(--muted-foreground)]">
									La sinopsis completa refleja la última versión guardada. La secuencia abierta tiene cambios aún no guardados.
								</p>
							{/if}
						</div>

						<Button variant="secondary" onclick={props.onClose}>Cerrar</Button>
					</div>
				</div>

				<div class="px-5 py-5">
					<SequenceSynopsisView groups={props.groups} />
				</div>
			</div>
		</div>
	</div>
{/if}
