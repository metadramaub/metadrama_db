<script lang="ts">
	import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';
	import FieldHelpTooltip from '$lib/components/ui/field-help-tooltip.svelte';
	import { normalizeRhymeSymbol } from './rhyme-notation';
	import { escribirEstancia, leerEstanciaEscrita } from './estancia-escrita';
	import { repartoDeLosCortes } from './estancia-escrita';
	import type { ParteAsignable, Reparto } from './reparto-estancia';

	const props = $props<{
		length: number;
		positionStart?: number;
		options: MetricCatalogDomainRow[];
		selectedIds: string[];
		onMeasureChange: (ids: string[]) => void;
		rhymeValue?: string;
		onRhymeChange?: (value: string) => void;
		/**
		 * Lo que la norma fija en cada verso, para los que no preguntan nada.
		 *
		 * Indexado desde `positionStart`. Sin esto solo se sabía la medida de base, que sale del rol
		 * `dominante`; la seguidilla gitana no lo tiene —sus versos miden 6, 6, 11 y 6 declarados uno
		 * a uno— y sus tres versos fijos decían «Sin medidas disponibles», que suena a que falta algo.
		 */
		medidasFijas?: (number | null)[];
		/** Rima que la arquitectura ya fija: «—» en el cuerpo y «A» en el pareado. */
		fixedRhymes?: string[];
		/**
		 * Las partes a las que puede pertenecer cada verso, cuando la unidad se reparte verso a
		 * verso —la estancia de la canción: fronte con o sin sus dos piedi, eslabón, sirima—.
		 *
		 * La partición no se pregunta verso a verso ni tramo a tramo: se **corta** entre dos versos,
		 * como el corte de la notación, y el nombre de cada tramo lo pone el orden que el catálogo
		 * fija —fronte, eslabón, sirima, y dentro de la fronte sus dos pies—. Un corte es fronte y
		 * sirima; dos, fronte, eslabón y sirima si el tramo del medio es un verso, o los dos pies y
		 * la sirima si no; tres, pies, eslabón y sirima. Y quien lo vea claro lo escribe de una vez:
		 * `abC.abC:c.dD`.
		 */
		partes?: ParteAsignable[];
		/** A qué parte pertenece cada verso, indexado desde `positionStart`; nulo, a ninguna. */
		reparto?: Reparto;
		onRepartoChange?: (reparto: Reparto) => void;
		readOnly?: boolean;
	}>();

	// ------------------------------------------------------------------
	// Los cortes: dónde empieza y acaba cada parte
	// ------------------------------------------------------------------

	/** Índices locales tras los que el reparto cambia de parte. */
	const cortes = $derived.by(() => {
		const out: number[] = [];
		const reparto = props.reparto ?? [];
		for (let index = 0; index + 1 < props.length; index += 1) {
			if ((reparto[index] ?? null) !== (reparto[index + 1] ?? null)) out.push(index);
		}
		return out;
	});

	/** Los tramos en índices locales, con la parte que lleva su primer verso. */
	const tramos = $derived.by(() => {
		const out: { desde: number; hasta: number; parteId: string | null }[] = [];
		let desde = 0;
		for (let index = 0; index < props.length; index += 1) {
			if (cortes.includes(index) || index === props.length - 1) {
				out.push({ desde, hasta: index, parteId: props.reparto?.[desde] ?? null });
				desde = index + 1;
			}
		}
		return out;
	});

	function tramoQueEmpiezaEn(index: number) {
		return tramos.find((tramo) => tramo.desde === index) ?? null;
	}

	/** Una estancia tiene cuatro partes como mucho: pie, pie, eslabón, sirima. */
	const admiteOtroCorte = $derived(cortes.length < 3);

	function conCortes(nuevos: number[]) {
		if (!props.partes || !props.onRepartoChange) return;
		props.onRepartoChange(repartoDeLosCortes(props.length, nuevos, props.partes));
	}

	function cortar(index: number) {
		conCortes([...cortes, index].sort((a, b) => a - b));
	}

	function unir(index: number) {
		conCortes(cortes.filter((corte) => corte !== index));
	}

	/** El nombre corto para la llave: «Fronte», «1.er pie», «2.º pie», «Eslabón», «Sirima». */
	function nombreEnLaLlave(parteId: string | null): string {
		const parte = props.partes?.find((candidate: ParteAsignable) => candidate.id === parteId);
		if (!parte) return '';
		const slug = String(parte.seccion.slug);
		if (slug === 'primer_pie') return '1.er pie';
		if (slug === 'segundo_pie') return '2.º pie';
		return String(parte.seccion.nombre ?? parte.label);
	}

	// ------------------------------------------------------------------
	// La estancia escrita de una vez
	// ------------------------------------------------------------------

	let escrita = $state('');
	let errorEscrita = $state<string | null>(null);

	/** Lo que hay ahora, escrito: se ofrece para corregirlo, no para repetirlo. */
	const escritaActual = $derived.by(() => {
		if (!props.partes) return null;
		const letras = Array.from(String(props.rhymeValue ?? '')).slice(0, props.length).join('');
		if (letras.trim().length !== props.length) return null;
		return escribirEstancia(letras, (props.reparto ?? []).slice(0, props.length), props.partes);
	});

	function aplicarEscrita() {
		if (!props.partes || !props.onRepartoChange || !props.onRhymeChange) return;
		const leida = leerEstanciaEscrita(escrita, props.partes, props.length);
		errorEscrita = leida.error;
		if (leida.error) return;
		// La medida sale de la letra: minúscula, el verso corto; mayúscula, el largo.
		const ids: string[] = [];
		for (const [index, position] of positions.entries()) {
			const largo = leida.letras[index] === leida.letras[index].toUpperCase();
			const candidatas = optionsAt(position).filter((option) => {
				const silabas = Number(option.metro_silabas);
				return Number.isFinite(silabas) && (largo ? silabas >= 9 : silabas <= 8);
			});
			if (candidatas.length === 1) ids.push(String(candidatas[0].opcion_eleccion_id));
			else {
				const actual = selectedAt(position);
				if (actual) ids.push(actual);
			}
		}
		props.onMeasureChange(ids);
		props.onRhymeChange(leida.letras);
		props.onRepartoChange(leida.reparto);
		escrita = '';
	}

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
			props.options
				.map((option: MetricCatalogDomainRow) => Number(option.posicion_unidad))
				// El catálogo ofrece posiciones hasta el máximo de la sección —quince en la
				// estancia—; solo cuentan las que la unidad tiene.
				.filter((position: number) => position >= (props.positionStart ?? 1) && position < (props.positionStart ?? 1) + props.length)
		).size
	);

	/** Lo que la norma pone en este verso, si lo pone. */
	function medidaFijaAt(position: number): number | null {
		const valor = props.medidasFijas?.[localIndex(position)];
		return typeof valor === 'number' && Number.isFinite(valor) && valor > 0 ? valor : null;
	}

	function silabasAt(position: number): number | null {
		const elegida = selectedSyllables(position);
		if (elegida !== null) return elegida;
		if (optionsAt(position).length > 0) return null;
		return medidaFijaAt(position) ?? medidaDeBase;
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

<!--
	**Una lista de versos, no una tabla.**

	Esto llevaba una cabecera de tres columnas —«Posición · Medida · Elección»— dentro de una caja
	con su borde. En el pareado son tres rótulos para dos filas, y en ninguna forma dicen nada que la
	fila no diga ya: el verso lleva su número, la barra lo que mide y los botones son visiblemente lo
	que se elige. Rotular una tabla de dos filas es lo que la hacía parecer una tabla.

	**La barra se queda**, que es lo contrario del caso del quiebro: aquí *todos* los versos piden
	medida, y verlas juntas enseña la forma medida de la estrofa —los siete y once alternos de la
	lira— que es justo lo que se está respondiendo.
-->
<div>
	{#if props.partes && props.onRepartoChange && !props.readOnly}
		<!--
			**El atajo va antes que las filas**, porque quien lo usa no va a bajar por ellas: escribe
			la estancia y las filas se rellenan. Lo que hay ahora se enseña escrito al lado, para que
			se pueda copiar y corregir.
		-->
		<div class="mb-3 flex flex-wrap items-center gap-x-3 gap-y-1">
			<label class="flex items-center gap-2 text-xs text-[color:var(--muted-foreground)]">
				<span class="flex items-center gap-1 whitespace-nowrap">
					Escribir la estancia
					<FieldHelpTooltip
						label="Cómo se escribe la estancia"
						text="Una letra por verso: minúscula para el verso corto y mayúscula para el largo. Los dos puntos cierran la fronte, y el punto separa los dos pies dentro de ella y el eslabón de la sirima después: abC.abC:c.dD. Sin dos puntos, la estancia queda sin partes. Sin punto en la fronte, es una fronte entera sin pies: abCabC:cdD."
					/>
				</span>
				<input
					type="text"
					class="h-7 w-40 border border-[color:var(--border)] bg-white px-2 font-mono text-sm"
					placeholder={escritaActual ?? 'abC.abC:c.dD'}
					bind:value={escrita}
					autocomplete="off"
					spellcheck="false"
					onkeydown={(event) => {
						if (event.key === 'Enter') {
							event.preventDefault();
							aplicarEscrita();
						}
					}}
				/>
			</label>
			<button type="button" class="link-action" onclick={aplicarEscrita} disabled={!escrita.trim()}>
				Aplicar
			</button>
			{#if escritaActual}
				<span class="text-xs text-[color:var(--muted-foreground)]">ahora <span class="font-mono">{escritaActual}</span></span>
			{/if}
			{#if errorEscrita}
				<span class="basis-full text-xs text-amber-800">{errorEscrita}</span>
			{/if}
		</div>
	{/if}
	{#each positions as position, index}
		{@const choices = optionsAt(position)}
		{@const selected = selectedAt(position)}
		{@const tramo = props.partes ? tramoQueEmpiezaEn(index) : null}
		{@const dentroDeTramo = props.partes && !tramo}
		<!--
			**El corte va entre dos filas**, donde se corta la estancia al leerla: un botón fino que
			dice «cortar» o, si ya hay corte, «unir». La llave de la izquierda nombra el tramo en su
			primer verso y baja como una línea por los demás.
		-->
		{#if props.partes && index > 0 && !props.readOnly}
			<div class="grid sm:grid-cols-[6rem_minmax(0,1fr)]">
				<div></div>
				<div class="flex h-3.5 items-center">
					{#if cortes.includes(index - 1)}
						<button
							type="button"
							class="link-action text-[0.65rem] leading-none"
							onclick={() => unir(index - 1)}
							aria-label={`Quitar el corte entre los versos ${position - 1} y ${position}`}
						>
							✕ quitar el corte
						</button>
					{:else if admiteOtroCorte}
						<button
							type="button"
							class="w-full text-left text-[0.65rem] leading-none text-[color:var(--muted-foreground)] opacity-40 hover:opacity-100 focus:opacity-100"
							onclick={() => cortar(index - 1)}
							aria-label={`Cortar entre los versos ${position - 1} y ${position}`}
						>
							— cortar aquí —
						</button>
					{/if}
				</div>
			</div>
		{/if}
		<div class={props.partes ? 'grid gap-2 py-0.5 sm:grid-cols-[6rem_minmax(0,1fr)]' : 'py-1'}>
			{#if props.partes}
				<!-- La llave: el nombre del tramo en su primer verso, y una línea por los demás. -->
				<div
					class={`flex h-7 items-center ${
						tramo?.parteId || (dentroDeTramo && props.reparto?.[index])
							? 'ml-1 border-l-2 border-[color:var(--primary)] pl-2'
							: 'ml-1 border-l-2 border-transparent pl-2'
					}`}
				>
					{#if tramo}
						<span class={`text-xs ${tramo.parteId ? 'font-medium' : 'text-[color:var(--muted-foreground)]'}`}>
							{tramo.parteId ? nombreEnLaLlave(tramo.parteId) : cortes.length === 0 ? 'Sin partes' : ''}
						</span>
					{/if}
				</div>
			{/if}
			<!--
				**Sin barra.** La fila llevaba el verso dibujado como una barra proporcional a su medida,
				con el número dentro, y al lado los botones de la medida: con quince versos de estancia
				eran dos veces la misma información y demasiado peso. Queda el número del verso, las
				medidas y la rima. El elegido se ve por presencia, no por matiz: sólido y oscuro frente a
				texto apagado sin borde.
			-->
			<div class="flex min-w-0 items-center gap-3">
				<span class="w-14 shrink-0 text-xs text-[color:var(--muted-foreground)]">Verso {position}</span>
				<!--
					Las medidas, como un solo control: los botones van pegados dentro de un borde común,
					y el elegido se rellena de oscuro. Sin elegir, todos quedan en blanco.
				-->
				<div
					class="inline-flex shrink-0 flex-wrap border border-[color:var(--border)]"
					role="group"
					aria-label={`Medida del verso ${position}`}
				>
					{#if choices.length === 0}
						<span class="px-2 text-xs leading-7 text-[color:var(--muted-foreground)]">
							{silabasAt(position) !== null ? `${silabasAt(position)} sílabas · fijo` : 'Sin medidas disponibles'}
						</span>
					{/if}
					{#each choices as option (String(option.opcion_eleccion_id))}
						{@const optionId = String(option.opcion_eleccion_id)}
						<button
							type="button"
							class={`h-7 min-w-9 px-2 text-sm tabular-nums transition-colors ${
								selected === optionId
									? 'bg-[color:var(--foreground)] font-semibold text-white'
									: 'bg-white text-[color:var(--muted-foreground)] hover:bg-[color:var(--muted)]'
							}`}
							disabled={props.readOnly}
							aria-pressed={selected === optionId}
							onclick={() => chooseMeasure(position, optionId)}
						>
							{syllables(option)}
						</button>
					{/each}
				</div>
				<div class="flex shrink-0 items-center gap-2">
				{#if props.onRhymeChange}
					<label class="flex items-center gap-2 sm:block">
					<span class="text-xs text-[color:var(--muted-foreground)] sm:sr-only">Rima</span>
					<input
						type="text"
						maxlength="1"
						class="h-7 w-10 border border-[color:var(--border)] bg-white px-1 text-center font-mono text-sm"
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
			</div>
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
	{#if props.partes && props.reparto}
		· {tramos.filter((tramo) => tramo.parteId).map((tramo) => nombreEnLaLlave(tramo.parteId)).join(' · ') || 'sin partes'}
	{/if}
</p>
