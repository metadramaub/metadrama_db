<script lang="ts">
	import type { Snippet } from 'svelte';

	const props = $props<{
		value?: string | null;
		class?: string;
		disabled?: boolean;
		required?: boolean;
		children?: Snippet;
	}>();
</script>

<select
	value={props.value ?? ''}
	class={`w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm text-[color:var(--foreground)] disabled:bg-[color:var(--muted)] ${props.class ?? ''}`}
	disabled={props.disabled}
	required={props.required}
>
	{@render props.children?.()}
</select>
