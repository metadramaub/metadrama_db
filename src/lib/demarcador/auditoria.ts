export type PoliticaFamiliaDemarcador = 'familia' | 'variantes';

export type EstrofaFuenteAuditoria = {
	termino_id: string;
	termino: string;
	etiqueta: string | null;
	termino_padre_id: string | null;
	orden: number | null;
	tipo_forma: string | null;
	tipo_rima_id: string | null;
	naturaleza_estrofica_id: string | null;
	tamanio_unidad_estrofica: number | null;
	arte_metrico: string | null;
	patron_especifico: string | null;
};

export type OpcionFuenteAuditoria = {
	termino_id: string;
	termino: string;
	etiqueta: string | null;
	numero_silabas?: number | null;
};

export type EstrofaMetroFuenteAuditoria = {
	estrofa_tipo_id: string;
	metro_id: string;
};

export type ConfiguracionFamiliaAuditoria = {
	familia_id: string;
	politica: PoliticaFamiliaDemarcador;
	revisado_en: string;
};

export type AvisoAuditoria = {
	codigo: 'padre_sin_dato_comun' | 'variantes_indistinguibles' | 'diferenciacion_incompleta';
	mensaje: string;
	terminoIds: string[];
};

export type RasgoAuditoria = {
	clave: 'metros' | 'rima' | 'naturaleza' | 'tamanio' | 'patron';
	etiqueta: string;
	valor: string;
	heredado: boolean;
	demarcador: boolean;
};

export type VarianteAuditoria = {
	id: string;
	nombre: string;
	slug: string;
	rasgos: RasgoAuditoria[];
};

export type FamiliaAuditoria = {
	id: string;
	nombre: string;
	slug: string;
	hijos: VarianteAuditoria[];
	politica: PoliticaFamiliaDemarcador | null;
	revisadoEn: string | null;
	sugerencia: PoliticaFamiliaDemarcador;
	razonSugerencia: string;
	rasgosDiferenciadores: string[];
	avisos: AvisoAuditoria[];
};

export type ResumenAuditoria = {
	familias: number;
	revisadas: number;
	sinRevisar: number;
	conAvisos: number;
	sugeridasComoVariantes: number;
};

export type ResultadoAuditoria = {
	familias: FamiliaAuditoria[];
	resumen: ResumenAuditoria;
};

type ContextoAuditoria = {
	opcionesPorId: Map<string, OpcionFuenteAuditoria>;
	metrosPorEstrofa: Map<string, string[]>;
};

type RasgoComparado = {
	clave: RasgoAuditoria['clave'];
	etiqueta: string;
	valor: string;
	comparable: string;
	heredado: boolean;
};

const SIN_DATO = 'No declarado';
const SIN_TAMANIO_FIJO = 'Sin tamaño fijo declarado';
const SIN_PATRON_FIJO = 'Sin patrón fijo declarado';

function nombreTermino(item: Pick<EstrofaFuenteAuditoria, 'termino' | 'etiqueta'>): string {
	return item.etiqueta?.trim() || item.termino;
}

function etiquetaOpcion(id: string | null, contexto: ContextoAuditoria): string | null {
	if (!id) return null;
	const opcion = contexto.opcionesPorId.get(id);
	return opcion ? opcion.etiqueta?.trim() || opcion.termino : id;
}

function ordenarValores(values: string[]): string[] {
	return [...new Set(values)].sort((a, b) => a.localeCompare(b, 'es'));
}

function construirMetrosPorEstrofa(
	relaciones: EstrofaMetroFuenteAuditoria[],
	opcionesPorId: Map<string, OpcionFuenteAuditoria>
): Map<string, string[]> {
	const result = new Map<string, string[]>();
	for (const relacion of relaciones) {
		const metro = opcionesPorId.get(relacion.metro_id);
		const nombre = metro
			? `${metro.etiqueta?.trim() || metro.termino}${
					typeof metro.numero_silabas === 'number' ? ` (${metro.numero_silabas})` : ''
				}`
			: relacion.metro_id;
		result.set(relacion.estrofa_tipo_id, [...(result.get(relacion.estrofa_tipo_id) ?? []), nombre]);
	}
	for (const [estrofaId, metros] of result) {
		result.set(estrofaId, ordenarValores(metros));
	}
	return result;
}

