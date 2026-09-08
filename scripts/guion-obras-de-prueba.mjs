/**
 * Escribe el guion de cada obra de prueba, **sin tocar la base**.
 *
 * Un guion es lo que se va a anotar dicho en claro: jornadas, cuadros, y una línea por secuencia
 * con su forma, su arquitectura y lo que se responde. Se mira, se corrige y solo entonces se
 * aplica. Antes el generador escribía directamente en la base y cada vuelta costaba tres cuartos
 * de hora; separar el plan de la escritura hace que revisar cueste segundos.
 *
 * El esqueleto —cuántas secuencias, de qué forma, de cuántos versos y dónde cortan las jornadas—
 * **sale de comedias reales de ARTELOPE** (`xml-lope/esqueletos/`), porque es justo lo que se me
 * daba mal inventar: el reparto de formas, la longitud de las tiradas y que ninguna pise el final
 * de una jornada. Lo que ARTELOPE no tiene —arquitectura, esquema de rima, asonancia, rasgos— se
 * sortea del catálogo respetando lo que el propio catálogo declara.
 *
 *   node scripts/guion-obras-de-prueba.mjs
 */
import fs from 'node:fs';
import path from 'node:path';
import { query } from './lib/consulta.mjs';

const RAIZ = path.resolve(import.meta.dirname, '..');
const ESQUELETOS = path.join(RAIZ, 'xml-lope', 'esqueletos');
const SALIDA = path.join(RAIZ, 'xml-lope', 'guiones');

/**
 * Las diez obras: un esqueleto real cada una, con título, autor y fecha inventados.
 *
 * Los títulos son de mentira a propósito. El esqueleto queda anotado para poder rehacer el guion,
 * pero nada de la obra real —ni su título, ni su autor, ni su texto— llega a la base.
 */
const OBRAS = [
	{ esqueleto: 'AL2019', titulo: 'La ciudad de los prodigios (prueba)', autor: 'montalban', genero: 'comedia_o_tragicomedia', fecha: [1604, 1608] },
	{ esqueleto: 'AL0787', titulo: 'El padrino burlado (prueba)', autor: 'montalban', genero: 'comedia_o_tragicomedia', fecha: [1610, 1612] },
	{ esqueleto: 'AL0849', titulo: 'El remedio en la fortuna (prueba)', autor: 'montalban', genero: 'comedia_o_tragicomedia', fecha: [1599, 1603] },
	{ esqueleto: 'AL0723', titulo: 'La monja de Ávila (prueba)', autor: 'benavente', genero: 'comedia_o_tragicomedia', fecha: [1614, 1618] },
	{ esqueleto: 'AL0762', titulo: 'Nadie se conoce a sí mismo (prueba)', autor: 'benavente', genero: 'comedia_o_tragicomedia', fecha: [1606, 1609] },
	{ esqueleto: 'AL0853', titulo: 'La Roma encendida (prueba)', autor: 'benavente', genero: 'tragedia', fecha: [1598, 1600] },
	{ esqueleto: 'AL2020', titulo: 'El rey perseguido (prueba)', autor: 'enciso', genero: 'tragedia', fecha: [1615, 1620] },
	{ esqueleto: 'AL0519', titulo: 'Las batuecas del duque (prueba)', autor: 'enciso', genero: 'comedia_o_tragicomedia', fecha: [1600, 1605] },
	{ esqueleto: 'AL0683', titulo: 'La imperial de Otón (prueba)', autor: 'cueva', genero: 'comedia_o_tragicomedia', fecha: [1596, 1599] },
	{ esqueleto: 'AL0655', titulo: 'El guante de doña Blanca (prueba)', autor: 'cueva', genero: 'comedia_o_tragicomedia', fecha: [1607, 1611] },
	// **Las dos raras.** Diez comedias corrientes se parecen mucho entre sí —eso es lo normal—, y
	// dejan sin ejercitar lo que solo pasa de vez en cuando. Estas dos traen lo que a las otras les
	// falta: una sextina, un villancico, versos cantados, un pasaje en prosa y unas desviaciones.
	{ esqueleto: 'AL0729', titulo: 'El marqués desdichado (prueba)', autor: 'cueva', genero: 'comedia_o_tragicomedia', fecha: [1593, 1598] },
	{ esqueleto: 'AL0634', titulo: 'Lo fingido y lo cierto (prueba)', autor: 'enciso', genero: 'comedia_o_tragicomedia', fecha: [1608, 1612] }
];

