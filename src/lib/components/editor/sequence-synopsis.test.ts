import { describe, expect, it } from 'vitest';
import { buildSequenceSynopsisGroups } from './sequence-synopsis';
import type { Tables } from '$lib/types/database.types';

type SecuenciaRow = Tables<'secuencias_metricas'>;
type JornadaRow = Pick<Tables<'jornadas'>, 'jornada_id' | 'jornada_num' | 'v_ini' | 'v_fin'>;
type CuadroRow = Pick<Tables<'cuadros'>, 'cuadro_id' | 'cuadro_num' | 'jornada_id' | 'v_ini' | 'v_fin'>;
type EstrofaOption = Pick<
	Tables<'vocabularios'>,
	'termino_id' | 'termino' | 'termino_padre_id' | 'tipo_forma'
>;

function createSecuencia(overrides: Partial<SecuenciaRow> = {}): SecuenciaRow {
	return {
		secuencia_id: overrides.secuencia_id ?? 'seq-1',
		obra_id: overrides.obra_id ?? 'obra-1',
		created_at: overrides.created_at ?? '2026-03-30T00:00:00.000Z',
		v_ini: overrides.v_ini ?? 1,
		v_fin: overrides.v_fin ?? 10,
		n_versos: overrides.n_versos ?? 10,
		estrofa_tipo_id: overrides.estrofa_tipo_id ?? 'estrofa-1',
		inaugura_espacio: overrides.inaugura_espacio ?? false,
		versos_partidos: overrides.versos_partidos ?? false,
		evocacion_metrica: overrides.evocacion_metrica ?? false,
		evocacion_metrica_texto: overrides.evocacion_metrica_texto ?? null,
		intervencion_personajes_femeninos:
			overrides.intervencion_personajes_femeninos ?? 'sin_intervencion',
		intervencion_figuras_donaire:
			overrides.intervencion_figuras_donaire ?? 'sin_intervencion',
		intervencion_personajes_sobrenaturales:
			overrides.intervencion_personajes_sobrenaturales ?? 'sin_intervencion',
		sinopsis: overrides.sinopsis ?? 'Sinopsis base',
		updated_at: overrides.updated_at ?? '2026-03-30T00:00:00.000Z'
	};
}

const jornadasBase: JornadaRow[] = [
	{ jornada_id: 'j1', jornada_num: 1, v_ini: 1, v_fin: 100 },
	{ jornada_id: 'j2', jornada_num: 2, v_ini: 101, v_fin: 200 }
];

const cuadrosBase: CuadroRow[] = [
	{ cuadro_id: 'c1', cuadro_num: 1, jornada_id: 'j1', v_ini: 1, v_fin: 50 },
	{ cuadro_id: 'c2', cuadro_num: 2, jornada_id: 'j1', v_ini: 51, v_fin: 100 },
	{ cuadro_id: 'c3', cuadro_num: 1, jornada_id: 'j2', v_ini: 101, v_fin: 150 },
	{ cuadro_id: 'c4', cuadro_num: 2, jornada_id: 'j2', v_ini: 151, v_fin: 200 }
];

const estrofasBase: EstrofaOption[] = [
	{ termino_id: 'estrofa-1', termino: 'redondilla', termino_padre_id: null, tipo_forma: 'forma_espanola' }
];

