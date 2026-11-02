import { describe, expect, it } from 'vitest';
import { render } from 'svelte/server';
import EstadoComprobacion from './EstadoComprobacion.svelte';
import { analizarEntrada, obtenerPilotos } from '$lib/server/importador-metrico/vista-previa';

const base = () => analizarEntrada(obtenerPilotos()[0].entrada);
const texto = (html: string) => html.replace(/<!--[\s\S]*?-->/g,'').replace(/<[^>]*>/g,' ').replace(/\s+/g,' ');
describe('confirmación explícita de comprobación', () => {
	it('confirma el final sin contar los recordatorios del flujo como problemas', () => {
		const vista=base();vista.errores=[];vista.pendientes_metadatos=[];
		vista.avisos=['referencia_local','cotejo_pendiente','segmentacion_provisional'].map(codigo=>({codigo,ruta:'',mensaje:'Recordatorio'}));
		const {body}=render(EstadoComprobacion,{props:{vista}});
		expect(body).toContain('role="status"');
		expect(texto(body)).toContain('Cambios comprobados: sin incidencias detectadas.');
	});
	it('cuenta avisos de longitud y formas pendientes sin declarar éxito completo', () => {
		const vista=base();vista.errores=[];vista.pendientes_metadatos=[];
		vista.avisos=[{codigo:'longitud_metrica',ruta:'',mensaje:'Revisar'},{codigo:'forma_pendiente',ruta:'',mensaje:'Pendiente'}];
		const {body}=render(EstadoComprobacion,{props:{vista}});
		expect(texto(body)).toContain('2 avisos para revisar.');
		expect(texto(body)).toContain('Revisar');
		expect(body).toContain('<li>');
		expect(texto(body)).not.toContain('sin incidencias');
	});
	it('localiza los dos tercetos pendientes junto al aviso de comprobación', () => {
		const vista=analizarEntrada(obtenerPilotos().find((p)=>p.id==='los-donaires-de-matico')!.entrada);
		vista.pendientes_metadatos=[];
		const contenido=texto(render(EstadoComprobacion,{props:{vista}}).body);
		expect(contenido).toContain('Cambios comprobados: 1 aviso para revisar.');
		expect(contenido).toContain('Formas pendientes de identificar: «tercetos» · vv. 1–127; «tercetos» · vv. 1523–1667.');
	});
	it('no anuncia ausencia de incidencias cuando quedan errores o campos obligatorios', () => {
		const vista=base();vista.avisos=[];
		vista.errores=[{codigo:'edicion',ruta:'',mensaje:'Revisar'}];
		expect(texto(render(EstadoComprobacion,{props:{vista}}).body)).toContain('1 error para corregir.');
		vista.errores=[];vista.pendientes_metadatos=[{codigo:'formato',ruta:'metadatos.titulo',mensaje:'Falta título'}];
		expect(texto(render(EstadoComprobacion,{props:{vista}}).body)).toContain('Faltan datos obligatorios de la obra.');
	});
});
