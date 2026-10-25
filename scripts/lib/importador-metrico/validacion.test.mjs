import { describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { validarExtraccion, validarTextoExtraccion, codigoSalida } from './validacion.mjs';

// Datos sintéticos: ninguna afirmación métrica o fecha se usa como verdad del corpus real.
const tramo = (id, ini, fin, literal = 'denominación sintética sin equivalencia') => ({
	id,
	jornada: 1,
	v_ini: ini,
	v_fin: fin,
	denominacion_literal: literal,
	n_versos_fuente: fin - ini + 1,
	fuente_id: 'foto-prueba',
	pagina: 10,
	notas_ref: []
});
function ejemplo() {
	return {
		esquema: 'versologia-extraccion/0.1',
		obra_ref: 'obra-sintetica',
		estado_revision: 'borrador_ia',
		revision_humana: { responsable: null, fecha: null, resultado: 'pendiente' },
		procedencia: {
			fecha: null,
			procedimiento: 'ejecucion_prompt',
			generador: null,
			modelo: null,
			prompt_version: 'extraccion/0.1',
			ensayo_controlado: false
		},
		metadatos: {
			titulo: 'Obra sintética',
			autoria: 'Autor sintético',
			genero_literal: null,
			fecha_inicio: 1600,
			fecha_fin: 1605,
			fuente_fecha: 'Referencia sintética',
			edicion_base: 'Edición sintética',
			observaciones: [],
			fuente_id: 'doc-prueba'
		},
		jornadas: [{ numero: 1, rotulo_literal: 'ACTO I' }],
		tramos: [tramo('t01', 1, 4, 'letrilla'), tramo('t02', 5, 8)],
		notas: [],
		resumen_fuente: [],
		incidencias: []
	};
}
const fuentes = {
	documento_metadatos: { id: 'doc-prueba' },
	fotografias: [{ id: 'foto-prueba', obra_ref: 'obra-sintetica', pagina_visible: 10 }]
};
const opciones = { fuentes };
const codigos = (informe, nivel) => informe[nivel].map((item) => item.codigo);
function conNota(obra = ejemplo()) {
	obra.tramos[0].notas_ref = ['n01'];
	obra.notas = [
		{
			id: 'n01',
			marca: '*',
			texto_literal: 'Nota sintética, sin inferir otra forma.',
			fuente_id: 'foto-prueba',
			pagina: 10,
			tramos_ref: ['t01'],
			v_ini: 2,
			v_fin: 2
		}
	];
	return obra;
}

describe('formato inicial sin normalización ni promoción a gold', () => {
	it('admite términos desconocidos y mantiene el cotejo pendiente', () => {
		const informe = validarExtraccion(ejemplo(), opciones);
		expect(informe.estructura_valida).toBe(true);
		expect(informe.errores).toEqual([]);
		expect(informe.advertencias).toEqual([]);
		expect(codigos(informe, 'pendientes')).toContain('cotejo_humano_pendiente');
		expect(codigoSalida(informe)).toBe(0);
	});
	it.each([null, [], true, 12, {}, { tramos: null }])(
		'informa de una estructura inválida sin lanzar: %j',
		(entrada) => {
			const informe = validarExtraccion(entrada);
			expect(informe.estructura_valida).toBe(false);
			expect(informe.errores.length).toBeGreaterThan(0);
			expect(codigoSalida(informe)).toBe(1);
		}
	);
	it('no convierte números escritos como texto ni mezcla una forma de catálogo con la fuente', () => {
		const obra = ejemplo();
		obra.tramos[0].v_ini = '1';
		obra.tramos[0].forma_id = 'no-es-un-dato-de-la-extraccion';
		const informe = validarExtraccion(obra);
		expect(informe.estructura_valida).toBe(false);
		expect(obra.tramos[0].v_ini).toBe('1');
	});
	it('rechaza la declaración de revisión humana dentro de este intercambio de borrador', () => {
		const obra = ejemplo();
		obra.estado_revision = 'gold';
		obra.revision_humana = { responsable: 'alguien', fecha: '2026-10-22', resultado: 'validada' };
		expect(validarExtraccion(obra).estructura_valida).toBe(false);
	});
	it('no acepta un literal formado solo por espacios como transcripción legible', () => {
		const obra = ejemplo();
		obra.tramos[0].denominacion_literal = '   ';
		expect(validarExtraccion(obra).estructura_valida).toBe(false);
		expect(obra.tramos[0].denominacion_literal).toBe('   ');
	});
	it('tolera BOM y conserva exactamente el literal', () => {
		const obra = ejemplo();
		obra.tramos[0].denominacion_literal = '  letrilla (en la edición)  ';
		const texto = '\uFEFF' + JSON.stringify(obra);
		expect(validarTextoExtraccion(texto, opciones).errores).toEqual([]);
		expect(obra.tramos[0].denominacion_literal).toBe('  letrilla (en la edición)  ');
	});
	it.each(['texto sin JSON', '```json\n{}\n```', '{"a":', '{"a":1} y después prosa'])(
		'rechaza texto ajeno al objeto JSON: %s',
		(texto) => {
			expect(codigos(validarTextoExtraccion(texto), 'errores')).toEqual(['json_invalido']);
		}
	);
	it('distingue un dato ilegible de cero y no completa el recuento de fuente', () => {
		const obra = ejemplo();
		obra.tramos[0].denominacion_literal = null;
		obra.tramos[0].n_versos_fuente = null;
		const informe = validarExtraccion(obra, opciones);
		expect(informe.estructura_valida).toBe(true);
		expect(codigos(informe, 'pendientes')).toContain('denominacion_pendiente');
		expect(informe.datos_calculados.versos_union_conocida).toBe(8);
		expect(obra.tramos[0].n_versos_fuente).toBeNull();
		obra.tramos[0].n_versos_fuente = 0;
		expect(validarExtraccion(obra).estructura_valida).toBe(false);
	});
	it('comprueba que una fecha de ejecución exista, sin exigirla si no se conoce', () => {
		const obra = ejemplo();
		obra.procedencia.fecha = '2026-02-30';
		expect(validarExtraccion(obra).estructura_valida).toBe(false);
		obra.procedencia.fecha = '2024-02-29';
		expect(validarExtraccion(obra).estructura_valida).toBe(true);
	});
});

describe('extensión conocida y limitaciones de la fotografía', () => {
	it('separa cobertura de unión y suma cuando hay solapamiento anidado', () => {
		const obra = ejemplo();
		obra.tramos = [tramo('a', 1, 100), tramo('b', 2, 3), tramo('c', 4, 5)];
		const informe = validarExtraccion(obra, opciones);
		expect(informe.datos_calculados.versos_union_conocida).toBe(100);
		expect(informe.datos_calculados.versos_suma_rangos_conocidos).toBe(104);
		expect(informe.datos_calculados.versos_repetidos_conocidos).toBe(4);
		expect(codigos(informe, 'advertencias')).toContain('solapamiento');
		expect(codigoSalida(informe)).toBe(2);
	});
	it('detecta un hueco y conserva los rangos y recuentos originales', () => {
		const obra = ejemplo();
		obra.tramos = [tramo('a', 1, 4), tramo('b', 7, 10)];
		const informe = validarExtraccion(obra, opciones);
		expect(informe.datos_calculados.huecos_entre_rangos_conocidos).toEqual([
			{ v_ini: 5, v_fin: 6 }
		]);
		expect(codigos(informe, 'advertencias')).toContain('hueco');
		expect(obra.tramos[1].v_ini).toBe(7);
	});
	it('un rango ilegible impide presentar el hueco como pérdida cierta de versos', () => {
		const obra = ejemplo();
		obra.tramos = [
			tramo('a', 1, 4),
			{ ...tramo('b', 5, 6), v_ini: null, v_fin: null },
			tramo('c', 7, 10)
		];
		const informe = validarExtraccion(obra, opciones);
		expect(informe.datos_calculados.todos_los_rangos_transcritos).toBe(false);
		expect(informe.datos_calculados.versos_union_conocida).toBe(8);
		expect(codigos(informe, 'advertencias')).not.toContain('hueco');
		expect(codigos(informe, 'advertencias')).toContain('hueco_entre_rangos_conocidos');
	});
	it('no supone que el inicio sea 1 ni conoce el final sin contexto', () => {
		const obra = ejemplo();
		obra.tramos = [tramo('a', 500, 510)];
		const parcial = validarExtraccion(obra, opciones);
		expect(parcial.advertencias).toEqual([]);
		expect(parcial.datos_calculados.extremos_contrastados).toBe(false);
		const completo = validarExtraccion(obra, {
			...opciones,
			rangoEsperado: { v_ini: 1, v_fin: 1000 }
		});
		expect(codigos(completo, 'advertencias')).toContain('extremos_incompletos');
	});
	it('detecta orden inverso sin ordenar la extracción', () => {
		const obra = ejemplo();
		obra.tramos.reverse();
		const informe = validarExtraccion(obra, opciones);
		expect(codigos(informe, 'advertencias')).toContain('orden_discrepante');
		expect(informe.datos_calculados.versos_union_conocida).toBe(8);
		expect(obra.tramos[0].id).toBe('t02');
	});
	it('un rango invertido y un recuento discrepante se señalan sin reparar la fuente', () => {
		const obra = ejemplo();
		obra.tramos[0].n_versos_fuente = 5;
		expect(codigos(validarExtraccion(obra), 'advertencias')).toContain('recuento_discrepante');
		expect(obra.tramos[0].n_versos_fuente).toBe(5);
		obra.tramos[0].v_ini = 20;
		const informe = validarExtraccion(obra);
		expect(informe.estructura_valida).toBe(true);
		expect(codigos(informe, 'advertencias')).toContain('rango_invertido');
		expect(obra.tramos[0].v_ini).toBe(20);
	});
	it('admite un solo verso y no inventa una forma para él', () => {
		const obra = ejemplo();
		obra.tramos = [tramo('a', 2666, 2666, 'octosílabo suelto')];
		const informe = validarExtraccion(obra, opciones);
		expect(informe.errores).toEqual([]);
		expect(informe.datos_calculados.versos_union_conocida).toBe(1);
		expect(obra.tramos[0]).not.toHaveProperty('forma_id');
	});
	it('no da por exacto un agregado mayor que los enteros representables', () => {
		const obra = ejemplo();
		obra.tramos = [tramo('a', 1, Number.MAX_SAFE_INTEGER), tramo('b', 1, Number.MAX_SAFE_INTEGER)];
		const informe = validarExtraccion(obra, opciones);
		expect(codigos(informe, 'errores')).toContain('conteo_fuera_de_limite');
		expect(informe.datos_calculados.versos_union_conocida).toBe(Number.MAX_SAFE_INTEGER);
		expect(informe.datos_calculados.versos_suma_rangos_conocidos).toBeNull();
	});
});

describe('trazabilidad y notas de la edición', () => {
	it.each(['fila', 'jornada', 'nota', 'fuente'])('detecta referencias duplicadas de %s', (tipo) => {
		const obra = conNota();
		const config = structuredClone(opciones);
		if (tipo === 'fila') obra.tramos[1].id = obra.tramos[0].id;
		if (tipo === 'jornada') obra.jornadas.push({ ...obra.jornadas[0] });
		if (tipo === 'nota') obra.notas.push({ ...obra.notas[0] });
		if (tipo === 'fuente') config.fuentes.fotografias.push({ ...config.fuentes.fotografias[0] });
		expect(codigos(validarExtraccion(obra, config), 'errores')).toContain('referencia_duplicada');
	});
	it('no mezcla fotografías de otras obras', () => {
		const config = structuredClone(opciones);
		config.fuentes.fotografias[0].obra_ref = 'otra-obra';
		expect(codigos(validarExtraccion(ejemplo(), config), 'errores')).toContain(
			'fuente_de_otra_obra'
		);
	});
	it('detecta documento, foto y jornada no registrados', () => {
		const obra = ejemplo();
		obra.metadatos.fuente_id = 'doc-no-registrado';
		obra.tramos[0].fuente_id = 'foto-no-registrada';
		obra.tramos[0].jornada = 2;
		const informe = validarExtraccion(obra, opciones);
		expect(codigos(informe, 'errores')).toEqual(
			expect.arrayContaining([
				'fuente_metadatos_desconocida',
				'fuente_desconocida',
				'jornada_desconocida'
			])
		);
	});
	it('una página desconocida no invalida una fuente localizada por archivo', () => {
		const obra = ejemplo();
		obra.tramos[0].pagina = null;
		expect(validarExtraccion(obra, opciones).advertencias).toEqual([]);
		obra.tramos[0].pagina = 11;
		expect(codigos(validarExtraccion(obra, opciones), 'advertencias')).toContain(
			'pagina_discrepante'
		);
	});
	it('comprueba enlaces en ambas direcciones sin perder la nota', () => {
		const obra = conNota();
		obra.tramos[0].notas_ref = [];
		expect(codigos(validarExtraccion(obra, opciones), 'errores')).toContain(
			'enlace_tramo_no_reciproco'
		);
		expect(obra.notas[0].texto_literal).toContain('Nota sintética');
	});
	it('detecta una nota fuera de sus tramos, incluso si cae entre sus extremos', () => {
		const obra = conNota();
		obra.tramos = [tramo('t01', 1, 4), tramo('t02', 8, 10)];
		for (const row of obra.tramos) row.notas_ref = ['n01'];
		obra.notas[0].tramos_ref = ['t01', 't02'];
		obra.notas[0].v_ini = 3;
		obra.notas[0].v_fin = 9;
		expect(codigos(validarExtraccion(obra, opciones), 'advertencias')).toContain(
			'nota_fuera_de_tramos'
		);
	});
	it('localizar una excepción no cambia el número de tramos', () => {
		const obra = conNota();
		const original = JSON.stringify(obra);
		const informe = validarExtraccion(obra, opciones);
		expect(informe.errores).toEqual([]);
		expect(informe.datos_calculados.tramos).toBe(2);
		expect(JSON.stringify(obra)).toBe(original);
	});
	it('un contexto de fuentes mal formado produce diagnóstico y no excepción', () => {
		const informe = validarExtraccion(ejemplo(), { fuentes: { fotografias: null } });
		expect(informe.estructura_valida).toBe(true);
		expect(informe.errores.length).toBeGreaterThan(0);
		expect(informe.datos_calculados).toBeNull();
	});
});

describe('metadatos y resúmenes parciales', () => {
	it('fechas desconocidas quedan pendientes sin impedir transcribir los versos', () => {
		const obra = ejemplo();
		obra.metadatos.fecha_inicio = null;
		obra.metadatos.fecha_fin = null;
		const informe = validarExtraccion(obra, opciones);
		expect(informe.errores).toEqual([]);
		expect(codigos(informe, 'pendientes')).toContain('metadato_pendiente');
		expect(informe.datos_calculados.versos_union_conocida).toBe(8);
	});
	it('señala fechas invertidas sin estrechar el intervalo ni sustituirlas', () => {
		const obra = ejemplo();
		obra.metadatos.fecha_inicio = 1610;
		expect(codigos(validarExtraccion(obra, opciones), 'advertencias')).toContain(
			'fechas_invertidas'
		);
		expect(obra.metadatos.fecha_inicio).toBe(1610);
		expect(obra.metadatos.fecha_fin).toBe(1605);
	});
	it('un resumen parcial no se compara como total ni se vuelve a sumar a los versos', () => {
		const obra = ejemplo();
		obra.resumen_fuente = [
			{
				denominacion_literal: 'Etiqueta del resumen',
				n_versos_fuente: 4,
				porcentaje_literal: '50,0',
				fuente_id: 'foto-prueba',
				pagina: 10
			}
		];
		const parcial = validarExtraccion(obra, opciones);
		expect(parcial.advertencias).toEqual([]);
		expect(parcial.datos_calculados.versos_union_conocida).toBe(8);
		expect(parcial.datos_calculados.total_resumen_aportado).toBe(4);
		const completo = validarExtraccion(obra, { ...opciones, resumenCompleto: true });
		expect(codigos(completo, 'advertencias')).toContain('total_resumen_discrepante');
	});
	it('conserva porcentajes redondeados cuya suma es 100,1 sin corregirlos', () => {
		const obra = ejemplo();
		obra.resumen_fuente = ['50,1', '50,0'].map((porcentaje_literal, i) => ({
			denominacion_literal: `Grupo ${i}`,
			n_versos_fuente: 4,
			porcentaje_literal,
			fuente_id: 'foto-prueba',
			pagina: 10
		}));
		expect(validarExtraccion(obra, { ...opciones, resumenCompleto: true }).advertencias).toEqual(
			[]
		);
		expect(obra.resumen_fuente[0].porcentaje_literal).toBe('50,1');
	});
	it('no contrasta como extensión completa un resumen frente a rangos con huecos', () => {
		const obra = ejemplo();
		obra.tramos = [tramo('a', 1, 4), tramo('b', 7, 10)];
		obra.resumen_fuente = [
			{
				denominacion_literal: 'Total sintético',
				n_versos_fuente: 8,
				porcentaje_literal: '100',
				fuente_id: 'foto-prueba',
				pagina: 10
			}
		];
		expect(
			codigos(validarExtraccion(obra, { ...opciones, resumenCompleto: true }), 'pendientes')
		).toContain('resumen_no_comparable');
	});
});

describe('compatibilidad mecánica de las cuatro extracciones borrador', () => {
	const root = new URL('../../../docs/importador-metrico/piloto/', import.meta.url);
	const manifiesto = JSON.parse(readFileSync(new URL('fuentes.json', root), 'utf8'));
	it.each(['el-molino', 'el-verdadero-amante', 'los-donaires-de-matico', 'los-locos-de-valencia'])(
		'%s pasa sin afirmar que la transcripción sea gold',
		(ref) => {
			const texto = readFileSync(new URL(`extracciones/${ref}.json`, root), 'utf8');
			const informe = validarTextoExtraccion(texto, { fuentes: manifiesto });
			expect(informe.errores).toEqual([]);
			expect(informe.advertencias).toEqual([]);
			expect(codigos(informe, 'pendientes')).toContain('cotejo_humano_pendiente');
		}
	);
});

describe('CLI sin escrituras', () => {
	const cli = fileURLToPath(
		new URL('../../importador-metrico/validar-extraccion.mjs', import.meta.url)
	);
	const ejecutar = (input, args = ['-', '--json']) =>
		spawnSync(process.execPath, [cli, ...args], { input, encoding: 'utf8' });
	it('acepta stdin y devuelve un informe conservando pendientes', () => {
		const result = ejecutar(JSON.stringify(ejemplo()));
		expect(result.status, result.stderr).toBe(0);
		expect(JSON.parse(result.stdout).pendientes.length).toBeGreaterThan(0);
	});
	it('separa los códigos de formato y discrepancia', () => {
		expect(ejecutar('no json').status).toBe(1);
		const obra = ejemplo();
		obra.tramos[0].n_versos_fuente = 5;
		expect(ejecutar(JSON.stringify(obra)).status).toBe(2);
	});
	it('rechaza opciones desconocidas y rangos inválidos', () => {
		expect(ejecutar('', ['--borrar']).status).toBe(64);
		expect(ejecutar('', ['-', '--rango-esperado', '9:1']).status).toBe(64);
	});
	it('exporta JSON Schema sin leer una extracción', () => {
		const result = ejecutar('', ['--esquema']);
		expect(result.status, result.stderr).toBe(0);
		const schema = JSON.parse(result.stdout);
		expect(schema.properties.esquema.const).toBe('versologia-extraccion/0.1');
		expect(schema.additionalProperties).toBe(false);
	});
});
