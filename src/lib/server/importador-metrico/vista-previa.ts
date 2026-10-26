/** Adaptador de servidor: ensaya el intercambio existente sin DB, confirmación ni archivos escritos. */
import { createHash } from 'node:crypto';
import { normalizarExtraccion } from '../../../../scripts/lib/importador-metrico/normalizacion.mjs';
import {
	prepararFichaMinima,
	validarFichaMinima,
	resumirFichaMinima,
	serializarCanonico
} from '../../../../scripts/lib/importador-metrico/ficha-minima.mjs';
import catalogoRaw from '../../../../docs/importador-metrico/piloto/catalogo-referencia.json?raw';
import reglasRaw from '../../../../docs/importador-metrico/piloto/equivalencias.propuestas.json?raw';
import bibliografiaRaw from '../../../../docs/importador-metrico/piloto/bibliografia-contraste.json?raw';
import segmentacionRaw from '../../../../docs/importador-metrico/piloto/segmentacion.propuestas.json?raw';
import auditoriaRaw from '../../../../docs/importador-metrico/piloto/auditoria-flujo-2026-10-26.json?raw';
import camposRaw from '../../../../docs/importador-metrico/piloto/auditoria-campos-2026-10-22.json?raw';
import molino from '../../../../docs/importador-metrico/piloto/extracciones/el-molino.json?raw';
import amante from '../../../../docs/importador-metrico/piloto/extracciones/el-verdadero-amante.json?raw';
import donaires from '../../../../docs/importador-metrico/piloto/extracciones/los-donaires-de-matico.json?raw';
import locos from '../../../../docs/importador-metrico/piloto/extracciones/los-locos-de-valencia.json?raw';
import prompt from '../../../../prompts/importador-metrico/extraccion-v0.1.md?raw';
import type {
	FichaMinima,
	MetadatosEditables,
	ResultadoVistaPrevia
} from '$lib/importador-metrico/types';

type Registro = Record<string, unknown>;
const objeto = (v: unknown): Registro =>
	v !== null && typeof v === 'object' && !Array.isArray(v) ? (v as Registro) : {};
const cadena = (v: unknown) => (typeof v === 'string' || typeof v === 'number' ? String(v) : '');
const sha = (v: string) => createHash('sha256').update(v).digest('hex');
const catalogo = JSON.parse(catalogoRaw);
const reglas = JSON.parse(reglasRaw);
const campos = JSON.parse(camposRaw);
const referencia = {
	...catalogo,
	generos: JSON.parse(auditoriaRaw)
		.vocabularios.filter((v: { categoria: string }) => v.categoria === 'genero')
		.map((v: { termino: string }) => v.termino),
	metros: campos.metros_ejemplo.map((m: { slug: string }) => m.slug),
	secciones: [...(catalogo.secciones ?? []), ...campos.secciones_cancion]
};
const pilotos = [molino, amante, donaires, locos].map((entrada) => {
	const datos = JSON.parse(entrada);
	return { id: datos.obra_ref as string, titulo: datos.metadatos.titulo as string, entrada };
});
const huellasPiloto = new Set(pilotos.map((p) => sha(serializarCanonico(JSON.parse(p.entrada)))));