/**
 * Lo que se le añade a mano a las dos obras raras.
 *
 * Nada de esto sale de ARTELOPE, que solo etiqueta la estrofa: **el villancico no aparece en
 * ninguna de las 365 comedias del repositorio** —ni él ni el zéjel—, y las caracterizaciones y las
 * desviaciones son cosa nuestra. Se ponen aquí, contadas una a una, porque el objeto de estas dos
 * obras es justamente que la precomputación y la ficha se topen con ellas.
 *
 * Las desviaciones van en los casos de verdad frecuentes: el verso corto o largo de más en una
 * tirada, la laguna donde el testimonio ha perdido versos, y una rima que no está en el repertorio.
 */
const EXTRAS = {
	AL0729: {
		caracterizaciones: [
			{ forma: 'romance', ocurrencia: 2, tipo: 'cantado', versos: 16, nota: 'Romance cantado por músicos dentro.' }
		],
		desviaciones: [
			{ forma: 'redondilla', ocurrencia: 3, dimension: 'metro', relacion_norma: 'menor_que_norma', versos: 1, nota: 'Un verso hipométrico.' },
			{ forma: 'quintilla', ocurrencia: 4, dimension: 'estructura', relacion_norma: 'falta', versos: 2, nota: 'Laguna: el testimonio ha perdido dos versos.' }
		]
	},
	AL0634: {
		// El villancico sustituye a una seguidilla o a un pasaje breve: se declara entero, ciclo a
		// ciclo, porque es la única forma del catálogo cuyas partes tienen partes dentro.
		villancico: {
			ocurrencia: 1,
			forma_sustituida: 'copla_de_arte_menor',
			arquitectura: 'estribillo_tras_primera_copla',
			ciclos: [
				{ mudanza: 4, copla: 4, enlace: 1, estribillo: 3, vuelta: 1 },
				{ mudanza: 4, copla: 4, estribillo: 3 },
				{ mudanza: 4, copla: 3, estribillo: 3 }
			]
		},
		caracterizaciones: [
			{ villancico: true, tipo: 'cantado', nota: 'El villancico lo cantan los músicos.' },
			{ forma: 'redondilla', ocurrencia: 5, tipo: 'prosa', versos: 6, nota: 'Pasaje en prosa dentro de la escena.' }
		],
		desviaciones: [
			{ forma: 'octava_real', ocurrencia: 2, dimension: 'rima', relacion_norma: 'otra', versos: 8, nota: 'Una octava con rima distinta de la del repertorio.' },
			{ forma: 'romance', ocurrencia: 4, dimension: 'metro', relacion_norma: 'mayor_que_norma', versos: 1, nota: 'Un verso hipermétrico.' }
		]
	}
};

const AUTORES = [
	{ clave: 'montalban', nombre: 'Juan Pérez de Montalbán', wikidata: 'Q3100564' },
	{ clave: 'benavente', nombre: 'Luis Quiñones de Benavente', wikidata: 'Q1876516' },
	{ clave: 'enciso', nombre: 'Diego Jiménez de Enciso', wikidata: 'Q5274715' },
	{ clave: 'cueva', nombre: 'Juan de la Cueva', wikidata: 'Q164964' }
];

/**
 * Del vocabulario de ARTELOPE al catálogo.
 *
 * ARTELOPE nombra la forma y nada más: dice «redondilla», no «octosilábica». La arquitectura la
 * ponemos nosotros, y va la habitual en la comedia salvo donde el número de versos mande otra cosa.
 * Un valor `null` significa que ese pasaje no se afirma como forma: va a tramo sin forma.
 */
/**
 * Los pasajes que ARTELOPE deja sin clasificar y hemos mirado uno a uno.
 *
 * `copla_estructura_abierta` y `pareados` son sus cajones de sastre, y por el número de versos no
 * se puede adivinar qué hay dentro. Estos cinco se han contado en el texto: se anotan por el verso
 * que ocupan en la obra real, antes de que el guion recosa los rangos.
 */
const AJUSTES = {
	// Veintidós hexasílabos cantados: eso es un romancillo, que es como el catálogo llama al
	// romance hexasilábico. Van cantados, y por ahí entra el primer «cantado» de la serie.
	AL0519: [{ desde: 1854, forma: 'romance', arquitectura: 'hexasilabica', cantado: true }],
	AL0723: [
		// Un heptasílabo y un endecasílabo: el pareado alirado, que es la única arquitectura del
		// pareado que mide distinto en cada verso. Se canta, y sigue cantándose lo que viene después.
		{ desde: 2660, forma: 'pareado', arquitectura: 'alirado', medida: ['Heptasílabo', 'Endecasílabo'], cantado: true, arrastra: true },
		{ desde: 2678, forma: 'pareado', arquitectura: 'cualquier_medida', medida: 'Octosílabo' }
	],
	AL0787: [
		{ desde: 235, forma: 'pareado', arquitectura: 'cualquier_medida', medida: 'Octosílabo' },
		{ desde: 1243, forma: 'pareado', arquitectura: 'cualquier_medida', medida: 'Octosílabo' }
	]
};

