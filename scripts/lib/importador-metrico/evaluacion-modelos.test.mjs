import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { evaluarRespuestaModelo } from './evaluacion-modelos.mjs';
const gold = JSON.parse(
	readFileSync(
		new URL(
			'../../../docs/importador-metrico/piloto/extracciones/los-locos-de-valencia.json',
			import.meta.url
		),
		'utf8'
	)
);
const evaluar = (d) => evaluarRespuestaModelo(JSON.stringify(d), gold);
describe('cotejo de modelos de extracción', () => {
	it('separa un número escrito como texto de una lectura numérica distinta, sin aceptar ni corregir la respuesta', () => {
		const d = structuredClone(gold);
		d.tramos[0].pagina = String(gold.tramos[0].pagina);
		d.tramos[1].v_fin = String(gold.tramos[1].v_fin + 1);
		const resultado = evaluar(d);
		expect(resultado.diferencias_formato.map((x) => x.ruta)).toEqual(['tramos.0.pagina']);
		expect(resultado.diferencias.map((x) => x.ruta)).toContain('tramos.1.v_fin');
		expect(resultado.estructura_valida).toBe(false);
		expect(resultado.lista_para_importar_sin_corregir).toBe(false);
		expect(typeof d.tramos[0].pagina).toBe('string');
	});
	it('acepta la transcripción de referencia sin premiar un nombre de proveedor', () =>
		expect(evaluar(gold).lista_para_importar_sin_corregir).toBe(true));
	it('no confunde mismo total con mismos rangos', () => {
		const d = structuredClone(gold);
		d.tramos[0].v_fin++;
		d.tramos[1].v_ini++;
		expect(evaluar(d).diferencias.some((x) => x.ruta === 'tramos.0.v_fin')).toBe(true);
		expect(evaluar(d).lista_para_importar_sin_corregir).toBe(false);
	});
	it('detecta omisión de notas y de sus vínculos aunque la tabla sea correcta', () => {
		const d = structuredClone(gold);
		d.notas = [];
		expect(evaluar(d).diferencias.some((x) => x.ruta === 'notas')).toBe(true);
	});
	it('no penaliza el cambio coherente de los identificadores de notas', () => {
		const d = structuredClone(gold);
		for (const n of d.notas) {
			for (const t of d.tramos)
				t.notas_ref = t.notas_ref.map((id) => (id === n.id ? 'nuevo-' + id : id));
			n.id = 'nuevo-' + n.id;
		}
		expect(evaluar(d).diferencias).toEqual([]);
	});
	it('no convierte texto explicativo o una salida truncada en JSON válido', () => {
		expect(evaluarRespuestaModelo('Aquí tienes: ' + JSON.stringify(gold), gold).json_valido).toBe(
			false
		);
		expect(evaluarRespuestaModelo('{', gold).json_valido).toBe(false);
	});
	it('los bloques de código admitidos por el importador se registran como tales', () => {
		expect(
			evaluarRespuestaModelo('```json\n' + JSON.stringify(gold) + '\n```', gold)
		).toMatchObject({
			json_valido: true,
			formato: 'bloque_json',
			lista_para_importar_sin_corregir: true
		});
	});
});
