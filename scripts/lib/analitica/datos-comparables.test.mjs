import { describe, it, expect } from 'vitest';
import {
	normalizarDatosComparables,
	precomputarDatosComparables,
	rangosArquitectura
} from './datos-comparables.mjs';
import {
	seleccionarAportacion,
	precomputarAportacion,
	precomputarReferente
} from './aportaciones.mjs';
import { readFileSync } from 'node:fs';

const sec = (extra = {}) => ({
	ref: 's1',
	v_ini: 1,
	v_fin: 100,
	forma_slug: 'romance',
	arquitectura_slug: 'octosilabo',
	detalles: [],
	desviaciones: [],
	segmentacion: 'confirmada',
	...extra
});
const fuente = (tipo = 'basica', secuencias = [sec()], realizaciones = []) => ({
	tipo,
	secuencias,
	evidencia_adicional: { realizaciones }
});
const refs = {
	metros: { m7: { slug: 'heptasilabo' }, m11: { slug: 'endecasilabo' } },
	rasgos: { vocal: { slug: 'vocales_asonancia' }, distico: { slug: 'distico_final' } },
	valores: {
		io: { slug: 'i-o', rasgo_id: 'vocal' },
		presente: { slug: 'presente', rasgo_id: 'distico' }
	},
	arquitecturas: { octo: { slug: 'octosilabo' }, hepta: { slug: 'heptasilabo' } },
	secciones: {
		remate: { slug: 'remate', tipo_seccion: 'remate' },
		tercetos: { slug: 'tercetos', tipo_seccion: 'parte' }
	},
	rimas: {
		r1: { slug: 'abba', notacion: 'ABBA', arquitectura_id: 'octo' },
		r2: { slug: 'abba', notacion: 'abba', arquitectura_id: 'hepta' },
		r3: { slug: 'cdc-dcd', notacion: 'CDC DCD', arquitectura_id: 'octo', seccion_id: 'tercetos' }
	},
	esquemas_metricos: { em: { slug: '7-11', arquitectura_id: 'octo' } },
	repeticiones: { rep: { slug: 'estribillo' } },
	variedades: { var: { slug: 'copla-estribillo' } }
};
const normal = (a) => normalizarDatosComparables(a, refs);
const resumen = (a) => precomputarDatosComparables(normal(a));

describe('correspondencia de evidencia básica y v2', () => {
	it('la misma asonancia explícita produce el mismo dato desde ambos orígenes', () => {
		const b = normal(
			fuente('basica', [
				sec({ detalles: [{ rasgo_slug: 'vocales_asonancia', valor_slug: 'i-o', literal: '-io' }] })
			])
		);
		const d = normal(
			fuente('detallada', [sec({ detalles: [{ dimension: 'rasgo', valor_rasgo_id: 'io' }] })])
		);
		expect(b.secuencias[0].datos_comparables).toEqual(d.secuencias[0].datos_comparables);
	});
	it('la asonancia literal sin valor normalizado sigue siendo texto', () => {
		const a = normal(
			fuente('basica', [sec({ detalles: [{ dimension: 'asonancia', literal: '-io' }] })])
		);
		expect(a.secuencias[0].datos_comparables).toEqual([]);
		expect(a.secuencias[0].notas_no_estructuradas).toHaveLength(1);
	});
	it('el dístico final es rasgo; no fabrica una sección de remate', () => {
		const r = resumen(
			fuente('basica', [
				sec({ detalles: [{ rasgo_slug: 'distico_final', valor_slug: 'presente' }] })
			])
		);
		expect(r.valores.map((v) => v.dimension)).toEqual(['rasgo']);
		expect(r.cobertura.find((c) => c.dimension === 'remate').sin_dato).toBe(1);
	});
	it('un remate final de dos versos coincide con su realización v2', () => {
		const b = normal(
			fuente('basica', [
				sec({ detalles: [{ tipo_seccion: 'remate', n_versos: 2, posicion: 'final' }] })
			])
		);
		const d = normal(
			fuente(
				'detallada',
				[sec()],
				[{ realizacion_id: 'r', secuencia_id: 's1', v_ini: 99, v_fin: 100, seccion_id: 'remate' }]
			)
		);
		expect(b.secuencias[0].datos_comparables).toEqual(d.secuencias[0].datos_comparables);
		expect(precomputarDatosComparables(d).valores[0].extension_documentada).toBe(2);
	});
	it('una definición de remate sin realización no inventa presencia', () => {
		expect(resumen(fuente('detallada')).valores).toEqual([]);
	});
	it('el remate 3+1 conserva exactamente un verso', () => {
		const r = resumen(
			fuente('basica', [
				sec({
					forma_slug: 'terceto_encadenado',
					detalles: [{ tipo_seccion: 'remate', n_versos: 1 }]
				})
			])
		);
		expect(r.valores[0].extension_documentada).toBe(1);
	});
	it('no acepta remates más largos que su secuencia', () => {
		const a = normal(
			fuente('basica', [sec({ detalles: [{ tipo_seccion: 'remate', n_versos: 101 }] })])
		);
		expect(a.incidencias_datos_comparables[0].codigo).toBe('remate_fuera_de_secuencia');
	});
	it('una desviación métrica identifica la medida observada sin cambiar la forma', () => {
		const a = normal(
			fuente('detallada', [
				sec({
					desviaciones: [
						{
							dimension: 'metro',
							relacion_norma: 'menor_que_norma',
							v_ini: 20,
							v_fin: 20,
							metro_observado_id: 'm7'
						}
					]
				})
			])
		);
		const r = precomputarDatosComparables(a);
		expect(r.valores[0]).toMatchObject({
			dimension: 'desviacion',
			metro_observado: 'heptasilabo',
			extension_documentada: 1
		});
		expect(a.secuencias[0].forma_slug).toBe('romance');
	});
});

