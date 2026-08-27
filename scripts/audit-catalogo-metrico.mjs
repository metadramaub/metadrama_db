/**
 * Informe de conformidad del catálogo métrico.
 *
 * Contrasta los datos poblados con los criterios de nivel definidos en
 * docs/dominio-metrico/criterios-de-nivel.md y produce dos bloques:
 *
 *   - defectos: incumplimientos que no dependen de una decisión editorial;
 *   - matrices de homogeneidad: dónde vive cada dimensión en cada forma,
 *     para detectar criterios distintos aplicados al mismo fenómeno.
 *
 * Uso:
 *   node scripts/audit-catalogo-metrico.mjs                 # vuelca la base enlazada
 *   node scripts/audit-catalogo-metrico.mjs --dump copia.sql
 *   node scripts/audit-catalogo-metrico.mjs --markdown docs/.../informe.md
 */

import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dumpLinkedDatabase, readDump } from './lib/volcado.mjs';
import { query } from './lib/consulta.mjs';
// La cuenta de clases, rachas y sueltos es la misma que valida lo que el editor escribe. Vive
// en `src/lib/metrica/` con sus pruebas, y aquí se importa en vez de repetirse.
import { medirDisposicion } from '../src/lib/metrica/esquema-rima-escrito.ts';

// --------------------------------------------------------------------------
// Argumentos
// --------------------------------------------------------------------------

function parseArguments(argv) {
	const options = { dump: null, markdown: null };
	for (let index = 0; index < argv.length; index += 1) {
		if (argv[index] === '--dump') options.dump = argv[index + 1] ?? null;
		if (argv[index] === '--markdown') options.markdown = argv[index + 1] ?? null;
	}
	return options;
}

// --------------------------------------------------------------------------
// Obtención de los datos
// --------------------------------------------------------------------------

// --------------------------------------------------------------------------
// Índices de trabajo
// --------------------------------------------------------------------------

function index(rows, key) {
	const map = new Map();
	for (const row of rows) map.set(row[key], row);
	return map;
}

function group(rows, key) {
	const map = new Map();
	for (const row of rows) {
		const bucket = map.get(row[key]);
		if (bucket) bucket.push(row);
		else map.set(row[key], [row]);
	}
	return map;
}

function build(tables) {
	const get = (name) => tables.get(name) ?? [];
	const model = {
		formas: get('formas_metricas'),
		configuraciones: get('arquitecturas_forma'),
		patronesMetricos: get('esquemas_metricos'),
		posicionesMetricas: get('esquema_metrico_posiciones'),
		opcionesMetricas: get('esquema_metrico_opciones'),
		patronesRima: get('esquemas_rima'),
		posicionesRima: get('esquema_rima_posiciones'),
		restriccionesRima: get('esquema_rima_restricciones'),
		secciones: get('estructuras_secciones'),
		repeticiones: get('repeticiones_metricas'),
		combinaciones: get('variedades_arquitectura'),
		grupos: get('grupos_eleccion_metrica'),
		opciones: get('opciones_eleccion_metrica'),
		rasgos: get('rasgos_metricos'),
		valoresRasgo: get('rasgo_valores'),
		configuracionRasgos: get('arquitectura_rasgos'),
		denominaciones: get('denominaciones_metricas'),
		relaciones: get('forma_relaciones'),
		metros: get('metros'),
		vocabularios: get('vocabularios')
	};

	/**
	 * Lo retirado no se audita.
	 *
	 * Hasta el 20 de agosto de 2026 esto no se notaba porque el catálogo nunca había retirado
	 * nada: `activo` era `true` en todas las filas. Ese día se retiró la copla de pie quebrado
	 * —nombraba un rasgo y no una estructura— y el informe siguió contándola entre las formas y
	 * pasándole las comprobaciones. Un defecto en algo que ya no está en el catálogo no es un
	 * defecto, y el recuento del inventario deja de cuadrar con la web.
	 *
	 * Se filtran forma y arquitectura, y con ellas todo lo que cuelga de una arquitectura: si no
	 * se arrastrara la cascada, los esquemas y las secciones de la arquitectura retirada
	 * seguirían examinándose sin dueño.
	 */
	model.formas = model.formas.filter((forma) => forma.activo !== false);
	const formasVivas = new Set(model.formas.map((forma) => forma.forma_id));
	model.configuraciones = model.configuraciones.filter(
		(configuracion) =>
			configuracion.activo !== false && formasVivas.has(configuracion.forma_id)
	);
	const configuracionesVivas = new Set(
		model.configuraciones.map((configuracion) => configuracion.arquitectura_id)
	);
	for (const clave of [
		'patronesMetricos',
		'patronesRima',
		'secciones',
		'repeticiones',
		'combinaciones',
		'grupos',
		'configuracionRasgos'
	]) {
		model[clave] = model[clave].filter((fila) =>
			configuracionesVivas.has(fila.arquitectura_id)
		);
	}
	model.relaciones = model.relaciones.filter(
		(relacion) =>
			formasVivas.has(relacion.forma_origen_id) && formasVivas.has(relacion.forma_destino_id)
	);

	model.formaPorId = index(model.formas, 'forma_id');
	model.configuracionPorId = index(model.configuraciones, 'arquitectura_id');
	model.patronMetricoPorId = index(model.patronesMetricos, 'esquema_metrico_id');
	model.patronRimaPorId = index(model.patronesRima, 'esquema_rima_id');
	model.seccionPorId = index(model.secciones, 'seccion_id');
	model.grupoPorId = index(model.grupos, 'grupo_eleccion_id');
	model.rasgoPorId = index(model.rasgos, 'rasgo_id');
	model.metroPorId = index(model.metros, 'metro_id');
	model.terminoPorId = index(model.vocabularios, 'termino_id');

	model.configuracionesPorForma = group(model.configuraciones, 'forma_id');
	model.patronesMetricosPorConfiguracion = group(model.patronesMetricos, 'arquitectura_id');
	model.patronesRimaPorConfiguracion = group(model.patronesRima, 'arquitectura_id');
	model.seccionesPorConfiguracion = group(model.secciones, 'arquitectura_id');
	model.repeticionesPorConfiguracion = group(model.repeticiones, 'arquitectura_id');
	model.combinacionesPorConfiguracion = group(model.combinaciones, 'arquitectura_id');
	model.gruposPorConfiguracion = group(model.grupos, 'arquitectura_id');
	model.rasgosPorConfiguracion = group(model.configuracionRasgos, 'arquitectura_id');
	model.posicionesPorPatronMetrico = group(model.posicionesMetricas, 'esquema_metrico_id');
	model.opcionesPorPatronMetrico = group(model.opcionesMetricas, 'esquema_metrico_id');
	model.posicionesPorPatronRima = group(model.posicionesRima, 'esquema_rima_id');
	model.restriccionesPorPatronRima = group(model.restriccionesRima, 'esquema_rima_id');
	model.opcionesPorGrupo = group(model.opciones, 'grupo_eleccion_id');

	return model;
}

