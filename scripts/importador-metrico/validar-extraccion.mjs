/** CLI de solo lectura. El núcleo se puede reutilizar sin terminal ni acceso al sistema. */
import { readFileSync } from 'node:fs';
import { z } from 'zod';
import {
	extraccionSchema,
	validarTextoExtraccion,
	codigoSalida
} from '../lib/importador-metrico/validacion.mjs';

const ayuda = `Valida una extracción JSON sin corregirla ni guardarla.

node scripts/importador-metrico/validar-extraccion.mjs archivo.json [opciones]
node scripts/importador-metrico/validar-extraccion.mjs - --json
node scripts/importador-metrico/validar-extraccion.mjs --esquema

  --fuentes archivo.json       Contrastar IDs, obra y páginas con el manifiesto local
  --resumen-completo          Declarar que el resumen aportado cubre toda la obra
  --rango-esperado inicio:fin Contrastar también los extremos de la extracción
  --json                     Informe estructurado en stdout
  --esquema                  JSON Schema del formato 0.1; no lee entradas
  --ayuda                    Mostrar esta ayuda

Salidas: 0 sin errores/advertencias técnicas (pueden quedar pendientes humanos);
1 formato, referencias o lectura inválidos; 2 discrepancias para cotejo; 64 uso incorrecto.
Sin --rango-esperado no se presume que el primer verso sea 1 ni que esté el final.
No consulta Supabase ni abre las fotografías referenciadas en el manifiesto.
`;

function opcionesDe(args) {
	const parsed = { opciones: {}, json: false, archivo: null };
	for (let i = 0; i < args.length; i += 1) {
		const arg = args[i];
		if (arg === '--json') parsed.json = true;
		else if (arg === '--resumen-completo') parsed.opciones.resumenCompleto = true;
		else if (arg === '--fuentes' || arg === '--rango-esperado') {
			const value = args[++i];
			if (!value || value.startsWith('--')) throw new Error(`Falta el valor de ${arg}`);
			if (arg === '--fuentes') parsed.fuentes = value;
			else {
				if (!/^\d+:\d+$/.test(value)) throw new Error('El rango esperado se escribe inicio:fin');
				const [v_ini, v_fin] = value.split(':').map(Number);
				if (![v_ini, v_fin].every((n) => Number.isSafeInteger(n) && n > 0) || v_ini > v_fin)
					throw new Error('Rango esperado inválido');
				parsed.opciones.rangoEsperado = { v_ini, v_fin };
			}
		} else if (arg !== '-' && arg.startsWith('-')) throw new Error(`Opción desconocida: ${arg}`);
		else if (parsed.archivo !== null) throw new Error('Admite una sola extracción por ejecución');
		else parsed.archivo = arg;
	}
	if (parsed.archivo === null) throw new Error('Falta archivo JSON o - para stdin');
	return parsed;
}

const args = process.argv.slice(2);
if (args.length === 1 && args[0] === '--esquema') {
	console.log(JSON.stringify(z.toJSONSchema(extraccionSchema), null, 2));
} else if (args.length === 1 && args[0] === '--ayuda') {
	console.log(ayuda);
} else {
	let config;
	try {
		config = opcionesDe(args);
	} catch (error) {
		console.error(`${error.message}\n\n${ayuda}`);
		process.exitCode = 64;
	}
	if (config) {
		try {
			const texto = readFileSync(config.archivo === '-' ? 0 : config.archivo, 'utf8');
			if (config.fuentes)
				config.opciones.fuentes = JSON.parse(
					readFileSync(config.fuentes, 'utf8').replace(/^\uFEFF/, '')
				);
			const informe = validarTextoExtraccion(texto, config.opciones);
			if (config.json) console.log(JSON.stringify(informe, null, 2));
			else {
				console.log(
					`Estructura: ${informe.estructura_valida ? 'válida' : 'inválida'}. ${informe.alcance}`
				);
				for (const nivel of ['errores', 'advertencias', 'pendientes', 'informacion']) {
					for (const item of informe[nivel])
						console.log(`[${nivel}] ${item.codigo} · ${item.ruta || '(raíz)'}: ${item.mensaje}`);
				}
				if (informe.datos_calculados)
					console.log(
						`Rangos conocidos: ${informe.datos_calculados.tramos_con_rango_valido}/${informe.datos_calculados.tramos}; unión de versos: ${informe.datos_calculados.versos_union_conocida ?? 'fuera de límite exacto'}.`
					);
			}
			process.exitCode = codigoSalida(informe);
		} catch (error) {
			const mensaje = `No se pudo leer la extracción o su manifiesto: ${error.message}`;
			if (config.json)
				console.log(
					JSON.stringify(
						{
							esquema: 'versologia-validacion-tecnica/0.1',
							estructura_valida: false,
							errores: [{ codigo: 'lectura_invalida', ruta: '', mensaje }],
							advertencias: [],
							pendientes: [],
							informacion: [],
							datos_calculados: null
						},
						null,
						2
					)
				);
			else console.error(mensaje);
			process.exitCode = 1;
		}
	}
}
