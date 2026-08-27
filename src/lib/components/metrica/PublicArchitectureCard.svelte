<script lang="ts">
	import type {
		PublicArchitecture,
		PublicMetricScheme,
		PublicRhymeRestriction,
		PublicRhymeScheme,
		PublicTrait
	} from '$lib/metrica/formas-publicas.types';
	import type { FilaDeRima, Rejilla } from '$lib/metrica/rejilla';
	import MetricPositionGrid from './MetricPositionGrid.svelte';
	import MetricDeterminationLabel from './MetricDeterminationLabel.svelte';
	import PublicFormSectionTree from './PublicFormSectionTree.svelte';
	import Badge from '$lib/components/ui/badge.svelte';
	import InlineNotePopover from '$lib/components/ui/inline-note-popover.svelte';
	import { renderInlineMarkdown } from '$lib/utils/markdown';
	import {
		determinacionDeExtension,
		determinacionDeMedida,
		determinacionDePartes,
		determinacionDeRepeticion,
		determinacionDeRima,
		type DeterminacionMetrica
	} from '$lib/metrica/determinacion';
	import { rangoDeModalidad } from '$lib/metrica/modalidad';

	/**
	 * Una arquitectura, leída **dimensión a dimensión**: extensión, medida, rima, partes,
	 * repetición y rasgos, una fila por cada una y con marca de cuánto deja determinado la
	 * arquitectura y cuánto concreta cada poema.
	 *
	 * Lo que sustituye: una plantilla que enseñaba prosa y repetía cada hecho hasta cuatro veces
	 * —el reparto en partes salía en la figura, en la lista de partes y en la glosa del esquema—.
	 * Aquí cada hecho se dice una vez, en su dimensión, y la prosa del catálogo solo aparece
	 * cuando dice algo que la figura no puede dibujar.
	 */
	const { arquitectura }: { arquitectura: PublicArchitecture } = $props();

	/**
	 * Los dos perfiles que **no** son una serie: lo que se repite en ellos es una parte con
	 * nombre —la estancia de la canción, el ciclo de copla del villancico—, no un verso.
	 */
	const esComposicion = $derived(
		arquitectura.perfil === 'estancias_declaradas' ||
			arquitectura.perfil === 'composicion_con_estribillo'
	);

	/**
	 * La extensión de la arquitectura.
	 *
	 * Una unidad sin extensión declarada era «serie abierta» viniera de donde viniera, y eso
	 * imprimía «serie» sobre seis composiciones —las tres de la canción, las dos del villancico
	 * y la del zéjel—, que no lo son y cuya propia cabecera dice «Composición». Una composición
	 * no se mide en versos: se mide en cuántas veces vuelve su parte, y eso lo declara la parte.
	 */
	function extension(): string {
		const { unidadMin: min, unidadMax: max } = arquitectura;
		if (min == null && max == null) {
			if (!esComposicion) return 'serie abierta';
			const raiz = arquitectura.secciones.find(
				(seccion) => (seccion.repeticionesMin ?? 0) >= 1 && seccion.repeticionesMax === null
			);
			if (!raiz) return 'composición abierta';
			return `${raiz.repeticionesMin} o más apariciones de «${raiz.nombre}»`;
		}
		if (min != null && max != null) {
			return min === max ? `${min} versos` : `de ${min} a ${max} versos`;
		}
		return min != null ? `desde ${min} versos` : `hasta ${max} versos`;
	}

	/** El repertorio de una medida no fijada, dicho una vez: «7 u 11 sílabas». */
	function repertorio(esquema: PublicMetricScheme): string {
		const dominantes = esquema.repertorio.filter((medida) => medida.rol === 'dominante');
		const quebrados = esquema.repertorio.filter((medida) => medida.rol === 'quebrado');
		const listar = (medidas: typeof esquema.repertorio) =>
			medidas.map((medida) => medida.silabas).join(' · ');
		if (dominantes.length > 0 && quebrados.length > 0) {
			return `${listar(dominantes)} de base, con quebrados de ${listar(quebrados)}`;
		}
		return `${listar(esquema.repertorio)} sílabas`;
	}

	const repertoriosAbiertos = $derived(
		arquitectura.esquemasMetricos.filter((esquema) => esquema.repertorio.length > 1)
	);
	const esquemasAbiertos = $derived(
		arquitectura.esquemasRima.filter((esquema) => esquema.abierto)
	);
	const repeticionesNorma = $derived(
		arquitectura.repeticiones.filter((repeticion) => !repeticion.esAlternativa)
	);
	const repeticionesElegibles = $derived(
		arquitectura.repeticiones.filter((repeticion) => repeticion.esAlternativa)
	);
	const extensionDeterminada = $derived(determinacionDeExtension(arquitectura));
	const medidaDeterminada = $derived(determinacionDeMedida(arquitectura));
	const rimaDeterminada = $derived(determinacionDeRima(arquitectura));
	const partesDeterminadas = $derived(determinacionDePartes(arquitectura));
	/** Lo que puede darse sin ser norma, venga o no con pregunta para el editor. */
	const permitidosYOpcionales = $derived([
		...arquitectura.rasgos.permitidos,
		...arquitectura.rasgos.opcionales
	]);

	/**
	 * Las disposiciones agrupadas por la parte de la que son, en orden de lectura. El soneto
	 * elige una para sus cuartetos **y otra** para sus tercetos, y eso solo se entiende si cada
	 * parte lleva su rótulo y su cuenta.
	 */
	const gruposDeRima = $derived.by(() => {
		const grupos: { parte: string | null; filas: FilaDeRima[] }[] = [];
		const porParte = new Map<string, (typeof grupos)[number]>();
		for (const fila of arquitectura.rejilla?.filasDeRima ?? []) {
			const clave = fila.parte ?? '';
			const grupo = porParte.get(clave);
			if (grupo) grupo.filas.push(fila);
			else {
				const nuevo = { parte: fila.parte, filas: [fila] };
				porParte.set(clave, nuevo);
				grupos.push(nuevo);
			}
		}
		return grupos;
	});
	const esquemasRimaDibujados = $derived(
		new Set(gruposDeRima.flatMap((grupo) => grupo.filas.map((fila) => fila.esquemaRimaId)))
	);
	/** Disposiciones cerradas que existen en el catálogo pero no caben en una rejilla abierta. */
	const esquemasCerradosSinDibujo = $derived(
		arquitectura.esquemasRima.filter(
			(esquema) => !esquema.abierto && !esquemasRimaDibujados.has(esquema.id)
		)
	);

	/**
	 * La glosa de cada disposición, para que la rejilla la ofrezca **en su fila**.
	 *
	 * Antes se abría desde un botón «Qué distingue X» debajo del dibujo y ocupaba una columna
	 * entera. Eran dos sitios para una nota que es de una fila concreta, y el rótulo prometía un
	 * contraste que la nota no siempre hace. Ahora es el icono de nota de siempre, junto al
	 * nombre de la disposición, como el resto de las notas de la ficha.
	 */
	const glosas = $derived(
		Object.fromEntries(
			arquitectura.esquemasRima
				.filter((esquema) => esquema.descripcion)
				.map((esquema) => [esquema.id, esquema.descripcion])
		)
	);

	/**
	 * Los otros nombres de cada disposición, para que la rejilla los ponga junto al suyo.
	 *
	 * `denominaciones_metricas` los guarda con `esquema_rima_id` y el tipo los trae desde el
	 * principio —«cuarteta» es la redondilla cruzada, no la redondilla—, pero **no se pintaban en
	 * ninguna parte**: la ficha de la redondilla enseñaba dos fuentes discutiendo la cuarteta sin
	 * que la palabra apareciera en la figura.
	 */
	/**
	 * Si lo que vuelve en esta arquitectura son palabras y no rimas.
	 *
	 * La sextina dibuja seis guiones bajo «Sin rima», que es cierto y deja al lector sin saber qué
	 * la sostiene. Lo dice la fila «Repetición», pero queda más abajo y tras un icono, así que la
	 * rejilla lo imprime también al pie, junto al dibujo que lo provoca.
	 */
	/**
	 * El código de una variedad, sin la notación que lleva detrás.
	 *
	 * Se llaman «A1 · aBaBcC», y aquí la notación sobra porque la rejilla la dibuja justo debajo y
	 * con la caja ya deducida de la medida. **En el editor no sobra**: allí la opción se lee sin
	 * dibujo al lado y «A1» a secas sería opaco, así que el nombre guardado se queda entero y es
	 * la ficha la que se queda con la primera parte.
	 */
	const codigoDeVariedad = (nombre: string): string => nombre.split(' · ')[0].trim() || nombre;

	const palabraFinal = $derived(
		arquitectura.repeticiones.some((repeticion) => repeticion.tipo === 'palabra_final')
	);

	const denominacionesDeRima = $derived(
		Object.fromEntries(
			arquitectura.esquemasRima
				.filter((esquema) => esquema.denominaciones.length > 0)
				.map((esquema) => [esquema.id, esquema.denominaciones])
		)
	);

	/**
	 * A partir de cuántos valores un rasgo excluyente pasa de lista en columna a fila envuelta.
	 *
	 * Los dos o tres valores de un rasgo ordinario piden una línea cada uno, porque llevan detrás
	 * su modalidad y a veces su nota. Un inventario cerrado y de nombres cortos —las diecinueve
	 * asonancias— pide lo contrario: puestos en columna eran diecinueve líneas iguales, y en fila
	 * caben en dos. **No se esconde ninguno**: el recuento acompaña a los valores, no los sustituye.
	 */
	const TOPE_ENUMERAR_RASGOS = 6;

	/**
	 * Un inventario largo se ordena por su nombre, dentro de cada modalidad.
	 *
	 * El `orden` que trae la opción no significa nada para estos valores: las mismas diecinueve
	 * asonancias llegaban en un orden distinto en cada arquitectura del romance, de modo que el
	 * mismo inventario parecía dos. Cuando nada distingue a unos valores de otros, el orden del
	 * nombre es el único que el lector puede seguir. En `arquitectura_rasgos.nombre` está el
	 * nombre del rasgo, igual en todas las filas, así que la comparación va por `valor`.
	 */
	const ordenarInventario = (valores: PublicTrait[]) =>
		[...valores].sort(
			(a, b) =>
				rangoDeModalidad(a.modalidad) - rangoDeModalidad(b.modalidad) ||
				String(a.valor ?? '').localeCompare(String(b.valor ?? ''), 'es', {
					sensitivity: 'base',
					numeric: true
				})
		);

	/**
	 * Las restricciones de un esquema abierto, en una sola frase.
	 *
	 * Se unían con `'. '`, y una descripción escrita a mano acaba en punto de forma natural, así
	 * que salía «…de esta arquitectura.. La disposición debe ser regular». Hoy no queda ninguna
	 * que acabe en punto —las redacciones por tipo no lo llevan—, pero la próxima que se escriba
	 * volvería a romperlo.
	 */
	const unirRestricciones = (restricciones: PublicRhymeRestriction[]) =>
		restricciones
			.map((restriccion) => restriccion.texto.replace(/\s*\.\s*$/, ''))
			.filter(Boolean)
			.join('. ');

	/** La modalidad compartida por todos los valores, cuando la comparten. */
	const modalidadComun = (valores: PublicTrait[]) => {
		const modalidades = new Set(valores.map((valor) => valor.modalidad ?? ''));
		return modalidades.size === 1 ? (valores[0]?.modalidad ?? null) : null;
	};

	/** Una disposición autónoma cuando la arquitectura abierta no ofrece columnas comunes. */
	function rejillaDeEsquema(esquema: PublicRhymeScheme): Rejilla {
		return {
			celdas: esquema.figura.map((_, indice) => ({ verso: indice + 1, medida: null })),
			filasDeRima: [
				{
					esquemaRimaId: esquema.id,
					nombre: esquema.nombre,
					notacion: esquema.notacion,
					modalidad: esquema.modalidad ?? null,
					tipoRima: esquema.tipoRima,
					parte: esquema.deLaSeccion,
					desde: 1,
					hasta: esquema.figura.length,
					clases: esquema.figura
				}
			],
			bandas: [],
			enlaces: [],
			// Aquí solo se dibuja una disposición, así que el esqueleto es suyo por definición.
			esqueletoDe: esquema.id,
			cicla: esquema.cicla,
			// Es la rima la que cicla aquí, no una medida repetida.
			cicloSoloMetrico: false,
			recortada: false,
			tieneMedida: false,
			tieneRima: true,
			parte: esquema.deLaSeccion,
			repeticionesDeLaParte: null
		};
	}
