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
	class={`w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm text-[color:var(--foreground)] disabled:bg-[color:var(--muted)] ${props.class ?? ''}`}
	rows={props.rows ?? 4}
	placeholder={props.placeholder}
	required={props.required}
	disabled={props.disabled}
>{props.value ?? ''}</textarea>
