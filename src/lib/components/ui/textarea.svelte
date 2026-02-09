<script lang="ts">
	const props = $props<{
		value?: string | null;
		class?: string;
		rows?: number;
		placeholder?: string;
		required?: boolean;
		disabled?: boolean;
	}>();
</script>

<textarea
	class={`w-full rounded-md border border-[color:var(--border)] bg-white px-3 py-2 text-sm ${props.class ?? ''}`}
	rows={props.rows ?? 4}
	placeholder={props.placeholder}
	required={props.required}
	disabled={props.disabled}
>{props.value ?? ''}</textarea>