const MAPA = {
	redondilla: ['redondilla', 'octosilabica'],
	cuarteta: ['redondilla', 'octosilabica'],
	romance_tirada: ['romance', 'octosilabica'],
	// **Romancillo y endecha son lo mismo, y no son la endecha real.** El romancillo hexasílabo es
	// romance de seis sílabas; la endecha real mezcla heptasílabos con un endecasílabo final.
	romancillo_o_endecha: ['romance', 'hexasilabica'],
	quintilla: ['quintilla', 'octosilabica_consonante'],
	decima: ['decima', 'espinela'],
	octava_real: ['octava_real', 'endecasilabica_consonante'],
	soneto: ['soneto', 'endecasilabica_consonante'],
	endecasilabos_sueltos_tirada: ['endecasilabo_suelto', 'endecasilabica'],
	silva_tirada: ['silva', 'consonante_irregular'],
	lira: ['lira', 'heptasilabica_endecasilabica'],
	sexteto_lira: ['sexteto_lira', 'heterometrica_consonante'],
	// **El «terceto» de la comedia es terceto encadenado.** Se ve en los propios largos: 39, 55, 58
	// y 160 versos, que son cadenas de tercetos con —o sin— el serventesio de cierre.
	terceto: ['terceto_encadenado', 'endecasilabica_consonante'],
	// Lo normal es que sean la canción regular y ARTELOPE las haya llamado de dos maneras.
	cancion: ['cancion_petrarquista', 'estancias_consonantes_variables'],
	cancion_canzone: ['cancion_petrarquista', 'estancias_consonantes_variables'],
	sestina: ['sextina', 'clasica'],
	seguidilla: ['seguidilla', 'simple'],
	sextilla_de_pie_quebrado: ['sextilla', 'pie_quebrado'],
	cuarteta_asonantada: ['redondilla', 'octosilabica'],
	// **El pareado mide igual en sus dos versos**, y ARTELOPE dice cuál en la propia etiqueta salvo
	// en `pareados` a secas, donde va el octosílabo por ser el metro del entorno en que aparecen.
	pareados: ['pareado', 'cualquier_medida', 'Octosílabo'],
	pareados_endecasilabos: ['pareado', 'cualquier_medida', 'Endecasílabo'],
	pareado_hexasilabo: ['pareado', 'cualquier_medida', 'Hexasílabo'],
	// Un verso solo entre dos formas no es un pasaje sin clasificar: es verso aislado, que el
	// catálogo registra como tal.
	verso_suelto: ['verso_aislado', 'cualquier_medida'],
	_solo_sangrado_: null,
	null: null
};

/**
 * La copla que ARTELOPE deja sin clasificar se elige por el número de versos.
 *
 * `copla_estructura_abierta` es su cajón de sastre: pasajes estróficos que no encajaron en ninguna
 * etiqueta. Como son obras de prueba, basta con que la forma quepa: se toma la que divide exacto.
 */
function coplaPorLargo(versos) {
	if (versos % 10 === 0) return ['copla_real', 'octosilabica_consonante'];
	if (versos % 8 === 0) return ['copla_de_arte_menor', 'octosilabica'];
	if (versos % 6 === 0) return ['sextilla', 'octosilabica'];
	if (versos % 5 === 0) return ['quintilla', 'octosilabica_consonante'];
	if (versos % 4 === 0) return ['redondilla', 'octosilabica'];
	if (versos % 2 === 0) return ['pareado', 'cualquier_medida', 'Octosílabo'];
	return null;
}

/** Azar reproducible: el mismo guion sale igual mañana. */
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