describe('sequence-synopsis', () => {
	it('agrupa una secuencia dentro de un solo cuadro y crea su divisor externo', () => {
		const groups = buildSequenceSynopsisGroups({
			secuencias: [createSecuencia({ v_ini: 10, v_fin: 20, n_versos: 11 })],
			jornadas: jornadasBase,
			cuadros: cuadrosBase,
			estrofaOptions: estrofasBase
		});

		expect(groups).toHaveLength(1);
		expect(groups[0]?.label).toBe('Jornada 1');
		expect(groups[0]?.cards[0]?.startingCuadro.label).toBe('Cuadro 1');
		expect(groups[0]?.cards[0]?.endingCuadro.label).toBe('Cuadro 1');
		expect(groups[0]?.cards[0]?.tramos).toEqual([
			{
				cuadroId: 'c1',
				cuadroNum: 1,
				label: 'Cuadro 1 · vv. 10-20',
				vIni: 10,
				vFin: 20
			}
		]);
		expect(groups[0]?.items.map((item) => item.type)).toEqual(['cuadro_divider', 'card']);
		expect(groups[0]?.items[0]).toMatchObject({
			type: 'cuadro_divider',
			cuadro: {
				label: 'Cuadro 1',
				rangeLabel: 'vv. 1-50'
			}
		});
	});

	it('inserta un divisor nuevo cuando la siguiente secuencia empieza en otro cuadro', () => {
		const groups = buildSequenceSynopsisGroups({
			secuencias: [
				createSecuencia({ secuencia_id: 'seq-1', v_ini: 10, v_fin: 20 }),
				createSecuencia({ secuencia_id: 'seq-2', v_ini: 60, v_fin: 70 })
			],
			jornadas: jornadasBase,
			cuadros: cuadrosBase,
			estrofaOptions: estrofasBase
		});

		expect(groups[0]?.items.map((item) => item.type)).toEqual([
			'cuadro_divider',
			'card',
			'cuadro_divider',
			'card'
		]);
		expect(groups[0]?.items[2]).toMatchObject({
			type: 'cuadro_divider',
			cuadro: {
				label: 'Cuadro 2',
				rangeLabel: 'vv. 51-100'
			}
		});
	});

	it('marca los cambios internos de cuadro sin partir la secuencia', () => {
		const groups = buildSequenceSynopsisGroups({
			secuencias: [createSecuencia({ v_ini: 40, v_fin: 80, n_versos: 41 })],
			jornadas: jornadasBase,
			cuadros: cuadrosBase,
			estrofaOptions: estrofasBase
		});

		expect(groups[0]?.cards[0]?.spansMultipleCuadros).toBe(true);
		expect(groups[0]?.cards[0]?.startingCuadro.label).toBe('Cuadro 1');
		expect(groups[0]?.cards[0]?.endingCuadro.label).toBe('Cuadro 2');
		expect(groups[0]?.cards[0]?.tramos.map((tramo) => tramo.label)).toEqual([
			'Cuadro 1 · vv. 40-50',
			'Cuadro 2 · vv. 51-80'
		]);
		expect(groups[0]?.items.map((item) => item.type)).toEqual(['cuadro_divider', 'card']);
	});

	it('usa mini carryover si el cuadro ya empezo dentro de la secuencia anterior', () => {
		const groups = buildSequenceSynopsisGroups({
			secuencias: [
				createSecuencia({ secuencia_id: 'seq-1', v_ini: 40, v_fin: 80 }),
				createSecuencia({ secuencia_id: 'seq-2', v_ini: 81, v_fin: 90 })
			],
			jornadas: jornadasBase,
			cuadros: cuadrosBase,
			estrofaOptions: estrofasBase
		});

		expect(groups[0]?.items.map((item) => item.type)).toEqual([
			'cuadro_divider',
			'card',
			'cuadro_carryover',
			'card'
		]);
		expect(groups[0]?.items[2]).toMatchObject({
			type: 'cuadro_carryover',
			cuadro: {
				label: 'Cuadro 2'
			}
		});
		expect(groups[0]?.cards[1]?.startingCuadro.label).toBe('Cuadro 2');
	});

	it('mantiene una card visible cuando la sinopsis esta vacia', () => {
		const groups = buildSequenceSynopsisGroups({
			secuencias: [createSecuencia({ sinopsis: '   ' })],
			jornadas: jornadasBase,
			cuadros: cuadrosBase,
			estrofaOptions: estrofasBase
		});

		expect(groups[0]?.cards[0]?.hasSynopsis).toBe(false);
		expect(groups[0]?.cards[0]?.sinopsis).toBe('   ');
	});

	it('usa el término de estrofa de una secuencia pública mínima sin vocabulario externo', () => {
		const groups = buildSequenceSynopsisGroups({
			secuencias: [
				{
					secuencia_id: 'seq-publica',
					v_ini: 12,
					v_fin: 24,
					n_versos: 13,
					estrofa_tipo_id: null,
					estrofa_tipo_term: 'Quintilla',
					sinopsis: 'Sinopsis pública'
				}
			],
			jornadas: jornadasBase,
			cuadros: cuadrosBase
		});

		expect(groups[0]?.cards[0]?.estrofaLabel).toBe('Quintilla');
		expect(groups[0]?.cards[0]?.sinopsis).toBe('Sinopsis pública');
		expect(groups[0]?.cards[0]?.nVersos).toBe(13);
	});

	it('envia a fallback las secuencias sin jornada o sin cuadro', () => {
		const groups = buildSequenceSynopsisGroups({
			secuencias: [
				createSecuencia({ secuencia_id: 'seq-outside', v_ini: 205, v_fin: 210 }),
				createSecuencia({ secuencia_id: 'seq-no-cuadro', v_ini: 10, v_fin: 20 })
			],
			jornadas: jornadasBase,
			cuadros: cuadrosBase.filter((cuadro) => cuadro.cuadro_id !== 'c1'),
			estrofaOptions: estrofasBase
		});

		expect(groups).toHaveLength(2);
		expect(groups[0]?.items[0]).toMatchObject({
			type: 'cuadro_divider',
			cuadro: {
				label: 'Sin cuadro',
				rangeLabel: null
			}
		});
		expect(groups[1]?.label).toBe('Sin jornada');
		expect(groups[1]?.items[0]).toMatchObject({
			type: 'cuadro_divider',
			cuadro: {
				label: 'Sin cuadro',
				rangeLabel: null
			}
		});
	});
});
