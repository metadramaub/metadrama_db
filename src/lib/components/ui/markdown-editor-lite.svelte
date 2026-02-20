<script lang="ts">
	import { renderMarkdown } from '$lib/utils/markdown';

	const props = $props<{
		value?: string | null;
		disabled?: boolean;
		rows?: number;
		placeholder?: string;
		class?: string;
		minHeightClass?: string;
		toolbarCompact?: boolean;
		showPreviewToggle?: boolean;
		onChange?: (value: string) => void;
	}>();

	let preview = $state(false);
	let textareaRef = $state<HTMLTextAreaElement | null>(null);

	const currentValue = $derived(props.value ?? '');
	const isDisabled = $derived(Boolean(props.disabled));
	const minHeightClass = $derived(props.minHeightClass ?? 'min-h-28');
	const toolbarCompact = $derived(props.toolbarCompact ?? true);
	const showPreviewToggle = $derived(props.showPreviewToggle ?? true);
	const toolbarButtonClass = $derived(
		toolbarCompact
			? 'h-7 min-w-7 px-2 py-1 text-xs leading-none'
			: 'px-3 py-1.5 text-sm leading-none'
	);
	const previewToggleClass = $derived(
		toolbarCompact
			? 'ml-auto h-7 px-2 py-1 text-xs leading-none'
			: 'ml-auto px-3 py-1.5 text-sm leading-none'
	);

	$effect(() => {
		if (!showPreviewToggle && preview) {
			preview = false;
		}
	});

	function emitChange(nextValue: string) {
		props.onChange?.(nextValue);
	}

	function applyFormat(prefix: string, suffix = prefix) {
		if (isDisabled) return;
		const current = currentValue;
		const input = textareaRef;
		if (!input) {
			emitChange(`${current}${prefix}${suffix}`);
			return;
		}

		const start = input.selectionStart ?? current.length;
		const end = input.selectionEnd ?? start;
		const selected = current.slice(start, end);
		const nextValue = `${current.slice(0, start)}${prefix}${selected}${suffix}${current.slice(end)}`;
		emitChange(nextValue);

		requestAnimationFrame(() => {
			const activeInput = textareaRef;
			if (!activeInput) return;
			const cursor = end + prefix.length + suffix.length;
			activeInput.focus();
			activeInput.setSelectionRange(cursor, cursor);
		});
	}
</script>

<div
	class={`overflow-hidden rounded-md border border-[color:var(--border)] bg-white ${
		isDisabled ? 'bg-[color:var(--muted)]' : ''
	} ${props.class ?? ''}`}
>
	<div class="flex flex-wrap items-center gap-1 border-b border-[color:var(--border)] bg-[color:var(--muted)] px-2 py-1">
		<button
			type="button"
			class={`inline-flex items-center justify-center rounded border border-[color:var(--border)] bg-white text-[color:var(--foreground)] transition-colors hover:bg-[color:var(--gray-100)] disabled:cursor-not-allowed disabled:opacity-50 ${toolbarButtonClass}`}
			title="Negrita"
			disabled={isDisabled || preview}
			onclick={() => applyFormat('**', '**')}
		>
			B
		</button>
		<button
			type="button"
			class={`inline-flex items-center justify-center rounded border border-[color:var(--border)] bg-white text-[color:var(--foreground)] transition-colors hover:bg-[color:var(--gray-100)] disabled:cursor-not-allowed disabled:opacity-50 ${toolbarButtonClass}`}
			title="Cursiva"
			disabled={isDisabled || preview}
			onclick={() => applyFormat('*', '*')}
		>
			I
		</button>
		<button
			type="button"
			class={`inline-flex items-center justify-center rounded border border-[color:var(--border)] bg-white text-[color:var(--foreground)] transition-colors hover:bg-[color:var(--gray-100)] disabled:cursor-not-allowed disabled:opacity-50 ${toolbarButtonClass}`}
			title="Lista"
			disabled={isDisabled || preview}
			onclick={() => applyFormat('\n- ', '')}
		>
			&bull;
		</button>
		<button
			type="button"
			class={`inline-flex items-center justify-center rounded border border-[color:var(--border)] bg-white text-[color:var(--foreground)] transition-colors hover:bg-[color:var(--gray-100)] disabled:cursor-not-allowed disabled:opacity-50 ${toolbarButtonClass}`}
			title="Enlace"
			disabled={isDisabled || preview}
			onclick={() => applyFormat('[', '](https://)')}
		>
			&#8599;
		</button>
		<button
			type="button"
			class={`inline-flex items-center justify-center rounded border border-[color:var(--border)] bg-white text-[color:var(--foreground)] transition-colors hover:bg-[color:var(--gray-100)] disabled:cursor-not-allowed disabled:opacity-50 ${toolbarButtonClass}`}
			title="Encabezado 1"
			disabled={isDisabled || preview}
			onclick={() => applyFormat('\n# ', '')}
		>
			H1
		</button>
		<button
			type="button"
			class={`inline-flex items-center justify-center rounded border border-[color:var(--border)] bg-white text-[color:var(--foreground)] transition-colors hover:bg-[color:var(--gray-100)] disabled:cursor-not-allowed disabled:opacity-50 ${toolbarButtonClass}`}
			title="Encabezado 2"
			disabled={isDisabled || preview}
			onclick={() => applyFormat('\n## ', '')}
		>
			H2
		</button>

		{#if showPreviewToggle}
			<button
				type="button"
				class={`inline-flex items-center justify-center rounded border border-[color:var(--border)] bg-[color:var(--gray-100)] text-[color:var(--foreground)] transition-colors hover:bg-[color:var(--gray-200)] disabled:cursor-not-allowed disabled:opacity-50 ${previewToggleClass}`}
				title={preview ? 'Editar' : 'Vista previa'}
				onclick={() => (preview = !preview)}
			>
				{preview ? 'Editar' : 'Vista previa'}
			</button>
		{/if}
	</div>

	{#if preview}
		<div
			class={`prose prose-sm max-w-none px-3 py-2 text-sm ${
				isDisabled ? 'text-[color:var(--muted-foreground)]' : ''
			} ${minHeightClass}`}
			style="--tw-prose-body: var(--foreground);"
		>
			{#if currentValue.trim()}
				{@html renderMarkdown(currentValue)}
			{:else}
				<p class="text-[color:var(--muted-foreground)]">Sin contenido.</p>
			{/if}
		</div>
	{:else}
		<textarea
			bind:this={textareaRef}
			rows={props.rows ?? 4}
			placeholder={props.placeholder}
			value={currentValue}
			disabled={isDisabled}
			class={`w-full resize-y border-0 bg-transparent px-3 py-2 text-sm outline-none disabled:cursor-not-allowed ${minHeightClass}`}
			oninput={(event) => emitChange(event.currentTarget.value)}
		></textarea>
	{/if}
</div>
