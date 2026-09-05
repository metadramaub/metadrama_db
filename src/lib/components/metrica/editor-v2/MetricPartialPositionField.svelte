<script lang="ts">
	/**
	 * Qué versos de la unidad se quiebran, y de qué medida.
	 *
	 * **Esto era una rejilla de dos pasos.** Cada verso candidato se dibujaba como una barra con su
	 * medida de base, había que pulsar «Marcar como quebrado» para que apareciesen las medidas, y
	 * un «Volver a 8» para deshacerlo. El paso previo existía porque la pregunta ofrecía tres
	 * respuestas por verso —octosílabo, pentasílabo, tetrasílabo— y había que distinguir «este
	 * verso mide ocho» de «este verso todavía no se ha mirado».
	 *
	 * **Ya no las ofrece.** La migración del 5 de septiembre de 2026 retiró la medida de base, que
	 * no era una respuesta: decir que el verso mide ocho es decir que ahí no hay quiebro, y eso lo
	 * dice no contestar. Con dos medidas por verso, **elegir la medida es marcar el quiebro**, así
	 * que el paso previo sobra y con él la barra, el «marcar» y el «volver a».
	 *
	 * Queda una línea por verso candidato con sus dos medidas, ninguna marcada de partida. Sirve
	 * para los tres casos del catálogo sin cambiar de forma:
	 *
	 * - **la norma dice dónde** —copla manriqueña, cuatro quiebros; sextilla de pie quebrado, dos—:
	 *   salen sus versos y hay que responderlos todos;
	 * - **un solo verso candidato** —quintilla, copla castellana, novena, septilla—: una línea;
	 * - **varios candidatos** —oncena, redondilla, copla real, copla de arte menor—: una línea cada
	 *   uno, y el tope arriba cuando no se pueden quebrar todos.
	 */
	import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';
	import { shortPositionOptionLabel } from './positional-options';

	const props = $props<{
		options: MetricCatalogDomainRow[];
		selectedKeys: string[] | null;
		keyField: 'opcion_eleccion_id' | 'slug';
		minimum: number;
		maximum: number;
		positionLimit?: number;
		mixed?: boolean;
		ariaLabel: string;
		onChange: (keys: string[]) => void;
	}>();

	const visibleOptions = $derived(
		typeof props.positionLimit === 'number'
			? props.options.filter(
					(option: MetricCatalogDomainRow) =>
						Number(option.posicion_unidad) <= props.positionLimit!
				)
			: props.options
	);
	const positions = $derived(
		Array.from(
			new Set<number>(
				visibleOptions.map((option: MetricCatalogDomainRow) =>
					Number(option.posicion_unidad)
				)
			)
		).sort((a: number, b: number) => a - b)
	);
	const effectiveMaximum = $derived(Math.min(props.maximum, positions.length));
	const selected = $derived(props.selectedKeys ?? []);
	/** La medida que conservan los versos que no se quiebran. Se dice una vez, arriba. */
	const baseSyllables = $derived(Number(visibleOptions[0]?.metro_base_silabas) || null);
	const selectedVisibleCount = $derived(
		positions.filter((position: number) => selectedAt(position) !== null).length
	);
	/** Cuando no se pueden quebrar todos los candidatos, el tope se dice antes de elegir. */
	const hayTope = $derived(effectiveMaximum < positions.length);
	/**
	 * Si los versos que salen **son** los quiebros o si son los que **podrían** serlo.
	 *
	 * En la copla manriqueña y en la sextilla de pie quebrado la norma dice dónde caen —cuatro y
	 * dos— y lo único que se elige es cuánto miden. Decirle ahí al editor «señala 4 versos
	 * quebrados» le pide que decida algo que la forma ya decidió: lo que le falta es medirlos.
	 */
	const laNormaLosSitua = $derived(positions.length > 0 && props.minimum >= positions.length);

	function keyOf(option: MetricCatalogDomainRow): string {
		return String(option[props.keyField]);
	}

	function optionsAt(position: number): MetricCatalogDomainRow[] {
		return visibleOptions.filter(
			(option: MetricCatalogDomainRow) => Number(option.posicion_unidad) === position
		);
	}

	function selectedAt(position: number): string | null {
		return (
			optionsAt(position)
				.map(keyOf)
				.find((key: string) => selected.includes(key)) ?? null
		);
	}

	/**
	 * Un clic elige la medida; el mismo clic otra vez deshace el quiebro.
	 *
	 * Sin la medida de base no hace falta un botón aparte para quitarlo: el botón que lo puso lo
	 * quita, que es como se comporta cualquier grupo de opciones excluyentes.
	 */
	function elegir(position: number, option: MetricCatalogDomainRow) {
		const key = keyOf(option);
		const actual = selectedAt(position);
		const claves = new Set(optionsAt(position).map(keyOf));
		const resto = selected.filter((elegida: string) => !claves.has(elegida));
		if (actual === key) {
			props.onChange(resto);
			return;
		}
		// El tope solo frena al quebrar un verso más, no al cambiarle la medida a uno ya quebrado.
		if (actual === null && selectedVisibleCount >= effectiveMaximum) return;
		props.onChange([...resto, key]);
	}