const listOf = (map, key) => map.get(key) ?? [];

function formaDeConfiguracion(model, configuracionId) {
	const configuracion = model.configuracionPorId.get(configuracionId);
	if (!configuracion) return null;
	return model.formaPorId.get(configuracion.forma_id) ?? null;
}

function etiqueta(model, configuracionId) {
	const configuracion = model.configuracionPorId.get(configuracionId);
	const forma = formaDeConfiguracion(model, configuracionId);
	if (!configuracion || !forma) return String(configuracionId);
	return `${forma.slug} · ${configuracion.slug}`;
}

function metrosDeConfiguracion(model, configuracionId) {
	const metros = new Set();
	for (const patron of listOf(model.patronesMetricosPorConfiguracion, configuracionId)) {
		for (const posicion of listOf(model.posicionesPorPatronMetrico, patron.esquema_metrico_id)) {
			if (posicion.metro_id) metros.add(posicion.metro_id);
		}
		for (const opcion of listOf(model.opcionesPorPatronMetrico, patron.esquema_metrico_id)) {
			metros.add(opcion.metro_id);
		}
	}
	return metros;
}

/** Extensión derivada de las secciones raíz cuando todas son fijas. */
function extensionDerivada(model, configuracionId) {
	const raices = listOf(model.seccionesPorConfiguracion, configuracionId).filter(
		(seccion) => !seccion.seccion_padre_id
	);
	if (raices.length === 0) return null;
	let total = 0;
	for (const seccion of raices) {
		const { versos_min: minimo, versos_max: maximo } = seccion;
		const repeticionMin = seccion.repeticiones_min;
		const repeticionMax = seccion.repeticiones_max;
		if (minimo === null || maximo === null || minimo !== maximo) return null;
		if (repeticionMin === null || repeticionMax === null || repeticionMin !== repeticionMax) {
			return null;
		}
		total += minimo * repeticionMin;
	}
	return total > 0 ? total : null;
}

const ESQUEMA = /^[A-Ha-h-]{2,}$/;

// --------------------------------------------------------------------------
// Bloque 1 · Defectos
// --------------------------------------------------------------------------

