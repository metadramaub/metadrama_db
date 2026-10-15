<script lang="ts">
	import { TINTA } from '$lib/figuras/tema';
	const { x, y, size = 16, color = TINTA.texto } = $props<{ x?: number; y?: number; size?: number; color?: string }>();
</script>

<svg {x} {y} width={size} height={size} viewBox="0 0 16 16" aria-hidden="true">
	<path d="M6 12V3L13 1V10M6 5L13 3" fill="none" stroke={color} stroke-width="1.5" stroke-linejoin="round" />
	<ellipse cx="3.8" cy="12.5" rx="2.7" ry="1.9" fill={color} transform="rotate(-20 3.8 12.5)" />
	<ellipse cx="10.8" cy="10.5" rx="2.7" ry="1.9" fill={color} transform="rotate(-20 10.8 10.5)" />
</svg>
