import { json } from '@sveltejs/kit';
import { z } from 'zod';
import type { RequestHandler } from './$types';
import {
	METRIC_CATALOG_RESOURCES,
	type MetricCatalogResource
} from '$lib/metrica/catalogo';
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

const resources: Record<MetricCatalogResource, ResourceDefinition> = {
	families: {
		table: 'familias_metricas',
		keys: ['familia_id'],
		fields: [
			'slug',
			'nombre',
			'descripcion',
			'familia_padre_id',
			'estado_revision',
			'activo',
			'orden'
		],
		booleanFields: ['activo'],
		numberFields: ['orden']
	},
	familyForms: {
		table: 'familias_formas',
		keys: ['familia_id', 'forma_id'],
		fields: ['es_principal', 'orden', 'nota'],
		booleanFields: ['es_principal'],
		numberFields: ['orden']
	},
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
		keys: ['forma_id', 'tradicion_id', 'tipo_relacion'],
		fields: ['es_principal', 'cronologia', 'nota'],
		booleanFields: ['es_principal']
	},
	aliases: {
		table: 'denominaciones_metricas',
		keys: ['alias_id'],
		fields: [
			'destino',
			'nombre',
			'slug_normalizado',
			'tipo_alias',
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
		table: 'modelos_verso',
		keys: ['modelo_verso_id'],
		fields: [
			'slug',
			'nombre',
			'metro_id',
			'tipo',
			'silabas_totales',
			'tipo_cesura',
			'patron_acentual',
			'descripcion',
			'estado_revision',
			'activo'
		],
		booleanFields: ['activo'],
		numberFields: ['silabas_totales']
	},
	verseSegments: {
		table: 'modelo_verso_segmentos',
		keys: ['segmento_id'],
		fields: [
			'modelo_verso_id',
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
		table: 'patrones_metricos',
		keys: ['patron_metrico_id'],
		fields: [
			'configuracion_id',
			'nombre',
			'ambito',
			'tipo',
			'descripcion',
			'estado_revision'
		]
	},
	metricPositions: {
		table: 'patron_metrico_posiciones',
		keys: ['posicion_id'],
		fields: [
			'patron_metrico_id',
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
		table: 'patron_metrico_opciones',
		keys: ['patron_metrico_id', 'metro_id'],
		fields: ['orden', 'nota'],
		numberFields: ['orden']
	},
	rhymePatterns: {
		table: 'patrones_rima',
		keys: ['patron_rima_id'],
		fields: [
			'configuracion_id',
			'nombre',
			'esquema',
			'tipo_rima_id',
			'ambito',
			'comportamiento',
			'fijeza',
			'descripcion',
			'estado_revision'
		]
	},
	rhymePositions: {
		table: 'patron_rima_posiciones',
		keys: ['posicion_id'],
		fields: [
			'patron_rima_id',
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
		table: 'patron_rima_enlaces',
		keys: ['enlace_id'],
		fields: [
			'patron_rima_id',
			'bloque_origen',
			'posicion_origen',
			'ubicacion_origen',
			'desplazamiento_bloque',
			'bloque_destino',
			'posicion_destino',
			'ubicacion_destino',
			'tipo_enlace',
			'obligatorio',
			'nota'
		],
		booleanFields: ['obligatorio'],
		numberFields: [
			'bloque_origen',
			'posicion_origen',
			'desplazamiento_bloque',
			'bloque_destino',
			'posicion_destino'
		]
	},
	rhymeRestrictions: {
		table: 'patron_rima_restricciones',
		keys: ['restriccion_id'],
		fields: [
			'patron_rima_id',
			'tipo',
			'valor_numero',
			'valor_texto',
			'descripcion',
			'obligatoria'
		],
		booleanFields: ['obligatoria'],
		numberFields: ['valor_numero']
	},
	patternCombinations: {
		table: 'combinaciones_patrones_configuracion',
		keys: ['combinacion_id'],
		fields: [
			'configuracion_id',
			'slug',
			'nombre',
			'descripcion',
			'patron_metrico_id',
			'patron_rima_id',
			'preferente',
			'estado_revision',
			'activo',
			'orden'
		],
		booleanFields: ['preferente', 'activo'],
		numberFields: ['orden']
	},
	sections: {
		table: 'estructuras_secciones',
		keys: ['seccion_id'],
		fields: [
			'configuracion_id',
			'seccion_padre_id',
			'tipo_seccion',
			'nombre',
			'orden',
			'repeticiones_min',
			'repeticiones_max',
			'versos_min',
			'versos_max',
			'configuracion_referenciada_id',
			'patron_metrico_id',
			'patron_rima_id',
			'nota'
		],
		numberFields: [
			'orden',
			'repeticiones_min',
			'repeticiones_max',
			'versos_min',
			'versos_max'
		]
	},
	repetitionPatterns: {
		table: 'patrones_repeticion',
		keys: ['patron_repeticion_id'],
		fields: [
			'configuracion_id',
			'tipo',
			'ambito',
			'regla',
			'fijeza',
			'descripcion',
			'estado_revision'
		]
	},
	repetitionPositions: {
		table: 'patron_repeticion_posiciones',
		keys: ['posicion_id'],
		fields: [
			'patron_repeticion_id',
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
		table: 'configuracion_rasgos',
		keys: ['configuracion_id', 'rasgo_id', 'modalidad'],
		fields: ['valor_id', 'valor_numero', 'valor_texto', 'nota'],
		numberFields: ['valor_numero']
	},
	choiceGroups: {
		table: 'grupos_eleccion_metrica',
		keys: ['grupo_eleccion_id'],
		fields: [
			'configuracion_id',
			'slug',
			'nombre',
			'ayuda_editor',
			'dimension',
			'tipo_control',
			'alcance',
			'seccion_id',
			'selecciones_min',
			'selecciones_max',
			'permite_aplicar_global',
			'estado_revision',
			'activo',
			'orden'
		],
		booleanFields: ['permite_aplicar_global', 'activo'],
		numberFields: ['selecciones_min', 'selecciones_max', 'orden']
	},
	choiceOptions: {
		table: 'opciones_eleccion_metrica',
		keys: ['opcion_eleccion_id'],
		fields: [
			'grupo_eleccion_id',
			'slug',
			'nombre',
			'descripcion',
			'objetivo',
			'materializa_seccion_id',
			'extension_desde_seccion_id',
			'posicion_unidad',
			'activo',
			'orden'
		],
		booleanFields: ['activo'],
		numberFields: ['posicion_unidad', 'orden']
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
		fields: [
			'fuente_id',
			'destino',
			'localizador',
			'resumen',
			'confianza',
			'estado_revision'
		]
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
		output.modelo_verso_id = type === 'modelo' && id ? id : null;
	}
	if (resource === 'aliases' && 'destino' in output) {
		const targetFields = [
			'forma_id',
			'configuracion_id',
			'patron_metrico_id',
			'patron_rima_id',
			'seccion_id',
			'patron_repeticion_id'
		];
		const [type, id] = String(output.destino ?? '').split(':', 2);
		delete output.destino;
		for (const field of targetFields) output[field] = null;
		if (targetFields.includes(type) && id) output[type] = id;
	}
	if (resource === 'sourceClaims' && 'destino' in output) {
		const targetFields = [
			'forma_id',
			'familia_id',
			'tradicion_id',
			'configuracion_id',
			'patron_metrico_id',
			'patron_rima_id',
			'rasgo_id'
		];
		const [type, id] = String(output.destino ?? '').split(':', 2);
		delete output.destino;
		for (const field of targetFields) output[field] = null;
		if (targetFields.includes(type) && id) output[type] = id;
	}
	if (resource === 'choiceOptions' && 'objetivo' in output) {
		const targetFields = [
			'metro_id',
			'patron_metrico_id',
			'patron_rima_id',
			'combinacion_id',
			'seccion_id',
			'patron_repeticion_id',
			'rasgo_id',
			'valor_rasgo_id'
		];
		const [type, id] = String(output.objetivo ?? '').split(':', 2);
		delete output.objetivo;
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
	let values: Record<string, unknown>;
	try {
		values = normalizeValues(parsed.data.resource, definition, parsed.data.values ?? {}, true);
	} catch (error) {
		return json(
			{ error: 'validation_error', message: error instanceof Error ? error.message : 'Datos inválidos.' },
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
			{ error: 'validation_error', message: error instanceof Error ? error.message : 'Datos inválidos.' },
			{ status: 422 }
		);
	}
};

export const DELETE: RequestHandler = async ({ locals, request }) => {
	const profile = await requireCatalogManager(locals);
	if (!profile) return forbiddenResponse('Solo admin o IP pueden retirar datos del catálogo métrico.');
	const parsed = mutationSchema.safeParse(await request.json().catch(() => ({})));
	if (!parsed.success) return validationErrorResponse(parsed.error);
	const definition = resources[parsed.data.resource];
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
			{ error: 'validation_error', message: error instanceof Error ? error.message : 'Datos inválidos.' },
			{ status: 422 }
		);
	}
};
