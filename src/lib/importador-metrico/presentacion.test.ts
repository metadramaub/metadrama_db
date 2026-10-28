import { describe, expect, it } from 'vitest';
import { analizarEntrada, obtenerPilotos } from '$lib/server/importador-metrico/vista-previa';
import { datosMetricos, notasMetricas } from './presentacion';

const filas = (obra: string) => analizarEntrada(obtenerPilotos().find((p) => p.id === obra)!.entrada).filas;

describe('datos anotados frente a texto en la tabla del importador', () => {
	it('muestra los valores del catálogo y la extensión de los remates sin abrir el editor', () => {
		const amante = filas('el-verdadero-amante');
		expect(datosMetricos(amante.find((f) => f.ref === 't09')!)).toEqual([{etiqueta: 'Vocales de la asonancia', valor: 'i-o'}]);
		expect(datosMetricos(amante.find((f) => f.ref === 't10')!)).toEqual([{etiqueta: 'Dístico final', valor: 'Presente'}]);
		expect(datosMetricos(amante.find((f) => f.ref === 't07')!)).toEqual([{etiqueta: 'Remate final', valor: '1 verso (3+1)'}]);
		expect(datosMetricos(amante.find((f) => f.ref === 't02')!)).toEqual([{etiqueta: 'Remate final', valor: '2 versos'}]);
	});
	it('separa la desviación estructurada de su nota original y no repite el mismo texto', () => {
		const fila = filas('los-locos-de-valencia').find((f) => f.ref === 't16')!;
		expect(datosMetricos(fila)).toEqual([{etiqueta: 'Desviación estructural', valor: 'v. 2666: Sobra'}]);
		const texto = String(fila.desviaciones[0].texto_fuente);
		expect(notasMetricas(fila).filter((n) => n === texto)).toHaveLength(1);
		expect(datosMetricos(fila).some((d) => d.valor.includes(texto))).toBe(false);
	});
	it('no presenta un literal sin normalizar o una nota libre como un dato de catálogo', () => {
		const fila = filas('el-verdadero-amante')[0];
		fila.detalles_fuente = [{literal: '-io', dimension: 'asonancia'}];
		fila.nota = 'Revisar con la edición.';
		expect(datosMetricos(fila)).toEqual([]);
		expect(notasMetricas(fila)).toEqual(['Asonancia en la fuente: -io', 'Revisar con la edición.']);
	});
});
