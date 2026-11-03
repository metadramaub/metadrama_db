import { describe, it, expect } from 'vitest';
import { analizarEntrada, obtenerPilotos, vistaDeFichaGuardada } from '$lib/server/importador-metrico/vista-previa';
import { aplicarEdiciones } from './edicion';
import { datosMetricos } from './presentacion';

function entrada() {
	const raw = JSON.parse(obtenerPilotos()[0].entrada);
	raw.obra_ref = 'prueba-prosa'; raw.notas = []; raw.incidencias = []; raw.resumen_fuente = [];
	raw.jornadas = [{numero:1,rotulo_literal:'Jornada primera'}];
	const fila = (id: string, inicio: number | null, fin: number | null, literal: string) => ({
		id,jornada:1,v_ini:inicio,v_fin:fin,denominacion_literal:literal,
		n_versos_fuente:inicio === null || fin === null ? null : fin-inicio+1,fuente_id:'foto-prosa',pagina:996,notas_ref:[]
	});
	raw.tramos = [fila('t01',1,96,'octavas reales'),fila('t02',null,null,'carta en prosa'),fila('t03',97,120,'octavas reales')];
	return raw;
}

describe('prosa entre tramos de la misma forma', () => {
	it('conserva el original y guarda una sola secuencia con prosa, sin sumar versos', () => {
		const raw = entrada(), original = structuredClone(raw);
		const vista = analizarEntrada(JSON.stringify(raw));
		expect(vista.errores).toEqual([]); expect(raw).toEqual(original);
		expect(vista.datos!.segmentos).toHaveLength(1);
		expect(vista.resumen!.extension).toBe(120);
		expect(vista.datos!.segmentos[0]).toMatchObject({v_ini:1,v_fin:120,
			origen:{tramo_ref:'t01',tramos_ref:['t01','t03']},
			caracterizaciones:[{termino:'prosa',v_ini:96,v_fin:97,tramo_ref:'t02',literal:'carta en prosa'}]});
		expect(datosMetricos(vista.filas[0])).toContainEqual({etiqueta:'Prosa',valor:'Entre vv. 96 y 97'});
		const guardada = vistaDeFichaGuardada(vista.datos as never, raw, {obra_id:'obra',importacion_id:'imp'});
		expect(guardada.filas[0].caracterizaciones).toEqual(vista.filas[0].caracterizaciones);
	});
	it.each(['numerada','forma distinta','sin identificar','jornada distinta','hueco'])('no inventa una unión cuando hay %s', (caso) => {
		const raw = entrada();
		if(caso==='numerada')Object.assign(raw.tramos[1],{v_ini:97,v_fin:120,n_versos_fuente:24});
		if(caso==='forma distinta')raw.tramos[2].denominacion_literal='redondillas';
		if(caso==='sin identificar')raw.tramos[0].denominacion_literal='letrilla';
		if(caso==='jornada distinta'){raw.jornadas.push({numero:2,rotulo_literal:'Jornada segunda'});raw.tramos[2].jornada=2;}
		if(caso==='hueco'){raw.tramos[2].v_ini=98;raw.tramos[2].n_versos_fuente=23;}
		expect(analizarEntrada(JSON.stringify(raw)).errores.length).toBeGreaterThan(0);
	});
	it('no une dos filas contiguas sin prosa', () => {
		const raw=entrada();raw.tramos.splice(1,1);
		expect(analizarEntrada(JSON.stringify(raw)).datos!.segmentos).toHaveLength(2);
	});
	it('encadena varias inserciones y conserva sus localizadores', () => {
		const raw=entrada();raw.tramos.push({...raw.tramos[1],id:'t04'}, {...raw.tramos[2],id:'t05',v_ini:121,v_fin:128,n_versos_fuente:8});
		const vista=analizarEntrada(JSON.stringify(raw));expect(vista.errores).toEqual([]);
		expect(vista.datos!.segmentos[0].caracterizaciones?.map(c=>c.v_ini)).toEqual([96,120]);
		expect(vista.resumen!.extension).toBe(128);
	});
	it('mantiene la prosa al dividir, y rechaza el corte entre sus dos versos de localización', () => {
		const datos=analizarEntrada(JSON.stringify(entrada())).datos!;
		const parte=(v_ini:number,v_fin:number)=>({v_ini,v_fin,identificacion:{forma_slug:'octava_real',arquitectura_slug:'endecasilabica_consonante'},nota:null,remate:null});
		const cambio={tramo_ref:'t01',partes:[parte(1,80),parte(81,120)]};
		const editada=aplicarEdiciones(datos,[cambio]);
		expect(editada.segmentos.map(s=>s.caracterizaciones?.length)).toEqual([0,1]);
		expect(() => aplicarEdiciones(datos,[{...cambio,partes:[parte(1,96),parte(97,120)]}])).toThrow('prosa');
	});
});
