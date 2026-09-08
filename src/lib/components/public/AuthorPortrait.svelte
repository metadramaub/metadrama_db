<script lang="ts">
	const FALLBACK_SRC = '/images/autores/sin-retrato.webp';

	const props = $props<{
		src?: string | null;
		alt: string;
		class?: string;
	}>();

	let failedSrc = $state<string | null>(null);
	const displayedSrc = $derived(
		props.src && props.src !== failedSrc ? props.src : FALLBACK_SRC
	);

	function useFallback() {
		if (displayedSrc !== FALLBACK_SRC) failedSrc = displayedSrc;
	}
</script>

<img
	src={displayedSrc}
	alt={props.alt}
	class={props.class ?? 'h-full w-full object-cover'}
	loading="lazy"
	referrerpolicy="no-referrer"
	onerror={useFallback}
/>
