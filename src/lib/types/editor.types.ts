import type { Tables } from '$lib/types/database.types';

export type EditorJornadaRow = Pick<
	Tables<'jornadas'>,
	'jornada_id' | 'jornada_num' | 'obra_id' | 'v_ini' | 'v_fin'
>;

export type EditorCuadroRow = Pick<
	Tables<'cuadros'>,
	'cuadro_id' | 'cuadro_num' | 'jornada_id' | 'v_ini' | 'v_fin'
>;

export type EditorSecuenciaRow = Pick<
	Tables<'secuencias_metricas'>,
	| 'secuencia_id'
	| 'obra_id'
	| 'v_ini'
	| 'v_fin'
	| 'n_versos'
	| 'estrofa_tipo_id'
	| 'inaugura_espacio'
	| 'versos_partidos'
	| 'intervencion_personajes_femeninos'
	| 'intervencion_figuras_donaire'
	| 'intervencion_personajes_sobrenaturales'
	| 'evento_sobrenatural'
	| 'sinopsis'
> & {
	/**
	 * Si la secuencia está anotada con el catálogo nuevo. No es una columna: la estampa el `load` de
	 * la obra cruzando `anotaciones_metricas`, y la checklist de revisión la mira para no dar por
	 * incompleta una secuencia cuya forma vive ahí y no en `estrofa_tipo_id`. Quien reemplace una
	 * fila con la respuesta de la API —que devuelve la tabla a secas— tiene que volver a ponerla.
	 */
	tiene_anotacion_metrica?: boolean;
};
