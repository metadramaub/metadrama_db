import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import type { Json } from '$lib/types/database.types';
import { requireEditorProfile } from '$lib/server/auth';
import { forbiddenResponse } from '$lib/server/http';
import { generateDemarcatorFromMetricCatalog } from '$lib/server/demarcador-catalogo';
import { canManageVocabularios } from '$lib/utils/permissions';

const versionSelect =
	'version_id,numero,estado,fuente_tipo,catalogo_revision,fuente_actualizada_en,total_familias,total_familias_variantes,total_variantes_demarcables,generado_en';

export const POST: RequestHandler = async ({ locals }) => {
	const profile = await requireEditorProfile({ locals });
	if (!canManageVocabularios(profile.roleTerm)) {
		return forbiddenResponse('Solo admin o IP pueden generar pruebas del demarcador.');
	}

	let generated: Awaited<ReturnType<typeof generateDemarcatorFromMetricCatalog>>;
	try {
		generated = await generateDemarcatorFromMetricCatalog(locals.supabase);
	} catch (error) {
		return json(
			{
				error: 'generation_error',
				message: error instanceof Error ? error.message : 'No se pudo compilar el catálogo métrico.'
			},
			{ status: 500 }
		);
	}

	if (generated.artifact.familias.length === 0) {
		return json(
			{
				error: 'empty_catalog',
				message: 'No hay formas con una configuración principal demarcable.'
			},
			{ status: 409 }
		);
	}

	const existing = await locals.supabase
		.from('demarcador_versiones')
		.select(versionSelect)
		.eq('fuente_tipo', 'catalogo_metrico')
		.eq('huella_fuente', generated.sourceHash)
		.order('generado_en', { ascending: false })
		.limit(1)
		.maybeSingle();

	if (existing.error) {
		return json({ error: 'db_error', message: existing.error.message }, { status: 500 });
	}
	if (existing.data) {
		return json({
			version: existing.data,
			reused: true,
			warnings: generated.warnings
		});
	}

	const artifact = generated.artifact;
	const inserted = await locals.supabase
		.from('demarcador_versiones')
		.insert({
			esquema: artifact.esquema,
			artefacto: artifact as unknown as Json,
			huella_fuente: generated.sourceHash,
			fuente_tipo: 'catalogo_metrico',
			catalogo_revision: generated.catalogRevision,
			fuente_actualizada_en: artifact.fuenteActualizadaEn,
			total_familias: artifact.estadisticas.familias,
			total_familias_variantes: artifact.estadisticas.familiasConVariantes,
			total_variantes_demarcables: artifact.estadisticas.variantesDemarcables,
			generado_por: profile.userId
		})
		.select(versionSelect)
		.single();

	if (inserted.error) {
		return json({ error: 'db_error', message: inserted.error.message }, { status: 500 });
	}

	return json(
		{
			version: inserted.data,
			reused: false,
			warnings: generated.warnings
		},
		{ status: 201 }
	);
};
