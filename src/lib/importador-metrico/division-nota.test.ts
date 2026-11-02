import { describe, expect, it } from 'vitest';
import { render } from 'svelte/server';
import { proponerDivisionDesdeNota } from './division-nota';
import type { NotaFuenteImportador } from './types';
import { analizarEntrada, obtenerPilotos, obtenerReferenciaImportador } from '$lib/server/importador-metrico/vista-previa';
import EditorSecuencia from '$lib/components/importador-metrico/EditorSecuencia.svelte';
import VistaPrevia from '$lib/components/importador-metrico/VistaPrevia.svelte';

function entrada() {
	const raw = JSON.parse(obtenerPilotos()[0].entrada);
	raw.obra_ref = 'obra-importada'; raw.jornadas = [{ numero: 1, rotulo_literal: null }];
	raw.resumen_fuente = []; raw.incidencias = [];
	raw.tramos = [
		{ id: 't00', jornada: 1, v_ini: 1, v_fin: 869, denominacion_literal: 'endecasílabos blancos', n_versos_fuente: 869, fuente_id: 'foto-01', pagina: null, notas_ref: [] },
		{ id: 't01', jornada: 1, v_ini: 870, v_fin: 999, denominacion_literal: 'coplas reales', n_versos_fuente: 130, fuente_id: 'foto-01', pagina: null, notas_ref: ['n01'] }
	];
	raw.notas = [{ id: 'n01', marca: '5', texto_literal: 'En los vv. 930-934 hay una quintilla aislada, con rima ccddc. A partir del v. 935 continúa el patrón regular de coplas reales.', fuente_id: 'foto-01', pagina: null, tramos_ref: ['t01'], v_ini: 930, v_fin: 934 }];
	return JSON.stringify(raw);
}
function escenario() {
	const raw = entrada(), vista = analizarEntrada(raw);
	const secuencia = vista.filas[1], nota = secuencia.notas_fuente![0];
	return { raw, vista, secuencia, nota };
}

describe('división propuesta por una nota localizada', () => {
	it('avisa en la tabla sin abrir el editor y retira la propuesta después de dividir', () => {
		const { raw, vista, secuencia, nota } = escenario();
		const mostrar = (datos: typeof vista) => render(VistaPrevia, { props: { vista: datos } }).body
			.replace(/<!--[\s\S]*?-->/g, '').replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ');
		const tabla = mostrar(vista);
		expect(tabla).toContain('Revisar división: la nota describe una quintilla aislada en 930–934');
		expect(tabla).toContain('Propuesta: 60 + 5 + 65 versos');
		expect(tabla).toContain('Al dividir, vv. 935–999: 65 versos. Copla real requiere');
		expect(tabla).not.toContain('Dividir según la nota');
		const propuesta = proponerDivisionDesdeNota(secuencia, nota)!;
		const editada = analizarEntrada(raw, {}, [{ tramo_ref: 't01', partes: propuesta.partes.map((p) => ({ ...p, nota: null, remate: null })) }]);
		const posterior = mostrar(editada);
		expect(posterior).not.toContain('Revisar división:');
		expect(posterior).toContain('65 versos. Copla real requiere');
	});
	it('propone 60 + 5 + 65 y avisa del descuadre aunque el conjunto sea compatible', () => {
		const { secuencia, nota } = escenario();
		const antes = structuredClone({ secuencia, nota });
		expect(secuencia.longitud?.estado).toBe('compatible');
		const propuesta = proponerDivisionDesdeNota(secuencia, nota)!;
		expect(propuesta.partes.map((p) => [p.v_ini, p.v_fin, p.identificacion.forma_slug])).toEqual([
			[870, 929, 'copla_real'], [930, 934, 'quintilla'], [935, 999, 'copla_real']
		]);
		expect(propuesta.avisos.map((p) => p.longitud.estado)).toEqual(['compatible', 'compatible', 'revisar']);
		expect(propuesta.avisos[2].longitud.mensaje).toContain('65 versos');
		expect({ secuencia, nota }).toEqual(antes);
	});
	it.each([
		{ v_ini: 931 }, { v_fin: 935 }, { tramos_ref: ['otra'] },
		{ texto_literal: 'Hay quintillas intercaladas.' },
		{ texto_literal: 'En los vv. 930-934 no hay una quintilla aislada. A partir del v. 935 continúa el patrón regular de coplas reales.' },
		{ texto_literal: 'En los vv. 930-934 hay una quintilla aislada. A partir del v. 936 continúa el patrón regular de coplas reales.' },
		{ texto_literal: 'En los vv. 930-934 hay una quintilla aislada. En los vv. 940-944 hay una quintilla aislada. A partir del v. 935 continúa el patrón regular de coplas reales.' }
	])('no interpreta una nota insuficiente, contradictoria o ajena: %j', (cambio) => {
		const { secuencia, nota } = escenario();
		expect(proponerDivisionDesdeNota(secuencia, { ...nota, ...cambio } as NotaFuenteImportador)).toBeNull();
	});
	it('no aplica cortes al preparar; al aceptar conserva extensión, fuente y aviso', () => {
		const { raw, vista, secuencia, nota } = escenario();
		expect(vista.errores).toEqual([]);
		expect(vista.filas).toHaveLength(2);
		const propuesta = proponerDivisionDesdeNota(secuencia, nota)!;
		const editada = analizarEntrada(raw, {}, [{ tramo_ref: 't01', partes: propuesta.partes.map((p) => ({ ...p, nota: null, remate: null, rasgos: [], desviaciones: [] })) }]);
		expect(editada.errores).toEqual([]);
		expect(editada.filas).toHaveLength(4);
		expect(editada.resumen!.extension).toBe(999);
		for (const parte of editada.filas.slice(1)) expect(parte.origen).toEqual(secuencia.origen);
		expect(editada.filas.at(-1)!.longitud?.estado).toBe('revisar');
	});
	it('muestra la propuesta y su advertencia junto a la nota antes de aplicarla', () => {
		const { vista, nota } = escenario();
		const { body } = render(EditorSecuencia, { props: {
			datos: vista.datos!, tramoRef: 't01', formas: obtenerReferenciaImportador().formas, notasFuente: [nota],
			onaplicar: () => { throw new Error('No se debe aplicar al abrir'); }, onrestablecer: () => {}, oncancelar: () => {}
		} });
		const texto = body.replace(/<!--[\s\S]*?-->/g, '').replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ');
		expect(texto).toContain('Dividir según la nota');
		expect(texto).toContain('935–999 (65 versos, Copla real)');
		expect(texto).toContain('65 versos. Copla real requiere');
	});
});
