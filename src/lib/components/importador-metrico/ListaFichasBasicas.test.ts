import { describe, expect, it } from 'vitest';
import { render } from 'svelte/server';
import ListaFichasBasicas from './ListaFichasBasicas.svelte';
import type { FilaBasica } from '$lib/server/importador-metrico/persistencia';
const fila = (): FilaBasica => ({ importacion_id: 'imp', obra_id: 'obra', titulo: 'Matico', autor_nombre: 'Lope', importado_por: 'Persona', importado_en: '2026-11-02T12:00:00Z', modificado_en: null, formas_pendientes: [{ denominacion:'tercetos',v_ini:1,v_fin:127 },{ denominacion:'tercetos',v_ini:1523,v_fin:1667 }], comprobacion_registrada: false, avisos_longitud: [], incidencias_fuente: [] });
const texto = (body: string) => body.replace(/<!--[\s\S]*?-->/g,'').replace(/<[^>]*>/g,' ').replace(/\s+/g,' ');
describe('tabla de fichas básicas', () => {
	it('agrupa las formas pendientes y no inventa fecha ni ausencia de avisos antiguos', () => {
		const { body } = render(ListaFichasBasicas,{props:{filas:[fila()]}});
		expect(texto(body)).toContain('tercetos — 1–127, 1523–1667');
		expect(texto(body.slice(body.indexOf('<tbody')))).toContain('No consta');
		expect(texto(body)).toContain('Longitud: sin registro al importar.');
		expect(texto(body)).not.toContain('Sin pendientes registrados');
		expect(body).not.toContain('aria-label="Eliminar Matico"');
	});
	it('ofrece la papelera al permiso explícito y separa avisos de incidencias originales', () => {
		const f=fila(); f.modificado_en=f.importado_en; f.comprobacion_registrada=true;
		f.avisos_longitud=[{segmento_ref:'t01',v_ini:1,v_fin:127,mensaje:'Longitud a revisar'}];
		f.incidencias_fuente=[{descripcion:'Nota recortada'}];
		const {body}=render(ListaFichasBasicas,{props:{filas:[f],puedeEliminar:true,oneliminar:()=>{}}});
		expect(body).toContain('aria-label="Eliminar Matico"');
		expect(texto(body)).toContain('Longitud: 1–127');
		expect(texto(body)).toContain('JSON original: 1 incidencia');
		expect(texto(body.slice(body.indexOf('<tbody')))).not.toContain('No consta');
	});
});
