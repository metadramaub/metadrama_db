<script lang="ts">
	import type { RangeConsistencyIssue } from '$lib/utils/range-consistency';

	const props = $props<{
		issues: RangeConsistencyIssue[];
		title?: string;
	}>();
</script>

{#if props.issues.length > 0}
	<section
		role="alert"
		class="border border-[color:var(--danger)] bg-red-50 px-4 py-3 text-sm text-red-950"
	>
		<p class="font-semibold">
			{props.title ?? `Hay ${props.issues.length} incoherencia${props.issues.length === 1 ? '' : 's'} de rango pendiente${props.issues.length === 1 ? '' : 's'} de corregir`}
		</p>
		<ul class="mt-2 list-disc space-y-1 pl-5">
			{#each props.issues as issue}
				<li>{issue.message}</li>
			{/each}
		</ul>
	</section>
{/if}
