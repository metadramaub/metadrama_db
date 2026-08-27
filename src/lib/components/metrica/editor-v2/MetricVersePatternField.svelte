<script lang="ts">
	import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';
	import MetricVerseBar from './MetricVerseBar.svelte';
	import { normalizeRhymeSymbol } from './rhyme-notation';

	const props = $props<{
		length: number;
		positionStart?: number;
		options: MetricCatalogDomainRow[];
		selectedIds: string[];
		onMeasureChange: (ids: string[]) => void;
		rhymeValue?: string;
		onRhymeChange?: (value: string) => void;
		/** Rima que la arquitectura ya fija: «—» en el cuerpo y «A» en el pareado. */
		fixedRhymes?: string[];
		readOnly?: boolean;
	}>();

	const positions = $derived(
		Array.from({ length: props.length }, (_, index) => (props.positionStart ?? 1) + index)
	);

	/**
	 * La medida que la norma pone donde no pregunta nada.
	 *
	 * En la copla manriqueña la norma fija los ocho octosílabos y solo deja abiertos los cuatro
	 * quebrados, así que el catálogo deriva opciones **únicamente** para esas cuatro posiciones. Las
	 * otras ocho decían «sin medidas disponibles», que suena a que falta algo: no falta nada, están
	 * decididas. Se pintan con su medida y sin poder tocarlas.
	 */
	const medidaDeBase = $derived.by(() => {
		for (const option of props.options) {
			const base = Number(option.metro_base_silabas);
			if (Number.isFinite(base) && base > 0) return base;
		}
		return null;
	});

	/** Cuántos versos de la rejilla admiten más de una medida, que son los que hay que responder. */
	const versosQuePreguntan = $derived(
		new Set(
			props.options.map((option: MetricCatalogDomainRow) => Number(option.posicion_unidad))
		).size
	);

	/**
	 * Con qué se compara la anchura de cada barra.
	 *
	 * Con medida de base es esa base —la manriqueña, donde los quebrados han de verse más cortos que
	 * los octosílabos—; sin ella, la mayor que ofrece el repertorio, para que en un cuarteto-lira el
	 * endecasílabo llene la barra y el heptasílabo no.
	 */
	const medidaMayor = $derived.by(() => {
		if (medidaDeBase !== null) return medidaDeBase;
		let mayor = 0;
		for (const option of props.options) {
			const silabas = Number(option.metro_silabas);
			if (Number.isFinite(silabas) && silabas > mayor) mayor = silabas;
		}
		return mayor > 0 ? mayor : null;
	});

	function silabasAt(position: number): number | null {
		const elegida = selectedSyllables(position);
		if (elegida !== null) return elegida;
		return optionsAt(position).length === 0 ? medidaDeBase : null;
	}

	function optionsAt(position: number): MetricCatalogDomainRow[] {
		return props.options.filter(
			(option: MetricCatalogDomainRow) => Number(option.posicion_unidad) === position
		);
	}

	function selectedAt(position: number): string | null {
		const ids = new Set(
			optionsAt(position).map((option: MetricCatalogDomainRow) =>
				String(option.opcion_eleccion_id)
			)
		);
		return props.selectedIds.find((id: string) => ids.has(id)) ?? null;
	}

	function syllables(option: MetricCatalogDomainRow): string {
		const exact = Number(option.metro_silabas);
		if (Number.isFinite(exact)) return String(exact);
		const match = String(option.nombre ?? '').match(/\b(\d+)\b/);
		return match?.[1] ?? String(option.nombre ?? '');
	}

	function localIndex(position: number): number {
		return position - (props.positionStart ?? 1);
	}

	function selectedOption(position: number, overrideId?: string): MetricCatalogDomainRow | null {
		const optionId = overrideId ?? selectedAt(position);
		return optionsAt(position).find(
			(option) => String(option.opcion_eleccion_id) === optionId
		) ?? null;
	}

	function selectedSyllables(position: number, overrideId?: string): number | null {
		const value = Number(selectedOption(position, overrideId)?.metro_silabas);
		return Number.isFinite(value) ? value : null;
	}

	function chooseMeasure(position: number, optionId: string) {
		const positionIds = new Set(
			optionsAt(position).map((option) => String(option.opcion_eleccion_id))
		);
		props.onMeasureChange([
			...props.selectedIds.filter((id: string) => !positionIds.has(id)),
			optionId
		]);
		if (props.onRhymeChange) {
			const index = localIndex(position);
			const chars = Array.from(String(props.rhymeValue ?? '')).slice(0, props.length);
			const current = chars[index] ?? '';
			const normalized = normalizeRhymeSymbol(current, selectedSyllables(position, optionId));
			if (current && normalized !== current) {
				chars[index] = normalized;
				props.onRhymeChange(chars.join(''));
			}
		}
	}

	function rhymeAt(position: number): string {
		return Array.from(String(props.rhymeValue ?? ''))[localIndex(position)]?.trim() ?? '';
	}

	function changeRhyme(position: number, raw: string) {
		if (!props.onRhymeChange) return;
		const value = normalizeRhymeSymbol(raw, selectedSyllables(position));
		const chars = Array.from(props.rhymeValue ?? '').slice(0, props.length);
		while (chars.length < props.length) chars.push(' ');
		chars[localIndex(position)] = value || ' ';
		props.onRhymeChange(chars.join(''));
	}

	$effect(() => {
		if (!props.onRhymeChange || !props.rhymeValue) return;
		const chars = Array.from(String(props.rhymeValue)).slice(0, props.length);
		let changed = false;
		for (const position of positions) {
			const index = localIndex(position);
			const normalized = normalizeRhymeSymbol(chars[index] ?? '', selectedSyllables(position));
			if (normalized && normalized !== chars[index]) {
				chars[index] = normalized;
				changed = true;
			}
		}
		if (changed) props.onRhymeChange(chars.join(''));
	});
