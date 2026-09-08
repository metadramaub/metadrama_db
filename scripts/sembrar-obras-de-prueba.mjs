/**
 * Siembra obras de prueba anotadas con el catálogo nuevo.
 *
 * Hacen falta para rehacer la precomputación y la ficha pública: hoy las 92 obras del corpus están
 * anotadas con el vocabulario legado y **ninguna** con el catálogo nuevo, así que no hay contra qué
 * escribir la función ni con qué comprobar que la ficha abre. Los datos son inventados a propósito.
 *
 * **No se anota a mano ni se inserta a pelo.** Cada secuencia se guarda con
 * `guardar_anotacion_metrica`, que es la vía que valida —la misma que usa el editor V2—, y las
 * respuestas se derivan del catálogo: por cada pregunta activa de la arquitectura se elige una
 * opción. Así la siembra es también una prueba del catálogo: si una forma no se puede responder
 * sola, sale aquí antes de que se atasque un editor.
 *
 * **Las obras se marcan «(prueba)» en el título.** La anterior obra de pruebas contaminó todo lo
 * que se medía sobre el corpus —44 de 260 secuencias eran suyas— y hubo que retirarla con una
 * migración: ver `20260804120000_retirar_obra_de_pruebas.sql`. Estas se retiran igual, y por eso
 * llevan la marca en el título.
 *
 * Uso:
 *   node scripts/sembrar-obras-de-prueba.mjs --probe        # qué formas se pueden sembrar y cuáles no
 *   node scripts/sembrar-obras-de-prueba.mjs --obra escoba  # siembra una
 *   node scripts/sembrar-obras-de-prueba.mjs                # siembra todas
 */

import { query, tryQuery } from './lib/consulta.mjs';

// --------------------------------------------------------------------------
// Utilidades de SQL
// --------------------------------------------------------------------------

/** Cita un literal de texto para SQL. */
function lit(value) {
	if (value === null || value === undefined) return 'null';
	return `'${String(value).replaceAll("'", "''")}'`;
}

/** Una consulta que devuelve una sola fila y un solo valor. */
function scalar(sql) {
	const rows = query(sql);
	if (rows.length === 0) return null;
	return Object.values(rows[0])[0];
}

/**
 * El identificador de un admin, para prestarle su identidad a las llamadas que lo exigen.
 *
 * `guardar_anotacion_metrica` comprueba quién anota y `auth.uid()` rellena `created_by`. Desde la
 * CLI no pregunta nadie, así que sin esto ni guarda ni deja rastro de quién sembró.
 */
function idDeUnAdmin() {
	const admin = scalar(`
		select e.user_id
		from public.editores e
		join public.vocabularios rol on rol.termino_id = e.role
		where lower(rol.termino) in ('admin', 'ip') and coalesce(e.activo, true)
		limit 1
	`);
	if (!admin) {
		console.error('No hay ningún admin en la base: sin identidad no se puede anotar.');
		process.exit(1);
	}
	return admin;
}

// --------------------------------------------------------------------------
// El catálogo, leído una vez
// --------------------------------------------------------------------------

function cargarCatalogo() {
	const arquitecturas = query(`
		select
			a.arquitectura_id, a.slug as arquitectura_slug, a.nombre as arquitectura,
			a.unidad_versos_min, a.unidad_versos_max, a.principal,
			f.forma_id, f.slug as forma_slug, f.nombre as forma, f.nivel_estructural, f.tipo_registro,
			r.modulo_versos, r.minimo_versos
		from public.arquitecturas_forma a
		join public.formas_metricas f using (forma_id)
		left join public.arquitecturas_reglas_longitud r using (arquitectura_id)
		where a.activo and f.activo
		order by f.nombre, a.orden
	`);

	const secciones = query(`
		select
			s.seccion_id, s.arquitectura_id, s.seccion_padre_id, s.nombre, s.orden,
			s.repeticiones_min, s.repeticiones_max, s.versos_min, s.versos_max
		from public.estructuras_secciones s
		order by s.arquitectura_id, s.orden
	`);

	const grupos = query(`
		select
			g.grupo_eleccion_id, g.arquitectura_id, g.nombre, g.dimension, g.alcance,
			g.seccion_id, g.seccion_tratada_id, g.selecciones_min, g.selecciones_max, g.tipo_control
		from public.grupos_eleccion_metrica_resueltos g
		where g.activo
		order by g.arquitectura_id, g.orden
	`);

	const opciones = query(`
		select opcion_eleccion_id, grupo_eleccion_id, nombre, orden, posicion_unidad
		from public.opciones_eleccion_metrica
		where activo
		order by grupo_eleccion_id, orden, nombre
	`);

	const porArquitectura = new Map();
	for (const arquitectura of arquitecturas) {
		porArquitectura.set(arquitectura.arquitectura_id, {
			...arquitectura,
			secciones: [],
			grupos: []
		});
	}
	for (const seccion of secciones) {
		porArquitectura.get(seccion.arquitectura_id)?.secciones.push(seccion);
	}
	const opcionesPorGrupo = new Map();
	for (const opcion of opciones) {
		const lista = opcionesPorGrupo.get(opcion.grupo_eleccion_id) ?? [];
		lista.push(opcion);
		opcionesPorGrupo.set(opcion.grupo_eleccion_id, lista);
	}
	for (const grupo of grupos) {
		porArquitectura.get(grupo.arquitectura_id)?.grupos.push({
			...grupo,
			opciones: opcionesPorGrupo.get(grupo.grupo_eleccion_id) ?? []
		});
	}

	return { arquitecturas, porArquitectura };
}

// --------------------------------------------------------------------------
// De un rango a una anotación
// --------------------------------------------------------------------------

/**
 * Las realizaciones de una secuencia: las unidades que caben en el rango y, dentro de cada una, las
 * partes que la arquitectura declara.
 *
 * **Solo se derivan las partes que no admiten repetirse ni crecer.** Una sección `1-1` con extensión
 * fija ocupa un sitio calculable dentro de la unidad; en cuanto puede repetirse o su extensión
 * varía, cuántas hay y dónde empiezan es una decisión de quien anota, no una cuenta. Esas formas se
 * quedan fuera de la siembra automática y se dicen por su nombre.
 */
