/**
 * Compone la figura que se descarga: título, gráfico, leyenda y pie, en **un solo SVG**.
 *
 * Es puro —recibe el gráfico ya serializado y una función que mide texto— para poder probarlo
 * sin navegador. El PNG sale después de rasterizar exactamente esto, así que lo que se ve en la
 * vista previa del modal, lo que baja en SVG y lo que baja en PNG son la misma figura.
 *
 * **El pie va dentro de la imagen, debajo del gráfico**, y no encima como marca de agua. Quien la
 * recorte se queda sin la cita a la vista, pero no sin ella: va también en los metadatos, y el
 * gráfico lleva su propio sello en un sitio que no se puede cortar sin cortar el gráfico.
 */
import type { CreditoFigura, MetadatosFigura, Tramo } from './cita';
import { CUERPO, FAMILIA_TEXTO, TINTA } from './tema';
import type { ItemLeyenda } from './tipos';

export type GraficoSerializado = {
	/** El `<svg>` del gráfico, con `width` y `height` a su tamaño natural. */
	svg: string;
	ancho: number;
	alto: number;
};

export type EstiloTexto = { cuerpo: number; peso?: number; cursiva?: boolean };

/** Ancho de un texto en unidades del SVG. En el navegador lo da un canvas; en las pruebas, una cuenta. */
export type Medidor = (texto: string, estilo: EstiloTexto) => number;

export type FiguraCompuesta = { svg: string; ancho: number; alto: number };

const MARGEN = 40;
/** Por debajo de esto el pie se parte en demasiadas líneas. */
const ANCHO_MINIMO = 640;
/** Un gráfico más ancho se reduce: a más, en una página impresa la letra quedaría ilegible. */
const ANCHO_MAXIMO_GRAFICO = 1000;

const TITULO = { cuerpo: 20, peso: 700, interlinea: 26 };
const OBRA = { cuerpo: 14, interlinea: 20 };
const LEYENDA = { cuerpo: CUERPO.referencia, alto: 22, muestra: 12, linea: 18, hueco: 22 };
const PIE = { cuerpo: CUERPO.menor, interlinea: 16, parrafo: 5 };

export function escaparXml(texto: string): string {
	return texto
		.replaceAll('&', '&amp;')
		.replaceAll('<', '&lt;')
		.replaceAll('>', '&gt;')
		.replaceAll('"', '&quot;')
		.replaceAll("'", '&apos;');
}

type Palabra = { texto: string; cursiva: boolean };

/**
 * Parte un texto con estilos en líneas que quepan en `ancho`.
 *
 * Cada palabra se lleva el espacio que la sigue, y el espacio no cuenta para decidir si cabe: una
 * línea que llena el ancho justo con su última palabra no tiene por qué saltar.
 */
export function partirEnLineas(
	tramos: Tramo[],
	ancho: number,
	cuerpo: number,
	medir: Medidor
): Palabra[][] {
	const palabras: Palabra[] = tramos.flatMap((tramo) =>
		(tramo.texto.match(/\S+\s*|\s+/g) ?? []).map((texto) => ({
			texto,
			cursiva: tramo.cursiva === true
		}))
	);
	const lineas: Palabra[][] = [];
	let actual: Palabra[] = [];
	let ocupado = 0;
	for (const palabra of palabras) {
		const estilo = { cuerpo, cursiva: palabra.cursiva };
		const sinEspacio = medir(palabra.texto.trimEnd(), estilo);
		if (actual.length > 0 && ocupado + sinEspacio > ancho) {
			lineas.push(actual);
			actual = [];
			ocupado = 0;
		}
		if (actual.length === 0 && palabra.texto.trim() === '') continue;
		actual.push(palabra);
		ocupado += medir(palabra.texto, estilo);
	}
	if (actual.length > 0) lineas.push(actual);
	return lineas;
}

/** Una línea como `<tspan>`s, juntando las palabras seguidas del mismo estilo. */
function tspans(linea: Palabra[]): string {
	const grupos: Palabra[] = [];
	for (const palabra of linea) {
		const ultimo = grupos[grupos.length - 1];
		if (ultimo && ultimo.cursiva === palabra.cursiva) ultimo.texto += palabra.texto;
		else grupos.push({ ...palabra });
	}
	if (grupos.length > 0) {
		const ultimo = grupos[grupos.length - 1];
		ultimo.texto = ultimo.texto.trimEnd();
	}
	return grupos
		.map((grupo) =>
			grupo.cursiva
				? `<tspan font-style="italic">${escaparXml(grupo.texto)}</tspan>`
				: `<tspan>${escaparXml(grupo.texto)}</tspan>`
		)
		.join('');
}

