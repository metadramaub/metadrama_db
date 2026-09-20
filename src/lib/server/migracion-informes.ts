/**
 * Los informes de migración que el editor lee en el dashboard.
 *
 * Los escribe `npm run migracion:informe` en `src/lib/content/migracion/`: un fragmento HTML por
 * obra y un índice con sus cifras. Se cargan como la guía del dashboard, con `import.meta.glob`,
 * así que viajan con el despliegue y no hay que servir ficheros sueltos.
 *
 * **Quién puede leer un informe no lo dice el índice.** El índice trae el `obra_id`; el permiso se
 * resuelve contra la obra en vivo, porque el editor asignado puede cambiar después de generarlo.
 */

import type { SupabaseClient } from '@supabase/supabase-js';
import type { EditorProfile } from '$lib/types/obra.types';

export type InformeMigracion = {
	slug: string;
	obraId: string;
	titulo: string;
	/** Quien anotó la obra cuando se generó el informe; el permiso no se decide con esto. */
	editor: string | null;
	excel: string;
	secuencias: number;
	decidir: number;
	responder: number;
	confirmar: number;
	desviaciones: number;
};

type IndiceGenerado = {
	generado: string;
	obras: {
		slug: string;
		obra_id: string;
		titulo: string;
		editor: string | null;
		excel: string;
		secuencias: number;
		decidir: number;
		responder: number;
		confirmar: number;
		desviaciones: number;
	}[];
};

const indices = import.meta.glob('../content/migracion/indice.json', {
	eager: true,
	import: 'default'
}) as Record<string, IndiceGenerado>;

const fragmentos = import.meta.glob('../content/migracion/*.html', {
	eager: true,
	query: '?raw',
	import: 'default'
}) as Record<string, string>;

const indice: IndiceGenerado = Object.values(indices)[0] ?? { generado: '', obras: [] };

const fragmentoPorSlug = new Map<string, string>(
	Object.entries(fragmentos).map(([ruta, html]) => [
		(ruta.split('/').pop() ?? '').replace(/\.html$/, ''),
		html
	])
);

const informes: InformeMigracion[] = indice.obras
	.filter((obra) => fragmentoPorSlug.has(obra.slug))
	.map((obra) => ({
		slug: obra.slug,
		obraId: obra.obra_id,
		titulo: obra.titulo,
		editor: obra.editor,
		excel: obra.excel,
		secuencias: obra.secuencias,
		decidir: obra.decidir,
		responder: obra.responder,
		confirmar: obra.confirmar,
		desviaciones: obra.desviaciones
	}));

export function getFechaDeGeneracion(): string {
	return indice.generado;
}

/** Los informes que este perfil puede leer: todos si es admin o IP, los suyos si es editor. */
export async function getInformesVisibles(
	supabase: SupabaseClient,
	profile: EditorProfile
): Promise<InformeMigracion[]> {
	if (informes.length === 0) return [];
	if (profile.roleTerm === 'admin' || profile.roleTerm === 'ip') return informes;

	const { data } = await supabase
		.from('obras')
		.select('obra_id')
		.eq('editor_asignado', profile.userId)
		.in(
			'obra_id',
			informes.map((informe) => informe.obraId)
		);
	const mias = new Set((data ?? []).map((fila) => fila.obra_id));
	return informes.filter((informe) => mias.has(informe.obraId));
}

export type InformeConTexto = InformeMigracion & { html: string };

/**
 * El informe de una obra si este perfil puede leerlo. Devuelve `null` cuando no existe y lanza
 * nada: quien llama decide si eso es un 404 o un 403.
 */
export async function getInformePorSlug(
	supabase: SupabaseClient,
	profile: EditorProfile,
	slug: string
): Promise<{ informe: InformeConTexto | null; permitido: boolean }> {
	const informe = informes.find((candidato) => candidato.slug === slug);
	if (!informe) return { informe: null, permitido: false };

	const html = fragmentoPorSlug.get(slug) ?? '';
	const conTexto: InformeConTexto = { ...informe, html };

	if (profile.roleTerm === 'admin' || profile.roleTerm === 'ip') {
		return { informe: conTexto, permitido: true };
	}

	const { data } = await supabase
		.from('obras')
		.select('editor_asignado')
		.eq('obra_id', informe.obraId)
		.maybeSingle();
	return { informe: conTexto, permitido: data?.editor_asignado === profile.userId };
}
