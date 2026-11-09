import { z } from 'zod';
import type { BorradorFichaMinima, IncidenciaImportador } from '$lib/importador-metrico/types';
import { formasImportador } from '$lib/importador-metrico/catalogo';

/**
 * Correspondencias registradas por quien importa: un término de la edición que llegó sin
 * identificar y se resolvió a mano. Solo completan filas pendientes; nunca pisan una regla
 * de equivalencias ni eligen entre registros que se contradicen.
 */
const correspondenciaSchema = z.object({
	id: z.string().uuid(),
	literal: z.string(),
	forma: z.string(),
	arquitectura: z.string().nullable()
});
export type Correspondencia = z.infer<typeof correspondenciaSchema>;

const LIMITE_LECTURA = 1000;
/** Tabla o columna ausentes: la migración aún no está aplicada y se importa sin registro. */
const REGISTRO_AUSENTE = new Set(['42P01', '42703', 'PGRST204', 'PGRST205']);

type Respuesta = { data: unknown; error: { code?: string } | null };
// La tabla aún no está en database.types.ts; se tipa solo lo que se usa.
type ClienteRegistro = {
	from: (tabla: 'correspondencias_importador') => {
		select: (campos: string) => { limit: (n: number) => PromiseLike<Respuesta> };
	};
};

/** Misma comparación que el informe de equivalencias: espacios y mayúsculas no cuentan. */
export const claveDenominacion = (s: string) =>
	s.normalize('NFC').replace(/\s+/gu, ' ').trim().toLocaleLowerCase('es');

export async function cargarCorrespondencias(cliente: unknown): Promise<Correspondencia[]> {
	const r = await (cliente as ClienteRegistro)
		.from('correspondencias_importador')
		.select('id, literal, forma, arquitectura')
		.limit(LIMITE_LECTURA + 1);
	if (r.error) {
		if (REGISTRO_AUSENTE.has(r.error.code ?? '')) return [];
		throw new Error('No se pudieron consultar las correspondencias registradas.');
	}
	const filas = z.array(correspondenciaSchema).parse(r.data);
	if (filas.length > LIMITE_LECTURA)
		throw new Error('El registro de correspondencias supera el límite de lectura: hay que paginarlo.');
	return filas;
}

const destinoEnCatalogo = (r: Correspondencia) =>
	formasImportador.some(
		(f) => f.slug === r.forma && (!r.arquitectura || f.arquitecturas.some((a) => a.slug === r.arquitectura))
	);

export function aplicarCorrespondencias(
	datos: BorradorFichaMinima,
	registros: Correspondencia[],
	avisos: IncidenciaImportador[]
) {
	for (const s of datos.segmentos) {
		const literal = s.origen.denominacion_literal;
		if (s.identificacion || !literal) continue;
		const compatibles = registros.filter(
			(r) => claveDenominacion(r.literal) === claveDenominacion(literal) && destinoEnCatalogo(r)
		);
		if (!compatibles.length) continue;
		const destinos = new Set(compatibles.map((r) => `${r.forma}/${r.arquitectura ?? ''}`));
		if (destinos.size > 1) {
			avisos.push({
				codigo: 'correspondencias_conflicto',
				ruta: s.ref,
				mensaje: `«${literal}» tiene varias identificaciones registradas que no coinciden; revisa la fila.`
			});
			continue;
		}
		const r = compatibles[0];
		s.identificacion = { forma_slug: r.forma, arquitectura_slug: r.arquitectura };
		s.candidatas = [];
		s.regla_id = 'registro:' + r.id;
		s.nota = [s.nota, 'Identificación tomada del registro de correspondencias del importador.']
			.filter(Boolean)
			.join(' ');
	}
}
