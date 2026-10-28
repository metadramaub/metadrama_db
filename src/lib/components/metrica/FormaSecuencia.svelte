<script lang="ts">
	let { forma, arquitectura = null, pendiente = 'Pendiente' } = $props<{
		forma: string | null;
		arquitectura?: string | null;
		pendiente?: string;
	}>();
</script>

<span class={forma ? 'font-medium' : 'italic text-[color:var(--muted-foreground)]'}>
	{forma ?? pendiente}
</span>
{#if arquitectura && arquitectura !== forma}
	<span class="block text-xs text-[color:var(--muted-foreground)]">{arquitectura}</span>
{/if}