function planDeRealizaciones(arquitectura, vIni, vFin) {
	const versosUnidad = Number(arquitectura.unidad_versos_min ?? 0);
	const versosDelRango = vFin - vIni + 1;
	const problemas = [];
	// **La unidad abierta es el pasaje entero.** Un romance, una silva o un tramo sin forma dejan su
	// extensión sin declarar: no hay unidad que quepa un número de veces, hay una sola.
	const abierta = !arquitectura.unidad_versos_min;

	if (!abierta && Number(arquitectura.unidad_versos_max) !== versosUnidad) {
		problemas.push('la unidad crece: su extensión mínima y su máxima no coinciden');
		return { unidades: [], problemas };
	}
	if (!abierta && versosDelRango % versosUnidad !== 0) {
		problemas.push(
			`el rango (${versosDelRango} versos) no es múltiplo de la unidad (${versosUnidad})`
		);
		return { unidades: [], problemas };
	}

	const pasoDeUnidad = abierta ? versosDelRango : versosUnidad;
	const raices = arquitectura.secciones.filter((seccion) => seccion.seccion_padre_id === null);
	const conHijas = raices.some((raiz) =>
		arquitectura.secciones.some((seccion) => seccion.seccion_padre_id === raiz.seccion_id)
	);
	if (conHijas) {
		problemas.push('sus partes tienen partes dentro: eso lo decide quien anota');
		return { unidades: [], problemas };
	}

	// **Una parte que se repite sin tope llena lo que sobra.** Es la cadena de tercetos del terceto
	// encadenado: la unidad no declara extensión, la cadena se repite «1 o más» y el serventesio
	// final es opcional. Se materializa lo que cada parte dice —cero, si es opcional— y la que no
	// tiene tope ocupa el resto, que por eso tiene que caber justo.
	const sinTope = raices.filter((seccion) => seccion.repeticiones_max === null);
	if (sinTope.length > 1) {
		problemas.push(
			'tiene más de una parte sin tope de repeticiones: no hay una sola manera de repartirla'
		);
		return { unidades: [], problemas };
	}

	const medible = (seccion) =>
		Number(seccion.versos_min) === Number(seccion.versos_max) && Number(seccion.versos_min) > 0;
	if (raices.length > 0 && !raices.every(medible)) {
		problemas.push(
			'alguna de sus partes no tiene extensión fija: cuánto ocupa lo decide quien anota'
		);
		return { unidades: [], problemas };
	}

	const vueltas = new Map();
	let ocupado = 0;
	for (const seccion of raices) {
		if (seccion.repeticiones_max === null) continue;
		const veces = Number(seccion.repeticiones_min);
		vueltas.set(seccion.seccion_id, veces);
		ocupado += veces * Number(seccion.versos_min);
	}

	if (sinTope.length === 1) {
		const seccion = sinTope[0];
		const resto = pasoDeUnidad - ocupado;
		const veces = resto / Number(seccion.versos_min);
		if (resto <= 0 || !Number.isInteger(veces)) {
			problemas.push(
				`su parte repetible mide ${seccion.versos_min} versos y quedan ${resto} por repartir`
			);
			return { unidades: [], problemas };
		}
		vueltas.set(seccion.seccion_id, veces);
		ocupado += resto;
	}

	if (raices.length > 0 && ocupado !== pasoDeUnidad) {
		problemas.push(`sus partes ocupan ${ocupado} versos y la unidad mide ${pasoDeUnidad}`);
		return { unidades: [], problemas };
	}

	const unidades = [];
	// **El orden es único en toda la anotación**, no dentro de cada unidad: la tabla lo declara
	// `unique (anotacion_id, orden)`, así que una parte con orden 1 choca con la primera unidad.
	let orden = 1;
	for (let inicio = vIni; inicio <= vFin; inicio += pasoDeUnidad) {
		const unidad = {
			realizacion_id: crypto.randomUUID(),
			realizacion_padre_id: null,
			seccion_id: null,
			orden: orden++,
			v_ini: inicio,
			v_fin: inicio + pasoDeUnidad - 1,
			etiqueta: null,
			observaciones: null
		};
		unidades.push(unidad);

		let cursor = inicio;
		for (const seccion of raices) {
			const versos = Number(seccion.versos_min);
			for (let vuelta = 0; vuelta < (vueltas.get(seccion.seccion_id) ?? 0); vuelta += 1) {
				unidades.push({
					realizacion_id: crypto.randomUUID(),
					realizacion_padre_id: unidad.realizacion_id,
					seccion_id: seccion.seccion_id,
					orden: orden++,
					v_ini: cursor,
					v_fin: cursor + versos - 1,
					etiqueta: null,
					observaciones: null
				});
				cursor += versos;
			}
		}
	}

	return { unidades, problemas };
}

/**
 * Una respuesta por pregunta activa, elegida del catálogo.
 *
 * Se responde **todo lo que la arquitectura pregunta**, obligatorio o no, para que la obra sembrada
 * ejercite la ficha entera. Cuando la pregunta admite varias respuestas se dan las mínimas: lo que
 * interesa es que haya dato en cada dimensión, no llenar.
 */
