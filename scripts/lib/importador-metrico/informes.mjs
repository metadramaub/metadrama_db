/** Informes locales: las reglas describen posibilidades, no certifican su presencia en el corpus. */

/** Coincidencia de denominación disponible para revisar, sin ejecutar condiciones ni validar la obra. */
export function reglasPorDenominacion(literal, reglas) {
	const clave = (s) => String(s ?? '').normalize('NFC').replace(/\s+/gu, ' ').trim().toLocaleLowerCase('es');
	return reglas.filter(
		(r) => !r.ambito && !r.nota_contiene && !r.patron && r.literales.some((l) => clave(l) === clave(literal))
	);
}
export const celda = (s) => String(s ?? '—').replaceAll('|', '\\|').replace(/\r?\n/g, ' ');
export function informeSeguimiento(lote, registro) {
	const lineas = ['# Seguimiento de las veinte obras del piloto', '',
		'Generado con `npm run importador:informes`; no editar este informe a mano.', '',
		`Guardados contrastados por SELECT en Supabase: ${registro.consultado_en}. No se escribe en la base.`, '',
		'El guardado se acredita por obra_id, no por semejanza de títulos. Sin guardado confirmado no significa extracción incorrecta. La revisión y el motivo son anotaciones humanas, separadas del estado de persistencia.', '',
		'| N.º de foto | Obra | Guardado | Revisión y motivo |', '| --- | --- | --- | --- |'];
	let guardadas = 0;
	for (const obra of lote.obras) {
		const registros = registro.importaciones.filter((i) => i.obra_id === obra.obra_id);
		guardadas += Number(registros.length > 0);
		const guardado = registros.length ? registros.map((i) => `[Guardada ${i.importado_en.slice(0, 10)}](https://versologia.metadrama.org/dashboard/importador/fichas/${i.importacion_id})`).join('; ') : 'Sin guardado confirmado';
		const revision = [obra.revision, obra.observacion, obra.documento ? `[Detalle](../../historico/revisiones-obras/${obra.documento})` : ''].filter(Boolean).map((t) => t.replace(/\.+$/, '')).join('. ');
		lineas.push(`| ${obra.numero} | ${celda(obra.titulo)} | ${guardado} | ${celda(revision)} |`);
	}
	lineas.splice(4, 0, `**${guardadas} guardadas de ${lote.obras.length}.** El resto no tiene guardado confirmado en este registro.`, '');
	lineas.push('', 'Los títulos pendientes se identifican por el número de las fotografías; el rótulo del lote no sustituye a los metadatos bibliográficos. Los ensayos antiguos se conservan: la nueva pasada con el prompt vigente sigue pendiente donde se indica.', '',
		'Fuentes editables en `evaluacion/referencias/`: `seguimiento-lote.json` y `registro-guardados.json`. Regenerar: `npm run importador:informes`. Actualizar primero la consulta remota: `npm run importador:informes -- --actualizar-guardados`.', '');
	return lineas.join('\n');
}

