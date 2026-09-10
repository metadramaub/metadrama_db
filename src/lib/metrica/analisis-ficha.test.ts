import { describe, expect, it } from 'vitest';
import {
	SIN_FORMA,
	caracterizacionesDeLaObra,
	cierreDeJornadas,
	cortesDeCuadro,
	desgloseDeFormas,
	evolucionPorJornada,
	fichaTecnica,
	lecturaDeLaEvolucion,
	perfilDeFormas,
	perfilDeTradiciones,
	perfilPorJornada,
	secuenciasPorForma,
	transiciones,
	type SecuenciaAnalizable
} from './analisis-ficha';

/** Una secuencia con lo mínimo puesto; cada prueba cambia lo suyo. */
function secuencia(parcial: Partial<SecuenciaAnalizable> & { v_ini: number; n_versos: number }) {
	return {
		secuencia_id: `s${parcial.v_ini}`,
		v_fin: parcial.v_ini + parcial.n_versos - 1,
		forma_slug: 'redondilla',
		forma: 'Redondilla',
		arquitectura: 'Octosilábica',
		tradicion: 'forma_espanola',
		jornada_num: 1,
		cuadro_num: 1,
		cuadro_continua: false,
		esquemas: [],
		rasgos: [],
		caracterizaciones: [],
		desviaciones: [],
		versos_partidos: false,
		inaugura_espacio: false,
		...parcial
	} satisfies SecuenciaAnalizable;
}

/** Tres jornadas, cuatro formas y un tramo sin forma: lo justo para que nada sea trivial. */
const OBRA: SecuenciaAnalizable[] = [
	secuencia({ v_ini: 1, n_versos: 100, esquemas: [{ nombre: 'abrazada', unidades: 25 }] }),
	secuencia({
		v_ini: 101,
		n_versos: 60,
		forma_slug: 'romance',
		forma: 'Romance',
		arquitectura: 'Octosilábica',
		rasgos: [{ rasgo: 'Vocales de la asonancia', valor: 'e-o' }],
		caracterizaciones: [{ tipo: 'cantado', v_ini: 101, v_fin: 116 }]
	}),
	secuencia({
		v_ini: 161,
		n_versos: 40,
		jornada_num: 2,
		forma_slug: 'octava_real',
		forma: 'Octava real',
		arquitectura: 'Endecasilábica consonante',
		tradicion: 'forma_italiana',
		cuadro_num: 2,
		cuadro_continua: true
	}),
	secuencia({
		v_ini: 201,
		n_versos: 80,
		jornada_num: 2,
		cuadro_num: 2,
		esquemas: [
			{ nombre: 'abrazada', unidades: 15 },
			{ nombre: 'cruzada', unidades: 5 }
		]
	}),
	secuencia({
		v_ini: 281,
		n_versos: 20,
		jornada_num: 3,
		forma_slug: null,
		forma: null,
		arquitectura: null,
		tradicion: null,
		cuadro_num: 3,
		versos_partidos: true,
		desviaciones: [{ dimension: 'estructura', relacion_norma: 'falta' }]
	})
];

describe('perfilDeFormas', () => {
	it('reparte los versos y ordena de mayor a menor', () => {
		const perfil = perfilDeFormas(OBRA);
		expect(perfil[0]).toMatchObject({ forma: 'Redondilla', versos: 180, porcentaje: 60 });
		expect(perfil.map((p) => p.forma)).toEqual([
			'Redondilla',
			'Romance',
			'Octava real',
			SIN_FORMA
		]);
	});

	it('**cuenta el tramo sin forma**, que si no los porcentajes no suman cien', () => {
		const perfil = perfilDeFormas(OBRA);
		const sinForma = perfil.find((p) => p.colorKey === SIN_FORMA);
		expect(sinForma).toMatchObject({ versos: 20 });
		expect(perfil.reduce((t, p) => t + p.porcentaje, 0)).toBeCloseTo(100, 1);
	});

	it('no revienta con una obra vacía', () => {
		expect(perfilDeFormas([])).toEqual([]);
	});
});

describe('perfilPorJornada', () => {
	it('separa por jornada y suma lo suyo', () => {
		const porJornada = perfilPorJornada(OBRA);
		expect(porJornada.map((j) => [j.jornada, j.versos])).toEqual([
			[1, 160],
			[2, 120],
			[3, 20]
		]);
		expect(porJornada[1].formas.map((f) => f.forma)).toEqual(['Redondilla', 'Octava real']);
	});
});

