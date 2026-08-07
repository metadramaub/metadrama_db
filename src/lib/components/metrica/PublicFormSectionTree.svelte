<script lang="ts">
	import type { PublicSection } from '$lib/metrica/formas-publicas.types';
	import { renderInlineMarkdown } from '$lib/utils/markdown';

	const { sections } = $props<{ sections: PublicSection[] }>();

	function repeticiones(seccion: PublicSection): string | null {
		const { repeticionesMin: min, repeticionesMax: max } = seccion;
		if (min == null && max == null) return null;
		if (max == null) return `${min ?? 0} o más`;
		if (min === max) return String(min);
		return `de ${min ?? 0} a ${max}`;
	}

	function versos(seccion: PublicSection): string | null {
		const { versosMin: min, versosMax: max } = seccion;
		if (min == null && max == null) return null;
		if (max == null) return `${min} o más versos`;
		if (min === max) return `${min} versos`;
		return `de ${min} a ${max} versos`;
	}
</script>

{#snippet tree(items: PublicSection[], depth: number)}
	<ul class={depth === 0 ? 'mt-2 space-y-2 text-sm' : 'mt-2 ml-3 space-y-2 border-l border-[color:var(--border)] pl-3'}>
		{#each items as section (section.id)}
			<li>
				<span class="font-medium">{section.nombre}</span>
				{#if versos(section) || repeticiones(section)}
					<span class="text-[color:var(--muted-foreground)]">
						· {[versos(section), repeticiones(section) ? `×${repeticiones(section)}` : null]
							.filter(Boolean)
							.join(' ')}
					</span>
				{/if}
				{#if section.nota}
					<span class="block text-[color:var(--muted-foreground)]">
						{@html renderInlineMarkdown(section.nota)}
					</span>
				{/if}
				{#if section.hijas.length > 0}
					{@render tree(section.hijas, depth + 1)}
				{/if}
			</li>
		{/each}
	</ul>
{/snippet}

{@render tree(sections, 0)}