export const metadatosIniciales = (): MetadatosEditables => ({
	titulo: '',
	autor_nombre: '',
	genero: 'comedia_o_tragicomedia',
	edicion_base: '',
	fecha_inicio: '',
	fecha_fin: '',
	fuente_fecha: '',
	fundamento_autoria: ''
});
export function obtenerPilotos() {
	return pilotos.map((p) => ({ ...p }));
}
export function obtenerReferenciaImportador() {
	return {
		prompt,
		reglas_version: reglas.version as string,
		catalogo_revision: catalogo.estado.revision as number,
		fecha_consulta: catalogo.fecha_consulta as string,
		generos: [...referencia.generos] as string[]
	};
}
function leerMetadatos(raw: unknown): MetadatosEditables {
	const m = objeto(raw);
	return {
		titulo: cadena(m.titulo),
		autor_nombre: cadena(m.autor_nombre ?? m.autoria),
		genero: cadena(m.genero) || 'comedia_o_tragicomedia',
		edicion_base: cadena(m.edicion_base),
		fecha_inicio: cadena(m.fecha_inicio),
		fecha_fin: cadena(m.fecha_fin),
		fuente_fecha: cadena(m.fuente_fecha),
		fundamento_autoria: cadena(m.fundamento_autoria)
	};
}
const nombres = new Map<string, string>(
	catalogo.formas.map((f: { slug: string; nombre: string }) => [f.slug, f.nombre])
);
const nombresArquitectura = new Map<string, string>(
	catalogo.formas.flatMap(
		(f: { slug: string; arquitecturas: { slug: string; nombre: string }[] }) =>
			f.arquitecturas.map((a) => [`${f.slug}/${a.slug}`, a.nombre])
	)
);
function nombreDestino(destino: { forma_slug: string; arquitectura_slug: string | null }) {
	const forma = nombres.get(destino.forma_slug) ?? destino.forma_slug;
	if (!destino.arquitectura_slug) return forma;
	const arquitectura =
		nombresArquitectura.get(`${destino.forma_slug}/${destino.arquitectura_slug}`) ??
		destino.arquitectura_slug;
	return `${forma} · ${arquitectura}`;
}