</script>

{#snippet dimension(
	rotulo: string,
	determinacion: DeterminacionMetrica,
	ayuda: string | null = null
)}
	<th class="w-40 py-2.5 pr-4 align-top text-left">
		<span
			class="inline-flex items-center gap-1 text-[0.66rem] font-semibold uppercase tracking-[0.07em] text-[color:var(--muted-foreground)]"
		>
			{rotulo}
			{#if ayuda}
				<InlineNotePopover text={ayuda} label={`Explicar ${rotulo.toLocaleLowerCase('es')}`} />
			{/if}
		</span>
		<MetricDeterminationLabel valor={determinacion} />
	</th>
{/snippet}

{#snippet rasgoLinea(rasgo: PublicTrait)}
	<!--
		Un rasgo de un solo valor se etiqueta con el nombre del rasgo y no con el del valor —lo
		hace `opciones_eleccion_derivadas`, y en el editor es lo correcto: una casilla suelta debe
		decir «Dístico final», no «Presente»—. Aquí eso imprimía «Dístico final: Dístico final».
		Cuando el valor repite el nombre, se imprime solo el nombre.
	-->
	{@const valorPropio = rasgo.valor && rasgo.valor !== rasgo.nombre ? rasgo.valor : null}
	<li>
		{rasgo.nombre}{valorPropio ? ': ' : ''}{#if valorPropio}<span class="font-medium"
				>{valorPropio}</span
			>{/if}
		{#if rasgo.modalidad}
			<span class="text-[color:var(--muted-foreground)]">· {rasgo.modalidad}</span>
		{/if}
		{#if rasgo.posicionesMax !== null}
			<span class="text-[color:var(--muted-foreground)]">
				· hasta {rasgo.posicionesMax}
				{rasgo.posicionesMax === 1 ? 'posición' : 'posiciones'}
			</span>
		{/if}
		{#if rasgo.denominaciones.length > 0}
			<!--
				Cómo se llama la realización que tiene el rasgo, en línea y no dentro de la nota:
				quien busca «novena de pie quebrado» tiene que encontrarla sin abrir nada. La nota
				se conserva porque dice otra cosa — dónde cae el quiebro en esta arquitectura.
			-->
			<span class="text-[color:var(--muted-foreground)] italic">
				· {rasgo.denominaciones.join(' · ')}
			</span>
		{/if}
		{#if rasgo.nota}
			<InlineNotePopover text={rasgo.nota} label={`Mostrar nota sobre ${rasgo.nombre}`} />
		{/if}
	</li>
{/snippet}

<section class="min-w-0 border border-[color:var(--border)] bg-white p-5 shadow-sm md:p-6">
	<div class="flex flex-wrap items-baseline gap-x-3 gap-y-1">
		<h3 class="font-display text-2xl text-[color:var(--gray-900)]">{arquitectura.nombre}</h3>
		<div class="flex flex-wrap items-center gap-1.5">
			{#if arquitectura.principal}
				<Badge class="bg-[color:var(--gray-100)] text-[0.7rem] text-[color:var(--gray-700)]">
					Principal
				</Badge>
			{/if}
			{#if arquitectura.modalidad}
				<Badge class="bg-[color:var(--gray-100)] text-[0.7rem] capitalize text-[color:var(--gray-700)]">
					{arquitectura.modalidad}
				</Badge>
			{/if}
		</div>
	</div>

	{#if arquitectura.descripcion}
		<p class="mt-2 max-w-3xl leading-7">{@html renderInlineMarkdown(arquitectura.descripcion)}</p>
	{/if}
	{#if arquitectura.denominaciones.length > 0}
		<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">
			También: {arquitectura.denominaciones.join(' · ')}
		</p>
	{/if}

	<div class="mt-4 overflow-x-auto">
	<table class="w-full min-w-[38rem] border-collapse text-sm">
		<tbody>
			<tr class="border-t border-[color:var(--border)]">
				{@render dimension('Extensión', extensionDeterminada)}
				<td class="py-2.5 align-top">{extension()}</td>
			</tr>

			<!-- Cuando la arquitectura se elige por variedad, medida y rima no son dos preguntas:
			     son las dos caras de una, y separarlas obliga a recomponer las parejas de memoria. -->
			{#if arquitectura.eligeVariedad}
				<tr class="border-t border-[color:var(--border)]">
					{@render dimension('Variedades', medidaDeterminada)}
					<td class="py-2.5 align-top">
						<!--
							Una variedad empareja medida y rima, así que se dibuja como todo lo demás de la
							ficha: las dos alineadas verso a verso. Antes se leía «A1 · aBaBcC», luego
							`7-11-7-11-7-11` y luego `ababcc` en tres columnas, y había que cruzarlas de
							memoria; encima la última va sin caja, porque el esquema lo comparten tres
							variedades de medidas distintas y la caja depende de la medida. Dibujadas
							juntas, la caja se deduce y las tres columnas sobran.
						-->
						<ul class="space-y-3">
							{#each arquitectura.variedades as variedad, i (`v:${i}`)}
								<li>
									<p class="text-xs">
										<span class="font-medium">{codigoDeVariedad(variedad.nombre)}</span>
										{#if variedad.modalidad}
											<span class="text-[color:var(--muted-foreground)]">
												· {variedad.modalidad}
											</span>
										{/if}
									</p>
									{#if variedad.rejilla}
										<div class="mt-1">
											<MetricPositionGrid
												rejilla={variedad.rejilla}
												bandas={false}
												pie={false}
												modalidades={false}
												prefijoDeFila="esquema"
												cajaSegunMedida
											/>
										</div>
									{:else}
										<p class="font-mono text-xs">
											{[variedad.medida, variedad.rima].filter(Boolean).join(' · ')}
										</p>
									{/if}
								</li>
							{/each}
						</ul>
					</td>
				</tr>
			{:else}
				{#if repertoriosAbiertos.length === 0 && arquitectura.rejilla?.tieneMedida}
					<tr class="border-t border-[color:var(--border)]">
						{@render dimension('Medida', medidaDeterminada)}
						<td class="py-2.5 align-top">
							<!-- Sin pie: el ciclo y los enlaces hablan del dibujo entero y se dicen una sola
							     vez, abajo, donde está la rima que los produce. -->
							<MetricPositionGrid
								rejilla={arquitectura.rejilla}
								mostrar="medida"
								bandas={false}
								pie={false}
							/>
						</td>
					</tr>
				{/if}

				{#each repertoriosAbiertos as esquema, i (`m:${i}`)}
					<tr class="border-t border-[color:var(--border)]">
						{@render dimension(
							esquema.deLaSeccion ? `Medida · ${esquema.deLaSeccion}` : 'Medida',
							medidaDeterminada
						)}
						<td class="py-2.5 align-top">
							<span class="font-medium">{repertorio(esquema)}</span>
							{#if esquema.descripcion}
								<InlineNotePopover
									text={esquema.descripcion}
									label="Mostrar explicación de la medida"
								/>
							{/if}
						</td>
					</tr>
				{/each}

				<tr class="border-t border-[color:var(--border)]">
					{@render dimension('Rima', rimaDeterminada)}
					<td class="py-2.5 align-top">
						<!-- El régimen es lo primero que hay que saber de una rima, y se declara en el
						     nivel que le corresponde: arriba si es uno, y en cada disposición si dentro
						     de la arquitectura varía. -->
						{#if arquitectura.tipoRima}
							<span class="font-medium">{arquitectura.tipoRima}</span>
						{:else if arquitectura.tipoRimaPorDisposicion}
							<span class="text-[color:var(--muted-foreground)]">según la disposición</span>
						{:else}
							<span class="text-[color:var(--danger)]">
								El catálogo no declara el régimen de rima.
							</span>
						{/if}

						{#each gruposDeRima as grupo, i (`g:${i}`)}
							{#if grupo.parte}
								<p class="mt-2 text-[0.66rem] uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
									{grupo.parte}
									<span class="normal-case tracking-normal">
										— {grupo.filas.length > 1
											? `una de ${grupo.filas.length}`
											: 'disposición única'}
									</span>
								</p>
							{/if}
							<div class="mt-1">
								<MetricPositionGrid
									rejilla={arquitectura.rejilla!}
									mostrar="rima"
									filas={grupo.filas}
									numeros={i === gruposDeRima.length - 1}
									bandas={i === gruposDeRima.length - 1}
									{glosas}
									denominaciones={denominacionesDeRima}
									{palabraFinal}
								/>
							</div>
						{/each}

						{#if esquemasCerradosSinDibujo.length > 0}
							<div class="mt-2 space-y-2">
								{#each esquemasCerradosSinDibujo as esquema (esquema.id)}
									<div class="flex items-start gap-1">
										<MetricPositionGrid
											rejilla={rejillaDeEsquema(esquema)}
											mostrar="rima"
											bandas={false}
										/>
										{#if esquema.descripcion}
											<InlineNotePopover
												text={esquema.descripcion}
												label={`Mostrar explicación de ${esquema.nombre}`}
											/>
										{/if}
									</div>
								{/each}
							</div>
						{/if}

						{#if !arquitectura.declaraNormaDeRima}
							<p class="mt-2 text-[color:var(--danger)]">
								El catálogo no dice cómo se comporta la rima de esta arquitectura: ni la acota
								con restricciones, ni declara su densidad, ni recoge disposiciones concretas.
							</p>
						{/if}

						{#if esquemasAbiertos.length > 0}
							<ul class="mt-2 space-y-1">
								{#each esquemasAbiertos as esquema (esquema.id)}
									<li>
										{#if esquema.deLaSeccion}
											<span class="text-[color:var(--muted-foreground)]">
												{esquema.deLaSeccion}:
											</span>
										{/if}
						<!-- Un esquema abierto sin restricciones **no es un defecto**: es una forma
						     que no fija su disposición, y decirlo es informar, no fallar. El aviso
						     de que falta el dato es de la arquitectura entera y va más abajo.

						     Restricción y descripción dicen lo mismo por dos vías —qué acota la
						     norma y qué deja variar— y se imprimían distinto: la primera en el
						     texto corriente y la segunda atenuada y aparte, de modo que parecían
						     de rango distinto. Van juntas. Y el aviso por defecto solo aparece
						     cuando no hay ninguna de las dos: con descripción diría dos veces lo
						     mismo. -->
										{#if esquema.restricciones.length > 0}
											{unirRestricciones(esquema.restricciones)}
										{/if}
										{#if esquema.descripcion}
											{#if esquema.restricciones.length > 0}{' '}{/if}{@html renderInlineMarkdown(
												esquema.descripcion
											)}
										{/if}
										{#if esquema.restricciones.length === 0 && !esquema.descripcion}
											<span class="text-[color:var(--muted-foreground)]">
												La disposición no está fijada.
											</span>
										{/if}
									</li>
								{/each}
							</ul>
						{/if}
					</td>
				</tr>
			{/if}

			{#if arquitectura.secciones.length > 0}
				<tr class="border-t border-[color:var(--border)]">
					{@render dimension(
						'Partes',
						partesDeterminadas,
						'El signo × indica cuántas veces puede aparecer una parte dentro de la estructura que la contiene. Cuando no se muestra, aparece una sola vez.'
					)}
					<td class="py-2.5 align-top">
						<PublicFormSectionTree sections={arquitectura.secciones} />
					</td>
				</tr>
			{/if}

			{#if repeticionesNorma.length > 0}
				<tr class="border-t border-[color:var(--border)]">
					{@render dimension('Repetición', determinacionDeRepeticion(arquitectura, false))}
					<td class="py-2.5 align-top">
						<ul class="space-y-1">
							{#each repeticionesNorma as repeticion, i (`rn:${i}`)}
								<li>
									<span class="font-medium">{repeticion.nombre}</span>
									<!--
										La explicación de una repetición vive tras el icono porque la figura suele
										contarla: el estribillo del villancico tiene su banda y su ciclo. La de la
										sextina no tiene figura posible —la rejilla dibuja una estrofa y la
										permutación necesita las seis—, así que ahí es lo único que hay y se lee
										sin pulsar.
									-->
									{#if repeticion.descripcion && repeticion.tipo === 'palabra_final'}
										<span class="block text-[color:var(--muted-foreground)]">
											{@html renderInlineMarkdown(repeticion.descripcion)}
										</span>
									{:else if repeticion.descripcion}
										<InlineNotePopover
											text={repeticion.descripcion}
											label={`Mostrar explicación de ${repeticion.nombre}`}
										/>
									{/if}
								</li>
							{/each}
						</ul>
					</td>
				</tr>
			{/if}

			{#if repeticionesElegibles.length > 0}
				<tr class="border-t border-[color:var(--border)]">
					{@render dimension('Estribillo', determinacionDeRepeticion(arquitectura, true))}
					<td class="py-2.5 align-top">
						<ul class="space-y-1">
							{#each repeticionesElegibles as repeticion, i (`re:${i}`)}
								<li>
									<span class="font-medium">{repeticion.nombre}</span>
									{#if repeticion.modalidad}
										<span class="text-[color:var(--muted-foreground)]">
											· {repeticion.modalidad}
										</span>
									{/if}
								{#if repeticion.descripcion}
									<InlineNotePopover
										text={repeticion.descripcion}
										label={`Mostrar explicación de ${repeticion.nombre}`}
									/>
									{/if}
								</li>
							{/each}
						</ul>
					</td>
				</tr>
			{/if}

			{#if arquitectura.rasgos.declarados.length > 0}
				<tr class="border-t border-[color:var(--border)]">
					{@render dimension('Rasgos', { grado: 'fijo' })}
					<td class="py-2.5 align-top">
						<ul class="space-y-1">
							{#each arquitectura.rasgos.declarados as rasgo, i (`rd:${i}`)}
								{@render rasgoLinea(rasgo)}
							{/each}
						</ul>
					</td>
				</tr>
			{/if}

			<!--
				`permitidos` y `opcionales` se pintaban en dos bloques, «Rasgos permitidos ·
				Permitido» y «Rasgos · Opcional», que dicen lo mismo con dos palabras distintas.
				Lo que de verdad los separa no es del lector sino del editor: `opcionales` son los
				que tienen una pregunta en el formulario y `permitidos` los que no. Para quien lee
				la ficha, los dos son lo mismo —puede darse, con esta frecuencia—, y la modalidad
				impresa al lado ya dice cuánto. Van en un solo bloque; el servidor conserva la
				distinción, que sí le sirve al editor.
			-->
			{#if permitidosYOpcionales.length > 0}
				<tr class="border-t border-[color:var(--border)]">
					{@render dimension('Rasgos permitidos', { grado: 'permitido' })}
					<td class="py-2.5 align-top">
						<ul class="space-y-1">
							{#each permitidosYOpcionales as rasgo, i (`rp:${i}`)}
								{@render rasgoLinea(rasgo)}
							{/each}
						</ul>
					</td>
				</tr>
			{/if}

			{#each arquitectura.rasgos.excluyentes as grupo, i (`rx:${i}`)}
				<tr class="border-t border-[color:var(--border)]">
					{@render dimension(
						grupo.nombre,
						grupo.opcional
							? { grado: 'opcional', detalle: 'una posibilidad como máximo' }
							: { grado: 'variable', detalle: 'una posibilidad' }
					)}
					<td class="py-2.5 align-top">
						<!-- Un inventario cerrado se enseña entero, en fila envuelta y sin repetir la
						     modalidad en cada valor: las diecinueve asonancias del romance ocupan así
						     dos líneas, y de un vistazo se ve que el inventario está cerrado. En
						     columna, con su «· admitida» detrás, eran diecinueve líneas iguales. -->
						{#if grupo.valores.length > TOPE_ENUMERAR_RASGOS}
							<ul class="flex flex-wrap gap-1">
								{#each ordenarInventario(grupo.valores) as rasgo, j (`rxv:${j}`)}
									<li
										class="border border-[color:var(--border)] px-1.5 py-0.5 text-xs font-medium leading-5"
									>
										{rasgo.valor ?? 'Sí'}
										{#if !modalidadComun(grupo.valores) && rasgo.modalidad}
											<span class="text-[color:var(--muted-foreground)]">· {rasgo.modalidad}</span>
										{/if}
									</li>
								{/each}
							</ul>
							<p class="mt-1.5 text-xs text-[color:var(--muted-foreground)]">
								{grupo.valores.length} posibilidades{modalidadComun(grupo.valores)
									? `, todas de modalidad ${modalidadComun(grupo.valores)}`
									: ''}
								{#if grupo.nota}
									<InlineNotePopover
										text={grupo.nota}
										label={`Mostrar nota sobre ${grupo.nombre}`}
									/>
								{/if}
							</p>
						{:else}
							<ul class="space-y-1">
								{#each grupo.valores as rasgo, j (`rxv:${j}`)}
									<li>
										<span class="font-medium">{rasgo.valor ?? 'Sí'}</span>
										{#if rasgo.modalidad}
											<span class="text-[color:var(--muted-foreground)]">· {rasgo.modalidad}</span>
										{/if}
										{#if rasgo.nota}
											<InlineNotePopover
												text={rasgo.nota}
												label={`Mostrar nota sobre ${grupo.nombre}`}
											/>
										{/if}
									</li>
								{/each}
							</ul>
						{/if}
					</td>
				</tr>
			{/each}

		</tbody>
	</table>
	</div>
</section>
