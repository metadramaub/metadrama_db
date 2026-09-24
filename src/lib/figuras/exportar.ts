/**
 * La parte del exportador que necesita navegador: leer el gráfico pintado, medir texto con la
 * letra de verdad, rasterizar y descargar. La composición y los metadatos son puros y viven en
 * `componer.ts` y `png.ts`.
 */
import interNormal from '@fontsource-variable/inter/files/inter-latin-wght-normal.woff2?url';
import interCursiva from '@fontsource-variable/inter/files/inter-latin-wght-italic.woff2?url';
import type { CreditoFigura } from './cita';
import { componerFigura, rdfDeMetadatos, type FiguraCompuesta, type Medidor } from './componer';
import { conMetadatos } from './png';
import { FAMILIA_FIGURA } from './tema';
import type { ItemLeyenda } from './tipos';

/** Ancho del PNG en píxeles: a 300 ppp da unos 25 cm, más que el ancho de caja de una revista. */
const ANCHO_PNG = 3000;
const PPP = 300;

/**
 * Lee el gráfico ya pintado y lo devuelve como texto, a su tamaño natural.
 *
 * El gráfico se marca con `data-figura` en su `<svg>`, y se busca ese y no «el primer SVG que
 * haya»: el exportador anterior recogía también los iconos de los botones y los apilaba a tamaño
 * de página.
 */
export function serializarGrafico(contenedor: Element): { svg: string; ancho: number; alto: number } {
	const svg = contenedor.querySelector<SVGSVGElement>('svg[data-figura]');
	if (!svg) throw new Error('Este gráfico no tiene una versión para descargar.');
	const caja = svg.viewBox.baseVal;
	if (!caja || caja.width === 0 || caja.height === 0) {
		throw new Error('El gráfico no declara su tamaño.');
	}
	const copia = svg.cloneNode(true) as SVGSVGElement;
	copia.setAttribute('width', String(caja.width));
	copia.setAttribute('height', String(caja.height));
	copia.removeAttribute('class');
	copia.removeAttribute('style');
	// Los comentarios que deja Svelte para anclar bloques no pintan nada, pero ensucian el archivo.
	const recorrido = document.createTreeWalker(copia, NodeFilter.SHOW_COMMENT);
	const comentarios: Node[] = [];
	while (recorrido.nextNode()) comentarios.push(recorrido.currentNode);
	for (const comentario of comentarios) comentario.parentNode?.removeChild(comentario);
	return {
		svg: new XMLSerializer().serializeToString(copia),
		ancho: caja.width,
		alto: caja.height
	};
}

let lienzoDeMedir: CanvasRenderingContext2D | null = null;

/** Mide con la Inter que ya ha cargado la página, que es la misma que va dentro de la figura. */
const medir: Medidor = (texto, { cuerpo, peso = 400, cursiva = false }) => {
	lienzoDeMedir ??= document.createElement('canvas').getContext('2d');
	if (!lienzoDeMedir) return texto.length * cuerpo * 0.55;
	lienzoDeMedir.font = `${cursiva ? 'italic ' : ''}${peso} ${cuerpo}px Inter, sans-serif`;
	return lienzoDeMedir.measureText(texto).width;
};

async function aBase64(url: string): Promise<string> {
	const respuesta = await fetch(url);
	if (!respuesta.ok) throw new Error('No se pudo cargar la letra de la figura.');
	const bytes = new Uint8Array(await respuesta.arrayBuffer());
	let binario = '';
	for (let i = 0; i < bytes.length; i += 0x8000) {
		binario += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
	}
	return btoa(binario);
}

let estiloFuentes: Promise<string> | null = null;

/**
 * Las `@font-face` con la Inter incrustada.
 *
 * **Va dentro del archivo** porque un SVG convertido en imagen no puede cargar nada de fuera: sin
 * esto el PNG salía en Arial. Solo el juego latino, que cubre el castellano, las comillas
 * angulares y las rayas; con la variable caben todos los pesos en un archivo.
 */
