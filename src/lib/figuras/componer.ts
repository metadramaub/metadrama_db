/**
 * Compone la figura que se descarga: título, gráfico y leyenda, en **un solo SVG**.
 *
 * Es puro —recibe el gráfico ya serializado y una función que mide texto— para poder probarlo
 * sin navegador. El PNG sale después de rasterizar exactamente esto, así que lo que se ve en la
 * vista previa del modal, lo que baja en SVG y lo que baja en PNG son la misma figura.
 *
 * La cita y la licencia se muestran en el panel de descarga y se conservan en los metadatos.
 */
import type { CreditoFigura, MetadatosFigura, Tramo } from './cita';
import { CUERPO, FAMILIA_TEXTO, FAMILIA_TITULO, TINTA } from './tema';
import type { ItemLeyenda } from './tipos';
import { svgDeTrama } from './tramas';

export type GraficoSerializado = {
	/** El `<svg>` del gráfico, con `width` y `height` a su tamaño natural. */
	svg: string;
	ancho: number;
	alto: number;
};

export type EstiloTexto = { cuerpo: number; peso?: number; cursiva?: boolean; familia?: 'titulo' | 'texto' };

/** Ancho de un texto en unidades del SVG. En el navegador lo da un canvas; en las pruebas, una cuenta. */
export type Medidor = (texto: string, estilo: EstiloTexto) => number;

export type FiguraCompuesta = { svg: string; ancho: number; alto: number };

const MARGEN = 40;
/** Anchura mínima para que el título y la leyenda sigan siendo legibles. */
const ANCHO_MINIMO = 640;
/** Un gráfico más ancho se reduce: a más, en una página impresa la letra quedaría ilegible. */
const ANCHO_MAXIMO_GRAFICO = 1000;

const TITULO = { cuerpo: 28, peso: 400, interlinea: 34 };
const SUBTITULO = { cuerpo: 14, interlinea: 20 };
const LEYENDA = { cuerpo: CUERPO.referencia, alto: 22, muestra: 12, linea: 18, hueco: 22 };

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

function muestraDeLeyenda(item: ItemLeyenda, x: number, y: number, indice: number): string {
	if (item.muestra === 'texto') return '';
	if (item.trama) {
		const id = `leyenda-trama-${indice}`;
		return `<defs>${svgDeTrama(id, item.trama)}</defs><rect x="${x}" y="${y - LEYENDA.muestra + 1}" width="22" height="${LEYENDA.muestra}" fill="url(#${id})" stroke="${TINTA.texto}" stroke-width="0.6"/>`;
	}
	const centro = y - LEYENDA.muestra / 2 + 1;
	if (item.muestra === 'linea' || item.muestra === 'linea-discontinua') {
		const discontinua = item.muestra === 'linea-discontinua' ? ` stroke-dasharray="${escaparXml(item.trazosLinea ?? '3 3')}"` : '';
		return `<line x1="${x}" x2="${x + LEYENDA.linea}" y1="${centro}" y2="${centro}" stroke="${escaparXml(item.color)}" stroke-width="${item.anchoLinea ?? 2}"${discontinua}/>`;
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
	for (const [indice, item] of items.entries()) {
		const muestra = item.trama ? 22 : item.muestra === 'linea' || item.muestra === 'linea-discontinua' ? LEYENDA.linea : LEYENDA.muestra;
		const sangria = item.muestra === 'texto' ? 0 : muestra + 6;
		const ocupa = sangria + medir(item.etiqueta, { cuerpo: LEYENDA.cuerpo });
		if (x > x0 && x + ocupa > x0 + ancho) {
			x = x0;
			y += LEYENDA.alto;
		}
		partes.push(muestraDeLeyenda(item, x, y, indice));
		partes.push(
			`<text x="${x + sangria}" y="${y}" font-size="${LEYENDA.cuerpo}" fill="${TINTA.texto}">${escaparXml(item.etiqueta)}</text>`
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

	const titulo = partirEnLineas(credito.obra, util, TITULO.cuerpo, (texto, estilo) =>
		medir(texto, { ...estilo, peso: TITULO.peso, familia: 'titulo' })
	);
	partes.push(
		parrafo(
			titulo,
			MARGEN,
			y + TITULO.cuerpo,
			TITULO.interlinea,
			`font-family="${escaparXml(FAMILIA_TITULO)}" font-size="${TITULO.cuerpo}" font-weight="${TITULO.peso}" fill="${TINTA.texto}"`
		)
	);
	y += titulo.length * TITULO.interlinea;
	const subtitulo = partirEnLineas([{ texto: credito.titulo }], util, SUBTITULO.cuerpo, medir);
	partes.push(parrafo(subtitulo, MARGEN, y + SUBTITULO.cuerpo, SUBTITULO.interlinea,
		`font-size="${SUBTITULO.cuerpo}" font-weight="400" fill="${TINTA.secundario}"`));
	y += subtitulo.length * SUBTITULO.interlinea;

	y += 18;

	const transformacion = escala === 1 ? '' : ` scale(${escala})`;
	partes.push(`<g transform="translate(${MARGEN} ${y})${transformacion}">${grafico.svg}</g>`);
	y += altoGrafico + 18;

	const bloqueLeyenda = leyendaEnFilas(leyenda, MARGEN, y, util, medir);
	if (bloqueLeyenda.alto > 0) {
		partes.push(bloqueLeyenda.svg);
		y += bloqueLeyenda.alto + 14;
	}

	const alto = Math.ceil(y + MARGEN);
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
