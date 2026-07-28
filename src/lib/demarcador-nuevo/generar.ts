import type {
	ArtefactoDemarcadorNuevo,
	CandidatoDemarcadorNuevo,
	FamiliaDemarcadorNuevo,
	PoliticaFamilia,
	RasgosCandidatoDemarcador,
	ValorCatalogado
} from './modelo';

export type EstrofaFuenteDemarcador = {
	termino_id: string;
	termino: string;
	etiqueta: string | null;
	definicion: string | null;
	termino_padre_id: string | null;
	orden: number | null;
	tipo_rima_id: string | null;
	naturaleza_estrofica_id: string | null;
	tamanio_unidad_estrofica: number | null;
	patron_especifico: string | null;
	updated_at: string;
};

export type OpcionFuenteDemarcador = {
	termino_id: string;
	termino: string;
	etiqueta: string | null;
	numero_silabas: number | null;
	updated_at?: string;
};

export type RelacionMetroFuenteDemarcador = {
	estrofa_tipo_id: string;
	metro_id: string;
	updated_at?: string;
};

export type PoliticaFuenteDemarcador = {
	familia_id: string;
	politica: PoliticaFamilia;
	updated_at: string;
};

export class PoliticasDemarcadorPendientesError extends Error {
	constructor(public readonly familias: Array<{ id: string; etiqueta: string }>) {
		super(`Faltan políticas para ${familias.length} familias.`);
		this.name = 'PoliticasDemarcadorPendientesError';
	}
}

function etiquetaDe(item: { termino: string; etiqueta: string | null }): string {
	return item.etiqueta?.trim() || item.termino;
}

function valorCatalogado(
	id: string | null,
	opcionesPorId: Map<string, OpcionFuenteDemarcador>
): ValorCatalogado | null {
	if (!id) return null;
	const opcion = opcionesPorId.get(id);
	if (!opcion) return { clave: id, etiqueta: id };
	return {
		clave: opcion.termino,
		etiqueta: etiquetaDe(opcion)
	};
}

function construirMetros(
	relaciones: RelacionMetroFuenteDemarcador[],
	opcionesPorId: Map<string, OpcionFuenteDemarcador>
): Map<string, ValorCatalogado[]> {
	const result = new Map<string, ValorCatalogado[]>();
	for (const relacion of relaciones) {
		const metro = opcionesPorId.get(relacion.metro_id);
		if (!metro) continue;
		const clave =
			typeof metro.numero_silabas === 'number' ? String(metro.numero_silabas) : metro.termino;
		const etiqueta =
			typeof metro.numero_silabas === 'number'
				? `${metro.numero_silabas} sílabas`
				: etiquetaDe(metro);
		result.set(relacion.estrofa_tipo_id, [
			...(result.get(relacion.estrofa_tipo_id) ?? []),
			{ clave, etiqueta }
		]);
	}
	for (const [estrofaId, metros] of result) {
		result.set(
			estrofaId,
			[...new Map(metros.map((metro) => [metro.clave, metro])).values()].sort((a, b) =>
				a.clave.localeCompare(b.clave, 'es', { numeric: true })
			)
		);
	}
	return result;
}

function rasgosDe(
	item: EstrofaFuenteDemarcador,
	raiz: EstrofaFuenteDemarcador,
	metrosPorEstrofa: Map<string, ValorCatalogado[]>,
	opcionesPorId: Map<string, OpcionFuenteDemarcador>
): RasgosCandidatoDemarcador {
	const metrosPropios = metrosPorEstrofa.get(item.termino_id) ?? [];
	const metrosRaiz = metrosPorEstrofa.get(raiz.termino_id) ?? [];
	const esRaiz = item.termino_id === raiz.termino_id;

	return {
		metros: metrosPropios.length > 0 || esRaiz ? metrosPropios : metrosRaiz,
		rima:
			valorCatalogado(item.tipo_rima_id, opcionesPorId) ??
			(esRaiz ? null : valorCatalogado(raiz.tipo_rima_id, opcionesPorId)),
		naturaleza:
			valorCatalogado(item.naturaleza_estrofica_id, opcionesPorId) ??
			(esRaiz ? null : valorCatalogado(raiz.naturaleza_estrofica_id, opcionesPorId)),
		// Tamaño y patrón no se heredan: null puede expresar que no existe un valor fijo.
		tamanio: item.tamanio_unidad_estrofica,
		patron: item.patron_especifico?.trim() || null,
		patronEtiqueta: item.patron_especifico?.trim() || null
	};
}