const DEFECTOS = [
	{
		id: 'D1',
		titulo: 'Configuración sin contenido normativo',
		criterio: 'Una configuración debe declarar al menos un patrón, una sección o una variedad.',
		detectar(model) {
			return model.configuraciones
				.filter(
					(configuracion) =>
						listOf(model.patronesMetricosPorConfiguracion, configuracion.arquitectura_id).length ===
							0 &&
						listOf(model.patronesRimaPorConfiguracion, configuracion.arquitectura_id).length ===
							0 &&
						listOf(model.seccionesPorConfiguracion, configuracion.arquitectura_id).length === 0 &&
						listOf(model.combinacionesPorConfiguracion, configuracion.arquitectura_id).length === 0
				)
				.map((configuracion) => ({
					sujeto: etiqueta(model, configuracion.arquitectura_id),
					detalle: `principal=${configuracion.principal} · demarcable=${configuracion.demarcable}`
				}));
		}
	},
	{
		id: 'D2',
		titulo: 'Patrón de rima sin contenido alguno',
		criterio:
			'Un esquema debe aportar algo computable: notación, posiciones o restricciones. Un esquema vacío no declara norma y solo ocupa un hueco en la interfaz. Se exceptúa el de tipo abierta con un tipo de rima declarado: afirma que la norma exige ese tipo y deja libre la disposición, como corresponde a una forma general.',
		detectar(model) {
			const declaraTipoDeRima = (patron) =>
				Boolean(
					patron.tipo_rima_id || model.configuracionPorId.get(patron.arquitectura_id)?.tipo_rima_id
				);
			return model.patronesRima
				.filter(
					(patron) =>
						!(patron.tipo_secuencia === 'abierta' && declaraTipoDeRima(patron)) &&
						!patron.notacion &&
						listOf(model.posicionesPorPatronRima, patron.esquema_rima_id).length === 0 &&
						listOf(model.restriccionesPorPatronRima, patron.esquema_rima_id).length === 0
				)
				.map((patron) => ({
					sujeto: etiqueta(model, patron.arquitectura_id),
					detalle: `${patron.nombre ?? 'sin nombre'} · ${patron.tipo_secuencia}`
				}));
		}
	},
	{
		id: 'D2b',
		titulo: 'Configuración sin ninguna declaración de rima ni de repetición',
		criterio:
			'Toda configuración debe declarar cómo se comporta la rima: un patrón propio, una sección que lo aporte o lo reutilice, o un patrón de repetición que ocupe su lugar.',
		detectar(model) {
			return model.configuraciones
				.filter((configuracion) => {
					const id = configuracion.arquitectura_id;
					if (listOf(model.patronesRimaPorConfiguracion, id).length > 0) return false;
					if (listOf(model.repeticionesPorConfiguracion, id).length > 0) return false;
					return !listOf(model.seccionesPorConfiguracion, id).some(
						(seccion) => seccion.esquema_rima_id || seccion.arquitectura_referenciada_id
					);
				})
				.map((configuracion) => ({
					sujeto: etiqueta(model, configuracion.arquitectura_id),
					detalle: `${listOf(model.seccionesPorConfiguracion, configuracion.arquitectura_id).length} sección(es), sin patrón de rima accesible`
				}));
		}
	},
	{
		id: 'D3',
		titulo: 'Patrón métrico sin posiciones ni opciones',
		criterio: 'Un patrón métrico debe declarar posiciones ordenadas o un conjunto permitido.',
		detectar(model) {
			return model.patronesMetricos
				.filter(
					(patron) =>
						listOf(model.posicionesPorPatronMetrico, patron.esquema_metrico_id).length === 0 &&
						listOf(model.opcionesPorPatronMetrico, patron.esquema_metrico_id).length === 0
				)
				.map((patron) => ({
					sujeto: etiqueta(model, patron.arquitectura_id),
					detalle: `${patron.ambito} · ${patron.tipo_secuencia}`
				}));
		}
	},
	{
		id: 'D4',
		titulo: 'La extensión de la unidad no se declara ni se puede derivar',
		criterio:
			'Una arquitectura declara cuántos versos tiene su unidad, y entonces sus secciones no pueden sumar otra cosa; o la deja sin declarar, y entonces tiene que haber secciones de las que derivarla. Lo que no puede es no decirlo por ninguna de las dos vías.',
		detectar(model) {
			const hallazgos = [];
			for (const configuracion of model.configuraciones) {
				const derivada = extensionDerivada(model, configuracion.arquitectura_id);
				if (configuracion.unidad_versos_min === null) {
					// La unidad sin declarar es legítima cuando la extensión varía con el pasaje,
					// pero entonces las secciones son las que la producen.
					const secciones = listOf(model.seccionesPorConfiguracion, configuracion.arquitectura_id);
					if (
						secciones.length === 0 &&
						formaDeConfiguracion(model, configuracion.arquitectura_id)?.nivel_estructural !==
							'serie'
					) {
						hallazgos.push({
							sujeto: etiqueta(model, configuracion.arquitectura_id),
							detalle: 'no declara unidad y no tiene secciones de las que derivarla'
						});
					}
					continue;
				}
				if (derivada === null) continue;
				if (
					derivada < configuracion.unidad_versos_min ||
					derivada > configuracion.unidad_versos_max
				) {
					hallazgos.push({
						sujeto: etiqueta(model, configuracion.arquitectura_id),
						detalle: `declara una unidad de ${configuracion.unidad_versos_min}–${configuracion.unidad_versos_max} y las secciones producen ${derivada}`
					});
				}
			}
			return hallazgos;
		}
	},
	{
		id: 'D5',
		titulo: 'La opción distingue menos posiciones que el patrón al que apunta',
		criterio:
			'El patrón debe modelar el nivel que la pregunta distingue; si la opción nombra un esquema más corto, la alternativa vive en un nivel inferior.',
		detectar(model) {
			const hallazgos = [];
			for (const opcion of model.opciones) {
				if (!opcion.esquema_rima_id) continue;
				const patron = model.patronRimaPorId.get(opcion.esquema_rima_id);
				if (!patron?.notacion || !ESQUEMA.test(opcion.slug)) continue;
				if (opcion.slug.length >= patron.notacion.length) continue;
				const grupo = model.grupoPorId.get(opcion.grupo_eleccion_id);
				hallazgos.push({
					sujeto: etiqueta(model, patron.arquitectura_id),
					detalle: `${grupo?.slug ?? '?'} · opción «${opcion.slug}» (${opcion.slug.length}) apunta a «${patron.notacion}» (${patron.notacion.length}), ámbito ${patron.ambito}`
				});
			}
			return hallazgos;
		}
	},
	{
		id: 'D6',
		titulo: 'Slug de opción con UUID incrustado',
		criterio: 'Los slugs son identificadores estables y legibles; serán clave de comparación.',
		detectar(model) {
			return model.opciones
				.filter((opcion) => /[0-9a-f]{8}-[0-9a-f]{4}-/.test(String(opcion.slug)))
				.map((opcion) => {
					const grupo = model.grupoPorId.get(opcion.grupo_eleccion_id);
					return {
						sujeto: grupo ? etiqueta(model, grupo.arquitectura_id) : '?',
						detalle: `${grupo?.slug ?? '?'} · ${opcion.slug}`
					};
				});
		}
	},
	{
		id: 'D7',
		titulo: 'Rasgo booleano usado como vector de posiciones',
		criterio:
			'Un rasgo describe una propiedad, no una posición. Una alternativa posicional pertenece al patrón métrico o a una opción de metro con posicion_unidad.',
		detectar(model) {
			const hallazgos = [];
			for (const [grupoId, opciones] of model.opcionesPorGrupo) {
				const grupo = model.grupoPorId.get(grupoId);
				if (!grupo || grupo.dimension !== 'rasgo') continue;
				const porRasgo = new Map();
				for (const opcion of opciones) {
					if (!opcion.rasgo_id || opcion.posicion_unidad === null) continue;
					porRasgo.set(opcion.rasgo_id, (porRasgo.get(opcion.rasgo_id) ?? 0) + 1);
				}
				for (const [rasgoId, total] of porRasgo) {
					if (total < 2) continue;
					const rasgo = model.rasgoPorId.get(rasgoId);
					hallazgos.push({
						sujeto: etiqueta(model, grupo.arquitectura_id),
						detalle: `${grupo.slug} repite el rasgo «${rasgo?.slug ?? rasgoId}» (${rasgo?.tipo_valor ?? '?'}) en ${total} posiciones`
					});
				}
			}
			return hallazgos;
		}
	},
	{
		id: 'D8',
		titulo: 'Componente copiado en lugar de reutilizado',
		criterio:
			'Cuando una forma declara `compuesta_por` o `subtipo_de` otra, sus secciones reutilizan la configuración del componente mediante arquitectura_referenciada_id. Copiar sus patrones obliga a mantener el repertorio en varios sitios y rompe la comparación.',
		detectar(model) {
			const compone = new Set();
			for (const relacion of model.relaciones) {
				if (!['compuesta_por', 'subtipo_de'].includes(relacion.tipo_relacion)) continue;
				compone.add(`${relacion.forma_origen_id}>${relacion.forma_destino_id}`);
				compone.add(`${relacion.forma_destino_id}>${relacion.forma_origen_id}`);
			}

			const porEsquema = new Map();
			for (const patron of model.patronesRima) {
				if (!patron.notacion) continue;
				const forma = formaDeConfiguracion(model, patron.arquitectura_id);
				if (!forma) continue;
				const bucket = porEsquema.get(patron.notacion) ?? new Map();
				bucket.set(forma.forma_id, (bucket.get(forma.forma_id) ?? 0) + 1);
				porEsquema.set(patron.notacion, bucket);
			}

			const acumulado = new Map();
			for (const [esquema, formas] of porEsquema) {
				if (formas.size < 2) continue;
				const ids = [...formas.keys()];
				for (let a = 0; a < ids.length; a += 1) {
					for (let b = a + 1; b < ids.length; b += 1) {
						if (!compone.has(`${ids[a]}>${ids[b]}`)) continue;
						const par = [model.formaPorId.get(ids[a]), model.formaPorId.get(ids[b])];
						const clave = par.map((forma) => forma.slug).join(' / ');
						const bucket = acumulado.get(clave) ?? [];
						bucket.push(esquema);
						acumulado.set(clave, bucket);
					}
				}
			}
			return [...acumulado.entries()].map(([clave, esquemas]) => ({
				sujeto: clave,
				detalle: `${esquemas.length} esquema(s) copiados: ${esquemas.join(', ')}`
			}));
		}
	},
	{
		id: 'D9',
		titulo: 'Rasgo cualitativo almacenado como restricción de rima sin catalogar',
		criterio:
			'Una propiedad transversal es un rasgo con modalidad declarada, no un literal libre colgado de un patrón.',
		detectar(model) {
			const porValor = new Map();
			for (const restriccion of model.restriccionesRima) {
				if (restriccion.tipo !== 'otra' || !restriccion.valor_texto) continue;
				const patron = model.patronRimaPorId.get(restriccion.esquema_rima_id);
				const forma = patron ? formaDeConfiguracion(model, patron.arquitectura_id) : null;
				const bucket = porValor.get(restriccion.valor_texto) ?? new Set();
				if (forma) bucket.add(forma.slug);
				porValor.set(restriccion.valor_texto, bucket);
			}
			return [...porValor.entries()]
				.sort((a, b) => b[1].size - a[1].size || a[0].localeCompare(b[0], 'es'))
				.map(([valor, formas]) => ({
					sujeto: valor,
					detalle: `${formas.size} forma(s): ${[...formas].join(', ')}`
				}));
		}
	},
	{
		id: 'D10',
		titulo: 'Coherencia del tipo de registro y del grado de especificación',
		criterio:
			'Un tramo sin forma no tiene arquitectura. Y la taxonomía va en una sola dirección: lo específico es subtipo de lo general, nunca al revés.',
		detectar(model) {
			const hallazgos = [];
			for (const forma of model.formas) {
				if (
					forma.tipo_registro === 'sin_forma' &&
					listOf(model.configuracionesPorForma, forma.forma_id).length > 0
				) {
					hallazgos.push({ sujeto: forma.slug, detalle: 'tramo sin forma con arquitectura' });
				}
			}
			return hallazgos;
		}
	},
	{
		id: 'D11',
		titulo: 'Sección que solo existe para repetir la unidad',
		criterio:
			'Una sección describe el interior de la unidad. Que el pasaje contenga varias unidades se deriva del rango, no se declara como sección. Se exceptúan las series, donde la sección repetible describe el ritmo interno de la propia serie.',
		detectar(model) {
			const hallazgos = [];
			for (const configuracion of model.configuraciones) {
				const forma = model.formaPorId.get(configuracion.forma_id);
				if (!forma || forma.nivel_estructural === 'serie') continue;
				const secciones = listOf(model.seccionesPorConfiguracion, configuracion.arquitectura_id);
				if (secciones.length !== 1 || secciones[0].seccion_padre_id) continue;
				const raiz = secciones[0];
				hallazgos.push({
					sujeto: etiqueta(model, configuracion.arquitectura_id),
					detalle: `«${raiz.tipo_seccion}» v=${raiz.versos_min}–${raiz.versos_max} rep=${raiz.repeticiones_min}–${raiz.repeticiones_max}, sin partes internas`
				});
			}
			return hallazgos;
		}
	},
	{
		id: 'D12',
		titulo: 'Pregunta estructural con alcance de secuencia',
		criterio:
			'Lo que es constante en toda la secuencia y afecta a la estructura es arquitectura, no pregunta. El alcance de secuencia se reserva a los rasgos. En las series no aplica: la secuencia contiene una sola unidad.',
		detectar(model) {
			const estructurales = new Set(['metro', 'rima', 'combinacion', 'estructura', 'repeticion']);
			return model.grupos
				.filter((grupo) => {
					if (grupo.alcance !== 'secuencia' || !estructurales.has(grupo.dimension)) return false;
					const forma = formaDeConfiguracion(model, grupo.arquitectura_id);
					return Boolean(forma) && forma.nivel_estructural !== 'serie';
				})
				.map((grupo) => ({
					sujeto: etiqueta(model, grupo.arquitectura_id),
					detalle: `${grupo.slug} · dimensión ${grupo.dimension} · ${listOf(model.opcionesPorGrupo, grupo.grupo_eleccion_id).length} opciones`
				}));
		}
	},
	{
		id: 'D13',
		titulo: 'Un esquema concreto contradice el criterio de su esquema abierto',
		criterio:
			'Cuando una arquitectura declara un esquema abierto con restricciones y además esquemas concretos sobre el mismo tramo, el abierto es la norma y los concretos son sus realizaciones documentadas: tienen que cumplirla. Se exceptúan tres. El concreto que el propio criterio excluye —ahí el abierto no es la norma sino la alternativa que queda—; los que ocupan otra sección, que no compiten con él sino que completan la estrofa; y **los declarados `excepcional`**, que están en el catálogo precisamente porque se apartan de la norma y se registran igual.',
		detectar(model) {
			const resumir = (patron) => {
				const posiciones = listOf(model.posicionesPorPatronRima, patron.esquema_rima_id)
					.slice()
					.sort((a, b) => a.bloque - b.bloque || a.posicion - b.posicion);
				if (posiciones.length === 0) return null;
				const medida = medirDisposicion(
					posiciones.map((p) => ({ clase: p.clase_rima, suelto: p.suelto === true }))
				);
				// **El auditor cuenta los sueltos con más manga que el editor.** Aquí un verso sin
				// rima es también una clase que aparece una sola vez, esté marcado o no: un esquema
				// catalogado puede dar clase a un verso que en realidad no rima con ninguno, y para
				// contrastar `versos_sueltos: ninguno` hay que verlo. Lo que el editor escribe, en
				// cambio, dice con un guion los que van sueltos, y ahí no hace falta deducirlo.
				const clase = (p) => (p.clase_rima ?? '').toLocaleLowerCase('es');
				const veces = new Map();
				for (const p of posiciones) veces.set(clase(p), (veces.get(clase(p)) ?? 0) + 1);
				return {
					...medida,
					sueltos:
						posiciones.filter((p) => p.suelto).length +
						[...veces.values()].filter((n) => n === 1).length
				};
			};

			const incumple = (restriccion, resumen) => {
				const numero = Number(restriccion.valor_numero);
				if (restriccion.tipo === 'numero_clases') return resumen.clases !== numero;
				if (restriccion.tipo === 'min_alternancias') return resumen.alternancias < numero;
				// Añadido el 25 de agosto de 2026 (C3). Estaba en el `CHECK` del tipo desde el
				// principio y esta función devolvía `false`, de modo que una restricción declarada
				// no se comprobaba contra nada: el catálogo la escribía y nadie la leía.
				if (restriccion.tipo === 'max_consecutivos') return resumen.maxConsecutivos > numero;
				if (restriccion.tipo === 'versos_sueltos') {
					if (restriccion.valor_texto === 'ninguno') return resumen.sueltos > 0;
					if (restriccion.valor_texto === 'todos') return resumen.sueltos === 0;
				}
				// `regularidad` e `identidad_entre_repeticiones` hablan de la serie, no de una
				// disposición suelta, y no se pueden contrastar contra un esquema concreto.
				return false;
			};

			const hallazgos = [];
			for (const [arquitecturaId, patrones] of model.patronesRimaPorConfiguracion) {
				const abiertos = patrones.filter((p) => p.tipo_secuencia === 'abierta');
				for (const abierto of abiertos) {
					const restricciones = listOf(model.restriccionesPorPatronRima, abierto.esquema_rima_id);
					if (restricciones.length === 0) continue;
					const excluidos = new Set(
						restricciones
							.filter((r) => r.tipo === 'excluye_esquema' && r.esquema_referido_id)
							.map((r) => r.esquema_referido_id)
					);
					for (const concreto of patrones) {
						if (concreto.tipo_secuencia === 'abierta') continue;
						if (excluidos.has(concreto.esquema_rima_id)) continue;
						// **Una disposición excepcional está en el catálogo porque se aparta.** El
						// `abbba` de la quintilla no lo numera ninguna fuente: se registra como
						// aparición suelta, que Morley y Bruerton atribuyen a errata o a adaptación
						// expresiva. Medirla contra la norma y llamarla defecto empujaría a una de
						// dos cosas, y las dos son peores: borrar el esquema, o no declarar la
						// restricción para que no proteste. Declarar algo excepcional **es** decir
						// que no cumple la norma.
						if (concreto.modalidad === 'excepcional') continue;
						// La sección dice de qué tramo habla cada esquema. Si difieren, son partes
						// complementarias —el cuerpo y el pareado final de la canción— y no se miden
						// con la misma vara.
						if ((concreto.seccion_id ?? null) !== (abierto.seccion_id ?? null)) continue;
						const resumen = resumir(concreto);
						if (!resumen) continue;
						const rotas = restricciones.filter((r) => incumple(r, resumen));
						if (rotas.length === 0) continue;
						hallazgos.push({
							sujeto: etiqueta(model, arquitecturaId),
							detalle: `${concreto.slug} incumple ${rotas.map((r) => r.tipo).join(', ')} de «${abierto.slug}» · ${resumen.clases} clases, ${resumen.alternancias} alternancias, ${resumen.sueltos} sueltos, ${resumen.maxConsecutivos} seguidos`
						});
					}
				}
			}
			return hallazgos;
		}
	},
	{
		id: 'D14',
		titulo: 'La notación de un esquema y sus clases de rima no cuadran',
		criterio:
			'La notación es lo que se publica y las posiciones son lo que se dibuja: tienen que decir lo mismo. Las letras de la notación, en orden de lectura, son las clases guardadas, con su caja —la mayúscula marca el arte mayor y no una clase distinta— y sin contar los versos sueltos, que la notación escribe con guion y las posiciones dejan sin clase. Ocho esquemas incumplían esto hasta el 12 de agosto de 2026, y se veía al dibujar la rejilla: las letras contradecían la notación impresa debajo.',
		detectar(model) {
			const hallazgos = [];
			for (const patron of model.patronesRima) {
				const notacion = patron.notacion?.trim();
				if (!notacion) continue;
				const posiciones = listOf(model.posicionesPorPatronRima, patron.esquema_rima_id)
					.slice()
					.sort((a, b) => a.bloque - b.bloque || a.posicion - b.posicion);
				if (posiciones.length === 0) continue;
				const letras = notacion.replace(/[^a-zA-Z]/g, '');
				const clases = posiciones
					.map((p) => p.clase_rima)
					.filter((clase) => clase !== null && clase !== undefined)
					.join('');
				if (letras === clases) continue;
				hallazgos.push({
					sujeto: etiqueta(model, patron.arquitectura_id),
					detalle: `${patron.slug} · la notación «${notacion}» da «${letras}» y las posiciones guardan «${clases}»`
				});
			}
			return hallazgos;
		}
	},
	{
		id: 'D15',
		titulo: 'Arquitectura sin régimen de rima declarado en ningún nivel',
		criterio:
			'El régimen —consonante, asonante, sin rima— se declara siempre, en el nivel que le corresponde: en la arquitectura cuando es uno solo, y en cada disposición cuando dentro de ella varía. El villancico lo declara abajo porque admite `abba` consonante junto a la asonantada `-a-a`, y la canción sin rima porque su cuerpo no rima y su pareado final sí. Lo que no vale es que no esté en ninguno de los dos: es lo primero que hay que saber de una rima, y ocho arquitecturas lo callaban hasta el 12 de agosto de 2026.',
		detectar(model) {
			return model.configuraciones
				.filter((configuracion) => {
					if (configuracion.tipo_rima_id) return false;
					const patrones = listOf(
						model.patronesRimaPorConfiguracion,
						configuracion.arquitectura_id
					);
					// Una arquitectura sin ninguna disposición no tiene dónde declararlo abajo;
					// la señala D2b, que es de quien es ese hueco.
					if (patrones.length === 0) return false;
					return patrones.some((patron) => !patron.tipo_rima_id);
				})
				.map((configuracion) => {
					const patrones = listOf(
						model.patronesRimaPorConfiguracion,
						configuracion.arquitectura_id
					);
					const mudos = patrones.filter((patron) => !patron.tipo_rima_id);
					return {
						sujeto: etiqueta(model, configuracion.arquitectura_id),
						detalle: `ni la arquitectura ni ${mudos.length} de sus ${patrones.length} disposiciones lo declaran: ${mudos.map((p) => p.slug).join(', ')}`
					};
				});
		}
	},
	{
		id: 'D16',
		titulo: 'Reutilización entre formas sin relación ontológica',
		criterio:
			'Cuando una sección reutiliza una arquitectura de otra forma, la precisión estructural vive en arquitectura_referenciada_id y el vínculo navegable vive en forma_relaciones. Tiene que existir al menos una relación entre ambas formas, declarada una sola vez en cualquiera de las dos direcciones.',
		detectar(model) {
			const relacionadas = new Set();
			for (const relacion of model.relaciones) {
				relacionadas.add(`${relacion.forma_origen_id}>${relacion.forma_destino_id}`);
				relacionadas.add(`${relacion.forma_destino_id}>${relacion.forma_origen_id}`);
			}

			const faltantes = new Map();
			for (const seccion of model.secciones) {
				if (!seccion.arquitectura_referenciada_id) continue;
				const propia = model.configuracionPorId.get(seccion.arquitectura_id);
				const reutilizada = model.configuracionPorId.get(seccion.arquitectura_referenciada_id);
				if (!propia || !reutilizada || propia.forma_id === reutilizada.forma_id) continue;
				if (relacionadas.has(`${propia.forma_id}>${reutilizada.forma_id}`)) continue;

				const origen = model.formaPorId.get(propia.forma_id);
				const destino = model.formaPorId.get(reutilizada.forma_id);
				const clave = `${propia.forma_id}>${reutilizada.forma_id}`;
				const secciones = faltantes.get(clave) ?? {
					sujeto: origen?.nombre ?? origen?.slug ?? propia.forma_id,
					destino: destino?.nombre ?? destino?.slug ?? reutilizada.forma_id,
					nombres: []
				};
				secciones.nombres.push(`${propia.slug} · ${seccion.nombre}`);
				faltantes.set(clave, secciones);
			}

			return [...faltantes.values()].map((faltante) => ({
				sujeto: faltante.sujeto,
				detalle: `reutiliza «${faltante.destino}» en ${faltante.nombres.join(', ')} sin forma_relacion`
			}));
		}
	},
	{
		id: 'D17',
		titulo: 'Una unidad cuya rima no está fija y nadie pregunta',
		criterio:
			'Regla 1 de criterios de nivel § 3.3: donde hay unidad y la norma no fija una sola disposición, el editor tiene que poder decir cuál leyó. Se cumple de cuatro maneras y basta una: la arquitectura pregunta su rima; la resuelve una variedad, que empareja esquema métrico y de rima; toda su rima vive en secciones que reutilizan otras arquitecturas y la heredan; o la norma la fija con un único esquema **definitorio**. Un único esquema marcado «habitual» o «admitida» no exime: decir que suele ser ese es decir que hay otros. Las series quedan fuera porque no tienen unidad: su rima se describe por rasgos del pasaje.',
		detectar(model) {
			const conPregunta = new Set(
				model.grupos
					.filter((grupo) => grupo.dimension === 'rima' && grupo.activo !== false)
					.map((grupo) => grupo.arquitectura_id)
			);
			// Una pregunta de combinación elige la pareja de esquema métrico y de rima a la vez:
			// resuelve la disposición aunque no se llame pregunta de rima. Es el sexteto-lira, y
			// que su nivel deba conservarse es cuestión abierta del IP, no un defecto.
			const conVariedad = new Set(
				model.grupos
					.filter((grupo) => grupo.dimension === 'combinacion' && grupo.activo !== false)
					.map((grupo) => grupo.arquitectura_id)
			);
			const reutilizadoras = new Set(
				model.secciones
					.filter((seccion) => seccion.arquitectura_referenciada_id)
					.map((seccion) => seccion.arquitectura_id)
			);

			const faltan = [];
			for (const configuracion of model.configuraciones) {
				const forma = model.formaPorId.get(configuracion.forma_id);
				if (!forma || forma.activo === false) continue;
				if (forma.nivel_estructural === 'serie') continue;
				if (conPregunta.has(configuracion.arquitectura_id)) continue;
				if (conVariedad.has(configuracion.arquitectura_id)) continue;
				if (reutilizadoras.has(configuracion.arquitectura_id)) continue;

				const concretos = listOf(model.patronesRimaPorConfiguracion, configuracion.arquitectura_id)
					.filter((patron) => patron.tipo_secuencia !== 'abierta');
				// **Un solo esquema solo exime si es el que define la forma.** Marcarlo `habitual`
				// o `admitida` es decir que hay otros, y entonces quien encuentre uno distinto
				// necesita dónde decirlo. La regla miraba cuántos había y no qué decían.
				if (concretos.length === 1 && concretos[0].modalidad === 'definitoria') continue;

				faltan.push({
					sujeto: etiqueta(model, configuracion.arquitectura_id),
					detalle:
						concretos.length === 0
							? 'no declara ninguna disposición ni pregunta cuál se observa'
							: concretos.length === 1
								? `declara una sola disposición, «${concretos[0].modalidad}», y no pregunta cuál se observa`
								: `declara ${concretos.length} disposiciones y no pregunta cuál se observa`
				});
			}
			return faltan;
		}
	},
	{
		id: 'D18',
		titulo: 'Una unidad cuya medida no está fija y nadie pregunta',
		criterio:
			'El mismo principio que D17, en la otra dimensión: donde la norma admite varias medidas y no dice cuál va en cada verso, el editor tiene que poder decir cuál leyó. Exime que la arquitectura pregunte su metro, que lo resuelva una variedad —que empareja esquema métrico y de rima—, o que su estructura reutilice otras arquitecturas. Las series quedan fuera porque no tienen unidad. Una arquitectura cuyo esquema métrico fija cada posición no entra: ahí la medida no varía, y lo que se salga de ella es una desviación.',
		detectar(model) {
			const conPregunta = new Set(
				model.grupos
					.filter((grupo) => grupo.dimension === 'metro' && grupo.activo !== false)
					.map((grupo) => grupo.arquitectura_id)
			);
			const conVariedad = new Set(
				model.grupos
					.filter((grupo) => grupo.dimension === 'combinacion' && grupo.activo !== false)
					.map((grupo) => grupo.arquitectura_id)
			);
			const reutilizadoras = new Set(
				model.secciones
					.filter((seccion) => seccion.arquitectura_referenciada_id)
					.map((seccion) => seccion.arquitectura_id)
			);

			const faltan = [];
			for (const configuracion of model.configuraciones) {
				const forma = model.formaPorId.get(configuracion.forma_id);
				if (!forma || forma.activo === false) continue;
				if (forma.nivel_estructural === 'serie') continue;
				if (conPregunta.has(configuracion.arquitectura_id)) continue;
				if (conVariedad.has(configuracion.arquitectura_id)) continue;
				if (reutilizadoras.has(configuracion.arquitectura_id)) continue;

				// «No fija la medida» es declarar un repertorio de medidas admitidas en vez de
				// decir cuál va en cada verso. Es la serie alirada: endecasílabos y heptasílabos,
				// y la disposición la pone cada estrofa.
				const abiertos = listOf(
					model.patronesMetricosPorConfiguracion,
					configuracion.arquitectura_id
				).filter(
					(patron) => listOf(model.opcionesPorPatronMetrico, patron.esquema_metrico_id).length > 0
				);
				if (abiertos.length === 0) continue;

				const medidas = new Set();
				for (const patron of abiertos) {
					for (const opcion of listOf(model.opcionesPorPatronMetrico, patron.esquema_metrico_id)) {
						const metro = model.metroPorId?.get(opcion.metro_id);
						if (metro?.silabas) medidas.add(String(metro.silabas));
					}
				}
				faltan.push({
					sujeto: etiqueta(model, configuracion.arquitectura_id),
					detalle: `admite ${[...medidas].sort().join(' y ') || 'varias medidas'} y no pregunta cuál va en cada verso`
				});
			}
			return faltan;
		}
	}
];

