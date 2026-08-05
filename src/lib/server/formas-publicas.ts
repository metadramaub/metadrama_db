/**
 * Catálogo público de formas métricas.
 *
 * Lee el catálogo y lo convierte en fichas legibles. **No hay contenido escrito aquí**: todo
 * lo que se enseña sale del dato —definiciones, descripciones, notas y afirmaciones con
 * fuente—, de modo que la página no puede quedarse vieja ni contradecir al catálogo.
 *
 * Si algo se lee mal en la web, se arregla en el catálogo, no aquí.
 */

import type {
	PublicArchitecture,
	PublicFormDetail,
	PublicFormSummary,
	PublicRhymeScheme,
	PublicSourceClaim
} from '$lib/metrica/formas-publicas.types';

/** Ordena por nombre entendiendo los números: «Tipología 2» antes que «Tipología 10». */
const porNombre = (a: { nombre: string }, b: { nombre: string }) =>
	a.nombre.localeCompare(b.nombre, 'es', { numeric: true });

type UntypedSupabaseClient = { from: (table: string) => any };
type QueryError = { code?: string; message: string } | null;

function throwQueryError(context: string, error: QueryError): void {
	if (!error) return;
	throw new Error(`${context}: ${error.message}`);
}

const texto = (value: unknown): string | null => {
	const limpio = typeof value === 'string' ? value.trim() : value == null ? '' : String(value);
	return limpio || null;
};
const numero = (value: unknown): number | null =>
	value === null || value === undefined ? null : Number(value);

/** Agrupa filas por una clave, conservando el orden de llegada. */
function agrupar<T>(rows: T[], clave: (row: T) => string | null): Map<string, T[]> {
	const grupos = new Map<string, T[]>();
	for (const row of rows) {
		const key = clave(row);
		if (!key) continue;
		const lista = grupos.get(key) ?? [];
		lista.push(row);
		grupos.set(key, lista);
	}
	return grupos;
}

async function cargarTodo(db: UntypedSupabaseClient) {
	const consultas = {
		formas: db
			.from('formas_metricas')
			.select(
				'forma_id,slug,nombre,definicion,tipo_registro,nivel_estructural,grado_especificacion,orden'
			)
			.eq('activo', true)
			.order('nombre'),
		arquitecturas: db
			.from('arquitecturas_forma')
			.select(
				'arquitectura_id,forma_id,slug,nombre,descripcion,principal,modalidad,unidad_versos_min,unidad_versos_max,tipo_rima_id,orden'
			)
			.eq('activo', true)
			.order('orden'),
		esquemasMetricos: db.from('esquemas_metricos').select('arquitectura_id,nombre,descripcion'),
		esquemasRima: db
			.from('esquemas_rima')
			.select('esquema_rima_id,arquitectura_id,nombre,notacion,descripcion'),
		enlacesRima: db
			.from('esquema_rima_enlaces')
			.select('esquema_rima_id,posicion_origen,posicion_destino,desplazamiento_bloque,nota'),
		secciones: db
			.from('estructuras_secciones')
			.select(
				'arquitectura_id,nombre,nota,versos_min,versos_max,repeticiones_min,repeticiones_max,arquitectura_referenciada_id,orden'
			)
			.order('orden'),
		variedades: db
			.from('variedades_arquitectura')
			.select('arquitectura_id,nombre,descripcion,orden')
			.eq('activo', true)
			.order('orden'),
		arquitecturaRasgos: db
			.from('arquitectura_rasgos')
			.select('arquitectura_id,rasgo_id,valor_id,modalidad,nota'),
		rasgos: db.from('rasgos_metricos').select('rasgo_id,nombre'),
		valores: db.from('rasgo_valores').select('valor_id,nombre'),
		tiposRima: db
			.from('vocabularios')
			.select('termino_id,termino,etiqueta')
			.eq('categoria', 'tipo_rima'),
		denominaciones: db
			.from('denominaciones_metricas')
			.select('forma_id,arquitectura_id,nombre,tipo_alias,preferente'),
		tradiciones: db.from('tradiciones_metricas').select('tradicion_id,nombre'),
		formasTradiciones: db.from('formas_tradiciones').select('forma_id,tradicion_id'),
		afirmaciones: db
			.from('afirmaciones_fuentes_metricas')
			.select('fuente_id,forma_id,arquitectura_id,localizador,resumen,confianza'),
		fuentes: db.from('fuentes_metricas').select('fuente_id,cita,autoria,titulo,anio')
	};

	const claves = Object.keys(consultas) as (keyof typeof consultas)[];
	const respuestas = await Promise.all(claves.map((clave) => consultas[clave]));

	const datos = {} as Record<keyof typeof consultas, any[]>;
	claves.forEach((clave, indice) => {
		throwQueryError(`No se pudo cargar el catálogo de formas (${clave})`, respuestas[indice].error);
		datos[clave] = respuestas[indice].data ?? [];
	});
	return datos;
}

