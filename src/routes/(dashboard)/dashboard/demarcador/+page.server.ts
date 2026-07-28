import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import {
	construirAuditoriaDemarcador,
	type ConfiguracionFamiliaAuditoria,
	type EstrofaFuenteAuditoria,
	type EstrofaMetroFuenteAuditoria,
	type OpcionFuenteAuditoria
} from '$lib/demarcador/auditoria';
import { canManageVocabularios } from '$lib/utils/permissions';

const estrofaSelect =
	'termino_id,termino,etiqueta,termino_padre_id,orden,tipo_forma,tipo_rima_id,naturaleza_estrofica_id,tamanio_unidad_estrofica,arte_metrico,patron_especifico';

export const load: PageServerLoad = async ({ locals, parent }) => {
	const parentData = await parent();
	const profile = parentData.profile;

	if (!canManageVocabularios(profile.roleTerm)) {
		throw error(403, 'Solo admin o IP pueden revisar la configuración del demarcador.');
	}

	const [estrofasResp, opcionesResp, relacionesResp, configuracionesResp, versionesResp] =
		await Promise.all([
			locals.supabase
				.from('vocabularios')
				.select(estrofaSelect)
				.eq('categoria', 'estrofa_tipo')
				.eq('activo', true)
				.order('orden', { ascending: true })
				.order('termino', { ascending: true }),
			locals.supabase
				.from('vocabularios')
				.select('termino_id,termino,etiqueta,numero_silabas')
				.in('categoria', ['tipo_rima', 'naturaleza_estrofica', 'metro']),
			locals.supabase.from('estrofa_tipo_metros').select('estrofa_tipo_id,metro_id'),
			locals.supabase.from('demarcador_familias_config').select('familia_id,politica,revisado_en'),
			locals.supabase
				.from('demarcador_versiones')
				.select(
					'version_id,numero,estado,fuente_actualizada_en,total_familias,total_familias_variantes,total_variantes_demarcables,generado_en,publicado_en'
				)
				.order('generado_en', { ascending: false })
		]);

	if (estrofasResp.error) {
		throw error(500, `No se pudieron cargar las formas estróficas: ${estrofasResp.error.message}`);
	}
	if (opcionesResp.error) {
		throw error(500, `No se pudieron cargar los rasgos métricos: ${opcionesResp.error.message}`);
	}
	if (relacionesResp.error) {
		throw error(
			500,
			`No se pudieron cargar las relaciones entre formas y metros: ${relacionesResp.error.message}`
		);
	}

	if (configuracionesResp.error) {
		throw error(
			500,
			`No se pudo cargar la revisión del demarcador: ${configuracionesResp.error.message}`
		);
	}
	if (versionesResp.error) {
		throw error(
			500,
			`No se pudieron cargar las versiones del demarcador: ${versionesResp.error.message}`
		);
	}

	return {
		profile,
		versiones: versionesResp.data ?? [],
		auditoria: construirAuditoriaDemarcador({
			estrofas: (estrofasResp.data ?? []) as EstrofaFuenteAuditoria[],
			opciones: (opcionesResp.data ?? []) as OpcionFuenteAuditoria[],
			relacionesMetro: (relacionesResp.data ?? []) as EstrofaMetroFuenteAuditoria[],
			configuraciones: (configuracionesResp.data ?? []) as ConfiguracionFamiliaAuditoria[]
		})
	};
};