function resolverRasgos(
	item: EstrofaFuenteAuditoria,
	padre: EstrofaFuenteAuditoria,
	contexto: ContextoAuditoria
): RasgoComparado[] {
	const metrosPropios = contexto.metrosPorEstrofa.get(item.termino_id) ?? [];
	const metrosPadre = contexto.metrosPorEstrofa.get(padre.termino_id) ?? [];
	const metrosHeredados = item.termino_id !== padre.termino_id && metrosPropios.length === 0;
	const metros = metrosHeredados ? metrosPadre : metrosPropios;

	const rimaPropia = etiquetaOpcion(item.tipo_rima_id, contexto);
	const rimaPadre = etiquetaOpcion(padre.tipo_rima_id, contexto);
	const rimaHeredada = item.termino_id !== padre.termino_id && !rimaPropia && Boolean(rimaPadre);
	const rima = rimaPropia || (rimaHeredada ? rimaPadre : null);

	const naturalezaPropia = etiquetaOpcion(item.naturaleza_estrofica_id, contexto);
	const naturalezaPadre = etiquetaOpcion(padre.naturaleza_estrofica_id, contexto);
	const naturalezaHeredada =
		item.termino_id !== padre.termino_id && !naturalezaPropia && Boolean(naturalezaPadre);
	const naturaleza = naturalezaPropia || (naturalezaHeredada ? naturalezaPadre : null);

	return [
		{
			clave: 'metros',
			etiqueta: 'Metro',
			valor: metros.length ? metros.join(', ') : SIN_DATO,
			comparable: metros.join('|') || SIN_DATO,
			heredado: metrosHeredados && metros.length > 0
		},
		{
			clave: 'rima',
			etiqueta: 'Tipo de rima',
			valor: rima ?? SIN_DATO,
			comparable: rima ?? SIN_DATO,
			heredado: rimaHeredada
		},
		{
			clave: 'naturaleza',
			etiqueta: 'Naturaleza',
			valor: naturaleza ?? SIN_DATO,
			comparable: naturaleza ?? SIN_DATO,
			heredado: naturalezaHeredada
		},
		{
			clave: 'tamanio',
			etiqueta: 'Tamaño',
			valor:
				typeof item.tamanio_unidad_estrofica === 'number'
					? `${item.tamanio_unidad_estrofica} versos`
					: SIN_TAMANIO_FIJO,
			comparable:
				typeof item.tamanio_unidad_estrofica === 'number'
					? String(item.tamanio_unidad_estrofica)
					: SIN_TAMANIO_FIJO,
			heredado: false
		},
		{
			clave: 'patron',
			etiqueta: 'Patrón',
			valor: item.patron_especifico?.trim() || SIN_PATRON_FIJO,
			comparable: item.patron_especifico?.trim() || SIN_PATRON_FIJO,
			heredado: false
		}
	];
}

function valoresDirectosCoincidentes(
	hijos: EstrofaFuenteAuditoria[],
	getValue: (hijo: EstrofaFuenteAuditoria) => string | null
): string | null {
	const values = ordenarValores(
		hijos.map(getValue).filter((value): value is string => Boolean(value?.trim()))
	);
	return values.length === 1 && hijos.every((hijo) => Boolean(getValue(hijo)?.trim()))
		? values[0]
		: null;
}

