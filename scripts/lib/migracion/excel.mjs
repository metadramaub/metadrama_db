/**
 * El Excel que se le envía a quien anotó la obra, y que devuelve rellenado.
 *
 * Tres pestañas para escribir —Responder, Confirmar, Desviaciones—, dos de consulta —Secuencias,
 * Instrucciones— y una oculta con las listas de los desplegables. Cada fila que se rellena lleva
 * una **clave** en la última columna, que es lo que el aplicador lee: el texto de las demás
 * columnas es para la persona.
 *
 * Solo hay tres columnas en blanco por pestaña, y son las únicas de fondo amarillo: «Respuesta»,
 * «Excepciones / detalle» y «Comentario». El resto lo genera el sistema.
 */

import ExcelJS from 'exceljs';
import { FORMATOS, instrucciones as textoDeInstrucciones } from './markdown.mjs';

const RELLENO_CABECERA = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE5E7EB' } };
const RELLENO_RESPUESTA = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFEF9C3' } };
const RELLENO_CLAVE = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF3F4F6' } };
const FUENTE_CLAVE = { color: { argb: 'FF9CA3AF' }, size: 8 };

const ETIQUETA_TIPO = {
	decidir: 'Decidir',
	responder: 'Responder',
	confirmar: 'Confirmar',
	silabas: 'Sílabas (opcional)',
	informar: 'Informativa'
};

/** Quita las marcas de Markdown de un párrafo, para escribirlo en una celda. */
const sinMarcas = (texto) =>
	String(texto)
		.replaceAll(/\*\*(.+?)\*\*/g, '$1')
		.replaceAll(/\*(.+?)\*/g, '$1')
		.replaceAll(/\[(.+?)\]\((.+?)\)/g, '$1');

/**
 * Las listas de los desplegables viven en una hoja oculta y cada validación apunta a su rango:
 * una lista escrita dentro de la fórmula tiene un tope de 255 caracteres y rompe con comas.
 */
class Listas {
	constructor(hoja) {
		this.hoja = hoja;
		this.columnas = new Map();
	}
	rango(lista) {
		const clave = JSON.stringify(lista);
		if (!this.columnas.has(clave)) {
			const indice = this.columnas.size + 1;
			const columna = this.hoja.getColumn(indice);
			columna.values = ['lista', ...lista];
			columna.width = 40;
			const letra = columna.letter;
			this.columnas.set(clave, `Listas!$${letra}$2:$${letra}$${lista.length + 1}`);
		}
		return this.columnas.get(clave);
	}
}

function cabecera(hoja, columnas) {
	hoja.columns = columnas.map((c) => ({ header: c.titulo, key: c.clave, width: c.ancho }));
	const fila = hoja.getRow(1);
	fila.font = { bold: true };
	fila.fill = RELLENO_CABECERA;
	fila.alignment = { vertical: 'middle', wrapText: true };
	hoja.views = [{ state: 'frozen', ySplit: 1 }];
	hoja.autoFilter = { from: { row: 1, column: 1 }, to: { row: 1, column: columnas.length } };
}

function estilarFila(fila, columnas) {
	fila.alignment = { vertical: 'top', wrapText: true };
	columnas.forEach((c, i) => {
		const celda = fila.getCell(i + 1);
		if (c.respuesta) celda.fill = RELLENO_RESPUESTA;
		if (c.clave === 'clave') {
			celda.fill = RELLENO_CLAVE;
			celda.font = FUENTE_CLAVE;
		}
	});
}

function validar(celda, formato, listas) {
	if (formato?.modo !== 'lista' || !formato.lista?.length) return;
	celda.dataValidation = {
		type: 'list',
		allowBlank: true,
		showErrorMessage: true,
		errorTitle: 'Elige una opción',
		error: 'Elige una de las opciones del desplegable.',
		formulae: [listas.rango(formato.lista)]
	};
}

