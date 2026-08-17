/**
 * Cuánto deja determinado una arquitectura en cada dimensión.
 *
 * Este eje no es la `modalidad`: `habitual`, `admitida` y `excepcional` dicen con qué frecuencia
 * reconoce la teoría una realización. Aquí se dice solamente qué permanece estable y qué debe
 * concretar cada poema. Todo se deriva del catálogo; no hay listas de formas ni reglas filológicas.
 */

import type {
	PublicArchitecture,
	PublicChoiceGroup,
	PublicSection
} from '$lib/metrica/formas-publicas.types';

export type GradoDeterminacion =
	| 'fijo'
	| 'acotado'
	| 'variable'
	| 'opcional'
	| 'permitido'
	| 'abierto'
	| 'no_fijado'
	| 'primera_unidad';

export type DeterminacionMetrica = {
	grado: GradoDeterminacion;
	detalle?: string | null;
};

export const ETIQUETAS_DETERMINACION: Record<GradoDeterminacion, string> = {
	fijo: 'Fijo',
	acotado: 'Acotado',
	variable: 'Variable',
	opcional: 'Opcional',
	permitido: 'Permitido',
	abierto: 'Abierto',
	no_fijado: 'No fijado',
	primera_unidad: 'Fijado por la primera unidad'
};

const gruposDe = (arquitectura: PublicArchitecture, dimension: string): PublicChoiceGroup[] =>
	arquitectura.elecciones.filter((grupo) => grupo.dimension === dimension);

export function determinacionDeExtension(arquitectura: PublicArchitecture): DeterminacionMetrica {
	const { unidadMin: min, unidadMax: max } = arquitectura;
	if (min !== null && max !== null && min === max) return { grado: 'fijo' };
	if (min === null && max === null) return { grado: 'abierto' };
	return { grado: 'acotado' };
}

export function determinacionDeMedida(arquitectura: PublicArchitecture): DeterminacionMetrica {
	if (arquitectura.eligeVariedad) return { grado: 'variable', detalle: 'medida y rima juntas' };

	const grupos = gruposDe(arquitectura, 'metro');
	if (grupos.some((grupo) => grupo.defineNorma)) {
		return { grado: 'primera_unidad', detalle: 'las siguientes repiten el patrón' };
	}
	const seccionesQueEligen = new Set(
		grupos.map((grupo) => grupo.seccion).filter((seccion): seccion is string => Boolean(seccion))
	);

	const repertorios = arquitectura.esquemasMetricos.filter(
		(esquema) => esquema.repertorio.length > 1
	);
	if (repertorios.length > 0) {
		return {
			grado: 'variable',
			detalle:
				seccionesQueEligen.size > 1
					? 'una medida por parte'
					: repertorios.every((esquema) => esquema.uniforme)
						? 'una medida para toda la composición'
						: 'verso a verso'
		};
	}

	const tieneAlternativas = arquitectura.rejilla?.celdas.some(
		(celda) => Boolean(celda.medida?.opcional) || (celda.medida?.alternativas.length ?? 0) > 0
	);
	return tieneAlternativas
		? { grado: 'acotado', detalle: 'en posiciones concretas' }
		: { grado: 'fijo' };
}

export function determinacionDeRima(arquitectura: PublicArchitecture): DeterminacionMetrica {
	const grupos = gruposDe(arquitectura, 'rima');
	if (grupos.some((grupo) => grupo.defineNorma)) {
		return { grado: 'primera_unidad', detalle: 'las siguientes repiten el patrón' };
	}
	if (grupos.some((grupo) => grupo.seleccionesMin === 0 && grupo.opciones > 0)) {
		return { grado: 'opcional' };
	}
	if (grupos.some((grupo) => grupo.opciones > 1)) {
		return { grado: 'variable', detalle: grupos.length > 1 ? 'una disposición por parte' : null };
	}

	const abiertos = arquitectura.esquemasRima.filter((esquema) => esquema.abierto);
	if (abiertos.length > 0) {
		return abiertos.every((esquema) => esquema.restricciones.length === 0)
			? { grado: 'abierto' }
			: { grado: 'acotado' };
	}

	const cerrados = arquitectura.esquemasRima.filter((esquema) => !esquema.abierto);
	if (cerrados.length > 1) {
		return { grado: 'variable', detalle: grupos.length > 1 ? 'una disposición por parte' : null };
	}
	if (cerrados.length === 1 && cerrados[0].modalidad !== 'definitoria') {
		return { grado: 'no_fijado' };
	}
	return { grado: 'fijo' };
}

function aplanarSecciones(secciones: PublicSection[]): PublicSection[] {
	return secciones.flatMap((seccion) => [seccion, ...aplanarSecciones(seccion.hijas)]);
}

export function determinacionDePartes(arquitectura: PublicArchitecture): DeterminacionMetrica {
	const secciones = aplanarSecciones(arquitectura.secciones);
	if (secciones.some((seccion) => seccion.primeraRealizacionDefinePatron)) {
		return { grado: 'primera_unidad', detalle: 'las siguientes repiten la estructura' };
	}
	const opcionales = secciones.some((seccion) => seccion.repeticionesMin === 0);
	const abiertas = secciones.some(
		(seccion) =>
			seccion.repeticionesMax === null || (seccion.versosMin !== null && seccion.versosMax === null)
	);
	if (abiertas) return { grado: 'abierto', detalle: opcionales ? 'con partes opcionales' : null };
	const acotadas = secciones.some(
		(seccion) =>
			seccion.versosMin !== seccion.versosMax || seccion.repeticionesMin !== seccion.repeticionesMax
	);
	if (acotadas) return { grado: 'acotado', detalle: opcionales ? 'con partes opcionales' : null };
	return { grado: 'fijo' };
}

export function determinacionDeRepeticion(
	arquitectura: PublicArchitecture,
	elegible: boolean
): DeterminacionMetrica {
	if (!elegible) return { grado: 'fijo' };
	const grupos = gruposDe(arquitectura, 'repeticion');
	if (grupos.some((grupo) => grupo.seleccionesMin === 0)) {
		return { grado: 'opcional', detalle: 'en cada ciclo' };
	}
	return { grado: 'variable', detalle: 'en cada ciclo' };
}
