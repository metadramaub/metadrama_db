import { describe, expect, it } from 'vitest';
import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';
import { errorDeCoherenciaDeRasgos } from './coherencia-rasgos';

const traits = [
	{ rasgo_id: 'r-dens', slug: 'densidad_de_rima' },
	{ rasgo_id: 'r-par', slug: 'organizacion_en_pareados' },
	{ rasgo_id: 'r-dist', slug: 'distico_final' }
] as MetricCatalogDomainRow[];
const traitValues = [
	{ valor_id: 'v-ninguna', rasgo_id: 'r-dens', slug: 'ninguna' },
	{ valor_id: 'v-espor', rasgo_id: 'r-dens', slug: 'esporadica' },
	{ valor_id: 'v-par-ninguna', rasgo_id: 'r-par', slug: 'ninguna' },
	{ valor_id: 'v-par-ocas', rasgo_id: 'r-par', slug: 'ocasionales' },
	{ valor_id: 'v-dist', rasgo_id: 'r-dist', slug: 'presente' }
] as MetricCatalogDomainRow[];
const options = [
	{ opcion_eleccion_id: 'o-ninguna', valor_rasgo_id: 'v-ninguna' },
	{ opcion_eleccion_id: 'o-espor', valor_rasgo_id: 'v-espor' },
	{ opcion_eleccion_id: 'o-par-ninguna', valor_rasgo_id: 'v-par-ninguna' },
	{ opcion_eleccion_id: 'o-par-ocas', valor_rasgo_id: 'v-par-ocas' },
	{ opcion_eleccion_id: 'o-dist', valor_rasgo_id: 'v-dist' }
] as MetricCatalogDomainRow[];
const sec = (id: string) => ({ realizacion_id: null, opcion_eleccion_id: id });

describe('coherencia entre rasgos de la secuencia', () => {
	it('sin rima y con dístico final vale: el dístico no cuenta', () => {
		expect(
			errorDeCoherenciaDeRasgos([sec('o-ninguna'), sec('o-dist'), sec('o-par-ninguna')], options, traitValues, traits)
		).toBeNull();
	});

	it('sin rima y con pareados intercalados no vale', () => {
		expect(
			errorDeCoherenciaDeRasgos([sec('o-ninguna'), sec('o-par-ocas')], options, traitValues, traits)
		).toMatch(/pareados intercalados/);
	});

	it('esporádica con pareados intercalados vale', () => {
		expect(
			errorDeCoherenciaDeRasgos([sec('o-espor'), sec('o-par-ocas')], options, traitValues, traits)
		).toBeNull();
	});

	it('una respuesta de unidad no cuenta como respuesta de la secuencia', () => {
		expect(
			errorDeCoherenciaDeRasgos(
				[sec('o-ninguna'), { realizacion_id: 'u1', opcion_eleccion_id: 'o-par-ocas' }],
				options, traitValues, traits
			)
		).toBeNull();
	});
});