/** Los valores vacíos aportados expresamente sustituyen al original para poder borrar una fuente opcional. */
export function analizarEntrada(
	texto: string,
	cambios: Partial<MetadatosEditables> = {}
): ResultadoVistaPrevia {
	const resultado: ResultadoVistaPrevia = {
		persistido: false,
		confirmacion: null,
		formato: null,
		metadatos: { ...metadatosIniciales(), ...cambios },
		datos: null,
		resumen: null,
		filas: [],
		errores: [],
		avisos: []
	};
	try {
		if (texto.length > 2_000_000) throw new Error('El JSON supera el límite de 2 MB de texto.');
		const limpio = texto.trim().replace(/^```(?:json)?\s*\n([\s\S]*?)\n```$/i, '$1');
		if (!limpio) throw new Error('Pega el JSON de la extracción o carga una obra del piloto.');
		let entrada: Registro;
		try {
			entrada = objeto(JSON.parse(limpio));
		} catch {
			throw new Error('El texto no es JSON válido. Comprueba que has copiado el bloque completo.');
		}
		resultado.formato = cadena(entrada.esquema) || null;
		const minima =
			entrada.esquema === 'versologia-vista-previa-minima/0.1' ? objeto(entrada.datos) : entrada;
		resultado.metadatos = { ...leerMetadatos(minima.metadatos), ...cambios };
		const metadatos = {
			...resultado.metadatos,
			fecha_inicio: Number(resultado.metadatos.fecha_inicio),
			fecha_fin: Number(resultado.metadatos.fecha_fin),
			fuente_fecha: resultado.metadatos.fuente_fecha.trim() || null,
			fundamento_autoria: resultado.metadatos.fundamento_autoria.trim() || null
		};
		let datos: FichaMinima;
		if (entrada.esquema === 'versologia-extraccion/0.1') {
			const esPiloto = huellasPiloto.has(sha(serializarCanonico(entrada)));
			const segmentacion = JSON.parse(segmentacionRaw);
			const decisiones = esPiloto
				? [
						...segmentacion.propuestas.filter(
							(p: Registro) => p.estado === 'resuelta_como_desviacion'
						),
						...segmentacion.observaciones.filter(
							(p: Registro) => p.accion === 'registrar_desviacion_de_metro'
						)
					].map((p: Registro) => ({ ...p, estado: 'acordada', fundamento: p.motivo }))
				: [];
			// Un obra_ref escrito a mano no basta para heredar una decisión particular del piloto.
			const reglasAplicables = {
				...reglas,
				reglas: reglas.reglas.filter((r: Registro) => esPiloto || !r.ambito)
			};
			// El original identifica la fuente y las decisiones particulares. Los metadatos
			// editables se corrigen en una copia antes de validar también la extracción.
			const entradaCorregida = {
				...entrada,
				metadatos: {
					genero_literal: null,
					observaciones: [],
					fuente_id: null,
					...objeto(entrada.metadatos),
					titulo: metadatos.titulo.trim() || null,
					autoria: metadatos.autor_nombre.trim() || null,
					edicion_base: metadatos.edicion_base.trim() || null,
					fecha_inicio: resultado.metadatos.fecha_inicio.trim() ? metadatos.fecha_inicio : null,
					fecha_fin: resultado.metadatos.fecha_fin.trim() ? metadatos.fecha_fin : null,
					fuente_fecha: metadatos.fuente_fecha
				}
			};
			const normalizada = normalizarExtraccion(entradaCorregida, {
				reglas: reglasAplicables,
				catalogo,
				bibliografia: JSON.parse(bibliografiaRaw),
				decisiones
			});
			normalizada.revision_transcripcion = { sha256: sha(limpio) };
			normalizada.entradas_sha256 = {
				'equivalencias.propuestas.json': sha(reglasRaw),
				'catalogo-referencia.json': sha(catalogoRaw),
				'bibliografia-contraste.json': sha(bibliografiaRaw),
				...(esPiloto ? { 'segmentacion.propuestas.json': sha(segmentacionRaw) } : {})
			};
			datos = prepararFichaMinima(normalizada, { genero: metadatos.genero, metadatos });
		} else if (minima.esquema === 'versologia-ficha-minima/0.1') {
			datos = {
				...minima,
				metadatos: { ...objeto(minima.metadatos), ...metadatos }
			} as FichaMinima;
			resultado.avisos.push({
				codigo: 'revisiones_declaradas',
				ruta: 'segmentos',
				mensaje:
					'Las revisiones incluidas en el JSON son declaraciones de ese archivo: esta vista no acredita quién las realizó.'
			});
		} else
			throw new Error(
				'Formato no admitido. Se acepta extracción 0.1, ficha mínima 0.1 o vista previa mínima 0.1.'
			);
		const validacion = validarFichaMinima(datos, { catalogo: referencia });
		resultado.errores.push(...validacion.errores);
		resultado.avisos.push(...validacion.avisos);
		if (validacion.datos && !validacion.errores.length) {
			const ficha = validacion.datos;
			const notasOriginales =
				entrada.esquema === 'versologia-extraccion/0.1' && Array.isArray(entrada.notas)
					? entrada.notas
							.map(objeto)
							.filter((n) => typeof n.id === 'string' && typeof n.texto_literal === 'string')
					: null;
			resultado.datos = ficha;
			resultado.resumen = resumirFichaMinima(ficha);
			resultado.filas = ficha.segmentos.map((s) => ({
				...s,
				...(notasOriginales
					? {
							notas_fuente: notasOriginales
								.filter((n) => s.origen.notas_ref.includes(n.id as string))
								.map((n) => ({ id: n.id as string, texto_literal: n.texto_literal as string }))
						}
					: {}),
				jornada:
					ficha.jornadas.find((j) => s.v_ini >= j.v_ini && s.v_fin <= j.v_fin)?.numero ?? null,
				extension: s.v_fin - s.v_ini + 1,
				estado: s.identificacion_revisada
					? 'revisada'
					: s.propuesta
						? 'propuesta'
						: s.candidatas.length
							? 'candidatas'
							: 'sin_resolver',
				forma_revisada: s.identificacion_revisada
					? (nombres.get(s.identificacion_revisada.forma_slug) ??
						s.identificacion_revisada.forma_slug)
					: null,
				propuesta_nombre: s.propuesta ? nombreDestino(s.propuesta) : null,
				candidatas_nombres: s.candidatas.map(nombreDestino)
			}));
		}
	} catch (error) {
		resultado.errores.push({
			codigo: 'entrada',
			ruta: '',
			mensaje: error instanceof Error ? error.message : 'No se pudo interpretar la entrada.'
		});
	}
	resultado.avisos.push(
		{
			codigo: 'referencia_local',
			ruta: '',
			mensaje: `Ensayo con catálogo local de referencia (revisión ${catalogo.estado.revision}) y reglas ${reglas.version}. No comprueba el catálogo vivo ni crea una ficha.`
		},
		{
			codigo: 'cotejo_pendiente',
			ruta: '',
			mensaje:
				'La vista previa no confirma la extracción, la segmentación ni las equivalencias. Revisa los datos con las fotografías antes de importar.'
		}
	);
	return resultado;
}