describe('contexto y denominadores', () => {
	it('respeta la escala por verso y no promedia igual dos pasajes de longitudes distintas', () => {
		const referencias = {
			...refs,
			rasgos: { ...refs.rasgos, vocal: { slug: 'vocales_asonancia', escala_recuento: 'verso' } }
		};
		const a = normalizarDatosComparables(
			fuente('basica', [
				sec({ v_fin: 10, detalles: [{ rasgo_slug: 'vocales_asonancia', valor_slug: 'a-e' }] }),
				sec({
					ref: 's2',
					v_ini: 11,
					detalles: [{ rasgo_slug: 'vocales_asonancia', valor_slug: 'i-o' }]
				})
			]),
			referencias
		);
		const r = precomputarDatosComparables(a).valores.find((v) => v.valor === 'a-e');
		expect(r.proporcion_en_secuencias_con_dato).toBeNull();
		expect(r.posiciones_del_ambito_anotado).toMatchObject({
			numerador: 10,
			denominador: 100,
			proporcion: 0.1
		});
	});
	it('conserva cero numérico y falso como respuestas, no como datos ausentes', () => {
		const referencias = {
			...refs,
			rasgos: {
				n: { slug: 'recuento', tipo_valor: 'numero' },
				b: { slug: 'indicador', tipo_valor: 'booleano' }
			},
			preguntas: { pn: { rasgo_id: 'n' }, pb: { rasgo_id: 'b' } }
		};
		const a = normalizarDatosComparables(
			fuente('detallada', [
				sec({
					detalles: [
						{ dimension: 'rasgo', grupo_eleccion_id: 'pn', valor_texto: '0' },
						{ dimension: 'rasgo', grupo_eleccion_id: 'pb', valor_texto: 'false' }
					]
				})
			]),
			referencias
		);
		expect(a.secuencias[0].datos_comparables.map((h) => h.valor)).toEqual([0, false]);
		expect(
			precomputarDatosComparables(a).cobertura.find((c) => c.dimension === 'rasgo')
				.secuencias_con_dato
		).toBe(1);
	});
	it('no convierte el silencio básico en cero ni en prevalencia total', () => {
		const r = resumen(
			fuente('basica', [
				sec(),
				sec({ ref: 's2', detalles: [{ rasgo_slug: 'distico_final', valor_slug: 'presente' }] })
			])
		);
		expect(r.cobertura.find((c) => c.dimension === 'rasgo')).toMatchObject({
			secuencias_con_dato: 1,
			sin_dato: 1,
			denominador_secuencias: 2
		});
		expect(r.valores[0]).toMatchObject({
			denominador_con_dato: 1,
			proporcion_en_secuencias_con_dato: 1,
			prevalencia_total: null,
			secuencias_de_la_forma: 2
		});
	});
	it('cero de desviaciones solo para una detallada anotada, sin aplicarlo a la no migrada', () => {
		const r = resumen(
			fuente('detallada', [sec({ n_anotaciones: 1 }), sec({ ref: 's2', n_anotaciones: 0 })])
		);
		expect(r.cobertura.find((c) => c.dimension === 'desviacion')).toMatchObject({
			ausencias_comprobadas: 1,
			sin_dato: 1
		});
		expect(
			resumen(fuente()).cobertura.find((c) => c.dimension === 'desviacion').ausencias_comprobadas
		).toBe(0);
	});
	it('varias realizaciones no duplican la presencia por secuencia', () => {
		const a = fuente(
			'detallada',
			[
				sec({
					detalles: [
						{ dimension: 'rasgo', valor_rasgo_id: 'io', realizacion_id: 'r1' },
						{ dimension: 'rasgo', valor_rasgo_id: 'io', realizacion_id: 'r2' }
					]
				})
			],
			[
				{ realizacion_id: 'r1', secuencia_id: 's1', v_ini: 1, v_fin: 50 },
				{ realizacion_id: 'r2', secuencia_id: 's1', v_ini: 51, v_fin: 100 }
			]
		);
		const v = resumen(a).valores[0];
		expect(v.secuencias_con_evidencia).toBe(1);
		expect(v.evidencias).toHaveLength(2);
	});
	it('no confunde una respuesta por posición con un metro de toda la tirada', () => {
		const a = normal(
			fuente('detallada', [
				sec({ detalles: [{ dimension: 'metro', metro_id: 'm7', posicion_unidad: 1 }] })
			])
		);
		const v = a.secuencias[0].datos_comparables[0];
		expect(v.ambito).toMatchObject({
			tipo: 'posicion',
			posicion_unidad: 1,
			v_ini: null,
			v_fin: null
		});
		expect(precomputarDatosComparables(a).valores[0].extension_documentada).toBeNull();
	});
	it('una medida admitida por la arquitectura no genera un reparto de 7 y 11', () => {
		expect(
			resumen(
				fuente('detallada', [sec({ detalles: [{ dimension: 'metro', esquema_metrico_id: 'em' }] })])
			).valores[0]
		).toMatchObject({ dimension: 'esquema_metrico', valor: '7-11', extension_documentada: null });
	});
	it('conserva mayúsculas de rima y separa esquemas homónimos de arquitecturas distintas', () => {
		const a = fuente('detallada', [
			sec({
				detalles: [
					{ dimension: 'rima', esquema_rima_id: 'r1' },
					{ dimension: 'rima', esquema_rima_id: 'r2' }
				]
			})
		]);
		const r = resumen(a);
		expect(r.valores).toHaveLength(2);
		expect(new Set(r.valores.map((v) => v.notacion))).toEqual(new Set(['ABBA', 'abba']));
	});
	it('las disposiciones libres anotadas son datos, no notas ni recuentos silábicos', () => {
		const r = resumen(
			fuente('detallada', [
				sec({
					detalles: [
						{ dimension: 'rima', valor_texto: 'AaBb' },
						{ dimension: 'metro', valor_texto: '8 7 8' }
					]
				})
			])
		);
		expect(r.valores.map((v) => v.valor)).toEqual(expect.arrayContaining(['AaBb', '8 7 8']));
		expect(r.valores.every((v) => v.extension_documentada === null)).toBe(true);
	});
	it('conserva la sección descrita por un esquema aunque no traiga realización', () => {
		const a = normal(
			fuente('detallada', [sec({ detalles: [{ dimension: 'rima', esquema_rima_id: 'r3' }] })])
		);
		expect(a.secuencias[0].datos_comparables[0].ambito).toMatchObject({
			tipo: 'seccion',
			seccion: 'tercetos',
			v_ini: null,
			v_fin: null
		});
	});
	it('resuelve repeticiones y variedades sin convertirlas en forma', () => {
		const a = normal(
			fuente('detallada', [
				sec({
					detalles: [
						{ dimension: 'repeticion', repeticion_id: 'rep' },
						{ dimension: 'combinacion', variedad_id: 'var' }
					]
				})
			])
		);
		expect(a.secuencias[0].datos_comparables.map((h) => h.dimension)).toEqual([
			'repeticion',
			'variedad'
		]);
		expect(a.secuencias[0].forma_slug).toBe('romance');
	});
	it('una referencia rota produce incidencia en lugar de dato inventado', () => {
		const a = normal(
			fuente('detallada', [sec({ detalles: [{ dimension: 'metro', metro_id: 'inexistente' }] })])
		);
		expect(a.incidencias_datos_comparables[0].codigo).toBe('referencia_no_resuelta:metros');
		expect(a.secuencias[0].datos_comparables).toEqual([]);
	});
	it('la extensión de desviaciones solapadas usa unión y conserva ceros observados', () => {
		const a = fuente('basica', [
			sec({
				desviaciones: [
					{ dimension: 'estructura', relacion_norma: 'sobra', v_ini: 10, v_fin: 12 },
					{ dimension: 'estructura', relacion_norma: 'sobra', v_ini: 12, v_fin: 14 }
				]
			})
		]);
		expect(resumen(a).valores[0].extension_documentada).toBe(5);
	});
});

