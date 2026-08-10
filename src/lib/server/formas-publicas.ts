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
	PublicRepetition,
	PublicRhymeRestriction,
	PublicRhymeScheme,
	PublicSchemePart,
	PublicSection,
	PublicSource
} from '$lib/metrica/formas-publicas.types';
import type { MetricStructuralLevel } from '$lib/metrica/catalogo';

/** Ordena por nombre entendiendo los números: «Tipología 2» antes que «Tipología 10». */
const porNombre = (a: { nombre: string }, b: { nombre: string }) =>
	a.nombre.localeCompare(b.nombre, 'es', { numeric: true });

type UntypedSupabaseClient = {
	from: (table: string) => any;
	rpc: (fn: string, args?: Record<string, unknown>) => any;
};
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

type RawPublicFormData = Record<string, any[]>;

async function cargarAgrupado(
	db: UntypedSupabaseClient,
	funcion: string,
	args?: Record<string, unknown>
): Promise<RawPublicFormData> {
	const { data, error } = await db.rpc(funcion, args);
	throwQueryError(`No se pudo cargar el catálogo de formas (${funcion})`, error);
	return (data ?? {}) as RawPublicFormData;
}

/** Índice: una línea por forma, con lo justo para buscarla y situarla. */
export async function loadPublicForms(client: unknown): Promise<PublicFormSummary[]> {
	const db = client as UntypedSupabaseClient;
	const { formas, arquitecturas, tiposRima, denominaciones, tradiciones, formasTradiciones } =
		await cargarAgrupado(db, 'get_catalogo_formas_publicas');

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
		nivelEstructural: String(forma.nivel_estructural) as MetricStructuralLevel,
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
		posicionesRima,
		secciones,
		gruposEleccion,
		opcionesEleccion,
		variedades,
		arquitecturaRasgos,
		rasgos,
		valores,
		tiposRima,
		denominaciones,
		tradiciones,
		formasTradiciones,
		afirmaciones,
		fuentes,
		relaciones,
		repeticiones,
		restriccionesRima
	} = await cargarAgrupado(db, 'get_forma_metrica_publica_jerarquica', { p_slug: slug });

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
	const datosFuente = new Map(
		(fuentes as any[]).map((row) => [
			String(row.fuente_id),
			{
				cita:
					texto(row.cita) ??
					[texto(row.autoria), texto(row.titulo), texto(row.anio)].filter(Boolean).join(', '),
				anio: typeof row.anio === 'number' ? row.anio : null
			}
		])
	);

	const porArquitectura = <T extends { arquitectura_id?: unknown }>(rows: T[]) =>
		agrupar(rows, (row) => (row.arquitectura_id ? String(row.arquitectura_id) : null));

	const enlacesPorEsquema = agrupar(enlacesRima as any[], (row) =>
		String(row.esquema_rima_id)
	);
	const posicionesPorEsquema = agrupar(posicionesRima as any[], (row) =>
		String(row.esquema_rima_id)
	);
	const restriccionesPorEsquema = agrupar((restriccionesRima ?? []) as any[], (row) =>
		String(row.esquema_rima_id)
	);
	/** El nombre con que un esquema se cita desde otro, para las exclusiones. */
	const nombreDeEsquema = new Map(
		(esquemasRima as any[]).map((e) => [
			String(e.esquema_rima_id),
			texto(e.nombre) ?? texto(e.notacion) ?? 'otro esquema'
		])
	);

	/**
	 * Una restricción, redactada. La norma de un esquema abierto no se puede enseñar como una
	 * notación, porque justamente lo que declara es que no hay una: se lee en palabras.
	 */
	const restriccionesDe = (esquemaRimaId: string): PublicRhymeRestriction[] =>
		(restriccionesPorEsquema.get(esquemaRimaId) ?? []).map((r) => {
			const cifra = numero(r.valor_numero);
			const valor = texto(r.valor_texto);
			const referido = r.esquema_referido_id
				? (nombreDeEsquema.get(String(r.esquema_referido_id)) ?? 'otro esquema')
				: null;
			const redactada: Record<string, string> = {
				numero_clases: `Emplea ${cifra ?? '—'} clases de rima`,
				max_consecutivos: `No más de ${cifra ?? '—'} versos seguidos con la misma rima`,
				min_alternancias: `La rima cambia de clase al menos ${cifra ?? '—'} veces`,
				prohibe_pareado_final: 'No termina en pareado',
				// El valor lo dice todo, así que se redacta aquí en vez de describirse una a una:
				// las tres de la silva decían lo mismo con tres redacciones distintas.
				versos_sueltos:
					{
						ninguno: 'Ningún verso queda suelto',
						todos: 'Todos los versos quedan sueltos',
						predominantes: 'Predominan los versos sueltos sobre los rimados',
						admitidos: 'Admite versos sueltos intercalados'
					}[String(valor)] ?? `Versos sueltos: ${valor ?? '—'}`,
				identidad_entre_repeticiones: 'La disposición, sea cual sea, vuelve idéntica en cada repetición',
				regularidad: 'La disposición debe ser regular, aunque la norma no fije cuál',
				excluye_esquema: `No puede coincidir con «${referido}»`
			};
			// La descripción manda cuando la hay: está escrita para esa forma y dice más.
			return {
				texto: texto(r.descripcion) ?? redactada[String(r.tipo)] ?? String(r.tipo)
			};
		});

	/**
	 * Las partes con nombre de un esquema, con el verso donde empieza y acaba cada una. Las
	 * posiciones vienen ordenadas por bloque y posición, así que el verso es su orden de
	 * lectura: la doble enlazada tiene dos bloques de cuatro y sus versos van del 1 al 8.
	 */
	const partesDe = (esquemaRimaId: string): PublicSchemePart[] => {
		const partes: PublicSchemePart[] = [];
		(posicionesPorEsquema.get(esquemaRimaId) ?? []).forEach((row, indice) => {
			const nombre = String(row.seccion);
			const ultima = partes.at(-1);
			if (ultima?.nombre === nombre) {
				ultima.hasta = indice + 1;
				ultima.nota ??= texto(row.nota);
			} else {
				partes.push({ nombre, desde: indice + 1, hasta: indice + 1, nota: texto(row.nota) });
			}
		});
		return partes;
	};
	/**
	 * Toda la rima de una arquitectura, repartida por la parte de la que es y en el orden en
	 * que esas partes se leen. Una sección aporta las disposiciones que admite; lo que quede
	 * sin parte es de la unidad entera y va al final.
	 */
	const rimaAgrupadaPorParte = (arquitecturaId: string): PublicRhymeScheme[] => {
		const misSecciones = seccionesPor.get(arquitecturaId) ?? [];
		const vistosEnSecciones = new Set<string>();
		const deSecciones = misSecciones.flatMap((s) =>
			rimaDeSeccion(s.seccion_id, String(s.nombre)).filter((esquema) => {
				// Dos secciones distintas pueden llamarse «Mudanza» y apuntar al mismo repertorio.
				// En la ficha se explica una sola vez bajo ese nombre, sin duplicar claves ni contenido.
				const clave = `${String(s.nombre)}:${esquema.id}`;
				if (vistosEnSecciones.has(clave)) return false;
				vistosEnSecciones.add(clave);
				return true;
			})
		);
		const yaPuestos = new Set(deSecciones.map((e) => e.id));

		// Los que cuelgan de la arquitectura pero señalan una sección pertenecen a esa parte,
		// aunque su grupo de elección no esté atado a ella: es el caso de los tercetos del soneto,
		// cuyo esquema entrelaza los dos y no cabe en una sección de tres versos.
		const nombreDeSeccion = new Map(
			misSecciones.map((s) => [String(s.seccion_id), String(s.nombre)])
		);

		const deLaUnidad = rimaDe(arquitecturaId)
			.filter((e) => !yaPuestos.has(e.id))
			.map((e) => {
				const parte = e.seccionId ? nombreDeSeccion.get(e.seccionId) : undefined;
				return parte ? { ...e, deLaSeccion: parte } : e;
			});

		const conParte = deLaUnidad.filter((e) => e.deLaSeccion);
		const sinParte = deLaUnidad.filter((e) => !e.deLaSeccion);
		const orden = new Map(misSecciones.map((s, i) => [String(s.nombre), i]));
		return [...deSecciones, ...conParte]
			.sort(
				(a, b) =>
					(orden.get(a.deLaSeccion ?? '') ?? 0) - (orden.get(b.deLaSeccion ?? '') ?? 0)
			)
			.concat(sinParte);
	};

	const metricosPor = porArquitectura(esquemasMetricos as any[]);
	const rimaPor = porArquitectura(esquemasRima as any[]);
	const seccionesPor = porArquitectura(secciones as any[]);
	const variedadesPor = porArquitectura(variedades as any[]);
	const rasgosPor = porArquitectura(arquitecturaRasgos as any[]);
	const repeticionesPor = porArquitectura(repeticiones as any[]);
	const denominacionesPorArquitectura = porArquitectura(
		(denominaciones as any[]).filter((row) => row.arquitectura_id)
	);
	// Un nombre puede colgar de un esquema de rima y no de la forma: «cuarteta» nombra la
	// redondilla cruzada, no la redondilla. `denominaciones_metricas` admite ese destino.
	const denominacionesPorRima = agrupar(
		(denominaciones as any[]).filter((row) => row.esquema_rima_id),
		(row) => (row.esquema_rima_id ? String(row.esquema_rima_id) : null)
	);

	/**
	 * Los nombres de un esquema de rima, con el preferente delante.
	 *
	 * El orden importa porque el primero puede acabar siendo **el nombre del esquema**: muchas
	 * disposiciones no tienen `nombre` propio —se identifican por su notación— y el nombre que
	 * les dio la tradición vive como denominación. Al dejar de ser formas hijas, ahí acabaron:
	 * «Sexta rima» nombra hoy el esquema `ABABCC` del sexteto, y «Cuarteta», el cruzado de la
	 * redondilla.
	 */
	const nombresDeRima = (esquemaRimaId: string): string[] =>
		(denominacionesPorRima.get(esquemaRimaId) ?? [])
			.slice()
			.sort((a, b) => Number(Boolean(b.preferente)) - Number(Boolean(a.preferente)))
			.map((d) => String(d.nombre));

	/** Los esquemas de rima de una arquitectura, ordenados por nombre porque la tabla no ordena. */
	const mapearRima = (e: any): PublicRhymeScheme => {
		const nombres = nombresDeRima(String(e.esquema_rima_id));
		// Un esquema sin nombre propio se presenta con el que la tradición le dio, y entonces
		// ese nombre no se repite en la lista de los demás.
		const propio = texto(e.nombre);
		return {
			id: String(e.esquema_rima_id),
			nombre: propio ?? nombres[0] ?? '—',
			notacion: texto(e.notacion),
			descripcion: texto(e.descripcion),
			// El ciclo lo marca la notación: es la única declaración que hay.
			cicla: String(e.notacion ?? '').includes(']…'),
			enlaces: (enlacesPorEsquema.get(String(e.esquema_rima_id)) ?? []).map((l) => ({
				desde: Number(l.posicion_origen),
				hasta: Number(l.posicion_destino),
				desplazamiento: Number(l.desplazamiento_bloque),
				nota: texto(l.nota)
			})),
			denominaciones: propio ? nombres : nombres.slice(1),
			partes: partesDe(String(e.esquema_rima_id)),
			restricciones: restriccionesDe(String(e.esquema_rima_id)),
			deLaSeccion: null,
			seccionId: e.seccion_id ? String(e.seccion_id) : null
		};
	};

	/** Todos los esquemas, indexados por id, para resolverlos desde una opción de elección. */
	const esquemaRimaPorId = new Map(
		(esquemasRima as any[]).map((e) => [String(e.esquema_rima_id), mapearRima(e)])
	);

	/** Los esquemas de rima de una arquitectura, ordenados por nombre: la tabla no ordena. */
	const rimaDe = (arquitecturaId: string): PublicRhymeScheme[] =>
		(rimaPor.get(arquitecturaId) ?? []).map(mapearRima).sort(porNombre);

	/**
	 * Las disposiciones de rima que admite una sección, según su grupo de elección.
	 *
	 * Una sección que reutiliza otra forma no tiene rima propia: la del cuarteto del soneto
	 * vive en la arquitectura del cuarteto endecasílabo. Se resuelve por el grupo y no por la
	 * arquitectura referenciada porque el grupo es el recorte exacto —el terceto admite `-AA`,
	 * que en un soneto no existe—.
	 */
	const opcionesPorGrupo = agrupar(opcionesEleccion as any[], (row) =>
		String(row.grupo_eleccion_id)
	);
	// La sección puede venir por dos caminos: `seccion_id` cuando la pregunta se hace en cada
	// realización, y `seccion_tratada_id` cuando se hace una sola vez para todas —los cuartetos
	// del soneto comparten sus rimas, así que se eligen de una vez—. Para leer la ficha son lo
	// mismo: la parte de la que habla ese esquema.
	const gruposPorSeccion = agrupar(
		(gruposEleccion as any[]).filter(
			(row) => (row.seccion_id || row.seccion_tratada_id) && row.dimension === 'rima'
		),
		(row) => String(row.seccion_id ?? row.seccion_tratada_id)
	);
	const rimaDeSeccion = (seccionId: unknown, nombreSeccion?: string): PublicRhymeScheme[] => {
		if (!seccionId) return [];
		// El nombre lo pone la **opción**, no el esquema: el mismo `ABBA` se llama «Abrazada»
		// en el cuarteto, que es su dueño, y «ABBA ABBA» en el soneto, que lo repite dos veces.
		// Desde una forma se lee el nombre que esa forma le da.
		const opciones = (gruposPorSeccion.get(String(seccionId)) ?? []).flatMap((g) =>
			(opcionesPorGrupo.get(String(g.grupo_eleccion_id)) ?? []).filter((o) => o.esquema_rima_id)
		);
		const vistos = new Set<string>();
		const esquemas = opciones.flatMap((o) => {
			const id = String(o.esquema_rima_id);
			if (vistos.has(id)) return [];
			vistos.add(id);
			const esquema = esquemaRimaPorId.get(id);
			// La etiqueta de la opción ya trae la repetición escrita —«ABBA ABBA» frente al
			// «ABBA» del esquema—, así que sirve de notación desde esta forma. El nombre propio
			// del esquema pasa a ser la glosa.
			const etiqueta = texto(o.nombre);
			return esquema
				? [
						{
							...esquema,
							notacion: etiqueta ?? esquema.notacion,
							nombre: esquema.nombre
						}
					]
				: [];
		});
		// Las opciones de un mismo grupo son excluyentes —el cuarteto del soneto es abrazado o
		// cruzado, nunca las dos cosas—, y agruparlas bajo el nombre de su parte ya lo dice.
		return esquemas.map((e) => ({ ...e, deLaSeccion: nombreSeccion ?? null }));
	};

	/** Reconstruye el árbol porque `orden` solo ordena hermanos, no todas las filas juntas. */
	const seccionesDe = (arquitecturaId: string): PublicSection[] => {
		const filas = seccionesPor.get(arquitecturaId) ?? [];
		const ordenPorId = new Map<string, number>();
		const nodos = new Map<string, PublicSection>();

		for (const s of filas) {
			const id = String(s.seccion_id);
			ordenPorId.set(id, Number(s.orden ?? 0));
			nodos.set(id, {
				id,
				nombre: String(s.nombre),
				nota: texto(s.nota),
				versosMin: numero(s.versos_min),
				versosMax: numero(s.versos_max),
				repeticionesMin: numero(s.repeticiones_min),
				repeticionesMax: numero(s.repeticiones_max),
				reutiliza: s.arquitectura_referenciada_id
					? (nombreArquitectura.get(String(s.arquitectura_referenciada_id)) ?? null)
					: null,
				esquemasRima: rimaDeSeccion(s.seccion_id, String(s.nombre)),
				hijas: []
			});
		}

		const raices: PublicSection[] = [];
		for (const s of filas) {
			const nodo = nodos.get(String(s.seccion_id));
			if (!nodo) continue;
			const padre = s.seccion_padre_id ? nodos.get(String(s.seccion_padre_id)) : null;
			if (padre) padre.hijas.push(nodo);
			else raices.push(nodo);
		}

		const ordenar = (lista: PublicSection[]): PublicSection[] =>
			lista
				.sort(
					(a, b) =>
						(ordenPorId.get(a.id) ?? 0) - (ordenPorId.get(b.id) ?? 0) || porNombre(a, b)
				)
				.map((seccion) => ({ ...seccion, hijas: ordenar(seccion.hijas) }));

		return ordenar(raices);
	};


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
				// Bajo «Rima» va toda la de la forma: la que declara la unidad y la que declaran
				// sus secciones. Repartirlas entre «Rima» y «Partes» partía en dos sitios lo que
				// el lector busca junto —los tercetos del soneto arriba y sus cuartetos abajo—.
				// Toda la rima de la forma, agrupada por la parte de la que es y en el orden en
				// que se leen las partes: los cuartetos del soneto antes que sus tercetos.
				//
				// Los tercetos llegan por otro camino que los cuartetos. Su grupo de elección no
				// está atado a la sección —su esquema entrelaza los dos tercetos y no cabe en una
				// sección de tres versos—, así que cuelgan de la arquitectura. Pero señalan su
				// sección, y eso los coloca bajo su parte en vez de dejarlos sueltos.
				esquemasRima: rimaAgrupadaPorParte(id),
				// El árbol conserva contenedores y ordena cada grupo de hermanos por separado.
				secciones: seccionesDe(id),
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
				repeticiones: (repeticionesPor.get(id) ?? []).map(
					(r): PublicRepetition => ({
						slug: String(r.slug),
						tipo: String(r.tipo),
						regla: String(r.regla),
						modalidad: texto(r.modalidad),
						descripcion: texto(r.descripcion)
					})
				),
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

	// Agrupadas bajo su fuente y las fuentes por año: el orden cronológico es el único que no
	// insinúa una jerarquía entre monografías que el catálogo no quiere establecer.
	const misFuentes: PublicSource[] = [
		...(afirmaciones as any[])
			.filter(
				(row) =>
					String(row.forma_id ?? '') === formaId ||
					(row.arquitectura_id && arquitecturaDeId.has(String(row.arquitectura_id)))
			)
			.reduce((acc, row) => {
				const id = String(row.fuente_id);
				const datos = datosFuente.get(id);
				const fuente = acc.get(id) ?? {
					cita: datos?.cita ?? 'Fuente sin referencia',
					anio: datos?.anio ?? null,
					afirmaciones: []
				};
				fuente.afirmaciones.push({
					resumen: texto(row.resumen),
					localizador: texto(row.localizador),
					confianza: texto(row.confianza),
					sobre: row.arquitectura_id
						? (arquitecturaDeId.get(String(row.arquitectura_id)) ?? String(forma.nombre))
						: String(forma.nombre)
				});
				acc.set(id, fuente);
				return acc;
			}, new Map<string, PublicSource>())
			.values()
	].sort((a, b) => (a.anio ?? 0) - (b.anio ?? 0));

	const misDenominaciones = (denominaciones as any[])
		.filter((row) => String(row.forma_id ?? '') === formaId)
		.map((row) => String(row.nombre));

	return {
		slug: String(forma.slug),
		nombre: String(forma.nombre),
		definicion: texto(forma.definicion),
		tipoRegistro: String(forma.tipo_registro),
		nivelEstructural: String(forma.nivel_estructural) as MetricStructuralLevel,
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
		denominaciones: misDenominaciones,
		// Las relaciones se declaran en una dirección, pero interesan en las dos: el terceto
		// encadenado dice que se construye con tercetos, y esa frase es tan útil leída desde el
		// terceto como desde la serie.
		relaciones: (relaciones as any[])
			.filter(
				(row) =>
					String(row.forma_origen_id) === formaId || String(row.forma_destino_id) === formaId
			)
			.map((row) => {
				const esOrigen = String(row.forma_origen_id) === formaId;
				const otra = (formas as any[]).find(
					(f) =>
						String(f.forma_id) === String(esOrigen ? row.forma_destino_id : row.forma_origen_id)
				);
				return {
					nombre: String(otra?.nombre ?? '—'),
					slug: String(otra?.slug ?? ''),
					nivelEstructural: String(otra?.nivel_estructural) as MetricStructuralLevel,
					tipo: String(row.tipo_relacion),
					nota: texto(row.nota),
					esOrigen
				};
			})
			.filter((r) => r.slug)
			.sort(porNombre),
		arquitecturas_: misArquitecturas,
		fuentes: misFuentes
	};
}
