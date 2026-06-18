import { describe, expect, it } from 'vitest';
import { buildDistributionGroups } from './metric-distribution';

describe('buildDistributionGroups', () => {
	it('usa subtipos como desglose aunque el tipo coincida con la forma', () => {
		const [group] = buildDistributionGroups(
			[{ forma: 'quintilla', versos: 10, porcentaje: 100 }],
			[
				{
					v_ini: 1,
					v_fin: 10,
					estrofa_forma_term: 'quintilla',
					estrofa_tipo_term: 'quintilla',
					n_versos: 10,
					subtipos_estrofa: [
						{ subtipo_estrofa_term: 'quintilla aguda', v_ini: 1, v_fin: 5 },
						{ subtipo_estrofa_term: 'quintilla grave', v_ini: 6, v_fin: 10 }
					]
				}
			]
		);

		expect(group.children).toEqual([
			{ label: 'quintilla aguda', versos: 5, porcentaje: 50 },
			{ label: 'quintilla grave', versos: 5, porcentaje: 50 }
		]);
	});

	it('oculta un único tipo que no aporta desglose', () => {
		const [group] = buildDistributionGroups(
			[{ forma: 'quintilla', versos: 10, porcentaje: 100 }],
			[
				{
					estrofa_forma_term: 'quintilla',
					estrofa_tipo_term: 'quintilla',
					n_versos: 10
				}
			]
		);

		expect(group.children).toEqual([]);
	});
});
