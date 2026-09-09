import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export type ColaboradorPublico = {
	nombre_completo: string;
	orcid: string | null;
	total_obras: number;
	obras: Array<{
		titulo: string;
		slug: string;
	}>;
};

export const load: PageServerLoad = async ({ locals, setHeaders }) => {
	setHeaders({
		'cache-control': 'public, max-age=300, s-maxage=1800, stale-while-revalidate=3600'
	});

	const { data, error: dbError } = await locals.supabase.rpc('get_equipo_publico');
	if (dbError) {
		throw error(500, `No se pudo cargar el equipo: ${dbError.message}`);
	}

	const colaboradores = ((data ?? []) as ColaboradorPublico[])
		.filter(
			(persona) =>
				typeof persona.nombre_completo === 'string' &&
				persona.nombre_completo.trim() &&
				persona.nombre_completo.trim().toLocaleLowerCase('es') !== 'sin asignar'
		)
		.map((persona) => ({
			...persona,
			total_obras: Number.isInteger(persona.total_obras) ? persona.total_obras : 0,
			obras: Array.isArray(persona.obras)
				? persona.obras.filter(
						(obra) =>
							typeof obra?.titulo === 'string' &&
							typeof obra?.slug === 'string' &&
							obra.titulo.trim() &&
							obra.slug.trim()
					)
				: []
		}));

	return { colaboradores };
};