function parrafo(
	lineas: Palabra[][],
	x: number,
	y: number,
	interlinea: number,
	atributos: string
): string {
	return lineas
		.map(
			(linea, indice) =>
				`<text xml:space="preserve" x="${x}" y="${y + indice * interlinea}" ${atributos}>${tspans(linea)}</text>`
		)
		.join('');
}

function muestraDeLeyenda(item: ItemLeyenda, x: number, y: number): string {
	const centro = y - LEYENDA.muestra / 2 + 1;
	if (item.muestra === 'linea' || item.muestra === 'linea-discontinua') {
		const discontinua = item.muestra === 'linea-discontinua' ? ' stroke-dasharray="3 3"' : '';
		return `<line x1="${x}" x2="${x + LEYENDA.linea}" y1="${centro}" y2="${centro}" stroke="${escaparXml(item.color)}" stroke-width="2"${discontinua}/>`;
	}
	return `<rect x="${x}" y="${y - LEYENDA.muestra + 1}" width="${LEYENDA.muestra}" height="${LEYENDA.muestra}" fill="${escaparXml(item.color)}"/>`;
}

/** La leyenda en filas que se parten al llegar al ancho. Devuelve el SVG y lo que ocupa. */
function leyendaEnFilas(
	items: ItemLeyenda[],
	x0: number,
	y0: number,
	ancho: number,
	medir: Medidor
): { svg: string; alto: number } {
	if (items.length === 0) return { svg: '', alto: 0 };
	let x = x0;
	let y = y0 + LEYENDA.cuerpo;
	const partes: string[] = [];
	for (const item of items) {
		const muestra = item.muestra === 'linea' || item.muestra === 'linea-discontinua' ? LEYENDA.linea : LEYENDA.muestra;
		const ocupa = muestra + 6 + medir(item.etiqueta, { cuerpo: LEYENDA.cuerpo });
		if (x > x0 && x + ocupa > x0 + ancho) {
			x = x0;
			y += LEYENDA.alto;
		}
		partes.push(muestraDeLeyenda(item, x, y));
		partes.push(
			`<text x="${x + muestra + 6}" y="${y}" font-size="${LEYENDA.cuerpo}" fill="${TINTA.texto}">${escaparXml(item.etiqueta)}</text>`
		);
		x += ocupa + LEYENDA.hueco;
	}
	return { svg: `<g>${partes.join('')}</g>`, alto: y - y0 + 6 };
}

/**
 * Los metadatos en RDF, con la estructura que piden XMP y Dublin Core.
 *
 * Los mismos para el SVG (dentro de `<metadata>`) y para el PNG (en el paquete XMP), que es lo
 * que leen los gestores de imágenes y el panel de propiedades del sistema.
 */
export function rdfDeMetadatos(metadatos: MetadatosFigura): string {
	const alt = (texto: string) =>
		`<rdf:Alt><rdf:li xml:lang="x-default">${escaparXml(texto)}</rdf:li></rdf:Alt>`;
	const autores = metadatos.autor
		.split('; ')
		.map((autor) => `<rdf:li>${escaparXml(autor)}</rdf:li>`)
		.join('');
	return [
		'<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"',
		' xmlns:dc="http://purl.org/dc/elements/1.1/"',
		' xmlns:cc="http://creativecommons.org/ns#"',
		' xmlns:xmpRights="http://ns.adobe.com/xap/1.0/rights/">',
		'<rdf:Description rdf:about="">',
		`<dc:title>${alt(metadatos.titulo)}</dc:title>`,
		`<dc:creator><rdf:Seq>${autores}</rdf:Seq></dc:creator>`,
		`<dc:description>${alt(metadatos.descripcion)}</dc:description>`,
		`<dc:rights>${alt(metadatos.derechos)}</dc:rights>`,
		`<dc:source>${escaparXml(metadatos.fuente)}</dc:source>`,
		`<dc:date>${escaparXml(metadatos.fecha)}</dc:date>`,
		`<cc:license rdf:resource="${escaparXml(metadatos.licenciaUrl)}"/>`,
		'<xmpRights:Marked>True</xmpRights:Marked>',
		`<xmpRights:WebStatement>${escaparXml(metadatos.licenciaUrl)}</xmpRights:WebStatement>`,
		`<xmpRights:UsageTerms>${alt(metadatos.derechos)}</xmpRights:UsageTerms>`,
		'</rdf:Description>',
		'</rdf:RDF>'
	].join('');
}