// --------------------------------------------------------------------------
// Bloque 2 · Matrices de homogeneidad
// --------------------------------------------------------------------------

function viasDeMedida(model, forma) {
	const configuraciones = listOf(model.configuracionesPorForma, forma.forma_id);
	const vias = new Set();

	const firmas = new Set(
		configuraciones.map((configuracion) =>
			[...metrosDeConfiguracion(model, configuracion.arquitectura_id)].sort().join('|')
		)
	);
	if (configuraciones.length > 1 && firmas.size > 1) vias.add('configuracion');

	for (const configuracion of configuraciones) {
		for (const patron of listOf(
			model.patronesMetricosPorConfiguracion,
			configuracion.arquitectura_id
		)) {
			if (listOf(model.posicionesPorPatronMetrico, patron.esquema_metrico_id).length > 0) {
				vias.add('posiciones');
			}
			if (listOf(model.opcionesPorPatronMetrico, patron.esquema_metrico_id).length > 0) {
				vias.add('conjunto');
			}
		}
		for (const grupo of listOf(model.gruposPorConfiguracion, configuracion.arquitectura_id)) {
			if (grupo.dimension === 'metro') vias.add('eleccion');
		}
	}
	return vias;
}

function viasDeRima(model, forma) {
	const vias = new Set();
	for (const configuracion of listOf(model.configuracionesPorForma, forma.forma_id)) {
		const patrones = listOf(model.patronesRimaPorConfiguracion, configuracion.arquitectura_id);
		const grupos = listOf(model.gruposPorConfiguracion, configuracion.arquitectura_id);

		if (patrones.length === 0) vias.add('sin patrón');
		for (const grupo of grupos) {
			if (grupo.dimension === 'rima' && grupo.tipo_control === 'esquema_rima') {
				vias.add('esquema libre');
			} else if (grupo.dimension === 'rima') {
				vias.add('elección');
			} else if (grupo.dimension === 'combinacion') {
				vias.add('variedad');
			}
		}
		const tieneEleccion = grupos.some((grupo) => ['rima', 'combinacion'].includes(grupo.dimension));
		if (patrones.length === 1 && !tieneEleccion) vias.add('patrón único');
		if (patrones.length > 1 && !tieneEleccion) vias.add('varios patrones sin pregunta');
		for (const patron of patrones) {
			const restricciones = listOf(model.restriccionesPorPatronRima, patron.esquema_rima_id);
			if (restricciones.some((restriccion) => restriccion.tipo === 'otra')) vias.add('cualitativa');
		}
	}
	return vias;
}

