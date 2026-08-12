import { json } from '@sveltejs/kit';
import { z } from 'zod';
import type { RequestHandler } from './$types';
import { METRIC_CATALOG_RESOURCES, type MetricCatalogResource } from '$lib/metrica/catalogo';
import { requireEditorProfile } from '$lib/server/auth';
import { forbiddenResponse, validationErrorResponse } from '$lib/server/http';
import { canManageVocabularios } from '$lib/utils/permissions';

type UntypedSupabaseClient = {
	from: (table: string) => any;
};

type ResourceDefinition = {
	table: string;
	keys: string[];
	fields: string[];
	booleanFields?: string[];
	numberFields?: string[];
};

/**
 * Los recursos del catálogo que se escriben. No están todos: `choiceOptions` se deriva del
 * catálogo y se lee de una vista, así que no admite escritura por ningún camino.
 */
const resources: Partial<Record<MetricCatalogResource, ResourceDefinition>> = {
	traditions: {
		table: 'tradiciones_metricas',
		keys: ['tradicion_id'],
		fields: [
			'slug',
			'nombre',
			'descripcion',
			'ambito_geografico',
			'periodo_desde',
			'periodo_hasta',
			'estado_revision',
			'activo',
			'orden'
		],
		booleanFields: ['activo'],
		numberFields: ['periodo_desde', 'periodo_hasta', 'orden']
	},
	formTraditions: {
		table: 'formas_tradiciones',
		keys: ['forma_id', 'tradicion_id'],
		fields: ['cronologia', 'nota']
	},
	aliases: {
		table: 'denominaciones_metricas',
		keys: ['alias_id'],
		fields: [
			'destino',
			'nombre',
			'slug_normalizado',
			'idioma',
			'preferente',
			'fuente_id'
		],
		booleanFields: ['preferente']
	},
	formRelations: {
		table: 'forma_relaciones',
		keys: ['relacion_id'],
		fields: [
			'forma_origen_id',
			'forma_destino_id',
			'tipo_relacion',
			'cantidad_min',
			'cantidad_max',
			'orden_composicion',
			'nota',
			'estado_revision'
		],
		numberFields: ['cantidad_min', 'cantidad_max', 'orden_composicion']
	},
	verseModels: {
		table: 'metros',
		keys: ['metro_id'],
		fields: [
			'slug',
			'nombre',
			'silabas',
			'tipo',
			'tipo_cesura',
			'descripcion',
			'estado_revision',
			'activo',
			'orden'
		],
		booleanFields: ['activo'],
		numberFields: ['silabas', 'orden']
	},
	verseSegments: {
		table: 'metro_segmentos',
		keys: ['segmento_id'],
		fields: [
			'metro_id',
			'posicion',
			'silabas',
			'funcion',
			'pausa_posterior',
			'alternativa',
			'nota'
		],
		numberFields: ['posicion', 'silabas', 'alternativa']
	},
	metricPatterns: {
		table: 'esquemas_metricos',
		keys: ['esquema_metrico_id'],
		fields: [
			'arquitectura_id',
			'slug',
			'nombre',
			'seccion_id',
			'tipo_secuencia',
			'medida_uniforme',
			'descripcion',
			'estado_revision'
		],
		booleanFields: ['medida_uniforme']
	},
	metricPositions: {
		table: 'esquema_metrico_posiciones',
		keys: ['posicion_id'],
		fields: [
			'esquema_metrico_id',
			'medida',
			'posicion',
			'opcional',
			'grupo_repeticion',
			'alternativa',
			'nota'
		],
		booleanFields: ['opcional'],
		numberFields: ['posicion', 'alternativa']
	},
	metricOptions: {
		table: 'esquema_metrico_opciones',
		keys: ['esquema_metrico_id', 'metro_id'],
		fields: ['orden', 'nota'],
		numberFields: ['orden']
	},
	rhymePatterns: {
		table: 'esquemas_rima',
		keys: ['esquema_rima_id'],
		fields: [
			'arquitectura_id',
			'slug',
			'nombre',
			'notacion',
			'tipo_rima_id',
			'seccion_id',
			'tipo_secuencia',
			'modalidad',
			'descripcion',
			'estado_revision'
		]
	},
	rhymePositions: {
		table: 'esquema_rima_posiciones',
		keys: ['posicion_id'],
		fields: [
			'esquema_rima_id',
			'bloque',
			'seccion',
			'posicion',
			'ubicacion',
			'clase_rima',
			'suelto',
			'opcional',
			'nota'
		],
		booleanFields: ['suelto', 'opcional'],
		numberFields: ['bloque', 'posicion']
	},
	rhymeLinks: {
		table: 'esquema_rima_enlaces',
		keys: ['enlace_id'],
		fields: [
			'esquema_rima_id',
			'bloque_origen',
			'posicion_origen',
			'ubicacion_origen',
			'desplazamiento_bloque',
			'bloque_destino',
			'posicion_destino',
			'ubicacion_destino',
			'nota'
		],
		numberFields: [
			'bloque_origen',
			'posicion_origen',
			'desplazamiento_bloque',
			'bloque_destino',
			'posicion_destino'
		]
	},
	rhymeRestrictions: {
		table: 'esquema_rima_restricciones',
		keys: ['restriccion_id'],
		fields: [
			'esquema_rima_id',
			'tipo',
			'valor_numero',
			'valor_texto',
			'esquema_referido_id',
			'descripcion'
		],
		numberFields: ['valor_numero']
	},
	patternCombinations: {
		table: 'variedades_arquitectura',
		keys: ['variedad_id'],
		fields: [
			'arquitectura_id',
			'slug',
			'nombre',
			'descripcion',
			'esquema_metrico_id',
			'esquema_rima_id',
			'modalidad',
			'estado_revision',
			'activo',
			'orden'
		],
		booleanFields: ['activo'],
		numberFields: ['orden']
	},
	sections: {
		table: 'estructuras_secciones',
		keys: ['seccion_id'],
		fields: [
			'arquitectura_id',
			'seccion_padre_id',
			'tipo_seccion',
			'nombre',
			'orden',
			'repeticiones_min',
			'repeticiones_max',
			'versos_min',
			'versos_max',
			'arquitectura_referenciada_id',
			'esquema_metrico_id',
			'esquema_rima_id',
			'primera_realizacion_define_patron',
			'nota'
		],
		booleanFields: ['primera_realizacion_define_patron'],
		numberFields: ['orden', 'repeticiones_min', 'repeticiones_max', 'versos_min', 'versos_max']
	},
	repetitionPatterns: {
		table: 'repeticiones_metricas',
		keys: ['repeticion_id'],
		fields: [
			'arquitectura_id',
			'slug',
			'tipo',
			'nombre',
			'modalidad',
			'descripcion',
			'estado_revision'
		]
	},
	repetitionPositions: {
		table: 'repeticion_posiciones',
		keys: ['posicion_id'],
		fields: [
			'repeticion_id',
			'bloque',
			'posicion',
			'bloque_origen',
			'posicion_origen',
			'etiqueta_funcional',
			'condicion'
		],
		numberFields: ['bloque', 'posicion', 'bloque_origen', 'posicion_origen']
	},
	traits: {
		table: 'rasgos_metricos',
		keys: ['rasgo_id'],
		fields: [
			'slug',
			'nombre',
			'descripcion',
			'tipo_valor',
			'observabilidad',
			'demarcable',
			'estado_revision',
			'activo'
		],
		booleanFields: ['demarcable', 'activo']
	},
	traitValues: {
		table: 'rasgo_valores',
		keys: ['valor_id'],
		fields: ['rasgo_id', 'slug', 'nombre', 'descripcion', 'orden', 'activo'],
		booleanFields: ['activo'],
		numberFields: ['orden']
	},
	configurationTraits: {
		table: 'arquitectura_rasgos',
		// El valor de un rasgo es siempre de vocabulario desde el 9 de agosto de 2026: se
		// retiraron `valor_numero` y `valor_texto`, y esta lista seguía nombrándolas.
		keys: ['arquitectura_id', 'rasgo_id', 'modalidad', 'valor_id'],
		fields: ['valor_id', 'posiciones_max', 'nota'],
		numberFields: ['posiciones_max']
	},
	choiceGroups: {
		table: 'grupos_eleccion_metrica',
		keys: ['grupo_eleccion_id'],
		fields: [
			'arquitectura_id',
			'slug',
			'ayuda_editor',
			'dimension',
			'tipo_control',
			'alcance',
			'seccion_id',
			'selecciones_min',
			'selecciones_max',
			'permite_aplicar_global',
			'define_norma',
			'estado_revision',
			'activo',
			'orden'
		],
		booleanFields: ['permite_aplicar_global', 'define_norma', 'activo'],
		numberFields: ['selecciones_min', 'selecciones_max', 'orden']
	},
	sources: {
		table: 'fuentes_metricas',
		keys: ['fuente_id'],
		fields: ['tipo', 'autoria', 'titulo', 'anio', 'publicacion', 'doi', 'url', 'cita', 'nota'],
		numberFields: ['anio']
	},
	sourceClaims: {
		table: 'afirmaciones_fuentes_metricas',
		keys: ['afirmacion_id'],
		fields: ['fuente_id', 'destino', 'localizador', 'resumen', 'confianza', 'estado_revision']
	}
};

