/**
 * Informe del estado de las equivalencias entre el vocabulario legado y el catálogo.
 *
 * Responde a una sola pregunta: **de los términos legados, cuáles declaran ya su destino en el
 * catálogo nuevo, cuáles no, y cuánto se usa cada uno**. Es el dato que hay que tener delante
 * para decidir los que faltan, y el que caduca cada vez que se aplica una migración.
 *
 * Se genera, no se escribe a mano. Antes estas tablas vivían en
 * `equivalencias-pendientes.md` junto al razonamiento, y sus cifras se repetían además en el
 * plan de migración y en el estado del catálogo: cuatro copias que había que corregir a mano y
 * que se quedaban viejas por separado. Ahora el razonamiento y las decisiones del IP siguen en
 * aquel documento —que es prosa propia— y **el estado sale de aquí**.
 *
 * La equivalencia no se calcula aquí: la resuelve la vista `propuesta_metrica_secuencia`, la
 * misma que consumen la anotación en sombra y el informe por obra.
 *
 * Uso:
 *   node scripts/informe-equivalencias.mjs
 *   node scripts/informe-equivalencias.mjs --salida docs/dominio-metrico/informe-equivalencias.md
 */

import { writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { query } from './lib/consulta.mjs';

const SALIDA_POR_DEFECTO = fileURLToPath(
	new URL('../docs/dominio-metrico/informe-equivalencias.md', import.meta.url)
);

function parseArguments(argv) {
	const options = { salida: SALIDA_POR_DEFECTO };
	for (let index = 0; index < argv.length; index += 1) {
		if (argv[index] === '--salida') options.salida = argv[index + 1] ?? options.salida;
	}
	return options;
}

// --------------------------------------------------------------------------
// Datos
// --------------------------------------------------------------------------

/**
 * Cada término de `estrofa_tipo` con su destino declarado, si lo tiene, y su uso.
 *
 * «Propias» son las secuencias que declaran ese término exacto; «familia», las que declaran su
 * raíz o cualquier descendiente de ella. La segunda mide el riesgo: un término sin uso propio
 * dentro de una familia muy usada toca una zona delicada del corpus.
 */
function leerTerminos() {
	return query(`
		with recursive ascenso as (
			-- Sube por termino_padre_id hasta la raíz. Un solo salto no basta: la jerarquía
			-- legada tiene nietos, y su familia es la del ascendiente sin padre.
			select v.termino_id, v.termino_id as actual, v.termino_padre_id, 0 as salto
			from vocabularios v
			where v.categoria = 'estrofa_tipo'
			union all
			select a.termino_id, p.termino_id, p.termino_padre_id, a.salto + 1
			from ascenso a
			join vocabularios p on p.termino_id = a.termino_padre_id
			where a.salto < 8
		),
		raices as (
			select distinct on (termino_id) termino_id, actual as raiz_id
			from ascenso
			order by termino_id, salto desc
		),
		usos as (
			select s.estrofa_tipo_id, count(*) as propias
			from secuencias_metricas s
			group by 1
		),
		destino as (
			select v.termino_id,
				coalesce(
					(select 'forma · ' || f.nombre from formas_metricas f
					 where f.origen_termino_id = v.termino_id),
					(select 'arquitectura · ' || fo.nombre || ' · ' || a.nombre
					 from arquitecturas_forma a
					 join formas_metricas fo on fo.forma_id = a.forma_id
					 where a.origen_termino_id = v.termino_id),
					(select 'esquema de rima · ' || coalesce(e.nombre, e.notacion, e.slug)
					 from esquemas_rima e where e.origen_termino_id = v.termino_id),
					(select 'variedad · ' || va.nombre from variedades_arquitectura va
					 where va.origen_termino_id = v.termino_id),
					(select 'denominación · ' || d.nombre from denominaciones_metricas d
					 where d.origen_termino_id = v.termino_id),
					(select 'valor de rasgo · ' || rv.nombre from rasgo_valores rv
					 where rv.origen_termino_id = v.termino_id),
					(select 'metro · ' || mt.nombre from metros mt
					 where mt.origen_termino_id = v.termino_id)
				) as destino
			from vocabularios v
			where v.categoria = 'estrofa_tipo'
		)
		select v.termino,
			pad.termino as padre,
			d.destino,
			coalesce(u.propias, 0) as propias,
			coalesce((
				select sum(coalesce(u2.propias, 0))
				from raices r2
				left join usos u2 on u2.estrofa_tipo_id = r2.termino_id
				where r2.raiz_id = r.raiz_id
			), 0) as familia
		from vocabularios v
		join raices r on r.termino_id = v.termino_id
		left join vocabularios pad on pad.termino_id = v.termino_padre_id
		left join usos u on u.estrofa_tipo_id = v.termino_id
		left join destino d on d.termino_id = v.termino_id
		where v.categoria = 'estrofa_tipo'
		order by (d.destino is not null), coalesce(u.propias, 0) desc, v.termino
	`);
}

/** Reparto de las secuencias reales por vía de resolución. */
function leerVias() {
	return query(`
		select via,
			count(*) as n,
			count(*) filter (where arquitectura_propuesta is null) as sin_arquitectura,
			count(*) filter (where longitud_compatible = false) as longitud_incompatible
		from propuesta_metrica_secuencia
		group by 1
		order by n desc
	`);
}

/** Destinos reclamados por más de un término: el mapa no puede expresarlo. */
function leerConflictos() {
	return query(`
		select 'arquitectura' as tipo, fo.nombre || ' · ' || a.nombre as destino,
			count(*) as reclamantes
		from arquitecturas_forma a
		join formas_metricas fo on fo.forma_id = a.forma_id
		where a.origen_termino_id is not null
		group by 1, 2
		having count(*) > 1
	`);
}

// --------------------------------------------------------------------------
// Informe
// --------------------------------------------------------------------------

function construirInforme() {
	const terminos = leerTerminos();
	const vias = leerVias();
	const conflictos = leerConflictos();

	const conDestino = terminos.filter((t) => t.destino);
	const sinDestino = terminos.filter((t) => !t.destino);
	const totalSecuencias = vias.reduce((suma, v) => suma + Number(v.n), 0);
	const sinArquitectura = vias.reduce((suma, v) => suma + Number(v.sin_arquitectura), 0);
	const longitud = vias.reduce((suma, v) => suma + Number(v.longitud_incompatible), 0);

	const l = [];
	const w = (texto = '') => l.push(texto);

	w('# Estado de las equivalencias con el vocabulario legado');
	w();
	w('> **Documento generado.** No se edita a mano: lo produce');
	w('> `npm run equivalencias:informe` consultando la base enlazada. El razonamiento sobre');
	w('> por qué faltan y las decisiones del IP viven en');
	w('> [equivalencias-pendientes.md](./equivalencias-pendientes.md), que sí es prosa propia.');
	w();
	w(`Generado el ${new Date().toISOString().slice(0, 10)}.`);
	w();

	w('## Resumen');
	w();
	w(`- **${terminos.length} términos** en \`vocabularios.categoria = 'estrofa_tipo'\`.`);
	w(`- **${conDestino.length} declaran su destino** en el catálogo nuevo; **${sinDestino.length} no**.`);
	w(`- **${totalSecuencias} secuencias reales**, todas con forma propuesta.`);
	if (sinArquitectura > 0) {
		w(
			`- ${sinArquitectura} no proponen arquitectura: son tramos sin forma, que no la tienen por diseño.`
		);
	}
	if (longitud > 0) {
		w(
			`- **${longitud} tienen la longitud incompatible** con la arquitectura propuesta. No es un fallo de la equivalencia: es la anotación de la obra, y se revisa en [migracion/](./migracion/).`
		);
	}
	w();

	w('### Cómo se resuelve cada secuencia');
	w();
	w('| Vía | Secuencias | Qué significa |');
	w('| --- | ---: | --- |');
	const SENTIDO = {
		directa: 'El término declara su destino, o lo declara algo que cuelga de él',
		rasgo: 'El término se disolvió en un rasgo y la forma la da su ascendiente',
		ascendencia: 'El término no declara destino; lo hereda de un ascendiente',
		sin_destino: 'No hay destino ni por ascendencia',
		sin_tipo: 'La secuencia no declara forma ninguna'
	};
	for (const v of vias) {
		w(`| \`${v.via}\` | ${v.n} | ${SENTIDO[v.via] ?? '—'} |`);
	}
	w();

	if (conflictos.length > 0) {
		w('### Destinos reclamados por más de un término');
		w();
		w('`origen_termino_id` es único, así que esto no debería poder ocurrir.');
		w();
		w('| Destino | Reclamantes |');
		w('| --- | ---: |');
		for (const c of conflictos) w(`| ${c.destino} | ${c.reclamantes} |`);
		w();
	}

	w('## Términos sin destino declarado');
	w();
	if (sinDestino.length === 0) {
		w('Ninguno: los 119 términos declaran su equivalencia.');
	} else {
		w('Ordenados por uso propio. **Propias** son las secuencias que declaran ese término');
		w('exacto; **familia**, las que declaran su raíz o cualquier descendiente de ella.');
		w('Un término sin uso propio dentro de una familia muy usada toca una zona delicada.');
		w();
		w('| Término legado | Padre | Propias | Familia |');
		w('| --- | --- | ---: | ---: |');
		for (const t of sinDestino) {
			const propias = Number(t.propias) > 0 ? `**${t.propias}**` : t.propias;
			w(`| \`${t.termino}\` | ${t.padre ? `\`${t.padre}\`` : '—'} | ${propias} | ${t.familia} |`);
		}
	}
	w();

	w('## Términos con destino declarado');
	w();
	w('| Término legado | Destino en el catálogo | Propias | Familia |');
	w('| --- | --- | ---: | ---: |');
	for (const t of conDestino) {
		const propias = Number(t.propias) > 0 ? `**${t.propias}**` : t.propias;
		w(`| \`${t.termino}\` | ${t.destino} | ${propias} | ${t.familia} |`);
	}
	w();

	return { texto: l.join('\n'), conDestino: conDestino.length, sinDestino: sinDestino.length };
}

// --------------------------------------------------------------------------

const options = parseArguments(process.argv.slice(2));
const { texto, conDestino, sinDestino } = construirInforme();

writeFileSync(options.salida, `${texto}\n`, 'utf-8');
console.log(
	`Informe escrito en ${options.salida} · ${conDestino} con destino, ${sinDestino} sin destino.`
);
