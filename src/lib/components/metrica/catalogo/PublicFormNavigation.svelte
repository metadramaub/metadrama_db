<script lang="ts">
	type NavigationItem = {
		href: string;
		label: string;
	};

	const { items } = $props<{ items: NavigationItem[] }>();
</script>

<nav aria-label="Secciones de la ficha">
	<p
		class="hidden text-[0.68rem] font-semibold uppercase tracking-[0.09em] text-[color:var(--muted-foreground)] lg:block"
	>
		En esta ficha
	</p>
	<ul
		class="grid grid-cols-4 border-y border-[color:var(--border)] bg-[color:var(--background)] py-2 lg:mt-3 lg:block lg:border-y-0 lg:border-l lg:bg-transparent lg:py-0"
	>
		{#each items as item (item.href)}
			<li>
				<a
					href={item.href}
					class="block px-1 py-2 text-center text-xs text-[color:var(--muted-foreground)] transition-colors hover:bg-[color:var(--gray-50)] hover:text-[color:var(--foreground)] lg:-ml-px lg:border-l lg:border-transparent lg:px-3 lg:py-2.5 lg:text-left lg:text-sm lg:hover:border-[color:var(--gray-500)]"
				>
					{item.label}
				</a>
			</li>
		{/each}
	</ul>
</nav>
