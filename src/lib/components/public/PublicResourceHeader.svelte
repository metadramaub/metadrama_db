<script lang="ts">
	import type { Snippet } from 'svelte';
	import CircleHelp from 'lucide-svelte/icons/circle-help';
	import PublicPageHeader from './PublicPageHeader.svelte';

	const props = $props<{
		category: string;
		title: string;
		badge?: string;
		description: Snippet;
		onHelp: () => void;
	}>();
</script>

{#snippet helpAction()}
	<button
		type="button"
		class="inline-flex items-center gap-2 border border-[color:var(--border)] bg-white px-4 py-2 text-sm font-semibold transition-colors hover:border-[color:var(--gray-800)]"
		onclick={props.onHelp}
	>
		<CircleHelp size={16} aria-hidden="true" />
		Ayuda
	</button>
{/snippet}

<PublicPageHeader
	eyebrow={props.category.toUpperCase()}
	title={props.title}
	badge={props.badge}
	descriptionContent={props.description}
	actions={helpAction}
/>