function planDeRespuestas(arquitectura, unidades, versosDeLaSecuencia, giro = 0) {
	const elecciones = [];
	const problemas = [];

	for (const grupo of arquitectura.grupos) {
		const cuantas = Math.max(1, Number(grupo.selecciones_min) || 1);
		// **Una pregunta sin opciones no está rota: se responde escribiendo.** Son los esquemas de
		// secuencia abierta —la novena-lira, las sextillas, el sexteto dodecasílabo—, donde el
		// catálogo no ofrece repertorio porque la disposición varía de una composición a otra.
		const escrita = grupo.opciones.length === 0;
		if (escrita && !['rima', 'metro'].includes(grupo.dimension)) {
			if (Number(grupo.selecciones_min) > 0) {
				problemas.push(`la pregunta «${grupo.nombre}» es obligatoria y no ofrece ninguna opción`);
			}
			continue;
		}
		// **Cuando la pregunta va por posiciones, se responde una por posición.** El cuarteto-lira
		// pregunta la medida de cada verso, y sus opciones traen `posicion_unidad`: repetir la
		// primera dos veces da «Ya hay una respuesta para la posición 1».
		const porPosicion = new Map();
		for (const opcion of grupo.opciones) {
			const clave = opcion.posicion_unidad ?? 0;
			if (!porPosicion.has(clave)) porPosicion.set(clave, opcion);
		}
		const conPosiciones = porPosicion.size > 1 || [...porPosicion.keys()][0];
		// **Y nunca más de las que la pregunta admite.** El quiebro de una redondilla se puede marcar
		// en cuatro versos, pero la pregunta acepta tres respuestas como mucho: responder una por
		// posición sin mirar el tope da «necesita entre 0 y 3 respuestas».
		const tope = Number(grupo.selecciones_max) || Number.MAX_SAFE_INTEGER;
		// **La misma forma no se responde siempre igual.** Una obra con ocho quintillas y las ocho
		// en `ababa` no se parece a nada: el giro —el orden de la secuencia dentro de la obra—
		// desplaza la elección dentro del repertorio, así que salen varias tipologías, varias
		// variedades del sexteto-lira y varias disposiciones donde el catálogo ofrece más de una.
		const desdeElGiro = (indice) => grupo.opciones[(indice + giro) % grupo.opciones.length];
		const elegidas = escrita
			? [null]
			: (conPosiciones
					? [...porPosicion.values()]
					: Array.from({ length: Math.min(cuantas, grupo.opciones.length) }, (_, indice) =>
							desdeElGiro(indice)
						)
				).slice(0, tope);
		if (!escrita && elegidas.length < cuantas) {
			problemas.push(
				`la pregunta «${grupo.nombre}» pide ${cuantas} respuestas y solo ofrece ${grupo.opciones.length}`
			);
			continue;
		}

		const destinos =
			grupo.alcance === 'secuencia'
				? [null]
				: unidades
						.filter((unidad) =>
							grupo.seccion_id === null
								? unidad.realizacion_padre_id === null
								: unidad.seccion_id === grupo.seccion_id
						)
						.map((unidad) => unidad.realizacion_id);

		if (destinos.length === 0 && grupo.alcance !== 'secuencia') {
			problemas.push(`la pregunta «${grupo.nombre}» no tiene ninguna realización donde caer`);
			continue;
		}

		for (const destino of destinos) {
			const realizacionDestino = destino
				? unidades.find((unidad) => unidad.realizacion_id === destino)
				: null;
			for (const opcion of elegidas) {
				elecciones.push({
					realizacion_id: destino,
					dimension: grupo.dimension,
					seccion_tratada_id: grupo.seccion_tratada_id ?? null,
					opcion_eleccion_id: opcion ? opcion.opcion_eleccion_id : null,
					valor_texto: opcion
						? null
						: respuestaEscrita(grupo, realizacionDestino, arquitectura, versosDeLaSecuencia),
					observaciones: null
				});
			}
		}
	}

	return { elecciones, problemas };
}

/**
 * Lo que se escribe cuando la pregunta no ofrece repertorio.
 *
 * Son dos casos, y los dos existen a propósito: los **esquemas de secuencia abierta** —la
 * novena-lira, las sextillas—, donde la disposición varía de una composición a otra, y **la medida
 * de los tramos sin forma**, donde no hay norma que ofrecer porque el tramo es justamente lo que no
 * la tiene.
 */
function respuestaEscrita(grupo, realizacion, arquitectura, versosDeLaSecuencia) {
	// La medida de un tramo sin forma se escribe **verso a verso y en cifras**, y la base cuenta que
	// haya una por verso. Cuando la pregunta se responde en la secuencia y no en una unidad, los
	// versos son los del pasaje entero: son justamente los tramos sin forma, donde no hay unidad.
	if (grupo.dimension === 'metro') {
		const versos = realizacion
			? realizacion.v_fin - realizacion.v_ini + 1
			: (versosDeLaSecuencia ?? 4);
		return Array.from({ length: versos }, (_, indice) => (indice % 2 === 0 ? '8' : '7')).join(' ');
	}
	return esquemaEscrito(realizacion, arquitectura, versosDeLaSecuencia);
}

/**
 * Un esquema de rima escrito a mano, con tantas letras como versos tenga lo que describe.
 *
 * No pretende ser el de ninguna composición real: pretende ser uno **posible y bien contado**, que
 * es lo que comprueba el servidor. Riman los pares, como un romance.
 */
function esquemaEscrito(realizacion, arquitectura, versosDeLaSecuencia) {
	// Igual que la medida: la base cuenta que haya una letra por verso, y cuando la pregunta se
	// responde en la secuencia los versos son los del pasaje entero.
	const versos = realizacion
		? realizacion.v_fin - realizacion.v_ini + 1
		: Number(arquitectura.unidad_versos_min ?? 0) || versosDeLaSecuencia || 4;
	const letras = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
	let escrito = '';
	for (let posicion = 0; posicion < versos; posicion += 1) {
		escrito += letras[Math.floor(posicion / 2) % letras.length];
	}
	return escrito;
}

// --------------------------------------------------------------------------
// Modo sonda
// --------------------------------------------------------------------------

/**
 * Qué formas se pueden sembrar solas y cuáles no.
 *
 * Se prueba cada arquitectura con un rango de una unidad, que es el caso más favorable: si ahí no
 * sale, no sale con ninguno.
 */
