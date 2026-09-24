<script lang="ts">
	// Pestañas: texto sobre una línea, y la activa subrayada en dorado, como el menú de la web.
	//
	// **No son cajas.** Eran botones con borde y la activa rellena de dorado, y debajo, en la ficha,
	// venían los selectores negros de «Obra completa / Por jornadas»: dos niveles de cajas seguidos
	// que competían por la atención. Las cajas negras rellenas son el lenguaje de los controles; la
	// navegación entre pestañas habla como el menú.
	import type { Snippet } from 'svelte';

	const props = $props<{
		tabs: { id: string; label: string }[];
		active: string;
		onChange: (id: string) => void;
		actions?: Snippet;
	}>();
</script>

<div class="flex flex-wrap items-end gap-x-6 gap-y-2 border-b border-[color:var(--border)]">
	<div class="flex flex-wrap gap-x-6" role="tablist">
		{#each props.tabs as tab (tab.id)}
			{@const activa = props.active === tab.id}
			<button
				type="button"
				role="tab"
				aria-selected={activa}
				class={`-mb-px border-b-2 py-2 text-sm transition-colors ${
					activa
						? 'border-[color:var(--primary)] font-semibold text-[color:var(--gray-900)]'
						: 'border-transparent text-[color:var(--muted-foreground)] hover:border-[color:var(--gray-300)] hover:text-[color:var(--gray-900)]'
				}`}
				onclick={() => props.onChange(tab.id)}
			>
				{tab.label}
			</button>
		{/each}
	</div>

	{#if props.actions}
		<div class="ml-auto pb-2">
			{@render props.actions()}
		</div>
	{/if}
</div>