function cargarCatalogo() {
	const arquitecturas = query(`
		select
			a.arquitectura_id, a.slug as arquitectura, a.unidad_versos_min, a.unidad_versos_max,
			f.slug as forma, f.nombre as forma_nombre, a.nombre as arquitectura_nombre,
			r.modulo_versos, r.minimo_versos
		from public.arquitecturas_forma a
		join public.formas_metricas f using (forma_id)
		left join public.arquitecturas_reglas_longitud r using (arquitectura_id)
		where a.activo and f.activo
	`);

	const grupos = query(`
		select
			g.grupo_eleccion_id, g.arquitectura_id, g.nombre, g.dimension, g.alcance,
			g.selecciones_min, g.selecciones_max, g.permite_aplicar_global
		from public.grupos_eleccion_metrica_resueltos g
		where g.activo
		order by g.arquitectura_id, g.orden
	`);

	// **La frecuencia de cada opción viene del catálogo.** `esquemas_rima.modalidad` dice si una
	// disposición es habitual, admitida o excepcional; sortear con ese peso es lo que separa una
	// tirada de quintillas creíble de una que va rotando por las ocho.
	const opciones = query(`
		select
			o.opcion_eleccion_id, o.grupo_eleccion_id, o.nombre, o.orden, o.posicion_unidad,
			coalesce(er.modalidad, 'admitida') as modalidad
		from public.opciones_eleccion_metrica o
		left join public.esquemas_rima er on er.esquema_rima_id = o.esquema_rima_id
		where o.activo
		order by o.grupo_eleccion_id, o.orden
	`);

	const porArquitectura = new Map();
	for (const a of arquitecturas) porArquitectura.set(a.arquitectura_id, { ...a, grupos: [] });
	const porGrupo = new Map();
	for (const g of grupos) {
		const a = porArquitectura.get(g.arquitectura_id);
		if (!a) continue;
		const entrada = { ...g, opciones: [] };
		a.grupos.push(entrada);
		porGrupo.set(g.grupo_eleccion_id, entrada);
	}
	for (const o of opciones) porGrupo.get(o.grupo_eleccion_id)?.opciones.push(o);

	const porNombre = new Map();
	for (const a of porArquitectura.values()) porNombre.set(`${a.forma}/${a.arquitectura}`, a);
	return porNombre;
}

/** Cuánto ocupa una unidad: lo que declara, o el módulo de su regla de longitud. */
const pasoDe = (a) => Number(a.unidad_versos_min ?? 0) || Number(a.modulo_versos ?? 0) || 1;

const PESO = { habitual: 60, definitoria: 40, admitida: 12, excepcional: 2 };

/**
 * Con qué asonancia se hace un romance.
 *
 * Las veinte del catálogo no se usan por igual, y no es cuestión de gusto: **rimar en aguda obliga
 * a que todos los versos pares acaben en palabra aguda**, que en castellano son las menos, mientras
 * que las llanas en `-a` y en `-o` tienen detrás medio diccionario. De ahí que `é-o` y `á-a` sean
 * las asonancias corrientes de la comedia, que las agudas aparezcan de vez en cuando y en pasajes
 * cortos, y que la `u` tónica sea casi imposible. Sortear las veinte a partes iguales llenaba las
 * obras de romances agudos.
 */
const ASONANCIA = {
	'e-o': 100, 'a-a': 95, 'e-a': 85, 'a-o': 80, 'o-a': 70, 'i-a': 55, 'e-e': 50,
	'a-e': 45, 'o-e': 35, 'i-o': 30, 'o-o': 25, 'i-e': 20, 'u-a': 4, 'u-e': 3, 'u-o': 3,
	a: 18, e: 16, o: 12, i: 4, u: 1
};

/**
 * Lo que la modalidad del catálogo no dice: **cuál se usa más en la comedia**.
 *
 * `modalidad` responde a si una disposición está admitida en la forma, no a con qué frecuencia
 * aparece en el teatro. Las dos redondillas están «admitidas» por igual y sin embargo la comedia
 * es abrazada casi siempre; sortear a partes iguales daba mitad y mitad. Solo se corrige donde la
 * diferencia es notoria: en lo demás manda el catálogo.
 */
const FRECUENCIA_COMEDIA = {
	'Abrazada · abba': 85,
	'Cruzada · abab': 8
};

function sortea(opciones, rnd) {
	const peso = (o) =>
		ASONANCIA[o.nombre] ?? FRECUENCIA_COMEDIA[o.nombre] ?? PESO[o.modalidad] ?? 10;
	const total = opciones.reduce((t, o) => t + peso(o), 0);
	let corte = rnd() * total;
	for (const o of opciones) {
		corte -= peso(o);
		if (corte <= 0) return o;
	}
	return opciones[opciones.length - 1];
}

