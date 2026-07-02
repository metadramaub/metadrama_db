import { describe, expect, it } from 'vitest';
import {
	flattenVocabularyTree,
	moveVocabularyByDropIntent,
	moveVocabularyItem,
	moveSibling,
	normalizeTree,
	type VocabularyItem
} from './useVocabularyTree';

const baseItems: VocabularyItem[] = [
	{
		termino_id: 'root-a',
		categoria: 'estrofa_tipo',
		termino: 'romance',
		etiqueta: null,
		termino_padre_id: null,
		nivel: 1,
		orden: 10,
		definicion: null,
		ejemplo: null,
		bibliografia: null,
		equivalencias: null,
		patron_especifico: null,
		tipo_forma: null,
		tipo_rima: null,
		naturaleza_estrofica_id: null,
		tamanio_unidad_estrofica: null,
		arte_metrico: null,
		numero_silabas: null,
		activo: true
	},
	{
		termino_id: 'child-a1',
		categoria: 'estrofa_tipo',
		termino: 'romance_e-a',
		etiqueta: null,
		termino_padre_id: 'root-a',
		nivel: 2,
		orden: 10,
		definicion: null,
		ejemplo: null,
		bibliografia: null,
		equivalencias: null,
		patron_especifico: 'e-a',
		tipo_forma: null,
		tipo_rima: null,
		naturaleza_estrofica_id: null,
		tamanio_unidad_estrofica: null,
		arte_metrico: null,
		numero_silabas: null,
		activo: true
	},
	{
		termino_id: 'root-b',
		categoria: 'estrofa_tipo',
		termino: 'redondilla',
		etiqueta: null,
		termino_padre_id: null,
		nivel: 1,
		orden: 20,
		definicion: null,
		ejemplo: null,
		bibliografia: null,
		equivalencias: null,
		patron_especifico: null,
		tipo_forma: null,
		tipo_rima: null,
		naturaleza_estrofica_id: null,
		tamanio_unidad_estrofica: null,
		arte_metrico: null,
		numero_silabas: null,
		activo: true
	}
];

const itemsWithSiblingChildren: VocabularyItem[] = [
	...baseItems,
	{
		termino_id: 'child-a2',
		categoria: 'estrofa_tipo',
		termino: 'romance_o-a',
		etiqueta: null,
		termino_padre_id: 'root-a',
		nivel: 2,
		orden: 20,
		definicion: null,
		ejemplo: null,
		bibliografia: null,
		equivalencias: null,
		patron_especifico: 'o-a',
		tipo_forma: null,
		tipo_rima: null,
		naturaleza_estrofica_id: null,
		tamanio_unidad_estrofica: null,
		arte_metrico: null,
		numero_silabas: null,
		activo: true
	}
];

