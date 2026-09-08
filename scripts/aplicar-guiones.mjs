/**
 * Escribe en la base las obras de prueba que dicen los guiones.
 *
 * El guion —`xml-lope/guiones/`— es el pacto: qué obras hay, con qué jornadas y cuadros, y qué
 * lleva cada secuencia. Aquí no se decide nada, solo se ejecuta; si algo no sale como se quiere,
 * se corrige el guion y se vuelve a aplicar. Es idempotente: borra las obras de prueba anteriores
 * y las rehace.
 *
 * Lo único que el guion no dice es lo mecánico: cómo se reparten las realizaciones dentro de una
 * secuencia, y qué se escribe cuando una pregunta no ofrece repertorio. Eso se deduce del catálogo,
 * igual para todas las obras, y por eso no ensucia el guion.
 *
 *   node scripts/aplicar-guiones.mjs
 */
import fs from 'node:fs';
import path from 'node:path';
import { query, tryQuery } from './lib/consulta.mjs';

const RAIZ = path.resolve(import.meta.dirname, '..');
const GUIONES = path.join(RAIZ, 'xml-lope', 'guiones');

function lit(valor) {
	if (valor === null || valor === undefined) return 'null';
	return `'${String(valor).replaceAll("'", "''")}'`;
}

function scalar(sql) {
	const filas = query(sql);
	if (filas.length === 0) return null;
	return Object.values(filas[0])[0];
}

/**
 * Un admin cualquiera, para prestarle la identidad a la transacción.
 *
 * `guardar_anotacion_metrica` comprueba el permiso sobre la obra con `auth.uid()`, y un guion
 * ejecutado por la CLI no tiene sesión. El rol vive en `vocabularios`, no en una columna de texto.
 */
function idDeUnAdmin() {
	const id = scalar(`
		select e.user_id
		from public.editores e
		join public.vocabularios rol on rol.termino_id = e.role
		where lower(rol.termino) in ('admin', 'ip')
		order by e.created_at
		limit 1
	`);
	if (!id) {
		console.error('No hay ningún editor con rol admin o IP: sin identidad no se puede anotar.');
		process.exit(1);
	}
	return id;
}

/** Azar reproducible, para que dos aplicaciones del mismo guion escriban lo mismo. */
function azar(semilla) {
	let s = semilla >>> 0;
	return () => {
		s = (s + 0x6d2b79f5) >>> 0;
		let t = Math.imul(s ^ (s >>> 15), 1 | s);
		t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
		return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
	};
}

const semillaDe = (texto) => {
	let h = 2166136261;
	for (const c of texto) h = Math.imul(h ^ c.charCodeAt(0), 16777619);
	return h >>> 0;
};

// --------------------------------------------------------------------------
// El catálogo
// --------------------------------------------------------------------------

