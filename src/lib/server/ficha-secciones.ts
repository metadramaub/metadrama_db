// Fase 3: recorta del payload de la ficha pública los bloques cuya sección esté
// apagada o cuyo scope_minimo no alcance el scope EFECTIVO de la obra.
//
// Por qué aquí (servidor) y no en el cliente: si un bloque está apagado, su dato
// no debe salir del servidor. El {#if} de la UI es cosmético; la garantía es esto.
//
// Por qué scope EFECTIVO de la obra y no el global: el editor asignado ve su
// propia obra como admin/IP, así que también debe ver las sub-secciones
// restringidas DE ESA obra. Por eso este filtro recibe su propio mapa resuelto
// contra obraScope, no el sectionVisibility global del layout.

import {
	isSectionVisible,
	type SectionVisibilityMap
} from '$lib/secciones-publicas';
import type { PublicObraFichaPayload } from '$lib/types/public-ficha.types';

// Slugs de las sub-secciones de ficha (deben existir en secciones_publicas).
export const FICHA_SECTION_IDS = {
	autoria: 'ficha.autoria',
	fuentes: 'ficha.autoria.fuentes',
	metrica: 'ficha.metrica',
	observaciones: 'ficha.observaciones',
	bibliografia: 'ficha.bibliografia',
	comentarios: 'ficha.comentarios_publicos'
} as const;

/**
 * Devuelve una copia del payload con los bloques apagados vaciados. No muta el
 * original. Una sección ausente del mapa = no visible (default seguro del helper).
 */
export function applyFichaSectionVisibility(
	ficha: PublicObraFichaPayload,
	visibility: SectionVisibilityMap
): PublicObraFichaPayload {
	const show = (id: string) => isSectionVisible(visibility, id);

	// Autoría: si el bloque entero está oculto, se vacían autores y grupos.
	const autoriaVisible = show(FICHA_SECTION_IDS.autoria);
	const fuentesVisible = autoriaVisible && show(FICHA_SECTION_IDS.fuentes);

	const autoria: PublicObraFichaPayload['autoria'] = autoriaVisible
		? {
				autores: ficha.autoria.autores,
				grupos: fuentesVisible
					? ficha.autoria.grupos
					: // Mantener la atribución pero sin las evidencias/fuentes.
						ficha.autoria.grupos.map((grupo) => ({
							...grupo,
							propuestas: grupo.propuestas.map((propuesta) => ({
								...propuesta,
								evidencias: []
							}))
						}))
			}
		: { autores: [], grupos: [] };

	const metrica: PublicObraFichaPayload['metrica'] = show(FICHA_SECTION_IDS.metrica)
		? ficha.metrica
		: { secuencias: [], distribucion_formas: [] };

	// observaciones y bibliografia son campos de `obra`; se vacían si la sección
	// está apagada, sin tocar el resto de la ficha.
	const obra: PublicObraFichaPayload['obra'] = {
		...ficha.obra,
		observaciones: show(FICHA_SECTION_IDS.observaciones) ? ficha.obra.observaciones : null,
		bibliografia: show(FICHA_SECTION_IDS.bibliografia) ? ficha.obra.bibliografia : null
	};

	const comentarios_publicos = show(FICHA_SECTION_IDS.comentarios)
		? ficha.comentarios_publicos
		: [];

	return {
		obra,
		autoria,
		estructura: ficha.estructura,
		metrica,
		comentarios_publicos
	};
}
