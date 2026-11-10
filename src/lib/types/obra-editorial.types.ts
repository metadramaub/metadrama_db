import type { Database, Json } from './database.types';

type FilaGenerada = Database['public']['Views']['obras_editoriales']['Row'];
type CamposGarantizados =
	| 'obra_id' | 'titulo' | 'slug' | 'created_at' | 'updated_at' | 'estado'
	| 'tipo_ficha' | 'autores' | 'corpus' | 'dataciones' | 'visible_publico'
	| 'sin_figuras_donaire' | 'sin_personajes_sobrenaturales' | 'sin_eventos_sobrenaturales';

/** Contrato de la vista: PK del núcleo, COALESCE y agregados garantizados por SQL.
 * Los tipos generados se conservan intactos; no representan esta vista como una tabla física.
 */
export type ObraEditorial = Omit<FilaGenerada, CamposGarantizados> & {
	[K in Exclude<CamposGarantizados, 'tipo_ficha' | 'dataciones'>]: NonNullable<FilaGenerada[K]>;
} & {
	tipo_ficha: 'sin_ficha' | 'basica' | 'completa';
	dataciones: Json;
};

type CamposCalculados = 'autores' | 'corpus' | 'importacion_id' | 'importado_por'
	| 'inicio_elaboracion' | 'procedencia_registro';
export type ObraEditorialInsert = Pick<ObraEditorial, 'titulo'> &
	Partial<Omit<ObraEditorial, 'titulo' | CamposCalculados>>;
export type ObraEditorialUpdate = Partial<Omit<ObraEditorialInsert, 'obra_id' | 'tipo_ficha'>>;

type PublicaGenerada = Database['public']['Views']['obras_consulta_publica']['Row'];
export type ObraConsultaPublica = Omit<PublicaGenerada, 'obra_id' | 'titulo' | 'slug' | 'estado' | 'dataciones' | 'updated_at'> &
	Pick<ObraEditorial, 'obra_id' | 'titulo' | 'slug' | 'estado' | 'dataciones' | 'updated_at'>;
