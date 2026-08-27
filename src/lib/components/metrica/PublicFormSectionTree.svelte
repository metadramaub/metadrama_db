<script lang="ts">
	import type { PublicSection } from '$lib/metrica/formas-publicas.types';
	import InlineNotePopover from '$lib/components/ui/inline-note-popover.svelte';

	const { sections } = $props<{ sections: PublicSection[] }>();

	function repeticiones(seccion: PublicSection): string | null {
		const { repeticionesMin: min, repeticionesMax: max } = seccion;
		if (min == null && max == null) return null;
		if (min === 1 && max === 1) return null;
		if (min === 0 && max === 1) return 'opcional';
		if (min === 0 && max == null) return 'opcional · repetible';
		if (max == null) return `× ${min ?? 0} o más`;
		if (min === max) return `× ${min}`;
		return `× ${min ?? 0}–${max}`;
	}

	function versos(seccion: PublicSection): string | null {
		const { versosMin: min, versosMax: max } = seccion;
		if (min == null && max == null) return null;
		if (max == null) return `${min} o más versos`;
		if (min === max) return `${min} ${min === 1 ? 'verso' : 'versos'}`;
		return `de ${min} a ${max} versos`;
	}
</script>

{#snippet tree(items: PublicSection[], depth: number)}
	<ul
		class={depth === 0
			? 'mt-2 space-y-2 text-sm'
			: 'mt-2 ml-3 space-y-2 border-l border-[color:var(--border)] pl-3'}
	>
		{#each items as section (section.id)}
			<li>
				<span class={depth === 0 ? 'font-semibold' : 'font-medium'}>{section.nombre}</span>
				{#if versos(section) || repeticiones(section)}
					<span class="text-[color:var(--muted-foreground)]">
						· {[versos(section), repeticiones(section)]
							.filter(Boolean)
							.join(' · ')}
					</span>
				{/if}
				<!-- Una parte con nombre propio puede llevar el suyo: el eslabón de la estancia es
				     también la «chiave». Se lee igual que el «También» de una forma. -->
				{#if section.denominaciones.length > 0}
					<span class="text-[color:var(--muted-foreground)]">
						· también {section.denominaciones.join(' · ')}
					</span>
				{/if}
				{#if section.nota}
					<InlineNotePopover text={section.nota} label={`Mostrar nota sobre ${section.nombre}`} />
				{/if}
				<!-- La arquitectura reutilizada aporta la estructura de esa parte, incluida su medida
				     y su rima, y enlaza la ficha donde está declarada. -->
				{#if section.reutiliza}
					<span class="block text-[color:var(--muted-foreground)]">
						Se estructura como
						{#if section.reutiliza.slug}
							<a class="underline hover:no-underline" href="/recursos/catalogo-metrico/{section.reutiliza.slug}">
								{section.reutiliza.nombre}
							</a>
						{:else}
							{section.reutiliza.nombre}
						{/if}
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
