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
	modalidad: 'habitual',
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
	repeticiones: [],
	restriccionesRima: []
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
						slug: 'represa_total',
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
		expect(rpc).toHaveBeenCalledWith('get_forma_metrica_publica_jerarquica', {
			p_slug: 'villancico'
		});
		expect(resultado?.arquitecturas_[0].repeticiones).toEqual([
			{
				slug: 'represa_total',
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
						seccion_padre_id: null,
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
						seccion_padre_id: 'mudanza-inicial',
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
			'mudanza-inicial'
		]);
		expect(resultado?.arquitecturas_[0].secciones[0].hijas[0].id).toBe('mudanza-posterior');
		expect(resultado?.arquitecturas_[0].esquemasRima).toHaveLength(1);
		expect(resultado?.arquitecturas_[0].esquemasRima[0].id).toBe('rima-abba');
	});

	/**
	 * Un esquema abierto no tiene posiciones que enseñar: su norma son sus restricciones. Si no
	 * se leyeran, la ficha diría de esas formas únicamente que su rima es consonante.
	 */
	it('lee la norma de un esquema abierto en sus restricciones', async () => {
		const rpc = vi.fn().mockResolvedValue({
			data: {
				...detalleVacio,
				esquemasRima: [
					{
						esquema_rima_id: 'rima-abierta',
						arquitectura_id: arquitectura.arquitectura_id,
						nombre: 'Disposición variable',
						notacion: null,
						descripcion: null,
						ambito: 'unidad'
					},
					{
						esquema_rima_id: 'rima-manriquena',
						arquitectura_id: arquitectura.arquitectura_id,
						nombre: 'Manriqueña',
						notacion: 'abcabc|defdef',
						descripcion: null,
						ambito: 'unidad'
					}
				],
				restriccionesRima: [
					{
						esquema_rima_id: 'rima-abierta',
						tipo: 'regularidad',
						valor_numero: null,
						valor_texto: null,
						esquema_referido_id: null,
						obligatoria: true,
						descripcion: null
					},
					{
						esquema_rima_id: 'rima-abierta',
						tipo: 'excluye_esquema',
						valor_numero: null,
						valor_texto: null,
						esquema_referido_id: 'rima-manriquena',
						obligatoria: true,
						descripcion: null
					},
					{
						esquema_rima_id: 'rima-abierta',
						tipo: 'max_consecutivos',
						valor_numero: 2,
						valor_texto: null,
						esquema_referido_id: null,
						obligatoria: false,
						descripcion: null
					}
				]
			},
			error: null
		});

		const resultado = await loadPublicForm({ rpc }, 'villancico');
		const abierta = resultado?.arquitecturas_[0].esquemasRima.find(
			(esquema) => esquema.id === 'rima-abierta'
		);

		expect(abierta?.restricciones.map((r) => r.texto)).toEqual([
			'La disposición debe ser regular, aunque la norma no fije cuál',
			// La exclusión nombra al esquema al que apunta, no su identificador.
			'No puede coincidir con «Manriqueña»',
			'No más de 2 versos seguidos con la misma rima'
		]);
		expect(abierta?.restricciones.map((r) => r.obligatoria)).toEqual([true, true, false]);
		// Y un esquema cerrado no arrastra ninguna.
		expect(
			resultado?.arquitecturas_[0].esquemasRima.find((e) => e.id === 'rima-manriquena')
				?.restricciones
		).toEqual([]);
	});

	it('presenta el esquema sin nombre propio con la denominación que le dio la tradición', async () => {
		// Muchas disposiciones se identifican por su notación y no llevan `nombre`; el nombre
		// tradicional vive como denominación, que es donde acabó al dejar de ser forma hija.
		const rpc = vi.fn().mockResolvedValue({
			data: {
				...detalleVacio,
				esquemasRima: [
					{
						esquema_rima_id: 'rima-ababcc',
						arquitectura_id: arquitectura.arquitectura_id,
						nombre: null,
						notacion: 'ABABCC',
						descripcion: null,
						ambito: 'unidad'
					}
				],
				denominaciones: [
					{
						esquema_rima_id: 'rima-ababcc',
						nombre: 'Sexteto clásico',
						preferente: false
					},
					{ esquema_rima_id: 'rima-ababcc', nombre: 'Sexta rima', preferente: true }
				]
			},
			error: null
		});

		const resultado = await loadPublicForm({ rpc }, 'villancico');
		const esquema = resultado?.arquitecturas_[0].esquemasRima[0];

		// La preferente da el nombre, y por eso no se repite entre las demás.
		expect(esquema?.nombre).toBe('Sexta rima');
		expect(esquema?.denominaciones).toEqual(['Sexteto clásico']);
	});

	it('conserva el nombre propio del esquema y lista todas sus denominaciones', async () => {
		const rpc = vi.fn().mockResolvedValue({
			data: {
				...detalleVacio,
				esquemasRima: [
					{
						esquema_rima_id: 'rima-abab',
						arquitectura_id: arquitectura.arquitectura_id,
						nombre: 'Cruzada',
						notacion: 'abab',
						descripcion: null,
						ambito: 'unidad'
					}
				],
				denominaciones: [
					{ esquema_rima_id: 'rima-abab', nombre: 'Cuarteta', preferente: true }
				]
			},
			error: null
		});

		const resultado = await loadPublicForm({ rpc }, 'villancico');
		const esquema = resultado?.arquitecturas_[0].esquemasRima[0];

		expect(esquema?.nombre).toBe('Cruzada');
		expect(esquema?.denominaciones).toEqual(['Cuarteta']);
	});
});
