import { error, fail } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';
import { requireImportadorPreview } from '$lib/server/importador-metrico/acceso';
import {
	analizarEntrada,
	obtenerPilotos,
	obtenerReferenciaImportador
} from '$lib/server/importador-metrico/vista-previa';
import type { MetadatosEditables } from '$lib/importador-metrico/types';

export const load: PageServerLoad = async (event) => {
	await requireImportadorPreview(event);
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
		autores: autores.data ?? [],
		generos: generos.data ?? [],
		pilotos: obtenerPilotos(),
		referencia: obtenerReferenciaImportador()
	};
};

async function previsualizar(event: Parameters<Actions[string]>[0], editar: boolean) {
	// Las acciones no heredan la autorización del load.
	await requireImportadorPreview(event);
	if (Number(event.request.headers.get('content-length')) > 3_000_000) {
		return fail(413, { mensaje: 'La entrada es demasiado grande. Pega una obra cada vez.' });
	}
	const form = await event.request.formData();
	const texto = (key: string) => (typeof form.get(key) === 'string' ? String(form.get(key)) : '');
	const entrada = texto('entrada');
	if (entrada.length > 2_000_000)
		return fail(413, { mensaje: 'La entrada supera el límite de este ensayo.' });
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
			'fundamento_autoria'
		] as const)
			cambios[key] = texto(key);
	}
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
				vista: analizarEntrada(entrada, cambios, cambiosSecuencias),
				coincidencias: []
			});
		cambios.autor_nombre = autor.nombre_completo;
	}
	const vista = analizarEntrada(entrada, cambios, cambiosSecuencias);
	const coincidencias: { obra_id: string; titulo: string; slug: string }[] = [];
	if (vista.metadatos.titulo.trim()) {
		// Coincidencia por título, no una decisión de identidad ni una reimportación.
		const { data, error: dbError } = await event.locals.supabase
			.from('obras')
			.select('obra_id,titulo,slug')
			.ilike('titulo', vista.metadatos.titulo.trim().replace(/[\\%_]/g, '\\$&'))
			.limit(20);
		if (dbError) throw error(500, 'No se pudieron comprobar las coincidencias de título');
		coincidencias.push(...(data ?? []));
	}
	return { entrada, autorId, vista, coincidencias, ediciones };
}

export const actions: Actions = {
	leer: (event) => previsualizar(event, false),
	comprobar: (event) => previsualizar(event, true)
};