const resourceSchema = z.enum(METRIC_CATALOG_RESOURCES);
const recordSchema = z.record(z.string(), z.unknown());
const mutationSchema = z.object({
	resource: resourceSchema,
	keys: recordSchema.optional(),
	values: recordSchema.optional()
});

async function requireCatalogManager(locals: App.Locals) {
	const profile = await requireEditorProfile({ locals });
	if (!canManageVocabularios(profile.roleTerm)) return null;
	return profile;
}

function normalizeValues(
	resource: MetricCatalogResource,
	definition: ResourceDefinition,
	input: Record<string, unknown>,
	includeKeys: boolean
): Record<string, unknown> {
	const allowed = new Set([...definition.fields, ...(includeKeys ? definition.keys : [])]);
	const output: Record<string, unknown> = {};
	for (const [field, rawValue] of Object.entries(input)) {
		if (!allowed.has(field)) continue;
		if (definition.booleanFields?.includes(field)) {
			output[field] = Boolean(rawValue);
			continue;
		}
		if (definition.numberFields?.includes(field)) {
			if (rawValue === '' || rawValue === null || rawValue === undefined) {
				output[field] = null;
				continue;
			}
			const number = Number(rawValue);
			if (!Number.isFinite(number)) throw new Error(`El campo ${field} debe ser numérico.`);
			output[field] = number;
			continue;
		}
		if (typeof rawValue === 'string') {
			const value = rawValue.trim();
			output[field] = value === '' ? null : value;
			continue;
		}
		output[field] = rawValue ?? null;
	}
	if (resource === 'metricPositions' && 'medida' in output) {
		const [type, id] = String(output.medida ?? '').split(':', 2);
		delete output.medida;
		output.metro_id = type === 'metro' && id ? id : null;
	}
	if (resource === 'aliases' && 'destino' in output) {
		const targetFields = [
			'forma_id',
			'arquitectura_id',
			'esquema_metrico_id',
			'esquema_rima_id',
			'seccion_id',
			'repeticion_id'
		];
		const [type, id] = String(output.destino ?? '').split(':', 2);
		delete output.destino;
		for (const field of targetFields) output[field] = null;
		if (targetFields.includes(type) && id) output[type] = id;
	}
	if (resource === 'sourceClaims' && 'destino' in output) {
		const targetFields = [
			'forma_id',
			'tradicion_id',
			'arquitectura_id',
			'esquema_metrico_id',
			'esquema_rima_id',
			'rasgo_id'
		];
		const [type, id] = String(output.destino ?? '').split(':', 2);
		delete output.destino;
		for (const field of targetFields) output[field] = null;
		if (targetFields.includes(type) && id) output[type] = id;
	}
	return output;
}