describe('perfilDeTradiciones', () => {
	it('separa españolas, italianas y lo que no es ninguna', () => {
		const t = perfilDeTradiciones(OBRA);
		expect(t.espanola.versos).toBe(240);
		expect(t.italiana.versos).toBe(40);
		expect(t.sinTradicion.versos).toBe(20);
		expect(t.espanola.porcentaje + t.italiana.porcentaje + t.sinTradicion.porcentaje).toBeCloseTo(
			100,
			1
		);
	});
});

describe('desgloseDeFormas', () => {
	it('pesa las arquitecturas en versos y los esquemas en estrofas', () => {
		const redondilla = desgloseDeFormas(OBRA).find((d) => d.colorKey === 'redondilla')!;
		expect(redondilla.secuencias).toBe(2);
		expect(redondilla.arquitecturas).toEqual([
			{ nombre: 'Octosilábica', versos: 180, porcentaje: 100 }
		]);
		// 40 estrofas en total: 40 abrazadas y 5 cruzadas hacen 45.
		expect(redondilla.esquemas).toEqual([
			{ nombre: 'abrazada', unidades: 40, porcentaje: 88.89 },
			{ nombre: 'cruzada', unidades: 5, porcentaje: 11.11 }
		]);
	});

	it('una forma sin esquemas anotados no inventa ninguno', () => {
		const octava = desgloseDeFormas(OBRA).find((d) => d.colorKey === 'octava_real')!;
		expect(octava.esquemas).toEqual([]);
	});
});

describe('transiciones', () => {
	it('cuenta qué forma sigue a cuál **cruzando los cortes de jornada**', () => {
		const pasos = transiciones(OBRA);
		expect(pasos).toContainEqual({ de: 'Redondilla', a: 'Romance', veces: 1 });
		// El paso de la jornada 2 a la 3 se cuenta como cualquier otro.
		expect(pasos).toContainEqual({ de: 'Redondilla', a: SIN_FORMA, veces: 1 });
		expect(pasos.reduce((t, p) => t + p.veces, 0)).toBe(OBRA.length - 1);
	});

	it('una obra de una sola secuencia no tiene transiciones', () => {
		expect(transiciones([OBRA[0]])).toEqual([]);
	});
});

describe('secuenciasPorForma', () => {
	it('da cuántas, la media y los extremos', () => {
		const redondilla = secuenciasPorForma(OBRA).find((t) => t.colorKey === 'redondilla')!;
		expect(redondilla).toMatchObject({ secuencias: 2, versos: 180, media: 90, minima: 80, maxima: 100 });
	});
});

describe('cortesDeCuadro', () => {
	it('cuenta los límites reales y excluye la apertura de cada jornada', () => {
		const cuadros = [
			{ jornada_id: 'j1', cuadro_num: 1, v_ini: 1, v_fin: 50 },
			{ jornada_id: 'j1', cuadro_num: 2, v_ini: 51, v_fin: 100 },
			{ jornada_id: 'j1', cuadro_num: 3, v_ini: 101, v_fin: 160 },
			{ jornada_id: 'j2', cuadro_num: 1, v_ini: 161, v_fin: 200 },
			{ jornada_id: 'j2', cuadro_num: 2, v_ini: 201, v_fin: 240 },
			{ jornada_id: 'j2', cuadro_num: 3, v_ini: 241, v_fin: 280 }
		];
		expect(cortesDeCuadro(OBRA, cuadros)).toEqual({
			total: 4,
			partenSecuencia: 2,
			coincidenCambioForma: 2,
			entreSecuenciasMismaForma: 0,
			sinCobertura: 0
		});
	});

	it('separa el límite entre dos secuencias de la misma forma', () => {
		const secuencias = [secuencia({ v_ini: 1, n_versos: 10 }), secuencia({ v_ini: 11, n_versos: 10 })];
		const cuadros = [
			{ jornada_id: 'j1', cuadro_num: 1, v_ini: 1, v_fin: 10 },
			{ jornada_id: 'j1', cuadro_num: 2, v_ini: 11, v_fin: 20 }
		];
		expect(cortesDeCuadro(secuencias, cuadros)).toMatchObject({
			total: 1,
			entreSecuenciasMismaForma: 1
		});
	});
});

