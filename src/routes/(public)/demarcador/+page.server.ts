import estrofasRaw from '$lib/demarcador/data/estrofas.json';
import familiasRaw from '$lib/demarcador/data/familias.json';
import preguntasRaw from '$lib/demarcador/data/preguntas.json';
import reglasRaw from '$lib/demarcador/data/reglas_demarcacion.json';
import type { PageServerLoad } from './$types';

import {
	normalizarEstrofas,
	normalizarFamilias,
	normalizarPreguntas,
	normalizarReglas
} from '$lib/demarcador';
import { requireSectionVisible } from '$lib/server/secciones-publicas';

// Nota: ya no se prerenderiza. Necesita pasar por servidor para comprobar el flag
// de la sección 'demarcador' (que puede restringirse a login o admin/IP).

export const load: PageServerLoad = async ({ locals }) => {
	await requireSectionVisible(locals, 'demarcador');

	const familias = normalizarFamilias(familiasRaw);

	return {
		familias,
		estrofas: normalizarEstrofas(estrofasRaw, familias),
		preguntas: normalizarPreguntas(preguntasRaw),
		reglas: normalizarReglas(reglasRaw)
	};
}
