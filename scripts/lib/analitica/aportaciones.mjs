/** Núcleo del ensayo de precomputación. Sin DB, red ni uso desde las páginas. */
import { createHash } from 'node:crypto';
import { fichaMinimaSchema } from '../importador-metrico/ficha-minima.mjs';
import {
	normalizarDatosComparables,
	precomputarDatosComparables,
	rangosArquitectura,
	recortarSecuenciaComparable,
	precomputarArquitecturas
} from './datos-comparables.mjs';

export const VERSION_CALCULO = 'perfil-comparable-ensayo/0.3';
const ordenar = (a, b) => a.v_ini - b.v_ini || a.v_fin - b.v_fin;
const longitud = (r) => r.v_fin - r.v_ini + 1;
const clonar = (v) => structuredClone(v);
const canonico = (v) =>
	Array.isArray(v)
		? v.map(canonico)
		: v && typeof v === 'object'
			? Object.fromEntries(
					Object.keys(v)
						.sort()
						.map((k) => [k, canonico(v[k])])
				)
			: v;
export const huella = (v) =>
	createHash('sha256')
		.update(JSON.stringify(canonico(v)))
		.digest('hex');
const sinValor = (motivo) => ({ valor: null, motivo });

/** Se decide ANTES de traducir: una detallada publicada no se rellena desde la básica. */
export function seleccionarAportacion(registro, referencias = {}) {
	if (registro.publicada) {
		if (!registro.detallada) throw Error('Publicada sin fuente detallada');
		const d = registro.detallada;
		return normalizarDatosComparables(
			{
				obra_id: registro.obra_id,
				tipo: 'detallada',
				fuente: { id: registro.obra_id, huella: huella(d), version: 'anotacion-v2' },
				metadatos: clonar(d.metadatos),
				jornadas: clonar(d.jornadas),
				autorias: clonar(d.autorias),
				secuencias: d.secuencias.map((s) => ({ ...clonar(s), segmentacion: 'confirmada' })),
				evidencia_adicional: clonar(d.evidencia_adicional)
			},
			referencias
		);
	}
	const i = registro.basica;
	if (!i?.usada_en_corpus) return null;
	const d = fichaMinimaSchema.parse(i.datos_confirmados);
	return normalizarDatosComparables(
		{
			obra_id: registro.obra_id,
			tipo: 'basica',
			fuente: {
				id: i.importacion_id,
				huella: huella(d),
				version: d.esquema,
				procedencia: clonar(d.procedencia)
			},
			metadatos: clonar(d.metadatos),
			jornadas: d.jornadas.map((j) => ({ ...clonar(j), ref: `j${j.numero}` })),
			autorias: [
				{ autor_id: i.autor_id, ambito: 'obra', jornada_id: null, v_ini: null, v_fin: null }
			],
			secuencias: d.segmentos.map((s) => ({
				ref: s.ref,
				v_ini: s.v_ini,
				v_fin: s.v_fin,
				forma_slug: s.identificacion?.forma_slug ?? null,
				arquitectura_slug: s.identificacion?.arquitectura_slug ?? null,
				// La copia persistida acredita la aceptación de la división, también en importaciones
				// anteriores que conservaron por defecto el marcador provisional de la vista previa.
				segmentacion: 'confirmada',
				detalles: clonar(s.detalles_fuente),
				desviaciones: clonar(s.desviaciones)
			})),
			evidencia_adicional: { recogida_exhaustiva: false }
		},
		referencias
	);
}

function validarRangos(filas, nombre, incidencias) {
	if (!filas.length) incidencias.push(`${nombre}:sin_rangos`);
	for (const [i, r] of filas.entries()) {
		if (
			!Number.isSafeInteger(r.v_ini) ||
			!Number.isSafeInteger(r.v_fin) ||
			r.v_ini <= 0 ||
			r.v_fin < r.v_ini
		)
			incidencias.push(`${nombre}:rango_invalido`);
		if (i && r.v_ini !== filas[i - 1].v_fin + 1) incidencias.push(`${nombre}:hueco_o_solape`);
	}
}

function unionLongitudes(rangos) {
	let total = 0,
		fin = -1;
	for (const r of [...rangos].sort(ordenar)) {
		total += Math.max(0, r.v_fin - Math.max(r.v_ini, fin + 1) + 1);
		fin = Math.max(fin, r.v_fin);
	}
	return total;
}

