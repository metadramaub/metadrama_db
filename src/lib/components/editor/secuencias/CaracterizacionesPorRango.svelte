<script lang="ts">
	import { browser } from '$app/environment';
	import Pencil from 'lucide-svelte/icons/pencil';
	import Trash2 from 'lucide-svelte/icons/trash-2';
	import Button from '$lib/components/ui/button.svelte';
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import FieldHelpTooltip from '$lib/components/ui/field-help-tooltip.svelte';
	import MarkdownEditorLite from '$lib/components/ui/markdown-editor-lite.svelte';
	import { pushToast } from '$lib/stores/toast';
	import type { Tables } from '$lib/types/database.types';
	import { displayTerm } from '$lib/utils/vocabulario';

	/**
	 * Las caracterizaciones por rango de una secuencia: prosa, versos cantados, lagunas, hipometría.
	 *
	 * **Se guarda sola.** No entra en el formulario de la secuencia ni en su `save()`: tiene su
	 * propio endpoint y escribe en cuanto se acepta el modal. Por eso puede vivir aparte sin tocar
	 * nada de lo que la rodea, y por eso fue la primera pieza que salió de `SecuenciasTab` al
	 * partirla.
	 *
	 * *Se queda cuando el editor V2 sustituya la métrica de la secuencia*, aunque algunas de estas
	 * caracterizaciones acabarán siendo desviaciones del catálogo nuevo. Mientras tanto conviven.
	 */
	type CaracterizacionRangoItem = {
		caracterizacion_rango_id: string;
		secuencia_id: string;
		tipo_caracterizacion_rango_id: string;
		tipo_caracterizacion_rango_term: string;
		tipo_caracterizacion_rango_parent_id: string | null;
		v_ini: number;
		v_fin: number;
		observaciones: string | null;
	};

	type FormState = {
		tipo_caracterizacion_rango_id: string;
		v_ini: number;
		v_fin: number;
		observaciones: string;
	};

	type Opcion = Pick<
		Tables<'vocabularios'>,
		'termino_id' | 'termino' | 'etiqueta' | 'termino_padre_id' | 'orden'
	>;

	const props = $props<{
		obraId: string;
		/**
		 * La secuencia que se está editando, o `null` si todavía no se ha guardado. Sin ella no hay
		 * dónde colgar una caracterización, y la sección lo dice en vez de ofrecer un botón que
		 * fallaría.
		 */
		secuenciaId: string | null;
		/** El rango de la secuencia: acota el de cada caracterización y da el valor de partida. */
		rango: { v_ini: number; v_fin: number };
		opciones: Opcion[];
		readOnly?: boolean;
		/**
		 * Estas caracterizaciones alimentan `obras_resumen` pero no cambian la lista de secuencias,
		 * así que la página necesita enterarse por su cuenta de que hay datos públicos por rehacer.
		 */
		onMetricaDirty?: () => void;
	}>();

	let items = $state<CaracterizacionRangoItem[]>([]);
	let cargando = $state(false);
	/**
	 * El contador de peticiones **no es reactivo a propósito**: `++peticion` lo lee y lo escribe
	 * dentro del efecto que recarga, y siendo `$state` eso bastaba para que el efecto se
	 * reprogramara a sí mismo sin parar. Nadie lo pinta; solo sirve para comparar.
	 */
	let peticion = 0;
	let modalAbierto = $state(false);
	let guardando = $state(false);
	let editandoId = $state<string | null>(null);
	let borrandoId = $state<string | null>(null);
	let borrando = $state(false);
	let form = $state<FormState>({
		tipo_caracterizacion_rango_id: '',
		v_ini: 1,
		v_fin: 1,
		observaciones: ''
	});

	function ordenar(lista: CaracterizacionRangoItem[]) {
		return [...lista].sort((a, b) => a.v_ini - b.v_ini || a.v_fin - b.v_fin);
	}

	function ordenarOpciones(opciones: Opcion[]) {
		return [...opciones].sort(
			(a, b) =>
				(a.orden ?? Number.MAX_SAFE_INTEGER) - (b.orden ?? Number.MAX_SAFE_INTEGER) ||
				a.termino.localeCompare(b.termino, 'es')
		);
	}

	function normalizarTermino(valor: string): string {
		return valor
			.normalize('NFD')
			.replaceAll(/\p{M}/gu, '')
			.trim()
			.toLowerCase()
			.replaceAll(/[\s-]+/g, '_');
	}

	const opcionesDelDesplegable = $derived.by(() =>
		ordenarOpciones(props.opciones).map((opcion: Opcion) => ({
			id: opcion.termino_id,
			label: displayTerm(opcion),
			parentId: opcion.termino_padre_id ?? null
		}))
	);

	const opcionPorId = $derived.by(
		() => new Map<string, Opcion>(props.opciones.map((opcion: Opcion) => [opcion.termino_id, opcion]))
	);

	const terminoElegido = $derived.by(() =>
		normalizarTermino(opcionPorId.get(form.tipo_caracterizacion_rango_id)?.termino ?? '')
	);

	/**
	 * Cada tipo se anota de una manera y el modal lo dice mientras se rellena.
	 *
	 * Lo que separa unos de otros no es un capricho: la prosa ocupa por fuerza más de un verso
	 * porque no va numerada, y la hipometría es de un verso concreto. Decirlo aquí evita el aviso
	 * de error después.
	 */
	const ayudaDelRango = $derived.by(() => {
		if (terminoElegido === 'prosa') {
			return 'Indica entre qué versos aparece la prosa (no numerada). Ej.: v_ini=56, v_fin=57.';
		}
		if (terminoElegido === 'hipometrico' || terminoElegido === 'hipermetrico') {
			return 'Esta caracterización aplica a un solo verso: usa el mismo número en V. ini y V. fin.';
		}
		if (
			terminoElegido === 'cantado' ||
			terminoElegido === 'rima_defectuosa' ||
			terminoElegido === 'laguna'
		) {
			return 'Puedes marcar un solo verso (V. ini = V. fin) o un rango (V. ini < V. fin).';
		}
		if (terminoElegido === 'mayoria_agudas' || terminoElegido === 'mayoria_esdrujulas') {
			return 'Marca el tramo donde predominan esos finales acentuales dentro de la secuencia.';
		}
		return '';
	});

	function idPorDefecto() {
		// Solo son elegibles las hojas: las que cuelgan de otra. Un padre nombra una familia.
		return ordenarOpciones(props.opciones).find((opcion) => Boolean(opcion.termino_padre_id))
			?.termino_id ?? '';
	}

	function formInicial(): FormState {
		return {
			tipo_caracterizacion_rango_id: idPorDefecto(),
			v_ini: Number(props.rango.v_ini) || 1,
			v_fin: Number(props.rango.v_ini) || 1,
			observaciones: ''
		};
	}

	function etiquetaPorId(tipoId: string, respaldo = '') {
		return displayTerm(opcionPorId.get(tipoId)) || respaldo || '--';
	}

	/**
	 * **Se recarga solo al cambiar de secuencia.** Pedírselo desde fuera no valía: quien abre otra
	 * secuencia cambia `editingId` y llama en la misma vuelta, cuando el componente todavía no ha
	 * visto la secuencia nueva, así que recargaba la anterior —o ninguna—. Mirando él su propia
	 * propiedad, el orden deja de importar.
	 */
	$effect(() => {
		props.secuenciaId;
		void recargar();
	});

	/**
	 * El contador descarta las respuestas que llegan tarde: pasar deprisa de una secuencia a otra
	 * pintaba las de la anterior sobre las de la siguiente.
	 */
	async function recargar() {
		if (!browser) return;
		if (!props.secuenciaId) {
			items = [];
			return;
		}
		cargando = true;
		const id = ++peticion;

		const respuesta = await fetch(
			`/api/obras/${props.obraId}/secuencias/${props.secuenciaId}/caracterizaciones`
		);
		if (id !== peticion) return;
		cargando = false;

		if (!respuesta.ok) {
			const cuerpo = await respuesta.json().catch(() => ({}));
			pushToast('error', cuerpo.message ?? 'No se pudieron cargar las caracterizaciones por rango');
			return;
		}

		const carga = await respuesta.json().catch(() => ({ items: [] }));
		items = ordenar((carga.items ?? []) as CaracterizacionRangoItem[]);
	}

	function validar(avisar = true) {
		if (!props.secuenciaId) {
			if (avisar) {
				pushToast('error', 'Guarda la secuencia antes de gestionar caracterizaciones por rango');
			}
			return false;
		}
		if (!form.tipo_caracterizacion_rango_id) {
			if (avisar) pushToast('error', 'Selecciona un tipo de caracterización');
			return false;
		}
		if (!opcionPorId.has(form.tipo_caracterizacion_rango_id)) {
			if (avisar) pushToast('error', 'El tipo de caracterización seleccionado no es válido');
			return false;
		}

		const vIni = Number(form.v_ini);
		const vFin = Number(form.v_fin);
		if (!Number.isFinite(vIni) || !Number.isFinite(vFin)) {
			if (avisar) pushToast('error', 'Versos de caracterización inválidos');
			return false;
		}
		if (vIni > vFin) {
			if (avisar) pushToast('error', 'El verso inicial no puede ser mayor que el final');
			return false;
		}
		if (vIni < Number(props.rango.v_ini) || vFin > Number(props.rango.v_fin)) {
			if (avisar) {
				pushToast(
					'error',
					`La caracterización debe quedar dentro del rango de la secuencia (${props.rango.v_ini}-${props.rango.v_fin})`
				);
			}
			return false;
		}

		if (terminoElegido === 'prosa' && vIni >= vFin) {
			if (avisar) pushToast('error', 'En prosa, v_ini debe ser menor que v_fin');
			return false;
		}
		if ((terminoElegido === 'hipometrico' || terminoElegido === 'hipermetrico') && vIni !== vFin) {
			if (avisar) pushToast('error', 'Hipométrico e hipermétrico solo admiten un verso');
			return false;
		}

		return true;
	}

	export function abrirNueva() {
		if (props.readOnly || !props.secuenciaId) return;
		editandoId = null;
		form = formInicial();
		modalAbierto = true;
	}

	function abrirEdicion(caracterizacion: CaracterizacionRangoItem) {
		if (props.readOnly || !props.secuenciaId) return;
		editandoId = caracterizacion.caracterizacion_rango_id;
		form = {
			tipo_caracterizacion_rango_id: caracterizacion.tipo_caracterizacion_rango_id,
			v_ini: caracterizacion.v_ini,
			v_fin: caracterizacion.v_fin,
			observaciones: caracterizacion.observaciones ?? ''
		};
		modalAbierto = true;
	}

	export function cerrarModales() {
		if (guardando) return;
		modalAbierto = false;
		editandoId = null;
		borrandoId = null;
		form = formInicial();
	}

	async function guardar() {
		if (!browser) return;
		if (props.readOnly || guardando || !props.secuenciaId) return;
		if (!validar(true)) return;

		guardando = true;
		const editando = Boolean(editandoId);
		const base = `/api/obras/${props.obraId}/secuencias/${props.secuenciaId}/caracterizaciones`;

		const respuesta = await fetch(editando ? `${base}/${editandoId}` : base, {
			method: editando ? 'PATCH' : 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({
				tipo_caracterizacion_rango_id: form.tipo_caracterizacion_rango_id,
				v_ini: Number(form.v_ini),
				v_fin: Number(form.v_fin),
				observaciones: form.observaciones.trim() || null
			})
		});
		guardando = false;

		if (!respuesta.ok) {
			const cuerpo = await respuesta.json().catch(() => ({}));
			pushToast(
				'error',
				cuerpo.details?.[0]?.message ??
					cuerpo.message ??
					(editando
						? 'No se pudo actualizar la caracterización'
						: 'No se pudo crear la caracterización')
			);
			return;
		}

		const carga = await respuesta.json();
		const guardada = carga.caracterizacion as CaracterizacionRangoItem;
		items = ordenar(
			editando && editandoId
				? items.map((item) =>
						item.caracterizacion_rango_id === editandoId ? guardada : item
					)
				: [...items, guardada]
		);

		cerrarModales();
		props.onMetricaDirty?.();
		pushToast('success', editando ? 'Caracterización actualizada' : 'Caracterización creada');
	}

	async function eliminar(caracterizacionId: string) {
		if (!browser) return;
		if (props.readOnly || !props.secuenciaId || borrando) return;
		borrando = true;
		try {
			const respuesta = await fetch(
				`/api/obras/${props.obraId}/secuencias/${props.secuenciaId}/caracterizaciones/${caracterizacionId}`,
				{ method: 'DELETE' }
			);
			if (!respuesta.ok) {
				const cuerpo = await respuesta.json().catch(() => ({}));
				pushToast('error', cuerpo.message ?? 'No se pudo eliminar la caracterización');
				return;
			}
			items = items.filter((row) => row.caracterizacion_rango_id !== caracterizacionId);
			borrandoId = null;
			props.onMetricaDirty?.();
			pushToast('success', 'Caracterización eliminada');
		} catch {
			pushToast('error', 'No se pudo conectar con el servidor para eliminar la caracterización');
		} finally {
			borrando = false;
		}
	}