function fichaPorForma(model) {
	return model.formas
		.filter((forma) => forma.tipo_registro === 'forma')
		.map((forma) => {
			const configuraciones = listOf(model.configuracionesPorForma, forma.forma_id);
			const grupos = configuraciones.flatMap((configuracion) =>
				listOf(model.gruposPorConfiguracion, configuracion.arquitectura_id)
			);
			return {
				forma: forma.slug,
				nivel: forma.nivel_estructural,
				configuraciones: configuraciones.length,
				principal: configuraciones.some((configuracion) => configuracion.principal),
				medida: [...viasDeMedida(model, forma)].sort(),
				rima: [...viasDeRima(model, forma)].sort(),
				grupos: grupos.length,
				alcances: [...new Set(grupos.map((grupo) => grupo.alcance))].sort()
			};
		})
		.sort((a, b) => a.forma.localeCompare(b.forma, 'es'));
}

/** Cómo resuelve cada configuración la rima que la norma no fija. */
function estrategiasRimaVariable(model) {
	const filas = [];
	for (const configuracion of model.configuraciones) {
		const id = configuracion.arquitectura_id;
		const patrones = listOf(model.patronesRimaPorConfiguracion, id);
		const grupos = listOf(model.gruposPorConfiguracion, id);
		const abiertos = patrones.filter(
			(patron) =>
				!patron.notacion &&
				listOf(model.posicionesPorPatronRima, patron.esquema_rima_id).length === 0
		);
		if (abiertos.length === 0) continue;

		const conRestricciones = abiertos.filter(
			(patron) => listOf(model.restriccionesPorPatronRima, patron.esquema_rima_id).length > 0
		).length;
		const controlAbierto = grupos.some((grupo) => grupo.tipo_control === 'esquema_rima');

		const estrategias = [];
		if (controlAbierto) estrategias.push('control abierto de esquema');
		if (conRestricciones > 0) estrategias.push(`restricciones cualitativas (${conRestricciones})`);
		if (!controlAbierto && conRestricciones === 0) estrategias.push('patrón vacío, sin sustituto');

		filas.push({
			configuracion: etiqueta(model, id),
			patrones: abiertos.length,
			estrategia: estrategias.join(' + ')
		});
	}
	return filas.sort(
		(a, b) =>
			a.estrategia.localeCompare(b.estrategia, 'es') ||
			a.configuracion.localeCompare(b.configuracion, 'es')
	);
}

