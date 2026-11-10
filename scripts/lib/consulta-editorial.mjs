/** Herramientas editoriales: conservar contratos al separar obra y elaboración completa. */
import { query as consultar, tryQuery as intentar } from './consulta.mjs';
let nuevaRelacion;
function adaptar(sql) {
	if (nuevaRelacion === undefined) {
		nuevaRelacion = consultar(
			"select to_regclass('public.obras_editoriales') is not null as activa"
		)[0]?.activa;
	}
	return nuevaRelacion ? sql.replace(/public\.obras\b/g, 'public.obras_editoriales') : sql;
}
export function query(sql) {
	return consultar(adaptar(sql));
}
export function tryQuery(sql) {
	return intentar(adaptar(sql));
}