/**
 * Lo que se responde en una secuencia.
 *
 * El catálogo declara el **alcance** de cada pregunta, y es lo que manda:
 *
 * - `secuencia`: una respuesta para toda la tirada. Es la asonancia del romance —una para el
 *   romance entero—, la densidad de rima de la silva, el final acentual.
 * - `unidad`: una respuesta por estrofa. Aquí no vale rotar: una tirada de quintillas tiene **una
 *   disposición dominante y unas pocas unidades que se salen**, que es lo que se lee en las obras
 *   ya anotadas —`ababa` 32, `aabba` 17, `abaab` 3— y no ocho esquemas a partes iguales.
 *
 * Y una pregunta que admite cero respuestas casi siempre se queda sin responder: el pie quebrado
 * de una redondilla es excepcional, y la siembra anterior lo marcaba en todas.
 */
function respuestas(arq, unidades, rnd, medida) {
	const secuencia = {};
	const unidad = {};
	for (const g of arq.grupos) {
		if (g.opciones.length === 0) continue;
		const obligatoria = Number(g.selecciones_min) > 0;
		if (g.alcance === 'secuencia') {
			if (!obligatoria && rnd() > 0.18) continue;
			secuencia[g.nombre] = sortea(g.opciones, rnd).nombre;
			continue;
		}
		if (g.alcance !== 'unidad') continue;
		if (!obligatoria) {
			// **El pie quebrado es rarísimo.** Está admitido en la redondilla y en la quintilla, y por
			// eso el editor lo pregunta, pero en una comedia entera puede no aparecer ni una vez. La
			// siembra anterior lo marcaba en una de cada seis secuencias, que era un disparate.
			if (rnd() > 0.02) continue;
			unidad[g.nombre] = { dominante: null, excepciones: { [sortea(g.opciones, rnd).nombre]: 1 } };
			continue;
		}
		// Cuando las opciones van por posición dentro de la estrofa —los cuartetos y los tercetos del
		// soneto, la medida de cada verso—, se responde una por posición.
		const posiciones = [...new Set(g.opciones.map((o) => o.posicion_unidad ?? 0))].sort();
		if (posiciones.length > 1) {
			// **Y si todas las posiciones ofrecen las mismas medidas, es que la estrofa es isométrica**
			// y hay que responder la misma en todas: los dos versos de un pareado miden lo mismo. En
			// una estrofa alirada, en cambio, cada posición ofrece la suya y se responde una a una.
			const sufijo = (o) => o.nombre.replace(/^Verso \d+ · /, '');
			const repertorios = posiciones.map((p) =>
				g.opciones
					.filter((o) => (o.posicion_unidad ?? 0) === p)
					.map(sufijo)
					.sort()
					.join('|')
			);
			// **Y una medida dicha verso a verso manda sobre la heurística.** El pareado alirado ofrece
			// heptasílabo o endecasílabo en sus dos posiciones, así que parece isométrico y no lo es:
			// mide 7 + 11, que es lo que lo define. Cuando el pasaje se ha mirado en el texto, la
			// medida viene ya dada y no hay nada que deducir.
			const isometrica =
				!Array.isArray(medida) && new Set(repertorios).size === 1 && repertorios[0].includes('|');
			if (Array.isArray(medida)) {
				unidad[g.nombre] = {
					por_posicion: Object.fromEntries(posiciones.map((p, i) => [p, `Verso ${p} · ${medida[i]}`]))
				};
			} else if (isometrica) {
				const elegida =
					medida && repertorios[0].split('|').includes(medida)
						? medida
						: sufijo(sortea(g.opciones.filter((o) => (o.posicion_unidad ?? 0) === posiciones[0]), rnd));
				unidad[g.nombre] = { misma_en_todas: elegida, posiciones: posiciones.length };
			} else {
				unidad[g.nombre] = {
					por_posicion: Object.fromEntries(
						posiciones.map((p) => [
							p,
							sortea(g.opciones.filter((o) => (o.posicion_unidad ?? 0) === p), rnd).nombre
						])
					)
				};
			}
			continue;
		}
		const dominante = sortea(g.opciones, rnd);
		const excepciones = {};
		const otras = g.opciones.filter((o) => o.opcion_eleccion_id !== dominante.opcion_eleccion_id);
		if (otras.length > 0 && unidades > 3) {
			// Una segunda disposición se lleva entre el 10 % y el 35 % de las estrofas, y a veces
			// asoma una tercera en una o dos. Las proporciones salen de las quintillas ya anotadas.
			const segunda = sortea(otras, rnd);
			excepciones[segunda.nombre] = Math.max(1, Math.round(unidades * (0.1 + rnd() * 0.25)));
			const terceras = otras.filter((o) => o.opcion_eleccion_id !== segunda.opcion_eleccion_id);
			if (terceras.length > 0 && rnd() < 0.5) {
				excepciones[sortea(terceras, rnd).nombre] = 1 + Math.floor(rnd() * 3);
			}
		}
		unidad[g.nombre] = { dominante: dominante.nombre, excepciones };
	}
	return { secuencia, unidad };
}

