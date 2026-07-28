import { createHash } from 'node:crypto';
import {
	generarArtefactoDemarcador,
	type EstrofaFuenteDemarcador,
	type OpcionFuenteDemarcador,
	type PoliticaFuenteDemarcador,
	type RelacionMetroFuenteDemarcador
} from '$lib/demarcador-nuevo/generar';
import type { ArtefactoDemarcadorNuevo } from '$lib/demarcador-nuevo/modelo';

const estrofaSelect =
	'termino_id,termino,etiqueta,definicion,termino_padre_id,orden,tipo_rima_id,naturaleza_estrofica_id,tamanio_unidad_estrofica,patron_especifico,updated_at';

function ordenarPorId<T extends Record<string, unknown>>(rows: T[], key: keyof T): T[] {
	return [...rows].sort((a, b) => String(a[key]).localeCompare(String(b[key])));
}

export function esArtefactoDemarcadorNuevo(value: unknown): value is ArtefactoDemarcadorNuevo {
	if (!value || typeof value !== 'object' || Array.isArray(value)) return false;
	const record = value as Record<string, unknown>;
	return record.esquema === 1 && Array.isArray(record.familias);
}

export async function generarDemarcadorDesdeBaseDeDatos(
	supabase: App.Locals['supabase']
): Promise<{ artefacto: ArtefactoDemarcadorNuevo; huellaFuente: string }> {
	const [estrofasResp, opcionesResp, relacionesResp, politicasResp] = await Promise.all([
		supabase
			.from('vocabularios')
			.select(estrofaSelect)
			.eq('categoria', 'estrofa_tipo')
			.eq('activo', true)
			.order('orden', { ascending: true })
			.order('termino', { ascending: true }),
		supabase
			.from('vocabularios')
			.select('termino_id,termino,etiqueta,numero_silabas,updated_at')
			.in('categoria', ['tipo_rima', 'naturaleza_estrofica', 'metro']),
		supabase.from('estrofa_tipo_metros').select('estrofa_tipo_id,metro_id,updated_at'),
		supabase
			.from('demarcador_familias_config')
			.select('familia_id,politica,updated_at')
			.order('familia_id', { ascending: true })
	]);

	if (estrofasResp.error) {
		throw new Error(`No se pudieron cargar las formas estróficas: ${estrofasResp.error.message}`);
	}
	if (opcionesResp.error) {
		throw new Error(`No se pudieron cargar los rasgos métricos: ${opcionesResp.error.message}`);
	}
	if (relacionesResp.error) {
		throw new Error(`No se pudieron cargar los metros: ${relacionesResp.error.message}`);
	}
	if (politicasResp.error) {
		throw new Error(`No se pudieron cargar las políticas: ${politicasResp.error.message}`);
	}

	const estrofas = (estrofasResp.data ?? []) as EstrofaFuenteDemarcador[];
	const opciones = ordenarPorId(
		(opcionesResp.data ?? []) as OpcionFuenteDemarcador[],
		'termino_id'
	);
	const relacionesMetro = ordenarPorId(
		(relacionesResp.data ?? []) as RelacionMetroFuenteDemarcador[],
		'estrofa_tipo_id'
	);
	const politicas = (politicasResp.data ?? []) as PoliticaFuenteDemarcador[];
	const artefacto = generarArtefactoDemarcador({
		estrofas,
		opciones,
		relacionesMetro,
		politicas
	});
	const huellaFuente = createHash('sha256')
		.update(
			JSON.stringify({
				esquema: artefacto.esquema,
				familias: artefacto.familias
			})
		)
		.digest('hex');

	return { artefacto, huellaFuente };
}