</script>

<section class="bg-white p-4">
	<div class="mb-2 flex flex-wrap items-center justify-between gap-2">
		<h4 class="form-section-title mb-0">Caracterizaciones por rango</h4>
		<Button variant="secondary" onclick={abrirNueva} disabled={props.readOnly || !props.secuenciaId}>
			Añadir caracterización
		</Button>
	</div>

	{#if !props.secuenciaId}
		<p class="form-help">Guarda la secuencia para añadir caracterizaciones por rango.</p>
	{:else if cargando}
		<p class="form-help">Cargando caracterizaciones por rango...</p>
	{:else if items.length === 0}
		<p class="form-help">Sin caracterizaciones por rango registradas en esta secuencia.</p>
	{:else}
		<div class="mt-3 overflow-x-auto">
			<table class="min-w-full text-left text-xs">
				<thead class="bg-[color:var(--muted)]">
					<tr>
						<th class="px-2 py-2">Tipo</th>
						<th class="px-2 py-2">V_ini</th>
						<th class="px-2 py-2">V_fin</th>
						<th class="w-16 px-2 py-2"><span class="sr-only">Acciones</span></th>
					</tr>
				</thead>
				<tbody>
					{#each items as caracterizacion (caracterizacion.caracterizacion_rango_id)}
						<tr class="border-t border-[color:var(--border)]">
							<td class="px-2 py-2">
								{etiquetaPorId(
									caracterizacion.tipo_caracterizacion_rango_id,
									caracterizacion.tipo_caracterizacion_rango_term
								)}
							</td>
							<td class="px-2 py-2">{caracterizacion.v_ini}</td>
							<td class="px-2 py-2">{caracterizacion.v_fin}</td>
							<td class="px-2 py-2">
								<div class="flex items-center justify-end gap-1">
									<button
										type="button"
										class="p-1 text-[color:var(--muted-foreground)] hover:text-[color:var(--success)] disabled:opacity-40"
										aria-label="Editar caracterización"
										onclick={() => abrirEdicion(caracterizacion)}
										disabled={props.readOnly}
									>
										<Pencil size={15} />
									</button>
									<button
										type="button"
										class="p-1 text-[color:var(--muted-foreground)] hover:text-[color:var(--danger)] disabled:opacity-40"
										aria-label="Eliminar caracterización"
										onclick={() => (borrandoId = caracterizacion.caracterizacion_rango_id)}
										disabled={props.readOnly}
									>
										<Trash2 size={15} />
									</button>
								</div>
							</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	{/if}
</section>

{#if modalAbierto}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
		<div class="card w-full max-w-2xl p-5">
			<h3 class="text-lg font-semibold">
				{editandoId ? 'Editar caracterización' : 'Añadir caracterización'}
			</h3>
			<div class="mt-3 grid gap-3">
				<label class="form-field">
					<span class="form-label">Tipo *</span>
					<CheckDropdown
						multiple={false}
						hierarchical={true}
						collapsibleHierarchy={true}
						showPathInTrigger={true}
						allowSingleClear={false}
						search={opcionesDelDesplegable.length > 8}
						placeholder="Seleccionar tipo"
						items={opcionesDelDesplegable}
						disabled={props.readOnly || guardando}
						disableParentsWithChildren={true}
						selectedIds={form.tipo_caracterizacion_rango_id
							? [form.tipo_caracterizacion_rango_id]
							: []}
						onChange={(ids: string[]) => {
							const siguiente = ids[0] ?? '';
							if (!siguiente) return;
							form = { ...form, tipo_caracterizacion_rango_id: siguiente };
						}}
					/>
				</label>

				<div class="grid gap-3 sm:grid-cols-2">
					<label class="form-field">
						<span class="form-label">V. ini *</span>
						<input
							type="number"
							bind:value={form.v_ini}
							disabled={props.readOnly || guardando}
							class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
						/>
					</label>
					<label class="form-field">
						<span class="form-label">V. fin *</span>
						<input
							type="number"
							bind:value={form.v_fin}
							disabled={props.readOnly || guardando}
							class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
						/>
					</label>
				</div>

				{#if ayudaDelRango}
					<p
						class="rounded-md border border-[color:var(--border)] bg-[color:var(--muted)] px-3 py-2 text-xs text-[color:var(--muted-foreground)]"
					>
						{ayudaDelRango}
					</p>
				{/if}

				<label class="form-field">
					<span class="form-label">
						<span class="form-label-with-help">
							Observaciones
							<FieldHelpTooltip
								text="Este contenido se publica en la ficha pública de la obra."
								label="Visibilidad pública de observaciones de la caracterización"
							/>
						</span>
					</span>
					<MarkdownEditorLite
						rows={3}
						class="mt-1"
						minHeightClass="min-h-24"
						value={form.observaciones}
						disabled={props.readOnly || guardando}
						onChange={(siguiente: string) => (form = { ...form, observaciones: siguiente })}
					/>
				</label>
			</div>
			<div class="mt-4 flex justify-end gap-2">
				<Button variant="secondary" onclick={cerrarModales}>Cancelar</Button>
				<Button
					variant="success"
					disabled={props.readOnly}
					loading={guardando}
					loadingLabel="Guardando…"
					onclick={() => void guardar()}
				>
					Guardar
				</Button>
			</div>
		</div>
	</div>
{/if}

{#if borrandoId}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
		<div class="card w-full max-w-md p-5">
			<h3 class="text-lg font-semibold">Eliminar caracterización</h3>
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">
				Esta acción no se puede deshacer.
			</p>
			<div class="mt-4 flex justify-end gap-2">
				<Button variant="secondary" onclick={() => (borrandoId = null)} disabled={borrando}>
					Cancelar
				</Button>
				<Button
					variant="danger"
					disabled={props.readOnly}
					loading={borrando}
					loadingLabel="Eliminando…"
					onclick={() => borrandoId && void eliminar(borrandoId)}
				>
					Eliminar
				</Button>
			</div>
		</div>
	</div>
{/if}
