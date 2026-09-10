import { enunciationType, type EnunciationType } from './enunciation';

export interface PhenomenonSequence {
	secuencia_id: string;
	v_ini: number;
	v_fin: number;
	forma_nombre: string;
	/** Slug crudo de la forma raíz: la clave estable con la que se agrupa y se colorea. */
	forma_slug: string | null;
	caracterizaciones_rango: {
		caracterizacion_rango_id: string;
		tipo_caracterizacion_rango_term: string;
		v_ini: number;
		v_fin: number;
	}[];
	desviaciones: unknown[];
	versos_partidos: boolean | null;
	inaugura_espacio: boolean | null;
	intervencion_personajes_femeninos: string | null;
	intervencion_figuras_donaire: string | null;
	intervencion_personajes_sobrenaturales: string | null;
	evento_sobrenatural: boolean | null;
}

/**
 * Lo que la obra declara que no tiene.
 *
 * Marcar la casilla escribe «sin intervención» en todas las secuencias que callaban, así que sin
 * este dato la vertiente negativa saldría al cien por cien sin decir por qué. Con él, la rama no
 * lista cuarenta secuencias que dicen lo mismo: lo dice una vez.
 */
export interface PhenomenonDeclarations {
	sin_figuras_donaire: boolean;
	sin_personajes_sobrenaturales: boolean;
	sin_eventos_sobrenaturales: boolean;
}

export interface PhenomenonItem {
	id: string;
	secuencia_id: string;
	v_ini: number;
	v_fin: number;
	detalle: string | null;
}

/** Las ocurrencias de una vertiente que caen en una misma forma métrica. */
export interface PhenomenonForm {
	forma: string;
	colorKey: string;
	versos: number;
	items: PhenomenonItem[];
}

/** Una respuesta posible: sí, no, exclusiva, compartida, sin intervención. */
export interface PhenomenonFacet {
	id: string;
	/** Vacío cuando el fenómeno no se responde, solo ocurre —canto, prosa, desviaciones—. */
	label: string;
	positiva: boolean;
	total: number;
	formas: PhenomenonForm[];
}

/** Un tipo dentro del grupo. Solo la intervención de personajes tiene más de uno. */
export interface PhenomenonBranch {
	id: string;
	label: string | null;
	facetas: PhenomenonFacet[];
	/** Secuencias en las que todavía no se ha respondido. */
	pendientes: number;
	/** La obra cerró la pregunta desde arriba: no hay nada que listar. */
	declarada: boolean;
	/** Lo que dice esa declaración, cuando la hay. */
	nota: string | null;
}

export interface PhenomenonGroup {
	id: string;
	label: string;
	/** Secuencias con al menos un caso positivo. Es lo que cuenta el chip. */
	total: number;
	ramas: PhenomenonBranch[];
}

interface FacetSpec {
	id: string;
	label: string;
	positiva: boolean;
}

/** El fenómeno no se responde, se observa: solo hay dónde ocurre. */
const PRESENCIA: FacetSpec[] = [{ id: 'presente', label: '', positiva: true }];

const SI_NO: FacetSpec[] = [
	{ id: 'si', label: 'Sí', positiva: true },
	{ id: 'no', label: 'No', positiva: false }
];

const INTERVENCION: FacetSpec[] = [
	{ id: 'exclusiva', label: 'Exclusiva', positiva: true },
	{ id: 'compartida', label: 'Compartida', positiva: true },
	{ id: 'sin_intervencion', label: 'Sin intervención', positiva: false }
];

interface BranchSpec {
	id: string;
	label: string | null;
	facetas: FacetSpec[];
	declaracion?: keyof PhenomenonDeclarations;
	nota?: string;
}

interface GroupSpec {
	id: string;
	label: string;
	ramas: BranchSpec[];
}

/**
 * Los ocho fenómenos que la ficha sabe localizar.
 *
 * **La intervención de personajes es un solo grupo con tres tipos dentro**, como en el editor:
 * tres chips con nombres que no rimaban entre sí eran tres respuestas del mismo campo separadas
 * por accidente.
 */
