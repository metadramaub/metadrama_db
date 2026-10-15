/** El disparador legado borra los subtipos al cambiar el rango de su secuencia.
 * Conservamos sus filas completas y las reponemos con los rangos del plan, dentro
 * de la misma transacción. También cubre las partes absorbidas en una fusión.
 */
export function conservarSubtipos(secuencias, previstos) {
	const literal = (valor) => `'${JSON.stringify(valor).replaceAll("'", "''")}'::jsonb`;
	const ids = (valores) =>
		`array[${[...new Set(valores)].map((id) => `'${id.replaceAll("'", "''")}'`).join(',')}]::uuid[]`;
	const originales = secuencias.flatMap((s) =>
		(s.subtipos ?? []).map((t) => {
			if (!t.origen_original) throw new Error('Falta la fila original completa de un subtipo.');
			return t.origen_original;
		})
	);
	if (
		originales.length !== previstos.length ||
		new Set(previstos.map((t) => t.subtipo_secuencia_id)).size !== originales.length
	)
		throw new Error('El plan no conserva todos los subtipos originales.');
	const porId = new Map(originales.map((t) => [t.subtipo_secuencia_id, t]));
	const finales = previstos.map((t) => {
		const origen = porId.get(t.subtipo_secuencia_id);
		if (!origen) throw new Error('El plan contiene un subtipo sin origen.');
		return { ...origen, secuencia_id: t.secuencia_id, v_ini: t.v_ini, v_fin: t.v_fin };
	});
	return {
		antes: [
			`select 1 from public.secuencias_subtipos_estrofa where secuencia_id = any(${ids(secuencias.map((s) => s.secuencia_id))}) for update;`,
			`do $subtipos$ begin
			 if (select count(*) from public.secuencias_subtipos_estrofa where secuencia_id = any(${ids(secuencias.map((s) => s.secuencia_id))})) <> ${originales.length}
			 or exists(select 1 from jsonb_array_elements(${literal(originales)}) e
			 left join public.secuencias_subtipos_estrofa t on t.subtipo_secuencia_id = (e->>'subtipo_secuencia_id')::uuid
			 where to_jsonb(t) is distinct from e) then
			 raise exception 'Han cambiado los subtipos desde la lectura; no se migra'; end if;
			 end; $subtipos$;`,
			`create temporary table subtipos_migracion on commit drop as
			 select * from jsonb_populate_recordset(null::public.secuencias_subtipos_estrofa, ${literal(finales)});`
		],
		despues: [
			`insert into public.secuencias_subtipos_estrofa as t select * from subtipos_migracion
			 on conflict (subtipo_secuencia_id) do update set
			 secuencia_id = excluded.secuencia_id, v_ini = excluded.v_ini, v_fin = excluded.v_fin
			 where (t.secuencia_id,t.v_ini,t.v_fin) is distinct from (excluded.secuencia_id,excluded.v_ini,excluded.v_fin);`,
			`do $subtipos$ begin
			 if (select count(*) from public.secuencias_subtipos_estrofa where secuencia_id = any(${ids(finales.map((t) => t.secuencia_id))})) <> ${finales.length}
			 or exists(select 1 from subtipos_migracion p left join public.secuencias_subtipos_estrofa t using(subtipo_secuencia_id)
			 where (to_jsonb(t)-'updated_at') is distinct from (to_jsonb(p)-'updated_at')) then
			 raise exception 'No se han conservado los subtipos con sus rangos previstos'; end if;
			 end; $subtipos$;`
		]
	};
}
