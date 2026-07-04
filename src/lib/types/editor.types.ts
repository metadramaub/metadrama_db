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
	| 'evocacion_metrica'
	| 'evocacion_metrica_texto'
	| 'intervencion_personajes_femeninos'
	| 'intervencion_figuras_donaire'
	| 'intervencion_personajes_sobrenaturales'
	| 'sinopsis'
>;
