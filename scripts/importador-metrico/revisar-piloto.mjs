/**
 * Comprueba el primer lote y produce sus tablas de cotejo. Solo lee archivos locales.
 * No normaliza formas, no aplica particiones y no valida la revisión humana.
 * --comprobar verifica además que los derivados guardados están al día, sin escribirlos.
 * --verificar-fuentes contrasta SHA-256 de los originales en la ubicación local del manifiesto.
 */
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { resolve, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';

const repo = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const root = join(repo, 'docs/importador-metrico/piloto');
const read = (file) => JSON.parse(readFileSync(join(root, file), 'utf8'));
const fuentes = read('fuentes.json');
const equivalencias = read('equivalencias.propuestas.json');
const catalogo = read('catalogo-referencia.json');
const segmentacion = read('segmentacion.propuestas.json');
const refs = [...new Set(fuentes.fotografias.map((foto) => foto.obra_ref))].sort();
const obras = refs.map((ref) => read(`extracciones/${ref}.json`));
const errores = [];
const check = (condition, text) => { if (!condition) errores.push(text); };
const revision = existsSync(join(root, 'revision-humana.json')) ? read('revision-humana.json') : null;
if (revision) {
  check(revision.esquema === 'versologia-revision-transcripcion/0.1' && Boolean(revision.responsable) && Boolean(revision.fecha), 'Registro de revisión humana incompleto');
  check(revision.revisiones.length === refs.length && new Set(revision.revisiones.map((r) => r.obra_ref)).size === refs.length, 'La revisión debe identificar las cuatro extracciones sin duplicados');
  for (const ref of refs) {
    const entry = revision.revisiones.find((r) => r.obra_ref === ref);
    const archivo = `extracciones/${ref}.json`;
    const sha256 = createHash('sha256').update(readFileSync(join(root, archivo))).digest('hex');
    check(entry?.archivo === archivo && entry?.sha256 === sha256 && ['aceptada_sin_correcciones', 'aceptada_con_correccion'].includes(entry?.resultado), `La revisión humana no corresponde a la versión conservada: ${ref}`);
  }
}
const revisado = Boolean(revision);
const entero = (n) => Number.isInteger(n) && n > 0;
const sum = (rows, field) => rows.reduce((total, row) => total + row[field], 0);
const esc = (text) => String(text ?? '—').replaceAll('|', '\\|').replaceAll('\n', ' ');
const table = (headers, rows) => [
  `| ${headers.map(esc).join(' | ')} |`,
  `| ${headers.map(() => '---').join(' | ')} |`,
  ...rows.map((row) => `| ${row.map(esc).join(' | ')} |`)
].join('\n');
const formas = new Map(catalogo.formas.map((forma) => [forma.slug, forma]));
const rasgos = new Set(catalogo.rasgos_consultados.map((rasgo) => rasgo.slug));
const reglas = new Map();
for (const regla of equivalencias.reglas) {
  for (const literal of regla.literales) {
    check(!reglas.has(literal), `Regla duplicada para ${literal}`);
    reglas.set(literal, regla);
  }
  for (const candidata of regla.candidatas) {
    const forma = formas.get(candidata.forma_slug);
    check(Boolean(forma), `Forma candidata inexistente: ${candidata.forma_slug}`);
    if (candidata.arquitectura_slug) check(
      forma?.arquitecturas.some((arq) => arq.slug === candidata.arquitectura_slug),
      `Arquitectura candidata ajena a la forma: ${regla.id}`
    );
  }
  for (const detalle of regla.detalles_fuente) if (detalle.rasgo_slug_propuesto) {
    check(rasgos.has(detalle.rasgo_slug_propuesto), `Rasgo candidato inexistente: ${regla.id}`);
  }
}

// Agrupaciones para contrastar los DOS resúmenes editoriales aportados. No son equivalencias
// con el catálogo ni se usan en perfiles normalizados: «Tercetos» agrupa etiquetas más precisas.
function grupoResumen(literal) {
  if (['redondilla', 'redondillas'].includes(literal)) return 'redondillas';
  if (['quintilla', 'quintillas'].includes(literal)) return 'quintillas';
  if (literal.startsWith('tercetos')) return 'tercetos';
  if (literal.startsWith('endecasílabos sueltos')) return 'sueltos';
  if (['octava real', 'octavas reales'].includes(literal)) return 'octavas';
  return literal;
}

const controles = new Map();
const inventario = new Map();
for (const obra of obras) {
  const ref = obra.obra_ref;
  check(obra.esquema === 'versologia-extraccion/0.1', `${ref}: esquema inesperado`);
  check(obra.estado_revision === 'borrador_ia', `${ref}: este lote inicial debe seguir siendo borrador`);
  check(obra.revision_humana.resultado === 'pendiente' && obra.revision_humana.responsable === null &&
    obra.revision_humana.fecha === null, `${ref}: no atribuir validación humana en este lote`);
  const meta = obra.metadatos;
  check(Boolean(meta?.titulo && meta.autoria && meta.edicion_base && meta.fuente_fecha), `${ref}: metadatos mínimos ausentes`);
  check(entero(meta?.fecha_inicio) && entero(meta?.fecha_fin) && meta.fecha_inicio <= meta.fecha_fin, `${ref}: fechas incoherentes`);
  check(meta?.fuente_id === fuentes.documento_metadatos.id, `${ref}: fuente de metadatos no registrada`);
  const ids = new Set(obra.tramos.map((tramo) => tramo.id));
  check(ids.size === obra.tramos.length, `${ref}: identificadores de tramo repetidos`);
  const jornadas = new Set(obra.jornadas.map((jornada) => jornada.numero));
  check(jornadas.size === obra.jornadas.length, `${ref}: jornadas duplicadas`);
  const notas = new Map(obra.notas.map((nota) => [nota.id, nota]));
  check(notas.size === obra.notas.length, `${ref}: notas duplicadas`);
  let anterior = null;
  for (const tramo of obra.tramos) {
    const label = `${ref}/${tramo.id}`;
    check(jornadas.has(tramo.jornada), `${label}: jornada no registrada`);
    check(entero(tramo.v_ini) && entero(tramo.v_fin) && tramo.v_ini <= tramo.v_fin, `${label}: rango inválido`);
    check(entero(tramo.n_versos_fuente), `${label}: recuento no transcrito`);
    check(tramo.v_fin - tramo.v_ini + 1 === tramo.n_versos_fuente, `${label}: rango y recuento de fuente discrepan`);
    if (anterior) {
      check(anterior.v_fin + 1 === tramo.v_ini, `${label}: hueco o solapamiento`);
      check(tramo.jornada >= anterior.jornada, `${label}: orden de jornadas incoherente`);
    } else check(tramo.v_ini === 1, `${label}: la muestra no empieza en v. 1`);
    anterior = tramo;
    const fuente = fuentes.fotografias.find((foto) => foto.id === tramo.fuente_id);
    check(fuente?.obra_ref === ref, `${label}: foto no registrada para la obra`);
    check(fuente?.pagina_visible === tramo.pagina, `${label}: página no coincide con manifiesto`);
    for (const notaRef of tramo.notas_ref) check(notas.get(notaRef)?.tramos_ref.includes(tramo.id), `${label}: nota sin enlace recíproco`);
    check(typeof tramo.denominacion_literal === 'string' && tramo.denominacion_literal.length > 0, `${label}: denominación ausente`);
    check(reglas.has(tramo.denominacion_literal), `${label}: término aún no inventariado`);
    const entry = inventario.get(tramo.denominacion_literal) ?? { literal: tramo.denominacion_literal, tramos: 0, versos: 0, apariciones: [] };
    entry.tramos += 1;
    entry.versos += tramo.v_fin - tramo.v_ini + 1;
    entry.apariciones.push({obra_ref: ref, tramo_ref: tramo.id, fuente_id: tramo.fuente_id, pagina: tramo.pagina});
    inventario.set(entry.literal, entry);
  }
  for (const nota of obra.notas) {
    check(fuentes.fotografias.some((foto) => foto.id === nota.fuente_id && foto.obra_ref === ref && foto.pagina_visible === nota.pagina), `${ref}/${nota.id}: fuente de nota inválida`);
    for (const tramoRef of nota.tramos_ref) {
      const tramo = obra.tramos.find((row) => row.id === tramoRef);
      check(tramo?.notas_ref.includes(nota.id), `${ref}/${nota.id}: tramo sin enlace recíproco`);
      if (nota.v_ini !== null || nota.v_fin !== null) check(
        entero(nota.v_ini) && entero(nota.v_fin) && nota.v_ini <= nota.v_fin &&
        tramo && nota.v_ini >= tramo.v_ini && nota.v_fin <= tramo.v_fin,
        `${ref}/${nota.id}: localizador de nota fuera de su tramo`
      );
    }
  }
  for (const incidencia of obra.incidencias) {
    check(fuentes.fotografias.some((foto) => foto.id === incidencia.fuente_id && foto.obra_ref === ref), `${ref}: fuente de incidencia inválida`);
    for (const id of incidencia.tramos_ref) check(ids.has(id), `${ref}: incidencia enlaza tramo inexistente ${id}`);
  }
  const total = obra.tramos.reduce((n, row) => n + row.v_fin - row.v_ini + 1, 0);
  const filasResumen = obra.resumen_fuente.map((row) => {
    check(fuentes.fotografias.some((foto) => foto.id === row.fuente_id && foto.obra_ref === ref && foto.pagina_visible === row.pagina), `${ref}: localizador de resumen inválido`);
    check(/^\d+(,\d+)?$/.test(row.porcentaje_literal), `${ref}: porcentaje literal inválido`);
    const conjunto = obra.tramos.filter((tramo) => grupoResumen(tramo.denominacion_literal) === row.denominacion_literal.toLocaleLowerCase('es'));
    const calculado = sum(conjunto, 'n_versos_fuente');
    check(calculado === row.n_versos_fuente, `${ref}: resumen ${row.denominacion_literal} discrepa de los tramos`);
    return [row.denominacion_literal, row.n_versos_fuente, calculado, row.porcentaje_literal, (100 * calculado / total).toFixed(3)];
  });
  if (obra.resumen_fuente.length) check(sum(obra.resumen_fuente, 'n_versos_fuente') === total, `${ref}: total del resumen no coincide`);
  controles.set(ref, {total, filasResumen});
}
for (const propuesta of segmentacion.propuestas) {
  const obra = obras.find((row) => row.obra_ref === propuesta.obra_ref);
  const tramo = obra?.tramos.find((row) => row.id === propuesta.tramo_ref);
  const nota = obra?.notas.find((row) => row.id === propuesta.nota_ref);
  check(Boolean(tramo && nota?.tramos_ref.includes(tramo.id)), 'Partición sin evidencia de fuente');
  const segmentos = propuesta.segmentos;
  check(segmentos[0].v_ini === tramo?.v_ini && segmentos.at(-1).v_fin === tramo?.v_fin, 'Partición cambia los extremos');
  check(segmentos.every((row, i) => entero(row.v_ini) && row.v_fin >= row.v_ini &&
    (!i || segmentos[i-1].v_fin + 1 === row.v_ini)), 'Partición contiene huecos o solapamientos');
  check(segmentos.reduce((n, row) => n + row.v_fin - row.v_ini + 1, 0) === tramo?.n_versos_fuente, 'Partición cambia el número de versos');
}
if (process.argv.includes('--verificar-fuentes')) {
  for (const fuente of [fuentes.documento_metadatos, ...fuentes.fotografias]) {
    const file = join(fuentes.raiz_materiales_local, fuente.ruta_relativa);
    check(existsSync(file), `Original no localizado: ${fuente.ruta_relativa}`);
    if (existsSync(file)) check(createHash('sha256').update(readFileSync(file)).digest('hex') === fuente.sha256, `SHA-256 distinto: ${fuente.ruta_relativa}`);
  }
}
if (errores.length) { console.error(errores.join('\n')); process.exit(1); }

const derivados = new Map();
for (const obra of obras) {
  const control = controles.get(obra.obra_ref);
  const m = obra.metadatos;
  const partes = [
    `# ${m.titulo}: extracción para cotejo`,
    revisado ? '**Transcripción aceptada por el responsable del proyecto. Gold de transcripción; normalización independiente.** [Registro y hashes](../revision-humana.json).' : '**Borrador de IA. Revisión humana pendiente. No es gold ni ficha importada.**',
    `Datos reproducibles: [JSON de extracción](../extracciones/${obra.obra_ref}.json). Formato: [0.1](../formato-v0.1.md).`,
    `Autoría del lote: ${m.autoria}. Género en el DOCX: ${m.genero_literal}. Datación: **${m.fecha_inicio}–${m.fecha_fin}**.`,
    `Edición base, copiada del DOCX: ${m.edicion_base}`,
    `Fuente de datación, copiada del DOCX: ${m.fuente_fecha}`,
    ...m.observaciones.map((text) => `Observación del DOCX: ${text}`),
    '## Fuentes para cotejar',
    table(['ID', 'Archivo original', 'Página visible'], fuentes.fotografias.filter((foto) => foto.obra_ref === obra.obra_ref).map((foto) => [foto.id, foto.ruta_relativa, foto.pagina_visible])),
    'Los originales permanecen en la ubicación externa indicada en [fuentes.json](../fuentes.json); SHA-256 permite identificar la versión. La página desconocida se conserva vacía.',
    '## Jornadas derivadas de los rangos',
    table(['Jornada', 'Encabezamiento literal', 'Inicio', 'Fin', 'Versos calculados'], obra.jornadas.map((jornada) => {
      const rows = obra.tramos.filter((row) => row.jornada === jornada.numero);
      return [jornada.numero, jornada.rotulo_literal, rows[0].v_ini, rows.at(-1).v_fin, sum(rows, 'n_versos_fuente')];
    })),
    '## Filas de la sinopsis',
    table(['ID', 'Jornada', 'Inicio', 'Fin', 'Denominación literal', 'N fuente', 'N cálculo', 'Foto', 'Página', 'Notas'], obra.tramos.map((row) => [row.id, row.jornada, row.v_ini, row.v_fin, row.denominacion_literal, row.n_versos_fuente, row.v_fin-row.v_ini+1, row.fuente_id, row.pagina, row.notas_ref.join(', ')])),
    `Control mecánico: **${obra.tramos.length} filas, ${control.total} versos**, sin huecos ni solapamientos y con todos los recuentos de fila compatibles con sus rangos. Esto no sustituye al cotejo humano.`,
    '## Notas métricas de la fuente',
    ...(obra.notas.length ? obra.notas.map((nota) => `- **${nota.id}**, marca \`${nota.marca}\`, ${nota.fuente_id}, p. ${nota.pagina}, ${nota.tramos_ref.join(', ')}: ${nota.texto_literal}`) : ['No se han transcrito notas métricas en las fotografías aportadas.']),
    '## Resumen impreso y comprobación',
    ...(control.filasResumen.length ? [
      table(['Denominación del resumen', 'Versos impresos', 'Versos reagrupados', '% impreso', '% calculado'], control.filasResumen),
      'La reagrupación se usa solo para controlar el resumen de esta edición, no como identificación del catálogo. Los porcentajes impresos se conservan aunque difieran del redondeo usual o no sumen exactamente 100.'
    ] : ['No hay un resumen global completo transcribible en las fotografías aportadas.']),
    '## Incidencias y revisión pendiente',
    ...obra.incidencias.map((row) => `- ${row.tipo}: ${row.descripcion}`),
    revisado ? '- Cotejo humano aceptado el 22 de octubre de 2026; las correcciones posteriores, su fecha y las versiones previas figuran en revision-humana.json. La extracción conserva su estado de borrador; el registro externo identifica por SHA-256 la versión aceptada.' : '- Cotejar todos los rangos, etiquetas, recuentos, notas, páginas y metadatos; registrar responsable, fecha y correcciones antes de aceptar el gold.',
    ...(obra.obra_ref === 'los-locos-de-valencia' ? ['- [Criterios acordados](../segmentacion.propuestas.json): n01 es desviación de metro; n02 es adición estructural. Se conservan ambos tramos sin partición. Estas decisiones no alteran las filas de la fuente.'] : []),
    '- Las [equivalencias](../equivalencias.propuestas.json) se registran aparte: estancias → Canción está aceptada solo al nivel de forma, con remate declarado; las demás siguen pendientes. No modifican las extracciones literales.'
  ];
  derivados.set(`revision/${obra.obra_ref}.md`, partes.join('\n\n')+'\n');
}
const terminos = [...inventario.values()].sort((a,b) => a.literal.localeCompare(b.literal,'es'));
derivados.set('inventario-terminos.json', JSON.stringify({esquema:'versologia-inventario-terminos/0.1',estado:revisado ? 'derivado_de_transcripciones_aceptadas' : 'derivado_de_borradores_sin_revision_humana',terminos},null,2)+'\n');
derivados.set('inventario-terminos.md', [
  '# Inventario inicial de denominaciones',
  'Generado de las cuatro extracciones. Se conservan variantes literales, sin fusionar formas. Los recuentos describen filas editoriales. Estancias → Canción está aceptada al nivel de forma, con remate declarado; las demás correspondencias siguen pendientes de revisión humana.',
  table(['Denominación literal','Filas','Versos','Regla','Tipo','Destinos o candidatas','Revisión'], terminos.map((t) => {
    const r = reglas.get(t.literal);
    return [t.literal,t.tramos,t.versos,r.id,r.tipo,r.candidatas.map((c) => c.forma_slug+(c.arquitectura_slug ? '/'+c.arquitectura_slug : '')).join('; ') || 'sin candidatas respaldadas',r.aprobacion ? 'aceptada solo al nivel indicado' : 'pendiente'];
  })),
  `Referencia del catálogo: modelo ${catalogo.estado.modelo_version}, revisión ${catalogo.estado.revision}, consulta ${catalogo.fecha_consulta}. Es una consulta acotada, no una exportación completa.`,
  'Las apariciones por obra y fila están en [el JSON del inventario](./inventario-terminos.json); la justificación de cada propuesta, en [equivalencias.propuestas.json](./equivalencias.propuestas.json). Las listas orientativas no son exhaustivas ni equiprobables.'
].join('\n\n')+'\n');
derivados.set('informe-inicial.md', [
  '# Primer lote del piloto del importador',
  revisado ? '**Cuatro transcripciones aceptadas el 22 de octubre de 2026, con correcciones posteriores registradas cuando corresponda.** [Registro de aceptación y hashes](./revision-humana.json). Este ensayo genera archivos locales; no crea importaciones en Supabase.' : '**Cuatro borradores para revisión humana. No hay gold validado ni importación en Supabase.**',
  'Los datos proceden de lectura visual asistida de seis fotografías y de los bloques bibliográficos del DOCX. El prompt 0.1 queda preparado para ensayos posteriores; esta lectura no es una evaluación ciega ni una comparación entre proveedores.',
  table(['Obra','Fechas DOCX','Fotos','Filas fuente','Versos por rangos','Resumen impreso','Cotejo'], obras.map((obra) => [obra.metadatos.titulo,`${obra.metadatos.fecha_inicio}–${obra.metadatos.fecha_fin}`,fuentes.fotografias.filter((foto) => foto.obra_ref === obra.obra_ref).length,obra.tramos.length,controles.get(obra.obra_ref).total,obra.resumen_fuente.length ? 'recuentos compatibles' : 'no aportado completo',`[Abrir tabla](./revision/${obra.obra_ref}.md)`])),
  `En conjunto: **${obras.reduce((n, obra) => n+obra.tramos.length,0)} filas y ${[...controles.values()].reduce((n, c) => n+c.total,0)} versos por rangos**, distribuidos en ${terminos.length} denominaciones literales. Los resúmenes no se suman de nuevo.`,
  '## Qué está comprobado',
  'Se han comprobado parseo y estructura, metadatos mínimos, referencias a fotos y notas, rangos inclusivos, continuidad, recuentos declarados y sumas de los dos resúmenes disponibles. Los términos y arquitecturas propuestos existen en la referencia acotada del catálogo vivo. Estos controles no certifican fidelidad visual ni validez filológica de las propuestas.',
  '## Puntos concretos para revisar',
  '- **El molino:** «letrilla», t20, vv. 2880–2888, 9 versos. Se conserva sin identificación de catálogo ni inferencia de canto. La página de la primera foto no es visible y permanece sin asignar.',
  '- **Matico:** «tercetos», t01 y t09, 272 versos. Terceto y Terceto encadenado son candidatas orientativas, sin selección automática por la longitud.',
  '- **El verdadero amante:** «estancias con pareado final», t02, 67 versos: Canción aceptada como forma, con remate en pareado declarado, sin arquitectura ni patrón de estancias. No se exige cotejar el texto. «Tercetos encadenados con serventesio final», t07 y t12, 170 versos: Terceto encadenado aceptado con remate final de un verso (3+1), sin arquitectura. Se conserva el literal editorial, sin otra forma ni otra secuencia.',
  '- **Los locos de Valencia:** criterio acordado: n01 es desviación de metro en v. 2172; n02 es adición estructural en v. 2666. El tramo t16 conserva 133 versos, de los que 132 forman 33 redondillas; no se parte ni se inventa laguna. Ver [decisiones](./segmentacion.propuestas.json).',
  '- **Porcentajes:** los recuentos de los resúmenes de Matico y El molino coinciden con los tramos. En Matico se conserva 2,5 % para 72 versos en octavas sobre 2812 versos; el cociente es aproximadamente 2,560 %. En El molino los porcentajes impresos suman 100,1 %. No se reescribe la fuente ni se interpreta esto como un error de extracción.',
  '## Archivos y reproducción',
  '- [Formato provisional](./formato-v0.1.md) y [prompt de extracción](../../../prompts/importador-metrico/extraccion-v0.1.md).',
  '- [Fuentes y hashes](./fuentes.json), [inventario de términos](./inventario-terminos.md), [propuestas de equivalencia](./equivalencias.propuestas.json) y [propuesta de segmentación](./segmentacion.propuestas.json).',
  '- [Referencia del catálogo](./catalogo-referencia.json), obtenida con [una consulta SELECT](../../../scripts/importador-metrico/catalogo-piloto.sql). No se utiliza como autoridad la exportación anterior del repositorio.',
  'Desde la raíz del repo: `node scripts/importador-metrico/revisar-piloto.mjs` regenera tablas e inventario; `node scripts/importador-metrico/revisar-piloto.mjs --comprobar --verificar-fuentes` verifica sus contenidos y los originales sin escribir. Solo lee archivos locales y no conecta con Supabase.',
  revisado ? 'El paso siguiente es revisar equivalencias y preparar la capa normalizada, conservando estas transcripciones como referencia. Una extracción fiel puede seguir teniendo identificación parcial.' : 'El paso siguiente es el cotejo humano de las cuatro tablas. Las reglas de equivalencia se revisan después como decisiones independientes; una extracción fiel puede seguir teniendo identificación parcial.'
].join('\n\n')+'\n');

for (const [rel, contenido] of derivados) {
  const file = join(root,rel);
  if (process.argv.includes('--comprobar')) check(existsSync(file) && readFileSync(file,'utf8').replaceAll('\r\n','\n') === contenido, `Derivado desactualizado: ${rel}`);
  else { mkdirSync(dirname(file),{recursive:true}); writeFileSync(file,contenido); }
}
if (errores.length) { console.error(errores.join('\n')); process.exit(1); }
console.log(JSON.stringify({obras:obras.length,fotos:fuentes.fotografias.length,tramos:obras.reduce((n,o)=>n+o.tramos.length,0),versos:[...controles.values()].reduce((n,c)=>n+c.total,0),terminos:terminos.length,derivados:derivados.size,revision_humana:revisado ? 'aceptada' : 'pendiente'},null,2));
