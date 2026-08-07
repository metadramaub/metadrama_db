import { describe, expect, it, vi } from 'vitest';
import { loadPublicForm, loadPublicForms } from './formas-publicas';

const forma = {
	forma_id: 'forma-villancico',
	slug: 'villancico',
	nombre: 'Villancico',
	definicion: 'Forma con estribillo.',
	tipo_registro: 'forma',
	nivel_estructural: 'composicion',
	orden: 1
};

const arquitectura = {
	arquitectura_id: 'arquitectura-inicial',
	forma_id: forma.forma_id,
	slug: 'estribillo_inicial',
	nombre: 'Estribillo inicial',
	descripcion: 'La cabeza abre la composición.',
	principal: true,
	modalidad: 'preferente',
	unidad_versos_min: null,
	unidad_versos_max: null,
	tipo_rima_id: null,
	orden: 1
};

const detalleVacio = {
	formas: [forma],
	arquitecturas: [arquitectura],
	esquemasMetricos: [],
	esquemasRima: [],
	enlacesRima: [],
	posicionesRima: [],
	secciones: [],
	gruposEleccion: [],
	opcionesEleccion: [],
	variedades: [],
	arquitecturaRasgos: [],
	rasgos: [],
	valores: [],
	tiposRima: [],
	denominaciones: [],
	tradiciones: [],
	formasTradiciones: [],
	afirmaciones: [],
	fuentes: [],
	relaciones: [],
	repeticiones: []
};

describe('catálogo público de formas', () => {
	it('carga el índice completo mediante una sola consulta agregada', async () => {
		const rpc = vi.fn().mockResolvedValue({
			data: {
				formas: [forma, { ...forma, forma_id: 'forma-zejel', slug: 'zejel', nombre: 'Zéjel' }],
				arquitecturas: [arquitectura],
				tiposRima: [],
				denominaciones: [],
				tradiciones: [],
				formasTradiciones: []
			},
			error: null
		});

		const resultado = await loadPublicForms({ rpc });

		expect(rpc).toHaveBeenCalledOnce();
		expect(rpc).toHaveBeenCalledWith('get_catalogo_formas_publicas', undefined);
		expect(resultado.map((item) => item.slug)).toEqual(['villancico', 'zejel']);
	});

	it('carga una ficha mediante una sola consulta e incluye sus repeticiones y fuentes', async () => {
		const rpc = vi.fn().mockResolvedValue({
			data: {
				...detalleVacio,
				repeticiones: [
					{
						arquitectura_id: arquitectura.arquitectura_id,
						tipo: 'estribillo',
						regla: 'La represa reproduce el estribillo.',
						modalidad: 'admitida',
						descripcion: 'Reaparición material.'
					}
				],
				afirmaciones: [
					{
						fuente_id: 'fuente-navarro',
						forma_id: forma.forma_id,
						arquitectura_id: null,
						localizador: '§ 145',
						resumen: 'Describe la forma clásica.',
						confianza: 'alta'
					}
				],
				fuentes: [
					{
						fuente_id: 'fuente-navarro',
						cita: 'Tomás Navarro Tomás, Métrica española',
						autoria: 'Tomás Navarro Tomás',
						titulo: 'Métrica española',
						anio: 1972
					}
				]
			},
			error: null
		});

		const resultado = await loadPublicForm({ rpc }, 'villancico');

		expect(rpc).toHaveBeenCalledOnce();
		expect(rpc).toHaveBeenCalledWith('get_forma_metrica_publica', { p_slug: 'villancico' });
		expect(resultado?.arquitecturas_[0].repeticiones).toEqual([
			{
				tipo: 'estribillo',
				regla: 'La represa reproduce el estribillo.',
				modalidad: 'admitida',
				descripcion: 'Reaparición material.'
			}
		]);
		expect(resultado?.fuentes).toHaveLength(1);
	});

	it('conserva ids de sección y no duplica una misma rima en mudanzas homónimas', async () => {
		const rpc = vi.fn().mockResolvedValue({
			data: {
				...detalleVacio,
				esquemasRima: [
					{
						esquema_rima_id: 'rima-abba',
						arquitectura_id: arquitectura.arquitectura_id,
						nombre: 'Mudanza en redondilla',
						notacion: 'abba',
						descripcion: null,
						ambito: 'seccion'
					}
				],
				secciones: [
					{
						seccion_id: 'mudanza-inicial',
						arquitectura_id: arquitectura.arquitectura_id,
						nombre: 'Mudanza',
						nota: null,
						versos_min: 4,
						versos_max: 4,
						repeticiones_min: 1,
						repeticiones_max: 1,
						arquitectura_referenciada_id: null,
						orden: 1
					},
					{
						seccion_id: 'mudanza-posterior',
						arquitectura_id: arquitectura.arquitectura_id,
						nombre: 'Mudanza',
						nota: null,
						versos_min: 4,
						versos_max: 4,
						repeticiones_min: 1,
						repeticiones_max: 1,
						arquitectura_referenciada_id: null,
						orden: 2
					}
				],
				gruposEleccion: [
					{
						grupo_eleccion_id: 'grupo-inicial',
						seccion_id: 'mudanza-inicial',
						dimension: 'rima'
					},
					{
						grupo_eleccion_id: 'grupo-posterior',
						seccion_id: 'mudanza-posterior',
						dimension: 'rima'
					}
				],
				opcionesEleccion: [
					{
						grupo_eleccion_id: 'grupo-inicial',
						esquema_rima_id: 'rima-abba',
						nombre: 'abba — redondilla',
						orden: 1
					},
					{
						grupo_eleccion_id: 'grupo-posterior',
						esquema_rima_id: 'rima-abba',
						nombre: 'abba — redondilla',
						orden: 1
					}
				]
			},
			error: null
		});

		const resultado = await loadPublicForm({ rpc }, 'villancico');

		expect(resultado?.arquitecturas_[0].secciones.map((seccion) => seccion.id)).toEqual([
			'mudanza-inicial',
			'mudanza-posterior'
		]);
		expect(resultado?.arquitecturas_[0].esquemasRima).toHaveLength(1);
		expect(resultado?.arquitecturas_[0].esquemasRima[0].id).toBe('rima-abba');
	});
});
