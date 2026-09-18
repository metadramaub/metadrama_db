import { describe, expect, it } from 'vitest';
import { contarUnidades, type SeccionContable, type UnidadContable } from './contar-unidades';

const secciones: SeccionContable[] = [
	{ seccion_id: 'cabeza', seccion_padre_id: null, repeticiones_max: 1 },
	{ seccion_id: 'ciclo', seccion_padre_id: null, repeticiones_max: null },
	{ seccion_id: 'copla', seccion_padre_id: 'ciclo', repeticiones_max: 1 },
	{ seccion_id: 'mudanza', seccion_padre_id: 'copla', repeticiones_max: 1 },
	{ seccion_id: 'enlace', seccion_padre_id: 'copla', repeticiones_max: 1 },
	{ seccion_id: 'vuelta', seccion_padre_id: 'copla', repeticiones_max: 1 },
	{ seccion_id: 'estribillo', seccion_padre_id: 'ciclo', repeticiones_max: 1 },
	{ seccion_id: 'cuartetos', seccion_padre_id: null, repeticiones_max: 2 },
	{ seccion_id: 'tercetos', seccion_padre_id: null, repeticiones_max: 2 }
];

function unidad(padre: string | null, seccion: string | null): UnidadContable {
	return { realizacion_padre_id: padre, seccion_id: seccion };
}

describe('contarUnidades', () => {
	it('cuenta las estrofas de una serie estrófica', () => {
		expect(contarUnidades([unidad(null, null), unidad(null, null), unidad(null, null)], secciones)).toBe(3);
	});

	it('cuenta las coplas del villancico, no las catorce filas del árbol', () => {
		const ciclo = (n: string) => [
			unidad('raiz', 'ciclo'),
			unidad(n, 'copla'),
			unidad(`${n}-copla`, 'mudanza'),
			unidad(`${n}-copla`, 'enlace'),
			unidad(`${n}-copla`, 'vuelta'),
			unidad(n, 'estribillo')
		];
		const unidades = [unidad(null, null), unidad('raiz', 'cabeza'), ...ciclo('c1'), ...ciclo('c2')];
		expect(unidades).toHaveLength(14);
		expect(contarUnidades(unidades, secciones)).toBe(2);
	});

	it('un soneto es una unidad aunque tenga dos secciones repetibles', () => {
		const unidades = [
			unidad(null, null),
			unidad('raiz', 'cuartetos'),
			unidad('raiz', 'cuartetos'),
			unidad('raiz', 'tercetos'),
			unidad('raiz', 'tercetos')
		];
		expect(contarUnidades(unidades, secciones)).toBe(1);
	});

	it('una estrofa sola es una unidad', () => {
		expect(contarUnidades([unidad(null, null)], secciones)).toBe(1);
		expect(contarUnidades([], secciones)).toBe(0);
	});
});
