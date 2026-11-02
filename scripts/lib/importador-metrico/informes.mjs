/** Informes locales: las reglas describen posibilidades, no certifican su presencia en el corpus. */
export const celda = (s) => String(s ?? '—').replaceAll('|', '\\|').replace(/\r?\n/g, ' ');
export function informeSeguimiento(lote, registro) {
	const lineas = ['# Seguimiento de las veinte obras del piloto', '',
		`Guardados contrastados por SELECT en Supabase: ${registro.consultado_en}. No se escribe en la base.`, '',
		'El guardado se acredita por obra_id, no por semejanza de títulos. Sin guardado confirmado no significa extracción incorrecta. La revisión y el motivo son anotaciones humanas, separadas del estado de persistencia.', '',
		'| N.º de foto | Obra | Guardado | Revisión y motivo |', '| --- | --- | --- | --- |'];
	let guardadas = 0;
	for (const obra of lote.obras) {
		const registros = registro.importaciones.filter((i) => i.obra_id === obra.obra_id);
		guardadas += Number(registros.length > 0);
		const guardado = registros.length ? registros.map((i) => `[Guardada ${i.importado_en.slice(0, 10)}](https://versologia.metadrama.org/dashboard/importador/fichas/${i.importacion_id})`).join('; ') : 'Sin guardado confirmado';
		const revision = [obra.revision, obra.observacion, obra.documento ? `[Detalle](../${obra.documento})` : ''].filter(Boolean).map((t) => t.replace(/\.+$/, '')).join('. ');
		lineas.push(`| ${obra.numero} | ${celda(obra.titulo)} | ${guardado} | ${celda(revision)} |`);
	}
	lineas.splice(4, 0, `**${guardadas} guardadas de ${lote.obras.length}.** El resto no tiene guardado confirmado en este registro.`, '');
	lineas.push('', 'Los títulos pendientes se identifican por el número de las fotografías; el rótulo del lote no sustituye a los metadatos bibliográficos. Los ensayos antiguos se conservan: la nueva pasada con el prompt vigente sigue pendiente donde se indica.', '',
		'Fuente editable: `seguimiento-lote.json`. Guardados: `registro-guardados.json`. Regenerar: `npm run importador:informes`. Actualizar primero la consulta remota: `npm run importador:informes -- --actualizar-guardados`.', '');
	return lineas.join('\n');
}

export function informeEquivalencias(catalogo, equivalencias, observaciones, problemas = []) {
	const reglas = equivalencias.reglas;
	const directas = reglas.filter((r) => r.tipo === 'equivalencia_propuesta');
	const candidatas = reglas.filter((r) => r.tipo === 'candidatas_orientativas');
	const paraForma = (lista, slug) => lista.filter((r) => r.candidatas.some((c) => c.forma_slug === slug));
	const ids = (lista) => lista.map((r) => r.id).join(', ') || '—';
	const nombres = new Map(catalogo.formas.map((f) => [f.slug, f.nombre]));
	const sinRegla = catalogo.formas.filter((f) => !paraForma(directas, f.slug).length);
	const l = ['# Equivalencias del importador: documento de revisión', '',
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
	l.push('## Casos particulares pendientes', '', 'Véase [Casos complejos de equivalencias](../casos-complejos-equivalencias.md). Se reproducen debajo para que este documento pueda enviarse por separado.', '');
	return l.join('\n');
}