function sondar(catalogo) {
	const sirven = [];
	const noSirven = [];

	for (const arquitectura of catalogo.porArquitectura.values()) {
		// Se prueba con lo que la arquitectura ocupa: su unidad si la declara, y si no, lo que sumen
		// sus partes. Probar un romance con un verso decía que sus partes no caben, que es verdad y
		// no dice nada.
		const versos = Number(arquitectura.unidad_versos_min ?? 0);
		const partes = arquitectura.secciones
			.filter((seccion) => seccion.seccion_padre_id === null)
			.reduce(
				(total, seccion) =>
					total + Number(seccion.versos_min || 0) * Number(seccion.repeticiones_min || 0),
				0
			);
		const vFin = versos > 0 ? versos : partes > 0 ? partes : 8;
		const { unidades, problemas } = planDeRealizaciones(arquitectura, 1, vFin);
		const respuestas =
			unidades.length > 0 ? planDeRespuestas(arquitectura, unidades, vFin) : { problemas: [] };
		const todos = [...problemas, ...respuestas.problemas];
		const etiqueta = `${arquitectura.forma} · ${arquitectura.arquitectura}`;
		if (todos.length === 0) sirven.push(etiqueta);
		else noSirven.push(`${etiqueta}\n    ${todos.join('\n    ')}`);
	}

	console.log(`Se pueden sembrar solas: ${sirven.length} arquitecturas`);
	console.log(sirven.map((linea) => `  · ${linea}`).join('\n'));
	console.log(`\nNo se pueden: ${noSirven.length}`);
	console.log(noSirven.map((linea) => `  · ${linea}`).join('\n'));
}

// --------------------------------------------------------------------------
// Quién firma y qué se siembra
// --------------------------------------------------------------------------

/**
 * Cuatro autores **semirreales**, y dos de ellos con más de una obra.
 *
 * Dos decisiones, y las dos por lo mismo —que la demo enseñe lo que la ficha sabe hacer—:
 *
 * * **Son dramaturgos reales, con su identificador de Wikidata.** La ficha de autor pide a Wikidata
 *   el retrato y las fechas, así que un autor inventado sale sin cara y sin datas. Se han elegido
 *   cuatro que **no están en el corpus**, para no mezclar sus obras reales con estas.
 * * **Dos firman más de una obra.** El perfil de autor se precomputa aparte —`autores_resumen`— y
 *   agrega lo de todas sus obras: con un autor por obra, esa mitad no se probaría nunca.
 *
 * Las obras que firman **sí son inventadas**, y llevan «(prueba)» en el título. Por eso la limpieza
 * los busca por su identificador de Wikidata y no por el nombre: el nombre es el de una persona
 * real y algún día puede estar en el corpus de verdad.
 */
const AUTORES = [
	{ clave: 'montalban', nombre: 'Juan Pérez de Montalbán', wikidata: 'Q3100564' },
	{ clave: 'benavente', nombre: 'Luis Quiñones de Benavente', wikidata: 'Q1876516' },
	{ clave: 'enciso', nombre: 'Diego Jiménez de Enciso', wikidata: 'Q5274715' },
	{ clave: 'cueva', nombre: 'Juan de la Cueva', wikidata: 'Q164964' }
];

/**
 * Las caracterizaciones y las desviaciones que se reparten por las obras.
 *
 * No van en todas: lo que interesa es que la ficha se encuentre con obras que las tienen y con
 * obras que no, porque las dos cosas pasan en el corpus.
 */
const CARACTERIZACIONES = ['cantado', 'prosa', 'evocacion_metrica'];

/**
 * Prosa de relleno, para que los campos largos **ocupen lo que van a ocupar**.
 *
 * Una sinopsis de seis palabras y una bibliografía vacía hacen que la ficha se vea más holgada de
 * lo que se verá nunca. Es lorem ipsum a propósito: nadie debe confundirlo con contenido.
 */
const LOREM = [
	'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
	'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
	'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.',
	'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
	'Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium.',
	'Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores.'
];

/** Un párrafo de tantas frases, empezando por donde diga el giro, para que no se repitan todas. */
function lorem(frases, giro = 0) {
	return Array.from({ length: frases }, (_, indice) => LOREM[(indice + giro) % LOREM.length]).join(
		' '
	);
}
/**
 * Las desviaciones que se reparten, **con las relaciones que la base admite de verdad**.
 *
 * No son las del plan del 3 de agosto: la comprobación de la tabla es más estrecha —la rima solo
 * admite `otra`, y `repeticion` y `rasgo` solo `falta`, `sobra` y `otra`—, y `diferente` no la
 * admite ninguna dimensión. Aquí se usan las que pasan; la diferencia entre el plan y la base está
 * anotada aparte, porque es una decisión y no un arreglo del sembrador.
 */
const DESVIACIONES = [
	{
		dimension: 'metro',
		relacion_norma: 'menor_que_norma',
		observaciones: 'Verso de una sílaba menos que la norma.'
	},
	{
		dimension: 'metro',
		relacion_norma: 'mayor_que_norma',
		observaciones: 'Verso de una sílaba de más.'
	},
	{
		dimension: 'rima',
		relacion_norma: 'otra',
		observaciones: 'La rima no es la que la norma fija.'
	},
	{
		dimension: 'estructura',
		relacion_norma: 'falta',
		observaciones: 'Falta la parte final que la norma espera.'
	},
	{ dimension: 'repeticion', relacion_norma: 'sobra', observaciones: 'Una unidad de más.' },
	{ dimension: 'rasgo', relacion_norma: 'otra', observaciones: 'Predominan los finales agudos.' }
];

/**
 * Las obras, que son **comedias y no muestrarios**.
 *
 * La primera tanda eran cuatro «exploraciones» que repartían el catálogo entero a partes iguales:
 * servían para saber que todo se puede guardar, y no se parecían a nada. Estas se calibran con el
 * corpus de Lope —264.118 versos de redondilla, 87.315 de quintilla, 78.353 de romance, y luego
 * octava real, sueltos, décima, terceto encadenado, lira, soneto y silva— de modo que **el grueso
 * es siempre el mismo puñado de formas y cada obra trae además una rareza distinta**. Así el
 * catálogo se recorre entre todas sin que ninguna parezca un inventario.
 *
 * Los pesos son porcentajes de versos y no hace falta que sumen cien: lo que falte se reparte.
 * La extensión va entre 2.500 y 3.200 versos, que es lo que mide una comedia y lo único que la
 * base va a analizar por ahora.
 */
const NUCLEO = [
	['redondilla', 30],
	['quintilla', 14],
	['romance', 22],
	['octava_real', 6],
	['endecasilabo_suelto', 5],
	['decima', 5],
	['terceto_encadenado', 4],
	['soneto', 2]
];

