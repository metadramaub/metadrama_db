import type { MetricCatalogDomainData, MetricCatalogDomainRow } from '$lib/metrica/catalogo';

export type DisposicionQuebrados = {
	id: string;
	posiciones: number[];
	versos: number;
	base: number;
	etiqueta: string;
};

const etiqueta = (posiciones: number[]) =>
	posiciones.length === 0
		? 'Sin quebrados'
		: posiciones.length === 1
			? `Verso ${posiciones[0]}`
			: `Versos ${posiciones.slice(0, -1).join(', ')} y ${posiciones.at(-1)}`;

/** Lee esquemas completos con roles de base/quebrado; no contiene nombres de formas. */
export function disposicionesDeQuebrados(
	domain: MetricCatalogDomainData,
	arquitecturaId: string | null
): DisposicionQuebrados[] {
	const modelos = domain.metricPatterns
		.filter((p) => p.arquitectura_id === arquitecturaId && p.tipo_secuencia === 'secuencia')
		.sort((a, b) => String(a.created_at ?? '').localeCompare(String(b.created_at ?? '')));
	if (modelos.length < 2) return [];
	const metros = new Map(domain.verseModels.map((m) => [String(m.metro_id), Number(m.silabas)]));
	const resultado: DisposicionQuebrados[] = [];
	for (const modelo of modelos) {
		const id = String(modelo.esquema_metrico_id);
		const roles = domain.metricOptions.filter((o) => o.esquema_metrico_id === id);
		const bases = [
			...new Set(
				roles.filter((o) => o.rol === 'dominante').map((o) => metros.get(String(o.metro_id)))
			)
		];
		const base = bases[0];
		const quebrados = new Set(
			roles.filter((o) => o.rol === 'quebrado').map((o) => String(o.metro_id))
		);
		if (bases.length !== 1 || !base || quebrados.size === 0) continue;
		const porPosicion = new Map<number, MetricCatalogDomainRow[]>();
		for (const p of domain.metricPositions.filter((p) => p.esquema_metrico_id === id)) {
			const posicion = Number(p.posicion);
			porPosicion.set(posicion, [...(porPosicion.get(posicion) ?? []), p]);
		}
		const versos = Math.max(0, ...porPosicion.keys());
		if (!versos || porPosicion.size !== versos) continue;
		let pautas: number[][] = [[]];
		for (let n = 1; n <= versos; n++) {
			const opciones = porPosicion.get(n) ?? [];
			const pleno = opciones.some((p) => metros.get(String(p.metro_id)) === base);
			const corto = opciones.some((p) => quebrados.has(String(p.metro_id)));
			if (!pleno && !corto) {
				pautas = [];
				break;
			}
			pautas = pautas.flatMap((p) => [...(pleno ? [p] : []), ...(corto ? [[...p, n]] : [])]);
		}
		for (const posiciones of pautas) {
			if (resultado.some((r) => r.posiciones.join(',') === posiciones.join(','))) continue;
			resultado.push({
				id: `${id}:${posiciones.join(',')}`,
				posiciones,
				versos,
				base,
				etiqueta: etiqueta(posiciones)
			});
		}
	}
	return resultado.length > 1 ? resultado : [];
}

/** Las opciones del editor llevan esta lectura preparada junto con sus medidas. */
export function disposicionesDeOpciones(options: MetricCatalogDomainRow[]): DisposicionQuebrados[] {
	return (options[0]?.disposiciones_quebrados as DisposicionQuebrados[] | undefined) ?? [];
}

export function disposicionCompatible(
	disposiciones: DisposicionQuebrados[],
	posiciones: number[]
): DisposicionQuebrados | null {
	const candidatas = disposiciones.filter((d) => posiciones.every((n) => d.posiciones.includes(n)));
	return candidatas.find((d) => d.posiciones.length === posiciones.length) ?? candidatas[0] ?? null;
}

/** Solo completa medidas que coinciden en todos los patrones compatibles con lo respondido. */
export function medidasDeLosQuebrados(
	disposiciones: DisposicionQuebrados[],
	elegidas: MetricCatalogDomainRow[]
): (number | null)[] {
	const posiciones = elegidas.map((o) => Number(o.posicion_unidad));
	let candidatas = disposiciones.filter((d) => posiciones.every((n) => d.posiciones.includes(n)));
	if (posiciones.length === 0) {
		const plenos = candidatas.find((d) => d.posiciones.length === 0);
		if (plenos) candidatas = [plenos];
	}
	const versos = Math.max(0, ...disposiciones.map((d) => d.versos));
	return Array.from({ length: versos }, (_, i) => {
		const n = i + 1;
		const respondida = elegidas.find((o) => Number(o.posicion_unidad) === n);
		if (respondida) return Number(respondida.metro_silabas) || null;
		if (!candidatas.length || candidatas.some((d) => d.posiciones.includes(n))) return null;
		const bases = [...new Set(candidatas.map((d) => d.base))];
		return bases.length === 1 ? bases[0] : null;
	});
}
