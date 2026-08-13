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
	PublicMetricScheme,
	PublicRepetition,
	PublicRhymeRestriction,
	PublicRhymeScheme,
	PublicSchemePart,
	PublicSection,
	PublicSource,
	PublicTrait,
	PublicTraits,
	PublicVariety
} from '$lib/metrica/formas-publicas.types';
import type { MetricStructuralLevel } from '$lib/metrica/catalogo';
import {
	construirRejilla,
	perfilDeArquitectura,
	type EsquemaMetricoEntrada,
	type EsquemaRimaEntrada,
	type EntradaRejilla,
	type SeccionEntrada
} from '$lib/metrica/rejilla';

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
		(tiposRima as any[]).map((row) => [String(row.termino_id), String(row.etiqueta ?? row.termino)])
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
		posicionesMetricas,
		opcionesMetricas,
		esquemasRima,
		enlacesRima,
		posicionesRima,
		posicionesRimaCompletas,
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
		restriccionesRima,
		formasReferenciadas,
		arquitecturasReutilizadas
	} = await cargarAgrupado(db, 'get_forma_metrica_publica_jerarquica', { p_slug: slug });

	const forma = (formas as any[]).find((row) => String(row.slug) === slug);
	if (!forma) return null;
	const formaId = String(forma.forma_id);

	const nombreArquitectura = new Map(
		(arquitecturas as any[]).map((row) => [String(row.arquitectura_id), String(row.nombre)])
	);
	/**
	 * A qué forma lleva una parte que reutiliza otra arquitectura. Se enseña el nombre de la
	 * forma —«Cuarteto endecasílabo» es una realización suya— y se enlaza su ficha.
	 */
	const formaDeArquitectura = new Map(
		((formasReferenciadas ?? []) as any[]).map((row) => [
			String(row.arquitectura_id),
			{ nombre: String(row.forma_nombre), slug: texto(row.forma_slug) }
		])
	);
	const reutilizacionDe = (
		arquitecturaReferenciadaId: unknown
	): { nombre: string; slug: string | null } | null => {
		if (!arquitecturaReferenciadaId) return null;
		const id = String(arquitecturaReferenciadaId);
		const forma = formaDeArquitectura.get(id);
		if (forma) return forma;
		const nombre = nombreArquitectura.get(id);
		return nombre ? { nombre, slug: null } : null;
	};
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

	const enlacesPorEsquema = agrupar(enlacesRima as any[], (row) => String(row.esquema_rima_id));
	// Las que llevan sección, para nombrar las partes de un esquema, y todas, para dibujarlas.
	const posicionesPorEsquema = agrupar(posicionesRima as any[], (row) =>
		String(row.esquema_rima_id)
	);
	const todasLasPosicionesPorEsquema = agrupar(
		(posicionesRimaCompletas ?? []) as any[],
		(row) => String(row.esquema_rima_id)
	);
	const posicionesMetricasPorEsquema = agrupar((posicionesMetricas ?? []) as any[], (row) =>
		String(row.esquema_metrico_id)
	);
	const opcionesMetricasPorEsquema = agrupar((opcionesMetricas ?? []) as any[], (row) =>
		String(row.esquema_metrico_id)
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
				identidad_entre_repeticiones:
					'La disposición, sea cual sea, vuelve idéntica en cada repetición',
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
		const todas = (todasLasPosicionesPorEsquema.get(esquemaRimaId) ?? []).length
			? (todasLasPosicionesPorEsquema.get(esquemaRimaId) ?? [])
			: (posicionesPorEsquema.get(esquemaRimaId) ?? []);
		todas.forEach((row, indice) => {
			const nombre = texto(row.seccion);
			if (!nombre) return;
			const ultima = partes.at(-1);
			// Dos bloques seguidos con el mismo nombre son dos partes, no una: `ABBA ABBA` son
			// los dos cuartetos del soneto, y fundirlos dejaba una sola parte de 1 a 8 que, por
			// ser única, no llegaba a enseñarse.
			if (ultima?.nombre === nombre && ultima.hasta === indice && ultima.bloque === Number(row.bloque)) {
				ultima.hasta = indice + 1;
				ultima.nota ??= texto(row.nota);
			} else {
				partes.push({
					nombre,
					bloque: Number(row.bloque ?? 1),
					desde: indice + 1,
					hasta: indice + 1,
					nota: texto(row.nota)
				});
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
			.sort((a, b) => (orden.get(a.deLaSeccion ?? '') ?? 0) - (orden.get(b.deLaSeccion ?? '') ?? 0))
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
			// Qué esperar de esta disposición: la quintilla tiene una habitual, cuatro admitidas
			// y tres excepcionales, y sin esto salían las ocho iguales.
			modalidad: texto(e.modalidad),
			tipoRima: e.tipo_rima_id ? (nombreTipoRima.get(String(e.tipo_rima_id)) ?? null) : null,
			abierto: (todasLasPosicionesPorEsquema.get(String(e.esquema_rima_id)) ?? []).length === 0,
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
			// La etiqueta de la opción **se deriva** desde el 11 de agosto de 2026: es
			// «nombre · notación» del propio esquema. Usarla como notación imprimía el nombre dos
			// veces —«Cuartetos de rima cruzada · ABAB ABAB» y debajo «Cuartetos de rima
			// cruzada»—. El esquema ya trae las dos cosas por separado.
			return esquemaRimaPorId.get(id) ? [esquemaRimaPorId.get(id)!] : [];
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
				reutiliza: reutilizacionDe(s.arquitectura_referenciada_id),
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
					(a, b) => (ordenPorId.get(a.id) ?? 0) - (ordenPorId.get(b.id) ?? 0) || porNombre(a, b)
				)
				.map((seccion) => ({ ...seccion, hijas: ordenar(seccion.hijas) }));

		return ordenar(raices);
	};

	/** El nombre de una sección, para saber a cuál se aplica un esquema métrico. */
	const nombreDeSeccionPorId = new Map(
		(secciones as any[]).map((s) => [String(s.seccion_id), String(s.nombre)])
	);

	/** Un esquema métrico tal como lo dibuja la rejilla: sus posiciones y su repertorio. */
	const metricoEntrada = (e: any): EsquemaMetricoEntrada => ({
		tipoSecuencia: texto(e.tipo_secuencia),
		medidaUniforme: e.medida_uniforme === null ? null : e.medida_uniforme === true,
		seccion: e.seccion_id ? (nombreDeSeccionPorId.get(String(e.seccion_id)) ?? null) : null,
		posiciones: (posicionesMetricasPorEsquema.get(String(e.esquema_metrico_id)) ?? []).map((p) => ({
			posicion: Number(p.posicion),
			silabas: p.silabas === null || p.silabas === undefined ? null : String(p.silabas),
			alternativa: numero(p.alternativa),
			opcional: p.opcional === true
		})),
		opciones: (opcionesMetricasPorEsquema.get(String(e.esquema_metrico_id)) ?? []).map((o) => ({
			silabas: o.silabas === null || o.silabas === undefined ? null : String(o.silabas),
			rol: texto(o.rol)
		}))
	});

	const rimaEntrada = (e: any, nombreSeccion: string | null): EsquemaRimaEntrada => ({
		id: String(e.esquema_rima_id),
		nombre: texto(e.nombre),
		notacion: texto(e.notacion),
		seccion: nombreSeccion,
		modalidad: texto(e.modalidad),
		posiciones: (todasLasPosicionesPorEsquema.get(String(e.esquema_rima_id)) ?? []).map((p) => ({
			bloque: Number(p.bloque ?? 1),
			posicion: Number(p.posicion),
			clase: texto(p.clase_rima),
			suelto: p.suelto === true,
			seccion: texto(p.seccion)
		})),
		enlaces: (enlacesPorEsquema.get(String(e.esquema_rima_id)) ?? []).map((l) => ({
			desde: Number(l.posicion_origen),
			hasta: Number(l.posicion_destino),
			desplazamiento: Number(l.desplazamiento_bloque),
			nota: texto(l.nota)
		}))
	});

	/** La medida y la rima que una parte hereda de la arquitectura que reutiliza. */
	const reutilizadaPorId = new Map(
		((arquitecturasReutilizadas ?? []) as any[]).map((row) => [String(row.arquitectura_id), row])
	);

	/**
	 * Lo que la rejilla necesita de una arquitectura. Las secciones son solo las raíces: las
	 * hijas describen el interior de una parte y no dibujan columnas propias.
	 */
	const entradaDeRejilla = (arquitecturaId: string): EntradaRejilla => {
		const filas = seccionesPor.get(arquitecturaId) ?? [];
		const raices: SeccionEntrada[] = filas
			.filter((s) => !s.seccion_padre_id)
			.sort((a, b) => Number(a.orden ?? 0) - Number(b.orden ?? 0))
			.map((s) => ({
				nombre: String(s.nombre),
				versosMin: numero(s.versos_min),
				versosMax: numero(s.versos_max),
				repeticionesMin: numero(s.repeticiones_min),
				repeticionesMax: numero(s.repeticiones_max),
				reutiliza: reutilizacionDe(s.arquitectura_referenciada_id)
			}));

		// Qué parte ofrece cada disposición. Un esquema puede no declarar `seccion_id` y aun así
		// ser de una parte, porque quien lo ofrece es la pregunta de esa parte: las tres mudanzas
		// del villancico cuelgan de la arquitectura y son de la mudanza.
		const seccionOfrecida = new Map<string, string>();
		for (const s of filas) {
			for (const esquema of rimaDeSeccion(s.seccion_id, String(s.nombre))) {
				if (!seccionOfrecida.has(esquema.id)) seccionOfrecida.set(esquema.id, String(s.nombre));
			}
		}

		const rimas: EsquemaRimaEntrada[] = (rimaPor.get(arquitecturaId) ?? []).map((e) =>
			rimaEntrada(
				e,
				e.seccion_id
					? (nombreDeSeccionPorId.get(String(e.seccion_id)) ?? null)
					: (seccionOfrecida.get(String(e.esquema_rima_id)) ?? null)
			)
		);
		// La misma disposición puede servir a dos partes —las dos quintillas de la copla real
		// eligen del mismo repertorio—, así que la clave es la pareja parte + esquema.
		const vistos = new Set(rimas.map((rima) => `${rima.seccion ?? ''}:${rima.id}`));
		const metricos: EsquemaMetricoEntrada[] = (metricosPor.get(arquitecturaId) ?? []).map(
			metricoEntrada
		);
		for (const s of filas) {
			const nombre = String(s.nombre);
			for (const esquema of rimaDeSeccion(s.seccion_id, nombre)) {
				if (vistos.has(`${nombre}:${esquema.id}`)) continue;
				vistos.add(`${nombre}:${esquema.id}`);
				const crudo = (esquemasRima as any[]).find((e) => String(e.esquema_rima_id) === esquema.id);
				if (crudo) rimas.push(rimaEntrada(crudo, nombre));
			}
			// Lo que la parte hereda de la forma que reutiliza. Sin esto el cuerpo de la seguidilla
			// compuesta y la estrofa de las sextinas se dibujaban sin medida.
			const heredada = s.arquitectura_referenciada_id
				? reutilizadaPorId.get(String(s.arquitectura_referenciada_id))
				: null;
			if (!heredada) continue;
			if (!metricos.some((esquema) => esquema.seccion === nombre)) {
				for (const em of (heredada.esquemas_metricos ?? []) as any[]) {
					metricos.push({
						tipoSecuencia: texto(em.tipo_secuencia),
						medidaUniforme: em.medida_uniforme === null ? null : em.medida_uniforme === true,
						seccion: nombre,
						posiciones: ((em.posiciones ?? []) as any[]).map((p) => ({
							posicion: Number(p.posicion),
							silabas: p.silabas === null || p.silabas === undefined ? null : String(p.silabas),
							alternativa: numero(p.alternativa),
							opcional: p.opcional === true
						})),
						opciones: ((em.opciones ?? []) as any[]).map((o) => ({
							silabas: o.silabas === null || o.silabas === undefined ? null : String(o.silabas),
							rol: texto(o.rol)
						}))
					});
				}
			}
			if (rimas.some((rima) => rima.seccion === nombre)) continue;
			for (const er of (heredada.esquemas_rima ?? []) as any[]) {
				rimas.push({
					id: String(er.esquema_rima_id),
					nombre: texto(er.nombre),
					notacion: texto(er.notacion),
					seccion: nombre,
					modalidad: texto(er.modalidad),
					posiciones: ((er.posiciones ?? []) as any[]).map((p) => ({
						bloque: Number(p.bloque ?? 1),
						posicion: Number(p.posicion),
						clase: texto(p.clase_rima),
						suelto: p.suelto === true,
						seccion: texto(p.seccion)
					})),
					enlaces: []
				});
			}
		}
		const arquitectura = (arquitecturas as any[]).find(
			(a) => String(a.arquitectura_id) === arquitecturaId
		);
		return {
			metricos,
			rimas,
			secciones: raices,
			unidadMin: numero(arquitectura?.unidad_versos_min),
			unidadMax: numero(arquitectura?.unidad_versos_max)
		};
	};

	/**
	 * Los rasgos, repartidos por cómo se leen. Lo que los separa es su grupo de elección: si no
	 * tienen, la arquitectura lo afirma; si lo tienen y admite una sola respuesta entre varias,
	 * los valores son excluyentes; si es una sola opción que puede quedarse vacía, es un sí o un no.
	 */
	const rasgosDe = (arquitecturaId: string): PublicTraits => {
		const grupoDeRasgo = new Map(
			(gruposEleccion as any[])
				.filter((g) => String(g.arquitectura_id) === arquitecturaId && g.rasgo_id)
				.map((g) => [String(g.rasgo_id), g])
		);
		const opcionesDeGrupo = (grupoId: string) =>
			(opcionesEleccion as any[]).filter(
				(o) => String(o.grupo_eleccion_id) === grupoId && o.valor_rasgo_id
			);

		const declarados: PublicTrait[] = [];
		const opcionales: PublicTrait[] = [];
		const porRasgo = new Map<string, { nombre: string; nota: string | null; valores: PublicTrait[] }>();

		for (const r of rasgosPor.get(arquitecturaId) ?? []) {
			const nombre = nombreRasgo.get(String(r.rasgo_id)) ?? '—';
			const rasgo: PublicTrait = {
				nombre,
				valor: r.valor_id ? (nombreValor.get(String(r.valor_id)) ?? null) : null,
				modalidad: texto(r.modalidad),
				nota: texto(r.nota),
				posicionesMax: numero(r.posiciones_max)
			};
			const grupo = grupoDeRasgo.get(String(r.rasgo_id));
			if (!grupo) {
				declarados.push(rasgo);
				continue;
			}
			const opciones = opcionesDeGrupo(String(grupo.grupo_eleccion_id));
			// Una sola opción que se puede dejar sin responder no es una elección: es un sí o un no.
			// Es el mismo criterio con el que el editor decide su control.
			if (opciones.length <= 1 && Number(grupo.selecciones_min ?? 0) === 0) {
				opcionales.push(rasgo);
				continue;
			}
			const grupoDeValores = porRasgo.get(nombre) ?? { nombre, nota: null, valores: [] };
			grupoDeValores.valores.push(rasgo);
			grupoDeValores.nota ??= rasgo.nota;
			porRasgo.set(nombre, grupoDeValores);
		}

		// Un rasgo que se pregunta pero del que solo se declaró un valor no es una disyuntiva.
		const excluyentes = [...porRasgo.values()].filter((grupo) => grupo.valores.length > 1);
		for (const grupo of porRasgo.values()) {
			if (grupo.valores.length === 1) opcionales.push(grupo.valores[0]);
		}
		return { declarados, excluyentes, opcionales };
	};

	/**
	 * El régimen de rima, leído en el nivel en que el catálogo lo declara.
	 *
	 * Se declara **siempre**: en la arquitectura si su régimen es uno, y en cada disposición si
	 * dentro de ella varía. Lo que esta función no hace es rellenar el de la arquitectura con el
	 * de sus disposiciones cuando coinciden: eso taparía que falta declararlo donde toca, y la
	 * ficha existe justamente para que esos huecos se vean.
	 */
	const tipoDeRima = (
		row: any,
		esquemas: PublicRhymeScheme[]
	): { tipoRima: string | null; tipoRimaPorDisposicion: boolean; tipoRimaSinDeclarar: boolean } => {
		const declarado = row.tipo_rima_id
			? (nombreTipoRima.get(String(row.tipo_rima_id)) ?? null)
			: null;
		if (declarado) {
			return { tipoRima: declarado, tipoRimaPorDisposicion: false, tipoRimaSinDeclarar: false };
		}
		const conRegimen = esquemas.filter((esquema) => esquema.tipoRima);
		const porDisposicion = conRegimen.length > 0 && conRegimen.length === esquemas.length;
		return {
			tipoRima: null,
			tipoRimaPorDisposicion: porDisposicion,
			tipoRimaSinDeclarar: !porDisposicion
		};
	};

	const misArquitecturas: PublicArchitecture[] = (arquitecturas as any[])
		.filter((row) => String(row.forma_id) === formaId)
		.map((row) => {
			const id = String(row.arquitectura_id);
			const entrada = entradaDeRejilla(id);
			// Una sola figura: dentro van ya todas las disposiciones, alineadas bajo la medida.
			const rejilla = construirRejilla(entrada);
			return {
				slug: String(row.slug),
				nombre: String(row.nombre),
				descripcion: texto(row.descripcion),
				principal: row.principal === true,
				modalidad: texto(row.modalidad),
				...tipoDeRima(row, rimaAgrupadaPorParte(id)),
				unidadMin: numero(row.unidad_versos_min),
				unidadMax: numero(row.unidad_versos_max),
				perfil: perfilDeArquitectura({
					...entrada,
					variedades: (variedadesPor.get(id) ?? []).length,
					tieneCicloDeEstribillo: (repeticionesPor.get(id) ?? []).some(
						(r) => String(r.tipo) === 'estribillo'
					)
				}),
				rejilla,
				esquemasMetricos: (metricosPor.get(id) ?? [])
					.map((e): PublicMetricScheme => {
						const dibujable = metricoEntrada(e);
						return {
							nombre: String(e.nombre ?? '—'),
							notacion: null,
							descripcion: texto(e.descripcion),
							modalidad: null,
							tipoSecuencia: dibujable.tipoSecuencia,
							// Solo un repertorio abierto declara si la medida elegida vale para todo
							// el pasaje: en la silva elige cada verso; en el villancico, la
							// composición entera.
							uniforme: e.medida_uniforme === true,
							repertorio: dibujable.opciones.flatMap((opcion) =>
								opcion.silabas ? [{ silabas: opcion.silabas, rol: opcion.rol }] : []
							),
							deLaSeccion: dibujable.seccion
						};
					})
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
				// Una variedad es un emparejamiento: la medida M1 con la rima R1. Enseñarla como
				// nombre y descripción obligaba a escribir en prosa lo que ya está en los dos
				// esquemas, y dejaba salir a la web los códigos internos «M1» y «R1».
				variedades: (variedadesPor.get(id) ?? []).map((v): PublicVariety => {
					const metrico = (esquemasMetricos as any[]).find(
						(e) => String(e.esquema_metrico_id) === String(v.esquema_metrico_id)
					);
					const rima = (esquemasRima as any[]).find(
						(e) => String(e.esquema_rima_id) === String(v.esquema_rima_id)
					);
					const medida = metrico
						? metricoEntrada(metrico)
								.posiciones.filter((posicion) => (posicion.alternativa ?? 1) === 1)
								.sort((a, b) => a.posicion - b.posicion)
								.map((posicion) => posicion.silabas ?? '?')
								.join('-')
						: '';
					return {
						nombre: String(v.nombre),
						descripcion: texto(v.descripcion),
						modalidad: texto(v.modalidad),
						medida: medida || null,
						rima: rima ? (texto(rima.notacion) ?? texto(rima.nombre)) : null
					};
				}),
				eligeVariedad: (gruposEleccion as any[]).some(
					(g) => String(g.arquitectura_id) === id && String(g.dimension) === 'combinacion'
				),
				rasgos: rasgosDe(id),
				// `repeticiones_metricas` no tiene columna `regla`: la ficha llevaba imprimiendo
				// «undefined» en el villancico, el zéjel y las tres sextinas. Lo que sí distingue a
				// unas de otras es si materializan una sección, porque entonces no son norma de la
				// forma sino las respuestas de una pregunta del editor.
				repeticiones: (repeticionesPor.get(id) ?? []).map(
					(r): PublicRepetition => ({
						slug: String(r.slug),
						tipo: String(r.tipo),
						nombre: String(r.nombre),
						modalidad: texto(r.modalidad),
						descripcion: texto(r.descripcion),
						esAlternativa: Boolean(r.materializa_seccion_id) || String(r.tipo) === 'estribillo'
					})
				),
				denominaciones: (denominacionesPorArquitectura.get(id) ?? []).map((d) => String(d.nombre))
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
				(row) => String(row.forma_origen_id) === formaId || String(row.forma_destino_id) === formaId
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
