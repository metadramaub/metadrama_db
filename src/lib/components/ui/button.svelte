<script lang="ts">
	import type { Snippet } from 'svelte';

	type Variant = 'primary' | 'secondary' | 'ghost' | 'danger';
	const props = $props<{
		type?: 'button' | 'submit' | 'reset';
		variant?: Variant;
		class?: string;
		disabled?: boolean;
		onclick?: (event: MouseEvent) => void;
		children?: Snippet;
	}>();

	const base =
		'inline-flex items-center justify-center rounded-md px-3 py-2 text-sm font-medium transition disabled:cursor-not-allowed disabled:opacity-50';
	const variants: Record<Variant, string> = {
		primary: 'bg-[color:var(--primary)] text-[color:var(--primary-foreground)] hover:opacity-95',
		secondary: 'bg-[color:var(--muted)] text-[color:var(--foreground)] hover:bg-[#ded3c2]',
		ghost: 'border border-[color:var(--border)] text-[color:var(--foreground)] hover:bg-[#efe5d7]',
		danger: 'bg-[color:var(--danger)] text-white hover:opacity-95'
	};
	const chosenVariant = $derived((props.variant ?? 'primary') as Variant);
</script>

<button
	type={props.type ?? 'button'}
	class={`${base} ${variants[chosenVariant]} ${props.class ?? ''}`}
	disabled={props.disabled ?? false}
	onclick={props.onclick}
>
	{@render props.children?.()}
</button>