function avisosDeFuente(
	padre: EstrofaFuenteAuditoria,
	hijos: EstrofaFuenteAuditoria[],
	rasgosHijos: Map<string, RasgoComparado[]>,
	contexto: ContextoAuditoria
): AvisoAuditoria[] {
	const avisos: AvisoAuditoria[] = [];
	const comprobacionesComunes = [
		{
			etiqueta: 'tipo de rima',
			padreTieneDato: Boolean(padre.tipo_rima_id),
			getValue: (hijo: EstrofaFuenteAuditoria) => hijo.tipo_rima_id
		},
		{
			etiqueta: 'naturaleza estrófica',
			padreTieneDato: Boolean(padre.naturaleza_estrofica_id),
			getValue: (hijo: EstrofaFuenteAuditoria) => hijo.naturaleza_estrofica_id
		},
		{
			etiqueta: 'tipo de forma',
			padreTieneDato: Boolean(padre.tipo_forma),
			getValue: (hijo: EstrofaFuenteAuditoria) => hijo.tipo_forma
		}
	];

	for (const comprobacion of comprobacionesComunes) {
		const valorComun = valoresDirectosCoincidentes(hijos, comprobacion.getValue);
		if (!comprobacion.padreTieneDato && valorComun) {
			const valorLegible = etiquetaOpcion(valorComun, contexto) ?? valorComun.replaceAll('_', ' ');
			avisos.push({
				codigo: 'padre_sin_dato_comun',
				mensaje: `Todos los hijos declaran ${comprobacion.etiqueta} «${valorLegible}», pero el padre no.`,
				terminoIds: [padre.termino_id]
			});
		}
	}

	const metrosPadre = contexto.metrosPorEstrofa.get(padre.termino_id) ?? [];
	const metrosHijos = hijos.map((hijo) => contexto.metrosPorEstrofa.get(hijo.termino_id) ?? []);
	if (
		metrosPadre.length === 0 &&
		metrosHijos.length > 0 &&
		metrosHijos.every((metros) => metros.length > 0) &&
		new Set(metrosHijos.map((metros) => metros.join('|'))).size === 1
	) {
		avisos.push({
			codigo: 'padre_sin_dato_comun',
			mensaje: `Todos los hijos declaran el mismo metro (${metrosHijos[0].join(', ')}), pero el padre no.`,
			terminoIds: [padre.termino_id]
		});
	}

	const firmas = new Map<string, string[]>();
	for (const hijo of hijos) {
		const firma = (rasgosHijos.get(hijo.termino_id) ?? [])
			.map((rasgo) => `${rasgo.clave}:${rasgo.comparable}`)
			.join('||');
		firmas.set(firma, [...(firmas.get(firma) ?? []), hijo.termino_id]);
	}
	const gruposIndistinguibles = [...firmas.values()].filter((ids) => ids.length > 1);
	if (gruposIndistinguibles.length > 0) {
		const nombresPorId = new Map(hijos.map((hijo) => [hijo.termino_id, nombreTermino(hijo)]));
		for (const ids of gruposIndistinguibles) {
			avisos.push({
				codigo: 'variantes_indistinguibles',
				mensaje: `No hay rasgos estructurados que permitan distinguir: ${ids
					.map((id) => nombresPorId.get(id))
					.join(', ')}.`,
				terminoIds: ids
			});
		}
	}

	for (const clave of ['metros', 'rima', 'naturaleza'] as const) {
		const valores = hijos.map((hijo) => {
			const rasgo = rasgosHijos.get(hijo.termino_id)?.find((item) => item.clave === clave);
			return rasgo?.comparable ?? SIN_DATO;
		});
		if (valores.includes(SIN_DATO) && valores.some((valor) => valor !== SIN_DATO)) {
			const etiqueta =
				clave === 'metros' ? 'metro' : clave === 'rima' ? 'tipo de rima' : 'naturaleza';
			avisos.push({
				codigo: 'diferenciacion_incompleta',
				mensaje: `El ${etiqueta} diferencia algunos hijos, pero falta en otros y tampoco puede heredarse del padre.`,
				terminoIds: hijos
					.filter((hijo) => {
						const rasgo = rasgosHijos.get(hijo.termino_id)?.find((item) => item.clave === clave);
						return rasgo?.comparable === SIN_DATO;
					})
					.map((hijo) => hijo.termino_id)
			});
		}
	}

	return avisos;
}

