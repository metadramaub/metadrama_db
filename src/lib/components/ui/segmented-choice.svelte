<script lang="ts">
	/**
	 * Grupo de opciones excluyentes visibles a la vez. Sustituye a un `<select>` cuando las
	 * alternativas son pocas y la decisión es de contenido: ver «abba» y «abab» uno al lado
	 * del otro cuesta menos que abrir un desplegable para elegir entre dos.
	 *
	 * Es el patrón que ya usaba el proyecto copiado a mano; aquí vive una sola vez.
	 */
	export type SegmentedItem = {
		id: string;
		label: string;
		/** Texto largo cuando la etiqueta va abreviada. */
		title?: string;
		disabled?: boolean;
	};

	const props = $props<{
		items: SegmentedItem[];
		value: string | null;
		onChange: (id: string | null) => void;
		ariaLabel: string;
		/** Volver a pulsar la opción activa la deselecciona. Para preguntas opcionales. */
		allowClear?: boolean;
		size?: 'sm' | 'md';
		disabled?: boolean;
		class?: string;
	}>();

	const size = $derived(props.size ?? 'md');
	const sizeClass = $derived(size === 'sm' ? 'px-2.5 py-1 text-xs' : 'px-3 py-1.5 text-sm');

	function select(item: SegmentedItem) {
		if (props.disabled || item.disabled) return;
		if (props.allowClear && props.value === item.id) {
			props.onChange(null);
			return;
		}
		props.onChange(item.id);
	}
</script>

<div class={`inline-flex flex-wrap ${props.class ?? ''}`} role="radiogroup" aria-label={props.ariaLabel}>
	{#each props.items as item (item.id)}
		{@const active = props.value === item.id}
		<button
			type="button"
			role="radio"
			aria-checked={active}
			title={item.title}
			disabled={props.disabled || item.disabled}
			class={`relative -ml-px border font-medium transition-colors first:ml-0 disabled:cursor-not-allowed disabled:opacity-40 ${sizeClass} ${
				active
					? 'z-10 border-[color:var(--primary)] bg-[color:var(--primary)] text-[color:var(--primary-foreground)]'
					: 'border-[color:var(--border)] bg-white text-[color:var(--muted-foreground)] hover:bg-[color:var(--muted)]'
			}`}
			onclick={() => select(item)}
		>
			{item.label}
		</button>
	{/each}
</div>
