/**
 * Informe de migración por obra: lo que hay que decirle a quien la anotó, y lo que hay que pedirle.
 *
 * Por cada obra con secuencias legadas escribe tres cosas:
 *
 *   docs/dominio-metrico/migracion/<obra>.md                 el informe, para el repositorio
 *   src/lib/content/migracion/<obra>.html                    el mismo informe, para el dashboard
 *   docs/dominio-metrico/migracion/cuestionarios/<obra>.xlsx el Excel que el editor rellena
 *
 * **El informe se lee en el dashboard**, en `/dashboard/migracion/<obra>`, que solo ven admin, el
 * IP y el editor asignado a esa obra; el Excel se manda por correo, que es lo que hay que
 * devolver. Por eso el fragmento HTML se escribe dentro de `src/`: la aplicación lo carga con
 * `import.meta.glob`, como la guía del dashboard, y llega desplegado con el resto del código.
 *
 * Se genera, no se escribe a mano: cada decisión que se toma sobre el catálogo lo cambia, y un
 * documento escrito a mano caducaría el mismo día. Lo que el editor devuelve va a
 * `migracion/respuestas/`, y el aplicador lo lee por las claves que aquí se escriben.
 *
 * **La equivalencia no se calcula aquí.** La resuelve la vista `propuesta_metrica_secuencia`, la
 * misma que consulta el dashboard; el modelo de lo que falta y lo que se pregunta está en
 * `scripts/lib/migracion/`.
 *
 * Uso:
 *   node scripts/informe-migracion-obras.mjs
 *   node scripts/informe-migracion-obras.mjs --salida docs/dominio-metrico/migracion
 */

import { mkdirSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { cargarObras } from './lib/migracion/datos.mjs';
import { escribirExcel } from './lib/migracion/excel.mjs';
import { fragmentoDeInforme } from './lib/migracion/html.mjs';
import { indiceDeObras, informeDeObra } from './lib/migracion/markdown.mjs';

const SALIDA_POR_DEFECTO = fileURLToPath(
	new URL('../docs/dominio-metrico/migracion', import.meta.url)
);
const CONTENIDO = fileURLToPath(new URL('../src/lib/content/migracion', import.meta.url));

function parseArguments(argv) {
	const options = { salida: SALIDA_POR_DEFECTO };
	for (let index = 0; index < argv.length; index += 1) {
		if (argv[index] === '--salida') options.salida = argv[index + 1] ?? options.salida;
	}
	return options;
}

const options = parseArguments(process.argv.slice(2));
const fecha = new Date().toISOString().slice(0, 10);
const cuestionarios = join(options.salida, 'cuestionarios');

mkdirSync(cuestionarios, { recursive: true });
mkdirSync(CONTENIDO, { recursive: true });
// Una obra que deja de tener secuencias legadas no debe dejar su informe atrás mintiendo. Las
// respuestas devueltas viven en otra carpeta y no se tocan.
for (const fichero of readdirSync(options.salida)) {
	if (fichero.endsWith('.md')) rmSync(join(options.salida, fichero));
}
// Lo mismo con los fragmentos: una obra migrada deja de tener informe y su página debe irse con
// ella, no quedarse pidiendo lo que ya se contestó.
for (const fichero of readdirSync(CONTENIDO)) {
	if (fichero.endsWith('.html')) rmSync(join(CONTENIDO, fichero));
}
// Un Excel abierto en Excel está bloqueado en Windows: se avisa y se sigue con los demás.
const bloqueados = new Set();
for (const fichero of readdirSync(cuestionarios)) {
	if (!/\.xlsx$/.test(fichero)) continue;
	try {
		rmSync(join(cuestionarios, fichero));
	} catch (error) {
		if (error.code !== 'EPERM' && error.code !== 'EBUSY') throw error;
		bloqueados.add(fichero);
		console.warn(`  ${fichero} está abierto en otro programa y no se puede reescribir.`);
	}
}

const obras = cargarObras();

for (const obra of obras) {
	const markdown = informeDeObra(obra, fecha);
	writeFileSync(join(options.salida, `${obra.slug}.md`), `${markdown}\n`, 'utf-8');
	writeFileSync(join(CONTENIDO, `${obra.slug}.html`), `${fragmentoDeInforme(markdown)}\n`, 'utf-8');
	if (!bloqueados.has(`${obra.slug}.xlsx`)) {
		await escribirExcel(obra, join(cuestionarios, `${obra.slug}.xlsx`), fecha);
	}

	const decidir = obra.cuestionario.responder.filter((f) => f.tipo === 'decidir').length;
	console.log(
		`  ${obra.titulo.padEnd(38)} ${String(obra.secuencias.length).padStart(3)} secs · ` +
			`${decidir} decidir · ${obra.cuestionario.responder.length - decidir} responder · ` +
			`${obra.cuestionario.confirmar.length} confirmar · ${obra.cuestionario.desviaciones.length} desviaciones`
	);
}

writeFileSync(join(options.salida, 'README.md'), `${indiceDeObras(obras, fecha)}\n`, 'utf-8');

// El índice que lee el dashboard. Lleva el `obra_id` porque quién puede ver un informe **no se
// decide aquí**: la ruta lo comprueba contra la obra en vivo, y el editor asignado puede cambiar
// después de generarlo. Lo demás son las cifras de la portada, para no abrir once fragmentos.
writeFileSync(
	join(CONTENIDO, 'indice.json'),
	`${JSON.stringify(
		{
			generado: fecha,
			obras: obras.map((obra) => ({
				slug: obra.slug,
				obra_id: obra.obra_id,
				titulo: obra.titulo,
				editor: obra.editor,
				excel: `${obra.slug}.xlsx`,
				secuencias: obra.secuencias.length,
				decidir: obra.cuestionario.responder.filter((f) => f.tipo === 'decidir').length,
				responder: obra.cuestionario.responder.filter((f) => f.tipo !== 'decidir').length,
				confirmar: obra.cuestionario.confirmar.length,
				desviaciones: obra.cuestionario.desviaciones.length
			}))
		},
		null,
		'\t'
	)}\n`,
	'utf-8'
);

const total = obras.reduce((n, o) => n + o.secuencias.length, 0);
console.log(
	`${obras.length} informes escritos en ${options.salida} y en ${CONTENIDO} (${total} secuencias legadas)`
);
