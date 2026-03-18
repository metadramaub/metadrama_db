<script lang="ts">
	import { tick } from 'svelte';

	const props = $props<{
		text: string;
		label?: string;
	}>();

	let rootEl: HTMLSpanElement | null = null;
	let bubbleEl: HTMLSpanElement | null = null;
	let isOpen = $state(false);
	let side = $state<'top' | 'bottom'>('top');
	let leftPx = $state(0);
	let topPx = $state(0);

	const viewportPadding = 8;
	const tooltipGap = 6;

	function updatePosition() {
		if (!rootEl || !bubbleEl) return;

		const triggerRect = rootEl.getBoundingClientRect();
		const bubbleWidth = bubbleEl.offsetWidth;
		const bubbleHeight = bubbleEl.offsetHeight;

		const desiredLeft = triggerRect.left + triggerRect.width / 2 - bubbleWidth / 2;
		const minLeft = viewportPadding;
		const maxLeft = window.innerWidth - viewportPadding - bubbleWidth;

		if (maxLeft < minLeft) {
			leftPx = minLeft;
		} else {
			leftPx = Math.min(Math.max(desiredLeft, minLeft), maxLeft);
		}

		const topIfAbove = triggerRect.top - tooltipGap - bubbleHeight;
		const topIfBelow = triggerRect.bottom + tooltipGap;
		const canPlaceAbove = topIfAbove >= viewportPadding;
		const canPlaceBelow = topIfBelow + bubbleHeight <= window.innerHeight - viewportPadding;

		side = canPlaceAbove || !canPlaceBelow ? 'top' : 'bottom';

		const preferredTop = side === 'top' ? topIfAbove : topIfBelow;
		const minTop = viewportPadding;
		const maxTop = window.innerHeight - viewportPadding - bubbleHeight;
		topPx = maxTop < minTop ? minTop : Math.min(Math.max(preferredTop, minTop), maxTop);
	}

	async function openTooltip() {
		isOpen = true;
		await tick();
		updatePosition();
	}

	function closeTooltip() {
		isOpen = false;
	}

	function onFocusOut(event: FocusEvent) {
		const currentTarget = event.currentTarget as HTMLElement | null;
		const nextTarget = event.relatedTarget as Node | null;
		if (!currentTarget?.contains(nextTarget)) {
			closeTooltip();
		}
	}

	$effect(() => {
		if (!isOpen) return;

		const syncPosition = () => updatePosition();
		window.addEventListener('resize', syncPosition);
		window.addEventListener('scroll', syncPosition, true);

		return () => {
			window.removeEventListener('resize', syncPosition);
			window.removeEventListener('scroll', syncPosition, true);
		};
	});
</script>

<span
	class={`field-help-tooltip ${isOpen ? 'is-open' : ''}`}
	role="group"
	data-side={side}
	style={`--tooltip-left: ${leftPx}px; --tooltip-top: ${topPx}px;`}
	bind:this={rootEl}
	onmouseenter={() => void openTooltip()}
	onmouseleave={closeTooltip}
	onfocusin={() => void openTooltip()}
	onfocusout={onFocusOut}
>
	<button
		type="button"
		class="field-help-trigger"
		aria-label={props.label ?? 'Mostrar ayuda del campo'}
	>
		?
	</button>
	<span class="field-help-bubble" role="tooltip" bind:this={bubbleEl}>{props.text}</span>
</span>

<style>
	.field-help-tooltip {
		position: relative;
		display: inline-flex;
		align-items: center;
	}

	.field-help-trigger {
		display: inline-flex;
		height: 1rem;
		width: 1rem;
		align-items: center;
		justify-content: center;
		border: 1px solid var(--border);
		background: var(--muted);
		color: var(--muted-foreground);
		font-size: 0.65rem;
		font-weight: 700;
		line-height: 1;
		padding: 0;
		cursor: help;
	}

	.field-help-trigger:focus-visible {
		outline: 1px solid var(--primary);
		outline-offset: 1px;
	}

	.field-help-bubble {
		position: fixed;
		left: var(--tooltip-left, 0px);
		top: var(--tooltip-top, 0px);
		z-index: 30;
		min-width: 13rem;
		max-width: min(18rem, calc(100vw - 1rem));
		border: 1px solid var(--border);
		background: white;
		padding: 0.45rem 0.55rem;
		color: var(--foreground);
		font-size: 0.75rem;
		font-weight: 400;
		line-height: 1.3;
		letter-spacing: normal;
		text-transform: none;
		white-space: normal;
		box-shadow: 0 6px 18px rgb(0 0 0 / 10%);
		opacity: 0;
		visibility: hidden;
		pointer-events: none;
		transition: opacity 120ms ease;
	}

	.field-help-tooltip.is-open .field-help-bubble {
		opacity: 1;
		visibility: visible;
	}
</style>