describe('useVocabularyTree', () => {
	it('flattens hierarchy preserving depth', () => {
		const rows = flattenVocabularyTree(baseItems);
		expect(rows.map((row) => `${row.depth}:${row.item.termino_id}`)).toEqual([
			'1:root-a',
			'2:child-a1',
			'1:root-b'
		]);
	});

	it('normalizes sibling order and levels', () => {
		const shuffled = [
			{ ...baseItems[2], orden: 3, nivel: 99 },
			{ ...baseItems[0], orden: 2, nivel: 99 },
			{ ...baseItems[1], orden: 5, nivel: 99 }
		];
		const normalized = normalizeTree(shuffled);
		const rootA = normalized.find((item) => item.termino_id === 'root-a');
		const childA = normalized.find((item) => item.termino_id === 'child-a1');
		const rootB = normalized.find((item) => item.termino_id === 'root-b');

		expect(rootA?.nivel).toBe(1);
		expect(childA?.nivel).toBe(2);
		expect(rootB?.nivel).toBe(1);
		expect(rootA?.orden).toBe(10);
		expect(rootB?.orden).toBe(20);
	});

	it('prevents cycle-producing moves', () => {
		const moved = moveVocabularyItem(baseItems, 'root-a', 'child-a1', 0);
		const rootA = moved.find((item) => item.termino_id === 'root-a');
		expect(rootA?.termino_padre_id).toBeNull();
	});

	it('moves before sibling with top placement', () => {
		const moved = moveVocabularyByDropIntent(baseItems, 'root-b', 'root-a', 'top');
		const roots = moved
			.filter((item) => item.termino_padre_id === null)
			.sort((a, b) => (a.orden ?? 999) - (b.orden ?? 999))
			.map((item) => item.termino_id);
		expect(roots).toEqual(['root-b', 'root-a']);
	});

	it('moves after sibling with bottom placement', () => {
		const moved = moveVocabularyByDropIntent(baseItems, 'root-a', 'root-b', 'bottom');
		const roots = moved
			.filter((item) => item.termino_padre_id === null)
			.sort((a, b) => (a.orden ?? 999) - (b.orden ?? 999))
			.map((item) => item.termino_id);
		expect(roots).toEqual(['root-b', 'root-a']);
	});

	it('reparents as child with mid placement and recalculates level', () => {
		const moved = moveVocabularyByDropIntent(baseItems, 'root-b', 'root-a', 'mid');
		const rootB = moved.find((item) => item.termino_id === 'root-b');
		expect(rootB?.termino_padre_id).toBe('root-a');
		expect(rootB?.nivel).toBe(2);
	});

	it('moves to root with root-start and root-end placements', () => {
		const rootStart = moveVocabularyByDropIntent(baseItems, 'child-a1', null, 'root-start');
		const rootStartRoots = rootStart
			.filter((item) => item.termino_padre_id === null)
			.sort((a, b) => (a.orden ?? 999) - (b.orden ?? 999))
			.map((item) => item.termino_id);
		expect(rootStartRoots).toEqual(['child-a1', 'root-a', 'root-b']);

		const rootEnd = moveVocabularyByDropIntent(baseItems, 'child-a1', null, 'root-end');
		const rootEndRoots = rootEnd
			.filter((item) => item.termino_padre_id === null)
			.sort((a, b) => (a.orden ?? 999) - (b.orden ?? 999))
			.map((item) => item.termino_id);
		expect(rootEndRoots).toEqual(['root-a', 'root-b', 'child-a1']);
	});

	it('blocks self-parent and descendant cycle on drop intents', () => {
		const selfParent = moveVocabularyByDropIntent(baseItems, 'root-a', 'root-a', 'mid');
		expect(selfParent).toBe(baseItems);

		const cycle = moveVocabularyByDropIntent(baseItems, 'root-a', 'child-a1', 'mid');
		expect(cycle).toBe(baseItems);
	});

	it('blocks moves that would create a third level', () => {
		const moved = moveVocabularyByDropIntent(baseItems, 'root-a', 'root-b', 'mid');
		expect(moved).toBe(baseItems);
	});

	it('moves a root sibling down', () => {
		const moved = moveSibling(baseItems, 'root-a', 1);
		const roots = moved
			.filter((item) => item.termino_padre_id === null)
			.sort((a, b) => (a.orden ?? 999) - (b.orden ?? 999))
			.map((item) => item.termino_id);
		expect(roots).toEqual(['root-b', 'root-a']);
	});

	it('moves a root sibling up', () => {
		const moved = moveSibling(baseItems, 'root-b', -1);
		const roots = moved
			.filter((item) => item.termino_padre_id === null)
			.sort((a, b) => (a.orden ?? 999) - (b.orden ?? 999))
			.map((item) => item.termino_id);
		expect(roots).toEqual(['root-b', 'root-a']);
	});

	it('moves a child among siblings without changing parent', () => {
		const moved = moveSibling(itemsWithSiblingChildren, 'child-a2', -1);
		const children = moved
			.filter((item) => item.termino_padre_id === 'root-a')
			.sort((a, b) => (a.orden ?? 999) - (b.orden ?? 999))
			.map((item) => item.termino_id);
		const movedChild = moved.find((item) => item.termino_id === 'child-a2');
		expect(children).toEqual(['child-a2', 'child-a1']);
		expect(movedChild?.termino_padre_id).toBe('root-a');
		expect(movedChild?.nivel).toBe(2);
	});

	it('returns the original items when moving beyond sibling bounds', () => {
		expect(moveSibling(baseItems, 'root-a', -1)).toBe(baseItems);
		expect(moveSibling(baseItems, 'root-b', 1)).toBe(baseItems);
	});
});
