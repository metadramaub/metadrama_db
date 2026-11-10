import type { ObraEditorial } from '$lib/types/obra-editorial.types';

export type ObraControlRow = Pick<
	ObraEditorial,
	'obra_id' | 'titulo' | 'slug' | 'estado' | 'editor_asignado' | 'updated_at' | 'visible_publico'
> & {
	tipo_ficha?: string;
	dataciones?: unknown;
	fecha_inicio_trad?: number | null;
	fecha_fin_trad?: number | null;
	autores?: string[];
	corpus?: string[];
	importacion_id?: string | null;
	inicio_elaboracion?: string | null;
	procedencia_registro?: string | null;
};
