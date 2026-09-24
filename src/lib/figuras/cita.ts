import type { FiguraDescargable, OpcionesFigura, ProcedenciaFigura } from './tipos';

/**
 * Lo que dice de sí mismo el proyecto, tal como está en `/como-citarnos`.
 *
 * Si cambia allí, cambia aquí: la cita de una figura y la de la página que enseña a citar no
 * pueden decir cosas distintas.
 */
export const VERSOLOGIA = {
	nombre: 'Versología',
	titulo:
		'Versología: base de datos y herramientas de estilometría estrófica para el verso dramático',
	responsables: 'Gaston Gilabert y David Merino Recalde',
	origen: 'https://versologia.metadrama.org',
	licencia: 'CC BY-NC-SA 4.0',
	licenciaUrl: 'https://creativecommons.org/licenses/by-nc-sa/4.0/deed.es'
} as const;

/** Un trozo de texto con su estilo: la cita lleva títulos en cursiva. */
export type Tramo = { texto: string; cursiva?: boolean };

export const textoDe = (tramos: Tramo[]) => tramos.map((tramo) => tramo.texto).join('');

/** El año de la versión de una ficha, o «s. f.» si no se sabe. */
export function anioDeFicha(actualizada: string | null | undefined): string {
	if (!actualizada) return 's. f.';
	const fecha = new Date(actualizada);
	return Number.isNaN(fecha.valueOf()) ? 's. f.' : String(fecha.getUTCFullYear());
}

export const urlDeObra = (slug: string) => `${VERSOLOGIA.origen}/obras/${slug}`;

/** Una fecha como se escribe en una cita, en la zona de quien consulta. */
export function fechaLarga(fecha: Date): string {
	return new Intl.DateTimeFormat('es-ES', { dateStyle: 'long' }).format(fecha);
}

/**
 * La cita de un análisis, en la forma de «Cómo citar un análisis específico».
 *
 * **El editor firma el análisis y el proyecto es la obra que lo contiene**, como un capítulo en un
 * libro colectivo: por eso Gilabert y Merino Recalde van tras el «en». Es lo que ya decía
 * `/como-citarnos`, y resuelve quién es autor de qué sin inventar una fórmula nueva.
 *
 * Entre corchetes va la ficha y no la portada: quien lee la cita tiene que poder llegar al dato.
 * Sin editor asignado se cita el análisis sin firma, que es lo que se hace con una obra anónima.
 *
 * **La fecha de consulta es la del día de quien consulta**, y por eso puede faltar: el servidor no
 * sabe en qué zona está el lector, así que pinta la cita sin ella y el navegador la añade.
 */
export function citaDelAnalisis(procedencia: ProcedenciaFigura, consulta?: Date): Tramo[] {
	const autor = procedencia.autorFicha?.trim();
	return [
		...(autor ? [{ texto: `${autor}, ` }] : []),
		{ texto: '«Análisis y estudio versológico de ' },
		{ texto: procedencia.obraTitulo, cursiva: true },
		{ texto: `», en ${VERSOLOGIA.responsables}, ` },
		{ texto: VERSOLOGIA.titulo, cursiva: true },
		{
			texto: ` [${urlDeObra(procedencia.obraSlug)}], ${procedencia.anio}${
				consulta ? ` (consulta: ${fechaLarga(consulta)})` : ''
			}.`
		}
	];
}

/**
 * Quién hizo qué —el editor, los datos; el proyecto, la visualización— y de cuándo son los datos.
 *
 * Hay dos fechas y dicen cosas distintas: la de consulta, en la cita, es cuándo se descargó; la de
 * los datos, aquí, es la versión de la ficha de la que sale el gráfico.
 */
export function autoriaDeFigura(procedencia: ProcedenciaFigura): string {
	const autor = procedencia.autorFicha?.trim();
	const fecha = procedencia.actualizada ? new Date(procedencia.actualizada) : null;
	const datos = fecha && !Number.isNaN(fecha.valueOf()) ? `datos a ${fechaLarga(fecha)}` : null;
	const anotacion = autor
		? `Anotación métrica: ${[autor, datos].filter(Boolean).join(', ')}. `
		: datos
			? `${datos.charAt(0).toLocaleUpperCase('es')}${datos.slice(1)}. `
			: '';
	return `${anotacion}Visualización: ${VERSOLOGIA.nombre} (${VERSOLOGIA.responsables}).`;
}

export type CreditoFigura = {
	titulo: string;
	/** El subtítulo: la obra. */
	obra: Tramo[];
	/** El pie: fuente, autoría y licencia, un párrafo cada uno. */
	pie: Tramo[][];
	/** La cita en texto plano, para copiarla. */
	cita: string;
	metadatos: MetadatosFigura;
};

/** Lo que va dentro del archivo, además de a la vista. */
export type MetadatosFigura = {
	titulo: string;
	autor: string;
	descripcion: string;
	derechos: string;
	licenciaUrl: string;
	fuente: string;
	fecha: string;
};

export function creditoDeFigura(
	figura: FiguraDescargable,
	procedencia: ProcedenciaFigura,
	opciones: OpcionesFigura,
	consulta: Date
): CreditoFigura {
	const cita = citaDelAnalisis(procedencia, consulta);
	const autoria = autoriaDeFigura(procedencia);
	const autor = procedencia.autorFicha?.trim();
	const derechos = `${VERSOLOGIA.licencia}. ${autor ? `${autor} y ${VERSOLOGIA.nombre}` : VERSOLOGIA.nombre}.`;
	const titulo = `${figura.titulo}. ${procedencia.obraTitulo}`;
	return {
		titulo: figura.titulo,
		obra: [{ texto: procedencia.obraTitulo, cursiva: true }],
		pie: [
			[{ texto: 'Fuente: ' }, ...cita],
			[{ texto: autoria }],
			[{ texto: `Licencia ${VERSOLOGIA.licencia}${opciones.paleta === 'grises' ? '. Versión en blanco y negro' : ''}.` }]
		],
		cita: textoDe(cita),
		metadatos: {
			titulo,
			autor: [autor, `${VERSOLOGIA.nombre} (${VERSOLOGIA.responsables})`]
				.filter(Boolean)
				.join('; '),
			descripcion: `${titulo}. Fuente: ${textoDe(cita)} ${autoria}`,
			derechos,
			licenciaUrl: VERSOLOGIA.licenciaUrl,
			fuente: urlDeObra(procedencia.obraSlug),
			fecha: consulta.toISOString()
		}
	};
}