export function componerFigura({
	grafico,
	credito,
	leyenda = [],
	estiloFuentes = '',
	medir
}: {
	grafico: GraficoSerializado;
	credito: CreditoFigura;
	leyenda?: ItemLeyenda[];
	/** Las `@font-face` con la letra incrustada. Vacío en las pruebas. */
	estiloFuentes?: string;
	medir: Medidor;
}): FiguraCompuesta {
	const escala = Math.min(1, ANCHO_MAXIMO_GRAFICO / grafico.ancho);
	const anchoGrafico = grafico.ancho * escala;
	const altoGrafico = grafico.alto * escala;
	const util = Math.max(ANCHO_MINIMO, anchoGrafico);
	const ancho = Math.ceil(util + MARGEN * 2);

	const partes: string[] = [];
	let y = MARGEN;

	const titulo = partirEnLineas([{ texto: credito.titulo }], util, TITULO.cuerpo, (texto, estilo) =>
		medir(texto, { ...estilo, peso: TITULO.peso })
	);
	partes.push(
		parrafo(
			titulo,
			MARGEN,
			y + TITULO.cuerpo,
			TITULO.interlinea,
			`font-size="${TITULO.cuerpo}" font-weight="${TITULO.peso}" fill="${TINTA.texto}"`
		)
	);
	y += titulo.length * TITULO.interlinea;

	const obra = partirEnLineas(credito.obra, util, OBRA.cuerpo, medir);
	partes.push(
		parrafo(obra, MARGEN, y + OBRA.cuerpo, OBRA.interlinea, `font-size="${OBRA.cuerpo}" fill="${TINTA.secundario}"`)
	);
	y += obra.length * OBRA.interlinea + 18;

	const transformacion = escala === 1 ? '' : ` scale(${escala})`;
	partes.push(`<g transform="translate(${MARGEN} ${y})${transformacion}">${grafico.svg}</g>`);
	y += altoGrafico + 18;

	const bloqueLeyenda = leyendaEnFilas(leyenda, MARGEN, y, util, medir);
	if (bloqueLeyenda.alto > 0) {
		partes.push(bloqueLeyenda.svg);
		y += bloqueLeyenda.alto + 14;
	}

	partes.push(
		`<line x1="${MARGEN}" x2="${MARGEN + util}" y1="${y}" y2="${y}" stroke="${TINTA.guia}" stroke-width="1"/>`
	);
	y += 12;

	for (const tramos of credito.pie) {
		const lineas = partirEnLineas(tramos, util, PIE.cuerpo, medir);
		partes.push(
			parrafo(lineas, MARGEN, y + PIE.cuerpo, PIE.interlinea, `font-size="${PIE.cuerpo}" fill="${TINTA.secundario}"`)
		);
		y += lineas.length * PIE.interlinea + PIE.parrafo;
	}

	const alto = Math.ceil(y + MARGEN - PIE.parrafo);
	const svg = [
		`<svg xmlns="http://www.w3.org/2000/svg" width="${ancho}" height="${alto}" viewBox="0 0 ${ancho} ${alto}"`,
		` font-family="${escaparXml(FAMILIA_TEXTO)}">`,
		`<title>${escaparXml(credito.metadatos.titulo)}</title>`,
		`<desc>${escaparXml(credito.metadatos.descripcion)}</desc>`,
		`<metadata>${rdfDeMetadatos(credito.metadatos)}</metadata>`,
		estiloFuentes ? `<defs><style>${estiloFuentes}</style></defs>` : '',
		`<rect width="${ancho}" height="${alto}" fill="${TINTA.fondo}"/>`,
		...partes,
		'</svg>'
	].join('');
	return { svg, ancho, alto };
}
