<script lang="ts">
	import FieldHelpTooltip from '$lib/components/ui/field-help-tooltip.svelte';
	import { renderInlineMarkdown, stripMarkdown } from '$lib/utils/markdown';
	import { controlDePregunta } from '$lib/metrica/controles-formulario';
	import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';
	import MetricPartialPositionField from './MetricPartialPositionField.svelte';
	import MetricVersePatternField from './MetricVersePatternField.svelte';
	import {
		arePositionalOptions,
		haveAlternativesByPosition,
		isPartialPositionalSelection
	} from './positional-options';
	import {
		componerEsquemaEscrito,
		leerEsquemaEscrito,
		separarRegimen,
		type EsquemaCatalogado,
		type RestriccionRima
	} from '$lib/metrica/esquema-rima-escrito';

	const props = $props<{
		group: MetricCatalogDomainRow;
		options: MetricCatalogDomainRow[];
		selectedIds: string[];
		onChange: (ids: string[]) => void;
		textValue?: string;
		onTextChange?: (value: string) => void;
		onApplyAll?: () => void;
		positionStart?: number;
		positionLimit?: number;
		/** Lo que la norma fija en cada verso, desde `positionStart`. Ver `MetricVersePatternField`. */
		medidasFijas?: (number | null)[];
		pendingPositions?: number[];
		onPendingPositionsChange?: (positions: number[]) => void;
		/**
		 * `celda` es la variante de la rejilla: una sola línea de alto, para que la fila de
		 * cada realización quepa junto a las demás. Las alternativas se enseñan en un
		 * desplegable aunque sean pocas, porque una lista de tres con sus explicaciones
		 * ocuparía más que la composición entera.
		 */
		variant?: 'campo' | 'celda';
		/**
		 * El enunciado, cuando la fila ya nombra la sección de la que habla y repetirla sobra:
		 * «Esquema de rima» en la fila de los cuartetos, no «Cuartetos · Esquema de rima».
		 */
		label?: string;
		/**
		 * Sin rótulo propio: la fila que lo contiene ya nombra la pregunta.
		 *
		 * Lo usa la respuesta común de la rejilla, donde el rótulo y el recuento —«en las 3
		 * unidades»— van en la fila y repetirlos dentro sería decir dos veces lo mismo.
		 */
		sinRotulo?: boolean;
		/**
		 * La explicación que el catálogo deriva de la respuesta elegida. Es lo que la rejilla
		 * se dejaría por el camino al comprimir las listas en desplegables, así que se
		 * recupera debajo, y solo donde aporta: en la respuesta común y en la que diverge.
		 */
		showDescription?: boolean;
		/** Resume una respuesta común y deja el control completo para cuando se crea una excepción. */
		compact?: boolean;
		/**
		 * Plegado, se lee como una línea de texto y no como un campo.
		 *
		 * Dentro de una unidad ya plegada, pintar cada respuesta con su recuadro, su rótulo y una
		 * nota que dice «respuesta de esta copla» era un cuadro dentro de otro para decir dos
		 * palabras. Ahí lo que hace falta es leer de un vistazo qué contestó la unidad.
		 */
		resumen?: boolean;
		onExpand?: () => void;
		/** Explica si el resumen procede de la respuesta común o de esta unidad. */
		compactNote?: string;
		changeLabel?: string;
		hideCompactAction?: boolean;
		/**
		 * Lo que hace falta para leer un esquema escrito a mano: cuánto mide la unidad, en qué
		 * régimen rima y qué disposiciones tiene ya el catálogo. Sin esto el campo abierto acepta
		 * cualquier cosa, que es lo que hacía hasta el 25 de agosto de 2026.
		 */
		normaEsquema?: {
			versos?: number | null;
			regimen?: string | null;
			catalogados?: EsquemaCatalogado[];
			restricciones?: RestriccionRima[];
			/**
			 * Los regímenes entre los que hay que elegir, **solo cuando varían dentro de la
			 * arquitectura**. Donde la arquitectura declara uno solo se hereda y no se pregunta.
			 */
			regimenes?: { slug: string; etiqueta: string }[];
		};
	}>();

	const celda = $derived(props.variant === 'celda');

	const minimum = $derived(Number(props.group.selecciones_min ?? 0));
	const maximum = $derived(Number(props.group.selecciones_max ?? 1));
	const optional = $derived(minimum === 0);
	const positional = $derived(arePositionalOptions(props.options));
	const visibleOptions = $derived(
		positional
			? props.options.filter(
					(option: MetricCatalogDomainRow) =>
						(typeof props.positionStart !== 'number' ||
							Number(option.posicion_unidad) >= props.positionStart) &&
						(typeof props.positionLimit !== 'number' ||
							Number(option.posicion_unidad) <= props.positionLimit)
				)
			: props.options
	);
	const positionalAlternatives = $derived(haveAlternativesByPosition(visibleOptions));
	const partialPositionalSelection = $derived(
		isPartialPositionalSelection(props.group, visibleOptions)
	);
	const visiblePositions = $derived(
		Array.from(
			new Set<number>(
				visibleOptions.map((option: MetricCatalogDomainRow) =>
					Number(option.posicion_unidad)
				)
			)
		).sort((a: number, b: number) => a - b)
	);
	const effectiveMaximum = $derived(
		positional && typeof props.positionLimit === 'number'
			? Math.min(maximum, Math.max(1, props.positionLimit))
			: maximum
	);
	/** Los dos controles que dejan escribir un esquema. El híbrido además ofrece la lista. */
	const admiteEsquemaEscrito = $derived(
		props.group.tipo_control === 'esquema_rima' ||
			props.group.tipo_control === 'opciones_y_esquema'
	);
	/**
	 * La serie de medidas: una medida por verso, escrita de una vez.
	 *
	 * Es el registro de los tramos sin forma, que no tienen norma contra la que leer nada. Por eso
	 * no pasa por lo del esquema de rima —régimen, disposiciones catalogadas, lectura contra la
	 * norma—: aquí solo hay que contar que venga una medida por verso.
	 */
	const esSerieDeMedidas = $derived(props.group.tipo_control === 'serie_medidas');
	const medidasEscritas = $derived(
		(props.textValue ?? '').trim().split(/\s+/).filter(Boolean)
	);
	const faltanMedidas = $derived(
		props.normaEsquema?.versos ? props.normaEsquema.versos - medidasEscritas.length : null
	);
	/**
	 * Cuando escribir es **todo** el control: no hay repertorio que ofrecer.
	 *
	 * Lo era el abierto puro, y lo es también el híbrido cuya arquitectura no tiene ninguna
	 * disposición catalogada. La novena-lira es ese caso: su único esquema es «Distribución
	 * variable», de secuencia `abierta`, y la función que deriva las opciones no ofrece las
	 * abiertas. Sin esto, pasarla al control híbrido —para que las cuatro liras abiertas funcionen
	 * igual— le habría puesto delante un desplegable vacío.
	 */
	const isRhymeScheme = $derived(
		props.group.tipo_control === 'esquema_rima' ||
			(admiteEsquemaEscrito && visibleOptions.length === 0)
	);

	/**
	 * Lo escrito, leído contra la norma.
	 *
	 * Cuando resulta ser una de las disposiciones catalogadas, **se guarda como esa**: eso es lo que
	 * mantiene comparable el dato entre quien la eligió de la lista y quien la escribió. Ver la
	 * regla 3 de criterios de nivel § 3.3.
	 */
	/**
	 * La notación y el régimen se guardan juntos en un solo campo —`abcabc · asonante`— y en
	 * pantalla son dos controles. Aquí se separan para pintarlos y se recomponen al escribir.
	 */
	const escrito = $derived(separarRegimen(props.textValue ?? ''));
	const regimenesPosibles = $derived(props.normaEsquema?.regimenes ?? []);
	/** Se pregunta solo si de verdad hay entre qué elegir. */
	const preguntaElRegimen = $derived(admiteEsquemaEscrito && regimenesPosibles.length > 1);

	const lecturaEscrita = $derived(
		leerEsquemaEscrito(props.textValue ?? '', {
			versos: props.normaEsquema?.versos ?? null,
			regimen: props.normaEsquema?.regimen ?? null,
			catalogados: props.normaEsquema?.catalogados ?? [],
			restricciones: props.normaEsquema?.restricciones ?? []
		})
	);
	const errorEscrito = $derived(
		lecturaEscrita.estado === 'error' ? lecturaEscrita.mensaje : null
	);
	const avisosEscritos = $derived(
		lecturaEscrita.estado === 'ok' ? lecturaEscrita.avisos : []
	);

	/**
	 * Escribir una disposición que el catálogo ya tiene **elige esa opción** y vacía el campo: la
	 * respuesta es la misma, y guardarla como texto la sacaría de las cuentas.
	 */
	/** Cambiar el régimen no borra la notación escrita, ni al revés. */
	function escribirRegimen(regimen: string) {
		escribirEsquema(componerEsquemaEscrito(escrito.notacion, regimen || null));
	}

	function escribirNotacion(notacion: string) {
		escribirEsquema(
			componerEsquemaEscrito(notacion, preguntaElRegimen ? escrito.regimen : null)
		);
	}

	function escribirEsquema(valor: string) {
		props.onTextChange?.(valor);
		const lectura = leerEsquemaEscrito(valor, {
			versos: props.normaEsquema?.versos ?? null,
			regimen: props.normaEsquema?.regimen ?? null,
			catalogados: props.normaEsquema?.catalogados ?? []
		});
		if (lectura.estado === 'ok' && lectura.esquemaCatalogadoId) {
			// **Lo escrito ya está en el repertorio, y aquí no se cambia nada solo.** Se comprueba
			// mientras se teclea, así que a mitad de escribir se pasa por notaciones que existen sin
			// que sean la que se quiere decir: cambiar la respuesta ahí obligaría a empezar de cero.
			// Se avisa y se espera.
			const nombre = visibleOptions.find(
				(option: MetricCatalogDomainRow) =>
					String(option.opcion_eleccion_id) === lectura.esquemaCatalogadoId
			)?.nombre;
			coincidencia = { id: lectura.esquemaCatalogadoId, nombre: String(nombre ?? ''), texto: valor };
			return;
		}
		coincidencia = null;
	}

	/** Se acepta el aviso: lo escrito era una del repertorio y se marca. */
	function marcarCoincidencia() {
		if (!coincidencia) return;
		const id = coincidencia.id;
		// **El texto se limpia primero.** La respuesta escrita y la elegida son la misma fila del
		// borrador, así que vaciar el texto después de marcar la opción borraba lo recién marcado.
		props.onTextChange?.('');
		props.onChange([id]);
		escribiendoOtra = false;
		coincidencia = null;
	}

	/**
	 * Enterado: se cierra el aviso y se sigue escribiendo.
	 *
	 * **No deja de contrastar.** Se cierra este aviso, y a la siguiente tecla se vuelve a mirar el
	 * repertorio: si lo que queda escrito coincide otra vez, con esta o con otra, se dice otra vez.
	 * Recordar lo descartado hacía que corregir una notación y volver sobre ella pasara en silencio.
	 */
	function descartarCoincidencia() {
		coincidencia = null;
	}

	/**
	 * La salida abierta, que es una opción más y no un campo siempre puesto.
	 *
	 * Estaba debajo de cada lista de rima —**49 preguntas en 42 arquitecturas de 26 formas**—
	 * compitiendo con el repertorio que sí se usa casi siempre. Ahora se elige como se elige
	 * cualquier otra respuesta, y el campo aparece detrás.
	 */
	const OTRA = '__otra__';
	let escribiendoOtra = $state(false);
	/** Lo escrito coincide con una del repertorio; se dice y se espera respuesta. */
	let coincidencia: { id: string; nombre: string; texto: string } | null = $state(null);
	/** Se escribe cuando se ha pedido, o cuando se reabre una respuesta que ya venía escrita. */
	const escribiendoEsquema = $derived(
		escribiendoOtra || Boolean((props.textValue ?? '').trim())
	);
	const ofreceOtra = $derived(
		props.group.tipo_control === 'opciones_y_esquema' && !isRhymeScheme && visibleOptions.length > 0
	);

	function elegirOtra() {
		escribiendoOtra = true;
		coincidencia = null;
		if (props.selectedIds.length > 0) props.onChange([]);
	}

	function dejarDeEscribir() {
		escribiendoOtra = false;
		coincidencia = null;
		if ((props.textValue ?? '').trim()) props.onTextChange?.('');
	}

	/** Un rasgo con un solo valor no es una elección entre alternativas: está o no está. */
	const control = $derived(controlDePregunta(visibleOptions.length, minimum));
	const showAsCheckbox = $derived(
		!admiteEsquemaEscrito && !positional && maximum === 1 && optional && control === 'casilla'
	);
	const showAsList = $derived(
		!celda &&
			!isRhymeScheme &&
			!positional &&
			!showAsCheckbox &&
			maximum === 1 &&
			control === 'lista'
	);

	/** Lo que dice el catálogo de la respuesta elegida, cuando hay una sola. */
	const descripcionElegida = $derived(
		props.selectedIds.length === 1
			? String(
					visibleOptions.find(
						(option: MetricCatalogDomainRow) =>
							String(option.opcion_eleccion_id) === props.selectedIds[0]
					)?.descripcion ?? ''
				)
			: ''
	);
	function changeSingle(event: Event) {
		const value = (event.currentTarget as HTMLSelectElement).value;
		if (value === OTRA) {
			elegirOtra();
			return;
		}
		dejarDeEscribir();
		props.onChange(value ? [value] : []);
	}

	function toggleOption(optionId: string, checked: boolean) {
		const current = new Set(props.selectedIds);
		if (checked) {
			if (current.size >= effectiveMaximum) return;
			current.add(optionId);
		} else {
			current.delete(optionId);
		}
		props.onChange([...current]);
	}

	/** El metro de la primera respuesta, para poder repetirlo en las demás posiciones. */
	const metroRespondido = $derived(
		visibleOptions.find((option: MetricCatalogDomainRow) =>
			props.selectedIds.includes(String(option.opcion_eleccion_id))
		)?.metro_id ?? null
	);
	const puedeRellenarPosiciones = $derived(
		positional &&
			!partialPositionalSelection &&
			Boolean(metroRespondido) &&
			visiblePositions.length > props.selectedIds.length
	);

	/**
	 * Repite la medida ya respondida en todas las posiciones que quedan. Ahorra teclear la
	 * misma sílaba una vez por verso cuando el pasaje es isosilábico.
	 */
	function rellenarPosiciones() {
		if (!metroRespondido) return;
		const siguientes: string[] = [];
		for (const position of visiblePositions) {
			const yaRespondida = visibleOptions.find(
				(option: MetricCatalogDomainRow) =>
					Number(option.posicion_unidad) === position &&
					props.selectedIds.includes(String(option.opcion_eleccion_id))
			);
			const elegida =
				yaRespondida ??
				visibleOptions.find(
					(option: MetricCatalogDomainRow) =>
						Number(option.posicion_unidad) === position &&
						String(option.metro_id) === String(metroRespondido)
				);
			if (elegida) siguientes.push(String(elegida.opcion_eleccion_id));
		}
		props.onChange(siguientes.slice(0, effectiveMaximum));
	}

	/**
	 * Los controles de varias líneas —una fila por verso, una casilla por posición— ocupan
	 * tanto como el resto del formulario junto. Cuando ya están contestados se recogen en su
	 * respuesta: la pregunta contestada debe encoger, no seguir pesando lo mismo.
	 */
	let expanded = $state(false);

	const multiline = $derived(
		positionalAlternatives || positional || (!isRhymeScheme && maximum !== 1)
	);
	const answered = $derived(
		admiteEsquemaEscrito && Boolean((props.textValue ?? '').trim())
			? true
			: isRhymeScheme
			? Boolean((props.textValue ?? '').trim())
			: positionalAlternatives
				? partialPositionalSelection
					? props.selectedIds.length >= minimum
					: visiblePositions.length > 0 && props.selectedIds.length === visiblePositions.length
				: props.selectedIds.length > 0 && props.selectedIds.length >= minimum
	);
	const collapsed = $derived(
		answered && (props.compact || (!partialPositionalSelection && multiline && !expanded))
	);
	/**
	 * La medida verso a verso, en notación: `8 8 4 8 8 4`.
	 *
	 * Es la única manera legible de resumir una respuesta posicional. Enumerando los nombres de las
	 * opciones salía «Verso 3 · Tetrasílabo · Verso 6 · Tetrasílabo · Verso 9 · Tetrasílabo · Verso
	 * 12 · Tetrasílabo», que ocupa cuatro renglones para decir lo que la serie dice en una línea, y
	 * además esconde dónde están los ocho versos que no se preguntan.
	 *
	 * Las posiciones sin respuesta se rellenan con la medida de base, que es lo que la norma pone
	 * ahí. Sin base no hay serie que valga.
	 */
	function serieDeMedidas(): string | null {
		// Ojo con el cero: `Number(null)` lo devuelve y pasa por finito. No hay verso de 0 sílabas.
		const crudo = Number(visibleOptions[0]?.metro_base_silabas);
		const base = Number.isFinite(crudo) && crudo > 0 ? crudo : null;
		if (visiblePositions.length === 0) return null;
		const porPosicion = new Map<number, number>();
		for (const option of visibleOptions) {
			if (!props.selectedIds.includes(String(option.opcion_eleccion_id))) continue;
			const posicion = Number(option.posicion_unidad);
			const silabas = Number(option.metro_silabas);
			if (Number.isFinite(posicion) && Number.isFinite(silabas)) porPosicion.set(posicion, silabas);
		}
		const desde = patternStart;
		const hasta = base !== null ? desde + patternLength - 1 : (visiblePositions.at(-1) ?? desde);
		const piezas: string[] = [];
		let respondida = false;
		for (let posicion = desde; posicion <= hasta; posicion += 1) {
			const silabas = porPosicion.get(posicion) ?? base;
			// Un verso sin contestar **y sin medida de base** se marca, no se calla: en las formas
			// aliradas abiertas no hay base ninguna, y devolver nulo mandaba el resumen a enumerar
			// nombres de opción, que es de donde veníamos.
			if (silabas === null) {
				piezas.push('·');
				continue;
			}
			if (porPosicion.has(posicion)) respondida = true;
			piezas.push(String(silabas));
		}
		if (!respondida && base === null) return null;
		return piezas.length > 0 ? piezas.join(' ') : null;
	}

	/** De dónde a dónde llega la rejilla: el tramo de la unidad del que trata la pregunta. */
	const patternStart = $derived(props.positionStart ?? 1);
	const patternLength = $derived(
		Math.max(
			1,
			(typeof props.positionLimit === 'number'
				? props.positionLimit
				: (visiblePositions.at(-1) ?? patternStart)) -
				patternStart +
				1
		)
	);

	const answerSummary = $derived.by(() => {
		const selectedOptions = visibleOptions
			.filter((option: MetricCatalogDomainRow) =>
				props.selectedIds.includes(String(option.opcion_eleccion_id))
			)
			.sort(
				(a: MetricCatalogDomainRow, b: MetricCatalogDomainRow) =>
					Number(a.posicion_unidad ?? 0) - Number(b.posicion_unidad ?? 0)
			);
		if (partialPositionalSelection) {
			const base = Number(visibleOptions[0]?.metro_base_silabas);
			if (selectedOptions.length === 0) {
				return `Ningún verso quebrado${Number.isFinite(base) ? ` · todos, ${base} síl.` : ''}`;
			}
			const broken = selectedOptions.map((option: MetricCatalogDomainRow) => {
				const position = Number(option.posicion_unidad);
				const syllables = Number(option.metro_silabas);
				return Number.isFinite(syllables)
					? `v. ${position} (${syllables} síl.)`
					: String(option.nombre);
			});
			const remaining = visiblePositions.length - selectedOptions.length;
			return `Quebrados: ${broken.join(', ')}${
				remaining > 0 && Number.isFinite(base)
					? ` · los demás, ${base} síl.`
					: ''
			}`;
		}
		// Cualquier respuesta por posiciones se lee en serie, no enumerando nombres de opción.
		if (positional) {
			const serie = serieDeMedidas();
			if (serie) return serie;
		}
		const names = selectedOptions.map((option: MetricCatalogDomainRow) => String(option.nombre));
		const distinct = [...new Set(names)];
		if (names.length > 1 && distinct.length === 1) {
			return `${distinct[0]} · ${names.length} posiciones`;
		}
		return names.join(' · ');
	});

	/**
	 * **La respuesta en notación, para leerla de un golpe.**
	 *
	 * Plegada, una unidad se lee mejor con la notación que con la prosa: `abab|cdcd` dice lo mismo
	 * que «las dos cruzadas» sin gastar una línea, y `8·8·8·4·8·8·8·4` dice de un vistazo lo que
	 * «quebrados: v. 4 (4 síl.), v. 8 (4 síl.) · los demás, 8 síl.» obliga a reconstruir verso a
	 * verso. La prosa se queda donde se responde, que es donde hay que elegir.
	 *
	 * Devuelve `null` cuando la pregunta no tiene notación, y entonces vale el resumen de siempre.
	 */
	const notacionResumen = $derived.by(() => {
		const selectedOptions = visibleOptions.filter((option: MetricCatalogDomainRow) =>
			props.selectedIds.includes(String(option.opcion_eleccion_id))
		);
		// Un esquema escrito a mano ya viene en notación.
		if (selectedOptions.length === 0 && props.textValue) return props.textValue;

		if (positional) return serieDeMedidas();

		// `catalogados` viene identificado por la **opción**, no por el esquema: es lo que el editor
		// guarda, y así lo escribe quien construye la norma. Buscar por `esquema_rima_id` no
		// encontraba nada y la rima caía al resumen en prosa.
		const catalogados = props.normaEsquema?.catalogados ?? [];
		const notaciones = selectedOptions
			.map(
				(option: MetricCatalogDomainRow) =>
					catalogados.find(
						(candidato: EsquemaCatalogado) =>
							candidato.esquemaRimaId === String(option.opcion_eleccion_id)
					)?.notacion
			)
			.filter((notacion: string | null | undefined): notacion is string => Boolean(notacion));
		return notaciones.length > 0 ? [...new Set(notaciones)].join(' · ') : null;
	});

	/** «rima», «medida»: el nombre largo del grupo sobra cuando solo se está leyendo. */
	const etiquetaResumen = $derived(
		props.group.dimension === 'rima'
			? 'rima'
			: props.group.dimension === 'metro'
				? 'medida'
				: String(props.label ?? props.group.nombre).toLocaleLowerCase('es')
	);