/**
 * Los cuadros, calibrados con las cinco comedias que se leyeron a mano.
 *
 * Un cuadro es un tramo entre dos vaciados del tablado, y de ahí salen dos cosas que las cinco
 * canónicas enseñan y que no se pueden inventar a ojo:
 *
 * - **Son más hacia el final.** La dama boba va 2-4-3; Fuente Ovejuna, 4-5-8; Peribáñez, 5-7-8. La
 *   acción se acelera y los cuadros se acortan.
 * - **Siete de cada diez cortan donde acaba una secuencia, y tres no.** El cambio de cuadro suele
 *   traer cambio de forma, pero una tirada de romance puede seguir sonando después de que el
 *   tablado se vacíe. Fin de jornada, en cambio, es siempre fin de cuadro.
 */
function cuadrosDe(jornada, secuencias, rnd) {
	const dentro = secuencias.filter((s) => s.v_ini >= jornada.v_ini && s.v_fin <= jornada.v_fin);
	const holgura = [0, 2, 3, 4][jornada.numero] ?? 3; // I: 2-4, II: 3-5, III: 4-6
	const cuantos = Math.min(holgura + Math.floor(rnd() * 3), Math.max(1, dentro.length));
	const cortes = [];
	for (let i = 1; i < cuantos; i += 1) {
		const indice = Math.round((dentro.length * i) / cuantos) - 1;
		const seq = dentro[Math.max(0, Math.min(dentro.length - 1, indice))];
		if (!seq || seq.v_fin >= jornada.v_fin) continue;
		// Tres de cada diez cortan dentro de una tirada, si es lo bastante larga para partirla.
		const dentroDeLaTirada = rnd() < 0.45 && seq.versos >= 12;
		const corte = dentroDeLaTirada
			? seq.v_ini + Math.floor(seq.versos / 2)
			: seq.v_fin;
		if (!cortes.includes(corte)) cortes.push(corte);
	}
	const limites = [jornada.v_ini - 1, ...cortes, jornada.v_fin];
	return limites.slice(0, -1).map((v, i) => ({ numero: i + 1, v_ini: v + 1, v_fin: limites[i + 1] }));
}

