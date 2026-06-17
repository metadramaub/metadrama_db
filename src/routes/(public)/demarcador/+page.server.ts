import estrofasRaw from '$lib/demarcador/data/estrofas.json';
import familiasRaw from '$lib/demarcador/data/familias.json';
import preguntasRaw from '$lib/demarcador/data/preguntas.json';
import reglasRaw from '$lib/demarcador/data/reglas_demarcacion.json';

import {
	normalizarEstrofas,
	normalizarFamilias,
	normalizarPreguntas,
	normalizarReglas
} from '$lib/demarcador';

export const prerender = true;

export function load() {
	const familias = normalizarFamilias(familiasRaw);

	return {
		familias,
		estrofas: normalizarEstrofas(estrofasRaw, familias),
		preguntas: normalizarPreguntas(preguntasRaw),
		reglas: normalizarReglas(reglasRaw)
	};
}