</script>

{#if collapsed && props.resumen}
	<p class="text-sm leading-snug">
		<span class="text-[color:var(--muted-foreground)]">{etiquetaResumen}:</span>
		<span class="tabular-nums">{notacionResumen ?? answerSummary}</span>
	</p>
{:else}
<fieldset class="form-field">
	{#if !props.sinRotulo}
		<legend class="form-label">
			<span class="form-label-with-help">
				{props.label ?? String(props.group.nombre)}{optional ? '' : ' *'}
				{#if props.group.ayuda_editor}
					<FieldHelpTooltip
						text={String(props.group.ayuda_editor)}
						label={`Ayuda sobre «${String(props.group.nombre)}»`}
					/>
				{/if}
			</span>
		</legend>
	{/if}

	{#if collapsed}
		<div class="border border-[color:var(--border)] bg-white text-sm">
			{#if props.compactNote}
				<p class="border-b border-[color:var(--border)] bg-[color:var(--muted)] px-3 py-1.5 text-xs font-medium text-[color:var(--muted-foreground)]">
					{props.compactNote}
				</p>
			{/if}
			<div class="flex flex-wrap items-baseline justify-between gap-2 px-3 py-2">
				<span>{answerSummary}</span>
				{#if !props.hideCompactAction}
					<button
						type="button"
						class="link-action"
						onclick={() => (props.onExpand ? props.onExpand() : (expanded = true))}
					>
						{props.changeLabel ?? 'Cambiar'}
					</button>
				{/if}
			</div>
		</div>
	{:else if esSerieDeMedidas}
		<div class="space-y-1">
			<input
				type="text"
				inputmode="numeric"
				class="w-full border border-[color:var(--border)] px-3 py-2 text-sm"
				value={props.textValue ?? ''}
				placeholder={props.normaEsquema?.versos
					? Array.from({ length: Math.min(props.normaEsquema.versos, 8) }, () => '11').join(' ')
					: '11 7 11'}
				oninput={(event) => props.onTextChange?.(event.currentTarget.value)}
			/>
			{#if faltanMedidas !== null && faltanMedidas !== 0}
				<p class="text-xs text-[color:var(--muted-foreground)]">
					{faltanMedidas > 0
						? `Faltan ${faltanMedidas} ${faltanMedidas === 1 ? 'medida' : 'medidas'}`
						: `Sobran ${-faltanMedidas} ${faltanMedidas === -1 ? 'medida' : 'medidas'}`}
				</p>
			{/if}
		</div>
	{:else if isRhymeScheme}
		{@render campoEsquemaEscrito('aBaBcC')}
	{:else if showAsCheckbox}
		{@const unica = visibleOptions[0]}
		<label class="flex items-start gap-2 border border-[color:var(--border)] bg-white px-3 py-2 text-sm">
			<input
				type="checkbox"
				class="mt-0.5"
				checked={props.selectedIds.length > 0}
				onchange={(event) =>
					props.onChange(
						event.currentTarget.checked ? [String(unica.opcion_eleccion_id)] : []
					)}
			/>
			<span>
				{String(unica.nombre)}
				{#if unica.descripcion}
					<span class="block text-xs text-[color:var(--muted-foreground)]">
						{@html renderInlineMarkdown(String(unica.descripcion))}
					</span>
				{/if}
			</span>
		</label>
	{:else if showAsList}
		<div class="space-y-1">
			{#each visibleOptions as option (String(option.opcion_eleccion_id))}
				{@const id = String(option.opcion_eleccion_id)}
				<label
					class={`flex cursor-pointer items-start gap-2 border px-3 py-2 text-sm ${
						props.selectedIds.includes(id)
							? 'border-[color:var(--primary)] bg-[color:var(--muted)]'
							: 'border-[color:var(--border)] bg-white'
					}`}
				>
					<input
						type="radio"
						class="mt-0.5"
						name={String(props.group.grupo_eleccion_id)}
						checked={props.selectedIds.includes(id) && !escribiendoEsquema}
						onchange={() => {
							dejarDeEscribir();
							props.onChange([id]);
						}}
					/>
					<span>
						{String(option.nombre)}
						{#if option.descripcion}
							<span class="block text-xs text-[color:var(--muted-foreground)]">
								{@html renderInlineMarkdown(String(option.descripcion))}
							</span>
						{/if}
					</span>
				</label>
			{/each}
			{#if ofreceOtra}
				<label
					class={`flex cursor-pointer items-start gap-2 border px-3 py-2 text-sm ${
						escribiendoEsquema
							? 'border-[color:var(--primary)] bg-[color:var(--muted)]'
							: 'border-[color:var(--border)] bg-white'
					}`}
				>
					<input
						type="radio"
						class="mt-0.5"
						name={String(props.group.grupo_eleccion_id)}
						checked={escribiendoEsquema}
						onchange={elegirOtra}
					/>
					<span>Rima de otra manera</span>
				</label>
			{/if}
			{#if optional}
				<button
					type="button"
					class="link-action text-xs"
					disabled={props.selectedIds.length === 0}
					onclick={() => props.onChange([])}
				>
					Quitar selección
				</button>
			{/if}
		</div>
	{:else if positional && maximum === 1 && !partialPositionalSelection && !positionalAlternatives}
		<!--
			Posicional pero sin alternativas: no hay medidas que comparar, solo la posición.
		-->
		<div class="flex flex-wrap gap-2">
			{#each visibleOptions as option (String(option.opcion_eleccion_id))}
				<label
					class={`flex min-h-10 min-w-10 cursor-pointer items-center justify-center border px-3 text-sm ${
						props.selectedIds.includes(String(option.opcion_eleccion_id))
							? 'border-[color:var(--primary)] bg-[color:var(--primary)] text-white'
							: 'border-[color:var(--border)] bg-white'
					}`}
					title={String(option.nombre)}
				>
					<input
						type="radio"
						class="sr-only"
						checked={props.selectedIds.includes(String(option.opcion_eleccion_id))}
						onchange={() => props.onChange([String(option.opcion_eleccion_id)])}
					/>
					<span>{Number(option.posicion_unidad)}</span>
				</label>
			{/each}
		</div>
	{:else if maximum === 1 && !partialPositionalSelection && !positionalAlternatives}
		<select
			class={`w-full border bg-white px-3 text-sm ${
				celda ? 'h-9 max-w-sm' : 'h-10'
			} ${
				props.selectedIds.length === 0 && !optional
					? 'border-[color:var(--primary)]'
					: 'border-[color:var(--border)]'
			}`}
			value={escribiendoEsquema ? OTRA : (props.selectedIds[0] ?? '')}
			onchange={changeSingle}
		>
			<option value="">
				{optional ? 'Sin seleccionar' : 'Seleccionar una respuesta'}
			</option>
			{#each visibleOptions as option (String(option.opcion_eleccion_id))}
				<option value={String(option.opcion_eleccion_id)} title={stripMarkdown(String(option.descripcion ?? ''))}>
					{String(option.nombre)}
				</option>
			{/each}
			{#if ofreceOtra}
				<option value={OTRA}>Rima de otra manera…</option>
			{/if}
		</select>
	{:else if partialPositionalSelection}
		<MetricPartialPositionField
			options={visibleOptions}
			selectedKeys={props.selectedIds}
			keyField="opcion_eleccion_id"
			minimum={minimum}
			maximum={effectiveMaximum}
			pendingPositions={props.pendingPositions}
			onPendingPositionsChange={props.onPendingPositionsChange}
			ariaLabel={props.label ?? String(props.group.nombre)}
			onChange={props.onChange}
		/>
	{:else if positionalAlternatives}
		<!--
			**La rejilla es la de la unidad, no la de las posiciones que preguntan.**

			Se dibujaba tantas filas como opciones hubiera, empezando en la primera: con los quebrados
			de la manriqueña, que van en los versos 3, 6, 9 y 12, salían cuatro filas seguidas —3, 4,
			5 y 6— y los otros ocho versos no aparecían. Ahora se pinta la unidad entera y cada verso
			sale con lo suyo: los que la norma deja abiertos preguntan, y los que fija se ven fijados.
		-->
		<MetricVersePatternField
			length={patternLength}
			positionStart={patternStart}
			medidasFijas={props.medidasFijas}
			options={visibleOptions}
			selectedIds={props.selectedIds}
			onMeasureChange={props.onChange}
		/>
	{:else if positional}
		<div class="flex flex-wrap gap-2">
			{#each visibleOptions as option (String(option.opcion_eleccion_id))}
				<label
					class={`flex min-h-10 min-w-10 cursor-pointer items-center justify-center border px-3 text-sm ${
						props.selectedIds.includes(String(option.opcion_eleccion_id))
							? 'border-[color:var(--primary)] bg-[color:var(--primary)] text-white'
							: 'border-[color:var(--border)] bg-white'
					}`}
					title={String(option.nombre)}
				>
					<input
						type="checkbox"
						class="sr-only"
						checked={props.selectedIds.includes(String(option.opcion_eleccion_id))}
						onchange={(event) =>
							toggleOption(
								String(option.opcion_eleccion_id),
								event.currentTarget.checked
							)}
					/>
					<span>{Number(option.posicion_unidad)}</span>
				</label>
			{/each}
		</div>
		<p class="text-xs text-[color:var(--muted-foreground)]">
			{props.selectedIds.length} de {effectiveMaximum} posiciones seleccionadas
		</p>
	{:else}
		<div class="grid gap-2 sm:grid-cols-2">
			{#each visibleOptions as option (String(option.opcion_eleccion_id))}
				<label class="flex items-start gap-2 border border-[color:var(--border)] bg-white px-3 py-2 text-sm">
					<input
						type="checkbox"
						class="mt-0.5"
						checked={props.selectedIds.includes(String(option.opcion_eleccion_id))}
						onchange={(event) =>
							toggleOption(
								String(option.opcion_eleccion_id),
								event.currentTarget.checked
							)}
					/>
					<span>{String(option.nombre)}</span>
				</label>
			{/each}
		</div>
	{/if}

	<!--
		La salida abierta del control híbrido, **detrás de su opción**: la norma acota un repertorio
		y escribir es para lo que el repertorio no cubre, así que no compite con la lista. Si lo
		escrito resulta ser una de las catalogadas, se marca esa, se dice cuál y el campo se retira.
	-->
	<!-- Sin repertorio el campo escrito ya es el control entero, y no se pinta dos veces. -->
	{#if ofreceOtra && escribiendoEsquema && !collapsed}
		<div class="mt-2 border-t border-[color:var(--border)] pt-2">
			<p class="form-help mb-1">
				Escribe la disposición que has leído, una letra por verso y un guion para el verso
				suelto.
			</p>
			{@render campoEsquemaEscrito('abcabc')}
		</div>
	{/if}
	{#if coincidencia && !collapsed}
		<div
			class="mt-2 flex flex-wrap items-center gap-x-3 gap-y-1 border border-[color:var(--primary)] bg-[color:var(--muted)] px-3 py-2 text-sm"
		>
			<p class="min-w-0 flex-1">
				La disposición anotada coincide con <strong>{coincidencia.nombre}</strong>, que ya está
				en el repertorio.
			</p>
			<button type="button" class="link-action" onclick={marcarCoincidencia}>
				Marcarla
			</button>
			<button type="button" class="link-action" onclick={descartarCoincidencia}>
				Intentar de nuevo
			</button>
		</div>
	{/if}

	{#if props.showDescription && !collapsed && descripcionElegida}
		<p class="form-help">{@html renderInlineMarkdown(descripcionElegida)}</p>
	{/if}

	<div class={`flex flex-wrap gap-x-4 gap-y-1 ${collapsed ? 'hidden' : 'mt-1'}`}>
		{#if props.onApplyAll && props.group.permite_aplicar_global}
			<button
				type="button"
				class="link-action"
				onclick={props.onApplyAll}
				disabled={isRhymeScheme
					? !(props.textValue ?? '').trim()
					: props.selectedIds.length === 0}
			>
				Aplicar esta respuesta a todas las unidades equivalentes
			</button>
		{/if}

		{#if puedeRellenarPosiciones}
			<button type="button" class="link-action" onclick={rellenarPosiciones}>
				Repetir esta medida en las demás posiciones
			</button>
		{/if}
	</div>
</fieldset>
{/if}

{#snippet campoEsquemaEscrito(ejemplo: string)}
	<div class={preguntaElRegimen ? 'flex gap-2' : ''}>
		<input
			type="text"
			class={`h-10 w-full border bg-white px-3 font-mono text-sm tracking-wide ${
				errorEscrito ? 'border-[color:var(--destructive)]' : 'border-[color:var(--border)]'
			}`}
			value={escrito.notacion}
			placeholder={ejemplo}
			autocomplete="off"
			spellcheck="false"
			aria-invalid={errorEscrito ? 'true' : undefined}
			oninput={(event) => escribirNotacion(event.currentTarget.value)}
		/>
		<!--
			El régimen solo se pregunta donde varía dentro de la arquitectura. La octava aguda tiene
			`---a---a` consonante y `---a---a` asonante: sin esto, lo escrito no identifica cuál de
			las dos se ha leído. Donde la arquitectura declara un régimen único se hereda y no hay
			nada que preguntar.
		-->
		{#if preguntaElRegimen}
			<select
				class="h-10 shrink-0 border border-[color:var(--border)] bg-white px-2 text-sm"
				value={escrito.regimen ?? ''}
				aria-label="Régimen de rima"
				onchange={(event) => escribirRegimen(event.currentTarget.value)}
			>
				<option value="">¿Cómo rima?</option>
				{#each regimenesPosibles as regimen (regimen.slug)}
					<option value={regimen.slug}>{regimen.etiqueta}</option>
				{/each}
			</select>
		{/if}
	</div>
	{#if errorEscrito}
		<p class="mt-1 text-xs text-[color:var(--destructive)]">{errorEscrito}</p>
	{/if}
	<!--
		Lo que rompe una restricción declarada se avisa y no se bloquea: un pasaje real puede
		apartarse de su norma, y para eso está el registro de desviaciones.
	-->
	{#each avisosEscritos as aviso}
		<p class="mt-1 text-xs text-[color:var(--muted-foreground)]">{aviso} Si es lo que dice el
			texto, regístralo como desviación.</p>
	{/each}
{/snippet}
