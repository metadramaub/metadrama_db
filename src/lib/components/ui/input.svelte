<script lang="ts">
	const props = $props<{
		type?: string;
		value?: string | number | null;
		class?: string;
		placeholder?: string;
		required?: boolean;
		disabled?: boolean;
		min?: number;
		max?: number;
		step?: number;
	}>();
</script>

<input
	type={props.type ?? 'text'}
	value={props.value ?? ''}
	class={`w-full rounded-md border border-[color:var(--border)] bg-white px-3 py-2 text-sm ${props.class ?? ''}`}
	placeholder={props.placeholder}
	required={props.required}
	disabled={props.disabled}
	min={props.min}
	max={props.max}
	step={props.step}
/>