function cargarCatalogo() {
	const arquitecturas = query(`
		select
			a.arquitectura_id, a.slug as arquitectura, a.unidad_versos_min, a.unidad_versos_max,
			f.forma_id, f.slug as forma, r.modulo_versos
		from public.arquitecturas_forma a
		join public.formas_metricas f using (forma_id)
		left join public.arquitecturas_reglas_longitud r using (arquitectura_id)
		where a.activo and f.activo
	`);

	const secciones = query(`
		select
			s.seccion_id, s.arquitectura_id, s.seccion_padre_id, s.slug, s.nombre, s.orden,
			s.repeticiones_min, s.repeticiones_max, s.versos_min, s.versos_max
		from public.estructuras_secciones s
		order by s.arquitectura_id, s.orden
	`);

	const grupos = query(`
		select
			g.grupo_eleccion_id, g.arquitectura_id, g.nombre, g.dimension, g.alcance,
			g.seccion_id, g.seccion_tratada_id, g.selecciones_min, g.selecciones_max
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

	const porId = new Map();
	for (const a of arquitecturas) porId.set(a.arquitectura_id, { ...a, secciones: [], grupos: [] });
	for (const s of secciones) porId.get(s.arquitectura_id)?.secciones.push(s);
	const porGrupo = new Map();
	for (const g of grupos) {
		const a = porId.get(g.arquitectura_id);
		if (!a) continue;
		const entrada = { ...g, opciones: [] };
		a.grupos.push(entrada);
		porGrupo.set(g.grupo_eleccion_id, entrada);
	}
	for (const o of opciones) porGrupo.get(o.grupo_eleccion_id)?.opciones.push(o);

	const porNombre = new Map();
	for (const a of porId.values()) porNombre.set(`${a.forma}/${a.arquitectura}`, a);
	return porNombre;
}

function cargarVocabulario() {
	const termino = (categoria, valor) =>
		scalar(
			`select termino_id from public.vocabularios where categoria = ${lit(categoria)} and termino = ${lit(valor)} limit 1`
		);
	const generos = {};
	for (const fila of query(
		`select termino, termino_id from public.vocabularios where categoria = 'genero'`
	)) {
		generos[fila.termino] = fila.termino_id;
	}
	const caracterizaciones = {};
	for (const fila of query(
		`select termino, termino_id from public.vocabularios where categoria = 'caracterizacion_rango'`
	)) {
		caracterizaciones[fila.termino] = fila.termino_id;
	}
	return {
		generos,
		caracterizaciones,
		estado_publicado: termino('estado', 'publicado'),
		estado_vista_previa: termino('estado', 'vista_previa'),
		tipo_tradicional: termino('tipo_atribucion', 'tradicional'),
		modalidad_unica: termino('modalidad_atribucion', 'unica'),
		composicion_individual: termino('composicion_autoria', 'individual')
	};
}

// --------------------------------------------------------------------------
// Prosa de relleno
// --------------------------------------------------------------------------

const LOREM = [
	'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
	'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
	'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.',
	'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
	'Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium.',
	'Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores.'
];

const lorem = (frases, giro = 0) =>
	Array.from({ length: frases }, (_, i) => LOREM[(i + giro) % LOREM.length]).join(' ');

// --------------------------------------------------------------------------
// Realizaciones
// --------------------------------------------------------------------------

/**
 * Las realizaciones de una secuencia: la unidad, y dentro de ella sus partes.
 *
 * Es puro reparto aritmético, y por eso no está en el guion: la unidad mide lo que declara la
 * arquitectura —o el pasaje entero, si no declara nada—, y las partes se materializan tantas veces
 * como digan sus repeticiones. La que no tiene tope llena lo que sobra: es la cadena de tercetos
 * del terceto encadenado.
 *
 * **El orden es único en toda la anotación**, no dentro de cada unidad: la tabla lo declara
 * `unique (anotacion_id, orden)`.
 */
function realizacionesDe(arq, vIni, vFin) {
	const versosUnidad = Number(arq.unidad_versos_min ?? 0);
	const abierta = !versosUnidad;
	const paso = abierta ? vFin - vIni + 1 : versosUnidad;
	const raices = arq.secciones.filter((s) => s.seccion_padre_id === null);

	const vueltas = new Map();
	let ocupado = 0;
	for (const s of raices) {
		if (s.repeticiones_max === null) continue;
		const veces = Number(s.repeticiones_min);
		vueltas.set(s.seccion_id, veces);
		ocupado += veces * Number(s.versos_min || 0);
	}
	const sinTope = raices.filter((s) => s.repeticiones_max === null);
	if (sinTope.length === 1) {
		const resto = paso - ocupado;
		const veces = resto / Number(sinTope[0].versos_min);
		if (resto <= 0 || !Number.isInteger(veces)) {
			return { unidades: [], problema: `no cuadra la parte repetible en ${paso} versos` };
		}
		vueltas.set(sinTope[0].seccion_id, veces);
		ocupado += resto;
	}
	if (raices.length > 0 && ocupado !== paso) {
		return { unidades: [], problema: `las partes ocupan ${ocupado} y la unidad mide ${paso}` };
	}

	const unidades = [];
	let orden = 1;
	for (let inicio = vIni; inicio <= vFin; inicio += paso) {
		const unidad = {
			realizacion_id: crypto.randomUUID(),
			realizacion_padre_id: null,
			seccion_id: null,
			orden: orden++,
			v_ini: inicio,
			v_fin: inicio + paso - 1,
			etiqueta: null,
			observaciones: null
		};
		unidades.push(unidad);
		let cursor = inicio;
		for (const s of raices) {
			const versos = Number(s.versos_min);
			for (let vuelta = 0; vuelta < (vueltas.get(s.seccion_id) ?? 0); vuelta += 1) {
				unidades.push({
					realizacion_id: crypto.randomUUID(),
					realizacion_padre_id: unidad.realizacion_id,
					seccion_id: s.seccion_id,
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
	return { unidades, problema: null };
}

/**
 * Las realizaciones de las formas que crecen por ciclos, que el guion dice árbol abajo.
 *
 * Son la canción y el villancico: las únicas del catálogo **cuyas partes tienen partes dentro** —la
 * mudanza cuelga de la copla, no del ciclo; el pie del fronte, no de la estancia—, y ninguna regla
 * dice cuántos ciclos hay ni cuánto mide cada uno. La base lo comprueba: una sección raíz cuelga de
 * la unidad, y una sección interna de la realización de su sección superior.
 */
function realizacionesPorPartes(arq, vIni, partes) {
	const porSlug = new Map(arq.secciones.map((s) => [s.slug, s]));
	const unidades = [];
	let orden = 1;
	let problema = null;

	const largoDe = (nodo) =>
		nodo.partes ? nodo.partes.reduce((t, hijo) => t + largoDe(hijo), 0) : Number(nodo.versos);
	const total = partes.reduce((t, nodo) => t + largoDe(nodo), 0);

	const unidad = {
		realizacion_id: crypto.randomUUID(),
		realizacion_padre_id: null,
		seccion_id: null,
		orden: orden++,
		v_ini: vIni,
		v_fin: vIni + total - 1,
		etiqueta: null,
		observaciones: null
	};
	unidades.push(unidad);

	const materializar = (nodo, padre, desde) => {
		const seccion = porSlug.get(nodo.seccion);
		if (!seccion) {
			problema = `«${arq.forma}» no tiene parte «${nodo.seccion}»`;
			return desde;
		}
		const largo = largoDe(nodo);
		const suyo = {
			realizacion_id: crypto.randomUUID(),
			realizacion_padre_id: padre,
			seccion_id: seccion.seccion_id,
			orden: orden++,
			v_ini: desde,
			v_fin: desde + largo - 1,
			etiqueta: null,
			observaciones: null
		};
		unidades.push(suyo);
		let cursor = desde;
		for (const hijo of nodo.partes ?? []) cursor = materializar(hijo, suyo.realizacion_id, cursor);
		return desde + largo;
	};

	let cursor = vIni;
	for (const nodo of partes) cursor = materializar(nodo, unidad.realizacion_id, cursor);
	return problema ? { unidades: [], problema } : { unidades, problema: null };
}

// --------------------------------------------------------------------------
// Elecciones
// --------------------------------------------------------------------------

/** Un esquema escrito con una letra por verso, para las preguntas sin repertorio. */
function esquemaEscrito(versos) {
	const letras = 'abcdefgh';
	let escrito = '';
	for (let i = 0; i < versos; i += 1) escrito += letras[Math.floor(i / 2) % letras.length];
	return escrito;
}

/** Una medida escrita en cifras, una por verso: es como se anota un tramo sin forma. */
const medidaEscrita = (versos) =>
	Array.from({ length: versos }, (_, i) => (i % 2 === 0 ? '8' : '7')).join(' ');

/**
 * Las respuestas de una secuencia, expandidas desde lo que dice el guion.
 *
 * El guion habla en claro —«abba, salvo abab ×14»— y aquí se convierte en una fila por realización.
 * Las excepciones se reparten al azar entre las unidades, con la semilla de la secuencia para que
 * dos aplicaciones del mismo guion escriban exactamente lo mismo.
 *
 * Las preguntas que el guion no menciona son las que no ofrecen repertorio: se responden
 * escribiendo, que es lo que hace el editor, y por eso no hacía falta pactarlas una a una.
 */
function eleccionesDe(arq, seq, unidades, rnd) {
	const elecciones = [];
	const problemas = [];
	const raices = unidades.filter((u) => u.realizacion_padre_id === null);

	for (const g of arq.grupos) {
		const dichoEnUnidad = seq.unidad?.[g.nombre];
		const dichoEnSecuencia = seq.secuencia?.[g.nombre];
		const porNombre = new Map(g.opciones.map((o) => [o.nombre, o]));

		// Preguntas sin repertorio: se escribe la respuesta.
		if (g.opciones.length === 0) {
			if (Number(g.selecciones_min) === 0) continue;
			const destinos =
				g.alcance === 'secuencia'
					? [null]
					: unidades.filter((u) =>
							g.seccion_id === null ? u.realizacion_padre_id === null : u.seccion_id === g.seccion_id
						);
			for (const destino of destinos) {
				const versos = destino ? destino.v_fin - destino.v_ini + 1 : seq.versos;
				elecciones.push({
					realizacion_id: destino ? destino.realizacion_id : null,
					dimension: g.dimension,
					seccion_tratada_id: g.seccion_tratada_id ?? null,
					opcion_eleccion_id: null,
					valor_texto: g.dimension === 'metro' ? medidaEscrita(versos) : esquemaEscrito(versos),
					observaciones: null
				});
			}
			continue;
		}

		if (g.alcance === 'secuencia') {
			if (!dichoEnSecuencia) continue;
			const opcion = porNombre.get(dichoEnSecuencia);
			if (!opcion) {
				problemas.push(`«${dichoEnSecuencia}» no es una opción de «${g.nombre}»`);
				continue;
			}
			elecciones.push({
				realizacion_id: null,
				dimension: g.dimension,
				seccion_tratada_id: g.seccion_tratada_id ?? null,
				opcion_eleccion_id: opcion.opcion_eleccion_id,
				valor_texto: null,
				observaciones: null
			});
			continue;
		}

		if (g.alcance !== 'unidad' && g.alcance !== 'realizacion') continue;
		if (!dichoEnUnidad) continue;
		const destinos = unidades.filter((u) =>
			g.seccion_id === null ? u.realizacion_padre_id === null : u.seccion_id === g.seccion_id
		);
		if (destinos.length === 0) {
			problemas.push(`«${g.nombre}» no tiene ninguna realización donde caer`);
			continue;
		}

		// Una medida por posición del verso, o la misma en todas cuando la estrofa es isométrica.
		if (dichoEnUnidad.por_posicion || dichoEnUnidad.misma_en_todas) {
			for (const destino of destinos) {
				const nombres = dichoEnUnidad.por_posicion
					? Object.values(dichoEnUnidad.por_posicion)
					: g.opciones
							.filter((o) => o.nombre.endsWith(dichoEnUnidad.misma_en_todas))
							.map((o) => o.nombre);
				for (const nombre of nombres) {
					const opcion = porNombre.get(nombre);
					if (!opcion) {
						problemas.push(`«${nombre}» no es una opción de «${g.nombre}»`);
						continue;
					}
					// **Una posición que la realización no tiene no se responde.** Las partes de la
					// canción miden lo que quieran, así que una pregunta por posiciones puede ofrecer
					// más versos de los que ese pie tiene: la base lo rechaza, y con razón.
					if (
						opcion.posicion_unidad &&
						opcion.posicion_unidad > destino.v_fin - destino.v_ini + 1
					) {
						continue;
					}
					elecciones.push({
						realizacion_id: destino.realizacion_id,
						dimension: g.dimension,
						seccion_tratada_id: g.seccion_tratada_id ?? null,
						opcion_eleccion_id: opcion.opcion_eleccion_id,
						valor_texto: null,
						observaciones: null
					});
				}
			}
			continue;
		}

		// Dominante más excepciones: se sortea a qué unidades les toca salirse.
		const cuantas = destinos.length;
		const reparto = Array(cuantas).fill(dichoEnUnidad.dominante);
		const libres = [...reparto.keys()];
		for (const [nombre, veces] of Object.entries(dichoEnUnidad.excepciones ?? {})) {
			for (let i = 0; i < veces && libres.length > 0; i += 1) {
				const donde = libres.splice(Math.floor(rnd() * libres.length), 1)[0];
				reparto[donde] = nombre;
			}
		}
		for (const [indice, destino] of destinos.entries()) {
			const nombre = reparto[indice];
			if (!nombre) continue; // Una pregunta opcional que solo tiene excepciones.
			const opcion = porNombre.get(nombre);
			if (!opcion) {
				problemas.push(`«${nombre}» no es una opción de «${g.nombre}»`);
				continue;
			}
			elecciones.push({
				realizacion_id: destino.realizacion_id,
				dimension: g.dimension,
				seccion_tratada_id: g.seccion_tratada_id ?? null,
				opcion_eleccion_id: opcion.opcion_eleccion_id,
				valor_texto: null,
				observaciones: null
			});
		}
	}
	// `raices` solo se usa para saber si hay unidades donde colgar nada.
	if (raices.length === 0) problemas.push('la secuencia no tiene ninguna realización');
	return { elecciones, problemas };
}

// --------------------------------------------------------------------------
// La escritura
// --------------------------------------------------------------------------

const AUTORES = [
	{ clave: 'montalban', nombre: 'Juan Pérez de Montalbán', wikidata: 'Q3100564' },
	{ clave: 'benavente', nombre: 'Luis Quiñones de Benavente', wikidata: 'Q1876516' },
	{ clave: 'enciso', nombre: 'Diego Jiménez de Enciso', wikidata: 'Q5274715' },
	{ clave: 'cueva', nombre: 'Juan de la Cueva', wikidata: 'Q164964' }
];

function limpiar() {
	const wikidata = AUTORES.map((a) => lit(a.wikidata)).join(', ');
	query(`delete from public.obras where titulo like '%(prueba)'`);
	// Por Wikidata y no por nombre, y solo si no le queda ninguna obra: si alguno de estos autores
	// entra algún día en el corpus de verdad, una aplicación de guiones no se lo lleva por delante.
	query(`
		delete from public.autores a
		where a.wikidata_id in (${wikidata})
		  and not exists (select 1 from public.atribucion_autores aa where aa.autor_id = a.autor_id)
	`);
}

function sembrarAutores() {
	const porClave = new Map();
	for (const autor of AUTORES) {
		const existente = scalar(
			`select autor_id from public.autores where wikidata_id = ${lit(autor.wikidata)} limit 1`
		);
		porClave.set(
			autor.clave,
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
				`)
		);
	}
	return porClave;
}

