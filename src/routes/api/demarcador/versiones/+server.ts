import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import type { Json } from '$lib/types/database.types';
import { requireEditorProfile } from '$lib/server/auth';
import { conflictResponse, forbiddenResponse } from '$lib/server/http';
import { canManageVocabularios } from '$lib/utils/permissions';
import { PoliticasDemarcadorPendientesError } from '$lib/demarcador-nuevo/generar';
import {
	esArtefactoDemarcadorNuevo,
	generarDemarcadorDesdeBaseDeDatos
} from '$lib/server/demarcador-nuevo';

const versionSelect =
	'version_id,numero,estado,esquema,artefacto,huella_fuente,fuente_actualizada_en,total_familias,total_familias_variantes,total_variantes_demarcables,generado_en,publicado_en';

export const POST: RequestHandler = async ({ locals }) => {
	const profile = await requireEditorProfile({ locals });
	if (!canManageVocabularios(profile.roleTerm)) {
		return forbiddenResponse('Solo admin o IP pueden generar el demarcador.');
	}

	let generated: Awaited<ReturnType<typeof generarDemarcadorDesdeBaseDeDatos>>;
	try {
		generated = await generarDemarcadorDesdeBaseDeDatos(locals.supabase);
	} catch (error) {
		if (error instanceof PoliticasDemarcadorPendientesError) {
			return conflictResponse(
				'No se puede generar el demarcador mientras haya políticas pendientes.',
				{ familias: error.familias }
			);
		}
		return json(
			{
				error: 'generation_error',
				message: error instanceof Error ? error.message : 'No se pudo generar el demarcador.'
			},
			{ status: 500 }
		);
	}

	const existingResp = await locals.supabase
		.from('demarcador_versiones')
		.select(versionSelect)
		.eq('huella_fuente', generated.huellaFuente)
		.order('generado_en', { ascending: false })
		.limit(1)
		.maybeSingle();

	if (existingResp.error) {
		return json({ error: 'db_error', message: existingResp.error.message }, { status: 500 });
	}
	if (existingResp.data && esArtefactoDemarcadorNuevo(existingResp.data.artefacto)) {
		return json({ version: existingResp.data, reutilizada: true });
	}

	const artefacto = generated.artefacto;
	const insertResp = await locals.supabase
		.from('demarcador_versiones')
		.insert({
			esquema: artefacto.esquema,
			artefacto: artefacto as unknown as Json,
			huella_fuente: generated.huellaFuente,
			fuente_actualizada_en: artefacto.fuenteActualizadaEn,
			total_familias: artefacto.estadisticas.familias,
			total_familias_variantes: artefacto.estadisticas.familiasConVariantes,
			total_variantes_demarcables: artefacto.estadisticas.variantesDemarcables,
			generado_por: profile.userId
		})
		.select(versionSelect)
		.single();

	if (insertResp.error) {
		return json({ error: 'db_error', message: insertResp.error.message }, { status: 500 });
	}

	return json({ version: insertResp.data, reutilizada: false }, { status: 201 });
};
