<script lang="ts">
	import type { Snippet } from 'svelte';

	type Tone = 'neutral' | 'accent' | 'info' | 'success' | 'warning';
	type IconComponent = any;

	const props = $props<{
		tone?: Tone;
		interactive?: boolean;
		icon?: IconComponent | null;
		title?: string;
		ariaLabel?: string;
		onclick?: (event: MouseEvent) => void;
		class?: string;
		children?: Snippet;
	}>();

	const tone = $derived((props.tone ?? 'neutral') as Tone);
	const interactive = $derived(Boolean(props.interactive || props.onclick));
	const Icon = $derived(props.icon ?? null);
	const baseClass = 'inline-flex items-center gap-1 border px-2 py-0.5 text-xs font-medium leading-none';
	const toneClassMap: Record<Tone, string> = {
		neutral:
			'border-[color:var(--border)] bg-[color:var(--muted)] text-[color:var(--foreground)]',
		accent:
			'border-[color:var(--primary)] bg-[color:var(--muted)] text-[color:var(--primary)]',
		info: 'border-sky-300 bg-sky-50 text-sky-900',
		success: 'border-emerald-300 bg-emerald-50 text-emerald-900',
		warning: 'border-amber-300 bg-amber-50 text-amber-900'
	};
	const interactiveClass =
		'cursor-pointer transition-colors hover:brightness-95 focus-visible:outline focus-visible:outline-2 focus-visible:outline-[color:var(--primary)] focus-visible:outline-offset-2';
	const staticClass = 'cursor-default';
	const classes = $derived(
		`${baseClass} ${toneClassMap[tone]} ${interactive ? interactiveClass : staticClass} ${props.class ?? ''}`
	);
</script>

{#if props.onclick}
	<button
		type="button"
		class={classes}
		title={props.title}
		aria-label={props.ariaLabel}
		onclick={props.onclick}
	>
		{#if Icon}
			<Icon class="h-3 w-3 shrink-0" aria-hidden="true" />
		{/if}
		{@render props.children?.()}
	</button>
{:else}
	<span class={classes} title={props.title} aria-label={props.ariaLabel}>
		{#if Icon}
			<Icon class="h-3 w-3 shrink-0" aria-hidden="true" />
		{/if}
		{@render props.children?.()}
	</span>
{/if}
