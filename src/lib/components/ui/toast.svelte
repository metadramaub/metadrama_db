<script lang="ts">
	import { dismissToast, runToastAction, toastStore } from '$lib/stores/toast';
</script>

<div class="pointer-events-none fixed bottom-4 right-4 z-50 flex w-96 max-w-[90vw] flex-col gap-2">
	{#each $toastStore as item (item.id)}
		<div
			class={`pointer-events-auto border px-3 py-2 text-left text-sm ${
				item.type === 'success'
					? 'border-emerald-700 bg-emerald-50 text-emerald-900'
					: item.type === 'error'
						? 'border-rose-700 bg-rose-50 text-rose-900'
						: 'border-[color:var(--border)] bg-white text-[color:var(--foreground)]'
			}`}
		>
			<div class="flex items-center justify-between gap-2">
				<button type="button" class="flex-1 text-left" onclick={() => dismissToast(item.id)}>
					{item.message}
				</button>
				{#if item.actionLabel && item.onAction}
					<button
						type="button"
						class="shrink-0 border border-current px-2 py-1 text-xs font-medium hover:opacity-80"
						onclick={() => runToastAction(item.id)}
					>
						{item.actionLabel}
					</button>
				{/if}
			</div>
		</div>
	{/each}
</div>