/** Índice: una línea por forma, con lo justo para buscarla y situarla. */
export async function loadPublicForms(client: unknown): Promise<PublicFormSummary[]> {
	const db = client as UntypedSupabaseClient;
	const { formas, arquitecturas, tiposRima, denominaciones, tradiciones, formasTradiciones } =
		await cargarTodo(db);

	const nombreTipoRima = new Map(
		(tiposRima as any[]).map((row) => [
			String(row.termino_id),
			String(row.etiqueta ?? row.termino)
		])
	);

	const nombreTradicion = new Map(
		(tradiciones as any[]).map((row) => [String(row.tradicion_id), String(row.nombre)])
	);
	const arquitecturasPorForma = agrupar(arquitecturas as any[], (row) => String(row.forma_id));
	const denominacionesPorForma = agrupar(
		(denominaciones as any[]).filter((row) => row.forma_id),
		(row) => String(row.forma_id)
	);
	const tradicionesPorForma = agrupar(formasTradiciones as any[], (row) => String(row.forma_id));

	return (formas as any[]).map((forma) => ({
		slug: String(forma.slug),
		nombre: String(forma.nombre),
		definicion: texto(forma.definicion),
		tipoRegistro: String(forma.tipo_registro),
		nivelEstructural: String(forma.nivel_estructural),
		gradoEspecificacion: texto(forma.grado_especificacion),
		arquitecturas: (arquitecturasPorForma.get(String(forma.forma_id)) ?? []).length,
		tradiciones: (tradicionesPorForma.get(String(forma.forma_id)) ?? [])
			.map((row) => nombreTradicion.get(String(row.tradicion_id)))
			.filter((nombre): nombre is string => Boolean(nombre)),
		// Una forma puede admitir varios regímenes: la seguidilla asona y el pareado hace las dos.
		tiposRima: [
			...new Set(
				(arquitecturasPorForma.get(String(forma.forma_id)) ?? [])
					.map((row) => (row.tipo_rima_id ? nombreTipoRima.get(String(row.tipo_rima_id)) : null))
					.filter((nombre): nombre is string => Boolean(nombre))
			)
		],
		denominaciones: (denominacionesPorForma.get(String(forma.forma_id)) ?? []).map((row) =>
			String(row.nombre)
		)
	}));
}

