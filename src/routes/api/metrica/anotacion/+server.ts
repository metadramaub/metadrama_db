import { json } from '@sveltejs/kit';
import { z } from 'zod';
import type { RequestHandler } from './$types';
import { requireEditorProfile } from '$lib/server/auth';
import { validationErrorResponse } from '$lib/server/http';
import type { MetricLengthRule } from '$lib/metrica/catalogo';
import { metricLengthError } from '$lib/metrica/metric-length';

type UntypedSupabaseClient = {
	from: (table: string) => any;
	rpc: (name: string, args: Record<string, unknown>) => any;
};

const uuid = z.uuid();
const nullableUuid = uuid.nullable();

/**
 * Un identificador **derivado**, que no es un UUID de los que genera la base.
 *
 * `opciones_eleccion_metrica` construye el suyo con `md5(...)::uuid` sobre el contenido de la
 * opción, de modo que la misma opción conserva su identificador aunque el catálogo se regenere. Un
 * hash no lleva los bits de versión ni de variante que exige la norma: **672 de las 680 opciones del
 * catálogo no la cumplen**, y las ocho que sí es por azar.
 *
 * `z.uuid()` los rechazaba a todos —«Invalid UUID»— y con ellos cualquier respuesta que el editor
 * eligiera de una lista. `z.guid()` comprueba la forma sin exigir la versión, que es lo que aquí
 * corresponde: quien garantiza que ese identificador existe no es esta validación, sino la base,
 * que resuelve la opción contra el catálogo al guardar.
 */
const derivedUuid = z.guid();

const unitSchema = z.object({
	realizacion_id: uuid,
	realizacion_padre_id: nullableUuid,
	// La unidad no realiza ninguna sección: es la realización que no cuelga de ninguna otra.
	// Solo sus partes declaran cuál realizan.
	seccion_id: nullableUuid,
	orden: z.number().int().positive(),
	v_ini: z.number().int().positive(),
	v_fin: z.number().int().positive(),
	etiqueta: z.string().trim().max(240).nullable(),
	observaciones: z.string().trim().max(10_000).nullable(),
	/**
	 * La arquitectura de esta unidad cuando no es la de su secuencia: la décima aumentada entre
	 * décimas normales. La base comprueba en un disparador que sea de la misma forma y esté
	 * declarada intercalable, así que aquí solo se deja pasar.
	 */
	arquitectura_id: nullableUuid.optional()
});

const choiceSchema = z
	.object({
		realizacion_id: nullableUuid,
		grupo_eleccion_id: uuid,
		opcion_eleccion_id: derivedUuid.nullable(),
		valor_texto: z.string().trim().min(1).max(240).nullable(),
		observaciones: z.string().trim().max(10_000).nullable()
	})
	.refine(
		(choice) => Number(choice.opcion_eleccion_id !== null) + Number(choice.valor_texto !== null) === 1,
		{ message: 'Cada respuesta debe contener una opción o un valor textual, pero no ambos.' }
	);

