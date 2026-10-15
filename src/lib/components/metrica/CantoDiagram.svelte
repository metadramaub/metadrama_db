<script lang="ts">
	import MusicNote from './MusicNote.svelte';
	import { TINTA } from '$lib/figuras/tema';
	import type { CantoMarker } from './barcode-canto';
	import { diagramaDeCanto, type CantoStyle } from './canto-diagrama';

	const { markers, desde, hasta, width, style = 'pista', figure = false, x, y, onOpen } = $props<{
		markers: CantoMarker[]; desde: number; hasta: number; width: number;
		style?: CantoStyle; figure?: boolean; x?: number; y?: number;
		onOpen?: (id: string) => void;
	}>();
	const layout = $derived(diagramaDeCanto(markers, desde, hasta, width, style, figure));
	let selected = $state<string | null>(null);
	const selectedGroup = $derived(layout.groups.find((g) => g.id === selected));
	const clamp = (point: number) => Math.max(9, Math.min(width - 9, point));
	function activate(group: (typeof layout.groups)[number]) {
		if (group.items.length === 1) onOpen?.(group.items[0].secuencia_id);
		else selected = selected === group.id ? null : group.id;
	}
</script>

<svg {x} {y} width={width} height={layout.height} viewBox={`0 0 ${width} ${Math.max(1, layout.height)}`} style={figure ? 'overflow:visible' : 'width:100%;display:block;overflow:visible'} role="group" aria-label="Pasajes cantados">
	{#if figure && layout.groups.length}
		<MusicNote x={1} y={1} size={13} />
		<text x="21" y="12" font-size="11" font-family="sans-serif" fill={TINTA.secundario}>Pasajes cantados</text>
	{/if}
	{#each layout.captions as caption, index (index)}
		<text x={caption.x} y={caption.y} font-size="11" font-family="sans-serif" fill={TINTA.secundario}>{caption.text}</text>
	{/each}
	{#if layout.groups.length}
		{#if style === 'abanico'}
			{#each layout.groups as group (group.id)}
				{#each group.items as item (item.id)}
					<path d={`M${width / 2} ${layout.captionHeight + 22} Q${width / 2} ${layout.height - 24} ${item.targetX} ${layout.height - 3} m-2 -4 l2 4 l2 -4`} fill="none" stroke={TINTA.secundario} stroke-width="0.8" opacity="0.7" />
				{/each}
			{/each}
			<rect x={width / 2 - 35} y={layout.captionHeight + 1} width="70" height="23" rx="11" fill={TINTA.fondo} stroke={TINTA.guia} />
			<MusicNote x={width / 2 - 26} y={layout.captionHeight + 5} size={14} />
			<text x={width / 2 - 6} y={layout.captionHeight + 17} font-size="12" font-family="sans-serif" fill={TINTA.texto}>Canto</text>
		{:else if style === 'pista'}
			<line x1="0" x2={width} y1={layout.height - 17} y2={layout.height - 17} stroke={TINTA.guia} stroke-width="1" />
			{#each layout.groups as group (group.id)}
				{#each group.items as item (item.id)}
					{@const start = (item.v_ini - desde) / Math.max(1, hasta - desde + 1) * width}
					{@const length = Math.max(3, (item.v_fin - item.v_ini + 1) / Math.max(1, hasta - desde + 1) * width)}
					<rect x={Math.min(width - length, start)} y={layout.height - 20} width={length} height="6" rx="1" fill={TINTA.texto} />
				{/each}
			{/each}
		{:else}
			{#each layout.groups as group (group.id)}
				<path d={`M${clamp(group.x)} ${layout.height - 30} L${group.x} ${layout.height - 3}`} fill="none" stroke={TINTA.secundario} stroke-width="1" />
			{/each}
		{/if}
		{#each layout.groups as group, index (group.id)}
			{@const center = clamp(group.x)}
			{@const top = style === 'abanico' ? layout.height - 28 : layout.height - 43}
			{@const hitLeft = Math.max(0, Math.min(center - 11, ...group.items.map((i) => (i.v_ini - desde) / Math.max(1, hasta - desde + 1) * width)))}
			{@const hitRight = Math.min(width, Math.max(center + 11, ...group.items.map((i) => (i.v_fin + 1 - desde) / Math.max(1, hasta - desde + 1) * width)))}
			<!-- En pantalla es un botón SVG; en la figura pierde el rol, el foco y los manejadores. -->
			<!-- svelte-ignore a11y_no_noninteractive_tabindex -->
			<g
				role={figure ? undefined : 'button'}
				tabindex={figure ? undefined : 0}
				aria-label={`Cantado · ${group.items.map((i) => i.label).join('; ')}${group.items.length > 1 ? '. Mostrar pasajes' : '. Abrir secuencia'}`}
				onclick={figure ? undefined : () => activate(group)}
				onkeydown={figure ? undefined : (event) => { if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); activate(group); } }}
				style={figure ? undefined : 'cursor:pointer'}
			>
				<title>Cantado · {group.items.map((i) => i.label).join('; ')}</title>
				<rect x={hitLeft} y={top} width={hitRight - hitLeft} height={layout.height - top} rx="3" fill="transparent" />
				{#if figure || group.items.length > 1}
					<rect x={center - 8} y={top + 3} width="16" height="16" rx="8" fill={TINTA.fondo} stroke={TINTA.secundario} />
					<text x={center} y={top + 14} text-anchor="middle" font-size="10" font-family="sans-serif" fill={TINTA.texto}>{figure ? index + 1 : group.items.length}</text>
				{:else if style === 'grupos'}
					<circle cx={center} cy={top + 12} r="3" fill={TINTA.texto} />
				{/if}
			</g>
		{/each}
	{/if}
</svg>

{#if !figure && selectedGroup}
	<div class="absolute left-0 right-0 z-50 max-h-60 overflow-auto border border-[color:var(--border)] bg-white p-3 text-xs shadow-sm" style={`top:${layout.height}px;`}>
		<div class="mb-2 flex items-center justify-between gap-3">
			<span>Pasajes cantados</span>
			<button type="button" aria-label="Cerrar pasajes cantados" onclick={() => (selected = null)}>Cerrar</button>
		</div>
		<div class="flex flex-wrap gap-2">
			{#each selectedGroup.items as item (item.id)}
				<button type="button" class="border border-[color:var(--border)] px-2 py-1 hover:bg-[color:var(--muted)]" onclick={() => { selected = null; onOpen?.(item.secuencia_id); }}>{item.label}</button>
			{/each}
		</div>
	</div>
{/if}