const GROUPS: GroupSpec[] = [
	{ id: 'cantado', label: 'Canto', ramas: [{ id: 'cantado', label: null, facetas: PRESENCIA }] },
	{ id: 'prosa', label: 'Prosa', ramas: [{ id: 'prosa', label: null, facetas: PRESENCIA }] },
	{
		id: 'evocacion_metrica',
		label: 'Evocación métrica',
		ramas: [{ id: 'evocacion_metrica', label: null, facetas: PRESENCIA }]
	},
	{
		id: 'desviaciones',
		label: 'Desviaciones',
		ramas: [{ id: 'desviaciones', label: null, facetas: PRESENCIA }]
	},
	{
		id: 'versos_partidos',
		label: 'Versos partidos',
		ramas: [{ id: 'versos_partidos', label: null, facetas: SI_NO }]
	},
	{
		id: 'inaugura_espacio',
		label: 'Cambios de espacio',
		ramas: [{ id: 'inaugura_espacio', label: null, facetas: SI_NO }]
	},
	{
		id: 'intervenciones',
		label: 'Intervención de personajes',
		ramas: [
			{ id: 'personajes_femeninos', label: 'Personajes femeninos', facetas: INTERVENCION },
			{
				id: 'figuras_donaire',
				label: 'Figuras de donaire',
				facetas: INTERVENCION,
				declaracion: 'sin_figuras_donaire',
				nota: 'La obra declara que no tiene figuras de donaire.'
			},
			{
				id: 'personajes_sobrenaturales',
				label: 'Personajes sobrenaturales',
				facetas: INTERVENCION,
				declaracion: 'sin_personajes_sobrenaturales',
				nota: 'La obra declara que no tiene personajes sobrenaturales.'
			}
		]
	},
	{
		id: 'eventos_sobrenaturales',
		label: 'Eventos sobrenaturales',
		ramas: [
			{
				id: 'eventos_sobrenaturales',
				label: null,
				facetas: SI_NO,
				declaracion: 'sin_eventos_sobrenaturales',
				nota: 'La obra declara que en ella no ocurren eventos sobrenaturales.'
			}
		]
	}
];

const SIN_DECLARAR: PhenomenonDeclarations = {
	sin_figuras_donaire: false,
	sin_personajes_sobrenaturales: false,
	sin_eventos_sobrenaturales: false
};

function booleanFacet(value: boolean | null) {
	if (value === true) return 'si';
	if (value === false) return 'no';
	return null;
}

function intervencionFacet(value: string | null) {
	if (value === 'exclusiva' || value === 'compartida' || value === 'sin_intervencion') return value;
	return null;
}

/** En qué vertiente cae esta secuencia para esta rama, o null si nadie la ha respondido. */
function facetOf(branchId: string, sequence: PhenomenonSequence): string | null {
	switch (branchId) {
		case 'versos_partidos':
			return booleanFacet(sequence.versos_partidos);
		case 'inaugura_espacio':
			return booleanFacet(sequence.inaugura_espacio);
		case 'eventos_sobrenaturales':
			return booleanFacet(sequence.evento_sobrenatural);
		case 'personajes_femeninos':
			return intervencionFacet(sequence.intervencion_personajes_femeninos);
		case 'figuras_donaire':
			return intervencionFacet(sequence.intervencion_figuras_donaire);
		case 'personajes_sobrenaturales':
			return intervencionFacet(sequence.intervencion_personajes_sobrenaturales);
		default:
			return null;
	}
}

/**
 * Las ocurrencias de una vertiente, repartidas por la forma en que caen.
 *
 * El orden es por número de secuencias y no alfabético: la pregunta que contesta el índice es en
 * qué formas aparece más el fenómeno.
 */
function groupByForm(entries: { forma: string; colorKey: string; item: PhenomenonItem }[]) {
	const forms = new Map<string, PhenomenonForm>();
	for (const entry of entries) {
		const versos = entry.item.v_fin - entry.item.v_ini + 1;
		const existing = forms.get(entry.colorKey);
		if (existing) {
			existing.items.push(entry.item);
			existing.versos += versos;
			continue;
		}
		forms.set(entry.colorKey, {
			forma: entry.forma,
			colorKey: entry.colorKey,
			versos,
			items: [entry.item]
		});
	}
	return [...forms.values()]
		.map((form) => ({ ...form, items: [...form.items].sort((a, b) => a.v_ini - b.v_ini) }))
		.sort(
			(a, b) =>
				b.items.length - a.items.length ||
				b.versos - a.versos ||
				a.forma.localeCompare(b.forma, 'es')
		);
}

