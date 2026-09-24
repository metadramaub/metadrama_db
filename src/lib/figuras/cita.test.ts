import { describe, expect, it } from 'vitest';
import { anioDeFicha, autoriaDeFigura, citaDelAnalisis, creditoDeFigura, textoDe } from './cita';
import type { ProcedenciaFigura } from './tipos';

const procedencia: ProcedenciaFigura = {
	obraTitulo: 'El mágico prodigioso',
	obraSlug: 'el-magico-prodigioso',
	autorFicha: 'Emma González Mesas',
	anio: '2026'
};
const consulta = new Date('2026-09-23T10:00:00Z');

describe('citaDelAnalisis', () => {
	it('sigue la forma de «Cómo citar un análisis específico»', () => {
		expect(textoDe(citaDelAnalisis(procedencia, consulta))).toBe(
			'Emma González Mesas, «Análisis y estudio versológico de El mágico prodigioso», en Gaston ' +
				'Gilabert y David Merino Recalde, Versología: base de datos y herramientas de estilometría ' +
				'estrófica para el verso dramático [https://versologia.metadrama.org/obras/el-magico-prodigioso], ' +
				'2026 (consulta: 23 de septiembre de 2026).'
		);
	});

	it('pone en cursiva la obra y el recurso, y nada más', () => {
		const cursivas = citaDelAnalisis(procedencia, consulta)
			.filter((tramo) => tramo.cursiva)
			.map((tramo) => tramo.texto);
		expect(cursivas).toEqual([
			'El mágico prodigioso',
			'Versología: base de datos y herramientas de estilometría estrófica para el verso dramático'
		]);
	});

	it('sin fecha de consulta —en el servidor— la cita acaba en el año', () => {
		expect(textoDe(citaDelAnalisis(procedencia)).endsWith('[https://versologia.metadrama.org/obras/el-magico-prodigioso], 2026.')).toBe(true);
	});

	it('sin editor, cita el análisis sin firma', () => {
		const texto = textoDe(citaDelAnalisis({ ...procedencia, autorFicha: '  ' }, consulta));
		expect(texto.startsWith('«Análisis')).toBe(true);
	});
});

describe('autoría', () => {
	it('separa quién anotó de quién visualizó', () => {
		expect(autoriaDeFigura(procedencia)).toBe(
			'Anotación métrica: Emma González Mesas. Visualización: Versología (Gaston Gilabert y David Merino Recalde).'
		);
	});

	it('dice de cuándo son los datos, tras el editor', () => {
		expect(autoriaDeFigura({ ...procedencia, actualizada: '2026-09-18T09:56:00Z' })).toBe(
			'Anotación métrica: Emma González Mesas, datos a 18 de septiembre de 2026. ' +
				'Visualización: Versología (Gaston Gilabert y David Merino Recalde).'
		);
	});

	it('sin editor, la fecha de los datos va sola y en mayúscula', () => {
		expect(
			autoriaDeFigura({ ...procedencia, autorFicha: null, actualizada: '2026-09-18T09:56:00Z' })
		).toBe(
			'Datos a 18 de septiembre de 2026. Visualización: Versología (Gaston Gilabert y David Merino Recalde).'
		);
	});

	it('pone al editor y al proyecto como autores en los metadatos', () => {
		const credito = creditoDeFigura(
			{ titulo: 'Perfil métrico', archivo: 'perfil', admiteGrises: false },
			procedencia,
			{ paleta: 'color' },
			consulta
		);
		expect(credito.metadatos.autor).toBe(
			'Emma González Mesas; Versología (Gaston Gilabert y David Merino Recalde)'
		);
		expect(credito.metadatos.titulo).toBe('Perfil métrico. El mágico prodigioso');
	});

	it('dice en el pie si la figura es la versión en blanco y negro', () => {
		const credito = creditoDeFigura(
			{ titulo: 'x', archivo: 'x', admiteGrises: true },
			procedencia,
			{ paleta: 'grises' },
			consulta
		);
		expect(textoDe(credito.pie.at(-1) ?? [])).toContain('blanco y negro');
	});
});

describe('anioDeFicha', () => {
	it('toma el año de la última actualización', () => {
		expect(anioDeFicha('2026-03-01T12:00:00Z')).toBe('2026');
	});

	it('sin fecha, «s. f.»', () => {
		expect(anioDeFicha(null)).toBe('s. f.');
		expect(anioDeFicha('no es una fecha')).toBe('s. f.');
	});
});
