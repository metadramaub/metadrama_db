import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { canManageVocabularios, isProtectedVocabularyCategory } from '$lib/utils/permissions';

const vocabularySelect =
	'termino_id,categoria,termino,termino_padre_id,nivel,orden,definicion,ejemplo,bibliografia,equivalencias,patron_especifico,tipo_forma,activo';

export const load: PageServerLoad = async ({ locals, params, parent }) => {
	const parentData = await parent();
	const profile = parentData.profile;
	const categoria = decodeURIComponent(params.categoria ?? '').trim();

	if (!categoria || categoria === 'estado_revision') {
		throw error(404, 'Categoria no encontrada');
	}

	const { data, error: dbError } = await locals.supabase
		.from('vocabularios')
		.select(vocabularySelect)
		.eq('categoria', categoria)
		.order('orden', { ascending: true })
		.order('termino', { ascending: true });

	if (dbError) {
		throw error(500, `No se pudieron cargar los vocabularios de ${categoria}: ${dbError.message}`);
	}

	if (!data || data.length === 0) {
		throw error(404, `No existe la categoria ${categoria}`);
	}

	let metroOptions: Array<{ termino_id: string; termino: string }> = [];
	let estrofaTipoMetros: Array<{ estrofa_tipo_id: string; metro_id: string }> = [];

	if (categoria === 'estrofa_tipo') {
		const [metrosResp, relacionesResp] = await Promise.all([
			locals.supabase
				.from('vocabularios')
				.select('termino_id,termino')
				.eq('categoria', 'metro')
				.eq('activo', true)
				.order('orden', { ascending: true })
				.order('termino', { ascending: true }),
			locals.supabase
				.from('estrofa_tipo_metros')
				.select('estrofa_tipo_id,metro_id')
				.in(
					'estrofa_tipo_id',
					data.map((item) => item.termino_id)
				)
		]);

		if (metrosResp.error) {
			throw error(500, `No se pudieron cargar los metros: ${metrosResp.error.message}`);
		}
		if (relacionesResp.error) {
			throw error(500, `No se pudieron cargar las relaciones estrofa/metro: ${relacionesResp.error.message}`);
		}

		metroOptions = (metrosResp.data ?? []) as Array<{ termino_id: string; termino: string }>;
		estrofaTipoMetros = (relacionesResp.data ?? []) as Array<{
			estrofa_tipo_id: string;
			metro_id: string;
		}>;
	}

	const canManage = canManageVocabularios(profile.roleTerm);
	const isProtected = isProtectedVocabularyCategory(categoria);
	const canEdit = canManage && !isProtected;

	return {
		profile,
		categoria,
		canManage,
		isProtected,
		canEdit,
		vocabularios: data,
		metroOptions,
		estrofaTipoMetros
	};
};