/** Valida la fuente completa antes de calcular. Un fallo no se convierte en cero. */
export function precomputarAportacion(a, catalogo) {
	const incidencias = [];
	const secuencias = [...a.secuencias].sort(ordenar);
	const jornadas = [...a.jornadas].sort(ordenar);
	validarRangos(secuencias, 'secuencias', incidencias);
	validarRangos(jornadas, 'jornadas', incidencias);
	if (new Set(secuencias.map((s) => s.ref)).size !== secuencias.length)
		incidencias.push('secuencias:referencias_duplicadas');
	if (
		secuencias[0]?.v_ini !== jornadas[0]?.v_ini ||
		secuencias.at(-1)?.v_fin !== jornadas.at(-1)?.v_fin
	)
		incidencias.push('extension:no_coinciden_extremos');
	if (a.metadatos.fecha_inicio == null || a.metadatos.fecha_fin == null)
		incidencias.push('fechas:sin_intervalo');
	else if (a.metadatos.fecha_inicio > a.metadatos.fecha_fin)
		incidencias.push('fechas:intervalo_invertido');
	const formas = new Map(catalogo.map((f) => [f.slug, f]));
	for (const s of secuencias) {
		for (const r of s.arquitecturas_realizadas ?? []) {
			if (
				!Number.isInteger(r.v_ini) ||
				!Number.isInteger(r.v_fin) ||
				r.v_ini < s.v_ini ||
				r.v_fin > s.v_fin ||
				r.v_fin < r.v_ini ||
				!formas.get(s.forma_slug)?.arquitecturas.includes(r.arquitectura_slug)
			)
				incidencias.push('arquitectura:realizacion_invalida');
		}
		if (s.n_anotaciones > 1) incidencias.push('anotacion:varias_por_secuencia');
		if (a.tipo === 'detallada' && s.n_anotaciones === 0)
			incidencias.push('publicacion:secuencia_sin_anotacion_v2');
		if (!['provisional', 'confirmada'].includes(s.segmentacion))
			incidencias.push('segmentacion:estado_invalido');
		if (s.forma_slug && !formas.has(s.forma_slug)) incidencias.push('forma:ajena_al_catalogo');
		if (
			s.arquitectura_slug &&
			!formas.get(s.forma_slug)?.arquitecturas.includes(s.arquitectura_slug)
		)
			incidencias.push('arquitectura:ajena_a_la_forma');
		for (const d of s.desviaciones) {
			if (
				!Number.isSafeInteger(d.v_ini) ||
				!Number.isSafeInteger(d.v_fin) ||
				d.v_fin < d.v_ini ||
				d.v_ini < s.v_ini ||
				d.v_fin > s.v_fin
			)
				incidencias.push('desviacion:fuera_de_secuencia');
		}
	}
	// La incidencia editorial se comunica sin inventar forma ni cambiar la publicación.
	// El reparto confirmado puede conservarse; las medidas exactas dependen de su cobertura.
	const invalidas = incidencias.filter(
		(i) => !i.startsWith('fechas:') && !i.startsWith('publicacion:')
	);
	const base = {
		esquema: VERSION_CALCULO,
		obra_id: a.obra_id,
		tipo: a.tipo,
		fuente: clonar(a.fuente),
		metadatos: clonar(a.metadatos),
		autorias: clonar(a.autorias),
		incidencias: [...new Set(incidencias)],
		// El ensayo no transforma silencios en ausencia de canto, prosa u otros fenómenos.
		fenomenos: sinValor('fuera_del_calculo_de_este_ensayo'),
		valida: invalidas.length === 0
	};
	if (invalidas.length) return { ...base, medidas: null };
	const total = secuencias.reduce((n, s) => n + longitud(s), 0);
	const grupos = new Map();
	let pendiente = 0,
		arquitecturaConocida = 0,
		arquitecturaPendiente = 0,
		arquitecturaNoAplica = 0;
	const reconstruidos = [];
	for (const s of secuencias) {
		const n = longitud(s);
		if (!s.forma_slug) pendiente += n;
		else {
			const g = grupos.get(s.forma_slug) ?? {
				forma_slug: s.forma_slug,
				versos: 0,
				arquitecturas: {}
			};
			g.versos += n;
			for (const r of rangosArquitectura(s)) {
				const extension = longitud(r);
				if (r.conflicto) base.incidencias.push('arquitectura:realizaciones_en_conflicto');
				if (r.arquitectura_slug) {
					g.arquitecturas[r.arquitectura_slug] =
						(g.arquitecturas[r.arquitectura_slug] ?? 0) + extension;
					arquitecturaConocida += extension;
				} else if (!formas.get(s.forma_slug).arquitecturas.length)
					arquitecturaNoAplica += extension;
				else arquitecturaPendiente += extension;
			}
			grupos.set(s.forma_slug, g);
		}
		for (const d of s.desviaciones)
			if (d.dimension === 'estructura' && d.relacion_norma === 'falta') reconstruidos.push(d);
	}
	const completa = pendiente === 0;
	const confirmada = secuencias.every((s) => s.segmentacion === 'confirmada');
	const perfil = [...grupos.values()]
		.sort((a, b) => a.forma_slug.localeCompare(b.forma_slug))
		.map((g) => ({
			...g,
			proporcion_confirmada: g.versos / total,
			proporcion_total: completa
				? { valor: g.versos / total, motivo: null }
				: sinValor('forma_pendiente')
		}));
	const pares = [];
	let limitesPendientes = 0;
	for (let i = 1; i < secuencias.length; i++) {
		const de = secuencias[i - 1],
			a = secuencias[i];
		const cambioJornada = jornadas.some((j) => j.v_ini === a.v_ini);
		if (!de.forma_slug || !a.forma_slug) limitesPendientes++;
		else pares.push({ de: de.forma_slug, a: a.forma_slug, cambio_jornada: cambioJornada });
	}
	return {
		...base,
		medidas: {
			perfil_arquitecturas: precomputarArquitecturas(secuencias, catalogo),
			datos_adicionales: precomputarDatosComparables(a),
			extension: total,
			versos_reconstruidos_atribuidos: unionLongitudes(reconstruidos),
			cobertura_formas: {
				identificados: total - pendiente,
				pendientes: pendiente,
				denominador: total
			},
			cobertura_arquitecturas: {
				conocidas: arquitecturaConocida,
				pendientes: arquitecturaPendiente,
				no_aplica: arquitecturaNoAplica,
				forma_pendiente: pendiente,
				denominador: total
			},
			perfil_formas: perfil,
			n_formas_observadas: perfil.length,
			n_formas: completa ? { valor: perfil.length, motivo: null } : sinValor('forma_pendiente'),
			numero_efectivo_formas: completa
				? {
						valor: Math.exp(
							-perfil.reduce(
								(h, g) => h + g.proporcion_confirmada * Math.log(g.proporcion_confirmada),
								0
							)
						),
						motivo: null
					}
				: sinValor('forma_pendiente'),
			segmentacion: {
				confirmada,
				filas_origen: secuencias.length,
				n_secuencias: confirmada
					? { valor: secuencias.length, motivo: null }
					: sinValor('segmentacion_provisional'),
				densidad_secuencias: confirmada
					? { valor: (100 * secuencias.length) / total, motivo: null }
					: sinValor('segmentacion_provisional'),
				transiciones: confirmada
					? {
							limites_totales: secuencias.length - 1,
							limites_evaluables: pares.length,
							pares_identificados: pares,
							limites_con_forma_pendiente: limitesPendientes
						}
					: null
			},
			extremos_jornadas: jornadas.map((j) => ({
				ref: j.ref,
				apertura:
					secuencias.find((s) => s.v_ini <= j.v_ini && s.v_fin >= j.v_ini)?.forma_slug ?? null,
				cierre: secuencias.find((s) => s.v_ini <= j.v_fin && s.v_fin >= j.v_fin)?.forma_slug ?? null
			}))
		}
	};
}