export async function escribirExcel(obra, ruta, fecha) {
	const libro = new ExcelJS.Workbook();
	libro.creator = 'Versología · npm run migracion:informe';
	libro.created = new Date();

	// ------------------------------------------------------------------ Instrucciones
	const instrucciones = libro.addWorksheet('Instrucciones');
	instrucciones.columns = [{ width: 110 }];
	instrucciones.addRow([`Migración métrica · ${obra.titulo}`]).font = { bold: true, size: 14 };
	instrucciones.addRow([
		`Para ${obra.editor ?? 'quien anotó la obra'} · generado el ${fecha}`
	]).font = {
		italic: true
	};
	instrucciones.addRow([]);
	for (const parrafo of textoDeInstrucciones({ enExcel: true })) {
		const fila = instrucciones.addRow([sinMarcas(parrafo)]);
		fila.alignment = { wrapText: true, vertical: 'top' };
	}
	instrucciones.addRow([]);
	instrucciones.addRow(['Cuando no hay desplegable, los formatos son estos:']).font = {
		bold: true
	};
	for (const linea of FORMATOS) {
		instrucciones.addRow([linea]).alignment = { wrapText: true, vertical: 'top' };
	}

	const listas = new Listas(libro.addWorksheet('Listas', { state: 'veryHidden' }));

	// ------------------------------------------------------------------ Responder
	const columnasResponder = [
		{ titulo: 'Tipo', clave: 'tipo', ancho: 11 },
		{ titulo: 'Versos', clave: 'versos', ancho: 11 },
		{ titulo: 'Forma', clave: 'forma', ancho: 26 },
		{ titulo: 'Qué se pregunta', clave: 'asunto', ancho: 60 },
		{ titulo: 'Propuesta', clave: 'propuesta', ancho: 30 },
		{ titulo: 'Cómo contestar', clave: 'ayuda', ancho: 40 },
		{ titulo: 'Respuesta', clave: 'respuesta', ancho: 30, respuesta: true },
		{ titulo: 'Excepciones / detalle', clave: 'excepciones', ancho: 40, respuesta: true },
		{ titulo: 'Comentario', clave: 'comentario', ancho: 30, respuesta: true },
		{ titulo: 'Clave', clave: 'clave', ancho: 14 }
	];
	const responder = libro.addWorksheet('Responder');
	cabecera(responder, columnasResponder);
	const ordenTipo = { decidir: 0, responder: 1 };
	const filasResponder = [...obra.cuestionario.responder].sort(
		(a, b) => ordenTipo[a.tipo] - ordenTipo[b.tipo] || versoInicial(a) - versoInicial(b)
	);
	for (const f of filasResponder) {
		const fila = responder.addRow({
			tipo: ETIQUETA_TIPO[f.tipo],
			versos: f.versos,
			forma: f.forma,
			asunto: f.asunto,
			propuesta: f.propuesta ?? '',
			ayuda: f.formato?.ayuda ?? '',
			respuesta: '',
			excepciones: '',
			comentario: '',
			clave: f.clave
		});
		estilarFila(fila, columnasResponder);
		validar(fila.getCell('respuesta'), f.formato, listas);
	}

	// ------------------------------------------------------------------ Confirmar
	const columnasConfirmar = [
		{ titulo: 'Versos', clave: 'versos', ancho: 11 },
		{ titulo: 'Forma', clave: 'forma', ancho: 26 },
		{ titulo: 'Pregunta', clave: 'asunto', ancho: 30 },
		{ titulo: 'Respuesta', clave: 'propuesta', ancho: 44 },
		{ titulo: 'Vocabulario anterior', clave: 'origen', ancho: 30 },
		{ titulo: '¿Correcto?', clave: 'respuesta', ancho: 18, respuesta: true },
		{ titulo: 'Corrección', clave: 'excepciones', ancho: 36, respuesta: true },
		{ titulo: 'Comentario', clave: 'comentario', ancho: 30, respuesta: true },
		{ titulo: 'Clave', clave: 'clave', ancho: 14 }
	];
	const confirmar = libro.addWorksheet('Confirmar');
	cabecera(confirmar, columnasConfirmar);
	for (const f of obra.cuestionario.confirmar) {
		const fila = confirmar.addRow({
			versos: f.versos,
			forma: f.forma,
			asunto: f.asunto,
			propuesta: f.propuesta ?? '',
			origen: f.origen ?? '—',
			respuesta: '',
			excepciones: '',
			comentario: '',
			clave: f.clave
		});
		estilarFila(fila, columnasConfirmar);
		validar(fila.getCell('respuesta'), f.formato, listas);
	}

	// ------------------------------------------------------------------ Desviaciones
	const columnasDesviaciones = [
		{ titulo: 'Tipo', clave: 'tipo', ancho: 16 },
		{ titulo: 'Versos', clave: 'versos', ancho: 11 },
		{ titulo: 'Secuencia', clave: 'secuencia', ancho: 24 },
		{ titulo: 'Anotado como', clave: 'termino', ancho: 18 },
		{ titulo: 'Tu nota', clave: 'observacion', ancho: 44 },
		{ titulo: 'Cómo queda', clave: 'asunto', ancho: 40 },
		{ titulo: 'Sílabas', clave: 'respuesta', ancho: 10, respuesta: true },
		{ titulo: '¿Correcto?', clave: 'excepciones', ancho: 18, respuesta: true },
		{ titulo: 'Comentario', clave: 'comentario', ancho: 30, respuesta: true },
		{ titulo: 'Clave', clave: 'clave', ancho: 14 }
	];
	const desviaciones = libro.addWorksheet('Desviaciones');
	cabecera(desviaciones, columnasDesviaciones);
	for (const f of obra.cuestionario.desviaciones) {
		const fila = desviaciones.addRow({
			tipo: ETIQUETA_TIPO[f.tipo],
			versos: f.versos,
			secuencia: `${f.forma} (${f.secuenciaVersos ?? ''})`.replace(' ()', ''),
			termino: f.termino,
			observacion: f.observacion ?? '',
			asunto: f.asunto,
			respuesta: '',
			excepciones: '',
			comentario: '',
			clave: f.clave
		});
		estilarFila(fila, columnasDesviaciones);
		if (f.tipo === 'confirmar') validar(fila.getCell('excepciones'), f.formato, listas);
		if (f.tipo !== 'silabas') fila.getCell('respuesta').fill = RELLENO_CLAVE;
	}

	// ------------------------------------------------------------------ Secuencias
	const columnasSecuencias = [
		{ titulo: '#', clave: 'n', ancho: 5 },
		{ titulo: 'Versos', clave: 'versos', ancho: 11 },
		{ titulo: 'v', clave: 'v', ancho: 6 },
		{ titulo: 'Vocabulario anterior', clave: 'termino', ancho: 30 },
		{ titulo: 'Forma', clave: 'forma', ancho: 22 },
		{ titulo: 'Arquitectura', clave: 'arquitectura', ancho: 24 },
		{ titulo: 'Subtipos', clave: 'subtipos', ancho: 40 },
		{ titulo: 'Caracterizaciones', clave: 'caracterizaciones', ancho: 36 },
		{ titulo: 'Estado', clave: 'estado', ancho: 44 },
		{ titulo: 'Propuesta', clave: 'propuesta', ancho: 20 },
		{ titulo: 'Vía', clave: 'via', ancho: 26 }
	];
	const secuencias = libro.addWorksheet('Secuencias');
	cabecera(secuencias, columnasSecuencias);
	obra.secuencias.forEach((s, i) => {
		const rangos = (filas) =>
			filas.length === 0
				? '—'
				: filas
						.map((f) =>
							Number(f.v_ini) === s.v_ini && Number(f.v_fin) === s.v_fin
								? f.termino
								: `${f.termino} (${f.v_ini}–${f.v_fin})`
						)
						.join('\n');
		const fila = secuencias.addRow({
			n: i + 1,
			versos: `${s.v_ini}–${s.v_fin}`,
			v: s.n_versos,
			termino: s.termino_legado ?? '—',
			forma: s.forma_propuesta ?? '—',
			arquitectura: s.arquitectura_propuesta ?? '—',
			subtipos: rangos(s.subtipos),
			caracterizaciones: rangos(s.caracterizaciones),
			estado: s.diagnostico
				? `Revisar: ${s.diagnostico.texto}`
				: s.faltan.length > 0
					? `Falta: ${s.faltan.join(', ')}`
					: s.estado,
			propuesta:
				[
					s.anotadas > 0 ? `${s.anotadas} ${s.anotadas === 1 ? 'anotada' : 'anotadas'}` : null,
					s.derivadas > 0 ? `${s.derivadas} ${s.derivadas === 1 ? 'derivada' : 'derivadas'}` : null
				]
					.filter(Boolean)
					.join(' · ') || '—',
			via: s.via === 'ascendencia' ? `por ascendencia (${s.heredado_de})` : s.via
		});
		fila.alignment = { vertical: 'top', wrapText: true };
	});

	await libro.xlsx.writeFile(ruta);
}

function versoInicial(fila) {
	return Number(String(fila.versos).split('–')[0]) || 0;
}
