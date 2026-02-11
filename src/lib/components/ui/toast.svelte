<script lang="ts">
	import { dismissToast, runToastAction, toastStore } from '$lib/stores/toast';
</script>

<div class="pointer-events-none fixed bottom-4 right-4 z-50 flex w-96 max-w-[90vw] flex-col gap-2">
	{#each $toastStore as item (item.id)}
		<div
			class={`pointer-events-auto rounded-md border px-3 py-2 text-left text-sm shadow ${
				item.type === 'success'
					? 'border-emerald-200 bg-emerald-50 text-emerald-900'
					: item.type === 'error'
						? 'border-rose-200 bg-rose-50 text-rose-900'
						: 'border-slate-200 bg-white text-slate-900'
			}`}
		>
			<div class="flex items-center justify-between gap-2">
				<button type="button" class="flex-1 text-left" onclick={() => dismissToast(item.id)}>
					{item.message}
				</button>
				{#if item.actionLabel && item.onAction}
					<button
						type="button"
						class="shrink-0 rounded border border-current px-2 py-1 text-xs font-medium hover:opacity-80"
						onclick={() => runToastAction(item.id)}
					>
						{item.actionLabel}
					</button>
				{/if}
			</div>
		</div>
	{/each}
</div>
