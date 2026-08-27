import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { getObraContext } from '$lib/server/auth';

/**
 * Qué propone el catálogo nuevo para las secuencias que esta obra tiene anotadas con el vocabulario
 * legado.
 *
 * **Sirve a un mensaje, no a un formulario.** Al abrir una secuencia que ya venía anotada, el editor
 * enseña de dónde viene y qué propondría el catálogo, pero **no rellena nada**: la migración se hace
 * a mano, secuencia a secuencia, con el informe por obra delante y hablando con quien la anotó.
 * Automatizar la propuesta no ahorraría el repaso, porque faltan datos en casi todas.
 *
 * *Se pide una vez por obra y bajo demanda*, la primera vez que se abre una secuencia con término
 * legado. `propuesta_elecciones_secuencia` deriva el catálogo entero para responder, así que no vale
 * cargarla en cada visita a la pestaña: era justamente lo que hacía caer `/dashboard/metrica`.
 */
export const GET: RequestHandler = async ({ locals, params }) => {
	await getObraContext({ locals }, params.id, { requireEdit: false });

	const secuenciasResp = await locals.supabase
		.from('propuesta_metrica_secuencia')
		.select(
			'secuencia_id,termino_legado,forma_propuesta,arquitectura_propuesta,via,detalle,heredado_de,longitud_compatible,motivo_revision'
		)
		.eq('obra_id', params.id)
		.order('v_ini');

	if (secuenciasResp.error) {
		return json({ error: 'db_error', message: secuenciasResp.error.message }, { status: 500 });
	}

	// **Las respuestas se filtran por secuencia, no por obra**: la vista que las da no publica
	// `obra_id`, solo `secuencia_id`. Filtrar por una columna que no existe fallaba en silencio y el
	// mensaje salía sin ellas.
	const ids = (secuenciasResp.data ?? []).map((fila: Record<string, unknown>) =>
		String(fila.secuencia_id)
	);
	const respuestasResp = ids.length
		? await locals.supabase
				.from('propuesta_elecciones_secuencia')
				.select('secuencia_id,pregunta,respuesta,alcance')
				.in('secuencia_id', ids)
		: { data: [], error: null };

	// Las respuestas propuestas son un extra: si su consulta falla, el mensaje sigue valiendo con la
	// forma y la arquitectura, que es lo que de verdad orienta.
	const respuestas = respuestasResp.error ? [] : (respuestasResp.data ?? []);
	const porSecuencia = new Map<string, { pregunta: string; respuesta: string }[]>();
	for (const fila of respuestas as { secuencia_id: string; pregunta: string; respuesta: string }[]) {
		const clave = String(fila.secuencia_id);
		const lista = porSecuencia.get(clave) ?? [];
		// La misma respuesta se repite por unidad; en un mensaje basta con nombrarla una vez.
		if (!lista.some((item) => item.pregunta === fila.pregunta && item.respuesta === fila.respuesta)) {
			lista.push({ pregunta: String(fila.pregunta), respuesta: String(fila.respuesta) });
		}
		porSecuencia.set(clave, lista);
	}

	return json({
		items: (secuenciasResp.data ?? []).map((fila: Record<string, unknown>) => ({
			...fila,
			respuestas: porSecuencia.get(String(fila.secuencia_id)) ?? []
		}))
	});
};
