import { json } from '@sveltejs/kit';
import { z } from 'zod';
import type { RequestHandler } from './$types';
import { requireEditorProfile } from '$lib/server/auth';
import { forbiddenResponse, validationErrorResponse } from '$lib/server/http';
import type { MetricLengthRule } from '$lib/metrica/catalogo';
import { metricLengthError } from '$lib/metrica/metric-length';
import { canManageVocabularios } from '$lib/utils/permissions';

type UntypedSupabaseClient = {
	from: (table: string) => any;
	rpc: (name: string, args: Record<string, unknown>) => any;
};

const uuid = z.uuid();
const nullableUuid = uuid.nullable();

const unitSchema = z.object({
	realizacion_prueba_id: uuid,
	realizacion_padre_id: nullableUuid,
	// La unidad no realiza ninguna sección: es la realización que no cuelga de ninguna otra.
	// Solo sus partes declaran cuál realizan.
	seccion_id: nullableUuid,
	orden: z.number().int().positive(),
	v_ini: z.number().int().positive(),
	v_fin: z.number().int().positive(),
	etiqueta: z.string().trim().max(240).nullable(),
	observaciones: z.string().trim().max(10_000).nullable()
});

const choiceSchema = z
	.object({
		realizacion_prueba_id: nullableUuid,
		grupo_eleccion_id: uuid,
		opcion_eleccion_id: nullableUuid,
		valor_texto: z.string().trim().min(1).max(240).nullable(),
		observaciones: z.string().trim().max(10_000).nullable()
	})
	.refine(
		(choice) => Number(choice.opcion_eleccion_id !== null) + Number(choice.valor_texto !== null) === 1,
		{ message: 'Cada respuesta debe contener una opción o un valor textual, pero no ambos.' }
	);

const deviationSchema = z.object({
	realizacion_prueba_id: nullableUuid,
	v_ini: z.number().int().positive(),
	v_fin: z.number().int().positive(),
	dimension: z.enum(['metro', 'rima', 'estructura', 'repeticion', 'rasgo', 'combinacion']),
	relacion_norma: z.enum([
		'diferente',
		'menor_que_norma',
		'mayor_que_norma',
		'falta_elemento_esperado',
		'aparece_elemento_no_esperado',
		'ruptura',
		'omision',
		'adicion',
		'sustitucion',
		'otra'
	]),
	metro_observado_id: nullableUuid,
	esquema_rima_observado_id: nullableUuid,
	seccion_observada_id: nullableUuid,
	repeticion_observada_id: nullableUuid,
	valor_rasgo_observado_id: nullableUuid,
	observaciones: z.string().trim().max(10_000).nullable()
});

const requestSchema = z.discriminatedUnion('action', [
	z.object({
		action: z.literal('create_scenario'),
		nombre: z.string().trim().min(1).max(240),
		descripcion: z.string().trim().max(10_000).nullable()
	}),
	z.object({
		action: z.literal('update_scenario'),
		escenario_id: uuid,
		nombre: z.string().trim().min(1).max(240),
		descripcion: z.string().trim().max(10_000).nullable()
	}),
	z.object({
		action: z.literal('delete_scenario'),
		escenario_id: uuid
	}),
	z.object({
		action: z.literal('save_sequence'),
		secuencia_prueba_id: nullableUuid,
		escenario_id: uuid,
		orden: z.number().int().positive(),
		v_ini: z.number().int().positive(),
		v_fin: z.number().int().positive(),
		forma_id: uuid,
		arquitectura_id: nullableUuid,
		observaciones: z.string().trim().max(30_000).nullable(),
		unidades: z.array(unitSchema).max(500),
		elecciones: z.array(choiceSchema).max(2_000),
		desviaciones: z.array(deviationSchema).max(1_000)
	}),
	z.object({
		action: z.literal('delete_sequence'),
		secuencia_prueba_id: uuid
	})
]);

async function requireMetricManager(locals: App.Locals) {
	const profile = await requireEditorProfile({ locals });
	return canManageVocabularios(profile.roleTerm) ? profile : null;
}

