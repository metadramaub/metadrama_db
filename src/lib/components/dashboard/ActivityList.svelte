<script lang="ts">
	import type { DashboardNotificationItem } from '$lib/server/dashboard';
	import { formatRelative } from '$lib/utils/formatters';
	let { items, empty }: { items: DashboardNotificationItem[]; empty: string } = $props();
</script>

{#if items.length}
	<ul class="divide-y divide-[color:var(--border)] text-sm">
		{#each items as item (item.id)}
			<li class="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1 py-3">
				<div class="min-w-0">
					<a class="font-medium underline-offset-2 hover:underline"
						href={item.targetUrl ?? `/dashboard/obras/${item.obraId}?tab=${item.tab}`}>
						{item.obraTitulo}
					</a>
					<p class="text-xs text-[color:var(--muted-foreground)]">{item.description}</p>
				</div>
				<time datetime={item.eventAt ?? undefined} class="text-xs text-[color:var(--muted-foreground)]">{formatRelative(item.eventAt)}</time>
			</li>
		{/each}
	</ul>
{:else}
	<p class="py-3 text-sm text-[color:var(--muted-foreground)]">{empty}</p>
{/if}
