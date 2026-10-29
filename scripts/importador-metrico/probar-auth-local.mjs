/** Ensayo HTTP real de Auth → JWT → PostgREST → RLS/RPC. Solo loopback, datos sintéticos. */
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';
import { createClient } from '@supabase/supabase-js';
const read = (p) => JSON.parse(readFileSync(p, 'utf8').replace(/^\uFEFF/, ''));
const config = read('backups/importador-auth/status.json');
const cuentas = read('backups/importador-auth/cuentas.json');
if (new URL(config.API_URL).origin !== 'http://127.0.0.1:55421')
	throw Error('Este ensayo solo acepta el Supabase local del importador');
const cliente = () =>
	createClient(config.API_URL, config.ANON_KEY, {
		auth: { persistSession: false, autoRefreshToken: false }
	});
let n = 0;
function ok(cond, mensaje) {
	assert.ok(cond, mensaje);
	console.log('OK ' + mensaje);
	n++;
}
const clientes = [];
for (const [i, u] of cuentas.usuarios.entries()) {
	const c = cliente();
	const r = await c.auth.signInWithPassword({ email: u.email, password: cuentas.password });
	ok(!r.error && r.data.user.id === u.id, `inicio de sesión real de cuenta sintética ${i}`);
	const cap = await c.rpc('capacidades_importador_metrico');
	ok(
		!cap.error && cap.data.puede_importar === [0, 1, 2, 3].includes(i),
		`capacidad correcta para cuenta ${i}`
	);
	clientes.push(c);
}
const denegada = await clientes[4].rpc('listar_fichas_basicas');
ok(denegada.error?.code === '42501', 'editor sin permiso no lista básicas por HTTP');
const inactiva = await clientes[5].rpc('listar_fichas_basicas');
ok(inactiva.error?.code === '42501', 'sesión Auth válida pero perfil inactivo no lista básicas');
const piloto = read('docs/importador-metrico/piloto/preparadas/el-verdadero-amante.json').datos;
const entrada = read('docs/importador-metrico/piloto/extracciones/el-verdadero-amante.json');
const peticion = {
	p_peticion: '30000000-0000-4000-8000-000000000001',
	p_autor: '00000000-0000-4000-8000-000000000100',
	p_datos: piloto,
	p_entrada_original: entrada,
	p_coincidencias_revisadas: []
};
const a = await clientes[2].rpc('guardar_ficha_minima', peticion);
ok(
	!a.error && Boolean(a.data?.importacion_id),
	'guardado real de una básica con JWT de importador'
);
const b = await clientes[2].rpc('guardar_ficha_minima', peticion);
ok(
	!b.error && b.data.importacion_id === a.data.importacion_id && b.data.repetida,
	'reintento HTTP conserva la identidad'
);
const copia = await clientes[3].rpc('consultar_importacion_metrica', {
	p_importacion: a.data.importacion_id
});
assert.deepEqual(copia.data?.datos_confirmados, piloto);
ok(
	!copia.error && copia.data.importado_por === 'Persona de prueba 2',
	'otro importador consulta íntegra la copia y su responsable'
);
const ajena = await clientes[4].rpc('consultar_importacion_metrica', {
	p_importacion: a.data.importacion_id
});
ok(!ajena.error && ajena.data === null, 'editor sin permiso no obtiene la copia ajena');
const publico = await cliente().from('obras').select('obra_id').eq('obra_id', a.data.obra_id);
ok(!publico.error && publico.data.length === 0, 'anónimo no ve la obra básica');
const corpus = await clientes[2]
	.from('artefactos_publicos')
	.select('clave')
	.eq('tipo', 'corpus_comparativas');
ok(
	!corpus.error && corpus.data.length === 0,
	'importar no concede lectura de comparativas privadas'
);
const cambio = await clientes[0]
	.from('obras')
	.update({ titulo: 'Cambio directo prohibido' })
	.eq('obra_id', a.data.obra_id)
	.select('obra_id');
ok(!cambio.error && cambio.data.length === 0, 'ni el admin altera la básica por escritura directa');
const retirar = await clientes[0].rpc('establecer_permiso_importacion', {
	p_editor: cuentas.usuarios[2].id,
	p_permitir: false
});
ok(!retirar.error, 'admin puede retirar la capacidad individual');
try {
	const sinPermiso = await clientes[2].rpc('guardar_ficha_minima', peticion);
	ok(sinPermiso.error?.code === '42501', 'retirar el permiso bloquea también un JWT emitido antes');
} finally {
	const restaurar = await clientes[0].rpc('establecer_permiso_importacion', {
		p_editor: cuentas.usuarios[2].id,
		p_permitir: true
	});
	assert.equal(restaurar.error, null);
}
console.log(
	`${n} comprobaciones HTTP con Auth local real; sin usuarios ni acceso al Supabase compartido.`
);
