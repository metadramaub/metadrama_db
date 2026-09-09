export type PortadaAutorDestacado = {
	nombre_completo: string;
	slug: string;
	wikidata_id: string;
};

export const PORTADA_OBRA_DESTACADA_ID = '9420715f-85e9-44c6-89eb-aea105ca05df';

export const PORTADA_AUTORES_DESTACADOS: PortadaAutorDestacado[] = [
	{
		nombre_completo: 'Diego Jiménez de Enciso',
		slug: 'diego-jimenez-de-enciso',
		wikidata_id: 'Q5274715'
	},
	{
		nombre_completo: 'Juan de la Cueva',
		slug: 'juan-de-la-cueva',
		wikidata_id: 'Q164964'
	},
	{
		nombre_completo: 'Juan Pérez de Montalbán',
		slug: 'juan-perez-de-montalban',
		wikidata_id: 'Q3100564'
	}
];
