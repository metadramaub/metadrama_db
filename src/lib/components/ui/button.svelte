<script lang="ts">
	import type { Snippet } from 'svelte';

	type Variant = 'primary' | 'primary-soft' | 'secondary' | 'ghost' | 'danger' | 'success';
	const props = $props<{
		type?: 'button' | 'submit' | 'reset';
		variant?: Variant;
		class?: string;
		disabled?: boolean;
		loading?: boolean;
		loadingLabel?: string;
		onclick?: (event: MouseEvent) => void;
		children?: Snippet;
	}>();

	const base =
		'inline-flex items-center justify-center gap-2 px-3 py-2 text-sm font-medium transition-colors disabled:cursor-not-allowed disabled:opacity-50';
	const variants: Record<Variant, string> = {
		primary:
			'border border-[color:var(--primary)] bg-[color:var(--primary)] text-[color:var(--primary-foreground)] hover:brightness-95',
		'primary-soft':
			'border border-[color:var(--primary)] bg-[color:var(--muted)] text-[color:var(--primary)] hover:bg-[color:var(--gray-200)]',
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
	disabled={(props.disabled ?? false) || (props.loading ?? false)}
	aria-busy={props.loading ?? false}
	onclick={props.onclick}
>
	{#if props.loading}
		<span
			class="h-3.5 w-3.5 shrink-0 animate-spin border-2 border-current"
			aria-hidden="true"
		></span>
		<span>{props.loadingLabel ?? 'Procesando…'}</span>
	{:else}
		{@render props.children?.()}
	{/if}
</button>
