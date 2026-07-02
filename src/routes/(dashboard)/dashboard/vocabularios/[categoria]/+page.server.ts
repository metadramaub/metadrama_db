import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { canManageVocabularios, isProtectedVocabularyCategory } from '$lib/utils/permissions';

const vocabularySelect =
	'termino_id,categoria,termino,etiqueta,termino_padre_id,nivel,orden,definicion,ejemplo,bibliografia,equivalencias,patron_especifico,tipo_forma,tipo_rima,naturaleza_estrofica_id,tamanio_unidad_estrofica,arte_metrico,numero_silabas,activo';

type MetricMetadataOption = {
	termino_id: string;
	termino: string;
	etiqueta: string | null;
	activo?: boolean | null;
};

export const load: PageServerLoad = async ({ locals, params, parent }) => {
	const parentData = await parent();
	const profile = parentData.profile;
	const categoria = decodeURIComponent(params.categoria ?? '').trim();

	if (!categoria || categoria === 'estado_revision') {
		throw error(404, 'Categoría no encontrada');
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
		throw error(404, `No existe la categoría ${categoria}`);
	}

	let metroOptions: Array<{ termino_id: string; termino: string; numero_silabas: number | null }> = [];
	let estrofaTipoMetros: Array<{ estrofa_tipo_id: string; metro_id: string }> = [];
	let tipoRimaOptions: MetricMetadataOption[] = [];
	let naturalezaEstroficaOptions: MetricMetadataOption[] = [];

	if (categoria === 'estrofa_tipo') {
		const [metrosResp, relacionesResp, tipoRimaResp, naturalezaEstroficaResp] = await Promise.all([
			locals.supabase
				.from('vocabularios')
				.select('termino_id,termino,numero_silabas')
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
				),
			locals.supabase
				.from('vocabularios')
				.select('termino_id,termino,etiqueta')
				.eq('categoria', 'tipo_rima')
				.eq('activo', true)
				.order('orden', { ascending: true })
				.order('termino', { ascending: true }),
			locals.supabase
				.from('vocabularios')
				.select('termino_id,termino,etiqueta,activo')
				.eq('categoria', 'naturaleza_estrofica')
				.order('orden', { ascending: true })
				.order('termino', { ascending: true })
		]);

		if (metrosResp.error) {
			throw error(500, `No se pudieron cargar los metros: ${metrosResp.error.message}`);
		}
		if (relacionesResp.error) {
			throw error(500, `No se pudieron cargar las relaciones estrofa/metro: ${relacionesResp.error.message}`);
		}
		if (tipoRimaResp.error) {
			throw error(500, `No se pudieron cargar los tipos de rima: ${tipoRimaResp.error.message}`);
		}
		if (naturalezaEstroficaResp.error) {
			throw error(
				500,
				`No se pudieron cargar las naturalezas estróficas: ${naturalezaEstroficaResp.error.message}`
			);
		}

		metroOptions = (metrosResp.data ?? []) as Array<{
			termino_id: string;
			termino: string;
			numero_silabas: number | null;
		}>;
		estrofaTipoMetros = (relacionesResp.data ?? []) as Array<{
			estrofa_tipo_id: string;
			metro_id: string;
		}>;
		tipoRimaOptions = (tipoRimaResp.data ?? []) as MetricMetadataOption[];
		naturalezaEstroficaOptions = (naturalezaEstroficaResp.data ?? []) as MetricMetadataOption[];
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
		estrofaTipoMetros,
		tipoRimaOptions,
		naturalezaEstroficaOptions
	};
};
