/**
 * Exporta las formas métricas activas como JSON jerárquico y neutral.
 *
 * Uso:
 *   node scripts/variacion-simulacion/exportar.mjs
 *   node scripts/variacion-simulacion/exportar.mjs ruta/de/salida.json
 */

import { writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { query } from '../lib/consulta.mjs';

const DEFAULT_OUTPUT = fileURLToPath(
	new URL('../../docs/dominio-metrico/catalogo-metrico-estructurado.json', import.meta.url)
);
const outputPath = process.argv[2] ?? DEFAULT_OUTPUT;

const rows = query(`
	select
		f.slug,
		e.modelo_version,
		e.revision,
		get_forma_metrica_publica_jerarquica(f.slug) as catalogo
	from formas_metricas f
	cross join catalogo_metrico_estado e
	where f.activo
		and f.tipo_registro = 'forma'
	order by f.slug
`);

if (rows.length === 0) throw new Error('El catálogo vivo no devolvió formas activas.');

const list = (value) => (Array.isArray(value) ? value : []);
const byId = (items, key = 'id') => new Map(list(items).map((item) => [item[key], item]));

function groupBy(items, key) {
	const groups = new Map();
	for (const item of list(items)) {
		const value = item[key];
		if (!groups.has(value)) groups.set(value, []);
		groups.get(value).push(item);
	}
	return groups;
}

function exportForm(slug, data) {
	const forms = list(data.formas);
	const form = forms.find((item) => item.slug === slug) ?? forms[0];
	if (!form) throw new Error(`No se encontró la ficha de la forma «${slug}».`);
	const exportedForm = { ...form };
	delete exportedForm.orden;

	const metricPositions = groupBy(data.posicionesMetricas, 'esquema_metrico_id');
	const metricOptions = groupBy(data.opcionesMetricas, 'esquema_metrico_id');
	const rhymePositions = groupBy(data.posicionesRima, 'esquema_rima_id');
	const resolvedRhymePositions = groupBy(data.posicionesRimaCompletas, 'esquema_rima_id');
	const rhymeLinks = groupBy(data.enlacesRima, 'esquema_rima_id');
	const rhymeRestrictions = groupBy(data.restriccionesRima, 'esquema_rima_id');
	const choiceOptions = groupBy(data.opcionesEleccion, 'grupo_eleccion_id');

	const metricSchemes = groupBy(data.esquemasMetricos, 'arquitectura_id');
	const rhymeSchemes = groupBy(data.esquemasRima, 'arquitectura_id');
	const sections = groupBy(data.secciones, 'arquitectura_id');
	const repetitions = groupBy(data.repeticiones, 'arquitectura_id');
	const varieties = groupBy(data.variedades, 'arquitectura_id');
	const traits = groupBy(data.arquitecturaRasgos, 'arquitectura_id');
	const choiceGroups = groupBy(data.gruposEleccion, 'arquitectura_id');

	const architectures = list(data.arquitecturas).map((architecture) => ({
		...architecture,
		esquemas_metricos: list(metricSchemes.get(architecture.arquitectura_id)).map((scheme) => ({
			...scheme,
			posiciones: list(metricPositions.get(scheme.esquema_metrico_id)),
			opciones: list(metricOptions.get(scheme.esquema_metrico_id))
		})),
		esquemas_rima: list(rhymeSchemes.get(architecture.arquitectura_id)).map((scheme) => ({
			...scheme,
			posiciones: list(rhymePositions.get(scheme.esquema_rima_id)),
			posiciones_resueltas: list(resolvedRhymePositions.get(scheme.esquema_rima_id)),
			enlaces: list(rhymeLinks.get(scheme.esquema_rima_id)),
			restricciones: list(rhymeRestrictions.get(scheme.esquema_rima_id))
		})),
		secciones: list(sections.get(architecture.arquitectura_id)),
		repeticiones: list(repetitions.get(architecture.arquitectura_id)),
		variedades: list(varieties.get(architecture.arquitectura_id)),
		rasgos: list(traits.get(architecture.arquitectura_id)),
		elecciones: list(choiceGroups.get(architecture.arquitectura_id)).map((group) => ({
			...group,
			opciones: list(choiceOptions.get(group.grupo_eleccion_id))
		}))
	}));

	const claimsBySource = groupBy(data.afirmaciones, 'fuente_id');
	const sourceClaims = list(data.fuentes).map((source) => ({
		fuente: source,
		afirmaciones: list(claimsBySource.get(source.fuente_id))
	}));

	const traditions = byId(data.tradiciones, 'tradicion_id');
	const formTraditions = list(data.formasTradiciones).map((relation) => ({
		...relation,
		tradicion: traditions.get(relation.tradicion_id) ?? null
	}));

	return {
		...exportedForm,
		arquitecturas: architectures,
		denominaciones: list(data.denominaciones),
		relaciones: list(data.relaciones),
		tradiciones: formTraditions,
		fuentes: sourceClaims,
		catalogos_referenciados: {
			tipos_rima: list(data.tiposRima),
			rasgos: list(data.rasgos),
			valores_rasgo: list(data.valores),
			formas_referenciadas: list(data.formasReferenciadas),
			arquitecturas_reutilizadas: list(data.arquitecturasReutilizadas)
		}
	};
}

const artifact = {
	esquema_exportacion: 'catalogo-metrico-estructurado/1.0.0',
	procedencia: {
		fuente: 'Catálogo métrico vivo de METADRAMA (Supabase)',
		modelo_version: rows[0].modelo_version,
		revision: rows[0].revision,
		codificacion: 'UTF-8'
	},
	alcance: {
		registros: 'Formas activas',
		filtro_temporal: null,
		nota_temporal:
			'El catálogo abarca más que el Siglo de Oro. Se conservan las cronologías y afirmaciones disponibles sin inferir inclusiones ni exclusiones.'
	},
	formas: rows.map((row) => exportForm(row.slug, row.catalogo ?? {}))
};

writeFileSync(outputPath, `${JSON.stringify(artifact, null, 2)}\n`, 'utf8');
console.log(
	JSON.stringify({
		salida: outputPath,
		formas: artifact.formas.length,
		modelo_version: artifact.procedencia.modelo_version,
		revision: artifact.procedencia.revision
	})
);
