import { describe, expect, it } from 'vitest';
import { renderInlineMarkdown, stripMarkdown } from './markdown';

/**
 * La prosa del catálogo métrico se escribe en Markdown y se imprime de dos maneras: con
 * marcas donde cabe HTML y sin ellas donde no cabe, como el `<meta name="description">` de la
 * ficha de una forma. Las dos salidas tienen que decir lo mismo.
 */
describe('renderInlineMarkdown', () => {
	it('marca la negrita y la cursiva', () => {
		expect(renderInlineMarkdown('tras el cuarto verso **debe** haber una pausa')).toBe(
			'tras el cuarto verso <strong>debe</strong> haber una pausa'
		);
		expect(renderInlineMarkdown('la *fronte* de la estancia')).toBe(
			'la <em>fronte</em> de la estancia'
		);
	});

	it('escapa el HTML antes de interpretar las marcas', () => {
		expect(renderInlineMarkdown('<script>alert(1)</script> **y**')).toBe(
			'&lt;script&gt;alert(1)&lt;/script&gt; <strong>y</strong>'
		);
	});

	it('deja intacto el texto sin marcas, tildes y comillas incluidas', () => {
		const llano = 'Serie abierta de versos isométricos: los pares comparten asonancia.';
		expect(renderInlineMarkdown(llano)).toBe(llano);
	});
});

describe('stripMarkdown', () => {
	it('quita las marcas sin tocar el texto', () => {
		expect(stripMarkdown('tras el cuarto verso **debe** haber una pausa')).toBe(
			'tras el cuarto verso debe haber una pausa'
		);
		expect(stripMarkdown('la *fronte* de la estancia')).toBe('la fronte de la estancia');
		expect(stripMarkdown('el nombre `redondilla`')).toBe('el nombre redondilla');
	});

	it('conserva el rótulo de un enlace y descarta su destino', () => {
		expect(stripMarkdown('véase [la norma](/formas) para el detalle')).toBe(
			'véase la norma para el detalle'
		);
	});

	it('no confunde un asterisco suelto con una cursiva', () => {
		expect(stripMarkdown('la nota * de la tabla')).toBe('la nota * de la tabla');
	});

	it('deja en paz una cursiva al final de la frase', () => {
		expect(stripMarkdown('lo llamó *espinela*.')).toBe('lo llamó espinela.');
	});
});
