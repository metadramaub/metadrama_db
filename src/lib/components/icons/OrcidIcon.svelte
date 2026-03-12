<script lang="ts">
	const props = $props<{
		size?: number;
		class?: string;
	}>();

	const size = $derived(props.size ?? 14);
	const className = $derived(props.class ?? '');
</script>

<i
	class={`ai ai-orcid ${className}`}
	style={`font-size:${size}px; line-height:1; display:inline-block;`}
	aria-hidden="true"
></i>