function construirFamilia(
	padre: EstrofaFuenteAuditoria,
	hijos: EstrofaFuenteAuditoria[],
	configuracion: ConfiguracionFamiliaAuditoria | undefined,
	contexto: ContextoAuditoria
): FamiliaAuditoria {
	const rasgosHijos = new Map(
		hijos.map((hijo) => [hijo.termino_id, resolverRasgos(hijo, padre, contexto)])
	);
	const rasgosDiferenciadores = (
		['metros', 'rima', 'naturaleza', 'tamanio', 'patron'] as const
	).filter((clave) => {
		const values = new Set(
			hijos.map(
				(hijo) =>
					rasgosHijos.get(hijo.termino_id)?.find((rasgo) => rasgo.clave === clave)?.comparable
			)
		);
		return values.size > 1;
	});
	const etiquetasDiferenciadoras: Record<(typeof rasgosDiferenciadores)[number], string> = {
		metros: 'metro',
		rima: 'tipo de rima',
		naturaleza: 'naturaleza estrófica',
		tamanio: 'tamaño de la unidad',
		patron: 'patrón específico'
	};
	const avisos = avisosDeFuente(padre, hijos, rasgosHijos, contexto);
	const sugerencia: PoliticaFamiliaDemarcador =
		rasgosDiferenciadores.length > 0 ? 'variantes' : 'familia';
	const razonSugerencia =
		sugerencia === 'variantes'
			? `Los hijos presentan diferencias declaradas en ${rasgosDiferenciadores
					.map((clave) => etiquetasDiferenciadoras[clave])
					.join(', ')}.`
			: 'Los hijos no presentan diferencias estructuradas suficientes para formular preguntas distintas.';

	return {
		id: padre.termino_id,
		nombre: nombreTermino(padre),
		slug: padre.termino,
		hijos: hijos.map((hijo) => ({
			id: hijo.termino_id,
			nombre: nombreTermino(hijo),
			slug: hijo.termino,
			rasgos: (rasgosHijos.get(hijo.termino_id) ?? []).map((rasgo) => ({
				clave: rasgo.clave,
				etiqueta: rasgo.etiqueta,
				valor: rasgo.valor,
				heredado: rasgo.heredado,
				demarcador: rasgosDiferenciadores.includes(rasgo.clave)
			}))
		})),
		politica: configuracion?.politica ?? null,
		revisadoEn: configuracion?.revisado_en ?? null,
		sugerencia,
		razonSugerencia,
		rasgosDiferenciadores: rasgosDiferenciadores.map((clave) => etiquetasDiferenciadoras[clave]),
		avisos
	};
}

export function construirAuditoriaDemarcador(input: {
	estrofas: EstrofaFuenteAuditoria[];
	opciones: OpcionFuenteAuditoria[];
	relacionesMetro: EstrofaMetroFuenteAuditoria[];
	configuraciones?: ConfiguracionFamiliaAuditoria[];
}): ResultadoAuditoria {
	const opcionesPorId = new Map(input.opciones.map((opcion) => [opcion.termino_id, opcion]));
	const contexto: ContextoAuditoria = {
		opcionesPorId,
		metrosPorEstrofa: construirMetrosPorEstrofa(input.relacionesMetro, opcionesPorId)
	};
	const configuraciones = new Map(
		(input.configuraciones ?? []).map((configuracion) => [configuracion.familia_id, configuracion])
	);
	const hijosPorPadre = new Map<string, EstrofaFuenteAuditoria[]>();
	for (const estrofa of input.estrofas) {
		if (!estrofa.termino_padre_id) continue;
		hijosPorPadre.set(estrofa.termino_padre_id, [
			...(hijosPorPadre.get(estrofa.termino_padre_id) ?? []),
			estrofa
		]);
	}

	const familias = input.estrofas
		.filter((estrofa) => !estrofa.termino_padre_id)
		.map((padre) => {
			const hijos = [...(hijosPorPadre.get(padre.termino_id) ?? [])].sort(
				(a, b) =>
					(a.orden ?? Number.MAX_SAFE_INTEGER) - (b.orden ?? Number.MAX_SAFE_INTEGER) ||
					nombreTermino(a).localeCompare(nombreTermino(b), 'es')
			);
			return hijos.length
				? construirFamilia(padre, hijos, configuraciones.get(padre.termino_id), contexto)
				: null;
		})
		.filter((familia): familia is FamiliaAuditoria => Boolean(familia))
		.sort((a, b) => a.nombre.localeCompare(b.nombre, 'es'));

	return {
		familias,
		resumen: {
			familias: familias.length,
			revisadas: familias.filter((familia) => Boolean(familia.politica)).length,
			sinRevisar: familias.filter((familia) => !familia.politica).length,
			conAvisos: familias.filter((familia) => familia.avisos.length > 0).length,
			sugeridasComoVariantes: familias.filter((familia) => familia.sugerencia === 'variantes')
				.length
		}
	};
}
