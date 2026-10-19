import { describe, expect, it } from 'vitest';
import { formasDeFilas, numerosDeFila, tramasDeFormas } from './diagrama-exportacion';
import type { FilaDeBarras } from './MetricBarcodeFigura.svelte';

const fila: FilaDeBarras = {
	etiqueta: 'Jornada 2', desde: 1001, hasta: 2000,
	segmentos: [
		{ id: 'a', forma: 'Romance', v_ini: 950, v_fin: 1100, label: '' },
		{ id: 'b', forma: 'Silva', v_ini: 1101, v_fin: 1102, label: '' },
		{ id: 'c', forma: 'Romance', v_ini: 1103, v_fin: 2000, label: '' },
		{ id: 'd', forma: 'Soneto', v_ini: 2001, v_fin: 2014, label: '' }
	]
};

describe('leyenda del diagrama exportado', () => {
	it('incluye solo formas visibles por primera aparición y reutiliza su número', () => {
		expect(formasDeFilas([{ ...fila, segmentos: [...fila.segmentos].reverse() }])).toEqual([
			{ clave: 'Romance', forma: 'Romance', numero: 1 },
			{ clave: 'Silva', forma: 'Silva', numero: 2 }
		]);
	});
	it('mantiene la numeración entre varias jornadas de una misma imagen', () => {
		const tercera = { ...fila, desde: 2001, hasta: 2100 };
		expect(formasDeFilas([fila, tercera]).map((f) => f.forma)).toEqual(['Romance', 'Silva', 'Soneto']);
	});
});


describe('grises y números', () => {
	it('reserva los contrastes lisos a las formas con tramos más cortos', () => {
		const estilos = tramasDeFormas([fila]);
		expect(estilos.Silva.patron).toBe('liso');
		expect(estilos.Silva.fondo).toBe('#202020');
		expect(estilos.Romance).not.toEqual(estilos.Silva);
	});
	it('deja dentro los números que caben y solo saca fuera los de tramos estrechos', () => {
		const { items } = numerosDeFila(fila, 1000);
		expect(items).toHaveLength(3);
		expect(items[0]).toMatchObject({origen:50,exterior:false,numero:1});
		expect(items[1]).toMatchObject({origen:101,exterior:true,numero:2});
		expect(items[2].exterior).toBe(false);
	});
	it('separa las excepciones próximas sin mover los tramos', () => {
		const densa = { ...fila, segmentos: Array.from({ length: 30 }, (_, i) => ({id:String(i),forma:'Silva',label:'',v_ini:1100+i,v_fin:1100+i})) };
		const {items,alto} = numerosDeFila(densa,834);
		expect(alto).toBeGreaterThan(0);
		for(const item of items){
			expect(Math.abs(item.x-item.origen)).toBeLessThanOrEqual(12);
			expect(item.x).toBeGreaterThanOrEqual(8);
			expect(item.x).toBeLessThanOrEqual(826);
		}
		for(const nivel of new Set(items.map(i=>i.nivel))){
			const grupo=items.filter(i=>i.nivel===nivel);
			for(let i=1;i<grupo.length;i++)expect(grupo[i].x-grupo[i-1].x).toBeGreaterThanOrEqual(20);
		}
	});
	it('no confunde ninguna de las primeras doce muestras', () => {
		const muchas = {...fila,segmentos:Array.from({length:12},(_,i)=>({id:String(i),forma:String(i),label:'',v_ini:1001+i*20,v_fin:1020+i*20}))};
		expect(new Set(Object.values(tramasDeFormas([muchas])).map(s=>JSON.stringify(s))).size).toBe(12);
	});
});