/** Esquemas que coinciden literalmente en formas distintas, para revisión. */
function esquemasCoincidentes(model) {
	const porEsquema = new Map();
	for (const patron of model.patronesRima) {
		if (!patron.notacion) continue;
		const forma = formaDeConfiguracion(model, patron.arquitectura_id);
		if (!forma) continue;
		const bucket = porEsquema.get(patron.notacion) ?? new Map();
		bucket.set(forma.slug, (bucket.get(forma.slug) ?? 0) + 1);
		porEsquema.set(patron.notacion, bucket);
	}
	return [...porEsquema.entries()]
		.filter(([, formas]) => formas.size > 1)
		.sort((a, b) => b[1].size - a[1].size || a[0].localeCompare(b[0], 'es'))
		.map(([esquema, formas]) => ({
			esquema,
			formas: [...formas.entries()]
				.sort((a, b) => a[0].localeCompare(b[0], 'es'))
				.map(([slug, total]) => (total > 1 ? `${slug}×${total}` : slug))
		}));
}

function matrizAlcance(model) {
	const filas = new Map();
	for (const grupo of model.grupos) {
		const forma = formaDeConfiguracion(model, grupo.arquitectura_id);
		if (!forma) continue;
		const clave = `${grupo.dimension} · ${grupo.alcance}`;
		const bucket = filas.get(clave) ?? new Set();
		bucket.add(forma.slug);
		filas.set(clave, bucket);
	}
	return [...filas.entries()]
		.sort((a, b) => a[0].localeCompare(b[0], 'es'))
		.map(([clave, formas]) => ({ clave, formas: [...formas].sort() }));
}

