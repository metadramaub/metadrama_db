<script lang="ts">
	import Info from 'lucide-svelte/icons/info';

	const props = $props<{
		title?: string;
		items: Array<{ label: string; value: string }>;
		note: string;
		caution?: string;
	}>();
</script>

<section class="mt-4 border-t border-[color:var(--border)] pt-3" aria-label={props.title ?? 'Cómo leer los datos'}>
	<div class="flex items-start gap-2">
		<Info class="mt-0.5 h-3.5 w-3.5 shrink-0 text-[color:var(--primary)]" aria-hidden="true" />
		<div class="min-w-0 flex-1">
			<p class="text-[10px] font-semibold uppercase tracking-[0.14em] text-[color:var(--muted-foreground)]">
				{props.title ?? 'Cómo leerlo'}
			</p>
			<dl class="mt-2 grid gap-x-6 gap-y-2 sm:grid-cols-2 xl:grid-cols-3">
				{#each props.items as item (item.label)}
					<div>
						<dt class="text-[10px] uppercase tracking-wide text-[color:var(--muted-foreground)]">{item.label}</dt>
						<dd class="mt-0.5 text-xs font-semibold text-[color:var(--foreground)]">{item.value}</dd>
					</div>
				{/each}
			</dl>
			<p class="mt-2 max-w-4xl text-xs leading-5 text-[color:var(--muted-foreground)]">{props.note}</p>
			{#if props.caution}
				<p class="mt-1 text-xs leading-5 text-[color:var(--foreground)]">{props.caution}</p>
			{/if}
		</div>
	</div>
</section>
