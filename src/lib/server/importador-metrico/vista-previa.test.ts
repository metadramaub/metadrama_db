import { describe, expect, it } from 'vitest';
import { createHash } from 'node:crypto';
import type { FichaMinima } from '$lib/importador-metrico/types';
import { analizarEntrada, obtenerPilotos, obtenerReferenciaImportador, vistaDeFichaGuardada } from './vista-previa';
import preparada from '../../../../docs/importador-metrico/piloto/preparadas/el-verdadero-amante.json';

describe('vista previa del importador sin persistencia', () => {
	it('permite corregir y borrar la ejecución declarada sin modificar el original; se conserva al reabrir', () => {
		const raw = JSON.parse(obtenerPilotos()[0].entrada);
		raw.procedencia = { ...raw.procedencia, generador: 'ChatGPT', modelo: 'Modelo declarado', modo: 'Instant', plan: null, parametros: null };
		const texto = JSON.stringify(raw);
		const leida = analizarEntrada(texto);
		expect(leida.errores).toEqual([]);
		expect(leida.metadatos.ia_modelo).toBe('Modelo declarado');
		expect(leida.metadatos.ia_modo).toBe('Instant');
		const corregida = analizarEntrada(texto, { ia_generador: 'ChatGPT', ia_modelo: '', ia_modo: 'Instant', ia_plan: 'Plus', ia_parametros: 'top_p=0.8' });
		expect(corregida.errores).toEqual([]);
		expect(corregida.datos!.procedencia.ejecucion).toMatchObject({ generador: 'ChatGPT', modelo: null, modo: 'Instant', plan: 'Plus', parametros: 'top_p=0.8' });
		expect(corregida.datos!.metadatos).not.toHaveProperty('ia_modelo');
		expect(JSON.parse(texto).procedencia.modelo).toBe('Modelo declarado');
		const guardada = vistaDeFichaGuardada(corregida.datos as FichaMinima, raw, { obra_id: 'obra', importacion_id: 'imp' });
		expect(guardada.metadatos.ia_modelo).toBe('');
		expect(guardada.metadatos.ia_plan).toBe('Plus');
		expect(guardada.metadatos.ia_parametros).toBe('top_p=0.8');
		const antigua = structuredClone(corregida.datos) as FichaMinima;
		delete antigua.procedencia.ejecucion;
		expect(vistaDeFichaGuardada(antigua, raw, { obra_id: 'obra', importacion_id: 'imp' }).metadatos.ia_modelo).toBe('Modelo declarado');
	});
	it('avisa del descuadre métrico y recalcula tras declarar una adición, sin cambiar la extensión', () => {
		const raw=JSON.parse(obtenerPilotos()[0].entrada);
		raw.obra_ref='obra-importada';raw.jornadas=[{numero:1,rotulo_literal:null}];raw.resumen_fuente=[];raw.incidencias=[];
		raw.tramos=[{id:'t01',jornada:1,v_ini:1,v_fin:53,denominacion_literal:'Redondillas',n_versos_fuente:53,fuente_id:'foto-01',pagina:null,notas_ref:['n01']}];
		raw.notas=[{id:'n01',marca:'1',texto_literal:'El v. 5 es un verso añadido.',fuente_id:'foto-01',pagina:null,tramos_ref:['t01'],v_ini:5,v_fin:5}];
		const sinAjuste=analizarEntrada(JSON.stringify(raw));
		expect(sinAjuste.errores).toEqual([]);
		expect(sinAjuste.filas[0].longitud?.estado).toBe('revisar');
		expect(sinAjuste.avisos).toContainEqual(expect.objectContaining({codigo:'longitud_metrica',ruta:'segmentos.t01'}));
		expect(sinAjuste.datos!.procedencia.entradas_sha256['reglas-longitud.json']).toMatch(/^[a-f0-9]{64}$/);
		const copia=structuredClone(sinAjuste.datos) as FichaMinima;
		const antes=structuredClone(copia);
		const reabierta=vistaDeFichaGuardada(copia,raw,{obra_id:'00000000-0000-4000-8000-000000000001',importacion_id:'00000000-0000-4000-8000-000000000002'});
		expect(reabierta.filas[0].longitud?.estado).toBe('revisar');
		expect(copia).toEqual(antes);
		const ediciones=[{tramo_ref:'t01',partes:[{v_ini:1,v_fin:53,
			identificacion:{forma_slug:'redondilla',arquitectura_slug:null},nota:null,remate:null,
			desviaciones:[{v_ini:5,v_fin:5,dimension:'estructura',relacion_norma:'sobra',nota_ref:'n01',nota:null}]}]}];
		const corregida=analizarEntrada(JSON.stringify(raw),{},ediciones);
		expect(corregida.errores).toEqual([]);
		expect(corregida.filas[0].longitud?.estado).toBe('compatible');
		expect(corregida.avisos.some(a=>a.codigo==='longitud_metrica')).toBe(false);
		expect(corregida.resumen!.extension).toBe(53);
		expect(corregida.filas[0].v_ini).toBe(1);expect(corregida.filas[0].v_fin).toBe(53);
	});
	it('reconoce mayúsculas editoriales y Sextetos alirados sin alterar los literales', () => {
		const raw=JSON.parse(obtenerPilotos()[0].entrada);
		raw.obra_ref='obra-importada';raw.jornadas=[{numero:1,rotulo_literal:null}];
		raw.notas=[];raw.resumen_fuente=[];raw.incidencias=[];
		raw.tramos=[
			{id:'t01',jornada:1,v_ini:1,v_fin:616,denominacion_literal:'Redondillas',n_versos_fuente:616,fuente_id:'foto-01',pagina:null,notas_ref:[]},
			{id:'t02',jornada:1,v_ini:617,v_fin:694,denominacion_literal:'Sextetos alirados',n_versos_fuente:78,fuente_id:'foto-01',pagina:null,notas_ref:[]},
			{id:'t03',jornada:1,v_ini:695,v_fin:740,denominacion_literal:'Endecasílabos Sueltos',n_versos_fuente:46,fuente_id:'foto-01',pagina:null,notas_ref:[]}
		];
		const vista=analizarEntrada(JSON.stringify(raw));
		expect(vista.errores).toEqual([]);
		expect(vista.datos!.segmentos.map(s=>s.identificacion?.forma_slug)).toEqual(['redondilla','sexteto_lira','endecasilabo_suelto']);
		expect(vista.datos!.segmentos.map(s=>s.origen.denominacion_literal)).toEqual(raw.tramos.map((t:{denominacion_literal:string})=>t.denominacion_literal));
	});
	it('reconoce todas las asonancias del catálogo y conserva las desconocidas sin inventar valores', () => {
		const raw=JSON.parse(obtenerPilotos()[0].entrada);
		raw.obra_ref='obra-importada'; raw.jornadas=[{numero:1,rotulo_literal:null}];
		raw.notas=[]; raw.resumen_fuente=[]; raw.incidencias=[];
		const valores=['a','a-a','a-e','a-o','e','e-a','e-e','e-o','i','i-a','i-e','i-o','o','o-a','o-e','o-o','u','u-a','u-e','u-o'];
		for(const valor of valores) for(const literal of [valor, '-'+valor.replaceAll('-',''), valor.replaceAll('a','á').replaceAll('-',' – ')]) {
			raw.tramos=[{id:'t01',jornada:1,v_ini:1,v_fin:100,denominacion_literal:'romance en '+literal,n_versos_fuente:100,fuente_id:'foto-01',pagina:null,notas_ref:[]}];
			const vista=analizarEntrada(JSON.stringify(raw));
			expect(vista.errores).toEqual([]);
			expect(vista.datos!.segmentos[0].identificacion).toEqual({forma_slug:'romance',arquitectura_slug:'octosilabica'});
			expect(vista.datos!.segmentos[0].detalles_fuente).toEqual([{literal,rasgo_slug:'vocales_asonancia',valor_slug:valor}]);
		}
		raw.tramos[0].denominacion_literal='romance en e-i';
		const fuera=analizarEntrada(JSON.stringify(raw));
		expect(fuera.errores).toEqual([]);
		expect(fuera.datos!.segmentos[0].detalles_fuente).toEqual([{literal:'e-i',dimension:'asonancia'}]);
	});
	it('identifica los sueltos con pareado, pero solo anota el cierre cuando la nota lo declara', () => {
		const raw=JSON.parse(obtenerPilotos()[0].entrada);
		raw.obra_ref='obra-importada';raw.jornadas=[{numero:1,rotulo_literal:null}];raw.resumen_fuente=[];raw.incidencias=[];
		raw.tramos=[{id:'t01',jornada:1,v_ini:1,v_fin:54,denominacion_literal:'endecasílabos sueltos con pareado',n_versos_fuente:54,fuente_id:'foto-01',pagina:null,notas_ref:['n01']}];
		raw.notas=[{id:'n01',marca:'20',texto_literal:null,fuente_id:'foto-01',pagina:null,tramos_ref:['t01'],v_ini:null,v_fin:null}];
		const sinNota=analizarEntrada(JSON.stringify(raw));
		expect(sinNota.errores).toEqual([]);
		expect(sinNota.datos!.segmentos[0].identificacion?.forma_slug).toBe('endecasilabo_suelto');
		expect(sinNota.datos!.segmentos[0].detalles_fuente).toEqual([]);
		raw.notas[0].texto_literal='La serie está rematada por un pareado en vv. 53-54.';
		const conNota=analizarEntrada(JSON.stringify(raw));
		expect(conNota.errores).toEqual([]);
		expect(conNota.datos!.segmentos[0].detalles_fuente).toContainEqual(expect.objectContaining({rasgo_slug:'distico_final',valor_slug:'presente'}));
	});
	it('usa la nota enlazada para tercetos con cierre, sin trasladar esquemas de quintillas', () => {
		const raw=JSON.parse(obtenerPilotos()[0].entrada);
		raw.obra_ref='obra-importada'; raw.jornadas=[{numero:1,rotulo_literal:null}];
		raw.tramos=[
			{id:'t01',jornada:1,v_ini:1,v_fin:91,denominacion_literal:'tercetos',n_versos_fuente:91,fuente_id:'foto-01',pagina:null,notas_ref:['n01']},
			{id:'t02',jornada:1,v_ini:92,v_fin:331,denominacion_literal:'quintillas',n_versos_fuente:240,fuente_id:'foto-01',pagina:null,notas_ref:['n02']}
		];
		raw.notas=[
			{id:'n01',marca:'18',texto_literal:'Como es habitual, la serie de tercetos encadenados se cierra con un serventesio.',fuente_id:'foto-01',pagina:null,tramos_ref:['t01'],v_ini:null,v_fin:null},
			{id:'n02',marca:'19',texto_literal:'Formas ababa (115), aabba (120) y abaab (5).',fuente_id:'foto-01',pagina:null,tramos_ref:['t02'],v_ini:null,v_fin:null}
		]; raw.resumen_fuente=[]; raw.incidencias=[];
		const vista=analizarEntrada(JSON.stringify(raw));
		expect(vista.errores).toEqual([]);
		expect(vista.datos!.segmentos[0].identificacion).toEqual({forma_slug:'terceto_encadenado',arquitectura_slug:null});
		expect(vista.datos!.segmentos[0].detalles_fuente).toContainEqual(expect.objectContaining({tipo_seccion:'remate',n_versos:1}));
		expect(vista.datos!.segmentos[1].detalles_fuente).toEqual([]);
		expect(vista.filas[1].notas_fuente?.[0].texto_literal).toContain('abaab (5)');
		// Una nota de otra fila no resuelve los tercetos.
		raw.tramos[0].notas_ref=[]; raw.notas[0].tramos_ref=[];
		const sinNota=analizarEntrada(JSON.stringify(raw));
		expect(sinNota.datos!.segmentos[0].identificacion).toBeNull();
		expect(sinNota.datos!.segmentos[0].detalles_fuente).toEqual([]);
	});
	it('prepara las equivalencias y divide el estrambote sin perder la fila original', () => {
		const raw = JSON.parse(obtenerPilotos()[0].entrada);
		raw.obra_ref = 'obra-importada';
		raw.jornadas = [{numero: 1, rotulo_literal: 'ACTO PRIMERO'}];
		raw.tramos = [
			{id:'t01', jornada:1, v_ini:1, v_fin:76, denominacion_literal:'endecasílabos sueltos rematados\nen pareado', n_versos_fuente:76, fuente_id:'foto-01', pagina:null, notas_ref:[]},
			{id:'t02', jornada:1, v_ini:77, v_fin:178, denominacion_literal:'sextetos-liras', n_versos_fuente:102, fuente_id:'foto-01', pagina:null, notas_ref:[]},
			{id:'t03', jornada:1, v_ini:179, v_fin:195, denominacion_literal:'soneto con estrambote', n_versos_fuente:17, fuente_id:'foto-01', pagina:null, notas_ref:[]}
		];
		raw.notas=[]; raw.resumen_fuente=[]; raw.incidencias=[];
		const vista = analizarEntrada(JSON.stringify(raw));
		expect(vista.errores).toEqual([]);
		const partes = vista.datos!.segmentos;
		expect(partes).toHaveLength(4);
		expect(partes[0].identificacion).toEqual({forma_slug:'endecasilabo_suelto',arquitectura_slug:'endecasilabica'});
		expect(partes[0].detalles_fuente).toContainEqual({literal:'pareado final',rasgo_slug:'distico_final',valor_slug:'presente'});
		expect(partes[0].origen.denominacion_literal).toContain('\n');
		expect(partes[1].identificacion).toEqual({forma_slug:'sexteto_lira',arquitectura_slug:'heterometrica_consonante'});
		expect(partes[2]).toMatchObject({v_ini:179,v_fin:192,origen:{tramo_ref:'t03'},identificacion:{forma_slug:'soneto'}});
		expect(partes[3]).toMatchObject({v_ini:193,v_fin:195,origen:{tramo_ref:'t03'},identificacion:null,candidatas:[]});
		expect(partes[3].nota).toContain('criterio pendiente');
		// La división propuesta sigue siendo editable por la fila original.
		const edicion = [{tramo_ref:'t03',partes:[
			{v_ini:179,v_fin:192,identificacion:{forma_slug:'soneto',arquitectura_slug:'endecasilabica_consonante'},nota:null,remate:null},
			{v_ini:193,v_fin:195,identificacion:null,nota:partes[3].nota,remate:null}
		]}];
		const editada = analizarEntrada(JSON.stringify(raw), {}, edicion);
		expect(editada.errores).toEqual([]);
		expect(raw.tramos).toHaveLength(3);
	});
	it('explica una sola vez las jornadas fuera de orden, indicando los números recibidos', () => {
		const raw = JSON.parse(obtenerPilotos()[0].entrada);
		for (const j of raw.jornadas) j.numero += 1;
		for (const t of raw.tramos) t.jornada += 1;
		const vista = analizarEntrada(JSON.stringify(raw));
		expect(vista.errores).toHaveLength(1);
		expect(vista.errores[0]).toMatchObject({codigo:'orden_jornadas',ruta:'jornadas'});
		expect(vista.errores[0].mensaje).toContain('2, 3, 4');
		expect(vista.datos).toBeNull();
	});
	it('precarga el género aportado si tiene correspondencia y deja elegir si no la tiene', () => {
		const raw = JSON.parse(obtenerPilotos()[0].entrada);
		raw.metadatos.genero_literal = 'Tragedia';
		expect(analizarEntrada(JSON.stringify(raw)).metadatos.genero).toBe('tragedia');
		raw.metadatos.genero_literal = 'Denominación sin correspondencia';
		const vista = analizarEntrada(JSON.stringify(raw));
		expect(vista.metadatos.genero).toBe('');
		expect(vista.errores).toEqual([]);
		expect(vista.filas.length).toBeGreaterThan(0);
		expect(vista.pendientes_metadatos!.length).toBeGreaterThan(0);
	});
	it('permite revisar y editar sin metadatos y conserva los cambios al completarlos', () => {
		const raw = JSON.parse(obtenerPilotos()[0].entrada);
		raw.metadatos = null;
		const texto = JSON.stringify(raw);
		const inicial = analizarEntrada(texto);
		expect(inicial.errores).toEqual([]);
		expect(inicial.filas).toHaveLength(raw.tramos.length);
		expect(inicial.datos?.metadatos.fecha_inicio).toBeNull();
		expect(inicial.pendientes_metadatos!.length).toBeGreaterThan(0);
		const s = inicial.filas.find(s => s.identificacion?.forma_slug === 'redondilla')!;
		const ediciones = [{tramo_ref:s.origen.tramo_ref,partes:[{v_ini:s.v_ini,v_fin:s.v_fin,
			identificacion:s.identificacion,nota:'Revisión conservada',remate:null}]}];
		const editada = analizarEntrada(texto, {}, ediciones);
		expect(editada.errores).toEqual([]);
		expect(editada.filas.find(f => f.v_ini === s.v_ini)?.nota).toBe('Revisión conservada');
		const completa = analizarEntrada(texto, {titulo:'Título de prueba',autor_nombre:'Lope de Vega',
			edicion_base:'Edición de prueba',fecha_inicio:'1585',fecha_fin:'1593'}, ediciones);
		expect(completa.errores).toEqual([]);
		expect(completa.pendientes_metadatos).toEqual([]);
		expect(completa.filas.find(f => f.v_ini === s.v_ini)?.nota).toBe('Revisión conservada');
		expect(JSON.parse(texto).metadatos).toBeNull();
	});
	it('sitúa los errores de extracción en la fila y el campo sin mostrar JSON técnico', () => {
		const raw = JSON.parse(obtenerPilotos().find(p => p.id === 'los-locos-de-valencia')!.entrada);
		raw.notas[1].marca = '';
		raw.tramos[0].pagina = String(raw.tramos[0].pagina);
		const vista = analizarEntrada(JSON.stringify(raw));
		expect(vista.datos).toBeNull();
		expect(vista.errores).toEqual(expect.arrayContaining([
			expect.objectContaining({ruta: 'notas.1.marca', mensaje: 'Nota 2 (marca): Debe contener texto'}),
			expect.objectContaining({ruta: 'tramos.0.pagina', mensaje: 'Fila de la edición 1 (página): Debe ser un número entero sin comillas, o null si no consta.'})
		]));
		expect(vista.errores.every(e => !e.mensaje.includes('{'))).toBe(true);
		expect(raw.notas[1].marca).toBe('');
	});
	it.each(obtenerPilotos())('prepara el intercambio real de $titulo', (piloto) => {
		const vista = analizarEntrada(piloto.entrada);
		expect(vista.errores).toEqual([]);
		expect(vista.resumen?.jornadas).toBe(3);
		expect(vista.persistido).toBe(false);
		expect(vista.confirmacion).toBeNull();
		expect(vista.filas.length).toBeGreaterThan(10);
		expect(JSON.parse(JSON.stringify(vista))).toEqual(vista);
	});
	it('permite editar metadatos y vaciar expresamente la fuente opcional', () => {
		const vista = analizarEntrada(obtenerPilotos()[0].entrada, {
			titulo: 'Título revisado',
			fuente_fecha: '',
			fecha_inicio: '1580',
			fecha_fin: '1590'
		});
		expect(vista.errores).toEqual([]);
		expect(vista.datos?.metadatos).toMatchObject({
			titulo: 'Título revisado',
			fuente_fecha: null,
			fecha_inicio: 1580,
			fecha_fin: 1590
		});
	});
	it('deja revisar con fechas vacías, pero impide guardar; rechaza fechas invertidas', () => {
		expect(
			analizarEntrada(obtenerPilotos()[0].entrada, { fecha_inicio: '' }).pendientes_metadatos!.length
		).toBeGreaterThan(0);
		expect(
			analizarEntrada(obtenerPilotos()[0].entrada, {
				fecha_inicio: '1600',
				fecha_fin: '1590'
			}).errores.length
		).toBeGreaterThan(0);
	});
	it('corrige las fechas inválidas de la extracción sin cambiar la huella de la fuente original', () => {
		const raw = JSON.parse(obtenerPilotos()[0].entrada);
		raw.metadatos.fecha_inicio = 1600;
		raw.metadatos.fecha_fin = 1500;
		const entrada = JSON.stringify(raw);
		expect(analizarEntrada(entrada).errores.length).toBeGreaterThan(0);
		const corregida = analizarEntrada(entrada, { fecha_inicio: '1580', fecha_fin: '1590' });
		expect(corregida.errores).toEqual([]);
		expect(corregida.datos?.metadatos).toMatchObject({ fecha_inicio: 1580, fecha_fin: 1590 });
		expect(corregida.datos?.procedencia.extraccion_sha256).toBe(
			createHash('sha256').update(entrada).digest('hex')
		);
		expect(JSON.parse(entrada).metadatos.fecha_inicio).toBe(1600);
	});
	it('mantiene las decisiones del piloto al corregir sus metadatos mediante el formulario', () => {
		const entrada = obtenerPilotos().find((p) => p.id === 'los-locos-de-valencia')!.entrada;
		const corregida = analizarEntrada(entrada, { fecha_inicio: '1590', fecha_fin: '1595' });
		expect(corregida.errores).toEqual([]);
		expect(corregida.filas.flatMap((f) => f.desviaciones)).toHaveLength(2);
	});
	it('expone las notas literales de la extracción y no las inventa para una ficha mínima', () => {
		const entrada = obtenerPilotos().find((p) => p.id === 'los-locos-de-valencia')!.entrada;
		const vista = analizarEntrada(entrada);
		const original = JSON.parse(entrada);
		for (const fila of vista.filas) {
			expect(fila.notas_fuente).toEqual(
				original.notas
					.filter(
						(n: { id: string; texto_literal: string | null }) =>
							fila.origen.notas_ref.includes(n.id) && typeof n.texto_literal === 'string'
					)
					.map((n: { id: string; texto_literal: string; v_ini: number | null; v_fin: number | null; tramos_ref: string[] }) => ({
						id: n.id,
						texto_literal: n.texto_literal,
						v_ini: n.v_ini, v_fin: n.v_fin, tramos_ref: n.tramos_ref
					}))
			);
		}
		expect(vista.filas.flatMap((f) => f.notas_fuente ?? []).length).toBeGreaterThan(0);
		expect(
			analizarEntrada(JSON.stringify(preparada)).filas.every((f) => f.notas_fuente === undefined)
		).toBe(true);
	});
	it.each(['', '{incompleto', '[]', '{"esquema":"inventado"}'])(
		'rechaza entradas mal formadas: %s',
		(texto) => {
			const vista = analizarEntrada(texto);
			expect(vista.errores.length).toBeGreaterThan(0);
			expect(vista.datos).toBeNull();
		}
	);
	it('acepta un bloque JSON y la ficha mínima del piloto', () => {
		const vista = analizarEntrada('```json\n' + JSON.stringify(preparada) + '\n```');
		expect(vista.errores).toEqual([]);
		expect(vista.resumen?.forma_identificada).toBe(2878);
		expect(
			vista.filas.find((f) => f.forma_nombre === 'Canción')?.identificacion?.arquitectura_slug
		).toBeNull();
	});
	it('conserva tercetos ambiguos sin contarlos como formas identificadas', () => {
		const vista = analizarEntrada(
			obtenerPilotos().find((p) => p.id === 'los-donaires-de-matico')!.entrada
		);
		const tercetos = vista.filas.find((f) => f.candidatas.some((c) => c.forma_slug === 'terceto'));
		expect(tercetos?.identificacion).toBeNull();
		expect(tercetos).not.toHaveProperty('estado');
		expect(vista.resumen?.forma_pendiente).toBeGreaterThan(0);
		expect(vista.resumen?.forma_identificada).toBeLessThan(vista.resumen!.extension);
	});
	it('solo aplica decisiones de desviación al contenido preciso del piloto, no a su obra_ref', () => {
		const original = obtenerPilotos().find((p) => p.id === 'los-locos-de-valencia')!;
		const vista = analizarEntrada(original.entrada);
		expect(vista.filas.flatMap((f) => f.desviaciones)).toHaveLength(2);
		const cambiado = JSON.parse(original.entrada);
		cambiado.metadatos.titulo = 'Otra obra con la misma referencia';
		const suplantada = analizarEntrada(JSON.stringify(cambiado));
		expect(suplantada.errores).toEqual([]);
		expect(suplantada.filas.flatMap((f) => f.desviaciones)).toEqual([]);
	});
	it('ofrece el prompt literal y el carácter local del catálogo', () => {
		expect(obtenerReferenciaImportador().prompt).toContain('Transcribe las fotografías');
		expect(obtenerReferenciaImportador().prompt_version).toBe('0.13');
		expect(obtenerReferenciaImportador().prompt).toContain('Letra de rima | Caja impresa');
		expect(obtenerReferenciaImportador().prompt).toContain('posición 3: no se distingue b/B');
		expect(
			analizarEntrada(obtenerPilotos()[0].entrada).avisos.some(
				(a) => a.codigo === 'referencia_local'
			)
		).toBe(true);
	});
	it('distingue por sus nombres las arquitecturas propuestas y candidatas', () => {
		const ficha = structuredClone(preparada.datos) as FichaMinima;
		const segmento = ficha.segmentos.find((s) => s.identificacion?.arquitectura_slug && !s.detalles_fuente.length);
		expect(segmento).toBeDefined();
		const destino = segmento!.identificacion!;
		const propuesta = analizarEntrada(JSON.stringify(ficha));
		const nombre = propuesta.filas.find((f) => f.ref === segmento!.ref)?.forma_nombre;
		expect(nombre).toContain(' · ');
		expect(nombre).not.toContain(destino.arquitectura_slug);
		segmento!.candidatas = [destino];
		segmento!.identificacion = null;
		const candidatas = analizarEntrada(JSON.stringify(ficha));
		expect(candidatas.errores).toEqual([]);
		expect(candidatas.filas.find((f) => f.ref === segmento!.ref)?.candidatas_nombres).toEqual([
			nombre
		]);
	});
});