export function buildPhenomenaIndex(
	sequences: PhenomenonSequence[],
	declarations: PhenomenonDeclarations = SIN_DECLARAR
): PhenomenonGroup[] {
	/** Ocurrencias por clave `rama|faceta`. */
	const entries = new Map<string, { forma: string; colorKey: string; item: PhenomenonItem }[]>();
	const pendientes = new Map<string, number>();
	/** Secuencias con algún caso positivo, por grupo: el chip cuenta secuencias, no ocurrencias. */
	const positivas = new Map<string, Set<string>>();

	const add = (
		groupId: string,
		branchId: string,
		facetId: string,
		positiva: boolean,
		sequence: PhenomenonSequence,
		item: PhenomenonItem
	) => {
		const key = `${branchId}|${facetId}`;
		entries.set(key, [
			...(entries.get(key) ?? []),
			{
				forma: sequence.forma_nombre,
				colorKey: sequence.forma_slug ?? sequence.forma_nombre,
				item
			}
		]);
		if (!positiva) return;
		const seen = positivas.get(groupId) ?? new Set<string>();
		seen.add(sequence.secuencia_id);
		positivas.set(groupId, seen);
	};

	for (const sequence of sequences) {
		for (const range of sequence.caracterizaciones_rango ?? []) {
			const type: EnunciationType | null = enunciationType(range.tipo_caracterizacion_rango_term);
			if (!type) continue;
			add(type, type, 'presente', true, sequence, {
				id: range.caracterizacion_rango_id,
				secuencia_id: sequence.secuencia_id,
				v_ini: range.v_ini,
				v_fin: range.v_fin,
				detalle: null
			});
		}

		const desviaciones = sequence.desviaciones ?? [];
		if (desviaciones.length > 0) {
			add('desviaciones', 'desviaciones', 'presente', true, sequence, {
				id: `${sequence.secuencia_id}:desviaciones`,
				secuencia_id: sequence.secuencia_id,
				v_ini: sequence.v_ini,
				v_fin: sequence.v_fin,
				detalle: `${desviaciones.length} ${desviaciones.length === 1 ? 'desviación' : 'desviaciones'}`
			});
		}

		for (const group of GROUPS) {
			for (const branch of group.ramas) {
				if (branch.facetas === PRESENCIA) continue;
				if (branch.declaracion && declarations[branch.declaracion]) continue;
				const facetId = facetOf(branch.id, sequence);
				if (!facetId) {
					pendientes.set(branch.id, (pendientes.get(branch.id) ?? 0) + 1);
					continue;
				}
				const spec = branch.facetas.find((facet) => facet.id === facetId);
				if (!spec) continue;
				add(group.id, branch.id, facetId, spec.positiva, sequence, {
					id: `${sequence.secuencia_id}:${branch.id}`,
					secuencia_id: sequence.secuencia_id,
					v_ini: sequence.v_ini,
					v_fin: sequence.v_fin,
					detalle: null
				});
			}
		}
	}

	return GROUPS.map((group) => {
		const ramas = group.ramas
			.map((branch) => {
				const declarada = Boolean(branch.declaracion && declarations[branch.declaracion]);
				const facetas = declarada
					? []
					: branch.facetas
							.map((spec) => {
								const formas = groupByForm(entries.get(`${branch.id}|${spec.id}`) ?? []);
								return {
									...spec,
									total: formas.reduce((sum, form) => sum + form.items.length, 0),
									formas
								};
							})
							.filter((facet) => facet.total > 0);
				return {
					id: branch.id,
					label: branch.label,
					facetas,
					pendientes: declarada ? 0 : (pendientes.get(branch.id) ?? 0),
					declarada,
					nota: declarada ? (branch.nota ?? null) : null
				};
			})
			.filter((branch) => branch.declarada || branch.facetas.length > 0);

		return {
			id: group.id,
			label: group.label,
			total: positivas.get(group.id)?.size ?? 0,
			ramas
		};
	}).filter((group) => group.ramas.length > 0);
}
