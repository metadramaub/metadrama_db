import { readFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { normalizarExtraccion, informeNormalizacion } from './normalizacion.mjs';

const read = (file) =>
	JSON.parse(
		readFileSync(
			new URL(`../../../docs/importador-metrico/piloto/${file}`, import.meta.url),
			'utf8'
		)
	);
const reglas = read('equivalencias.propuestas.json');
const catalogo = read('catalogo-referencia.json');
const fuentes = read('fuentes.json');
const bibliografia = read('bibliografia-contraste.json');
const raw = (ref = 'los-locos-de-valencia') => read(`extracciones/${ref}.json`);
const context = (extra = {}) => ({
	reglas: structuredClone(reglas),
	catalogo: structuredClone(catalogo),
	fuentes,
	bibliografia,
	...extra
});
const approval = {
	responsable: 'Revisor de prueba',
	fecha: '2026-10-22',
	fundamento: 'Decisión sintética para probar el flujo; no es una aprobación del piloto'
};

describe('normalizador local', () => {
	it('la CLI verifica los derivados y sus entradas aceptadas sin escribir', () => {
		const result = spawnSync(
			process.execPath,
			[
				fileURLToPath(new URL('../../importador-metrico/normalizar-piloto.mjs', import.meta.url)),
				'--comprobar'
			],
			{ encoding: 'utf8' }
		);
		expect(result.status, result.stderr).toBe(0);
		expect(JSON.parse(result.stdout)).toMatchObject({
			obras: 4,
			versos: 11754,
			forma_revisada: 237
		});
	});
	it('la CLI rechaza opciones no declaradas antes de regenerar archivos', () => {
		const result = spawnSync(
			process.execPath,
			[
				fileURLToPath(new URL('../../importador-metrico/normalizar-piloto.mjs', import.meta.url)),
				'--aplicar'
			],
			{ encoding: 'utf8' }
		);
		expect(result.status).toBe(64);
	});
	it('conserva la transcripción, las fechas y todos los versos de las cuatro obras', () => {
		let total = 0;
		for (const ref of [
			'el-verdadero-amante',
			'los-donaires-de-matico',
			'el-molino',
			'los-locos-de-valencia'
		]) {
			const input = raw(ref);
			const before = structuredClone(input);
			const result = normalizarExtraccion(input, context());
			expect(input).toEqual(before);
			expect(result.metadatos).toEqual(input.metadatos);
			expect(result.segmentos.map((s) => s.fuente)).toEqual(input.tramos);
			expect(result.segmentos).toHaveLength(input.tramos.length);
			expect(result.apta_para_corpus).toBe(false);
			expect(result.cobertura.forma_revisada.versos).toBe(ref === 'el-verdadero-amante' ? 237 : 0);
			total += result.cobertura.versos;
		}
		expect(total).toBe(11754);
	});
	it('no escoge entre terceto y encadenado por nombre, longitud o candidatas', () => {
		const result = normalizarExtraccion(raw('los-donaires-de-matico'), context());
		const row = result.segmentos.find((s) => s.id === 't01');
		expect(row).toMatchObject({
			v_ini: 1,
			v_fin: 127,
			estado_identificacion: 'candidatas',
			identificacion_revisada: null,
			propuesta: null
		});
		expect(row.candidatas.map((c) => c.forma_slug)).toContain('terceto_encadenado');
		expect(result.cobertura.con_candidatas.versos).toBe(272);
	});
	it('no convierte letrilla en forma, canto ni lista exhaustiva', () => {
		const result = normalizarExtraccion(raw('el-molino'), context());
		const row = result.segmentos.find((s) => s.id === 't20');
		expect(row).toMatchObject({
			v_ini: 2880,
			v_fin: 2888,
			estado_identificacion: 'candidatas',
			identificacion_revisada: null,
			propuesta: null,
			caracterizaciones: []
		});
		expect(row.candidatas.map((c) => c.forma_slug)).toEqual([
			'villancico',
			'zejel',
			'romance',
			'romancillo'
		]);
		expect(row.exhaustividad).toBe('no_justificada');
		expect(row.evidencias_bibliograficas).toContain('letrilla_diccionario');
		expect(result.cobertura.con_candidatas.versos).toBe(9);
		expect(result.cobertura.versos).toBe(2992);
	});
	it('identifica las estancias como Canción con remate, sin exigir arquitectura ni cotejar el texto', () => {
		const result = normalizarExtraccion(raw('el-verdadero-amante'), context());
		const row = result.segmentos.find((s) => s.id === 't02');
		expect(row).toMatchObject({
			v_ini: 221,
			v_fin: 287,
			estado_identificacion: 'revisada',
			identificacion_revisada: { forma_slug: 'cancion', arquitectura_slug: null },
			propuesta: null,
			candidatas: []
		});
		expect(row.detalles_fuente).toContainEqual(
			expect.objectContaining({ literal: 'pareado final', tipo_seccion: 'remate', n_versos: 2 })
		);
		expect(result.cobertura.forma_revisada.versos).toBe(237);
		expect(result.cobertura.arquitectura_revisada.versos).toBe(0);
	});
	it('interpreta el serventesio final como un terceto encadenado más su remate de un verso', () => {
		const result = normalizarExtraccion(raw('el-verdadero-amante'), context());
		for (const [id, extension] of [
			['t07', 43],
			['t12', 127]
		]) {
			const row = result.segmentos.find((s) => s.id === id);
			expect(row.fuente.denominacion_literal).toBe('tercetos encadenados con serventesio final');
			expect(row.v_fin - row.v_ini + 1).toBe(extension);
			expect((extension - 1) % 3).toBe(0);
			expect(row.identificacion_revisada).toEqual({
				forma_slug: 'terceto_encadenado',
				arquitectura_slug: null
			});
			expect(row.detalles_fuente).toContainEqual(
				expect.objectContaining({
					literal: 'serventesio final',
					tipo_seccion: 'remate',
					n_versos: 1,
					posicion: 'final',
					estado: 'interpretacion_revisada'
				})
			);
			expect(row.propuesta).toBeNull();
		}
		expect(result.segmentos).toHaveLength(19);
		expect(
			result.segmentos.some((s) => s.identificacion_revisada?.forma_slug === 'serventesio')
		).toBe(false);
		expect(result.cobertura.forma_revisada.versos).toBe(237);
		expect(result.cobertura.arquitectura_revisada.versos).toBe(0);
	});
	it('una aprobación explícita identifica solo lo aprobado: forma sin arquitectura', () => {
		const ctx = context();
		ctx.reglas.reglas.find((r) => r.id === 'redondilla').aprobacion = approval;
		const result = normalizarExtraccion(raw(), ctx);
		const row = result.segmentos.find((s) => s.id === 't16');
		expect(row.identificacion_revisada).toEqual({
			forma_slug: 'redondilla',
			arquitectura_slug: null
		});
		expect(row.propuesta).toBeNull();
		expect(row.aprobacion).toEqual(approval);
		expect(result.cobertura.forma_revisada.versos).toBeGreaterThan(133);
		expect(result.cobertura.arquitectura_revisada.versos).toBe(0);
	});
	it('respeta el ámbito por obra y no aprende una equivalencia universal', () => {
		const ctx = context();
		const rule = ctx.reglas.reglas.find((r) => r.id === 'redondilla');
		rule.aprobacion = approval;
		rule.ambito = { obras: ['el-molino'] };
		const result = normalizarExtraccion(raw(), ctx);
		expect(result.segmentos.find((s) => s.id === 't16').estado_identificacion).toBe('sin_resolver');
	});
	it('rechaza reglas ambiguas o ajenas al catálogo', () => {
		const duplicate = context();
		duplicate.reglas.reglas.push({ ...duplicate.reglas.reglas[0], id: 'otra' });
		expect(() => normalizarExtraccion(raw(), duplicate)).toThrow(/conflicto/);
		const bad = context();
		bad.reglas.reglas[0].candidatas[0].arquitectura_slug = 'inventada';
		expect(() => normalizarExtraccion(raw(), bad)).toThrow(/Arquitectura ajena/);
	});
	it('no acepta referencias bibliográficas inexistentes', () => {
		const ctx = context();
		ctx.reglas.reglas
			.find((r) => r.id === 'letrilla')
			.evidencias_bibliograficas.push('referencia_inventada');
		expect(() => normalizarExtraccion(raw(), ctx)).toThrow(/Evidencia bibliográfica no registrada/);
	});
	it('una etiqueta no prevista conserva la fuente y queda pendiente', () => {
		const input = raw();
		input.tramos[0].denominacion_literal = 'término nuevo de edición';
		const result = normalizarExtraccion(input, context());
		expect(result.segmentos[0]).toMatchObject({
			estado_identificacion: 'sin_resolver',
			regla_id: null,
			identificacion_revisada: null,
			propuesta: null
		});
	});
	it('rechaza rangos solapados en vez de producir porcentajes engañosos', () => {
		const input = raw();
		input.tramos[1].v_ini = input.tramos[0].v_fin;
		expect(() => normalizarExtraccion(input, context())).toThrow(/discrepancias técnicas/);
	});
	it('mantiene segmentos sin rango como desconocidos, sin imputar cero versos', () => {
		const input = raw();
		input.tramos[0].v_ini = null;
		input.tramos[0].v_fin = null;
		const result = normalizarExtraccion(input, context());
		expect(result.cobertura.segmentos_sin_rango).toBe(1);
		expect(result.segmentos[0].v_ini).toBeNull();
		expect(result.cobertura.denominador).toBe('union_de_rangos_conocidos');
	});
	it('aplica las desviaciones acordadas sin partir secuencia ni descontar versos de la obra', () => {
		const decisions = [
			{
				obra_ref: 'los-locos-de-valencia',
				tramo_ref: 't13',
				nota_ref: 'n01',
				estado: 'acordada',
				fundamento: 'Decisión del responsable',
				desviacion: {
					v_ini: 2172,
					v_fin: 2172,
					dimension: 'metro',
					relacion_norma: 'menor_que_norma',
					metro_observado_slug: 'heptasilabo'
				}
			},
			{
				obra_ref: 'los-locos-de-valencia',
				tramo_ref: 't16',
				nota_ref: 'n02',
				estado: 'acordada',
				fundamento: 'Decisión del responsable',
				desviacion: { v_ini: 2666, v_fin: 2666, dimension: 'estructura', relacion_norma: 'sobra' }
			}
		];
		const result = normalizarExtraccion(raw(), context({ decisiones: decisions }));
		expect(result.segmentos).toHaveLength(20);
		expect(result.segmentos.find((s) => s.id === 't16')).toMatchObject({
			v_ini: 2622,
			v_fin: 2754,
			desviaciones: [expect.objectContaining({ v_ini: 2666, relacion_norma: 'sobra' })]
		});
		expect(result.cobertura.versos).toBe(3072);
		const wrong = structuredClone(decisions);
		wrong[1].desviacion.v_ini = 2665;
		expect(() => normalizarExtraccion(raw(), context({ decisiones: wrong }))).toThrow(
			/rango documentado/
		);
	});
	it('rechaza aprobaciones incompletas y decisiones sin acordar', () => {
		const ctx = context();
		ctx.reglas.reglas[0].aprobacion = { fecha: '2026-10-22' };
		expect(() => normalizarExtraccion(raw(), ctx)).toThrow();
		expect(() =>
			normalizarExtraccion(
				raw(),
				context({ decisiones: [{ obra_ref: 'los-locos-de-valencia', estado: 'propuesta' }] })
			)
		).toThrow(/sin acordar/);
	});
	it('el informe distingue propuestas de hechos y muestra los rangos de la edición', () => {
		const result = normalizarExtraccion(raw('el-molino'), context());
		const report = informeNormalizacion(result);
		expect(report).toContain('Forma revisada'.toLowerCase());
		expect(report).toContain('2880–2888');
		expect(report).toContain('No importado');
		expect(report).toContain('no son probabilidades');
	});
});
