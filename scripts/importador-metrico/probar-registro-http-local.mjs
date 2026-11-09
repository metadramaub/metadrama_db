/**
 * Recorre Auth → PostgREST → RLS del registro de correspondencias contra el Supabase local de
 * ensayo (backups/importador-auth), con cuentas sintéticas. Nunca contra el Supabase compartido.
 */
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';
import { createClient } from '@supabase/supabase-js';

const leer = (p) => JSON.parse(readFileSync(p, 'utf8').replace(/^﻿/, ''));
const config = leer('backups/importador-auth/status.json');
const cuentas = leer('backups/importador-auth/cuentas.json');
if (new URL(config.API_URL).origin !== 'http://127.0.0.1:55421')
	throw new Error('Solo se admite el Supabase local del ensayo.');

const cliente = () =>
	createClient(config.API_URL, config.ANON_KEY, { auth: { persistSession: false, autoRefreshToken: false } });
let pruebas = 0;
const ok = (condicion, nombre) => {
	assert.ok(condicion, nombre);
	pruebas++;
	console.log('OK ' + nombre);
};
async function entrar(indice) {
	const c = cliente();
	const { error } = await c.auth.signInWithPassword({ email: cuentas.usuarios[indice].email, password: cuentas.password });
	if (error) throw error;
	return { c, id: cuentas.usuarios[indice].id };
}
// Cuentas de fixtures-locales.mjs: 0 admin, 2 editor con permiso de importar, 4 editor sin él.
const admin = await entrar(0);
const importador = await entrar(2);
const sinPermiso = await entrar(4);

const literal = 'término de ensayo ' + Date.now();
const fila = (forma) => ({ literal, forma, arquitectura: null, procedencia: { obra: 'Obra sintética', fila: 't01' } });
const tabla = (c) => c.from('correspondencias_importador');

ok(!(await tabla(importador.c).insert(fila('seguidilla'))).error, 'quien importa registra con su sesión');
ok((await tabla(importador.c).insert(fila('seguidilla'))).error?.code === '23505', 'no se registra dos veces');
ok(!(await tabla(importador.c).insert(fila('quintilla'))).error, 'se conserva un registro contradictorio');
const propias = await tabla(importador.c).select('*').eq('literal', literal);
ok(propias.data?.length === 2 && propias.data.every((r) => r.creado_por === importador.id), 'queda quién la señaló');
ok(Boolean((await tabla(importador.c).insert({ ...fila('redondilla'), creado_por: admin.id })).error), 'no se registra en nombre de otro');
ok(Boolean((await tabla(sinPermiso.c).insert(fila('redondilla'))).error), 'sin permiso no registra');
ok((await tabla(sinPermiso.c).select('*').eq('literal', literal)).data?.length === 0, 'sin permiso no consulta');
ok(Boolean((await tabla(cliente()).select('*')).error), 'anónimo rechazado');

await tabla(importador.c).delete().eq('literal', literal);
ok((await tabla(admin.c).select('id').eq('literal', literal)).data?.length === 2, 'quien importa no borra');
const revision = await tabla(admin.c)
	.update({ revisado_por: admin.id, revisado_en: new Date().toISOString() })
	.eq('literal', literal)
	.eq('forma', 'quintilla')
	.select('id');
ok(!revision.error && revision.data?.length === 1, 'admin/IP marca revisada');
ok(Boolean((await tabla(admin.c).update({ forma: 'redondilla' }).eq('literal', literal)).error), 'nadie reescribe el destino');
await tabla(admin.c).delete().eq('literal', literal);
ok((await tabla(admin.c).select('id').eq('literal', literal)).data?.length === 0, 'admin/IP retira y deja limpio');

console.log(JSON.stringify({ pruebas, literal, limite: 'Supabase local con cuentas sintéticas.' }));