</script>

<div class="space-y-2">
	{#if hayTope}
		<p class="text-xs text-[color:var(--muted-foreground)]">
			{effectiveMaximum === 1
				? 'Se quiebra como mucho un verso.'
				: `Se quiebran como mucho ${effectiveMaximum} versos.`}
		</p>
	{/if}

	<div class="space-y-1">
		{#each positions as position (position)}
			{@const elegida = selectedAt(position)}
			<div class="flex flex-wrap items-center gap-2 text-sm">
				<span class="w-20 shrink-0 tabular-nums text-[color:var(--muted-foreground)]">
					Verso {position}
				</span>
				<div class="flex border border-[color:var(--border)] bg-white">
					{#each optionsAt(position) as option (keyOf(option))}
						{@const key = keyOf(option)}
						{@const activa = elegida === key}
						<button
							type="button"
							class={`min-h-8 border-l border-[color:var(--border)] px-2.5 text-xs first:border-l-0 ${
								activa
									? 'bg-[color:var(--primary)] text-white'
									: 'bg-white hover:bg-[color:var(--muted)]'
							}`}
							aria-label={`${props.ariaLabel}, verso ${position}: ${String(option.nombre)}`}
							aria-pressed={activa}
							title={String(option.nombre)}
							onclick={() => elegir(position, option)}
						>
							{shortPositionOptionLabel(option, position)}
						</button>
					{/each}
				</div>
			</div>
		{/each}
	</div>

	<p
		class={`text-xs ${
			!props.mixed && selectedVisibleCount < props.minimum
				? 'text-[color:var(--primary)]'
				: 'text-[color:var(--muted-foreground)]'
		}`}
	>
		{#if props.mixed}
			Las unidades conservan respuestas distintas.
		{:else if laNormaLosSitua}
			{@const faltan = positions.length - selectedVisibleCount}
			{faltan === 0
				? `Los ${positions.length} quiebros ya están medidos.`
				: faltan === 1
					? 'Falta la medida de un quiebro.'
					: `Faltan las medidas de ${faltan} de los ${positions.length} quiebros.`}
		{:else if selectedVisibleCount < props.minimum}
			{props.minimum === 1
				? 'Señala al menos un verso quebrado.'
				: `Señala ${props.minimum} versos quebrados.`}
		{:else if selectedVisibleCount === 0}
			Ningún verso quebrado{baseSyllables ? `: todos miden ${baseSyllables} sílabas` : ''}.
		{:else}
			{selectedVisibleCount}
			{selectedVisibleCount === 1 ? 'verso quebrado' : 'versos quebrados'}{baseSyllables &&
			selectedVisibleCount < positions.length
				? `; los demás miden ${baseSyllables}`
				: ''}.
		{/if}
	</p>

	{#if selectedVisibleCount === positions.length && positions.length > 1 && props.minimum === 0}
		<p class="border-l-2 border-amber-500 bg-amber-50 px-3 py-2 text-xs text-amber-950">
			Has quebrado todos los versos: no queda ninguno
			{baseSyllables ? `de ${baseSyllables} sílabas` : 'de la medida base'}. Revisa que esta siga
			siendo la forma adecuada.
		</p>
	{/if}
</div>