function candidatoDe(
	item: EstrofaFuenteDemarcador,
	raiz: EstrofaFuenteDemarcador,
	metrosPorEstrofa: Map<string, ValorCatalogado[]>,
	opcionesPorId: Map<string, OpcionFuenteDemarcador>
): CandidatoDemarcadorNuevo {
	return {
		id: item.termino_id,
		slug: item.termino,
		etiqueta: etiquetaDe(item),
		definicion: item.definicion?.trim() || null,
		familiaId: raiz.termino_id,
		familiaSlug: raiz.termino,
		familiaEtiqueta: etiquetaDe(raiz),
		esFamilia: item.termino_id === raiz.termino_id,
		rasgos: rasgosDe(item, raiz, metrosPorEstrofa, opcionesPorId)
	};
}

function maxFecha(values: Array<string | null | undefined>): string | null {
	const fechas = values
		.filter((value): value is string => Boolean(value))
		.map((value) => new Date(value))
		.filter((value) => !Number.isNaN(value.getTime()))
		.sort((a, b) => b.getTime() - a.getTime());
	return fechas[0]?.toISOString() ?? null;
}

export function generarArtefactoDemarcador(input: {
	estrofas: EstrofaFuenteDemarcador[];
	opciones: OpcionFuenteDemarcador[];
	relacionesMetro: RelacionMetroFuenteDemarcador[];
	politicas: PoliticaFuenteDemarcador[];
	generadoEn?: string;
}): ArtefactoDemarcadorNuevo {
	const opcionesPorId = new Map(input.opciones.map((opcion) => [opcion.termino_id, opcion]));
	const metrosPorEstrofa = construirMetros(input.relacionesMetro, opcionesPorId);
	const politicasPorFamilia = new Map(
		input.politicas.map((politica) => [politica.familia_id, politica.politica])
	);
	const hijosPorPadre = new Map<string, EstrofaFuenteDemarcador[]>();

	for (const estrofa of input.estrofas) {
		if (!estrofa.termino_padre_id) continue;
		hijosPorPadre.set(estrofa.termino_padre_id, [
			...(hijosPorPadre.get(estrofa.termino_padre_id) ?? []),
			estrofa
		]);
	}

	const raices = input.estrofas.filter((estrofa) => !estrofa.termino_padre_id);
	const pendientes = raices
		.filter((raiz) => (hijosPorPadre.get(raiz.termino_id) ?? []).length > 0)
		.filter((raiz) => !politicasPorFamilia.has(raiz.termino_id))
		.map((raiz) => ({ id: raiz.termino_id, etiqueta: etiquetaDe(raiz) }));

	if (pendientes.length > 0) {
		throw new PoliticasDemarcadorPendientesError(pendientes);
	}

	const familias = raices
		.map((raiz): FamiliaDemarcadorNuevo => {
			const hijos = [...(hijosPorPadre.get(raiz.termino_id) ?? [])].sort(
				(a, b) =>
					(a.orden ?? Number.MAX_SAFE_INTEGER) - (b.orden ?? Number.MAX_SAFE_INTEGER) ||
					etiquetaDe(a).localeCompare(etiquetaDe(b), 'es')
			);
			const politica = hijos.length
				? (politicasPorFamilia.get(raiz.termino_id) as PoliticaFamilia)
				: 'familia';
			return {
				id: raiz.termino_id,
				slug: raiz.termino,
				etiqueta: etiquetaDe(raiz),
				politica,
				raiz: candidatoDe(raiz, raiz, metrosPorEstrofa, opcionesPorId),
				variantes: hijos.map((hijo) => candidatoDe(hijo, raiz, metrosPorEstrofa, opcionesPorId))
			};
		})
		.sort((a, b) => a.etiqueta.localeCompare(b.etiqueta, 'es'));

	return {
		esquema: 1,
		generadoEn: input.generadoEn ?? new Date().toISOString(),
		fuenteActualizadaEn: maxFecha([
			...input.estrofas.map((estrofa) => estrofa.updated_at),
			...input.opciones.map((opcion) => opcion.updated_at),
			...input.relacionesMetro.map((relacion) => relacion.updated_at),
			...input.politicas.map((politica) => politica.updated_at)
		]),
		familias,
		estadisticas: {
			familias: familias.length,
			familiasConVariantes: familias.filter(
				(familia) => familia.politica === 'variantes' && familia.variantes.length > 0
			).length,
			variantesDemarcables: familias
				.filter((familia) => familia.politica === 'variantes')
				.reduce((total, familia) => total + familia.variantes.length, 0)
		}
	};
}
