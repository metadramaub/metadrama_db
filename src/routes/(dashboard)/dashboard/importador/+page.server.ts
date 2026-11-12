import { relacionObras } from '$lib/server/modelo-obras';
import { modeloEditorialActivo } from '$lib/server/modelo-obras';
import { z } from 'zod';
import { error, fail, redirect } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';
import { estadoImportador } from '$lib/server/importador-metrico/acceso';
import { cargarCorrespondencias } from '$lib/server/importador-metrico/correspondencias';
import {
	buscarCoincidencias,
	clienteImportador,
	guardarImportacion,
	huellaConfirmacion,
	ErrorImportacion,
	type CoincidenciaImportacion
} from '$lib/server/importador-metrico/persistencia';
import {
	analizarEntrada,
	obtenerPilotos,
	obtenerReferenciaImportador
} from '$lib/server/importador-metrico/vista-previa';
import type { MetadatosEditables } from '$lib/importador-metrico/types';
import { randomUUID } from 'node:crypto';

export const load: PageServerLoad = async (event) => {
	const acceso = await estadoImportador(event);
	const destinoId = event.url.searchParams.get('obra');
	let obraDestino: {obra_id: string; titulo: string} | null = null;
	if (destinoId) {
		if (!modeloEditorialActivo() || !z.string().uuid().safeParse(destinoId).success) throw error(400, 'Obra de destino inválida.');
		const r = await event.locals.supabase.rpc('destino_importacion_metrica' as never,{p_obra:destinoId} as never);
		const destino=z.object({obra_id:z.string().uuid(),titulo:z.string()}).safeParse(r.data);
		if(r.error||!destino.success)throw error(409,'Selecciona una obra sin ficha.');
		obraDestino=destino.data;
	}
	const [autores, generos] = await Promise.all([
		event.locals.supabase
			.from('autores')
			.select('autor_id,nombre_completo')
			.order('nombre_completo'),
		event.locals.supabase
			.from('vocabularios')
			.select('termino,etiqueta')
			.eq('categoria', 'genero')
			.eq('activo', true)
			.order('orden')
	]);
	if (autores.error || generos.error) throw error(500, 'No se pudieron cargar autores y géneros');
	return {
		obraDestino,
		peticionId: randomUUID(),
		guardadoDisponible: acceso.guardadoDisponible,
		autores: autores.data ?? [],
		generos: generos.data ?? [],
		pilotos: obtenerPilotos(),
		referencia: obtenerReferenciaImportador()
	};
};