/** Referente descriptivo, no una distancia de afinidad ni inferencia probabilística. */
export function precomputarReferente(
	aportaciones,
	catalogo,
	{ autor_id, excluir_obra_id = null, periodo = null }
) {
	if (new Set(aportaciones.map((a) => a.obra_id)).size !== aportaciones.length)
		throw Error('Una sola aportación por obra antes de agregar');
	if (
		periodo &&
		(!Number.isInteger(periodo[0]) || !Number.isInteger(periodo[1]) || periodo[0] > periodo[1])
	)
		throw Error('Periodo inválido');
	const seleccion = [],
		excluidas = [];
	for (const a of aportaciones) {
		if (a.obra_id === excluir_obra_id) continue; // Excluye TODAS sus jornadas.
		const unidades = a.autorias.filter((u) => u.autor_id === autor_id);
		if (!unidades.length) continue;
		if (periodo) {
			const { fecha_inicio: ini, fecha_fin: fin } = a.metadatos;
			if (ini == null || fin == null || ini > fin) {
				excluidas.push({ obra_id: a.obra_id, motivo: 'sin_intervalo_valido' });
				continue;
			}
			if (ini > periodo[1] || fin < periodo[0]) continue;
		}
		const obra = unidades.some((u) => u.ambito === 'obra');
		const rangos = obra ? a.jornadas : unidades.map((u) => ({ v_ini: u.v_ini, v_fin: u.v_fin }));
		// No sumar dos veces atribuciones superpuestas o mezclar obra+jornadas del mismo autor.
		const ordenados = [...rangos].sort(ordenar);
		if (
			ordenados.some(
				(r, i) =>
					!Number.isInteger(r.v_ini) ||
					!Number.isInteger(r.v_fin) ||
					r.v_fin < r.v_ini ||
					(i && r.v_ini <= ordenados[i - 1].v_fin)
			)
		) {
			excluidas.push({ obra_id: a.obra_id, motivo: 'autoria_con_rangos_invalidos_o_solapados' });
			continue;
		}
		const p = precomputarAportacion(a, catalogo);
		if (!p.valida) {
			excluidas.push({ obra_id: a.obra_id, motivo: 'fuente_invalida' });
			continue;
		}
		const limitesFuente = [...a.secuencias].sort(ordenar);
		if (
			ordenados.some(
				(r) => r.v_ini < limitesFuente[0].v_ini || r.v_fin > limitesFuente.at(-1).v_fin
			)
		) {
			excluidas.push({ obra_id: a.obra_id, motivo: 'autoria_fuera_de_la_fuente' });
			continue;
		}
		const origen = a.secuencias.every((s) => Array.isArray(s.datos_comparables))
			? a
			: normalizarDatosComparables(a);
		const secuencias = origen.secuencias.flatMap((s) =>
			ordenados
				.map((r) => recortarSecuenciaComparable(s, r, a.obra_id, a.tipo))
				.filter((s) => s.v_ini <= s.v_fin)
		);
		const extension = secuencias.reduce((n, s) => n + longitud(s), 0);
		if (!extension) {
			excluidas.push({ obra_id: a.obra_id, motivo: 'autoria_sin_cobertura' });
			continue;
		}
		seleccion.push({
			obra_id: a.obra_id,
			tipo: a.tipo,
			unidades: obra ? 1 : unidades.length,
			ambito: obra ? 'obra' : 'jornada',
			extension,
			secuencias
		});
	}
	const secuencias = seleccion.flatMap((s) => s.secuencias);
	const total = seleccion.reduce((n, s) => n + s.extension, 0);
	const pendiente = secuencias.filter((s) => !s.forma_slug).reduce((n, s) => n + longitud(s), 0);
	return {
		esquema: VERSION_CALCULO,
		permiso: 'interno',
		autor_id,
		excluir_obra_id,
		periodo,
		criterio_fechas: 'solapamiento_sin_fecha_media',
		obras: seleccion.map(({ secuencias: _s, ...r }) => r),
		excluidas,
		extension: total,
		pendiente,
		perfil_arquitecturas: precomputarArquitecturas(secuencias, catalogo),
		datos_adicionales: {
			...precomputarDatosComparables({ tipo: 'mixto', secuencias }),
			ambito: seleccion.some((s) => s.ambito === 'jornada')
				? 'partes_atribuidas_de_secuencias'
				: 'secuencias'
		},
		perfil_formas: catalogo.map((f) => {
			const versos = secuencias
				.filter((s) => s.forma_slug === f.slug)
				.reduce((n, s) => n + longitud(s), 0);
			return {
				forma_slug: f.slug,
				versos_confirmados: versos,
				denominador: total,
				proporcion_confirmada: total ? versos / total : null,
				proporcion_total: !total
					? sinValor('sin_muestra')
					: pendiente
						? sinValor('forma_pendiente')
						: { valor: versos / total, motivo: null }
			};
		}),
		comparacion_afinidad: sinValor('metodo_no_validado')
	};
}
