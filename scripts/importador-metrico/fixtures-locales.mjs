/** Datos sintéticos para PostgreSQL aislado y Supabase Auth local. */
import { readFileSync } from 'node:fs';
const json = (name) =>
	JSON.parse(
		readFileSync(new URL('../../docs/importador-metrico/piloto/' + name, import.meta.url), 'utf8')
	);
const lit = (v) => "'" + String(v).replaceAll("'", "''") + "'";
const autor = '00000000-0000-4000-8000-000000000100';
const refs = [
	'el-molino',
	'el-verdadero-amante',
	'los-donaires-de-matico',
	'los-locos-de-valencia'
];
export function semillaImportador(ids, crearAuth = true) {
	let seed = '';
	for (const v of json('auditoria-flujo-2026-10-26.json').vocabularios)
		seed += `insert into public.vocabularios(termino_id,categoria,termino) values(${lit(v.termino_id)},${lit(v.categoria)},${lit(v.termino)});\n`;
	for (const [i, role] of [
		'admin',
		'ip',
		'editor',
		'editor',
		'editor',
		'editor',
		'revisor'
	].entries()) {
		const rol = `20000000-0000-4000-8000-${String(i + 1).padStart(12, '0')}`;
		seed += `insert into public.vocabularios(termino_id,categoria,termino) values(${lit(rol)},'rol',${lit(role)}) on conflict (categoria,termino) do nothing;
${crearAuth ? `insert into auth.users(id) values(${lit(ids[i])});` : ''}
insert into public.editores(user_id,nombre_completo,email,role,activo,puede_importar_metrica)
values(${lit(ids[i])},'Persona de prueba ${i}',${lit(`prueba${i}@example.invalid`)},(select termino_id from public.vocabularios where categoria='rol' and termino=${lit(role)}),${i !== 5},${i === 2 || i === 3 || i === 5});\n`;
	}
	const nombre = json(`preparadas/${refs[0]}.json`).datos.metadatos.autor_nombre;
	seed += `insert into public.autores(autor_id,nombre_completo,slug) values(${lit(autor)},${lit(nombre)},'autor-de-prueba');\n`;
	for (const f of json('catalogo-referencia.json').formas) {
		seed += `insert into public.formas_metricas(forma_id,slug,nombre,definicion,tipo_registro)
values(${lit(f.forma_id)},${lit(f.slug)},${lit(f.nombre)},${lit(f.definicion)},${lit(f.tipo_registro)});\n`;
		for (const a of f.arquitecturas)
			seed += `insert into public.arquitecturas_forma(arquitectura_id,forma_id,slug,nombre,demarcable)
values(${lit(a.arquitectura_id)},${lit(f.forma_id)},${lit(a.slug)},${lit(a.nombre)},${f.tipo_registro !== 'sin_forma'});\n`;
	}
	for (const r of json('catalogo-referencia.json').rasgos) {
		// Solo ejercitamos referencias y contexto; la escala de recuento no interviene en estas pruebas.
		seed += `insert into public.rasgos_metricos(slug,nombre,tipo_valor,escala_recuento,naturaleza) values(${lit(r.slug)},${lit(r.nombre)},'catalogo','secuencia','construccion');\n`;
		for (const v of r.valores)
			seed += `insert into public.rasgo_valores(rasgo_id,slug,nombre) select rasgo_id,${lit(v.slug)},${lit(v.nombre)} from public.rasgos_metricos where slug=${lit(r.slug)};\n`;
		for (const c of r.contextos)
			seed += `insert into public.arquitectura_rasgos(arquitectura_id,rasgo_id,valor_id,modalidad) select a.arquitectura_id,r.rasgo_id,${c.valor_slug ? `(select valor_id from public.rasgo_valores where rasgo_id=r.rasgo_id and slug=${lit(c.valor_slug)})` : 'null'},'admitida' from public.arquitecturas_forma a join public.formas_metricas f using(forma_id) cross join public.rasgos_metricos r where f.slug=${lit(c.forma)} and a.slug=${lit(c.arquitectura)} and r.slug=${lit(r.slug)};\n`;
	}
	seed += `insert into public.estructuras_secciones(arquitectura_id,tipo_seccion,nombre,slug,orden)
select a.arquitectura_id,'remate','Remate o envío','remate',1 from public.arquitecturas_forma a
join public.formas_metricas f using(forma_id) where f.slug='cancion';\n`;
	for (const seccion of json('catalogo-referencia.json').secciones ?? []) {
		const forma = json('catalogo-referencia.json').formas.find((f) => f.slug === seccion.forma);
		const arquitectura = forma.arquitecturas.find((a) => a.slug === seccion.arquitectura);
		seed += `insert into public.estructuras_secciones(arquitectura_id,tipo_seccion,nombre,slug,orden,versos_min,versos_max)
values(${lit(arquitectura.arquitectura_id)},${lit(seccion.tipo_seccion)},${lit(seccion.seccion)},${lit(seccion.tipo_seccion)},${seccion.tipo_seccion === 'remate' ? 2 : 1},${seccion.versos_min},${seccion.versos_max});\n`;
	}
	for (const [slug, silabas] of [
		['heptasilabo', 7],
		['endecasilabo', 11],
		['octosilabo', 8]
	])
		seed += `insert into public.metros(slug,nombre,silabas) values(${lit(slug)},${lit(slug)},${silabas});\n`;
	return seed;
}