function cargarFuentes(): Promise<string> {
	estiloFuentes ??= Promise.all([aBase64(interNormal), aBase64(interCursiva)])
		.then(([normal, cursiva]) =>
			[
				[normal, 'normal'],
				[cursiva, 'italic']
			]
				.map(
					([datos, estilo]) =>
						`@font-face{font-family:'${FAMILIA_FIGURA}';font-style:${estilo};font-weight:100 900;` +
						`src:url(data:font/woff2;base64,${datos}) format('woff2');}`
				)
				.join('')
		)
		.catch((error) => {
			estiloFuentes = null;
			throw error;
		});
	return estiloFuentes;
}

export async function prepararFigura({
	contenedor,
	credito,
	leyenda
}: {
	contenedor: Element;
	credito: CreditoFigura;
	leyenda?: ItemLeyenda[];
}): Promise<FiguraCompuesta> {
	const grafico = serializarGrafico(contenedor);
	const fuentes = await cargarFuentes();
	await document.fonts?.ready;
	return componerFigura({ grafico, credito, leyenda, estiloFuentes: fuentes, medir });
}

export function blobSvg(figura: FiguraCompuesta): Blob {
	return new Blob([`<?xml version="1.0" encoding="UTF-8"?>\n${figura.svg}`], {
		type: 'image/svg+xml;charset=utf-8'
	});
}

function cargarImagen(url: string): Promise<HTMLImageElement> {
	return new Promise((resolver, rechazar) => {
		const imagen = new Image();
		imagen.onload = () => resolver(imagen);
		imagen.onerror = () => rechazar(new Error('No se pudo dibujar la figura.'));
		imagen.src = url;
	});
}

export async function blobPng(figura: FiguraCompuesta, credito: CreditoFigura): Promise<Blob> {
	const url = URL.createObjectURL(blobSvg(figura));
	try {
		const imagen = await cargarImagen(url);
		// Safari avisa del `load` antes de haber aplicado las fuentes de dentro del SVG: un
		// fotograma de espera basta para que no salga en la letra de reserva.
		await new Promise((resolver) => requestAnimationFrame(() => resolver(null)));
		const escala = ANCHO_PNG / figura.ancho;
		const lienzo = document.createElement('canvas');
		lienzo.width = Math.round(figura.ancho * escala);
		lienzo.height = Math.round(figura.alto * escala);
		const contexto = lienzo.getContext('2d');
		if (!contexto) throw new Error('El navegador no ofrece un lienzo para dibujar la figura.');
		contexto.fillStyle = '#fff';
		contexto.fillRect(0, 0, lienzo.width, lienzo.height);
		contexto.drawImage(imagen, 0, 0, lienzo.width, lienzo.height);
		const png = await new Promise<Blob>((resolver, rechazar) =>
			lienzo.toBlob(
				(blob) => (blob ? resolver(blob) : rechazar(new Error('No se pudo generar el PNG.'))),
				'image/png'
			)
		);
		const { metadatos } = credito;
		const bytes = conMetadatos(new Uint8Array(await png.arrayBuffer()), {
			ppp: PPP,
			textos: {
				Title: metadatos.titulo,
				Author: metadatos.autor,
				Description: metadatos.descripcion,
				Copyright: metadatos.derechos,
				Source: metadatos.fuente,
				'Creation Time': metadatos.fecha,
				Software: 'Versología',
				'XML:com.adobe.xmp':
					'<?xpacket begin="﻿" id="W5M0MpCehiHzreSzNTczkc9d"?>' +
					`<x:xmpmeta xmlns:x="adobe:ns:meta/">${rdfDeMetadatos(metadatos)}</x:xmpmeta>` +
					'<?xpacket end="r"?>'
			}
		});
		return new Blob([bytes], { type: 'image/png' });
	} finally {
		URL.revokeObjectURL(url);
	}
}

export function descargar(blob: Blob, nombre: string) {
	const url = URL.createObjectURL(blob);
	const enlace = document.createElement('a');
	enlace.href = url;
	enlace.download = nombre;
	enlace.hidden = true;
	document.body.append(enlace);
	enlace.click();
	enlace.remove();
	// Se suelta después: algunos navegadores leen la URL cuando el clic ya ha vuelto.
	setTimeout(() => URL.revokeObjectURL(url), 1000);
}

export function nombreDeArchivo(partes: string[]): string {
	return partes
		.join('-')
		.normalize('NFD')
		.replace(/[̀-ͯ]/g, '')
		.toLowerCase()
		.replace(/[^a-z0-9]+/g, '-')
		.replace(/^-|-$/g, '')
		.slice(0, 100);
}