// El vocabulario vive en la base (20260803100000_vocabulario_de_las_desviaciones.sql). Aquí
// solo se replica para rechazar pronto lo que la base rechazaría de todos modos: cinco
// dimensiones y seis relaciones, sin sinónimos.
const deviationSchema = z.object({
	realizacion_id: nullableUuid,
	v_ini: z.number().int().positive(),
	v_fin: z.number().int().positive(),
	dimension: z.enum(['metro', 'rima', 'estructura', 'repeticion', 'rasgo']),
	relacion_norma: z.enum([
		'diferente',
		'falta',
		'sobra',
		'menor_que_norma',
		'mayor_que_norma',
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
		action: z.literal('save_sequence'),
		anotacion_id: nullableUuid,
		// Una prueba cuelga de un escenario ficticio o anota una secuencia real. La
		// exclusividad se comprueba en el handler para poder explicarla.
		escenario_id: nullableUuid.default(null),
		secuencia_id: nullableUuid.default(null),
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
]);

function databaseError(error: { code?: string; message: string } | null, fallback: string) {
	const message = error?.message ?? fallback;
	const forbidden = error?.code === '42501';
	return json(
		{ error: forbidden ? 'forbidden' : 'db_error', message },
		{ status: forbidden ? 403 : 500 }
	);
}

export const POST: RequestHandler = async ({ locals, request }) => {
	/**
	 * **Quién puede anotar qué lo decide la base, no este endpoint.**
	 *
	 * Aquí hubo una puerta de admin o IP, de cuando esto era un laboratorio. Desde que los editores
	 * anotan sus obras, esa puerta las cerraba todas: el permiso depende de la obra —admin o IP con
	 * cualquiera, editor con la suya— y eso lo sabe `guardar_anotacion_metrica`, que lo comprueba
	 * con el mismo predicado que gobierna las políticas. Si dice que no, llega como 42501 y sale de
	 * aquí como un 403.
	 *
	 * Basta entonces con exigir sesión, que es lo que impide que esto quede abierto a cualquiera.
	 */
	await requireEditorProfile({ locals });

	const parsed = requestSchema.safeParse(await request.json().catch(() => ({})));
	if (!parsed.success) return validationErrorResponse(parsed.error);

	const db = locals.supabase as unknown as UntypedSupabaseClient;
	const input = parsed.data;

	if (Number(input.escenario_id !== null) + Number(input.secuencia_id !== null) !== 1) {
		return json(
			{
				error: 'validation_error',
				message:
					'Una prueba anota un escenario ficticio o una secuencia real, nunca las dos ni ninguna.'
			},
			{ status: 422 }
		);
	}

	// En la anotación en sombra el rango lo manda la secuencia real, igual que en la base:
	// validar contra lo que mande el cliente comprobaría un rango que no se va a guardar.
	let rangeStart = input.v_ini;
	let rangeEnd = input.v_fin;
	if (input.secuencia_id) {
		const { data: realSequence, error: realSequenceError } = await db
			.from('secuencias_metricas')
			.select('v_ini,v_fin')
			.eq('secuencia_id', input.secuencia_id)
			.maybeSingle();
		if (realSequenceError) {
			return databaseError(realSequenceError, 'No se pudo leer la secuencia real.');
		}
		if (!realSequence) {
			return json(
				{ error: 'validation_error', message: 'La secuencia real no existe.' },
				{ status: 422 }
			);
		}
		rangeStart = Number(realSequence.v_ini);
		rangeEnd = Number(realSequence.v_fin);
	}

	if (rangeEnd < rangeStart) {
		return json(
			{ error: 'validation_error', message: 'El verso final no puede ser anterior al inicial.' },
			{ status: 422 }
		);
	}
	if (input.arquitectura_id) {
		const { data: lengthRuleData, error: lengthRuleError } = await db
			.from('arquitecturas_reglas_longitud')
			.select(
				'arquitectura_id,arquitectura_nombre,modulo_versos,residuo_versos,minimo_versos,origen,explicacion,desplazamientos'
			)
			.eq('arquitectura_id', input.arquitectura_id)
			.maybeSingle();
		if (lengthRuleError) {
			return databaseError(
				lengthRuleError,
				'No se pudo comprobar la longitud de la secuencia.'
			);
		}
		// **La congruencia no aplica cuando alguna unidad declara su propia arquitectura.** Una
		// tirada de décimas con una aumentada mide `10n + 2` y no cabe en ninguna división exacta,
		// y es lo que las fuentes documentan. Ahí gobierna la cobertura del rango, no el módulo.
		const conArquitecturasPropias = (input.unidades ?? []).some(
			(unidad) => Boolean(unidad.arquitectura_id) && unidad.realizacion_padre_id === null
		);
		const lengthError = metricLengthError(
			(lengthRuleData as MetricLengthRule | null) ?? null,
			rangeStart,
			rangeEnd,
			lengthRuleData?.arquitectura_nombre,
			undefined,
			conArquitecturasPropias
		);
		if (lengthError) {
			return json({ error: 'validation_error', message: lengthError }, { status: 422 });
		}
	}
	for (const unit of input.unidades) {
		if (unit.v_fin < unit.v_ini || unit.v_ini < rangeStart || unit.v_fin > rangeEnd) {
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
			deviation.v_ini < rangeStart ||
			deviation.v_fin > rangeEnd
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

	const { data, error } = await db.rpc('guardar_anotacion_metrica', {
		p_datos: { ...input, v_ini: rangeStart, v_fin: rangeEnd }
	});
	if (error) return databaseError(error, 'No se pudo guardar la secuencia métrica de prueba.');
	return json({ anotacion_id: data });
};
