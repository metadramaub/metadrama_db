import { describe, expect, it } from 'vitest';
import { creditoDeFigura } from './cita';
import { componerFigura, escaparXml, partirEnLineas, type Medidor } from './componer';
import type { FiguraDescargable, ProcedenciaFigura } from './tipos';

/** Un medidor de letra monoespaciada: cada carácter, medio cuerpo. */
const medir: Medidor = (texto, { cuerpo }) => texto.length * cuerpo * 0.5;

const figura: FiguraDescargable = { titulo: 'Dónde cae cada forma', archivo: 'x', admiteGrises: true };
const procedencia: ProcedenciaFigura = {
	obraTitulo: 'El mágico prodigioso',
	obraSlug: 'el-magico-prodigioso',
	autorFicha: 'Emma González Mesas',
	anio: '2026'
};
const credito = creditoDeFigura(figura, procedencia, { paleta: 'color' }, new Date('2026-09-23T10:00:00Z'));
const grafico = { svg: '<svg width="1000" height="200"><rect/></svg>', ancho: 1000, alto: 200 };

describe('partirEnLineas', () => {
	it('no pasa del ancho y no pierde palabras', () => {
		const lineas = partirEnLineas([{ texto: 'uno dos tres cuatro cinco seis' }], 50, 10, medir);
		for (const linea of lineas) {
			expect(medir(linea.map((p) => p.texto).join('').trimEnd(), { cuerpo: 10 })).toBeLessThanOrEqual(50);
		}
		expect(lineas.flat().map((p) => p.texto.trim()).join(' ')).toBe('uno dos tres cuatro cinco seis');
	});

	it('conserva la cursiva palabra a palabra', () => {
		const lineas = partirEnLineas(
			[{ texto: 'de ' }, { texto: 'El mágico', cursiva: true }, { texto: ', en' }],
			1000,
			10,
			medir
		);
		expect(lineas[0].map((p) => p.cursiva)).toEqual([false, true, true, false, false]);
	});

	it('una palabra más larga que el ancho va sola, no se pierde', () => {
		const lineas = partirEnLineas([{ texto: 'https://versologia.metadrama.org/obras/x y' }], 40, 10, medir);
		expect(lineas[0][0].texto.trim()).toBe('https://versologia.metadrama.org/obras/x');
	});
});

describe('componerFigura', () => {
	const compuesta = componerFigura({ grafico, credito, medir });

	it('lleva dentro el gráfico, el título y la cita', () => {
		expect(compuesta.svg).toContain('<rect/>');
		expect(compuesta.svg).toContain('Dónde cae cada forma');
		expect(compuesta.svg).toContain('Emma González Mesas');
		expect(compuesta.svg).toContain('https://versologia.metadrama.org/obras/el-magico-prodigioso');
		expect(compuesta.svg).toContain('CC BY-NC-SA 4.0');
	});

	it('pone la obra en cursiva', () => {
		expect(compuesta.svg).toContain('<tspan font-style="italic">El mágico prodigioso</tspan>');
	});

	it('declara los metadatos en Dublin Core y la licencia', () => {
		expect(compuesta.svg).toContain('<metadata><rdf:RDF');
		expect(compuesta.svg).toContain('<dc:source>https://versologia.metadrama.org/obras/el-magico-prodigioso</dc:source>');
		expect(compuesta.svg).toContain('rdf:resource="https://creativecommons.org/licenses/by-nc-sa/4.0/deed.es"');
	});

	it('es XML bien formado: todo texto de fuera va escapado', () => {
		const raro = creditoDeFigura(
			{ ...figura, titulo: 'A & B <c>' },
			{ ...procedencia, obraTitulo: 'Amar "sin" <saber>' },
			{ paleta: 'color' },
			new Date()
		);
		const svg = componerFigura({ grafico, credito: raro, medir }).svg;
		expect(svg).not.toMatch(/A & B/);
		expect(svg).toContain('A &amp; B &lt;c&gt;');
		expect(svg).not.toContain('<saber>');
	});

	it('reduce un gráfico demasiado ancho y deja sitio al pie en uno estrecho', () => {
		const ancho = componerFigura({ grafico: { ...grafico, ancho: 2000 }, credito, medir });
		expect(ancho.svg).toContain('scale(0.5)');
		expect(ancho.ancho).toBe(1080);
		const estrecho = componerFigura({ grafico: { ...grafico, ancho: 300 }, credito, medir });
		expect(estrecho.ancho).toBe(720);
	});

	it('crece con la leyenda', () => {
		const conLeyenda = componerFigura({
			grafico,
			credito,
			medir,
			leyenda: [
				{ etiqueta: 'Españolas', color: '#e07016' },
				{ etiqueta: 'Cambio de jornada', color: '#272727', muestra: 'linea' }
			]
		});
		expect(conLeyenda.alto).toBeGreaterThan(compuesta.alto);
		expect(conLeyenda.svg).toContain('Cambio de jornada');
	});
});

describe('escaparXml', () => {
	it('escapa los cinco caracteres reservados', () => {
		expect(escaparXml(`&<>"'`)).toBe('&amp;&lt;&gt;&quot;&apos;');
	});
});