</script>

<div class="overflow-hidden border border-[color:var(--border)] bg-white">
	<!-- La cabecera sigue la rejilla de la barra: verso, lo que mide y con qué se responde. -->
	<div
		class="hidden border-b border-[color:var(--border)] bg-[color:var(--muted)] px-3 py-1.5 text-xs font-medium text-[color:var(--muted-foreground)] sm:grid sm:grid-cols-[4rem_minmax(9rem,1fr)_12rem]"
	>
		<span>Posición</span>
		<span>Medida</span>
		<span>{props.onRhymeChange || props.fixedRhymes ? 'Medida y rima' : 'Elección'}</span>
	</div>

	{#each positions as position}
		{@const choices = optionsAt(position)}
		{@const selected = selectedAt(position)}
		<!--
			La fila es la barra: se ve lo que mide cada verso antes de leer el número. Es el mismo
			dibujo que la pregunta de los pies quebrados, en un componente que usan las dos.
		-->
		<div class="border-b border-[color:var(--border)] px-3 py-2 last:border-b-0">
			<MetricVerseBar
				etiqueta={`Verso ${position}`}
				silabas={silabasAt(position)}
				maximo={medidaMayor}
				variante={selected ? 'elegida' : choices.length === 0 ? 'base' : 'vacia'}
				distintivo={choices.length === 0 && medidaDeBase !== null ? 'fijo' : undefined}
				texto={choices.length === 0 && medidaDeBase === null
					? 'Sin medidas disponibles'
					: selected
						? undefined
						: 'Elige la medida'}
			>
				<div class="flex min-w-0 items-center gap-2">
					<div class="flex min-w-0">
						{#each choices as option (String(option.opcion_eleccion_id))}
							{@const optionId = String(option.opcion_eleccion_id)}
							<button
								type="button"
								class={`h-9 min-w-12 border border-r-0 px-3 text-sm font-medium last:border-r ${
									selected === optionId
										? 'border-[color:var(--primary)] bg-[color:var(--primary)] text-white'
										: 'border-[color:var(--border)] bg-white hover:bg-[color:var(--muted)]'
								}`}
								disabled={props.readOnly}
								aria-pressed={selected === optionId}
								onclick={() => chooseMeasure(position, optionId)}
							>
								{syllables(option)}
							</button>
						{/each}
					</div>
				{#if props.onRhymeChange}
					<label class="flex items-center gap-2 sm:block">
					<span class="text-xs text-[color:var(--muted-foreground)] sm:sr-only">Rima</span>
					<input
						type="text"
						maxlength="1"
						class="h-9 w-16 border border-[color:var(--border)] bg-white px-2 text-center font-mono text-sm"
						value={rhymeAt(position)}
						aria-label={`Rima del verso ${position}`}
						autocomplete="off"
						spellcheck="false"
						oninput={(event) => changeRhyme(position, event.currentTarget.value)}
						/>
					</label>
					{:else if props.fixedRhymes}
						<span class="font-mono text-sm font-medium"
							>{props.fixedRhymes[localIndex(position)] ?? '—'}</span
						>
					{/if}
				</div>
			</MetricVerseBar>
		</div>
	{/each}
</div>

<!--
	Se cuentan **los que preguntan**, no los versos de la unidad: en la manriqueña la norma fija ocho
	de los doce, y decir «0 de 12» pedía una respuesta que nadie va a dar.
-->
<p class="text-xs text-[color:var(--muted-foreground)]">
		{props.selectedIds.length} de {versosQuePreguntan} versos con medida
	{#if props.onRhymeChange}
		· {Array.from(String(props.rhymeValue ?? '')).filter((char: string) => char.trim()).length} de {props.length} con rima
	{/if}
</p>
