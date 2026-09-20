/**
 * Migra una obra: lee el Excel que devolvió su editor y escribe la anotación nueva.
 *
 *   npm run migracion:aplicar -- --obra dido-y-eneas --simular
 *   npm run migracion:aplicar -- --obra dido-y-eneas
 *
 * **Con `--simular` no se toca la base.** Se hace el plan entero —las correcciones, las
 * anotaciones, lo que queda pendiente y por qué— y se escribe en `backups/migracion/`, que no está
 * versionado. Es lo que hay que leer antes de aplicar de verdad.
 *
 * Con `--simular --ensayar` se ejecuta además la transacción entera **y se deshace**. Es lo único
 * que responde a la pregunta que importa: si `guardar_anotacion_metrica` va a aceptar lo que se le
 * manda. Un plan puede estar bien escrito y que a una pregunta le falte una respuesta que solo la
 * función cuenta, y entonces la migración se cae al aplicarla. Escribe y deshace, así que fuera de
 * un ensayo deliberado no se usa.
 *
 * Sin `--simular`:
 *
 *   1. se comprueba que la obra está como se espera y se toma un snapshot suyo;
 *   2. **en una sola transacción**: las correcciones a las tablas legadas —renumeraciones por una
 *      laguna que no se contó, rangos, fusiones—, la anotación de cada secuencia por
 *      `guardar_anotacion_metrica` y el rastro en `migracion_secuencias`;
 *   3. se cuenta contra la base lo que se dice escrito, porque una transacción puede deshacerse sin
 *      que la CLI lo cuente como error.
 *
 * La identidad que se presta es la del **editor asignado**, no la de quien ejecuta: la anotación
 * queda firmada por quien la hizo en su día. `guardar_anotacion_metrica` pide el permiso sobre la
 * obra con `auth.uid()`, así que sin esa identidad la función niega.
 *
 * **No hay pausa de edición.** Se avisa al editor de que no toque la obra desde que devuelve el
 * Excel hasta que se le confirma la migración; aquí se comprueba, antes de escribir, que la obra
 * sigue teniendo los versos que el informe dijo.
 */

import { existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { query, tryQuery } from './lib/consulta.mjs';
import { cargarCatalogo } from './lib/metrica/catalogo.mjs';
import { cargarObras } from './lib/migracion/datos.mjs';
import { planificarObra } from './lib/migracion/aplicador.mjs';
import { leerRespuestas } from './lib/migracion/respuestas.mjs';

const RAIZ = fileURLToPath(new URL('..', import.meta.url));
const RESPUESTAS = join(RAIZ, 'docs', 'dominio-metrico', 'migracion', 'respuestas');
const SALIDA = join(RAIZ, 'backups', 'migracion');

function argumentos(argv) {
	const opciones = { obra: null, simular: false, ensayar: false, respuestas: null };
	for (let i = 0; i < argv.length; i += 1) {
		if (argv[i] === '--obra') opciones.obra = argv[i + 1] ?? null;
		if (argv[i] === '--simular') opciones.simular = true;
		if (argv[i] === '--ensayar') opciones.ensayar = true;
		if (argv[i] === '--respuestas') opciones.respuestas = argv[i + 1] ?? null;
	}
	return opciones;
}

const lit = (valor) =>
	valor === null || valor === undefined ? 'null' : `'${String(valor).replaceAll("'", "''")}'`;
const bool = (valor) => (valor === true ? 'true' : valor === false ? 'false' : 'null');
const scalar = (sql) => {
	const filas = query(sql);
	return filas.length === 0 ? null : Object.values(filas[0])[0];
};

// --------------------------------------------------------------------------
// El guion legible
// --------------------------------------------------------------------------

function guionDe(obra, plan, opciones) {
	const l = [];
	const w = (t = '') => l.push(t);
	const anotadas = plan.anotaciones.filter((a) => a.resultado !== 'pendiente');
	const pendientes = plan.anotaciones.filter((a) => a.resultado === 'pendiente');

	w(`# Migración de «${obra.titulo}»`);
	w();
	w(
		`${opciones.simular ? 'Simulación' : 'Aplicación'} del ${new Date().toISOString().slice(0, 19).replace('T', ' ')}.`
	);
	w(
		`${obra.secuencias.length} secuencias legadas · ${anotadas.length} se anotan · ` +
			`${pendientes.length} quedan pendientes · ${plan.correcciones.length} correcciones.`
	);
	w();

	w('## Correcciones a las tablas legadas');
	w();
	if (plan.correcciones.length === 0) w('Ninguna.');
	for (const correccion of plan.correcciones) w(`- ${correccion.descripcion}`);
	w();

	w('## Lo que se anota');
	w();
	for (const anotacion of anotadas) {
		const datos = anotacion.datos;
		const unidades = datos.unidades.filter((u) => u.realizacion_padre_id === null).length;
		w(
			`- **${datos.v_ini}–${datos.v_fin}** · ${anotacion.secuencia.forma_propuesta} · ` +
				`${anotacion.secuencia.arquitectura_propuesta ?? '—'} · ${unidades} estrofas · ` +
				`${datos.elecciones.length} respuestas · ${datos.desviaciones.length} desviaciones` +
				`${anotacion.resultado === 'fundida' ? ' · fundida' : ''}`
		);
		for (const aviso of anotacion.avisos ?? []) w(`  - ${aviso}`);
	}
	if (anotadas.length === 0) w('Nada.');
	w();

	w('## Lo que queda pendiente');
	w();
	if (pendientes.length === 0 && plan.pendientes.length === 0) w('Nada: la obra se migra entera.');
	for (const anotacion of pendientes) {
		for (const motivo of anotacion.motivos) w(`- ${motivo}`);
	}
	for (const pendiente of plan.pendientes) w(`- ${pendiente}`);
	w();

	w('## El detalle, secuencia a secuencia');
	w();
	w('```json');
	w(
		JSON.stringify(
			anotadas.map((a) => a.datos),
			null,
			'\t'
		)
	);
	w('```');
	return l.join('\n');
}

// --------------------------------------------------------------------------
// Las sentencias
// --------------------------------------------------------------------------

/**
 * Renumerar la obra desde un verso: **cuenta los versos que la laguna no contó**.
 *
 * Un rango que empieza en el salto o después se desplaza entero; uno que lo contiene crece por el
 * final. Se mueven las secuencias, las estrofas anotadas, las caracterizaciones, las jornadas y los
 * cuadros, y el total de versos de la obra.
 */
function sentenciasDeRenumeracion(obraId, correccion) {
	const desde = correccion.desde_efectivo ?? correccion.desde;
	const n = Number(correccion.faltan);
	const mover = (tabla, condicion) => `
		update public.${tabla} t
		set v_ini = case when t.v_ini >= ${desde} then t.v_ini + ${n} else t.v_ini end,
			v_fin = case when t.v_fin >= ${desde} then t.v_fin + ${n} else t.v_fin end
		where ${condicion};`;
	return [
		mover('secuencias_metricas', `t.obra_id = ${lit(obraId)}::uuid and t.v_fin >= ${desde}`),
		`update public.secuencias_metricas t set n_versos = t.v_fin - t.v_ini + 1
		 where t.obra_id = ${lit(obraId)}::uuid and t.n_versos <> t.v_fin - t.v_ini + 1;`,
		mover(
			'secuencias_subtipos_estrofa',
			`t.secuencia_id in (select s.secuencia_id from public.secuencias_metricas s where s.obra_id = ${lit(obraId)}::uuid) and t.v_fin >= ${desde}`
		),
		mover(
			'secuencias_caracterizaciones_rango',
			`t.secuencia_id in (select s.secuencia_id from public.secuencias_metricas s where s.obra_id = ${lit(obraId)}::uuid) and t.v_fin >= ${desde}`
		),
		mover('jornadas', `t.obra_id = ${lit(obraId)}::uuid and t.v_fin >= ${desde}`),
		mover(
			'cuadros',
			`t.jornada_id in (select j.jornada_id from public.jornadas j where j.obra_id = ${lit(obraId)}::uuid) and t.v_fin >= ${desde}`
		),
		`update public.obras set total_versos = total_versos + ${n} where obra_id = ${lit(obraId)}::uuid;`
	];
}

function sentenciasDeCorreccion(obraId, correccion) {
	if (correccion.tipo === 'renumerar') return sentenciasDeRenumeracion(obraId, correccion);

	if (correccion.tipo === 'rango') {
		return [
			`update public.secuencias_metricas
			 set v_ini = ${correccion.v_ini}, v_fin = ${correccion.v_fin},
				 n_versos = ${correccion.v_fin - correccion.v_ini + 1}
			 where secuencia_id = ${lit(correccion.secuencia_id)}::uuid;`
		];
	}

	if (correccion.tipo === 'fusion') {
		const superviviente = lit(correccion.secuencia_id);
		const absorbidas = correccion.absorbidas.map((a) => `${lit(a.secuencia_id)}::uuid`).join(', ');
		const i = correccion.indicadores;
		return [
			// Las estrofas y las caracterizaciones de las partes pasan a la secuencia que queda:
			// son lo que alguien miró verso a verso y no se pierde al fundir.
			`update public.secuencias_subtipos_estrofa set secuencia_id = ${superviviente}::uuid
			 where secuencia_id in (${absorbidas});`,
			`update public.secuencias_caracterizaciones_rango set secuencia_id = ${superviviente}::uuid
			 where secuencia_id in (${absorbidas});`,
			`update public.secuencias_metricas
			 set v_fin = ${correccion.v_fin},
				 n_versos = ${correccion.v_fin - correccion.v_ini + 1},
				 inaugura_espacio = ${bool(i.inaugura_espacio)},
				 versos_partidos = ${bool(i.versos_partidos)},
				 evento_sobrenatural = ${bool(i.evento_sobrenatural)},
				 intervencion_personajes_femeninos = ${lit(i.intervencion_personajes_femeninos)},
				 intervencion_figuras_donaire = ${lit(i.intervencion_figuras_donaire)},
				 intervencion_personajes_sobrenaturales = ${lit(i.intervencion_personajes_sobrenaturales)}
				 ${correccion.sinopsis ? `, sinopsis = ${lit(correccion.sinopsis)}` : ''}
			 where secuencia_id = ${superviviente}::uuid;`,
			`delete from public.secuencias_metricas where secuencia_id in (${absorbidas});`
		];
	}

	return [];
}

/** El rastro de una secuencia migrada, que se reescribe si la obra se vuelve a migrar. */
function sentenciaDeRastro(obraId, anotacion, correcciones, editorId) {
	const secuencia = anotacion.secuencia;
	const suyas = correcciones.filter((c) => c.secuencia_id === secuencia.secuencia_id);
	const respuestas = {
		via: secuencia.via,
		forma: secuencia.forma_propuesta,
		arquitectura: secuencia.arquitectura_propuesta,
		anotadas: secuencia.anotadas,
		derivadas: secuencia.derivadas
	};
	return `
		insert into public.migracion_secuencias (
			secuencia_id, obra_id, anotacion_id, termino_legado, origen_termino_id, resultado,
			respuestas, correcciones, notas, migrada_por
		)
		values (
			${lit(secuencia.secuencia_id)}::uuid,
			${lit(obraId)}::uuid,
			(select anotacion_id from public.anotaciones_metricas
			 where secuencia_id = ${lit(secuencia.secuencia_id)}::uuid),
			${lit(secuencia.termino_legado)},
			-- El término legado por su identificador, mientras estrofa_tipo_id siga ahí: el rastro
			-- tiene que sobrevivir al día en que esa columna se retire.
			(select estrofa_tipo_id from public.secuencias_metricas
			 where secuencia_id = ${lit(secuencia.secuencia_id)}::uuid),
			${lit(anotacion.resultado)},
			${lit(JSON.stringify(respuestas))}::jsonb,
			${lit(JSON.stringify(suyas))}::jsonb,
			${lit((anotacion.motivos ?? anotacion.avisos ?? []).join(' ') || null)},
			${lit(editorId)}::uuid
		)
		on conflict (secuencia_id) do update set
			anotacion_id = excluded.anotacion_id,
			origen_termino_id = excluded.origen_termino_id,
			resultado = excluded.resultado,
			respuestas = excluded.respuestas,
			correcciones = excluded.correcciones,
			notas = excluded.notas,
			migrada_en = now(),
			migrada_por = excluded.migrada_por;`;
}

// --------------------------------------------------------------------------

const opciones = argumentos(process.argv.slice(2));
if (!opciones.obra) {
	console.error(
		'Falta --obra <slug>. Por ejemplo: npm run migracion:aplicar -- --obra dido-y-eneas --simular'
	);
	process.exit(1);
}

const ruta = opciones.respuestas ?? join(RESPUESTAS, `${opciones.obra}.xlsx`);
if (!existsSync(ruta)) {
	console.error(`No hay Excel devuelto en ${ruta}.`);
	process.exit(1);
}

console.log('Leyendo la base…');
const obras = cargarObras();
const obra = obras.find((o) => o.slug === opciones.obra);
if (!obra) {
	console.error(
		`«${opciones.obra}» no tiene secuencias legadas que migrar. Las que hay: ${obras.map((o) => o.slug).join(', ')}`
	);
	process.exit(1);
}

const { porId: catalogo } = cargarCatalogo();
const metros = query('select metro_id, nombre, silabas from public.metros where activo');

console.log(`Leyendo ${ruta}…`);
const { respuestas, avisos } = await leerRespuestas(ruta);
for (const aviso of avisos) console.warn(`  ${aviso}`);
console.log(`  ${respuestas.size} respuestas con clave.`);

const plan = planificarObra(obra, respuestas, catalogo, metros);
const anotadas = plan.anotaciones.filter((a) => a.resultado !== 'pendiente');
const pendientes = plan.anotaciones.filter((a) => a.resultado === 'pendiente');

mkdirSync(SALIDA, { recursive: true });
const guion = join(SALIDA, `${obra.slug}-${new Date().toISOString().slice(0, 10)}.md`);
writeFileSync(guion, `${guionDe(obra, plan, opciones)}\n`, 'utf-8');

console.log('');
console.log(`  ${plan.correcciones.length} correcciones a las tablas legadas`);
console.log(`  ${anotadas.length} secuencias se anotan`);
console.log(`  ${pendientes.length} secuencias quedan pendientes`);
for (const anotacion of pendientes) {
	for (const motivo of anotacion.motivos) console.log(`      ${motivo}`);
}
for (const pendiente of plan.pendientes) console.log(`      ${pendiente}`);
console.log('');
console.log(`El guion completo está en ${guion}`);

if (anotadas.length === 0) {
	console.error('No hay nada que escribir. Se deja la obra como está.');
	process.exit(1);
}

// --- Antes de escribir: que la obra siga siendo la que el informe leyó.
const editorId = scalar(
	`select editor_asignado from public.obras where obra_id = ${lit(obra.obra_id)}::uuid`
);
if (!editorId) {
	console.error('La obra no tiene editor asignado: sin identidad no se puede anotar.');
	process.exit(1);
}
const yaAnotadas = Number(
	scalar(`select count(*)
		from public.anotaciones_metricas a
		join public.secuencias_metricas s using (secuencia_id)
		where s.obra_id = ${lit(obra.obra_id)}::uuid`)
);
if (yaAnotadas > 0 && plan.correcciones.some((c) => c.tipo === 'renumerar')) {
	console.error(
		`La obra tiene ${yaAnotadas} secuencias ya anotadas y el plan renumera la obra: una renumeración las desplazaría sin que nadie las revise. Hay que resolverlo a mano.`
	);
	process.exit(1);
}

// **La identidad prestada acompaña a toda la transacción.** `set_config(..., true)` vive hasta que
// la transacción acaba, y sin `auth.uid()` la función niega el permiso sobre la obra.
const identidad = `select set_config('request.jwt.claims', json_build_object('sub', ${lit(editorId)})::text, true);`;

if (opciones.simular) {
	if (!opciones.ensayar) {
		console.log('Simulación: no se ha tocado la base.');
		process.exit(0);
	}
	const ensayo = tryQuery(['begin;', ...sentenciasDeLaObra(), 'rollback;'].join('\n'));
	if (ensayo.error) {
		console.error(`El ensayo falló y se deshizo entero: ${ensayo.error}`);
		process.exit(1);
	}
	console.log('Ensayo: la transacción entera se ejecutó y se deshizo. La base queda como estaba.');
	process.exit(0);
}

console.log('Snapshot de las obras antes de tocar nada…');
const snapshot = spawnSync(process.execPath, [join(RAIZ, 'scripts', 'snapshot-obras.mjs')], {
	stdio: 'inherit'
});
if (snapshot.status !== 0) {
	console.error('El snapshot falló: no se migra sin copia.');
	process.exit(1);
}

function sentenciasDeLaObra() {
	return [
		identidad,
		...plan.correcciones.flatMap((correccion) => sentenciasDeCorreccion(obra.obra_id, correccion)),
		...anotadas.map(
			(anotacion) =>
				`select public.guardar_anotacion_metrica(${lit(JSON.stringify(anotacion.datos))}::jsonb);`
		),
		...plan.anotaciones.map((anotacion) =>
			sentenciaDeRastro(obra.obra_id, anotacion, plan.correcciones, editorId)
		)
	];
}

const sentencias = sentenciasDeLaObra();
console.log(`Escribiendo la obra en una transacción (${sentencias.length} sentencias)…`);
const escrita = tryQuery(`begin;\n${sentencias.join('\n')}\ncommit;`);
if (escrita.error) {
	console.error(`La transacción se deshizo entera: ${escrita.error}`);
	console.error('La obra se queda como estaba. El guion dice lo que se intentó escribir.');
	process.exit(1);
}

// **Lo que se dice escrito se cuenta contra la base.**
const escritas = Number(
	scalar(`select count(*)
		from public.anotaciones_metricas a
		join public.secuencias_metricas s using (secuencia_id)
		where s.obra_id = ${lit(obra.obra_id)}::uuid`)
);
const legadas = Number(
	scalar(
		`select count(*) from public.secuencias_metricas where obra_id = ${lit(obra.obra_id)}::uuid`
	)
);
console.log('');
console.log(`  ${escritas} secuencias anotadas de las ${legadas} que tiene la obra.`);
if (escritas !== anotadas.length + yaAnotadas) {
	console.log(`  DESCUADRE: se esperaban ${anotadas.length + yaAnotadas}.`);
}
if (pendientes.length > 0) {
	console.log(
		`  ${pendientes.length} secuencias siguen sin anotación: están en el guion, con su motivo.`
	);
}
console.log('');
console.log('Recalculando los datos públicos…');
query('select public.recompute_all();');
console.log('Hecho. Queda decirle al editor que ya puede revisar su obra en el dashboard.');