function guionDe(obra, catalogo) {
	const esqueleto = JSON.parse(
		fs.readFileSync(path.join(ESQUELETOS, `${obra.esqueleto}.json`), 'utf8')
	);
	const rnd = azar(semillaDe(obra.titulo));
	const avisos = [];

	const secuencias = [];
	let orden = 1;
	for (const s of esqueleto.secuencias) {
		const versos = s.v_fin - s.v_ini + 1;
		const fuente = s.forma_fuente ?? 'null';
		const ajuste = (AJUSTES[obra.esqueleto] ?? []).find((a) => a.desde === s.v_ini);
		let par = ajuste
			? [ajuste.forma, ajuste.arquitectura, ajuste.medida]
			: fuente === 'copla_estructura_abierta'
				? coplaPorLargo(versos)
				: MAPA[fuente];
		if (par === undefined) {
			avisos.push(`«${fuente}» no está en el mapa; vv. ${s.v_ini}-${s.v_fin} van sin forma`);
			par = null;
		}
		const arq = par ? catalogo.get(`${par[0]}/${par[1]}`) : null;
		if (par && !arq) {
			avisos.push(
				`«${par[0]}/${par[1]}» no existe en el catálogo; vv. ${s.v_ini}-${s.v_fin} van sin forma`
			);
		}
		const entrada = {
			orden: orden++,
			v_ini: s.v_ini,
			v_fin: s.v_fin,
			versos,
			forma_fuente: fuente,
			forma: arq ? arq.forma : null,
			arquitectura: arq ? arq.arquitectura : null
		};
		if (arq) {
			const paso = pasoDe(arq);
			// El rango se ajusta al módulo de la forma: la base rechaza una octava de 103 versos.
			const unidades = Math.max(1, Math.round(versos / paso));
			entrada.unidades = unidades;
			entrada.versos = unidades * paso;
			Object.assign(entrada, respuestas(arq, unidades, rnd, par[2]));
		}
		// `arrastra` dice que lo que viene detrás se sigue cantando: en La madre Teresa el pareado
		// alirado y los octosílabos que le siguen son el mismo canto.
		if (ajuste?.cantado) entrada.se_canta = ajuste.arrastra ? 'y lo siguiente' : true;
		secuencias.push(entrada);
	}

	const extras = EXTRAS[obra.esqueleto];
	/** La enésima secuencia de una forma, que es como se señala un pasaje sin saber su número. */
	const laDe = (forma, ocurrencia) =>
		secuencias.filter((s) => s.forma === forma)[Math.max(0, (ocurrencia ?? 1) - 1)];

	if (extras?.villancico) {
		const v = extras.villancico;
		const destino = laDe(v.forma_sustituida, v.ocurrencia);
		if (!destino) {
			avisos.push(`no hay ${v.ocurrencia}.ª secuencia de ${v.forma_sustituida} donde poner el villancico`);
		} else {
			destino.forma = 'villancico';
			destino.arquitectura = v.arquitectura;
			destino.unidades = v.ciclos.length;
			destino.versos = v.ciclos.reduce(
				(t, c) => t + Object.values(c).reduce((a, b) => a + b, 0),
				0
			);
			destino.secuencia = {};
			destino.unidad = {};
			// Las partes van dichas una a una: es la única forma del catálogo cuyas partes tienen
			// partes dentro, y no hay manera de deducir el reparto de una regla.
			destino.partes = v.ciclos;
		}
	}

	// **Los rangos se recosen.** Al ajustar cada tirada a su módulo se corren unos versos; las
	// secuencias tienen que quedar pegadas y sin huecos, que es lo que la base exige.
	let verso = 1;
	for (const s of secuencias) {
		s.v_ini = verso;
		s.v_fin = verso + s.versos - 1;
		verso = s.v_fin + 1;
	}
	const total = verso - 1;

	// Las jornadas conservan su proporción, pero **cortan donde acaba una secuencia**.
	const jornadas = [];
	let desde = 1;
	for (const [i, j] of esqueleto.jornadas.entries()) {
		const objetivo = Math.round((j.v_fin / esqueleto.obra.total_versos) * total);
		const fin =
			i === esqueleto.jornadas.length - 1
				? total
				: secuencias.reduce(
						(mejor, s) =>
							s.v_fin > desde && Math.abs(s.v_fin - objetivo) < Math.abs(mejor - objetivo)
								? s.v_fin
								: mejor,
						total
					);
		jornadas.push({ numero: i + 1, v_ini: desde, v_fin: fin });
		desde = fin + 1;
	}

	const cuadros = jornadas.flatMap((j) =>
		cuadrosDe(j, secuencias, rnd).map((c) => ({ jornada: j.numero, ...c }))
	);

	// Lo que se canta, marcado sobre los rangos ya definitivos.
	for (const [i, s] of secuencias.entries()) {
		if (!s.se_canta) continue;
		const alcanza = s.se_canta === 'y lo siguiente' ? [s, secuencias[i + 1]] : [s];
		for (const seq of alcanza.filter(Boolean)) {
			(seq.caracterizaciones ??= []).push({
				tipo: 'cantado',
				v_ini: seq.v_ini,
				v_fin: seq.v_fin,
				observaciones: 'Pasaje cantado.'
			});
		}
		delete s.se_canta;
	}

	// Las caracterizaciones y las desviaciones se cuelgan al final, cuando los rangos ya son los
	// definitivos: las dos señalan versos concretos dentro de una secuencia.
	for (const c of extras?.caracterizaciones ?? []) {
		const seq = c.villancico
			? secuencias.find((s) => s.forma === 'villancico')
			: laDe(c.forma, c.ocurrencia);
		if (!seq) {
			avisos.push(`no hay dónde poner la caracterización «${c.tipo}»`);
			continue;
		}
		const largo = Math.min(c.versos ?? seq.versos, seq.versos);
		(seq.caracterizaciones ??= []).push({
			tipo: c.tipo,
			v_ini: seq.v_ini,
			v_fin: seq.v_ini + largo - 1,
			observaciones: c.nota
		});
	}
	for (const d of extras?.desviaciones ?? []) {
		const seq = laDe(d.forma, d.ocurrencia);
		if (!seq) {
			avisos.push(`no hay dónde poner la desviación «${d.dimension}/${d.relacion_norma}»`);
			continue;
		}
		// Dentro de la secuencia y nunca a caballo: la base lo comprueba.
		const desde = seq.v_ini + Math.min(4, Math.max(0, seq.versos - (d.versos ?? 1)));
		(seq.desviaciones ??= []).push({
			dimension: d.dimension,
			relacion_norma: d.relacion_norma,
			v_ini: desde,
			v_fin: Math.min(desde + (d.versos ?? 1) - 1, seq.v_fin),
			observaciones: d.nota
		});
	}

	return {
		obra: {
			titulo: obra.titulo,
			autor: AUTORES.find((a) => a.clave === obra.autor),
			genero: obra.genero,
			fecha: obra.fecha,
			total_versos: total,
			estado: 'publicado'
		},
		esqueleto: {
			id: obra.esqueleto,
			procedencia: 'ARTELOPE, https://gitlab.com/artelope1/ARTELOPE',
			nota: 'Solo se toma la estructura: cuántas secuencias, de qué forma y de cuántos versos.'
		},
		jornadas,
		cuadros,
		secuencias,
		avisos
	};
}