function aplicar(guion, autores, catalogo, vocabulario, admin) {
	const obraId = crypto.randomUUID();
	const grupoId = crypto.randomUUID();
	const atribucionId = crypto.randomUUID();
	const titulo = guion.obra.titulo;
	const jornadaIds = new Map(guion.jornadas.map((j) => [j.numero, crypto.randomUUID()]));

	const cabecera = [
		`insert into public.obras (
			obra_id, titulo, titulo_normalizado, variantes_titulo, estado, genero_id, total_versos,
			visible_publico, edicion, bibliografia, observaciones,
			fecha_inicio_trad, fecha_fin_trad, fuente_fecha, slug
		 )
		 values (
			${lit(obraId)}::uuid, ${lit(titulo)}, public.metadrama_slugify(${lit(titulo)}),
			array[${lit(`${titulo.replace(' (prueba)', '')}, o el desengaño (prueba)`)}]::text[],
			${lit(vocabulario.estado_publicado)}::uuid,
			${lit(vocabulario.generos[guion.obra.genero])}::uuid,
			${guion.obra.total_versos},
			true,
			${lit(`Edición inventada para pruebas. ${lorem(1, 3)}`)},
			${lit(lorem(3, 1))},
			${lit(lorem(2, 4))},
			${guion.obra.fecha[0]}, ${guion.obra.fecha[1]},
			${lit('Datación inventada para pruebas.')},
			public.next_obras_slug(${lit(titulo)}, null)
		 );`,
		...guion.jornadas.map(
			(j) =>
				`insert into public.jornadas (jornada_id, obra_id, jornada_num, v_ini, v_fin)
				 values (${lit(jornadaIds.get(j.numero))}::uuid, ${lit(obraId)}::uuid, ${j.numero}, ${j.v_ini}, ${j.v_fin});`
		),
		...guion.cuadros.map(
			(c) =>
				`insert into public.cuadros (jornada_id, cuadro_num, v_ini, v_fin)
				 values (${lit(jornadaIds.get(c.jornada))}::uuid, ${c.numero}, ${c.v_ini}, ${c.v_fin});`
		),
		`insert into public.grupos_atribucion (grupo_atribucion_id, obra_id)
		 values (${lit(grupoId)}::uuid, ${lit(obraId)}::uuid);`,
		`insert into public.atribuciones (atribucion_id, obra_id, tipo_atribucion_id, modalidad_atribucion_id, composicion_autoria_id, grupo_atribucion_id, perfil_metrico)
		 values (${lit(atribucionId)}::uuid, ${lit(obraId)}::uuid, ${lit(vocabulario.tipo_tradicional)}::uuid,
			${lit(vocabulario.modalidad_unica)}::uuid, ${lit(vocabulario.composicion_individual)}::uuid,
			${lit(grupoId)}::uuid, true);`,
		`insert into public.atribucion_autores (atribucion_id, autor_id, orden)
		 values (${lit(atribucionId)}::uuid, ${lit(autores.get(guion.obra.autor.clave))}::uuid, 1);`
	].join('\n');

	const escrita = tryQuery(`begin;\n${cabecera}\ncommit;`);
	if (escrita.error) {
		console.log(`  ${titulo}: no se pudo crear — ${escrita.error}`);
		return { fallos: [escrita.error] };
	}

	const aperturas = new Set(guion.cuadros.map((c) => c.v_ini));
	const fallos = [];
	/**
	 * El guion de cada secuencia, para mandarlos **todos juntos y solo uno a uno si algo falla**.
	 *
	 * Cada llamada a la CLI abre su propia conexión y tarda un par de segundos: cuatrocientas
	 * setenta secuencias de una en una son hora y media. La obra entera va en una transacción, y
	 * cuando esa transacción se rompe se repite secuencia por secuencia para saber cuál fue y
	 * salvar las demás.
	 */
	const guiones = [];

	for (const seq of guion.secuencias) {
		const secuenciaId = crypto.randomUUID();
		const rnd = azar(semillaDe(`${titulo}#${seq.orden}`));
		const sentencias = [
			`insert into public.secuencias_metricas (secuencia_id, obra_id, v_ini, v_fin, n_versos, inaugura_espacio, versos_partidos, intervencion_personajes_femeninos, intervencion_figuras_donaire, intervencion_personajes_sobrenaturales, evento_sobrenatural, sinopsis)
			 values (
				${lit(secuenciaId)}::uuid, ${lit(obraId)}::uuid, ${seq.v_ini}, ${seq.v_fin}, ${seq.versos},
				${aperturas.has(seq.v_ini)}, ${seq.orden % 4 === 0},
				${lit(seq.orden % 3 === 0 ? 'exclusiva' : 'compartida')},
				${lit(seq.orden % 5 === 0 ? 'compartida' : 'sin_intervencion')},
				${lit(seq.orden % 7 === 0 ? 'exclusiva' : 'sin_intervencion')},
				${seq.orden % 9 === 0},
				${lit(`Pasaje ${seq.orden}. ${lorem(2, seq.orden)}`)}
			 );`,
			...(seq.caracterizaciones ?? []).map(
				(c) =>
					`insert into public.secuencias_caracterizaciones_rango (secuencia_id, tipo_caracterizacion_rango_id, v_ini, v_fin, observaciones)
					 values (${lit(secuenciaId)}::uuid, ${lit(vocabulario.caracterizaciones[c.tipo])}::uuid, ${c.v_ini}, ${c.v_fin}, ${lit(c.observaciones)});`
			)
		];

		const arq = seq.forma ? catalogo.get(`${seq.forma}/${seq.arquitectura}`) : null;
		if (!arq) {
			// Una secuencia sin forma se escribe igual, sin anotación: es un caso real.
			guiones.push({ orden: seq.orden, sql: sentencias.join('\n'), quien: 'sin forma' });
			continue;
		}

		const { unidades, problema } = seq.partes
			? realizacionesPorPartes(arq, seq.v_ini, seq.partes)
			: realizacionesDe(arq, seq.v_ini, seq.v_fin);
		const { elecciones, problemas } = unidades.length
			? eleccionesDe(arq, seq, unidades, rnd)
			: { elecciones: [], problemas: [] };

		if (problema || problemas.length > 0) {
			// La secuencia se escribe igual, sin anotación: una secuencia sin anotar es un caso real
			// y la ficha tiene que saber pintarla.
			guiones.push({ orden: seq.orden, sql: sentencias.join('\n'), quien: seq.forma });
			fallos.push(
				`secuencia ${seq.orden} (${seq.forma}): ${[problema, ...problemas].filter(Boolean).join('; ')}`
			);
			continue;
		}

		const datos = {
			anotacion_id: null,
			escenario_id: null,
			secuencia_id: secuenciaId,
			orden: seq.orden,
			v_ini: seq.v_ini,
			v_fin: seq.v_fin,
			forma_id: arq.forma_id,
			arquitectura_id: arq.arquitectura_id,
			observaciones: null,
			unidades,
			elecciones,
			desviaciones: (seq.desviaciones ?? []).map((d) => ({
				realizacion_id: null,
				dimension: d.dimension,
				relacion_norma: d.relacion_norma,
				v_ini: d.v_ini,
				v_fin: d.v_fin,
				observaciones: d.observaciones,
				metro_observado_id: null,
				esquema_rima_observado_id: null,
				seccion_observada_id: null,
				repeticion_observada_id: null,
				valor_rasgo_observado_id: null
			}))
		};

		guiones.push({
			orden: seq.orden,
			quien: `${seq.forma}/${seq.arquitectura}`,
			sql: `${sentencias.join('\n')}\nselect public.guardar_anotacion_metrica(${lit(JSON.stringify(datos))}::jsonb);`,
			sinAnotar: sentencias.join('\n')
		});
	}

	// **La identidad prestada acompaña siempre.** `set_config(..., true)` vive hasta que la
	// transacción acaba, y sin `auth.uid()` la función niega el permiso sobre la obra.
	const identidad = `select set_config('request.jwt.claims', json_build_object('sub', ${lit(admin)})::text, true);`;
	const deUnaVez = tryQuery(
		`begin;\n${identidad}\n${guiones.map((g) => g.sql).join('\n')}\ncommit;`
	);
	if (deUnaVez.error) {
		for (const g of guiones) {
			const suelto = tryQuery(`begin;\n${identidad}\n${g.sql}\ncommit;`);
			if (!suelto.error) continue;
			fallos.push(`secuencia ${g.orden} (${g.quien}): ${suelto.error}`);
			if (!g.sinAnotar) continue;
			const suelta = tryQuery(`begin;\n${g.sinAnotar}\ncommit;`);
			if (suelta.error) fallos.push(`  y tampoco se escribió la secuencia: ${suelta.error}`);
		}
	}

	// **Lo que se dice escrito se cuenta contra la base.** Una transacción puede deshacerse sin que
	// la CLI lo cuente como error, y entonces la obra queda con menos secuencias de las que dice el
	// registro.
	const escritas = Number(
		scalar(`select count(*) from public.secuencias_metricas where obra_id = ${lit(obraId)}::uuid`)
	);
	const anotadas = Number(
		scalar(`select count(*)
			from public.anotaciones_metricas a
			join public.secuencias_metricas s using (secuencia_id)
			where s.obra_id = ${lit(obraId)}::uuid`)
	);
	const conForma = guion.secuencias.filter((s) => s.forma).length;
	console.log(
		`  ${titulo.padEnd(38)} ${escritas}/${guion.secuencias.length} secuencias · ${anotadas}/${conForma} anotadas · ${guion.obra.total_versos} versos`
	);
	if (escritas !== guion.secuencias.length || anotadas !== conForma) {
		console.log(`      DESCUADRE: se esperaban ${guion.secuencias.length} y ${conForma}`);
	}
	for (const fallo of fallos) console.log(`      ${fallo}`);
	return { obraId, fallos };
}

// --------------------------------------------------------------------------

const catalogo = cargarCatalogo();
const vocabulario = cargarVocabulario();
const admin = idDeUnAdmin();

console.log('Borrando las obras de prueba anteriores…');
limpiar();
const autores = sembrarAutores();

const guiones = fs
	.readdirSync(GUIONES)
	.filter((f) => f.endsWith('.json'))
	.map((f) => JSON.parse(fs.readFileSync(path.join(GUIONES, f), 'utf8')));

console.log(`Aplicando ${guiones.length} guiones…`);
let fallos = 0;
for (const guion of guiones) {
	const resultado = aplicar(guion, autores, catalogo, vocabulario, admin);
	fallos += resultado.fallos.length;
}

console.log('\nRecalculando los datos públicos…');
query('select public.recompute_all();');
console.log(fallos === 0 ? 'Sin errores.' : `${fallos} errores.`);
