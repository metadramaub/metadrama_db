<script lang="ts">
	const props = $props<{
		forma: string;
		colorKey: string;
		colorByForma: Record<string, string>;
		className?: string;
	}>();
</script>

<span class={`inline-flex min-w-0 items-center gap-2 ${props.className ?? ''}`}>
	<span
		class="h-2.5 w-2.5 shrink-0 rounded-sm"
		style={`background-color: ${props.colorByForma[props.colorKey] ?? 'var(--gray-400)'}`}
		aria-hidden="true"
	></span>
	<span class="truncate" title={props.forma}>{props.forma}</span>
</span>
