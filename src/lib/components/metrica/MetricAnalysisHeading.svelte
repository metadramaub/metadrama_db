<script lang="ts">
	const props = $props<{
		id?: string;
		title: string;
		description: string;
	}>();
</script>

<div>
	<h2 id={props.id} class="text-lg font-semibold">{props.title}</h2>
	<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">{props.description}</p>
</div>