describe('caracterizacionesDeLaObra', () => {
	it('cuenta los versos del rango, no los de la secuencia entera', () => {
		expect(caracterizacionesDeLaObra(OBRA)).toEqual([
			{ tipo: 'cantado', versos: 16, porcentaje: 5.33, formas: ['Romance'] }
		]);
	});

	it('normaliza las etiquetas públicas y no duplica rangos solapados', () => {
		const secuencia = {
			...OBRA[0],
			caracterizaciones: [
				{ tipo: 'Cantado', v_ini: 1, v_fin: 4 },
				{ tipo: 'cantado', v_ini: 3, v_fin: 6 },
				{ tipo: 'Evocación métrica', v_ini: 8, v_fin: 8 },
				{ tipo: 'Laguna', v_ini: 9, v_fin: 9 }
			]
		};
		expect(caracterizacionesDeLaObra([secuencia])).toEqual([
			{ tipo: 'cantado', versos: 6, porcentaje: 6, formas: ['Redondilla'] },
			{ tipo: 'evocacion_metrica', versos: 1, porcentaje: 1, formas: ['Redondilla'] }
		]);
	});
});

describe('fichaTecnica', () => {
	it('resume la obra y dice con qué abre y con qué cierra', () => {
		const t = fichaTecnica(OBRA);
		expect(t).toMatchObject({
			versos: 300,
			secuencias: 5,
			jornadas: 3,
			formasDistintas: 3,
			mediaPorSecuencia: 60,
			abre: 'Redondilla',
			cierra: SIN_FORMA,
			conVersosPartidos: 1,
			conDesviaciones: 1
		});
		expect(t.secuenciaMasLarga?.n_versos).toBe(100);
	});
});

describe('cierreDeJornadas', () => {
	it('dice con qué abre y con qué cierra cada jornada', () => {
		expect(cierreDeJornadas(OBRA)).toEqual([
			{ jornada: 1, abre: 'Redondilla', cierra: 'Romance' },
			{ jornada: 2, abre: 'Octava real', cierra: 'Redondilla' },
			{ jornada: 3, abre: SIN_FORMA, cierra: SIN_FORMA }
		]);
	});
});

describe('evolucionPorJornada', () => {
	// Jornada I: una sola forma en dos secuencias largas. Jornada III: cuatro formas repartidas en
	// secuencias cortas. Es la obra que se acorta y se diversifica.
	const obra: SecuenciaAnalizable[] = [
		secuencia({ v_ini: 1, n_versos: 200, jornada_num: 1 }),
		secuencia({ v_ini: 201, n_versos: 200, jornada_num: 1 }),
		secuencia({ v_ini: 401, n_versos: 25, jornada_num: 3, forma_slug: 'romance', forma: 'Romance' }),
		secuencia({ v_ini: 426, n_versos: 25, jornada_num: 3, forma_slug: 'soneto', forma: 'Soneto' }),
		secuencia({ v_ini: 451, n_versos: 25, jornada_num: 3, forma_slug: 'lira', forma: 'Lira' }),
		secuencia({ v_ini: 476, n_versos: 25, jornada_num: 3 })
	];

	it('mide longitud media y diversidad jornada a jornada', () => {
		const puntos = evolucionPorJornada(obra);
		expect(puntos.map((p) => p.jornada)).toEqual([1, 3]);
		expect(puntos[0].longitudMedia).toBe(200);
		expect(puntos[1].longitudMedia).toBe(25);
		// Una sola forma: el número efectivo es 1. Cuatro a partes iguales: es 4.
		expect(puntos[0].numeroEfectivo).toBe(1);
		expect(puntos[1].numeroEfectivo).toBe(4);
	});

	it('no cuenta como forma el pasaje sin forma anotada', () => {
		const conHueco = [
			secuencia({ v_ini: 1, n_versos: 50, jornada_num: 1 }),
			secuencia({ v_ini: 51, n_versos: 50, jornada_num: 1, forma_slug: null, forma: null })
		];
		const [punto] = evolucionPorJornada(conHueco);
		expect(punto.formasDistintas).toBe(1);
		expect(punto.numeroEfectivo).toBe(1);
	});

	it('lee la tendencia comparando la primera jornada con la última', () => {
		const lectura = lecturaDeLaEvolucion(obra);
		expect(lectura?.longitud).toBe('baja');
		expect(lectura?.diversidad).toBe('sube');
	});

	it('dice que se mantiene cuando el cambio no llega al umbral', () => {
		const estable = [
			secuencia({ v_ini: 1, n_versos: 100, jornada_num: 1 }),
			secuencia({ v_ini: 101, n_versos: 105, jornada_num: 2 })
		];
		expect(lecturaDeLaEvolucion(estable)?.longitud).toBe('se mantiene');
	});

	it('no lee tendencia con una sola jornada', () => {
		expect(lecturaDeLaEvolucion([secuencia({ v_ini: 1, n_versos: 10 })])).toBeNull();
	});
});
