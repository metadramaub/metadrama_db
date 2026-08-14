<script lang="ts">
	import type { FilaDeRima, MedidaDeCelda, Rejilla } from '$lib/metrica/rejilla';
	import { renderInlineMarkdown } from '$lib/utils/markdown';

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
		glosas = {}
	}: {
		rejilla: Rejilla;
		mostrar?: 'todo' | 'medida' | 'rima';
		/** Qué disposiciones se dibujan. Por omisión, todas las de la rejilla. */
		filas?: FilaDeRima[];
		numeros?: boolean;
		bandas?: boolean;
		/** Para el recuadro del editor: sin números ni notas al pie. */
		compacta?: boolean;
		/** Glosa abierta de cada disposición, por identificador de esquema. */
		glosas?: Record<string, string | null>;
	} = $props();

	const columnas = $derived(rejilla.celdas.length);
	const filasVisibles = $derived(filas ?? rejilla.filasDeRima);
	const conMedida = $derived(mostrar !== 'rima' && rejilla.tieneMedida);
	const conRima = $derived(mostrar !== 'medida' && filasVisibles.length > 0);
	const hayGlosa = $derived(Object.values(glosas).some((texto) => Boolean(texto)));
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

	const celda = 'border border-[color:var(--border)] text-center font-mono leading-none';
	const alto = $derived(compacta ? 'px-1 py-1 text-[0.65rem]' : 'px-1 py-1.5 text-xs');
</script>

<div class="overflow-x-auto">
	<div
		class="inline-grid min-w-fit items-center gap-x-px gap-y-px"
		style="grid-template-columns: repeat({columnas}, minmax({compacta
			? '1.35rem'
			: '1.75rem'}, auto)){columnaRotulo ? ' max-content' : ''}{hayGlosa
			? ' minmax(12rem, 26rem)'
			: ''};"
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
			{#if hayGlosa}<div></div>{/if}
		{/if}

		{#if conRima}
			{#each filasVisibles as fila (fila.esquemaRimaId + ':' + fila.desde)}
				{#each fila.clases as clase, indice (indice)}
					<div
						class="{celda} {alto} {clase.suelto
							? 'text-[color:var(--muted-foreground)]'
							: `${colorDeRima(clase.clase)} ${esArteMayor(clase.clase) ? 'text-[0.8rem] font-bold' : 'text-[0.7rem] font-medium'}`}"
						style="grid-column: {fila.desde + indice};"
						title={clase.suelto ? 'Verso suelto: no rima' : `Clase de rima ${clase.clase}`}
					>
						{clase.suelto ? '–' : (clase.clase ?? '·')}
					</div>
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
				</div>
				{#if hayGlosa}
					<div
						class="px-3 text-[0.72rem] leading-5 text-[color:var(--muted-foreground)]"
						style="grid-column: {columnas + 2};"
					>
						{#if glosas[fila.esquemaRimaId]}
							{@html renderInlineMarkdown(glosas[fila.esquemaRimaId] ?? '')}
						{/if}
					</div>
				{/if}
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
				<div
					class="mt-1 border-t border-[color:var(--foreground)] pt-1 text-center text-[0.68rem] leading-4"
					style="grid-column: {banda.desde} / span {banda.hasta - banda.desde + 1};"
				>
					<span class="font-medium">{banda.nombre}</span>
					{#if (banda.apariciones ?? 1) > 1}
						<span class="text-[color:var(--muted-foreground)]">×{banda.apariciones}</span>
					{/if}
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
				</div>
			{/each}
		{/if}
	</div>
</div>

{#if !compacta && (rejilla.cicla || rejilla.recortada || enlacesEntreRepeticiones.length > 0)}
	<div class="mt-2 space-y-1 text-xs text-[color:var(--muted-foreground)]">
		{#if rejilla.cicla}
			<p><span aria-hidden="true">⟳</span> Se repite hasta el final de la serie.</p>
		{/if}
		{#if rejilla.recortada}
			<p>Se dibujan las {columnas} primeras posiciones.</p>
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