async function previsualizar(
	event: Parameters<Actions[string]>[0],
	editar: boolean,
	confirmar = false
) {
	// Las acciones no heredan la autorización del load.
	const acceso = await estadoImportador(event);
	if (confirmar && !acceso.guardadoDisponible)
		return fail(503, { mensaje: 'El guardado aún no está habilitado en esta base.' });
	if (Number(event.request.headers.get('content-length')) > 3_000_000) {
		return fail(413, { mensaje: 'La entrada es demasiado grande. Pega una obra cada vez.' });
	}
	const form = await event.request.formData();
	const texto = (key: string) => (typeof form.get(key) === 'string' ? String(form.get(key)) : '');
	const entrada = texto('entrada');
	const obraId = texto('obra_id') || null;
	if (obraId && (!modeloEditorialActivo() || !z.string().uuid().safeParse(obraId).success)) throw error(400, 'Obra de destino inválida.');
	if (entrada.length > 2_000_000)
		return fail(413, { mensaje: 'La entrada supera el límite. Pega una obra cada vez.' });
	const autorId = editar ? texto('autor_id') : '';
	const ediciones = editar ? texto('ediciones') || '[]' : '[]';
	let cambiosSecuencias: unknown;
	try {
		cambiosSecuencias = JSON.parse(ediciones);
	} catch {
		cambiosSecuencias = null;
	}
	const cambios: Partial<MetadatosEditables> = {};
	if (editar) {
		for (const key of [
			'titulo',
			'autor_nombre',
			'genero',
			'edicion_base',
			'fecha_inicio',
			'fecha_fin',
			'fuente_fecha',
			'fundamento_autoria',
			'ia_generador', 'ia_modelo', 'ia_modo', 'ia_plan', 'ia_parametros'
		] as const)
			if (!key.startsWith('ia_') || form.has(key)) cambios[key] = texto(key);
	}
	const correspondencias = await cargarCorrespondencias(event.locals.supabase);
	if (autorId) {
		const { data: autor, error: autorError } = await event.locals.supabase
			.from('autores')
			.select('autor_id,nombre_completo')
			.eq('autor_id', autorId)
			.maybeSingle();
		if (autorError) throw error(500, 'No se pudo comprobar el autor');
		if (!autor)
			return fail(400, {
				mensaje: 'El autor seleccionado ya no está disponible. Elige otro autor del catálogo.',
				entrada,
				ediciones,
				autorId: '',
				vista: analizarEntrada(entrada, cambios, cambiosSecuencias, correspondencias),
				coincidencias: [],
				huella: null
			});
		cambios.autor_nombre = autor.nombre_completo;
	}
	const vista = analizarEntrada(entrada, cambios, cambiosSecuencias, correspondencias);
	let coincidencias: CoincidenciaImportacion[] = [];
	if (vista.metadatos.titulo.trim() && acceso.guardadoDisponible) {
		try {
			coincidencias = await buscarCoincidencias(
				clienteImportador(event.locals.supabase),
				vista.metadatos.titulo
			);
		} catch {
			return fail(503, {
				mensaje: 'No se pudieron comprobar las coincidencias.',
				entrada,
				autorId,
				vista,
				coincidencias,
				ediciones,
				huella: null
			});
		}
	} else if (vista.metadatos.titulo.trim()) {
		// Coincidencia por título, no una decisión de identidad ni una reimportación.
		const { data, error: dbError } = await event.locals.supabase
			.from(relacionObras())
			.select('obra_id,titulo,slug')
			.ilike('titulo', vista.metadatos.titulo.trim().replace(/[\\%_]/g, '\\$&'))
			.limit(20);
		if (dbError) throw error(500, 'No se pudieron comprobar las coincidencias de título');
		coincidencias.push(
			...(data ?? []).map((o) => ({
				obra_id: o.obra_id,
				titulo: o.titulo,
				tipo_ficha: 'completa' as const,
				autores: []
			}))
		);
	}
	const huella =
		vista.datos && autorId && !vista.errores.length && !vista.pendientes_metadatos?.length
			? huellaConfirmacion(vista.datos, autorId, coincidencias, obraId)
			: null;
	const respuesta = { entrada, autorId, vista, coincidencias, ediciones, huella, comprobacion_realizada: editar && !confirmar };
	if (confirmar) {
		if (!vista.datos || vista.errores.length || vista.pendientes_metadatos?.length || !autorId)
			return fail(400, { ...respuesta, mensaje: 'Comprueba los datos antes de guardar.' });
		let guardada;
		try {
			guardada = await guardarImportacion(clienteImportador(event.locals.supabase), {
				datos: vista.datos,
				autorId,
				entrada,
				peticionId: texto('peticion_id'),
				coincidencias,
				huella: texto('huella'),
				otraObra: texto('decision_coincidencias') === 'otra_obra'
				,obraId
			});
		} catch (e) {
			return fail(e instanceof ErrorImportacion ? e.status : 503, {
				...respuesta,
				mensaje:
					e instanceof ErrorImportacion
						? e.message
						: 'No se pudo guardar. Comprueba los datos y reintenta.'
			});
		}
		throw redirect(303, '/dashboard/obras/' + guardada.obra_id + '?tab=secuencias');
	}
	return respuesta;
}

export const actions: Actions = {
	leer: (event) => previsualizar(event, false),
	comprobar: (event) => previsualizar(event, true),
	confirmar: (event) => previsualizar(event, true, true)
};
