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
import { datacionDeObra } from '$lib/dataciones';
import { loadInternalVocabulario } from '$lib/server/catalogos-internos';
import type { ObraEditorial } from '$lib/types/obra-editorial.types';
import { loadAutoriaCatalogs, validateAutoriaPayload } from '$lib/server/autoria';
import { autoriaInputSchema, obraDatosPatchSchema } from '$lib/utils/validators';

async function cargarDestino(locals: App.Locals, id: string) {
	if (!modeloEditorialActivo() || !z.string().uuid().safeParse(id).success)
		throw error(400, 'Obra de destino inválida.');
	const permiso = await locals.supabase.rpc('destino_importacion_metrica' as never, { p_obra: id } as never);
	const destino = z.object({ obra_id: z.string().uuid(), titulo: z.string() }).safeParse(permiso.data);
	if (permiso.error || !destino.success) throw error(409, 'Selecciona una obra sin ficha.');
	return destino.data;
}

export const load: PageServerLoad = async (event) => {
	const acceso = await estadoImportador(event);
	const destinoId = event.url.searchParams.get('obra');
	const obraDestino = destinoId ? await cargarDestino(event.locals, destinoId) : null;
	const esGestor = ['admin', 'ip'].includes(acceso.profile.roleTerm);
	let metadatosDestino = null;
	if (obraDestino && esGestor) {
		const [obra, generoOptions] = await Promise.all([
			event.locals.supabase.from('obras_editoriales').select('*').eq('obra_id', obraDestino.obra_id).single(),
			loadInternalVocabulario(event.locals.supabase, ['genero'])
		]);
		if (obra.error || !obra.data) throw error(500, 'No se pudieron cargar los datos de la obra.');
		metadatosDestino = { obra: obra.data as ObraEditorial, generoOptions, roleTerm: acceso.profile.roleTerm };
	}
	const [autores, generos, catalogosAutoria] = await Promise.all([
		event.locals.supabase
			.from('autores')
			.select('autor_id,nombre_completo,nombre_normalizado')
			.order('nombre_completo'),
		event.locals.supabase
			.from('vocabularios')
			.select('termino_id,termino,etiqueta')
			.eq('categoria', 'genero')
			.eq('activo', true)
			.order('orden'),
		esGestor && !obraDestino ? loadAutoriaCatalogs(event.locals.supabase) : null
	]);
	if (autores.error || generos.error) throw error(500, 'No se pudieron cargar autores y géneros');
	return {
		obraDestino,
		metadatosDestino,
		catalogosAutoria,
		roleTerm: acceso.profile.roleTerm,
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
	let autorId = editar ? texto('autor_id') : '';
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
			'inicio_inclusivo', 'fin_inclusivo', 'fecha_aproximada',
			'fuente_fecha',
			'fundamento_autoria',
			'ia_generador', 'ia_modelo', 'ia_modo', 'ia_plan', 'ia_parametros'
		] as const)
			if (form.has(key)) cambios[key] = texto(key);
	}
	const esGestor = ['admin', 'ip'].includes(acceso.profile?.roleTerm ?? '');
	const metadatosVigentes = !!obraId && esGestor;
	let datosNuevos: { variantes_titulo: string[]; propuestas_autoria: Record<string, unknown>[] } | undefined;
	if (!obraId && editar && esGestor && form.has('autoria_borrador')) {
		let propuesta: unknown;
		let variantes: unknown;
		try {
			propuesta = JSON.parse(texto('autoria_borrador'));
			variantes = JSON.parse(texto('variantes_borrador'));
		} catch {
			return fail(400, { mensaje: 'Revisa los datos de la obra.' });
		}
		const autoria = autoriaInputSchema.safeParse(propuesta);
		const datos = obraDatosPatchSchema.safeParse({ variantes_titulo: variantes });
		if (!autoria.success || !datos.success) return fail(400, { mensaje: 'Revisa los datos y la autoría de la obra.' });
		const [catalogos, autores] = await Promise.all([
			loadAutoriaCatalogs(event.locals.supabase),
			event.locals.supabase.from('autores').select('autor_id,nombre_completo')
		]);
		if (autores.error) throw error(500, 'No se pudo comprobar la autoría.');
		const nombres = new Map(autores.data.map((autor) => [autor.autor_id, autor.nombre_completo]));
		const problemas = validateAutoriaPayload(autoria.data, {
			jornadaIds: new Set(),
			tipoIds: new Set(catalogos.tipos.map((tipo) => tipo.termino_id)),
			composicionTermById: new Map(catalogos.composiciones.map((tipo) => [tipo.termino_id, tipo.termino])),
			authorIds: new Set(nombres.keys())
		});
		if (problemas.length) return fail(400, { mensaje: problemas[0].message });
		const propuestas = autoria.data.grupos[0]?.propuestas ?? [];
		datosNuevos = { variantes_titulo: datos.data.variantes_titulo ?? [], propuestas_autoria: propuestas };
		cambios.autor_nombre = propuestas.map((p) => p.autores.map((a) => nombres.get(a.autor_id)).join(' y '))
			.filter(Boolean).join(' o ');
		autorId = '';
	}
	if (obraId) {
		if (!confirmar) cambios.titulo = (await cargarDestino(event.locals, obraId)).titulo;
		if (!editar || metadatosVigentes) {
			const { data: obra, error: errorObra } = await event.locals.supabase
				.from('obras_editoriales')
				.select('titulo,autores,genero_id,dataciones')
				.eq('obra_id', obraId)
				.maybeSingle();
			if (errorObra) throw error(500, 'No se pudieron cargar los datos de la obra.');
			if (obra) {
				const fecha = datacionDeObra(obra);
				if (metadatosVigentes) {
					cambios.titulo = obra.titulo ?? cambios.titulo;
					cambios.autor_nombre = (obra.autores ?? []).join(', ');
					cambios.genero = '';
					autorId = '';
				}
				if (fecha.inicio !== null || metadatosVigentes) cambios.fecha_inicio = fecha.inicio?.toString() ?? '';
				if (fecha.fin !== null || metadatosVigentes) cambios.fecha_fin = fecha.fin?.toString() ?? '';
				if (fecha.fuente || metadatosVigentes) cambios.fuente_fecha = fecha.fuente ?? '';
				cambios.inicio_inclusivo = String(fecha.inicio_inclusivo);
				cambios.fin_inclusivo = String(fecha.fin_inclusivo);
				cambios.fecha_aproximada = String(fecha.aproximada);
				const nombre = obra.autores?.length === 1 ? obra.autores[0] : undefined;
				if (nombre) {
					const { data: candidatos, error: errorAutor } = await event.locals.supabase
						.from('autores').select('autor_id').eq('nombre_completo', nombre).limit(2);
					if (errorAutor) throw error(500, 'No se pudo cargar la autoría de la obra.');
					if (candidatos?.length === 1) autorId = candidatos[0].autor_id;
				}
				if (obra.genero_id) {
					const { data: genero, error: errorGenero } = await event.locals.supabase
						.from('vocabularios').select('termino').eq('termino_id', obra.genero_id).maybeSingle();
					if (errorGenero) throw error(500, 'No se pudo cargar el género de la obra.');
					if (genero) cambios.genero = genero.termino;
				}
			}
		}
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
	if (vista.datos && datosNuevos) Object.assign(vista.datos.metadatos, datosNuevos);
	const autoriaLista = autorId || metadatosVigentes || datosNuevos;
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
		vista.datos && autoriaLista && !vista.errores.length && !vista.pendientes_metadatos?.length
			? huellaConfirmacion(vista.datos, autorId, coincidencias, obraId)
			: null;
	const respuesta = { entrada, autorId, vista, coincidencias, ediciones, huella, comprobacion_realizada: editar && !confirmar };
	if (confirmar) {
		if (!vista.datos || vista.errores.length || vista.pendientes_metadatos?.length || !autoriaLista)
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
