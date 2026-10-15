<script lang="ts">
	import { TINTA } from '$lib/figuras/tema';
	import type { CantoMarker } from './barcode-canto';
	import { diagramaDeCanto } from './canto-diagrama';

	const { markers, desde, hasta, width, figure = false, x, y, onOpen } = $props<{
		markers: CantoMarker[]; desde: number; hasta: number; width: number;
		figure?: boolean; x?: number; y?: number;
		onOpen?: (id: string) => void;
	}>();
	const layout = $derived(diagramaDeCanto(markers, desde, hasta, width));
	let activeId = $state<string | null>(null);
	const active = $derived(layout.items.find((item) => item.id === activeId));
</script>

<svg {x} {y} width={width} height={layout.height} viewBox={`0 0 ${width} ${Math.max(1, layout.height)}`} style={figure ? 'overflow:visible' : 'width:100%;display:block;overflow:visible'} role="group" aria-label="Pasajes cantados">
	{#if layout.items.length}
		<line x1="0" x2={width} y1="12" y2="12" stroke={TINTA.guia} stroke-width="1" />
		{#each layout.items as item (item.id)}
			{@const centerY = 12}
			{#if !figure && activeId === item.id}
				<line x1={item.targetX} x2={item.targetX} y1={centerY + 5} y2={layout.height} stroke={TINTA.secundario} stroke-width="1" stroke-dasharray="2 2" pointer-events="none" />
			{/if}
			<rect x={item.drawStart} y={centerY - 3} width={item.drawWidth} height="6" rx="1" fill={TINTA.texto} stroke={TINTA.fondo} stroke-width="0.5" />
			<!-- Solo en pantalla el grupo actúa como botón y recibe foco. -->
			<!-- svelte-ignore a11y_no_noninteractive_tabindex -->
			<g
				role={figure ? undefined : 'button'}
				tabindex={figure ? undefined : 0}
				aria-label={`Cantado · ${item.label}. Abrir secuencia`}
				onclick={figure ? undefined : () => onOpen?.(item.secuencia_id)}
				onkeydown={figure ? undefined : (event) => { if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); onOpen?.(item.secuencia_id); } }}
				onpointerenter={figure ? undefined : () => (activeId = item.id)}
				onpointerleave={figure ? undefined : () => (activeId = null)}
				onfocus={figure ? undefined : () => (activeId = item.id)}
				onblur={figure ? undefined : () => (activeId = null)}
				style={figure ? undefined : 'cursor:pointer'}
			>
				<title>Cantado · {item.label}</title>
				<rect x={item.hitLeft} y={centerY - 7} width={Math.max(0, item.hitRight - item.hitLeft)} height="14" fill="transparent" />
			</g>
		{/each}
	{/if}
</svg>

{#if !figure && active}
	<div class="pointer-events-none absolute z-50 w-max max-w-full border border-[color:var(--border)] bg-white px-2 py-1 text-xs shadow-sm" style={`left:${Math.max(0, Math.min(width - 180, active.targetX))}px;top:-18px;`}>
		Cantado · {active.label}
	</div>
{/if}