/** Ficha completa de una forma. Devuelve null si no existe o está retirada. */
export async function loadPublicForm(
	client: unknown,
	slug: string
): Promise<PublicFormDetail | null> {
	const db = client as UntypedSupabaseClient;
	const {
		formas,
		arquitecturas,
		esquemasMetricos,
		esquemasRima,
		enlacesRima,
		secciones,
		variedades,
		arquitecturaRasgos,
		rasgos,
		valores,
		tiposRima,
		denominaciones,
		tradiciones,
		formasTradiciones,
		afirmaciones,
		fuentes
	} = await cargarTodo(db);

	const forma = (formas as any[]).find((row) => String(row.slug) === slug);
	if (!forma) return null;
	const formaId = String(forma.forma_id);

	const nombreArquitectura = new Map(
		(arquitecturas as any[]).map((row) => [String(row.arquitectura_id), String(row.nombre)])
	);
	const nombreRasgo = new Map(
		(rasgos as any[]).map((row) => [String(row.rasgo_id), String(row.nombre)])
	);
	const nombreValor = new Map(
		(valores as any[]).map((row) => [String(row.valor_id), String(row.nombre)])
	);
	const nombreTradicion = new Map(
		(tradiciones as any[]).map((row) => [String(row.tradicion_id), String(row.nombre)])
	);
	const nombreTipoRima = new Map(
		(tiposRima as any[]).map((row) => [String(row.termino_id), String(row.etiqueta ?? row.termino)])
	);
	const citaFuente = new Map(
		(fuentes as any[]).map((row) => [
			String(row.fuente_id),
			texto(row.cita) ??
				[texto(row.autoria), texto(row.titulo), texto(row.anio)].filter(Boolean).join(', ')
		])
	);

	const porArquitectura = <T extends { arquitectura_id?: unknown }>(rows: T[]) =>
		agrupar(rows, (row) => (row.arquitectura_id ? String(row.arquitectura_id) : null));

	const enlacesPorEsquema = agrupar(enlacesRima as any[], (row) =>
		String(row.esquema_rima_id)
	);
	const metricosPor = porArquitectura(esquemasMetricos as any[]);
	const rimaPor = porArquitectura(esquemasRima as any[]);
	const seccionesPor = porArquitectura(secciones as any[]);
	const variedadesPor = porArquitectura(variedades as any[]);
	const rasgosPor = porArquitectura(arquitecturaRasgos as any[]);
	const denominacionesPorArquitectura = porArquitectura(
		(denominaciones as any[]).filter((row) => row.arquitectura_id)
	);

	const misArquitecturas: PublicArchitecture[] = (arquitecturas as any[])
		.filter((row) => String(row.forma_id) === formaId)
		.map((row) => {
			const id = String(row.arquitectura_id);
			return {
				slug: String(row.slug),
				nombre: String(row.nombre),
				descripcion: texto(row.descripcion),
				principal: row.principal === true,
				modalidad: texto(row.modalidad),
				unidadMin: numero(row.unidad_versos_min),
				unidadMax: numero(row.unidad_versos_max),
				esquemasMetricos: (metricosPor.get(id) ?? [])
					.map((e) => ({
						nombre: String(e.nombre ?? '—'),
						notacion: null,
						descripcion: texto(e.descripcion)
					}))
					.sort(porNombre),
				// `esquemas_rima` no tiene columna de orden, así que se ordena por nombre.
				esquemasRima: (rimaPor.get(id) ?? [])
					.map(
						(e): PublicRhymeScheme => ({
							nombre: String(e.nombre ?? '—'),
							notacion: texto(e.notacion),
							descripcion: texto(e.descripcion),
							// El ciclo lo marca la notación: es la única declaración que hay.
							cicla: String(e.notacion ?? '').includes(']…'),
							enlaces: (enlacesPorEsquema.get(String(e.esquema_rima_id)) ?? []).map((l) => ({
								desde: Number(l.posicion_origen),
								hasta: Number(l.posicion_destino),
								desplazamiento: Number(l.desplazamiento_bloque),
								nota: texto(l.nota)
							}))
						})
					)
					.sort(porNombre),
				secciones: (seccionesPor.get(id) ?? []).map((s) => ({
					nombre: String(s.nombre),
					nota: texto(s.nota),
					versosMin: numero(s.versos_min),
					versosMax: numero(s.versos_max),
					repeticionesMin: numero(s.repeticiones_min),
					repeticionesMax: numero(s.repeticiones_max),
					reutiliza: s.arquitectura_referenciada_id
						? (nombreArquitectura.get(String(s.arquitectura_referenciada_id)) ?? null)
						: null
				})),
				variedades: (variedadesPor.get(id) ?? []).map((v) => ({
					nombre: String(v.nombre),
					notacion: null,
					descripcion: texto(v.descripcion)
				})),
				rasgos: (rasgosPor.get(id) ?? []).map((r) => ({
					nombre: nombreRasgo.get(String(r.rasgo_id)) ?? '—',
					valor: r.valor_id ? (nombreValor.get(String(r.valor_id)) ?? null) : null,
					modalidad: texto(r.modalidad),
					nota: texto(r.nota)
				})),
				denominaciones: (denominacionesPorArquitectura.get(id) ?? []).map((d) =>
					String(d.nombre)
				)
			};
		});

	const arquitecturaDeId = new Map(
		(arquitecturas as any[])
			.filter((row) => String(row.forma_id) === formaId)
			.map((row) => [String(row.arquitectura_id), String(row.nombre)])
	);

	const misFuentes: PublicSourceClaim[] = (afirmaciones as any[])
		.filter(
			(row) =>
				String(row.forma_id ?? '') === formaId ||
				(row.arquitectura_id && arquitecturaDeId.has(String(row.arquitectura_id)))
		)
		.map((row) => ({
			cita: citaFuente.get(String(row.fuente_id)) ?? 'Fuente sin referencia',
			resumen: texto(row.resumen),
			localizador: texto(row.localizador),
			confianza: texto(row.confianza),
			sobre: row.arquitectura_id
				? (arquitecturaDeId.get(String(row.arquitectura_id)) ?? String(forma.nombre))
				: String(forma.nombre)
		}));

	const misDenominaciones = (denominaciones as any[])
		.filter((row) => String(row.forma_id ?? '') === formaId)
		.map((row) => ({ nombre: String(row.nombre), tipo: String(row.tipo_alias ?? 'equivalente') }));

	return {
		slug: String(forma.slug),
		nombre: String(forma.nombre),
		definicion: texto(forma.definicion),
		tipoRegistro: String(forma.tipo_registro),
		nivelEstructural: String(forma.nivel_estructural),
		gradoEspecificacion: texto(forma.grado_especificacion),
		arquitecturas: misArquitecturas.length,
		tradiciones: (formasTradiciones as any[])
			.filter((row) => String(row.forma_id) === formaId)
			.map((row) => nombreTradicion.get(String(row.tradicion_id)))
			.filter((nombre): nombre is string => Boolean(nombre)),
		tiposRima: [
			...new Set(
				(arquitecturas as any[])
					.filter((row) => String(row.forma_id) === formaId)
					.map((row) => (row.tipo_rima_id ? nombreTipoRima.get(String(row.tipo_rima_id)) : null))
					.filter((nombre): nombre is string => Boolean(nombre))
			)
		],
		denominaciones: misDenominaciones.map((d) => d.nombre),
		denominacionesDetalle: misDenominaciones,
		arquitecturas_: misArquitecturas,
		fuentes: misFuentes
	};
}