function applyKeys(query: any, definition: ResourceDefinition, keys: Record<string, unknown>) {
	for (const field of definition.keys) {
		const value = keys[field];
		if (typeof value !== 'string' || !value.trim()) {
			throw new Error(`Falta la clave ${field}.`);
		}
		query = query.eq(field, value);
	}
	return query;
}

/**
 * Un recurso derivado no se escribe. Se responde con un error explícito en vez de dejar que
 * falle contra la vista, para que quede claro que la vía es cambiar el catálogo.
 */
function derivedResourceResponse(resource: MetricCatalogResource) {
	return json(
		{
			error: 'derived_resource',
			message: `«${resource}» se deriva del catálogo y no se puede escribir: cambia la entidad de la que sale.`
		},
		{ status: 409 }
	);
}

function databaseError(error: { code?: string; message: string }) {
	return json(
		{
			error: error.code === '23505' ? 'conflict' : 'db_error',
			message:
				error.code === '23505'
					? 'Ya existe un registro con esa combinación de valores.'
					: error.message
		},
		{ status: error.code === '23505' ? 409 : 500 }
	);
}

export const POST: RequestHandler = async ({ locals, request }) => {
	const profile = await requireCatalogManager(locals);
	if (!profile) return forbiddenResponse('Solo admin o IP pueden ampliar el catálogo métrico.');
	const parsed = mutationSchema.safeParse(await request.json().catch(() => ({})));
	if (!parsed.success) return validationErrorResponse(parsed.error);
	const definition = resources[parsed.data.resource];
	if (!definition) return derivedResourceResponse(parsed.data.resource);
	let values: Record<string, unknown>;
	try {
		values = normalizeValues(parsed.data.resource, definition, parsed.data.values ?? {}, true);
	} catch (error) {
		return json(
			{
				error: 'validation_error',
				message: error instanceof Error ? error.message : 'Datos inválidos.'
			},
			{ status: 422 }
		);
	}
	const { data, error } = await (locals.supabase as unknown as UntypedSupabaseClient)
		.from(definition.table)
		.insert(values)
		.select('*')
		.single();
	if (error) return databaseError(error);
	return json({ row: data }, { status: 201 });
};

