/** Restaura la copia previa, importa cuatro casos y genera archivos internos. Nunca usa Supabase. */
import { spawnSync } from 'node:child_process';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { randomUUID, createHash } from 'node:crypto';
import { resolve, join, relative, isAbsolute } from 'node:path';
import assert from 'node:assert/strict';
import {
	seleccionarAportacion,
	precomputarAportacion,
	precomputarReferente,
	huella,
	VERSION_CALCULO
} from '../lib/analitica/aportaciones.mjs';

const args = process.argv.slice(2);
if (args.length !== 4 || args[0] !== '--copia' || args[2] !== '--salida')
	throw Error(
		'Uso: ensayar-precomputacion.mjs --copia <carpeta con schema.sql,data.sql,contexto.json> --salida <backups/...>'
	);
const copia = resolve(args[1]),
	salida = resolve(args[3]);
const relativa = relative(resolve('backups'), salida);
if (!relativa || relativa.startsWith('..') || isAbsolute(relativa))
	throw Error('La salida privada debe quedar dentro de backups/');
mkdirSync(salida, { recursive: true });
const read = (n) => readFileSync(new URL(n, import.meta.url), 'utf8');
const json = (n) => JSON.parse(read(`../../docs/importador-metrico/piloto/${n}`));
const lit = (s) => "'" + String(s).replaceAll("'", "''") + "'";
const contenedor = 'versologia-importador-pruebas';
const db = 'analitica_ensayo_' + randomUUID().replaceAll('-', '');
function docker(args, input) {
	const r = spawnSync('docker', args, { input, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
	if (r.status !== 0) {
		writeFileSync(join(salida, 'ultimo-error.txt'), r.stderr || r.error?.message || 'Error Docker');
		throw Error('Falló el ensayo local; diagnóstico privado en ultimo-error.txt');
	}
	return r.stdout;
}
const config = JSON.parse(docker(['inspect', contenedor]))[0];
if (
	config.HostConfig.NetworkMode !== 'none' ||
	Object.keys(config.HostConfig.PortBindings ?? {}).length
)
	throw Error('Contenedor sin aislamiento: se exige red none y ningún puerto');
const sql = (s, database = db) =>
	docker(
		[
			'exec',
			'-i',
			contenedor,
			'psql',
			'-X',
			'-q',
			'-At',
			'-U',
			'postgres',
			'-d',
			database,
			'-v',
			'ON_ERROR_STOP=1'
		],
		s
	);
const consulta = (s) => JSON.parse(sql(s).trim());
const refs = [
	'el-molino',
	'el-verdadero-amante',
	'los-donaires-de-matico',
	'los-locos-de-valencia'
];
const huellasEntradas = {};
const cargar = (archivo) => {
	const s = readFileSync(archivo, 'utf8');
	huellasEntradas[archivo] = createHash('sha256').update(s).digest('hex');
	return s;
};
sql(`create database ${db} template template0;`, 'postgres');
try {
	const contexto = JSON.parse(cargar(join(copia, 'contexto.json')));
	if (contexto.importador_instalado || !contexto.prosa_registrada)
		throw Error('Este ensayo espera la copia previa al importador y posterior a la prosa');
	sql(`create schema auth; create schema extensions;
create extension "uuid-ossp" with schema extensions; create extension pgcrypto with schema extensions;
create table auth.users(id uuid primary key);
create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid; $$;
grant usage on schema auth,extensions to anon,authenticated,service_role;
${cargar(join(copia, 'schema.sql'))}`);
	sql(
		`insert into auth.users(id) values ${contexto.auth_ids.map((id) => `(${lit(id)})`).join(',')};`
	);
	sql(cargar(join(copia, 'data.sql')));
	sql(cargar(resolve('supabase/migrations/20261029180000_importador_fichas_basicas.sql')));
	const huellasOriginales = () =>
		consulta(`select jsonb_build_object(
 'obras',md5((select jsonb_agg(to_jsonb(o) order by obra_id)::text from public.obras o where tipo_ficha='completa')),
 'artefactos',md5((select jsonb_agg(to_jsonb(a) order by clave)::text from public.artefactos_publicos a)));`);
	const antes = huellasOriginales();
	const actor = consulta(
		`select to_jsonb(e.user_id) from public.editores e join public.vocabularios v on v.termino_id=e.role where v.termino='admin' and coalesce(e.activo,true) order by e.user_id limit 1;`
	);
	const autor = consulta(
		`select to_jsonb(autor_id) from public.autores where nombre_completo='Lope de Vega';`
	);
	for (const ref of refs) {
		const datos = JSON.parse(
			cargar(resolve(`docs/importador-metrico/piloto/preparadas/${ref}.json`))
		).datos;
		const original = JSON.parse(
			cargar(resolve(`docs/importador-metrico/piloto/extracciones/${ref}.json`))
		);
		sql(`begin; select set_config('request.jwt.claim.sub',${lit(actor)},true); set local role authenticated;
select public.guardar_ficha_minima(${lit(randomUUID())},${lit(autor)},${lit(JSON.stringify(datos))}::jsonb,${lit(JSON.stringify(original))}::jsonb); commit;`);
	}
	const extractor = cargar(resolve('scripts/analitica/extraer-aportaciones-local.sql'));
	cargar(resolve('scripts/lib/analitica/aportaciones.mjs'));
	cargar(resolve('scripts/lib/analitica/datos-comparables.mjs'));
	cargar(resolve('scripts/analitica/ensayar-precomputacion.mjs'));
	const extraer = () => consulta(extractor);
	const entrada = extraer();
	const aportaciones = entrada.registros
		.map((r) => seleccionarAportacion(r, entrada.referencias))
		.filter(Boolean);
	assert.equal(new Set(aportaciones.map((a) => a.obra_id)).size, aportaciones.length);
	const calcular = () => ({
		'fuentes-extraidas.json': entrada,
		'aportaciones.json': aportaciones,
		'perfiles-obras.json': aportaciones.map((a) => precomputarAportacion(a, entrada.catalogo)),
		'referente-lope.json': precomputarReferente(aportaciones, entrada.catalogo, { autor_id: autor })
	});
	const documentos = calcular();
	for (const p of documentos['perfiles-obras.json']) {
		assert.deepEqual(
			p.medidas?.datos_adicionales.incidencias,
			[],
			'Hay datos adicionales que el adaptador no ha traducido'
		);
		for (const c of p.medidas.datos_adicionales.cobertura)
			assert.equal(
				c.secuencias_con_dato + c.ausencias_comprobadas + c.sin_dato,
				c.denominador_secuencias
			);
	}
	const perfilesAnteriores =
		consulta(`select jsonb_object_agg(o.obra_id,public.perfil_formas_rango(o.obra_id,1,2147483647))
from public.obras o join public.vocabularios v on v.termino_id=o.estado where o.tipo_ficha='completa' and v.termino='publicado';`);
	let detalladasCotejadas = 0;
	for (const p of documentos['perfiles-obras.json'].filter(
		(p) => p.tipo === 'detallada' && p.valida
	)) {
		assert.deepEqual(
			Object.fromEntries(p.medidas.perfil_formas.map((f) => [f.forma_slug, f.versos])),
			perfilesAnteriores[p.obra_id],
			'El perfil de formas detallado difiere del productor vigente'
		);
		detalladasCotejadas++;
	}
	assert.deepEqual(calcular(), documentos, 'El cálculo debe ser determinista');
	assert.deepEqual(extraer(), entrada, 'El extractor no debe alterar la fuente');
	assert.deepEqual(huellasOriginales(), antes, 'El ensayo alteró obras o artefactos originales');
	const basicas = documentos['perfiles-obras.json'].filter((p) => p.tipo === 'basica');
	assert.equal(basicas.length, 4);
	for (const p of basicas) {
		assert.equal(p.valida, true, JSON.stringify(p.incidencias));
		const ref = aportaciones.find((a) => a.obra_id === p.obra_id).metadatos.titulo;
		const esperado = refs
			.map((r) => json(`preparadas/${r}.json`))
			.find((d) => d.datos.metadatos.titulo === ref).resumen;
		assert.equal(p.medidas.extension, esperado.extension);
		assert.equal(p.medidas.cobertura_formas.pendientes, esperado.forma_pendiente);
		assert.deepEqual(
			p.medidas.perfil_formas.map((f) => ({ forma_slug: f.forma_slug, versos: f.versos })),
			esperado.perfil_formas.map((f) => ({ forma_slug: f.forma_slug, versos: f.versos }))
		);
		assert.equal(p.medidas.segmentacion.n_secuencias.valor, esperado.bloques);
	}
	const informe = {
		esquema: VERSION_CALCULO,
		entorno: 'docker_aislado',
		escrituras_remotas: false,
		detalladas: documentos['perfiles-obras.json'].filter((p) => p.tipo === 'detallada').length,
		detalladas_cotejadas_con_productor_vigente: detalladasCotejadas,
		detalladas_con_incidencias: documentos['perfiles-obras.json'].filter(
			(p) => p.tipo === 'detallada' && p.incidencias.length
		).length,
		secuencias_detalladas_sin_v2: aportaciones
			.filter((a) => a.tipo === 'detallada')
			.reduce((n, a) => n + a.secuencias.filter((s) => s.n_anotaciones === 0).length, 0),
		basicas: basicas.map((p) => ({
			titulo: p.metadatos.titulo,
			extension: p.medidas.extension,
			pendientes: p.medidas.cobertura_formas.pendientes,
			filas: p.medidas.segmentacion.filas_origen,
			segmentacion_confirmada: p.medidas.segmentacion.confirmada,
			datos_adicionales: p.medidas.datos_adicionales.valores.map((v) => ({
				dimension: v.dimension,
				propiedad: v.propiedad,
				valor: v.valor,
				forma_slug: v.forma_slug,
				arquitectura_slug: v.arquitectura_slug,
				metro_observado: v.metro_observado,
				secuencias: v.secuencias_con_evidencia,
				extension_documentada: v.extension_documentada
			}))
		})),
		datos_adicionales_sin_incidencias: true,
		fuentes_previas_intactas: true,
		artefactos_previos_intactos: true,
		determinista: true
	};
	const archivos = Object.entries(documentos).map(([archivo, datos]) => {
		const texto = JSON.stringify(datos, null, 2) + '\n';
		writeFileSync(join(salida, archivo), texto);
		return {
			archivo,
			permiso: 'interno',
			sha256_json_canonico: huella(datos),
			sha256_archivo: createHash('sha256').update(texto).digest('hex')
		};
	});
	writeFileSync(join(salida, 'informe.json'), JSON.stringify(informe, null, 2) + '\n');
	writeFileSync(
		join(salida, 'manifiesto.json'),
		JSON.stringify(
			{
				esquema: VERSION_CALCULO,
				permiso: 'interno',
				estado: 'ensayo_no_publicado',
				seleccion: 'todas_las_detalladas_publicadas_y_basicas_seleccionadas',
				entrada_sha256: huella(entrada),
				huellas_entradas: huellasEntradas,
				documentos: archivos
			},
			null,
			2
		) + '\n'
	);
	console.log(JSON.stringify(informe, null, 2));
} finally {
	// Nombre creado en este proceso; nunca apunta al Supabase ni a una DB de trabajo existente.
	sql(`drop database ${db} with (force);`, 'postgres');
}
