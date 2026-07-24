<script lang="ts">
	const props = $props<{
		value: boolean | null;
		ariaLabel: string;
		disabled?: boolean;
		onChange?: (value: boolean | null) => void;
	}>();

	const options: Array<{ label: string; value: boolean | null }> = [
		{ label: 'Pendiente', value: null },
		{ label: 'No', value: false },
		{ label: 'Sí', value: true }
	];

	function isSelected(value: boolean | null) {
		return props.value === value;
	}

	function optionClass(value: boolean | null) {
		if (!isSelected(value)) {
			return 'border-[color:var(--border)] bg-white text-[color:var(--muted-foreground)] hover:bg-[color:var(--muted)]';
		}
		if (value === null) {
			return 'z-10 border-[color:var(--gray-500)] bg-[color:var(--gray-100)] text-[color:var(--gray-900)]';
		}
		return 'z-10 border-[color:var(--primary)] bg-[color:var(--primary)] text-[color:var(--primary-foreground)]';
	}
</script>

<div class="inline-flex" role="radiogroup" aria-label={props.ariaLabel}>
	{#each options as option}
		<button
			type="button"
			role="radio"
			aria-checked={isSelected(option.value)}
			disabled={props.disabled}
			class={`relative -ml-px border px-3 py-1.5 text-sm font-medium transition-colors first:ml-0 disabled:cursor-not-allowed disabled:opacity-60 ${optionClass(option.value)}`}
			onclick={() => props.onChange?.(option.value)}
		>
			{option.label}
		</button>
	{/each}
</div>