export function informeEquivalencias(catalogo, equivalencias, observaciones, problemas = [], opciones = {}) {
	const normalizar = (s) => s.toLocaleLowerCase('es').replace(/\s+/g, ' ').trim();
	const ordenadas = observaciones.toSorted((a, b) => a.literal.localeCompare(b.literal, 'es'));
	const enlace = (o) => `[${celda(o.literal)}](#termino-${ordenadas.indexOf(o) + 1})`;
	const reglas = equivalencias.reglas;
	const reglasDe = (o) => o.apariciones
		? reglas.filter((r) => o.apariciones.some((a) => a.regla_id === r.id))
		: reglas.filter((r) => r.literales.some((s) => normalizar(s) === normalizar(o.literal)));
	const porForma = (f) => ordenadas.filter((o) => o.apariciones
		? o.apariciones.some((a) => a.formas.includes(f.slug))
		: reglasDe(o).some((r) => r.candidatas.some((c) => c.forma_slug === f.slug)));
	const encontradas = catalogo.formas.filter((f) => porForma(f).length);
	const noEncontradas = catalogo.formas.filter((f) => !porForma(f).length);
	const sinRegla = catalogo.formas.filter((f) => !reglas.some((r) => r.tipo === 'equivalencia_propuesta' && r.candidatas.some((c) => c.forma_slug === f.slug)));
	const l = ['# Equivalencias del importador: documento de revisión', '',
		'Generado con `npm run importador:informes`; corregir las reglas o decisiones de origen, no este informe.', '',
		`Reglas ${equivalencias.version}; catálogo consultado el ${catalogo.fecha_consulta_formas}.`, '',
		'Para revisar: decisiones pendientes y tabla resumen. La procedencia y los casos complejos permiten comprobar ejemplos; el anexo conserva todas las apariciones y las reglas completas.', '',
		'[Decisiones](#decisiones-pendientes) · [Reglas disponibles](#reglas-disponibles-por-denominación) · [Resumen](#tabla-resumen) · [Procedencia](#procedencia-en-las-obras-del-piloto) · [Casos complejos](#casos-complejos) · [Anexo](#anexo-tecnico-y-documental)', '',
		'## Decisiones pendientes', '',
		'Estas propuestas no modifican las equivalencias hasta que se acuerde el criterio.', '',
		'| Término o caso | Criterio actual | Propuesta | Qué decidir |', '| --- | --- | --- | --- |'];
	for (const d of opciones.decisiones ?? []) l.push(`| ${celda(d.asunto)} | ${celda(d.actual)} | ${celda(d.propuesta)} | ${celda(d.decidir)} |`);
	if (!(opciones.decisiones?.length)) l.push('| — | No se han suministrado decisiones para este informe | — | — |');
	l.push('', '## Reglas disponibles por denominación', '',
		'Esta tabla comprueba la coincidencia literal con reglas generales sin condiciones. No aplica reglas por notas o patrones, ni identifica una obra bloqueada. La revisión de la regla y el bloqueo numérico son independientes. Las reglas aprobadas conservan su aprobación; las otras siguen siendo propuestas.', '',
		'| Denominación observada | Regla disponible | Destino propuesto | Revisión | Preparación de las apariciones |',
		'| --- | --- | --- | --- | --- |');
	for (const o of ordenadas) {
		for (const regla of reglasPorDenominacion(o.literal, reglas)) {
			const destino = regla.candidatas.map((c) => {
				const f = catalogo.formas.find((f) => f.slug === c.forma_slug);
				return (f?.nombre ?? c.forma_slug) + (c.arquitectura_slug ? ' / ' + c.arquitectura_slug : ' / sin arquitectura');
			}).join('; ') || 'Sin resolver';
			const bloqueadas = (o.apariciones ?? []).filter((a) => a.preparacion_bloqueada).map((a) => `${a.obra}, ${a.fila}`);
			const preparacion = bloqueadas.length ? 'Bloqueadas: ' + celda(bloqueadas.join('; ')) : 'Sin bloqueo registrado en estas apariciones';
			l.push(`| ${celda(o.literal)} | ${celda(regla.id)} | ${celda(destino)} | ${regla.aprobacion ? 'Aprobada' : 'Pendiente de revisión'} | ${preparacion} |`);
		}
	}
	l.push('', '## Tabla resumen', '',
		'Formas identificadas o planteadas como candidatas en las entradas disponibles. «Sin especificar» no significa ausencia. La revisión indicada corresponde a las reglas, no a la validación de cada obra.', '',
		'| Forma del catálogo | Términos de las ediciones | Arquitectura identificable | Situación | Ejemplos del piloto |', '| --- | --- | --- | --- | --- |');
	for (const f of encontradas) {
		const obs = porForma(f);
		const relacionadas = [...new Set(obs.flatMap(reglasDe))].filter((r) => r.candidatas.some((c) => c.forma_slug === f.slug));
		const directas = relacionadas.filter((r) => r.tipo === 'equivalencia_propuesta');
		const arquitecturas = [...new Set(directas.flatMap((r) => r.candidatas.filter((c) => c.forma_slug === f.slug).map((c) => f.arquitecturas.find((a) => a.slug === c.arquitectura_slug)?.nombre ?? 'Sin especificar')))];
		const situacion = !directas.length ? 'Solo candidata; sin equivalencia directa' : directas.every((r) => r.aprobacion) ? 'Reglas aprobadas' : directas.some((r) => r.aprobacion) ? 'Reglas parcialmente revisadas' : 'Correspondencias pendientes de revisión';
		const ejemplos = [...new Set(obs.flatMap((o) => o.apariciones?.map((a) => a.obra) ?? o.origenes.map((s) => s.split(', ')[0])))].slice(0, 2);
		const terminos = obs.filter((o, i) => obs.findIndex((otra) => normalizar(otra.literal) === normalizar(o.literal)) === i).map((o) => {
			const identificada = o.apariciones ? o.apariciones.some((a) => a.formas_identificadas?.includes(f.slug)) : reglasDe(o).some((r) => r.tipo === 'equivalencia_propuesta' && r.candidatas.some((c) => c.forma_slug === f.slug));
			return enlace(o) + (identificada ? '' : ' (candidata)');
		});
		l.push(`| ${celda(f.nombre)} | ${terminos.join('; ')} | ${celda(arquitecturas.join('; ') || 'Sin especificar')} | ${situacion} | ${celda(ejemplos.join('; '))} |`);
	}
	l.push('', '### Formas sin identificación ni candidatas en esta preparación', '',
		'Esta lista describe el resultado de la preparación, no la ausencia de esas denominaciones en las fotos. Una obra bloqueada puede contener términos con reglas disponibles, recogidos por separado en la tabla de coincidencias literales. No requiere inventar equivalencias.', '',
		noEncontradas.map((f) => catalogo.formas.filter((otra) => otra.nombre === f.nombre).length > 1 ? `${f.nombre} (${f.slug})` : f.nombre).join('; ') + '.', '',
		`Referencia completa: ${catalogo.formas.length} formas; ${sinRegla.length} sin regla directa de importación. El detalle de cobertura está en el anexo.`, '');
	if (problemas.length) l.push('**Entradas no disponibles o no válidas:**', '', ...problemas.map((p) => `- ${p}`), '');
	l.push('## Procedencia en las obras del piloto', '', 'Uno o dos ejemplos por término. Las notas son transcripciones de ensayo; no se consideran cotejadas por aparecer en este informe. Todas las localizaciones se conservan en el anexo.', '');
	for (const [i, o] of ordenadas.entries()) {
		l.push(`<a id="termino-${i + 1}"></a>`, '', `### ${o.literal}`, '');
		for (const [indice, origen] of o.origenes.slice(0, 2).entries()) {
			l.push(`- ${origen}.`);
			const nota = o.apariciones?.[indice]?.notas?.filter(Boolean).join(' ');
			if (nota) l.push(`  Nota de la edición: ${nota.length > 200 ? nota.slice(0, 200) + '… (texto completo en el anexo)' : nota}`);
		}
		l.push(`- Resultado: ${[...o.resultados].join('; ')}.`, '');
	}
	l.push('## Casos complejos', '', opciones.casos ?? 'Véase [Casos complejos de equivalencias](./casos-complejos-equivalencias.md).', '',
		'## Anexo técnico y documental', '', 'Consulta de detalle: apariciones completas, cobertura de formas y arquitecturas, reglas, condiciones y fundamentos.', '');
	const anexo = anexoEquivalencias(catalogo, equivalencias, observaciones, problemas);
	// Conserva el informe exhaustivo anterior, sin repetir su introducción ni la sección de casos.
	l.push(anexo.slice(anexo.indexOf('## Términos observados')).split('## Casos particulares pendientes')[0].replace(/^### /gm, '#### ').replace(/^## /gm, '### '));
	l.push('### Notas de las apariciones', '');
	for (const o of ordenadas) for (const a of o.apariciones ?? []) if (a.notas?.length) l.push(`- **${celda(o.literal)} · ${a.obra}, ${a.fila} (${a.v_ini}–${a.v_fin}):** ${a.notas.join(' ')}`);
	l.push('', '### Archivos y huellas de las entradas', '', ...(opciones.evidencias ?? []), '');
	return l.join('\n');
}

function anexoEquivalencias(catalogo, equivalencias, observaciones, problemas = []) {
	const reglas = equivalencias.reglas;
	const directas = reglas.filter((r) => r.tipo === 'equivalencia_propuesta');
	const candidatas = reglas.filter((r) => r.tipo === 'candidatas_orientativas');
	const paraForma = (lista, slug) => lista.filter((r) => r.candidatas.some((c) => c.forma_slug === slug));
	const ids = (lista) => lista.map((r) => r.id).join(', ') || '—';
	const nombres = new Map(catalogo.formas.map((f) => [f.slug, f.nombre]));
	const sinRegla = catalogo.formas.filter((f) => !paraForma(directas, f.slug).length);
	const l = ['# Equivalencias del importador: documento de revisión', '',
		'Generado con `npm run importador:informes`; corregir las reglas o decisiones de origen, no este informe.', '',
		`Reglas ${equivalencias.version}; catálogo de formas consultado el ${catalogo.fecha_consulta_formas}.`, '',
		'Este informe se genera, no se edita. Las decisiones se anotan en las reglas o en los casos complejos y después se regenera. No es una medición de la cobertura de todo el corpus ni una aprobación automática.', '',
		`**${catalogo.formas.length} formas; ${sinRegla.length} sin regla directa de importación.** Una candidata no equivale a una identificación; una regla disponible no demuestra que la forma haya aparecido en el lote. Una forma identificada sin arquitectura sigue siendo un dato válido al nivel de forma.`, '',
		'## Términos observados en las extracciones disponibles', '',
		'Se conservan los literales de la edición. Una sola entrada seleccionada por obra; son ensayos, no nuevos golds. Las decisiones manuales posteriores del importador no cambian estas transcripciones. Los términos sin resolver requieren revisión; la ausencia de una forma en las pruebas no exige inventar su equivalencia.', '',
		'| Literal | Obras y filas de origen | Resultado con las reglas actuales |', '| --- | --- | --- |'];
	for (const o of observaciones.toSorted((a, b) => a.literal.localeCompare(b.literal, 'es'))) {
		l.push(`| ${celda(o.literal)} | ${celda(o.origenes.join('; '))} | ${celda([...o.resultados].join('; '))} |`);
	}
	if (problemas.length) l.push('', '**Entradas no disponibles o no válidas para este informe:**', '', ...problemas.map((p) => `- ${p}`));
	l.push('', '## Cobertura de todas las formas del catálogo', '',
		'«Sin regla directa» incluye formas que solo tienen candidatas. No significa que esas formas no existan en las ediciones; solo que el importador aún no dispone de una correspondencia directa.', '',
		'| Forma | Reglas directas | Solo como candidata |', '| --- | --- | --- |');
	for (const f of catalogo.formas) l.push(`| ${celda(f.nombre)} | ${celda(ids(paraForma(directas, f.slug)))} | ${celda(ids(paraForma(candidatas, f.slug)))} |`);
	l.push('', '## Arquitecturas', '', 'Se indican solo reglas que seleccionan explícitamente la arquitectura. Una regla que identifica la forma no completa sus arquitecturas por defecto.', '',
		'| Forma | Arquitectura | Reglas directas |', '| --- | --- | --- |');
	for (const f of catalogo.formas) for (const a of f.arquitecturas) {
		l.push(`| ${celda(f.nombre)} | ${celda(a.nombre)} | ${celda(ids(directas.filter((r) => r.candidatas.some((c) => c.forma_slug === f.slug && c.arquitectura_slug === a.slug))))} |`);
	}
	l.push('', '## Reglas que revisar y datos adicionales que producen', '', 'El estado de aprobación se refiere a la equivalencia, no a la revisión de cada obra.', '');
	for (const r of reglas) {
		l.push(`### ${r.id}`, '', `Literales: ${r.literales.map((s) => `«${s}»`).join('; ') || 'Reconocimiento por patrón'}.`, '',
			`Resultado: ${r.tipo === 'equivalencia_propuesta' ? 'identificación directa' : r.tipo === 'candidatas_orientativas' ? 'candidatas, sin elegir' : 'sin resolver'}. ${r.candidatas.map((c) => `${nombres.get(c.forma_slug) ?? c.forma_slug}${c.arquitectura_slug ? ` / ${c.arquitectura_slug}` : ' / sin arquitectura'}`).join('; ')}.`, '',
			`Revisión de la regla: ${r.aprobacion ? `aprobada (${r.aprobacion.fecha})` : 'pendiente'}. Ámbito: ${r.ambito?.obras?.join(', ') ?? 'general'}.`, '',
			r.fundamento, '',
			...(r.nota_contiene?.length ? [`Condición: una nota enlazada debe contener ${r.nota_contiene.map((t) => `«${t}»`).join(' y ')}.`, ''] : []),
			...(r.patron ? [`Patrón de reconocimiento: ${r.patron}.`, ''] : []),
			...(r.division ? [`División aplicada por esta regla: ${r.division}.`, ''] : []),
			`Datos adicionales: ${r.detalles_fuente?.length ? JSON.stringify(r.detalles_fuente) : 'ninguno'}.`, '');
	}
	l.push('## Casos particulares pendientes', '', 'Véase [Casos complejos de equivalencias](./casos-complejos-equivalencias.md). Se reproducen debajo para que este documento pueda enviarse por separado.', '');
	return l.join('\n');
}
