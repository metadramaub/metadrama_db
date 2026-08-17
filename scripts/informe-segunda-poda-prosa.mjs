import { writeFileSync } from 'node:fs';
import { query } from './lib/consulta.mjs';

/**
 * Inventario para la segunda poda de la prosa del catálogo.
 *
 * A diferencia del primer informe, este no decide mediante una heurística qué sobra. Agrupa todo
 * el texto vivo de los niveles bajos y coloca juntos los textos idénticos, de modo que puedan
 * aprobarse como bloque después de leer las fichas completas. Las definiciones de forma y las
 * descripciones de arquitectura aparecen aparte: se revisan para mejorar su alcance, no para
 * podarlas.
 */

const CAMPOS = [
	{
		etiqueta: 'esquemas_metricos.nombre',
		sql: `select f.slug || '/' || a.slug sujeto, em.slug clave, em.nombre texto
			from formas_metricas f join arquitecturas_forma a on a.forma_id=f.forma_id and a.activo
			join esquemas_metricos em on em.arquitectura_id=a.arquitectura_id
			where f.activo and em.nombre is not null`
	},
	{
		etiqueta: 'esquemas_metricos.descripcion',
		sql: `select f.slug || '/' || a.slug sujeto, em.slug clave, em.descripcion texto
			from formas_metricas f join arquitecturas_forma a on a.forma_id=f.forma_id and a.activo
			join esquemas_metricos em on em.arquitectura_id=a.arquitectura_id
			where f.activo and em.descripcion is not null`
	},
	{
		etiqueta: 'esquema_metrico_posiciones.nota',
		sql: `select f.slug || '/' || a.slug sujeto, em.slug || ' pos.' || p.posicion clave, p.nota texto
			from formas_metricas f join arquitecturas_forma a on a.forma_id=f.forma_id and a.activo
			join esquemas_metricos em on em.arquitectura_id=a.arquitectura_id
			join esquema_metrico_posiciones p on p.esquema_metrico_id=em.esquema_metrico_id
			where f.activo and p.nota is not null`
	},
	{
		etiqueta: 'esquemas_rima.descripcion',
		sql: `select f.slug || '/' || a.slug sujeto, er.slug clave, er.descripcion texto
			from formas_metricas f join arquitecturas_forma a on a.forma_id=f.forma_id and a.activo
			join esquemas_rima er on er.arquitectura_id=a.arquitectura_id
			where f.activo and er.descripcion is not null`
	},
	{
		etiqueta: 'esquema_rima_posiciones.nota',
		sql: `select f.slug || '/' || a.slug sujeto, er.slug || ' pos.' || p.posicion clave, p.nota texto
			from formas_metricas f join arquitecturas_forma a on a.forma_id=f.forma_id and a.activo
			join esquemas_rima er on er.arquitectura_id=a.arquitectura_id
			join esquema_rima_posiciones p on p.esquema_rima_id=er.esquema_rima_id
			where f.activo and p.nota is not null`
	},
	{
		etiqueta: 'esquema_rima_enlaces.nota',
		sql: `select f.slug || '/' || a.slug sujeto, er.slug clave, l.nota texto
			from formas_metricas f join arquitecturas_forma a on a.forma_id=f.forma_id and a.activo
			join esquemas_rima er on er.arquitectura_id=a.arquitectura_id
			join esquema_rima_enlaces l on l.esquema_rima_id=er.esquema_rima_id
			where f.activo and l.nota is not null`
	},
	{
		etiqueta: 'esquema_rima_restricciones.descripcion',
		sql: `select f.slug || '/' || a.slug sujeto, er.slug || ' · ' || rr.tipo clave, rr.descripcion texto
			from formas_metricas f join arquitecturas_forma a on a.forma_id=f.forma_id and a.activo
			join esquemas_rima er on er.arquitectura_id=a.arquitectura_id
			join esquema_rima_restricciones rr on rr.esquema_rima_id=er.esquema_rima_id
			where f.activo and rr.descripcion is not null`
	},
	{
		etiqueta: 'estructuras_secciones.nota',
		sql: `select f.slug || '/' || a.slug sujeto, s.slug clave, s.nota texto
			from formas_metricas f join arquitecturas_forma a on a.forma_id=f.forma_id and a.activo
			join estructuras_secciones s on s.arquitectura_id=a.arquitectura_id
			where f.activo and s.nota is not null`
	},
	{
		etiqueta: 'variedades_arquitectura.descripcion',
		sql: `select f.slug || '/' || a.slug sujeto, v.slug clave, v.descripcion texto
			from formas_metricas f join arquitecturas_forma a on a.forma_id=f.forma_id and a.activo
			join variedades_arquitectura v on v.arquitectura_id=a.arquitectura_id and v.activo
			where f.activo and v.descripcion is not null`
	},
	{
		etiqueta: 'repeticiones_metricas.descripcion',
		sql: `select f.slug || '/' || a.slug sujeto, r.slug clave, r.descripcion texto
			from formas_metricas f join arquitecturas_forma a on a.forma_id=f.forma_id and a.activo
			join repeticiones_metricas r on r.arquitectura_id=a.arquitectura_id
			where f.activo and r.descripcion is not null`
	},
	{
		etiqueta: 'arquitectura_rasgos.nota',
		sql: `select f.slug || '/' || a.slug sujeto, rg.slug clave, ar.nota texto
			from formas_metricas f join arquitecturas_forma a on a.forma_id=f.forma_id and a.activo
			join arquitectura_rasgos ar on ar.arquitectura_id=a.arquitectura_id
			join rasgos_metricos rg on rg.rasgo_id=ar.rasgo_id
			where f.activo and ar.nota is not null`
	},
	{
		etiqueta: 'forma_relaciones.nota',
		sql: `select f.slug sujeto, r.tipo_relacion clave, r.nota texto
			from formas_metricas f join forma_relaciones r on r.forma_origen_id=f.forma_id
			where f.activo and r.nota is not null`
	}
];

