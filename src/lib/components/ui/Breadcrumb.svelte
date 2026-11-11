<script lang="ts">
	// Breadcrumb reutilizable para toda la web (pública y dashboard).
	// Estilo: separador " / ", mayúsculas con tracking, color suave (muted).
	// Cada paso con href es clicable; el paso actual (sin href) va subrayado
	// como los enlaces activos del menú superior.
	export interface BreadcrumbItem {
		label: string;
		href?: string;
		/** Mantener el texto tal cual (no forzar mayúsculas), p.ej. títulos de obra. */
		preserveCase?: boolean;
	}

	const props = $props<{
		items: BreadcrumbItem[];
		/** Etiqueta accesible del nav. */
		ariaLabel?: string;
	}>();

	function display(item: BreadcrumbItem): string {
		return item.preserveCase ? item.label : item.label.toUpperCase();
	}
</script>

<nav
	class="flex flex-wrap items-center gap-x-2 gap-y-1 text-xs font-semibold tracking-[0.08em] text-[color:var(--muted-foreground)]"
	aria-label={props.ariaLabel ?? 'Migas de pan'}
>
	{#each props.items as item, index (item.href ?? item.label + index)}
		{#if index > 0}
			<span class="select-none text-[color:var(--muted-foreground)]" aria-hidden="true">/</span>
		{/if}

		{#if item.href && index < props.items.length - 1}
			<a
				href={item.href}
				class="border-b border-transparent pb-0.5 transition-colors hover:text-[color:var(--foreground)]"
			>
				{display(item)}
			</a>
		{:else}
			<span
				class="border-b border-[color:var(--primary)] pb-0.5 text-[color:var(--foreground)]"
				aria-current="page"
			>
				{display(item)}
			</span>
		{/if}
	{/each}
</nav>
