import type { Database as Generada } from './database.types';
import type { ObraEditorial, ObraEditorialInsert, ObraEditorialUpdate, ObraConsultaPublica } from './obra-editorial.types';

/** Solo completa los contratos de vistas que PostgreSQL no infiere por sus triggers.
 * La tabla física y el archivo generado siguen describiendo exactamente el esquema.
 */
export type Database = Omit<Generada, 'public'> & {
	public: Omit<Generada['public'], 'Views'> & {
		Views: Omit<Generada['public']['Views'], 'obras_editoriales' | 'obras_consulta_publica'> & {
			obras_editoriales: Omit<Generada['public']['Views']['obras_editoriales'], 'Row'> & {
				Row: ObraEditorial;
				Insert: ObraEditorialInsert;
				Update: ObraEditorialUpdate;
			};
			obras_consulta_publica: Omit<Generada['public']['Views']['obras_consulta_publica'], 'Row'> & {
				Row: ObraConsultaPublica;
			};
		};
	};
};
export type { Tables, Json } from './database.types';
