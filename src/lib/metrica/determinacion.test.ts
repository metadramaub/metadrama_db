import { describe, expect, it } from 'vitest';
import type { PublicArchitecture, PublicSection } from './formas-publicas.types';
import {
	determinacionDeExtension,
	determinacionDeMedida,
	determinacionDePartes,
	determinacionDeRepeticion,
	determinacionDeRima
} from './determinacion';

function arquitectura(cambios: Partial<PublicArchitecture> = {}): PublicArchitecture {
	return {
		slug: 'arquitectura',
		nombre: 'Arquitectura',
		descripcion: null,
		principal: true,
		modalidad: 'habitual',
		tipoRima: 'Consonante',
		tipoRimaPorDisposicion: false,
		tipoRimaSinDeclarar: false,
		unidadMin: 4,
		unidadMax: 4,
		perfil: 'estrofa_elegible',
		rejilla: null,
		esquemasMetricos: [],
		esquemasRima: [],
		secciones: [],
		variedades: [],
		eligeVariedad: false,
		rasgos: { declarados: [], permitidos: [], excluyentes: [], opcionales: [] },
		repeticiones: [],
		elecciones: [],
		denominaciones: [],
		...cambios
	};
}

function seccion(cambios: Partial<PublicSection> = {}): PublicSection {
	return {
		id: 'seccion',
		nombre: 'Sección',
		nota: null,
		esquemasRima: [],
		versosMin: 4,
		versosMax: 4,
		repeticionesMin: 1,
		repeticionesMax: 1,
		primeraRealizacionDefinePatron: false,
		denominaciones: [],
		reutiliza: null,
		hijas: [],
		...cambios
	};
}

describe('grado de determinación de una arquitectura', () => {
	it('distingue extensión fija, acotada y abierta', () => {
		expect(determinacionDeExtension(arquitectura()).grado).toBe('fijo');
		expect(determinacionDeExtension(arquitectura({ unidadMin: 5, unidadMax: 12 })).grado).toBe(
			'acotado'
		);
		expect(determinacionDeExtension(arquitectura({ unidadMin: null, unidadMax: null })).grado).toBe(
			'abierto'
		);
	});

	it('separa un repertorio variable del patrón fijado por la primera unidad', () => {
		const esquema = {
			nombre: 'Repertorio',
			notacion: null,
			descripcion: null,
			modalidad: null,
			tipoSecuencia: 'conjunto',
			uniforme: false,
			repertorio: [
				{ silabas: '7', rol: null },
				{ silabas: '11', rol: null }
			],
			deLaSeccion: null
		};
		expect(determinacionDeMedida(arquitectura({ esquemasMetricos: [esquema] })).grado).toBe(
			'variable'
		);
		expect(
			determinacionDeMedida(
				arquitectura({
					esquemasMetricos: [esquema],
					elecciones: [
						{
							dimension: 'metro',
							alcance: 'unidad',
							seccion: null,
							tipoControl: 'opciones',
							seleccionesMin: 1,
							seleccionesMax: 1,
							defineNorma: true,
							opciones: 2
						}
					]
				})
			).grado
		).toBe('primera_unidad');
	});

	it('reconoce una medida elegida por cada parte aunque cada parte sea isométrica', () => {
		const esquema = {
			nombre: 'Hexasílabo u octosílabo',
			notacion: null,
			descripcion: null,
			modalidad: null,
			tipoSecuencia: 'conjunto',
			uniforme: true,
			repertorio: [
				{ silabas: '6', rol: null },
				{ silabas: '8', rol: null }
			],
			deLaSeccion: null
		};
		const grupo = (seccion: string) => ({
			dimension: 'metro',
			alcance: 'unidad',
			seccion,
			tipoControl: 'opciones',
			seleccionesMin: 1,
			seleccionesMax: 1,
			defineNorma: false,
			opciones: 2
		});

		expect(
			determinacionDeMedida(
				arquitectura({
					esquemasMetricos: [esquema],
					elecciones: [grupo('Cabeza'), grupo('Mudanza'), grupo('Enlace o vuelta')]
				})
			)
		).toEqual({ grado: 'variable', detalle: 'una medida por parte' });
	});

	it('no convierte una única disposición habitual en fija', () => {
		expect(
			determinacionDeRima(
				arquitectura({
					esquemasRima: [
						{
							id: 'rima',
							nombre: 'Disposición',
							notacion: 'ABABABCC',
							descripcion: null,
							modalidad: 'habitual',
							tipoRima: 'Consonante',
							figura: [
								{ clase: 'A', suelto: false },
								{ clase: 'B', suelto: false },
								{ clase: 'A', suelto: false },
								{ clase: 'B', suelto: false },
								{ clase: 'A', suelto: false },
								{ clase: 'B', suelto: false },
								{ clase: 'C', suelto: false },
								{ clase: 'C', suelto: false }
							],
							abierto: false,
							cicla: false,
							enlaces: [],
							partes: [],
							restricciones: [],
							deLaSeccion: null,
							seccionId: null,
							denominaciones: []
						}
					]
				})
			).grado
		).toBe('no_fijado');
	});

	it('da prioridad a una elección real sobre el esquema abierto que la acota', () => {
		expect(
			determinacionDeRima(
				arquitectura({
					esquemasRima: [
						{
							id: 'abierta',
							nombre: 'Distribución variable',
							notacion: null,
							descripcion: null,
							modalidad: 'definitoria',
							tipoRima: 'Consonante',
							figura: [],
							abierto: true,
							cicla: false,
							enlaces: [],
							partes: [],
							restricciones: [{ texto: 'Dos clases de rima' }],
							deLaSeccion: null,
							seccionId: null,
							denominaciones: []
						}
					],
					elecciones: [
						{
							dimension: 'rima',
							alcance: 'unidad',
							seccion: null,
							tipoControl: 'opciones',
							seleccionesMin: 1,
							seleccionesMax: 1,
							defineNorma: false,
							opciones: 8
						}
					]
				})
			).grado
		).toBe('variable');
	});

	it('resume la estructura variable sin confundirla con una parte opcional aislada', () => {
		expect(
			determinacionDePartes(
				arquitectura({
					secciones: [seccion({ repeticionesMin: 1, repeticionesMax: null })]
				})
			).grado
		).toBe('abierto');
		expect(
			determinacionDePartes(
				arquitectura({
					secciones: [seccion({ primeraRealizacionDefinePatron: true })]
				})
			).grado
		).toBe('primera_unidad');
	});

	it('distingue una repetición fija de una que varía en cada ciclo', () => {
		expect(determinacionDeRepeticion(arquitectura(), false).grado).toBe('fijo');
		expect(determinacionDeRepeticion(arquitectura(), true)).toEqual({
			grado: 'variable',
			detalle: 'en cada ciclo'
		});
	});
});