function databaseError(error: { code?: string; message: string } | null, fallback: string) {
	const message = error?.message ?? fallback;
	const forbidden = error?.code === '42501';
	return json(
		{ error: forbidden ? 'forbidden' : 'db_error', message },
		{ status: forbidden ? 403 : 500 }
	);
}

export const POST: RequestHandler = async ({ locals, request }) => {
	const profile = await requireMetricManager(locals);
	if (!profile) {
		return forbiddenResponse('Solo admin o IP pueden utilizar el editor métrico de prueba.');
	}

	const parsed = requestSchema.safeParse(await request.json().catch(() => ({})));
	if (!parsed.success) return validationErrorResponse(parsed.error);

	const db = locals.supabase as unknown as UntypedSupabaseClient;
	const input = parsed.data;

	if (input.action === 'create_scenario') {
		const { data, error } = await db
			.from('escenarios_editor_metrico')
			.insert({
				nombre: input.nombre,
				descripcion: input.descripcion,
				created_by: profile.userId,
				updated_by: profile.userId
			})
			.select('*')
			.single();
		if (error) return databaseError(error, 'No se pudo crear el escenario.');
		return json({ scenario: data }, { status: 201 });
	}

	if (input.action === 'update_scenario') {
		const { data, error } = await db
			.from('escenarios_editor_metrico')
			.update({
				nombre: input.nombre,
				descripcion: input.descripcion,
				updated_by: profile.userId
			})
			.eq('escenario_id', input.escenario_id)
			.select('*')
			.single();
		if (error) return databaseError(error, 'No se pudo actualizar el escenario.');
		return json({ scenario: data });
	}

	if (input.action === 'delete_scenario') {
		const { error } = await db
			.from('escenarios_editor_metrico')
			.delete()
			.eq('escenario_id', input.escenario_id);
		if (error) return databaseError(error, 'No se pudo eliminar el escenario.');
		return json({ deleted: true });
	}

	if (input.action === 'delete_sequence') {
		const { error } = await db
			.from('secuencias_editor_metrico')
			.delete()
			.eq('secuencia_prueba_id', input.secuencia_prueba_id);
		if (error) return databaseError(error, 'No se pudo eliminar la secuencia de prueba.');
		return json({ deleted: true });
	}

	if (input.v_fin < input.v_ini) {
		return json(
			{ error: 'validation_error', message: 'El verso final no puede ser anterior al inicial.' },
			{ status: 422 }
		);
	}
	if (input.arquitectura_id) {
		const { data: lengthRuleData, error: lengthRuleError } = await db
			.from('arquitecturas_reglas_longitud')
			.select(
				'arquitectura_id,arquitectura_nombre,modulo_versos,residuo_versos,minimo_versos,origen,explicacion'
			)
			.eq('arquitectura_id', input.arquitectura_id)
			.maybeSingle();
		if (lengthRuleError) {
			return databaseError(
				lengthRuleError,
				'No se pudo comprobar la longitud de la secuencia.'
			);
		}
		const lengthError = metricLengthError(
			(lengthRuleData as MetricLengthRule | null) ?? null,
			input.v_ini,
			input.v_fin,
			lengthRuleData?.arquitectura_nombre
		);
		if (lengthError) {
			return json({ error: 'validation_error', message: lengthError }, { status: 422 });
		}
	}
	for (const unit of input.unidades) {
		if (unit.v_fin < unit.v_ini || unit.v_ini < input.v_ini || unit.v_fin > input.v_fin) {
			return json(
				{
					error: 'validation_error',
					message: 'Todas las unidades deben quedar dentro del rango de la secuencia.'
				},
				{ status: 422 }
			);
		}
	}
	for (const deviation of input.desviaciones) {
		if (
			deviation.v_fin < deviation.v_ini ||
			deviation.v_ini < input.v_ini ||
			deviation.v_fin > input.v_fin
		) {
			return json(
				{
					error: 'validation_error',
					message: 'Todas las desviaciones deben quedar dentro del rango de la secuencia.'
				},
				{ status: 422 }
			);
		}
	}

	const { data, error } = await db.rpc('guardar_secuencia_editor_metrico_prueba', {
		p_datos: input
	});
	if (error) return databaseError(error, 'No se pudo guardar la secuencia métrica de prueba.');
	return json({ secuencia_prueba_id: data });
};