/** El guion dicho en una línea por secuencia, que es como se revisa. */
function tabla(guion) {
	const lineas = [
		`## ${guion.obra.titulo}`,
		'',
		`${guion.obra.total_versos} versos · ${guion.obra.autor.nombre} · ${guion.obra.genero} · ` +
			`${guion.obra.fecha[0]}-${guion.obra.fecha[1]} · esqueleto ${guion.esqueleto.id}`,
		'',
		`Jornadas: ${guion.jornadas.map((j) => `${j.numero} (${j.v_ini}-${j.v_fin})`).join(' · ')}`,
		`Cuadros: ${guion.cuadros.length}`,
		'',
		'| # | versos | forma / arquitectura | por secuencia | por unidad |',
		'|--:|:--|:--|:--|:--|'
	];
	for (const s of guion.secuencias) {
		const porSecuencia = Object.entries(s.secuencia ?? {})
			.map(([k, v]) => `${k}: **${v}**`)
			.join('<br>');
		const porUnidad = Object.entries(s.unidad ?? {})
			.map(([k, v]) => {
				if (v.misma_en_todas) return `${k}: **${v.misma_en_todas}** en sus ${v.posiciones} versos`;
				if (v.por_posicion)
					return `${k}: ${Object.values(v.por_posicion).join(' · ')}`;
				const sueltas = Object.entries(v.excepciones ?? {})
					.map(([n, c]) => `${n} ×${c}`)
					.join(', ');
				return `${k}: **${v.dominante ?? '—'}**${sueltas ? ` · salvo ${sueltas}` : ''}`;
			})
			.join('<br>');
		const aparte = [
			...(s.partes ?? []).map(
				(c, i) =>
					`ciclo ${i + 1}: ${Object.entries(c)
						.map(([n, v]) => `${n} ${v}`)
						.join(' + ')}`
			),
			...(s.caracterizaciones ?? []).map(
				(c) => `**${c.tipo}** vv. ${c.v_ini}-${c.v_fin}`
			),
			...(s.desviaciones ?? []).map(
				(d) => `**desviación** ${d.dimension}/${d.relacion_norma} vv. ${d.v_ini}-${d.v_fin}`
			)
		].join('<br>');
		lineas.push(
			`| ${s.orden} | ${s.v_ini}-${s.v_fin} (${s.versos}) | ` +
				`${s.forma ? `${s.forma} / ${s.arquitectura}` : '—'} | ${porSecuencia} | ` +
				`${[porUnidad, aparte].filter(Boolean).join('<br>')} |`
		);
	}
	return lineas.join('\n');
}

const catalogo = cargarCatalogo();
fs.mkdirSync(SALIDA, { recursive: true });
const resumen = [];
const tablas = [];
for (const obra of OBRAS) {
	const guion = guionDe(obra, catalogo);
	fs.writeFileSync(
		path.join(SALIDA, `${obra.esqueleto}.json`),
		JSON.stringify(guion, null, '\t'),
		'utf8'
	);
	tablas.push(tabla(guion));
	const formas = new Set(guion.secuencias.map((s) => s.forma).filter(Boolean));
	resumen.push(
		`${obra.titulo.padEnd(38)} ${String(guion.obra.total_versos).padStart(5)} vv · ` +
			`${String(guion.secuencias.length).padStart(3)} secuencias · ${formas.size} formas · ` +
			`${guion.cuadros.length} cuadros${guion.avisos.length ? ` · ${guion.avisos.length} avisos` : ''}`
	);
}
fs.writeFileSync(
	path.join(SALIDA, 'GUIONES.md'),
	['# Guiones de las obras de prueba', '', resumen.join('\n\n'), '', tablas.join('\n\n')].join('\n'),
	'utf8'
);

console.log(resumen.join('\n'));
console.log(`\nGuiones en ${path.relative(RAIZ, SALIDA)} · tabla en GUIONES.md`);
