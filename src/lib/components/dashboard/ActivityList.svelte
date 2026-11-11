<script lang="ts">
	import type { DashboardNotificationItem } from '$lib/server/dashboard';
	import { formatRelative } from '$lib/utils/formatters';
	import DashboardLinkRow from './DashboardLinkRow.svelte';
	let { items, empty }: { items: DashboardNotificationItem[]; empty: string } = $props();
</script>

{#if items.length}
	<ul class="divide-y divide-[color:var(--border)] text-sm">
		{#each items as item (item.id)}
			<li>
				<DashboardLinkRow href={item.targetUrl ?? `/dashboard/obras/${item.obraId}?tab=${item.tab}`}>
					<p class="font-medium">{item.obraTitulo}</p>
					<p class="text-xs text-[color:var(--muted-foreground)]">{item.description}</p>
					{#snippet detail()}
						<time datetime={item.eventAt ?? undefined} class="shrink-0 text-xs text-[color:var(--muted-foreground)]">{formatRelative(item.eventAt)}</time>
					{/snippet}
				</DashboardLinkRow>
			</li>
		{/each}
	</ul>
{:else}
	<p class="py-3 text-sm text-[color:var(--muted-foreground)]">{empty}</p>
{/if}
