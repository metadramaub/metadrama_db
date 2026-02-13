<script lang="ts">
	import type { Snippet } from 'svelte';

	type Variant = 'primary' | 'secondary' | 'ghost' | 'danger' | 'success';
	const props = $props<{
		type?: 'button' | 'submit' | 'reset';
		variant?: Variant;
		class?: string;
		disabled?: boolean;
		onclick?: (event: MouseEvent) => void;
		children?: Snippet;
	}>();

	const base =
		'inline-flex items-center justify-center px-3 py-2 text-sm font-medium transition-colors disabled:cursor-not-allowed disabled:opacity-50';
	const variants: Record<Variant, string> = {
		primary:
			'border border-[color:var(--primary)] bg-[color:var(--primary)] text-[color:var(--primary-foreground)] hover:brightness-95',
		secondary:
			'border border-[color:var(--border)] bg-[color:var(--muted)] text-[color:var(--foreground)] hover:bg-[color:var(--gray-200)]',
		ghost:
			'border border-[color:var(--border)] bg-transparent text-[color:var(--foreground)] hover:bg-[color:var(--muted)]',
		success:
			'border border-[color:var(--success)] bg-[color:var(--success)] text-white hover:opacity-95',
		danger: 'border border-[color:var(--danger)] bg-[color:var(--danger)] text-white hover:opacity-95'
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