function matrizAmbitoRima(model) {
	const filas = new Map();
	for (const patron of model.patronesRima) {
		const forma = formaDeConfiguracion(model, patron.arquitectura_id);
		if (!forma) continue;
		const bucket = filas.get(patron.ambito) ?? new Map();
		bucket.set(forma.slug, (bucket.get(forma.slug) ?? 0) + 1);
		filas.set(patron.ambito, bucket);
	}
	return [...filas.entries()]
		.sort((a, b) => a[0].localeCompare(b[0], 'es'))
		.map(([ambito, formas]) => ({
			ambito,
			total: [...formas.values()].reduce((suma, valor) => suma + valor, 0),
			formas: [...formas.entries()]
				.sort((a, b) => a[0].localeCompare(b[0], 'es'))
				.map(([slug, total]) => `${slug}×${total}`)
		}));
}

// --------------------------------------------------------------------------
// Bloque 3 · Cobertura del contrato del registrador
// --------------------------------------------------------------------------

function coberturaContrato(model, contratoPath) {
	let texto;
	try {
		texto = readFileSync(contratoPath, 'utf-8').toLowerCase();
	} catch {
		return null;
	}
	return model.formas
		.filter((forma) => forma.tipo_registro === 'forma')
		.filter((forma) => {
			const nombre = String(forma.nombre).toLowerCase();
			const slug = String(forma.slug).replace(/_/g, ' ');
			return !texto.includes(nombre) && !texto.includes(slug);
		})
		.map((forma) => forma.slug)
		.sort();
}

// --------------------------------------------------------------------------
// Informe
// --------------------------------------------------------------------------

const celda = (valor) => String(valor ?? '').replace(/\|/g, '\\|');