const OBRAS = [
	{
		clave: 'destino',
		sesgo: 0,
		fecha: [1614, 1618],
		titulo: 'La fuerza del destino en la corte (prueba)',
		autor: 'montalban',
		genero: 'comedia_o_tragicomedia',
		versos: 2980,
		raras: [
			['silva', 6],
			['lira', 3]
		]
	},
	{
		clave: 'sortija',
		sesgo: 1,
		fecha: [1620, 1620],
		titulo: 'El caballero de la sortija (prueba)',
		autor: 'montalban',
		genero: 'comedia_o_tragicomedia',
		versos: 2740,
		raras: [
			['seguidilla', 4],
			['pareado', 3]
		]
	},
	{
		clave: 'fabia',
		sesgo: 2,
		fecha: [1609, 1612],
		titulo: 'Los engaños de Fabia (prueba)',
		autor: 'benavente',
		genero: 'comedia_o_tragicomedia',
		versos: 3120,
		raras: [
			['sextina', 4],
			['terceto', 4]
		]
	},
	{
		clave: 'prodigio',
		sesgo: 3,
		fecha: [1623, 1625],
		titulo: 'El prodigio de Aragón (prueba)',
		autor: 'benavente',
		genero: 'comedia_o_tragicomedia',
		versos: 2860,
		raras: [
			['copla_real', 5],
			['sexteto_lira', 3]
		]
	},
	{
		clave: 'firmeza',
		sesgo: 4,
		fecha: [1616, 1616],
		titulo: 'La firmeza en el destierro (prueba)',
		autor: 'enciso',
		genero: 'tragedia',
		versos: 3050,
		raras: [
			['octava_aguda', 4],
			['endecha_real', 4]
		]
	},
	{
		clave: 'privanza',
		sesgo: 5,
		fecha: [1628, 1631],
		titulo: 'La privanza y la caída (prueba)',
		autor: 'enciso',
		genero: 'tragedia',
		versos: 2620,
		raras: [
			['copla_castellana', 5],
			['cuarteto', 3]
		]
	},
	{
		clave: 'peregrina',
		sesgo: 6,
		fecha: [1605, 1608],
		titulo: 'La peregrina de Sevilla (prueba)',
		autor: 'cueva',
		genero: 'comedia_o_tragicomedia',
		versos: 3180,
		raras: [
			['sextilla', 4],
			['septeto_lira', 3]
		]
	},
	{
		clave: 'burlas',
		sesgo: 7,
		visible: false,
		fecha: [1632, 1635],
		titulo: 'Las burlas del alcalde (prueba)',
		autor: 'cueva',
		genero: 'comedia_o_tragicomedia',
		versos: 2560,
		raras: [
			['copla_de_arte_menor', 5],
			['irregular', 2]
		]
	},
	{
		clave: 'santa',
		sesgo: 8,
		estado: 'vista_previa',
		fecha: [1619, 1621],
		titulo: 'La santa de las montañas (prueba)',
		autor: 'montalban',
		genero: 'comedia_o_tragicomedia',
		versos: 3020,
		raras: [
			['oncena', 4],
			['verso_aislado', 1]
		]
	},
	{
		clave: 'academia',
		sesgo: 9,
		fecha: [1626, 1629],
		titulo: 'La academia de los desengaños (prueba)',
		autor: 'enciso',
		genero: 'comedia_o_tragicomedia',
		versos: 2900,
		raras: [
			['decima_lira', 4],
			['septilla', 4]
		]
	}
];

// --------------------------------------------------------------------------
// La siembra
// --------------------------------------------------------------------------

/**
 * Lo que ocupa una unidad de esta arquitectura, y por tanto el múltiplo al que hay que ajustar
 * cualquier rango suyo.
 *
 * Si la unidad declara extensión, es esa. Si no —romance, silva, terceto encadenado—, manda **el
 * módulo de su regla de longitud**, que es lo que la base comprueba: bloques de tres versos en el
 * terceto encadenado, de cuatro en las enlazadas, de uno en el romance.
 */
function pasoDe(arquitectura) {
	const versos = Number(arquitectura.unidad_versos_min ?? 0);
	if (versos > 0) return versos;
	const modulo = Number(arquitectura.modulo_versos ?? 0);
	if (modulo > 0) return modulo;
	const partes = arquitectura.secciones
		.filter((seccion) => seccion.seccion_padre_id === null)
		.reduce(
			(total, seccion) =>
				total + Number(seccion.versos_min || 0) * Number(seccion.repeticiones_min || 0),
			0
		);
	return partes > 0 ? partes : 4;
}

/** Las arquitecturas que se siembran solas, en el orden en que las devuelve el catálogo. */
function arquitecturasSembrables(catalogo) {
	const sirven = [];
	for (const arquitectura of catalogo.porArquitectura.values()) {
		const paso = pasoDe(arquitectura);
		const { unidades, problemas } = planDeRealizaciones(arquitectura, 1, paso);
		if (problemas.length > 0) continue;
		if (planDeRespuestas(arquitectura, unidades, paso).problemas.length > 0) continue;
		sirven.push({ ...arquitectura, paso });
	}
	return sirven;
}

/** Los términos que hacen falta, leídos de una vez: antes eran nueve consultas por obra. */
function cargarVocabulario() {
	const filas = query(`
		select categoria, termino, termino_id
		from public.vocabularios
		where (categoria = 'estado' and termino = 'vista_previa')
		   or (categoria = 'estado' and termino = 'publicado')
		   or categoria in ('genero', 'tipo_atribucion', 'modalidad_atribucion', 'composicion_autoria', 'caracterizacion_rango')
	`);
	const busca = (categoria, termino) =>
		filas.find((fila) => fila.categoria === categoria && fila.termino === termino)?.termino_id ??
		null;
	const generos = {};
	const caracterizaciones = {};
	for (const fila of filas) {
		if (fila.categoria === 'genero') generos[fila.termino] = fila.termino_id;
		if (fila.categoria === 'caracterizacion_rango')
			caracterizaciones[fila.termino] = fila.termino_id;
	}
	return {
		estado_vista_previa: busca('estado', 'vista_previa'),
		estado_publicado: busca('estado', 'publicado'),
		tipo_tradicional: busca('tipo_atribucion', 'tradicional'),
		modalidad_unica: busca('modalidad_atribucion', 'unica'),
		composicion_individual: busca('composicion_autoria', 'individual'),
		generos,
		caracterizaciones
	};
}

