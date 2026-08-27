<script lang="ts">
	import type { PublicSource } from '$lib/metrica/formas-publicas.types';

	const { source } = $props<{ source: PublicSource }>();
	const hasStructuredReference = $derived(Boolean(source.autoria || source.titulo));
</script>

{#if hasStructuredReference}
	<div>
		{#if source.autoria}
			<p
				class="text-sm font-semibold tracking-[0.045em] text-[color:var(--gray-800)] [font-variant-caps:all-small-caps]"
			>
				{source.autoria}
			</p>
		{/if}
		<p class="mt-0.5 leading-6 text-[color:var(--foreground)]">
			{#if source.titulo}<cite class="italic">{source.titulo}</cite>{/if}{#if source.anio}<span
					class="text-[color:var(--muted-foreground)]"> · {source.anio}</span
				>{/if}
		</p>
		{#if source.publicacion}
			<p class="mt-0.5 text-sm leading-6 text-[color:var(--muted-foreground)]">
				{source.publicacion}
			</p>
		{/if}
	</div>
{:else}
	<p class="text-sm font-medium leading-6 text-[color:var(--gray-700)]">{source.cita}</p>
{/if}
