import { describe, expect, it } from 'vitest';
import { createHash } from 'node:crypto';
import type { FichaMinima } from '$lib/importador-metrico/types';
import { analizarEntrada, obtenerPilotos, obtenerReferenciaImportador } from './vista-previa';
import preparada from '../../../../docs/importador-metrico/piloto/preparadas/el-verdadero-amante.json';

describe('vista previa del importador sin persistencia', () => {
	it.each(obtenerPilotos())('prepara el intercambio real de $titulo', (piloto) => {
		const vista = analizarEntrada(piloto.entrada);
		expect(vista.errores).toEqual([]);
		expect(vista.resumen?.jornadas).toBe(3);
		expect(vista.persistido).toBe(false);
		expect(vista.confirmacion).toBeNull();
		expect(vista.filas.length).toBeGreaterThan(10);
		expect(JSON.parse(JSON.stringify(vista))).toEqual(vista);
	});
	it('permite editar metadatos y vaciar expresamente la fuente opcional', () => {
		const vista = analizarEntrada(obtenerPilotos()[0].entrada, {
			titulo: 'Título revisado',
			fuente_fecha: '',
			fecha_inicio: '1580',
			fecha_fin: '1590'
		});
		expect(vista.errores).toEqual([]);
		expect(vista.datos?.metadatos).toMatchObject({
			titulo: 'Título revisado',
			fuente_fecha: null,
			fecha_inicio: 1580,
			fecha_fin: 1590
		});
	});
	it('no admite fechas vacías ni invertidas', () => {
		expect(
			analizarEntrada(obtenerPilotos()[0].entrada, { fecha_inicio: '' }).errores.length
		).toBeGreaterThan(0);
		expect(
			analizarEntrada(obtenerPilotos()[0].entrada, {
				fecha_inicio: '1600',
				fecha_fin: '1590'
			}).errores.length
		).toBeGreaterThan(0);
	});
	it('corrige las fechas inválidas de la extracción sin cambiar la huella de la fuente original', () => {
		const raw = JSON.parse(obtenerPilotos()[0].entrada);
		raw.metadatos.fecha_inicio = 1600;
		raw.metadatos.fecha_fin = 1500;
		const entrada = JSON.stringify(raw);
		expect(analizarEntrada(entrada).errores.length).toBeGreaterThan(0);
		const corregida = analizarEntrada(entrada, { fecha_inicio: '1580', fecha_fin: '1590' });
		expect(corregida.errores).toEqual([]);
		expect(corregida.datos?.metadatos).toMatchObject({ fecha_inicio: 1580, fecha_fin: 1590 });
		expect(corregida.datos?.procedencia.extraccion_sha256).toBe(
			createHash('sha256').update(entrada).digest('hex')
		);
		expect(JSON.parse(entrada).metadatos.fecha_inicio).toBe(1600);
	});
	it('mantiene las decisiones del piloto al corregir sus metadatos mediante el formulario', () => {
		const entrada = obtenerPilotos().find((p) => p.id === 'los-locos-de-valencia')!.entrada;
		const corregida = analizarEntrada(entrada, { fecha_inicio: '1590', fecha_fin: '1595' });
		expect(corregida.errores).toEqual([]);
		expect(corregida.filas.flatMap((f) => f.desviaciones)).toHaveLength(2);
	});
	it('expone las notas literales de la extracción y no las inventa para una ficha mínima', () => {
		const entrada = obtenerPilotos().find((p) => p.id === 'los-locos-de-valencia')!.entrada;
		const vista = analizarEntrada(entrada);
		const original = JSON.parse(entrada);
		for (const fila of vista.filas) {
			expect(fila.notas_fuente).toEqual(
				original.notas
					.filter(
						(n: { id: string; texto_literal: string | null }) =>
							fila.origen.notas_ref.includes(n.id) && typeof n.texto_literal === 'string'
					)
					.map((n: { id: string; texto_literal: string }) => ({
						id: n.id,
						texto_literal: n.texto_literal
					}))
			);
		}
		expect(vista.filas.flatMap((f) => f.notas_fuente ?? []).length).toBeGreaterThan(0);
		expect(
			analizarEntrada(JSON.stringify(preparada)).filas.every((f) => f.notas_fuente === undefined)
		).toBe(true);
	});
	it.each(['', '{incompleto', '[]', '{"esquema":"inventado"}'])(
		'rechaza entradas mal formadas: %s',
		(texto) => {
			const vista = analizarEntrada(texto);
			expect(vista.errores.length).toBeGreaterThan(0);
			expect(vista.datos).toBeNull();
		}
	);
	it('acepta un bloque JSON y la ficha mínima del piloto', () => {
		const vista = analizarEntrada('```json\n' + JSON.stringify(preparada) + '\n```');
		expect(vista.errores).toEqual([]);
		expect(vista.resumen?.forma_identificada).toBe(67);
		expect(
			vista.filas.find((f) => f.forma_revisada === 'Canción')?.identificacion_revisada
				?.arquitectura_slug
		).toBeNull();
	});
	it('conserva tercetos ambiguos y propuestas sin contarlos como formas revisadas', () => {
		const vista = analizarEntrada(
			obtenerPilotos().find((p) => p.id === 'los-donaires-de-matico')!.entrada
		);
		const tercetos = vista.filas.find((f) => f.candidatas.some((c) => c.forma_slug === 'terceto'));
		expect(tercetos?.estado).toBe('candidatas');
		expect(tercetos?.identificacion_revisada).toBeNull();
		expect(vista.resumen?.solo_propuesta).toBeGreaterThan(0);
		expect(vista.resumen?.forma_identificada).toBe(0);
	});
	it('solo aplica decisiones de desviación al contenido preciso del piloto, no a su obra_ref', () => {
		const original = obtenerPilotos().find((p) => p.id === 'los-locos-de-valencia')!;
		const vista = analizarEntrada(original.entrada);
		expect(vista.filas.flatMap((f) => f.desviaciones)).toHaveLength(2);
		const cambiado = JSON.parse(original.entrada);
		cambiado.metadatos.titulo = 'Otra obra con la misma referencia';
		const suplantada = analizarEntrada(JSON.stringify(cambiado));
		expect(suplantada.errores).toEqual([]);
		expect(suplantada.filas.flatMap((f) => f.desviaciones)).toEqual([]);
	});
	it('ofrece el prompt literal y el carácter local del catálogo', () => {
		expect(obtenerReferenciaImportador().prompt).toContain('Transcribe las fotografías');
		expect(
			analizarEntrada(obtenerPilotos()[0].entrada).avisos.some(
				(a) => a.codigo === 'referencia_local'
			)
		).toBe(true);
	});
	it('distingue por sus nombres las arquitecturas propuestas y candidatas', () => {
		const ficha = structuredClone(preparada.datos) as FichaMinima;
		const segmento = ficha.segmentos.find((s) => s.propuesta?.arquitectura_slug);
		expect(segmento).toBeDefined();
		const destino = segmento!.propuesta!;
		const propuesta = analizarEntrada(JSON.stringify(ficha));
		const nombre = propuesta.filas.find((f) => f.ref === segmento!.ref)?.propuesta_nombre;
		expect(nombre).toContain(' · ');
		expect(nombre).not.toContain(destino.arquitectura_slug);
		segmento!.candidatas = [destino];
		segmento!.propuesta = null;
		segmento!.exhaustividad = 'orientativa';
		const candidatas = analizarEntrada(JSON.stringify(ficha));
		expect(candidatas.errores).toEqual([]);
		expect(candidatas.filas.find((f) => f.ref === segmento!.ref)?.candidatas_nombres).toEqual([
			nombre
		]);
	});
});
