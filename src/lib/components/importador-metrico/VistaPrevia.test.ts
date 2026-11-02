import { describe, expect, it } from 'vitest';
import { render } from 'svelte/server';
import VistaPrevia from './VistaPrevia.svelte';
import { analizarEntrada, obtenerPilotos } from '$lib/server/importador-metrico/vista-previa';

function vista(n: number) {
	const raw=JSON.parse(obtenerPilotos()[0].entrada);
	 raw.obra_ref='obra-importada';raw.jornadas=[{numero:1,rotulo_literal:null}];
	 raw.notas=[];raw.resumen_fuente=[];raw.incidencias=[];
	 raw.tramos=[{id:'t01',jornada:1,v_ini:1,v_fin:n,denominacion_literal:'Redondillas',n_versos_fuente:n,fuente_id:'foto-01',pagina:null,notas_ref:[]}];
	return analizarEntrada(JSON.stringify(raw));
}
const texto = (html: string) => html.replace(/<!--[\s\S]*?-->/g,'').replace(/<[^>]*>/g,' ').replace(/\s+/g,' ');

describe('avisos de longitud en la tabla del importador', () => {
	it('presenta el descuadre en el resumen y la fila, con un filtro específico', () => {
		const {body}=render(VistaPrevia,{props:{vista:vista(53)}});
		expect(texto(body)).toContain('1 secuencia con longitud a revisar');
		expect(texto(body)).toContain('53 versos. Redondilla requiere unidades completas de 4 versos');
		expect(body).toContain('value="longitud"');
	});
	it('no muestra un aviso de descuadre cuando la longitud es compatible', () => {
		const {body}=render(VistaPrevia,{props:{vista:vista(52)}});
		expect(texto(body)).not.toContain('secuencia con longitud a revisar');
		expect(texto(body)).not.toContain('Redondilla requiere');
	});
});