function construirInforme(model) {
	const lineas = [];
	const escribir = (texto = '') => lineas.push(texto);

	const formasReales = model.formas.filter((forma) => forma.tipo_registro === 'forma');
	const salidas = model.formas.filter((forma) => forma.tipo_registro === 'sin_forma');

	escribir('# Informe de conformidad del catálogo métrico');
	escribir();
	escribir(`Generado: ${new Date().toISOString().slice(0, 16).replace('T', ' ')}`);
	escribir();
	escribir(
		`Inventario: ${formasReales.length} formas y ${salidas.length} tramos sin forma · ` +
			`${model.configuraciones.length} configuraciones · ${model.patronesMetricos.length} patrones métricos · ` +
			`${model.patronesRima.length} patrones de rima · ${model.secciones.length} secciones · ` +
			`${model.grupos.length} grupos de elección · ${model.opciones.length} opciones · ` +
			`${model.rasgos.length} rasgos.`
	);
	escribir();
	escribir(
		'Criterios aplicados: [criterios-de-nivel.md](./criterios-de-nivel.md). ' +
			'El bloque 1 recoge incumplimientos que no dependen de una decisión editorial. ' +
			'El bloque 2 describe dónde vive cada dimensión para que las divergencias de criterio sean visibles.'
	);
	escribir();

	escribir('## 1 · Defectos');
	escribir();
	let totalDefectos = 0;
	for (const defecto of DEFECTOS) {
		const hallazgos = defecto.detectar(model);
		totalDefectos += hallazgos.length;
		escribir(`### ${defecto.id} · ${defecto.titulo} — ${hallazgos.length}`);
		escribir();
		escribir(`> ${defecto.criterio}`);
		escribir();
		if (hallazgos.length === 0) {
			escribir('Sin incidencias.');
		} else {
			escribir('| Sujeto | Detalle |');
			escribir('| --- | --- |');
			for (const hallazgo of hallazgos) {
				escribir(`| ${celda(hallazgo.sujeto)} | ${celda(hallazgo.detalle)} |`);
			}
		}
		escribir();
	}

	escribir('## 2 · Homogeneidad de criterio');
	escribir();
	escribir('### 2.1 · Dónde vive cada dimensión, forma por forma');
	escribir();
	escribir('| Forma | Nivel | Cfg | Prot. | Medida vive en | Rima vive en | Grupos | Alcance |');
	escribir('| --- | --- | ---: | :-: | --- | --- | ---: | --- |');
	const fichas = fichaPorForma(model);
	for (const ficha of fichas) {
		escribir(
			`| ${ficha.forma}${ficha.general ? ' ·gral' : ''} | ${ficha.nivel} | ${ficha.configuraciones} | ` +
				`${ficha.principal ? 'sí' : '—'} | ${ficha.medida.join(', ') || '—'} | ` +
				`${ficha.rima.join(', ') || '—'} | ${ficha.grupos} | ${ficha.alcances.join(', ') || '—'} |`
		);
	}
	escribir();

	const porVia = new Map();
	for (const ficha of fichas) {
		for (const via of ficha.medida) {
			const bucket = porVia.get(via) ?? [];
			bucket.push(ficha.forma);
			porVia.set(via, bucket);
		}
	}
	escribir('### 2.2 · Reparto de la medida');
	escribir();
	escribir('| Vía | Formas |');
	escribir('| --- | --- |');
	for (const [via, formas] of [...porVia.entries()].sort()) {
		escribir(`| ${via} (${formas.length}) | ${formas.join(', ')} |`);
	}
	escribir();

	escribir('### 2.3 · Alcance de las preguntas por dimensión');
	escribir();
	escribir('| Dimensión · alcance | Formas |');
	escribir('| --- | --- |');
	for (const fila of matrizAlcance(model)) {
		escribir(`| ${fila.clave} | ${fila.formas.join(', ')} |`);
	}
	escribir();

	escribir('### 2.4 · Ámbito declarado en los patrones de rima');
	escribir();
	escribir('| Ámbito | Total | Formas |');
	escribir('| --- | ---: | --- |');
	for (const fila of matrizAmbitoRima(model)) {
		escribir(`| ${fila.ambito} | ${fila.total} | ${fila.formas.join(', ')} |`);
	}
	escribir();

	escribir('### 2.5 · Cómo se resuelve la rima que la norma no fija');
	escribir();
	escribir('| Configuración | Patrones abiertos | Estrategia |');
	escribir('| --- | ---: | --- |');
	for (const fila of estrategiasRimaVariable(model)) {
		escribir(`| ${celda(fila.configuracion)} | ${fila.patrones} | ${celda(fila.estrategia)} |`);
	}
	escribir();

	escribir('### 2.6 · Esquemas que coinciden literalmente en varias formas');
	escribir();
	escribir(
		'Coincidencia literal no implica error: puede tratarse de la misma disposición sobre metros distintos. Solo debe reutilizarse cuando una forma es componente de la otra (véase D8).'
	);
	escribir();
	escribir('| Esquema | Formas |');
	escribir('| --- | --- |');
	for (const fila of esquemasCoincidentes(model)) {
		escribir(`| ${celda(fila.esquema)} | ${fila.formas.join(', ')} |`);
	}
	escribir();

	const sinContrato = coberturaContrato(
		model,
		fileURLToPath(
			new URL('../docs/dominio-metrico/contratos-registrador-formas-revisadas.md', import.meta.url)
		)
	);
	escribir('## 3 · Cobertura del contrato del registrador');
	escribir();
	if (sinContrato === null) {
		escribir('No se encontró el documento de contratos.');
	} else if (sinContrato.length === 0) {
		escribir('Todas las formas aparecen en el contrato del registrador.');
	} else {
		escribir(
			`Formas sin contrato editorial declarado (${sinContrato.length}): ${sinContrato.join(', ')}.`
		);
	}
	escribir();

	escribir('---');
	escribir();
	escribir(`Total de defectos detectados: ${totalDefectos}.`);
	escribir();

	return { texto: lineas.join('\n'), totalDefectos };
}

// --------------------------------------------------------------------------

const options = parseArguments(process.argv.slice(2));
const dumpPath = options.dump ?? dumpLinkedDatabase();
const tables = readDump(dumpPath);

// `opciones_eleccion_metrica` dejó de ser una tabla el 11 de agosto de 2026: hoy es una vista
// derivada de `opciones_eleccion_derivadas()`. **Un volcado de datos no contiene vistas**, así
// que desde ese día el informe leía cero opciones y decía «0 defectos» sin haber mirado ninguna:
// D5, D6 y D12 y las matrices de opciones corrían en vacío. Se pide por consulta, que es
// exactamente para lo que existe `consulta.mjs`.
if (tables.get('opciones_eleccion_metrica')?.length !== undefined) {
	// Nada que hacer: el volcado la traía, luego volvió a ser una tabla.
} else if (!options.dump) {
	tables.set('opciones_eleccion_metrica', query('select * from public.opciones_eleccion_metrica'));
} else {
	console.error(
		'Aviso: con --dump no se pueden leer las opciones de elección, que hoy son una vista.\n' +
			'El informe saldrá sin D5, D6, D12 ni las matrices de opciones.'
	);
}

const model = build(tables);

if (model.formas.length === 0) {
	console.error(
		'El volcado no contiene formas métricas. ¿Es un volcado del esquema public con datos?'
	);
	process.exit(1);
}
if (model.opciones.length === 0) {
	console.error(
		'El modelo no tiene ninguna opción de elección. Con 62 grupos activos eso no puede ser: ' +
			'algo dejó de leerse y el informe diría «0 defectos» sin haber mirado.'
	);
	process.exit(1);
}

const { texto, totalDefectos } = construirInforme(model);

if (options.markdown) {
	writeFileSync(options.markdown, `${texto}\n`);
	console.log(`Informe escrito en ${options.markdown} · ${totalDefectos} defectos.`);
} else {
	console.log(texto);
}