const filas = CAMPOS.flatMap((campo) =>
	query(campo.sql).map((fila) => ({ ...fila, campo: campo.etiqueta }))
);

const porTexto = new Map();
for (const fila of filas) {
	const grupo = porTexto.get(fila.texto) ?? [];
	grupo.push(fila);
	porTexto.set(fila.texto, grupo);
}

const repetidos = [...porTexto.entries()]
	.map(([texto, entradas]) => ({ texto, entradas }))
	.filter(({ entradas }) => entradas.length > 1)
	.sort((a, b) => b.entradas.length - a.entradas.length || a.texto.localeCompare(b.texto, 'es'));
const textosRepetidos = new Set(repetidos.map(({ texto }) => texto));

const formas = query(
	`select slug, nombre, definicion from formas_metricas where activo order by nombre`
);
const arquitecturas = query(`select f.slug forma, a.slug, a.nombre, a.modalidad, a.descripcion
	from formas_metricas f join arquitecturas_forma a on a.forma_id=f.forma_id
	where f.activo and a.activo order by f.nombre, a.principal desc, a.nombre`);

const lineas = [
	'# Segunda poda de la prosa del catálogo',
	'',
	'Inventario generado directamente de la base viva. No contiene decisiones automáticas.',
	'Las coincidencias literales se revisan por bloques; los textos singulares, por campo.',
	'Las definiciones y descripciones altas se revisan solo para mejorar su alcance.',
	'',
	`**${filas.length} textos bajos · ${repetidos.length} bloques idénticos · ` +
		`${filas.filter((fila) => textosRepetidos.has(fila.texto)).length} apariciones agrupadas.**`,
	'',
	'## Bloques idénticos',
	''
];

for (const [indice, grupo] of repetidos.entries()) {
	lineas.push(
		`### B${indice + 1} · ${grupo.entradas.length} apariciones`,
		'',
		`«${grupo.texto}»`,
		''
	);
	for (const entrada of grupo.entradas) {
		lineas.push(`- \`${entrada.campo}\` · **${entrada.sujeto}** · \`${entrada.clave}\``);
	}
	lineas.push('');
}

lineas.push('## Textos singulares por campo', '');
for (const campo of CAMPOS) {
	const singulares = filas
		.filter((fila) => fila.campo === campo.etiqueta && !textosRepetidos.has(fila.texto))
		.sort((a, b) => a.sujeto.localeCompare(b.sujeto, 'es') || a.clave.localeCompare(b.clave, 'es'));
	lineas.push(`### ${campo.etiqueta} · ${singulares.length}`, '');
	for (const fila of singulares) {
		lineas.push(`- **${fila.sujeto}** · \`${fila.clave}\`: «${fila.texto}»`);
	}
	lineas.push('');
}

lineas.push('## Definiciones de forma', '');
for (const forma of formas) {
	lineas.push(`- **${forma.nombre}** · \`${forma.slug}\`: «${forma.definicion ?? '—'}»`);
}

lineas.push('', '## Descripciones de arquitectura', '');
for (const arquitectura of arquitecturas) {
	lineas.push(
		`- **${arquitectura.forma}/${arquitectura.slug}** · ${arquitectura.nombre}` +
			`${arquitectura.modalidad ? ` · ${arquitectura.modalidad}` : ''}: «${arquitectura.descripcion ?? '—'}»`
	);
}

writeFileSync('docs/dominio-metrico/segunda-poda-de-la-prosa.md', lineas.join('\n'), 'utf8');
console.log(
	`${filas.length} textos bajos · ${repetidos.length} bloques idénticos · ` +
		`${filas.filter((fila) => textosRepetidos.has(fila.texto)).length} apariciones agrupadas`
);