export const PATCH: RequestHandler = async ({ locals, request }) => {
	const profile = await requireCatalogManager(locals);
	if (!profile) return forbiddenResponse('Solo admin o IP pueden modificar el catálogo métrico.');
	const parsed = mutationSchema.safeParse(await request.json().catch(() => ({})));
	if (!parsed.success) return validationErrorResponse(parsed.error);
	const definition = resources[parsed.data.resource];
	if (!definition) return derivedResourceResponse(parsed.data.resource);
	let values: Record<string, unknown>;
	try {
		values = normalizeValues(parsed.data.resource, definition, parsed.data.values ?? {}, false);
		let query = (locals.supabase as unknown as UntypedSupabaseClient)
			.from(definition.table)
			.update(values);
		query = applyKeys(query, definition, parsed.data.keys ?? {});
		const { data, error } = await query.select('*').single();
		if (error) return databaseError(error);
		return json({ row: data });
	} catch (error) {
		return json(
			{
				error: 'validation_error',
				message: error instanceof Error ? error.message : 'Datos inválidos.'
			},
			{ status: 422 }
		);
	}
};

export const DELETE: RequestHandler = async ({ locals, request }) => {
	const profile = await requireCatalogManager(locals);
	if (!profile)
		return forbiddenResponse('Solo admin o IP pueden retirar datos del catálogo métrico.');
	const parsed = mutationSchema.safeParse(await request.json().catch(() => ({})));
	if (!parsed.success) return validationErrorResponse(parsed.error);
	const definition = resources[parsed.data.resource];
	if (!definition) return derivedResourceResponse(parsed.data.resource);
	try {
		let query = (locals.supabase as unknown as UntypedSupabaseClient)
			.from(definition.table)
			.delete();
		query = applyKeys(query, definition, parsed.data.keys ?? {});
		const { error } = await query;
		if (error) return databaseError(error);
		return json({ deleted: true });
	} catch (error) {
		return json(
			{
				error: 'validation_error',
				message: error instanceof Error ? error.message : 'Datos inválidos.'
			},
			{ status: 422 }
		);
	}
};