describe('arquitecturas y casos del piloto', () => {
	it('no acepta una arquitectura de otra forma aunque comparta el mismo slug', () => {
		const referencias = {
			...refs,
			formas: { otra: { slug: 'otra_forma' } },
			arquitecturas: { octo: { slug: 'octosilabo', forma_id: 'otra' } }
		};
		const a = normalizarDatosComparables(
			fuente(
				'detallada',
				[sec()],
				[{ secuencia_id: 's1', arquitectura_id: 'octo', v_ini: 1, v_fin: 100 }]
			),
			referencias
		);
		expect(a.incidencias_datos_comparables[0].codigo).toBe('arquitectura_realizada_de_otra_forma');
		expect(a.secuencias[0].arquitecturas_realizadas).toEqual([]);
	});
	it('reparte arquitectura realizada y mantiene la forma completa como denominador', () => {
		const a = normal({
			...fuente(
				'detallada',
				[sec()],
				[{ secuencia_id: 's1', arquitectura_id: 'hepta', v_ini: 40, v_fin: 49 }]
			),
			obra_id: 'obra',
			fuente: { id: 'f' },
			metadatos: { fecha_inicio: 1600, fecha_fin: 1601 },
			jornadas: [{ ref: 'j', v_ini: 1, v_fin: 100 }],
			autorias: []
		});
		const p = precomputarAportacion(a, [
			{ slug: 'romance', arquitecturas: ['octosilabo', 'heptasilabo'] }
		]);
		expect(
			p.medidas.perfil_arquitecturas[0].valores.map((v) => [v.arquitectura_slug, v.versos])
		).toEqual([
			['heptasilabo', 10],
			['octosilabo', 90]
		]);
		expect(p.medidas.perfil_formas[0].versos).toBe(100);
	});
	it('no atribuye un remate ni una respuesta global fuera de la jornada del autor', () => {
		const a = normal({
			...fuente(
				'detallada',
				[sec({ detalles: [{ dimension: 'rasgo', valor_rasgo_id: 'io' }] })],
				[{ secuencia_id: 's1', seccion_id: 'remate', v_ini: 99, v_fin: 100 }]
			),
			obra_id: 'obra',
			fuente: { id: 'f' },
			metadatos: { fecha_inicio: 1600, fecha_fin: 1601 },
			jornadas: [
				{ ref: 'j1', v_ini: 1, v_fin: 50 },
				{ ref: 'j2', v_ini: 51, v_fin: 100 }
			],
			autorias: [{ autor_id: 'a', ambito: 'jornada', v_ini: 1, v_fin: 50 }]
		});
		const r = precomputarReferente([a], [{ slug: 'romance', arquitecturas: ['octosilabo'] }], {
			autor_id: 'a'
		});
		expect(r.extension).toBe(50);
		expect(r.datos_adicionales.valores).toEqual([]);
		expect(r.datos_adicionales.cobertura.find((c) => c.dimension === 'remate').sin_dato).toBe(1);
		expect(r.datos_adicionales.ambito).toBe('partes_atribuidas_de_secuencias');
	});
	it('dos obras con la misma referencia local no duplican ni fusionan sus evidencias', () => {
		const a = normal({
			...fuente('basica', [
				sec({ detalles: [{ rasgo_slug: 'distico_final', valor_slug: 'presente' }] })
			]),
			obra_id: 'obra1',
			fuente: { id: 'f' },
			metadatos: { fecha_inicio: 1600, fecha_fin: 1601 },
			jornadas: [{ ref: 'j', v_ini: 1, v_fin: 100 }],
			autorias: [{ autor_id: 'a', ambito: 'obra' }]
		});
		const b = structuredClone(a);
		b.obra_id = 'obra2';
		const r = precomputarReferente([a, b], [{ slug: 'romance', arquitecturas: ['octosilabo'] }], {
			autor_id: 'a'
		});
		expect(r.datos_adicionales.valores[0].secuencias_con_evidencia).toBe(2);
		expect(
			precomputarReferente([a, b], [{ slug: 'romance', arquitecturas: ['octosilabo'] }], {
				autor_id: 'a',
				excluir_obra_id: 'obra1'
			}).datos_adicionales.valores[0].secuencias_con_evidencia
		).toBe(1);
	});
	it('una realización intercalada reemplaza su rango sin duplicar versos', () => {
		const a = normal(
			fuente(
				'detallada',
				[sec()],
				[{ secuencia_id: 's1', arquitectura_id: 'hepta', v_ini: 40, v_fin: 49 }]
			)
		);
		expect(
			rangosArquitectura(a.secuencias[0]).map((r) => [r.v_fin - r.v_ini + 1, r.arquitectura_slug])
		).toEqual([
			[39, 'octosilabo'],
			[10, 'heptasilabo'],
			[51, 'octosilabo']
		]);
	});
	it('un conflicto entre arquitecturas queda pendiente, no se cuenta dos veces', () => {
		const s = sec({
			arquitecturas_realizadas: [
				{ v_ini: 1, v_fin: 50, arquitectura_slug: 'a' },
				{ v_ini: 40, v_fin: 60, arquitectura_slug: 'b' }
			]
		});
		expect(rangosArquitectura(s).find((r) => r.conflicto)).toMatchObject({
			v_ini: 40,
			v_fin: 50,
			arquitectura_slug: null
		});
	});
	it('el piloto aporta todos sus rasgos, remates y desviaciones sin cambiar las formas', () => {
		const read = (p) =>
			JSON.parse(
				readFileSync(
					new URL('../../../docs/importador-metrico/piloto/' + p, import.meta.url),
					'utf8'
				)
			);
		const cat = read('catalogo-referencia.json').formas.map((f) => ({
			slug: f.slug,
			arquitecturas: f.arquitecturas.map((a) => a.slug)
		}));
		const resultados = {};
		for (const ref of [
			'el-molino',
			'el-verdadero-amante',
			'los-donaires-de-matico',
			'los-locos-de-valencia'
		]) {
			const d = read('preparadas/' + ref + '.json').datos;
			const antes = JSON.stringify(d);
			const a = seleccionarAportacion({
				obra_id: ref,
				publicada: false,
				basica: {
					usada_en_corpus: true,
					importacion_id: ref,
					autor_id: 'lope',
					datos_confirmados: d
				}
			});
			const p = precomputarAportacion(a, cat);
			expect(p.medidas.datos_adicionales.incidencias).toEqual([]);
			expect(JSON.stringify(d)).toBe(antes);
			resultados[ref] = p.medidas.datos_adicionales;
		}
		expect(
			resultados['el-molino'].valores.find((v) => v.propiedad === 'distico_final')
				.secuencias_con_evidencia
		).toBe(2);
		expect(
			resultados['el-verdadero-amante'].valores
				.filter((v) => v.dimension === 'remate')
				.reduce((n, v) => n + v.extension_documentada, 0)
		).toBe(4);
		expect(
			resultados['los-locos-de-valencia'].valores.filter((v) => v.dimension === 'desviacion')
		).toHaveLength(2);
		expect(resultados['los-donaires-de-matico'].valores).toEqual([]);
	});
});