/** Borra lo sembrado antes, para poder repetir la siembra sin duplicar nada. */
function limpiar() {
	const wikidata = AUTORES.map((autor) => lit(autor.wikidata)).join(', ');
	query(`delete from public.obras where titulo like '%(prueba)'`);
	// Por Wikidata y no por nombre: si alguno de estos autores entra en el corpus de verdad, será
	// con sus obras y no conviene que una siembra se lo lleve por delante. Solo se borra el que no
	// haya quedado con ninguna obra.
	query(`
		delete from public.autores a
		where a.wikidata_id in (${wikidata})
		  and not exists (
			select 1
			from public.atribucion_autores aa
			where aa.autor_id = a.autor_id
		  )
	`);
}

function sembrarAutores() {
	const porClave = new Map();
	for (const autor of AUTORES) {
		const existente = scalar(
			`select autor_id from public.autores where wikidata_id = ${lit(autor.wikidata)} limit 1`
		);
		const id =
			existente ??
			scalar(`
				insert into public.autores (nombre_completo, nombre_normalizado, wikidata_id, slug)
				values (
					${lit(autor.nombre)},
					public.metadrama_slugify(${lit(autor.nombre)}),
					${lit(autor.wikidata)},
					public.next_autores_slug(${lit(autor.nombre)}, null)
				)
				returning autor_id
			`);
		porClave.set(autor.clave, id);
	}
	return porClave;
}

/**
 * Las secuencias de una obra: **tiradas de cada forma, repartidas por la obra**.
 *
 * No se trata de que cada forma salga una vez, sino de que salga **como sale en una comedia**: el
 * romance en tiradas largas, la redondilla repartida por todas partes, el soneto una vez y solo, y
 * la rareza de la obra en un pasaje suelto. Por eso cada forma se parte en tantas tiradas como
 * corresponde a su peso, y luego se barajan alternando para que ninguna quede pegada a sí misma.
 *
 * La extensión de cada tirada se ajusta al **módulo de la forma** —lo que su regla de longitud
 * exige: bloques de tres versos en el terceto encadenado, de ocho en la octava— porque si no, la
 * base rechaza el rango y con razón.
 */
function secuenciasDe(obra, sembrables) {
	// **Dos comedias no reparten igual.** Con el mismo núcleo en las diez, las diez salían con
	// diversidad 6,9 y forma dominante al 31 %: comparadas en el buscador parecían la misma obra.
	// El sesgo mueve el peso de las tres frecuentes en direcciones distintas según la obra, que es
	// lo que de verdad distingue a una comedia de redondillas de una de romances.
	const sesgo = obra.sesgo ?? 0;
	const nucleo = NUCLEO.map(([forma, peso], indice) => {
		if (indice > 2) return [forma, peso];
		const direccion = [1, -1, 0][(indice + sesgo) % 3];
		return [forma, Math.max(4, Math.round(peso * (1 + direccion * 0.45)))];
	});
	const reparto = [...nucleo, ...(obra.raras ?? [])];
	const tiradas = [];

	for (const [formaSlug, peso] of reparto) {
		const arquitectura = sembrables.find((a) => a.forma_slug === formaSlug);
		if (!arquitectura) continue;

		// **El verso aislado es un verso, y aparece una vez.** No tiene unidad ni módulo que repetir:
		// es la excepción del catálogo, y la base lo comprueba.
		if (formaSlug === 'verso_aislado') {
			tiradas.push({ arquitectura, versos: 1, forma: formaSlug });
			continue;
		}

		const versosDeLaForma = Math.round((obra.versos * peso) / 100);
		// Cuanto más pesa una forma, en más sitios aparece; el soneto y las rarezas, una o dos veces.
		const cuantasTiradas = Math.max(1, Math.min(9, Math.round(peso / 4)));
		const porTirada = Math.max(arquitectura.paso, Math.round(versosDeLaForma / cuantasTiradas));

		for (let numero = 0; numero < cuantasTiradas; numero += 1) {
			// Se redondea al módulo por arriba, nunca por debajo del mínimo de una unidad.
			const unidades = Math.max(1, Math.round(porTirada / arquitectura.paso));
			tiradas.push({ arquitectura, versos: unidades * arquitectura.paso, forma: formaSlug });
		}
	}

	// **Barajado por turnos.** Se van tomando tiradas de formas distintas, una de cada, hasta
	// vaciarlas: lo que sale es la alternancia de una comedia y no un bloque por forma.
	const porForma = new Map();
	for (const tirada of tiradas) {
		const lista = porForma.get(tirada.forma) ?? [];
		lista.push(tirada);
		porForma.set(tirada.forma, lista);
	}
	const ordenadas = [];
	while (porForma.size > 0) {
		for (const [forma, lista] of [...porForma.entries()]) {
			const siguiente = lista.shift();
			if (siguiente) ordenadas.push(siguiente);
			if (lista.length === 0) porForma.delete(forma);
		}
	}

	const secuencias = [];
	let verso = 1;
	let orden = 1;
	for (const tirada of ordenadas) {
		secuencias.push({
			orden: orden++,
			v_ini: verso,
			v_fin: verso + tirada.versos - 1,
			arquitectura: tirada.arquitectura
		});
		verso += tirada.versos;
	}
	return secuencias;
}

