import { describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';
import {
	seleccionarAportacion,
	precomputarAportacion,
	precomputarReferente,
	huella
} from './aportaciones.mjs';

const catalogo = [
	{ slug: 'redondilla', arquitecturas: [] },
	{ slug: 'romance', arquitecturas: ['octosilabo'] },
	{ slug: 'cancion', arquitecturas: ['petrarquista'] },
	{ slug: 'verso_aislado', arquitecturas: ['heptasilabo', 'endecasilabo'] },
	{ slug: 'versificacion_irregular', arquitecturas: [] }
];
const sec = (ref, i, f, forma, extra = {}) => ({
	ref,
	v_ini: i,
	v_fin: f,
	forma_slug: forma,
	arquitectura_slug: null,
	segmentacion: 'confirmada',
	detalles: [],
	desviaciones: [],
	...extra
});
const fuente = (extra = {}) => ({
	obra_id: 'obra1',
	tipo: 'detallada',
	fuente: { id: 'v2', huella: 'hash' },
	metadatos: { titulo: 'Prueba', edicion_base: 'Edición A', fecha_inicio: 1580, fecha_fin: 1590 },
	jornadas: [{ ref: 'j1', v_ini: 1, v_fin: 1000 }],
	autorias: [{ autor_id: 'autor1', ambito: 'obra', jornada_id: null, v_ini: null, v_fin: null }],
	secuencias: [
		sec('s1', 1, 600, 'redondilla'),
		sec('s2', 601, 800, 'romance'),
		sec('s3', 801, 1000, null)
	],
	...extra
});
const calcular = (a) => precomputarAportacion(a, catalogo);
const referente = (a, opciones = {}) =>
	precomputarReferente(a, catalogo, { autor_id: 'autor1', ...opciones });

describe('parte confirmada y exactitud', () => {
	it('600/1000 y 200 pendientes, sin renormalizar ni prometer diversidad exacta', () => {
		const m = calcular(fuente()).medidas;
		expect(m.cobertura_formas).toEqual({ identificados: 800, pendientes: 200, denominador: 1000 });
		expect(m.perfil_formas[0].proporcion_confirmada).toBe(0.6);
		expect(m.perfil_formas[0].proporcion_total.valor).toBeNull();
		expect(m.n_formas_observadas).toBe(2);
		expect(m.numero_efectivo_formas.valor).toBeNull();
	});
	it('una ausencia solo es cero exacto con clasificación completa', () => {
		const p = referente([fuente()]).perfil_formas.find((f) => f.forma_slug === 'cancion');
		expect(p.versos_confirmados).toBe(0);
		expect(p.proporcion_total).toEqual({ valor: null, motivo: 'forma_pendiente' });
		const a = fuente();
		a.secuencias[2].forma_slug = 'redondilla';
		expect(
			referente([a]).perfil_formas.find((f) => f.forma_slug === 'cancion').proporcion_total.valor
		).toBe(0);
	});
	it('señala una publicada sin v2 y conserva pendiente su forma, sin rellenarla', () => {
		const a = fuente();
		a.secuencias[2].n_anotaciones = 0;
		const p = calcular(a);
		expect(p.incidencias).toContain('publicacion:secuencia_sin_anotacion_v2');
		expect(p.medidas.cobertura_formas.pendientes).toBe(200);
		expect(p.medidas.n_formas.valor).toBeNull();
	});
	it('Canción cuenta aunque su arquitectura sea desconocida', () => {
		const m = calcular(fuente({ secuencias: [sec('s', 1, 1000, 'cancion')] })).medidas;
		expect(m.cobertura_formas.pendientes).toBe(0);
		expect(m.cobertura_arquitecturas.pendientes).toBe(1000);
		expect(m.numero_efectivo_formas.valor).toBe(1);
	});
	it('aislados e irregularidad cuentan como clases; las medidas no desdoblan la forma', () => {
		const a = fuente({
			secuencias: [
				sec('a', 1, 1, 'verso_aislado', { arquitectura_slug: 'heptasilabo' }),
				sec('b', 2, 2, 'verso_aislado', { arquitectura_slug: 'endecasilabo' }),
				sec('c', 3, 1000, 'versificacion_irregular')
			]
		});
		expect(calcular(a).medidas.n_formas.valor).toBe(2);
	});
	it('ni una adición ni una laguna atribuida se suman o restan otra vez al total', () => {
		const a = fuente({
			secuencias: [
				sec('s', 1, 1000, 'redondilla', {
					desviaciones: [
						{ v_ini: 10, v_fin: 10, dimension: 'estructura', relacion_norma: 'sobra' },
						{ v_ini: 20, v_fin: 22, dimension: 'estructura', relacion_norma: 'falta' },
						{ v_ini: 22, v_fin: 23, dimension: 'estructura', relacion_norma: 'falta' }
					]
				})
			]
		});
		expect(calcular(a).medidas.extension).toBe(1000);
		expect(calcular(a).medidas.versos_reconstruidos_atribuidos).toBe(4);
	});
	it.each([
		['hueco', [sec('a', 1, 500, 'romance'), sec('b', 502, 1000, 'romance')]],
		['solape', [sec('a', 1, 501, 'romance'), sec('b', 501, 1000, 'romance')]],
		['rango inválido', [sec('a', 1, 0, 'romance')]],
		['catálogo inexistente', [sec('a', 1, 1000, 'inventada')]],
		['arquitectura ajena', [sec('a', 1, 1000, 'redondilla', { arquitectura_slug: 'octosilabo' })]],
		['varias anotaciones', [sec('a', 1, 1000, 'romance', { n_anotaciones: 2 })]]
	])('un origen inválido (%s) queda excluido, nunca como cero', (_nombre, secuencias) => {
		const a = fuente({ secuencias });
		expect(calcular(a).valida).toBe(false);
		expect(calcular(a).medidas).toBeNull();
		expect(referente([a]).extension).toBe(0);
		expect(referente([a]).perfil_formas[0].proporcion_total.motivo).toBe('sin_muestra');
	});
});

describe('segmentación y extremos', () => {
	it('no convierte filas provisionales en secuencias ni transiciones exactas', () => {
		const a = fuente();
		a.secuencias[0].segmentacion = 'provisional';
		const m = calcular(a).medidas;
		expect(m.extension).toBe(1000);
		expect(m.segmentacion.filas_origen).toBe(3);
		expect(m.segmentacion.n_secuencias.valor).toBeNull();
		expect(m.segmentacion.transiciones).toBeNull();
	});
	it('incluye la transición entre jornadas y no salta por encima de una forma pendiente', () => {
		const a = fuente({
			jornadas: [
				{ ref: 'j1', v_ini: 1, v_fin: 600 },
				{ ref: 'j2', v_ini: 601, v_fin: 1000 }
			]
		});
		const m = calcular(a).medidas;
		expect(m.segmentacion.transiciones.limites_totales).toBe(2);
		expect(m.segmentacion.transiciones.limites_evaluables).toBe(1);
		expect(m.segmentacion.transiciones.pares_identificados).toEqual([
			{ de: 'redondilla', a: 'romance', cambio_jornada: true }
		]);
		expect(m.segmentacion.transiciones.limites_con_forma_pendiente).toBe(1);
		expect(m.extremos_jornadas[1]).toMatchObject({ apertura: 'romance', cierre: null });
	});
});

describe('fuente, autoría y cronología', () => {
	const read = (ref) =>
		JSON.parse(
			readFileSync(
				new URL(`../../../docs/importador-metrico/piloto/preparadas/${ref}.json`, import.meta.url),
				'utf8'
			)
		).datos;
	const registro = () => ({
		obra_id: 'obra1',
		publicada: false,
		basica: {
			importacion_id: 'importacion1',
			autor_id: 'autor1',
			usada_en_corpus: true,
			datos_confirmados: read('el-molino')
		},
		detallada: {
			...fuente(),
			metadatos: { titulo: 'Nuevo borrador', fecha_inicio: 1700, fecha_fin: 1701 }
		}
	});
	it('usa edición, fechas y estructura de la copia fija mientras hay borrador', () => {
		const a = seleccionarAportacion(registro());
		expect(a.metadatos.titulo).toBe('El molino');
		expect(a.metadatos.fecha_inicio).toBe(1585);
		expect(a.secuencias).toHaveLength(21);
		expect(a.autorias[0].autor_id).toBe('autor1');
	});
	it('la copia guardada confirma límites aun con el antiguo marcador provisional', () => {
		const r = registro(),
			antes = structuredClone(r.basica.datos_confirmados);
		const a = seleccionarAportacion(r);
		const cat = JSON.parse(
			readFileSync(
				new URL(
					'../../../docs/importador-metrico/piloto/catalogo-referencia.json',
					import.meta.url
				),
				'utf8'
			)
		).formas.map((f) => ({ slug: f.slug, arquitecturas: f.arquitecturas.map((a) => a.slug) }));
		const limites = precomputarAportacion(a, cat).medidas.segmentacion.transiciones;
		expect(limites.limites_totales).toBe(20);
		expect(limites.limites_evaluables).toBe(18);
		expect(limites.limites_con_forma_pendiente).toBe(2);
		expect(limites.pares_identificados.some((p) => !p.de || !p.a)).toBe(false);
		expect(r.basica.datos_confirmados).toEqual(antes);
	});
	it('publicar sustituye la básica, sin rellenar la detallada ni duplicar el aporte', () => {
		const r = registro();
		r.publicada = true;
		const a = seleccionarAportacion(r);
		expect(a.tipo).toBe('detallada');
		expect(a.metadatos.titulo).toBe('Nuevo borrador');
		expect(a.secuencias[2].forma_slug).toBeNull();
		expect(a.fuente.id).toBe('obra1');
	});
	it('no reactiva una copia retirada ni inventa una fuente publicada', () => {
		const r = registro();
		r.basica.usada_en_corpus = false;
		expect(seleccionarAportacion(r)).toBeNull();
		r.publicada = true;
		r.detallada = null;
		expect(() => seleccionarAportacion(r)).toThrow();
	});
	it('pondera por versos, no promedia porcentajes de obras de distinto tamaño', () => {
		const a = fuente({ secuencias: [sec('s', 1, 1000, 'redondilla')] });
		const b = fuente({
			obra_id: 'obra2',
			jornadas: [{ ref: 'j1', v_ini: 1, v_fin: 100 }],
			secuencias: [sec('s', 1, 100, 'romance')]
		});
		const r = referente([a, b]);
		expect(r.extension).toBe(1100);
		expect(r.perfil_formas[0].proporcion_total.valor).toBeCloseTo(1000 / 1100);
	});
	it('conserva atribución por jornada y recorta una secuencia que atraviesa el límite', () => {
		const a = fuente({
			autorias: [
				{ autor_id: 'autor1', ambito: 'jornada', jornada_id: 'j2', v_ini: 601, v_fin: 1000 }
			]
		});
		const r = referente([a]);
		expect(r.extension).toBe(400);
		expect(r.pendiente).toBe(200);
		expect(r.perfil_formas[0].versos_confirmados).toBe(0);
		expect(referente([a], { excluir_obra_id: 'obra1' }).extension).toBe(0);
	});
	it('una atribución de obra y sus jornadas no duplican versos', () => {
		const a = fuente();
		a.autorias.push({ autor_id: 'autor1', ambito: 'jornada', v_ini: 1, v_fin: 500 });
		expect(referente([a]).extension).toBe(1000);
	});
	it('rechaza dos aportaciones de la misma obra en vez de duplicar el denominador', () => {
		expect(() => referente([fuente(), fuente()])).toThrow('Una sola aportación');
	});
	it('combina básica y detallada del mismo autor bajo un único denominador', () => {
		const basica = seleccionarAportacion(registro());
		// Añadimos el catálogo del piloto, sin adjudicar la básica a partir de su título.
		const cat = JSON.parse(
			readFileSync(
				new URL(
					'../../../docs/importador-metrico/piloto/catalogo-referencia.json',
					import.meta.url
				),
				'utf8'
			)
		).formas.map((f) => ({ slug: f.slug, arquitecturas: f.arquitecturas.map((a) => a.slug) }));
		const detallada = fuente({ obra_id: 'otra', secuencias: [sec('s', 1, 1000, 'redondilla')] });
		const r = precomputarReferente([basica, detallada], cat, { autor_id: 'autor1' });
		expect(r.obras.map((o) => o.tipo)).toEqual(['basica', 'detallada']);
		expect(r.extension).toBe(3992);
		expect(r.pendiente).toBe(9);
		expect(r.perfil_formas.find((f) => f.forma_slug === 'redondilla').versos_confirmados).toBe(
			2708
		);
	});
	it('el orden de entrada de las secuencias no cambia el recorte de autoría', () => {
		const a = fuente();
		a.secuencias.reverse();
		expect(referente([a]).extension).toBe(1000);
	});
	it('rechaza solapamientos y atribuciones fuera del ámbito', () => {
		const a = fuente({
			autorias: [
				{ autor_id: 'autor1', ambito: 'jornada', v_ini: 1, v_fin: 500 },
				{ autor_id: 'autor1', ambito: 'jornada', v_ini: 500, v_fin: 800 }
			]
		});
		expect(referente([a]).excluidas[0].motivo).toContain('solapados');
		a.autorias = [{ autor_id: 'autor1', ambito: 'jornada', v_ini: 1, v_fin: 1200 }];
		expect(referente([a]).excluidas[0].motivo).toBe('autoria_fuera_de_la_fuente');
	});
	it('solapamiento de fechas inclusivo, sin asignar al año medio', () => {
		expect(referente([fuente()], { periodo: [1580, 1581] }).extension).toBe(1000);
		expect(referente([fuente()], { periodo: [1590, 1591] }).extension).toBe(1000);
		expect(referente([fuente()], { periodo: [1591, 1592] }).extension).toBe(0);
	});
	it('una fecha ausente no se convierte en cero ni excluye del perfil sin filtro', () => {
		const a = fuente();
		a.metadatos.fecha_inicio = null;
		expect(referente([a]).extension).toBe(1000);
		expect(referente([a], { periodo: [1580, 1590] }).excluidas[0].motivo).toBe(
			'sin_intervalo_valido'
		);
	});
	it('no presenta silencio como ausencia ni emite afinidad no validada', () => {
		expect(calcular(fuente()).fenomenos.valor).toBeNull();
		expect(referente([fuente()]).comparacion_afinidad.motivo).toBe('metodo_no_validado');
	});
	it('la huella no depende del orden de las claves', () => {
		expect(huella({ b: 2, a: { d: 4, c: 3 } })).toBe(huella({ a: { c: 3, d: 4 }, b: 2 }));
	});
});
