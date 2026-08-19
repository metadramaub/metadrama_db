<script lang="ts">
	import type { BandaRejilla, FilaDeRima, MedidaDeCelda, Rejilla } from '$lib/metrica/rejilla';
	import { renderInlineMarkdown } from '$lib/utils/markdown';
	import InlineNotePopover from '$lib/components/ui/inline-note-popover.svelte';

	/**
	 * La rejilla de posiciones, dibujada.
	 *
	 * Sirve a las tres superficies —la ficha de `/formas`, el demarcador y el recuadro de la norma
	 * del editor V2— con el mismo dibujo, para que una forma se vea igual dondequiera que se mire.
	 * No sabe de dónde salen los datos: consume `Rejilla`, que es un tipo de presentación.
	 *
	 * Se puede pedir entera o por dimensiones —`medida` y `rima` son dos cosas y la ficha las
	 * separa—, y con un subconjunto de filas, que es como se dibuja cada parte del soneto sin
	 * perder la alineación con las columnas de la unidad.
	 *
	 * **La glosa de una disposición se abre como una columna más de la rejilla**, nunca flotando
	 * encima: un cuadro absoluto dentro de un contenedor con scroll se recorta por el borde y
	 * arrastra la barra horizontal consigo.
	 */
	const {
		rejilla,
		mostrar = 'todo',
		filas,
		numeros = true,
		bandas = true,
		compacta = false,
		pie = true,
		glosas = {},
		denominaciones = {},
		palabraFinal = false
	}: {
		rejilla: Rejilla;
		mostrar?: 'todo' | 'medida' | 'rima';
		/** Qué disposiciones se dibujan. Por omisión, todas las de la rejilla. */
		filas?: FilaDeRima[];
		numeros?: boolean;
		bandas?: boolean;
		/** Para el recuadro del editor: sin números ni notas al pie. */
		compacta?: boolean;
		/**
		 * Si se imprimen las notas al pie —el ciclo, el recorte y los enlaces entre repeticiones—.
		 * Hablan del dibujo entero, no de una dimensión, así que cuando la misma rejilla se pide dos
		 * veces —una para la medida y otra para la rima— solo la última debe llevarlas: si no, el
		 * romance decía ocho veces que se repite hasta el final de la serie.
		 */
		pie?: boolean;
		/** Glosa abierta de cada disposición, por identificador de esquema. */
		glosas?: Record<string, string | null>;
		/** Los otros nombres de cada disposición: «cuarteta» es la redondilla cruzada. */
		denominaciones?: Record<string, string[]>;
		/** La arquitectura repite palabras finales en vez de rimar: la sextina. */
		palabraFinal?: boolean;
	} = $props();

	const columnas = $derived(rejilla.celdas.length);
	const filasVisibles = $derived(filas ?? rejilla.filasDeRima);
	const conMedida = $derived(mostrar !== 'rima' && rejilla.tieneMedida);
	const conRima = $derived(mostrar !== 'medida' && filasVisibles.length > 0);
	/** La columna de rótulos solo existe cuando hay rima que rotular. */
	const columnaRotulo = $derived(conRima ? 1 : 0);

	/**
	 * Qué se lee en la casilla de la medida. Un repertorio largo —el pareado admite nueve
	 * medidas— se recorta a sus extremos: enseñar las nueve haría ilegible la fila, y el
	 * repertorio entero se lee debajo.
	 */
	function medida(valor: MedidaDeCelda | null): string {
		if (!valor) return '·';
		if (valor.silabas) return valor.silabas;
		const numeros = valor.alternativas
			.map((silabas) => Number(silabas))
			.filter((numero) => Number.isFinite(numero))
			.sort((a, b) => a - b);
		if (valor.alternativas.length > 3 && numeros.length === valor.alternativas.length) {
			return `${numeros[0]}–${numeros[numeros.length - 1]}`;
		}
		return valor.alternativas.join('/');
	}

	function tituloDeMedida(valor: MedidaDeCelda | null): string | undefined {
		if (!valor) return 'La arquitectura no fija la medida de esta posición';
		if (valor.silabas) return `${valor.silabas} sílabas`;
		return `El poema concreta una de estas medidas: ${valor.alternativas.join(', ')} sílabas`;
	}

	function medidaEsDeArteMayor(valor: MedidaDeCelda | null): boolean {
		if (!valor?.silabas) return false;
		const silabas = Number(valor.silabas);
		return Number.isFinite(silabas) && silabas > 8;
	}

	const PALETA_DE_RIMAS = [
		'bg-rose-100 text-rose-950 ring-1 ring-inset ring-rose-200',
		'bg-blue-100 text-blue-950 ring-1 ring-inset ring-blue-200',
		'bg-emerald-100 text-emerald-950 ring-1 ring-inset ring-emerald-200',
		'bg-violet-100 text-violet-950 ring-1 ring-inset ring-violet-200',
		'bg-orange-100 text-orange-950 ring-1 ring-inset ring-orange-200',
		'bg-cyan-100 text-cyan-950 ring-1 ring-inset ring-cyan-200',
		'bg-fuchsia-100 text-fuchsia-950 ring-1 ring-inset ring-fuchsia-200',
		'bg-lime-100 text-lime-950 ring-1 ring-inset ring-lime-200'
	] as const;

	/** La misma letra conserva el color aunque cambie de caja: `a` y `A` son la misma clase. */
	function colorDeRima(clase: string | null): string {
		const normalizada = String(clase ?? '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();
		let indice = 0;
		for (const caracter of normalizada) indice = (indice * 31 + caracter.charCodeAt(0)) >>> 0;
		return PALETA_DE_RIMAS[indice % PALETA_DE_RIMAS.length];
	}

	function esArteMayor(clase: string | null): boolean {
		if (!clase) return false;
		return clase !== clase.toLocaleLowerCase('es') && clase === clase.toLocaleUpperCase('es');
	}

	const enlacesEntreRepeticiones = $derived(
		rejilla.enlaces.filter((enlace) => enlace.sentido !== 'interior')
	);

	/**
	 * Un ciclo que rima y no declara ningún enlace **renueva** su rima en cada vuelta.
	 *
	 * El modelo declara la conservación en positivo, con `esquema_rima_enlaces`: por eso el
	 * romance dice «El verso 2 conserva su rima en cada repetición». La renovación era su
	 * silencio, y el silencio no se distingue de un dato que falta. Aquí se dice.
	 *
	 * La condición de que rime no sobra: la `suelta` de la endecha real es un ciclo `[----]…` sin
	 * ninguna clase, y hablar allí de renovar la rima no significaría nada.
	 */
	const renuevaLaRima = $derived(
		rejilla.cicla &&
			!rejilla.cicloSoloMetrico &&
			enlacesEntreRepeticiones.length === 0 &&
			filasVisibles.some((fila) => fila.clases.some((clase) => clase.clase && !clase.suelto))
	);

	/**
	 * Dónde parte una banda que dibuja varias apariciones seguidas de la misma parte, en tanto
	 * por ciento de su ancho. Ninguna si solo dibuja una.
	 */
	/**
	 * La letra con que se nombra cada palabra final: A, B, C…
	 *
	 * Se numeraron primero, y la fila quedaba encima de la de números de verso sin poder
	 * distinguirse. Las letras las separan y son además la notación con que las fuentes escriben
	 * el envío de la sextina —«BA-DF-EC»—.
	 */
	const letraDePalabra = (indice: number): string =>
		indice < 26 ? String.fromCharCode(65 + indice) : String(indice + 1);

	const divisionesInteriores = (banda: BandaRejilla): number[] => {
		const apariciones = banda.apariciones ?? 1;
		if (apariciones < 2) return [];
		return Array.from({ length: apariciones - 1 }, (_, indice) =>
			Math.round(((indice + 1) / apariciones) * 10000) / 100
		);
	};

	const PREPOSICIONES = new Set(['de', 'del', 'con', 'en', 'por', 'a', 'al', 'y', 'o', 'sin']);

	/**
	 * El plural llano de un rótulo de parte: «Pareado añadido» → «Pareados añadidos».
	 *
	 * Hace falta porque la banda y el árbol cuentan cosas distintas del mismo nombre. El árbol dice
	 * qué es **una** parte —«Pareado añadido · 2 versos · × 3»— y la banda abarca las tres, ya
	 * desdobladas sobre los versos 5 a 10. El catálogo lo resuelve a mano donde puede: las secciones
	 * del soneto se llaman ya «Cuartetos» y «Tercetos».
	 *
	 * Se detiene en la primera preposición, que es lo que separa el núcleo del complemento: «Cadena
	 * de tercetos» son «Cadenas de tercetos», no «Cadenas de tercetoses».
	 */
	function enPlural(nombre: string): string {
		const palabras = nombre.split(' ');
		const salida: string[] = [];
		for (const palabra of palabras) {
			if (PREPOSICIONES.has(palabra.toLocaleLowerCase('es'))) break;
			if (/s$/i.test(palabra)) salida.push(palabra);
			else if (/[aeiouáéíóú]$/i.test(palabra)) salida.push(`${palabra}s`);
			else if (/z$/i.test(palabra)) salida.push(`${palabra.slice(0, -1)}ces`);
			else salida.push(`${palabra}es`);
		}
		return [...salida, ...palabras.slice(salida.length)].join(' ');
	}

	const celda = 'border border-[color:var(--border)] text-center font-mono leading-none';
	const alto = $derived(compacta ? 'px-1 py-1 text-[0.65rem]' : 'px-1 py-1.5 text-xs');
</script>

<div class="overflow-x-auto">
	<div
		class="inline-grid min-w-fit items-center gap-x-px gap-y-px"
		style="grid-template-columns: repeat({columnas}, minmax({compacta
			? '1.35rem'
			: '1.75rem'}, auto)){columnaRotulo ? ' max-content' : ''};"
	>
		{#if conMedida}
			{#each rejilla.celdas as item (item.verso)}
				<div
					class="{celda} {alto} {item.medida?.silabas
						? ''
						: 'text-[color:var(--muted-foreground)]'} {medidaEsDeArteMayor(item.medida)
						? 'bg-[color:var(--gray-50)] font-bold'
						: ''}"
					style="grid-column: {item.verso};"
					title={tituloDeMedida(item.medida)}
				>
					{medida(item.medida)}
				</div>
			{/each}
			{#if columnaRotulo}
				<div class="pl-2 text-[0.68rem] leading-4 text-[color:var(--muted-foreground)]">
					sílabas
				</div>
			{/if}
		{/if}

		{#if conRima}
			{#each filasVisibles as fila (fila.esquemaRimaId + ':' + fila.desde)}
				{#each fila.clases as clase, indice (indice)}
					{@const estilo = `${celda} ${alto} ${
						palabraFinal
							? 'text-[0.7rem] font-medium text-[color:var(--muted-foreground)]'
							: clase.suelto
								? 'text-[color:var(--muted-foreground)]'
								: `${colorDeRima(clase.clase)} ${esArteMayor(clase.clase) ? 'text-[0.8rem] font-bold' : 'text-[0.7rem] font-medium'}`
					}`}
					<!--
						Donde lo que vuelve es la palabra, la celda lleva el número de su palabra final en
						vez del guion. El guion no solo se quedaba corto: decía «verso suelto, no rima» de
						los versos más trabados del catálogo. Numerarlos dice lo que la primera estrofa
						hace —fijar seis palabras en orden— y prepara la permutación que explican la
						definición y la repetición.
					-->
					{@const rotulo = palabraFinal
						? letraDePalabra(indice)
						: clase.suelto
							? '–'
							: (clase.clase ?? '·')}
					{#if clase.nota}
						<!-- La celda anotada **es** el disparador: la precisión es de ese verso y en
						     ningún otro sitio se lee mejor. Que se puede pulsar lo dice la marca de
						     esquina —la convención de la hoja de cálculo—, más el cursor y el anillo
						     al pasar por encima. -->
						<InlineNotePopover
							text={clase.nota}
							label={`Ver la nota del verso ${fila.desde + indice}`}
							claseRaiz="justify-stretch"
							estiloRaiz="grid-column: {fila.desde + indice};"
							claseBoton="{estilo} relative w-full cursor-pointer hover:outline hover:outline-1 hover:outline-[color:var(--foreground)] focus-visible:outline focus-visible:outline-1"
						>
							{#snippet disparador()}
								{rotulo}
								<span
									class="pointer-events-none absolute right-0 top-0 size-2 bg-[color:var(--foreground)]"
									style="clip-path: polygon(100% 0, 0 0, 100% 100%)"
									aria-hidden="true"
								></span>
							{/snippet}
						</InlineNotePopover>
					{:else}
						<div
							class={estilo}
							style="grid-column: {fila.desde + indice};"
							title={palabraFinal
								? `Palabra final ${letraDePalabra(indice)}`
								: clase.suelto
									? 'Verso suelto: no rima'
									: `Clase de rima ${clase.clase}`}
						>
							{rotulo}
						</div>
					{/if}
				{/each}
				<div
					class="whitespace-nowrap pl-2 text-[0.68rem] leading-4"
					style="grid-column: {columnas + 1};"
				>
					{#if fila.nombre}<span>{fila.nombre}</span>{:else if fila.notacion}<span
							class="font-mono">{fila.notacion}</span
						>{/if}

					{#if fila.modalidad}<span class="text-[color:var(--muted-foreground)]"
							>· {fila.modalidad}</span
						>{/if}
					{#if fila.tipoRima}<span class="text-[color:var(--muted-foreground)]"
							>· {fila.tipoRima}</span
						>{/if}
					<!--
						Los nombres que la tradición da a **esta disposición** y no a la forma entera van
						en su propia línea y en cursiva. En una sola línea y en el gris de la modalidad
						se confundían con ella y empujaban la fila hasta el borde: el cuarteto cruzado
						tiene tres nombres y el sexteto clásico cuatro, sesenta y un caracteres.
					-->
					{#if (denominaciones[fila.esquemaRimaId] ?? []).length > 0}
						<span
							class="block max-w-[15rem] whitespace-normal italic text-[color:var(--muted-foreground)]"
						>
							también {denominaciones[fila.esquemaRimaId].join(' · ')}
						</span>
					{/if}
					<!-- La glosa de la disposición, junto a su nombre. Es de esta fila y de ninguna
					     otra, así que no necesita ni botón aparte ni columna propia. -->
					{#if glosas[fila.esquemaRimaId]}
						<InlineNotePopover
							text={glosas[fila.esquemaRimaId] ?? ''}
							label={`Mostrar nota sobre ${fila.nombre ?? fila.notacion ?? 'esta disposición'}`}
						/>
					{/if}
				</div>
			{/each}
		{/if}

		{#if numeros && !compacta}
			{#each rejilla.celdas as item (item.verso)}
				<div
					class="pt-0.5 text-center text-[0.6rem] leading-3 text-[color:var(--muted-foreground)]"
					style="grid-column: {item.verso};"
				>
					{item.verso}
				</div>
			{/each}
		{/if}

		{#if bandas && !compacta && rejilla.bandas.length > 0}
			{#each rejilla.bandas as banda, indice (`${banda.nombre}:${banda.desde}:${indice}`)}
				<!--
					**Las líneas de las partes se alinean entre sí pase lo que pase debajo**, y para eso
					hacen falta las dos cosas de aquí abajo.

					`self-start`, porque el contenedor centra sus elementos —lo necesitan las filas de
					celdas— y una banda más alta que otra quedaba con su borde superior a distinta
					altura: la de «Cuerpo» crece al llevar debajo «rima como Simple», así que su línea
					subía y la de al lado no. Anclándolas arriba, todas las líneas caen en la misma.

					Y el rótulo **fuera del flujo**, porque como grid item su ancho entraba en el cálculo
					de las columnas `auto` que abarca, y cada banda abarca un número distinto: unos
					versos salían más anchos que otros y la línea dejaba de caer sobre sus celdas.

					La regla, entonces: bajo una banda se puede escribir lo que haga falta —su cuenta, su
					nota de reutilización, un nombre largo— sin mover ni las celdas ni las líneas.
				-->
				<div
					class="relative mx-0.5 mt-1 self-start border-t border-[color:var(--foreground)] pt-1"
					style="grid-column: {banda.desde} / span {banda.hasta - banda.desde + 1};"
				>
					<!--
						Los topes de los extremos cierran la línea en corchete. Alineadas todas a la misma
						altura, dos partes contiguas se leían como una sola raya continua; el tope dice dónde
						acaba una y empieza la siguiente. El aire lateral es de la banda, no de la rejilla, así
						que las columnas no se mueven.
					-->
					<span class="absolute left-0 top-0 h-1.5 w-px bg-[color:var(--foreground)]"></span>
					<span class="absolute right-0 top-0 h-1.5 w-px bg-[color:var(--foreground)]"></span>
					<!--
						Y una marca por cada división interior cuando la banda abarca varias apariciones de
						la misma parte. Se daba por hecho que se contaban solas porque la disposición cambia
						de letras entre una y otra —`CDC DCD` en los tercetos del soneto—, pero eso no vale
						cuando se repiten iguales: en `ABBA ABBA` los ocho cuartetos se leían como un bloque
						de ocho y no como dos de cuatro. La marca es más corta que los topes para que la
						jerarquía se lea: los extremos cierran la parte, estas la dividen.
					-->
					{#each divisionesInteriores(banda) as porcentaje (porcentaje)}
						<span
							class="absolute top-0 h-1 w-px bg-[color:var(--muted-foreground)]"
							style="left: {porcentaje}%"
						></span>
					{/each}
					<div class={banda.reutiliza ? 'h-8' : 'h-4'}></div>
					<div class="absolute inset-x-0 top-1 flex justify-center">
						<span class="w-max text-center text-[0.68rem] leading-4">
							<span class="font-medium">
								{(banda.apariciones ?? 1) > 1 ? enPlural(banda.nombre) : banda.nombre}
							</span>
							<!--
								`×N` dice aquí lo mismo que en el árbol de partes, que es donde está explicado:
								cuántas veces aparece una parte dentro de lo que la contiene, **dibujada una sola
								vez**. Cuando la banda abarca varias apariciones ya desdobladas —los tres pareados
								de la chamberga ocupan los versos 5 a 10 y se ven los tres— no se rotula ninguna
								cuenta: se cuentan en la figura, y ponerles «×3» encima hacía dudar si eran tres o
								nueve.
							-->
							{#if banda.repeticiones}
								<span class="text-[color:var(--muted-foreground)]">{banda.repeticiones}</span>
							{/if}
							{#if banda.reutiliza}
								<span class="block text-[color:var(--muted-foreground)]">
									rima como
									{#if banda.reutiliza.slug}
										<a class="underline hover:no-underline" href="/formas/{banda.reutiliza.slug}">
											{banda.reutiliza.nombre}
										</a>
									{:else}
										{banda.reutiliza.nombre}
									{/if}
								</span>
							{/if}
						</span>
					</div>
				</div>
			{/each}
		{/if}
	</div>
</div>

{#if pie && !compacta && (rejilla.cicla || rejilla.recortada || enlacesEntreRepeticiones.length > 0 || palabraFinal)}
	<div class="mt-2 space-y-1 text-xs text-[color:var(--muted-foreground)]">
		{#if rejilla.cicla}
			<p><span aria-hidden="true">⟳</span> Se repite hasta el final de la serie.</p>
		{/if}
		{#if rejilla.recortada}
			<p>Se dibujan las {columnas} primeras posiciones.</p>
		{/if}
		<!--
			El guion dice la verdad —la sextina no rima— pero deja al lector sin saber qué la sostiene
			entonces. Lo que vuelve es la palabra, y conviene decirlo aquí, junto al dibujo, y no solo
			en la fila «Repetición» que queda más abajo y tras un icono.
		-->
		{#if palabraFinal}
			<p>No hay rima: lo que vuelve de una estrofa a otra son las palabras finales.</p>
		{/if}
		{#if renuevaLaRima}
			<p>La rima se renueva en cada repetición.</p>
		{/if}
		{#each enlacesEntreRepeticiones as enlace, indice (indice)}
			<p>
				{enlace.nota ??
					(enlace.desde === enlace.hasta
						? `El verso ${enlace.desde} conserva su rima en cada repetición.`
						: `La rima del verso ${enlace.desde} vuelve en el verso ${enlace.hasta} de la repetición ${
								enlace.sentido === 'adelante' ? 'siguiente' : 'anterior'
							}.`)}
			</p>
		{/each}
	</div>
{/if}
