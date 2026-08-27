<script lang="ts">
	const props = $props<{
		id: string;
		label: string;
		options: Array<{ value: string; label: string }>;
		selected: string | null;
		onSelect: (value: string | null) => void;
	}>();

	function optionClass(active: boolean): string {
		return `border-b py-1 text-sm leading-5 transition-colors focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[color:var(--primary)] ${
			active
				? 'border-[color:var(--primary)] font-semibold text-[color:var(--foreground)]'
				: 'border-transparent text-[color:var(--muted-foreground)] hover:border-[color:var(--gray-300)] hover:text-[color:var(--foreground)]'
		}`;
	}
</script>

<div
	class="flex flex-col gap-1 sm:flex-row sm:items-baseline sm:gap-4"
	role="group"
	aria-labelledby={props.id}
>
	<span
		id={props.id}
		class="text-[0.68rem] font-semibold uppercase tracking-[0.07em] text-[color:var(--muted-foreground)] sm:w-24 sm:shrink-0"
	>
		{props.label}
	</span>
	<div class="flex flex-wrap items-baseline gap-x-2 gap-y-0.5">
		<button
			type="button"
			class={optionClass(props.selected === null)}
			aria-pressed={props.selected === null}
			onclick={() => props.onSelect(null)}
		>
			Todas
		</button>
		{#each props.options as option (option.value)}
			<span class="text-[color:var(--gray-300)]" aria-hidden="true">·</span>
			<button
				type="button"
				class={optionClass(props.selected === option.value)}
				aria-pressed={props.selected === option.value}
				onclick={() => props.onSelect(option.value)}
			>
				{option.label}
			</button>
		{/each}
	</div>
</div>
