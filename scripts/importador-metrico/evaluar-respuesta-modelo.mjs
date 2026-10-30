import { readFileSync, writeFileSync } from 'node:fs';
import { evaluarRespuestaModelo } from '../lib/importador-metrico/evaluacion-modelos.mjs';
const args = process.argv.slice(2);
if (
	args.length !== 6 ||
	args[0] !== '--obra' ||
	args[2] !== '--respuesta' ||
	args[4] !== '--salida'
)
	throw Error(
		'Uso: evaluar-respuesta-modelo.mjs --obra <ref> --respuesta <texto> --salida <informe.json>'
	);
if (
	!['el-molino', 'el-verdadero-amante', 'los-donaires-de-matico', 'los-locos-de-valencia'].includes(
		args[1]
	)
)
	throw Error('Obra sin transcripción aceptada en este lote');
const gold = JSON.parse(
	readFileSync(
		new URL(`../../docs/importador-metrico/piloto/extracciones/${args[1]}.json`, import.meta.url),
		'utf8'
	)
);
const informe = evaluarRespuestaModelo(readFileSync(args[3], 'utf8'), gold);
writeFileSync(args[5], JSON.stringify(informe, null, 2) + '\n');
console.log(
	JSON.stringify({
		json_valido: informe.json_valido,
		estructura_valida: informe.estructura_valida,
		diferencias: informe.diferencias?.length ?? null,
		diferencias_formato: informe.diferencias_formato?.length ?? null,
		lista_para_importar_sin_corregir: informe.lista_para_importar_sin_corregir
	})
);