function sembrarObra(obra, autores, sembrables, admin) {
	const secuencias = secuenciasDe(obra, sembrables);
	if (secuencias.length === 0) {
		console.log(`  ${obra.titulo}: sin secuencias, se salta`);
		return null;
	}
	const totalVersos = secuencias[secuencias.length - 1].v_fin;

	// **Los identificadores se generan aquí.** Cada llamada a la CLI abre su propia conexión y
	// tarda segundos, así que la obra entera —cabecera, jornadas, cuadros y autoría— va en un solo
	// guion; para eso hace falta saber los identificadores antes de escribirlos, en vez de pedirlos
	// de vuelta uno a uno.
	const obraId = crypto.randomUUID();
	const grupoId = crypto.randomUUID();
	const atribucionId = crypto.randomUUID();

	// Tres jornadas, y **todas con cuadros**: una jornada sin cuadros no existe.
	const corte = Math.floor(totalVersos / 3);
	const jornadas = [
		{ id: crypto.randomUUID(), numero: 1, v_ini: 1, v_fin: corte },
		{ id: crypto.randomUUID(), numero: 2, v_ini: corte + 1, v_fin: corte * 2 },
		{ id: crypto.randomUUID(), numero: 3, v_ini: corte * 2 + 1, v_fin: totalVersos }
	];

	const cuadros = [];
	for (const jornada of jornadas) {
		const cuantos = 2 + (jornada.numero % 2);
		const largo = Math.floor((jornada.v_fin - jornada.v_ini + 1) / cuantos);
		for (let numero = 1; numero <= cuantos; numero += 1) {
			cuadros.push({
				jornadaId: jornada.id,
				numero,
				v_ini: jornada.v_ini + largo * (numero - 1),
				v_fin: numero === cuantos ? jornada.v_fin : jornada.v_ini + largo * numero - 1
			});
		}
	}

	const cabecera = [
		`insert into public.obras (
			obra_id, titulo, titulo_normalizado, variantes_titulo, estado, genero_id, total_versos,
			visible_publico, edicion, bibliografia, observaciones,
			fecha_inicio_trad, fecha_fin_trad, fuente_fecha, slug
		 )
		 values (
			${lit(obraId)}::uuid,
			${lit(obra.titulo)},
			public.metadrama_slugify(${lit(obra.titulo)}),
			array[${lit(obra.titulo.replace(' (prueba)', '') + ', o el desengaño (prueba)')}]::text[],
			${lit(obra.estado === 'vista_previa' ? vocabulario.estado_vista_previa : vocabulario.estado_publicado)}::uuid,
			${lit(vocabulario.generos[obra.genero])}::uuid,
			${totalVersos},
			${obra.estado !== 'vista_previa' && obra.visible !== false},
			${lit(`Edición inventada para pruebas. ${lorem(1, 3)}`)},
			${lit(lorem(3, 1))},
			${lit(lorem(2, 4))},
			${obra.fecha[0]},
			${obra.fecha[1]},
			${lit('Datación inventada para pruebas.')},
			public.next_obras_slug(${lit(obra.titulo)}, null)
		 );`,
		...jornadas.map(
			(jornada) =>
				`insert into public.jornadas (jornada_id, obra_id, jornada_num, v_ini, v_fin)
				 values (${lit(jornada.id)}::uuid, ${lit(obraId)}::uuid, ${jornada.numero}, ${jornada.v_ini}, ${jornada.v_fin});`
		),
		...cuadros.map(
			(cuadro) =>
				`insert into public.cuadros (jornada_id, cuadro_num, v_ini, v_fin)
				 values (${lit(cuadro.jornadaId)}::uuid, ${cuadro.numero}, ${cuadro.v_ini}, ${cuadro.v_fin});`
		),
		`insert into public.grupos_atribucion (grupo_atribucion_id, obra_id)
		 values (${lit(grupoId)}::uuid, ${lit(obraId)}::uuid);`,
		`insert into public.atribuciones (atribucion_id, obra_id, tipo_atribucion_id, modalidad_atribucion_id, composicion_autoria_id, grupo_atribucion_id, perfil_metrico)
		 values (
			${lit(atribucionId)}::uuid, ${lit(obraId)}::uuid,
			${lit(vocabulario.tipo_tradicional)}::uuid,
			${lit(vocabulario.modalidad_unica)}::uuid,
			${lit(vocabulario.composicion_individual)}::uuid,
			${lit(grupoId)}::uuid,
			true
		 );`,
		`insert into public.atribucion_autores (atribucion_id, autor_id, orden)
		 values (${lit(atribucionId)}::uuid, ${lit(autores.get(obra.autor))}::uuid, 1);`
	].join('\n');

	const cabeceraEscrita = tryQuery(`begin;\n${cabecera}\ncommit;`);
	if (cabeceraEscrita.error) {
		console.log(`  ${obra.titulo}: no se pudo crear — ${cabeceraEscrita.error}`);
		return null;
	}

	// **Inaugurar espacio es abrir cuadro.** Antes lo marcaba la primera secuencia y nada más, que
	// no quiere decir nada; ahora coincide con los cortes que la ficha dibuja encima del barcode.
	const aperturas = new Set(cuadros.map((cuadro) => cuadro.v_ini));

	const fallos = [];
	const medidas = [];
	let anotadas = 0;
	for (const secuencia of secuencias) {
		const secuenciaId = crypto.randomUUID();
		const sentencias = [
			`insert into public.secuencias_metricas (secuencia_id, obra_id, v_ini, v_fin, n_versos, inaugura_espacio, versos_partidos, intervencion_personajes_femeninos, intervencion_figuras_donaire, intervencion_personajes_sobrenaturales, evento_sobrenatural, sinopsis)
			 values (
				${lit(secuenciaId)}::uuid, ${lit(obraId)}::uuid, ${secuencia.v_ini}, ${secuencia.v_fin}, ${secuencia.v_fin - secuencia.v_ini + 1},
				${aperturas.has(secuencia.v_ini)}, ${secuencia.orden % 4 === 0},
				${lit(secuencia.orden % 3 === 0 ? 'exclusiva' : 'compartida')},
				${lit(secuencia.orden % 5 === 0 ? 'compartida' : 'sin_intervencion')},
				${lit(secuencia.orden % 7 === 0 ? 'exclusiva' : 'sin_intervencion')},
				${secuencia.orden % 9 === 0},
				${lit(`Pasaje ${secuencia.orden}. ${lorem(2, secuencia.orden)}`)}
			 );`
		];

		// Una caracterización por rango cada tres secuencias, rotando las tres que se ofrecen.
		if (secuencia.orden % 3 === 1) {
			// `orden % 3 === 1` filtra las secuencias, así que `orden % 3` valdría siempre 1 y
			// saldría siempre la misma: la que rota es la cuenta de las que pasan el filtro.
			const termino = CARACTERIZACIONES[Math.floor(secuencia.orden / 3) % CARACTERIZACIONES.length];
			sentencias.push(`
				insert into public.secuencias_caracterizaciones_rango (secuencia_id, tipo_caracterizacion_rango_id, v_ini, v_fin, observaciones)
				values (
					${lit(secuenciaId)}::uuid,
					${lit(vocabulario.caracterizaciones[termino])}::uuid,
					${secuencia.v_ini}, ${Math.min(secuencia.v_ini + (secuencia.orden % 5) + 1, secuencia.v_fin)},
					'Anotado por la siembra de prueba.'
				);`);
		}

		const { unidades, problemas } = planDeRealizaciones(
			secuencia.arquitectura,
			secuencia.v_ini,
			secuencia.v_fin
		);
		const respuestas = planDeRespuestas(
			secuencia.arquitectura,
			unidades,
			secuencia.v_fin - secuencia.v_ini + 1,
			secuencia.orden
		);
		if (problemas.length > 0 || respuestas.problemas.length > 0) {
			// La secuencia se escribe igual: una secuencia sin anotar es un caso real, y la ficha
			// tiene que saber pintarla.
			const suelta = tryQuery(`begin;\n${sentencias.join('\n')}\ncommit;`);
			if (suelta.error) fallos.push(`${secuencia.arquitectura.forma}: ${suelta.error}`);
			else
				fallos.push(
					`${secuencia.arquitectura.forma}: ${[...problemas, ...respuestas.problemas].join('; ')}`
				);
			continue;
		}

		const desviaciones =
			secuencia.orden % 4 === 2
				? [
						{
							...DESVIACIONES[secuencia.orden % DESVIACIONES.length],
							realizacion_id: null,
							// Acotada al rango: una secuencia puede medir un solo verso —el verso
							// aislado— y la base comprueba que la desviación caiga dentro.
							v_ini: Math.min(secuencia.v_ini + (secuencia.orden % 7), secuencia.v_fin),
							v_fin: Math.min(secuencia.v_ini + (secuencia.orden % 7), secuencia.v_fin),
							metro_observado_id: null,
							esquema_rima_observado_id: null,
							seccion_observada_id: null,
							repeticion_observada_id: null,
							valor_rasgo_observado_id: null
						}
					]
				: [];

		const datos = {
			anotacion_id: null,
			escenario_id: null,
			secuencia_id: secuenciaId,
			orden: secuencia.orden,
			v_ini: secuencia.v_ini,
			v_fin: secuencia.v_fin,
			forma_id: secuencia.arquitectura.forma_id,
			arquitectura_id: secuencia.arquitectura.arquitectura_id,
			observaciones: null,
			unidades,
			elecciones: respuestas.elecciones,
			desviaciones
		};

		// **Todo lo de la secuencia va en la misma transacción**: la fila, su caracterización y la
		// anotación. Y con ellas la identidad prestada, porque `set_config(..., true)` vive hasta que
		// la transacción acaba y sin `auth.uid()` la función niega el permiso sobre la obra.
		const guion = `
			begin;
			select set_config('request.jwt.claims', json_build_object('sub', ${lit(admin)})::text, true);
			${sentencias.join('\n')}
			select public.guardar_anotacion_metrica(${lit(JSON.stringify(datos))}::jsonb);
			commit;
		`;
		medidas.push(
			`${secuencia.arquitectura.forma}: ${unidades.length} realizaciones, ${respuestas.elecciones.length} respuestas, ${guion.length} caracteres`
		);
		const guardado = tryQuery(guion);
		if (guardado.error) {
			fallos.push(
				`${secuencia.arquitectura.forma} · ${secuencia.arquitectura.arquitectura}: ${guardado.error}`
			);
			// **La secuencia se escribe igual.** Todo iba en la misma transacción, así que un
			// rechazo de la anotación se llevaba por delante la fila de la secuencia y dejaba a la
			// obra con un hueco de versos. Una secuencia sin anotar es un caso real —hoy lo son las
			// 276 del corpus— y la ficha tiene que saber pintarla.
			const suelta = tryQuery(`begin;\n${sentencias.join('\n')}\ncommit;`);
			if (suelta.error) fallos.push(`  y tampoco se pudo escribir la secuencia: ${suelta.error}`);
		} else {
			anotadas += 1;
		}
	}

	// **Lo que se dice escrito se cuenta.** Una transacción puede deshacerse sin que la CLI lo
	// cuente como error, y entonces la obra queda con menos secuencias de las que dice el registro:
	// se comprueba contra la base, que es la única que sabe lo que hay.
	const escritas = Number(
		scalar(`select count(*) from public.secuencias_metricas where obra_id = ${lit(obraId)}::uuid`)
	);
	const anotadasEnLaBase = Number(
		scalar(
			`select count(*) from public.anotaciones_metricas a join public.secuencias_metricas s using (secuencia_id) where s.obra_id = ${lit(obraId)}::uuid`
		)
	);

	console.log(
		`  ${obra.titulo}: ${escritas}/${secuencias.length} secuencias, ${anotadasEnLaBase} anotadas, ${totalVersos} versos`
	);
	if (escritas !== secuencias.length || anotadasEnLaBase !== escritas) {
		console.log(
			`      DESCUADRE: planeadas ${secuencias.length}, escritas ${escritas}, anotadas ${anotadasEnLaBase}`
		);
		for (const medida of medidas) console.log(`      ${medida}`);
	}
	for (const fallo of fallos) console.log(`      ${fallo}`);
	return { obraId, fallos };
}

// --------------------------------------------------------------------------

const opciones = process.argv.slice(2);
const catalogo = cargarCatalogo();

if (opciones.includes('--probe')) {
	sondar(catalogo);
	process.exit(0);
}

const admin = idDeUnAdmin();
const vocabulario = cargarVocabulario();
const sembrables = arquitecturasSembrables(catalogo);
console.log(`Arquitecturas que se siembran solas: ${sembrables.length}`);

limpiar();
const autores = sembrarAutores();
console.log(`Autores sembrados: ${autores.size}`);

for (const obra of OBRAS) {
	sembrarObra(obra, autores, sembrables, admin);
}

console.log('\nHecho. Las obras y los autores llevan «(prueba)» en el nombre.');
