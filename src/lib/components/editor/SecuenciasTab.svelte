<script lang="ts">
	import { onDestroy } from 'svelte';
	import type { Tables } from '$lib/types/database.types';
	import Button from '$lib/components/ui/button.svelte';
	import InternalCommentsPanel from '$lib/components/editor/InternalCommentsPanel.svelte';
	import { pushToast } from '$lib/stores/toast';

	const props = $props<{
		obraId: string;
		secuenciasInitial: Tables<'secuencias_metricas'>[];
		secuenciasMetrosInitial: Tables<'secuencias_metros'>[];
		estrofaOptions: Array<Pick<Tables<'vocabularios'>, 'termino_id' | 'termino'>>;
		metroOptions: Array<Pick<Tables<'vocabularios'>, 'termino_id' | 'termino'>>;
		estadoRevisionOptions: Array<Pick<Tables<'vocabularios'>, 'termino_id' | 'termino'>>;
		certezaOptions: Array<Pick<Tables<'vocabularios'>, 'termino_id' | 'termino'>>;
		readOnly?: boolean;
		canComment?: boolean;
	}>();

	type FormState = {
		v_ini: number;
		v_fin: number;
		estrofa_tipo_id: string;
		inaugura_espacio: boolean;
		personajes_genero: 'mixto' | 'solo_masculino' | 'solo_femenino';
		personajes_donaire: 'ausente' | 'solo' | 'con_otros';
		personajes_sobrenatural: 'ausente' | 'solo' | 'con_otros';
		estado_revision: string;
		certeza_editor: string;
		observaciones: string;
		metro_ids: string[];
	};

	let secuencias = $state([...props.secuenciasInitial]);
	let secuenciaMetros = $state([...props.secuenciasMetrosInitial]);
	let sidebarOpen = $state(false);
	let editingId = $state<string | null>(null);
	let filtroEstrofa = $state('');
	let filtroEstado = $state('');
	let filtroCerteza = $state('');
	let deleteTargetId = $state<string | null>(null);
	let showCloseWithoutSavingModal = $state(false);

	let sidebarSaving = $state(false);
	let sidebarDirty = $state(false);
	let sidebarBaselineSnapshot = $state('');
	let autosaveErrorShown = $state(false);
	let lastSidebarSnapshot = $state('');
	let autosaveTimer: ReturnType<typeof setTimeout> | null = null;

	const defaultEstado = props.estadoRevisionOptions[0]?.termino_id ?? '';
	const defaultCerteza = props.certezaOptions[0]?.termino_id ?? '';
	const defaultEstrofa = props.estrofaOptions[0]?.termino_id ?? '';

	function initialForm(): FormState {
		return {
			v_ini: 1,
			v_fin: 2,
			estrofa_tipo_id: defaultEstrofa,
			inaugura_espacio: false,
			personajes_genero: 'mixto',
			personajes_donaire: 'ausente',
			personajes_sobrenatural: 'ausente',
			estado_revision: defaultEstado,
			certeza_editor: defaultCerteza,
			observaciones: '',
			metro_ids: []
		};
	}

	let form = $state<FormState>(initialForm());

	function metrosForSecuencia(secuenciaId: string): string[] {
		return secuenciaMetros
			.filter((item) => item.secuencia_id === secuenciaId)
			.map((item) => item.metro_id);
	}

	function termById(options: Array<Pick<Tables<'vocabularios'>, 'termino_id' | 'termino'>>, id: string | null) {
		if (!id) return '--';
		return options.find((option) => option.termino_id === id)?.termino ?? '--';
	}

	const filteredSecuencias = $derived.by(() => {
		return secuencias
			.filter((secuencia) => !filtroEstrofa || secuencia.estrofa_tipo_id === filtroEstrofa)
			.filter((secuencia) => !filtroEstado || secuencia.estado_revision === filtroEstado)
			.filter((secuencia) => !filtroCerteza || secuencia.certeza_editor === filtroCerteza)
			.sort((a, b) => a.v_ini - b.v_ini);
	});

	function clearAutosaveTimer() {
		if (!autosaveTimer) return;
		clearTimeout(autosaveTimer);
		autosaveTimer = null;
	}

	function sidebarSnapshot(): string {
		return JSON.stringify({
			sidebarOpen,
			id: editingId,
			v_ini: Number(form.v_ini),
			v_fin: Number(form.v_fin),
			estrofa_tipo_id: form.estrofa_tipo_id,
			inaugura_espacio: Boolean(form.inaugura_espacio),
			personajes_genero: form.personajes_genero,
			personajes_donaire: form.personajes_donaire,
			personajes_sobrenatural: form.personajes_sobrenatural,
			estado_revision: form.estado_revision,
			certeza_editor: form.certeza_editor,
			observaciones: form.observaciones.trim(),
			metro_ids: [...form.metro_ids].sort((a, b) => a.localeCompare(b))
		});
	}

	function setSidebarBaselineFromCurrent() {
		sidebarBaselineSnapshot = sidebarSnapshot();
		sidebarDirty = false;
		autosaveErrorShown = false;
		lastSidebarSnapshot = sidebarBaselineSnapshot;
	}

	function refreshSidebarDirty() {
		if (!sidebarOpen) {
			sidebarDirty = false;
			return false;
		}
		const current = sidebarSnapshot();
		sidebarDirty = current !== sidebarBaselineSnapshot;
		return sidebarDirty;
	}

	function validateForm(showToast = true) {
		if (!Number.isFinite(Number(form.v_ini)) || !Number.isFinite(Number(form.v_fin)) || Number(form.v_ini) >= Number(form.v_fin)) {
			if (showToast) pushToast('error', 'Rango de versos invalido');
			return false;
		}
		if (!form.estrofa_tipo_id) {
			if (showToast) pushToast('error', 'Selecciona estrofa');
			return false;
		}
		if (!form.estado_revision) {
			if (showToast) pushToast('error', 'Selecciona estado de revision');
			return false;
		}
		if (!form.certeza_editor) {
			if (showToast) pushToast('error', 'Selecciona certeza');
			return false;
		}
		if (form.metro_ids.length === 0) {
			if (showToast) pushToast('error', 'Selecciona al menos un metro');
			return false;
		}
		return true;
	}

	function handleAutosaveError(message: string) {
		if (autosaveErrorShown) return;
		autosaveErrorShown = true;
		pushToast('error', message);
	}

	function openNew() {
		if (props.readOnly) return;
		editingId = null;
		form = initialForm();
		sidebarOpen = true;
		showCloseWithoutSavingModal = false;
		setSidebarBaselineFromCurrent();
	}

	function openEdit(secuencia: Tables<'secuencias_metricas'>) {
		if (props.readOnly && !props.canComment) return;
		editingId = secuencia.secuencia_id;
		form = {
			v_ini: secuencia.v_ini,
			v_fin: secuencia.v_fin,
			estrofa_tipo_id: secuencia.estrofa_tipo_id ?? defaultEstrofa,
			inaugura_espacio: Boolean(secuencia.inaugura_espacio),
			personajes_genero: secuencia.personajes_genero as FormState['personajes_genero'],
			personajes_donaire: secuencia.personajes_donaire as FormState['personajes_donaire'],
			personajes_sobrenatural: secuencia.personajes_sobrenatural as FormState['personajes_sobrenatural'],
			estado_revision: secuencia.estado_revision,
			certeza_editor: secuencia.certeza_editor,
			observaciones: secuencia.observaciones ?? '',
			metro_ids: metrosForSecuencia(secuencia.secuencia_id)
		};
		sidebarOpen = true;
		showCloseWithoutSavingModal = false;
		setSidebarBaselineFromCurrent();
	}

	function toggleMetro(metroId: string) {
		if (props.readOnly) return;
		if (form.metro_ids.includes(metroId)) {
			form = { ...form, metro_ids: form.metro_ids.filter((id) => id !== metroId) };
			return;
		}
		form = { ...form, metro_ids: [...form.metro_ids, metroId] };
	}

	function performCloseSidebar() {
		clearAutosaveTimer();
		sidebarOpen = false;
		editingId = null;
		sidebarDirty = false;
		sidebarBaselineSnapshot = '';
		lastSidebarSnapshot = '';
		autosaveErrorShown = false;
		showCloseWithoutSavingModal = false;
	}

	function requestCloseSidebar() {
		if (props.readOnly) {
			performCloseSidebar();
			return;
		}
		if (!refreshSidebarDirty()) {
			performCloseSidebar();
			return;
		}
		showCloseWithoutSavingModal = true;
	}

	function cancelCloseWithoutSaving() {
		showCloseWithoutSavingModal = false;
	}

	function confirmCloseWithoutSaving() {
		performCloseSidebar();
	}

	async function save(source: 'manual' | 'autosave' = 'manual') {
		if (props.readOnly || sidebarSaving || !sidebarOpen) return;
		const showToast = source === 'manual';
		if (!validateForm(showToast)) return;

		sidebarSaving = true;
		const currentId = editingId;
		const endpoint = currentId
			? `/api/obras/${props.obraId}/secuencias/${currentId}`
			: `/api/obras/${props.obraId}/secuencias`;
		const method = currentId ? 'PATCH' : 'POST';

		const response = await fetch(endpoint, {
			method,
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify(form)
		});
		sidebarSaving = false;

		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			const message = body.message ?? 'No se pudo guardar la secuencia';
			if (source === 'manual') {
				pushToast('error', message);
			} else {
				handleAutosaveError(message);
			}
			return;
		}

		const payload = await response.json();
		const savedSecuencia = payload.secuencia as Tables<'secuencias_metricas'>;
		const savedMetroIds = (payload.metro_ids ?? []) as string[];
		const savedId = currentId ?? savedSecuencia.secuencia_id;

		if (currentId) {
			secuencias = secuencias.map((item) => (item.secuencia_id === currentId ? savedSecuencia : item));
		} else {
			secuencias = [...secuencias, savedSecuencia].sort((a, b) => a.v_ini - b.v_ini);
			editingId = savedId;
		}

		secuenciaMetros = secuenciaMetros.filter((item) => item.secuencia_id !== savedId);
		secuenciaMetros = [
			...secuenciaMetros,
			...savedMetroIds.map((metroId: string) => ({ secuencia_id: savedId, metro_id: metroId }))
		];

		form = {
			v_ini: savedSecuencia.v_ini,
			v_fin: savedSecuencia.v_fin,
			estrofa_tipo_id: savedSecuencia.estrofa_tipo_id ?? defaultEstrofa,
			inaugura_espacio: Boolean(savedSecuencia.inaugura_espacio),
			personajes_genero: savedSecuencia.personajes_genero as FormState['personajes_genero'],
			personajes_donaire: savedSecuencia.personajes_donaire as FormState['personajes_donaire'],
			personajes_sobrenatural: savedSecuencia.personajes_sobrenatural as FormState['personajes_sobrenatural'],
			estado_revision: savedSecuencia.estado_revision,
			certeza_editor: savedSecuencia.certeza_editor,
			observaciones: savedSecuencia.observaciones ?? '',
			metro_ids: [...savedMetroIds]
		};

		setSidebarBaselineFromCurrent();
		autosaveErrorShown = false;
		if (source === 'manual') {
			pushToast('success', currentId ? 'Secuencia actualizada' : 'Secuencia creada');
		}
	}

	function openDelete(secuenciaId: string) {
		if (props.readOnly) return;
		deleteTargetId = secuenciaId;
	}

	async function remove(secuenciaId: string) {
		if (props.readOnly) return;
		const response = await fetch(`/api/obras/${props.obraId}/secuencias/${secuenciaId}`, {
			method: 'DELETE'
		});
		if (!response.ok) {
			pushToast('error', 'No se pudo eliminar la secuencia');
			return;
		}
		secuencias = secuencias.filter((row) => row.secuencia_id !== secuenciaId);
		secuenciaMetros = secuenciaMetros.filter((row) => row.secuencia_id !== secuenciaId);
		if (editingId === secuenciaId) {
			performCloseSidebar();
		}
		pushToast('success', 'Secuencia eliminada');
		deleteTargetId = null;
	}

	$effect(() => {
		const open = sidebarOpen;
		const readOnly = props.readOnly;
		const saving = sidebarSaving;
		const track = `${form.v_ini}|${form.v_fin}|${form.estrofa_tipo_id}|${form.inaugura_espacio}|${form.personajes_genero}|${form.personajes_donaire}|${form.personajes_sobrenatural}|${form.estado_revision}|${form.certeza_editor}|${form.observaciones}|${form.metro_ids.join(',')}|${editingId}`;
		void track;

		if (!open || readOnly) {
			sidebarDirty = false;
			clearAutosaveTimer();
			return;
		}

		const currentSnapshot = sidebarSnapshot();
		if (currentSnapshot !== lastSidebarSnapshot) {
			lastSidebarSnapshot = currentSnapshot;
			autosaveErrorShown = false;
		}

		sidebarDirty = currentSnapshot !== sidebarBaselineSnapshot;
		if (!sidebarDirty) {
			clearAutosaveTimer();
			return;
		}

		if (saving) return;

		if (!validateForm(false)) {
			clearAutosaveTimer();
			return;
		}

		clearAutosaveTimer();
		autosaveTimer = setTimeout(() => {
			void save('autosave');
		}, 10_000);
	});

	onDestroy(() => {
		clearAutosaveTimer();
	});
</script>

<section class="space-y-4">
	<div class="flex items-end justify-between gap-4">
		<div>
			<h2 class="text-xl font-semibold">Secuencias metricas</h2>
			<p class="text-sm text-[color:var(--muted-foreground)]">Ordenadas por verso inicial.</p>
		</div>
	</div>

	<div class="card grid gap-3 p-4 md:grid-cols-3">
		<label class="text-sm">
			<span class="mb-1 block">Filtro por estrofa</span>
			<select bind:value={filtroEstrofa} class="w-full rounded-md border border-[color:var(--border)] px-3 py-2">
				<option value="">Todas</option>
				{#each props.estrofaOptions as opt}
					<option value={opt.termino_id}>{opt.termino}</option>
				{/each}
			</select>
		</label>
		<label class="text-sm">
			<span class="mb-1 block">Filtro por estado</span>
			<select bind:value={filtroEstado} class="w-full rounded-md border border-[color:var(--border)] px-3 py-2">
				<option value="">Todos</option>
				{#each props.estadoRevisionOptions as opt}
					<option value={opt.termino_id}>{opt.termino}</option>
				{/each}
			</select>
		</label>
		<label class="text-sm">
			<span class="mb-1 block">Filtro por certeza</span>
			<select bind:value={filtroCerteza} class="w-full rounded-md border border-[color:var(--border)] px-3 py-2">
				<option value="">Todas</option>
				{#each props.certezaOptions as opt}
					<option value={opt.termino_id}>{opt.termino}</option>
				{/each}
			</select>
		</label>
	</div>

	<div class="card overflow-x-auto">
		<table class="min-w-full text-left text-sm">
			<thead class="bg-[color:var(--muted)]">
				<tr>
					<th class="px-3 py-2">#</th>
					<th class="px-3 py-2">V_ini</th>
					<th class="px-3 py-2">V_fin</th>
					<th class="px-3 py-2">N_versos</th>
					<th class="px-3 py-2">Estrofa</th>
					<th class="px-3 py-2">Metros</th>
					<th class="px-3 py-2">Certeza</th>
					<th class="px-3 py-2">Estado</th>
					<th class="px-3 py-2">Acciones</th>
				</tr>
			</thead>
			<tbody>
				{#if filteredSecuencias.length === 0}
					<tr>
						<td class="px-3 py-4 text-[color:var(--muted-foreground)]" colspan={9}>
							Sin secuencias para este filtro.
						</td>
					</tr>
				{:else}
					{#each filteredSecuencias as secuencia, idx}
						<tr class="border-t border-[color:var(--border)]">
							<td class="px-3 py-2">{idx + 1}</td>
							<td class="px-3 py-2">{secuencia.v_ini}</td>
							<td class="px-3 py-2">{secuencia.v_fin}</td>
							<td class="px-3 py-2">{secuencia.n_versos}</td>
							<td class="px-3 py-2">{termById(props.estrofaOptions, secuencia.estrofa_tipo_id)}</td>
							<td class="px-3 py-2">
								{metrosForSecuencia(secuencia.secuencia_id)
									.map((id) => termById(props.metroOptions, id))
									.join(', ')}
							</td>
							<td class="px-3 py-2">{termById(props.certezaOptions, secuencia.certeza_editor)}</td>
							<td class="px-3 py-2">{termById(props.estadoRevisionOptions, secuencia.estado_revision)}</td>
							<td class="px-3 py-2">
								<div class="flex gap-2">
									<Button
										variant="ghost"
										onclick={() => openEdit(secuencia)}
										disabled={props.readOnly && !props.canComment}
										>{props.readOnly ? 'Ver' : 'Editar'}</Button
									>
									<Button variant="danger" onclick={() => openDelete(secuencia.secuencia_id)} disabled={props.readOnly}
										>Eliminar</Button
									>
								</div>
							</td>
						</tr>
					{/each}
				{/if}
			</tbody>
		</table>
	</div>

	<div class="flex justify-start">
		<Button variant="secondary" onclick={openNew} disabled={props.readOnly}>Nueva secuencia</Button>
	</div>
</section>

{#if sidebarOpen}
	<aside class="fixed right-0 top-0 z-40 h-screen w-full max-w-xl overflow-y-auto border-l border-[color:var(--border)] bg-[color:var(--gray-50)] p-5">
		<div class="sticky top-0 z-10 mb-4 flex items-center justify-between gap-3 bg-[color:var(--gray-50)] pb-3">
			<h3 class="text-lg font-semibold">
				{#if editingId}
					{props.readOnly ? 'Ver secuencia' : 'Editar secuencia'}
				{:else}
					Nueva secuencia
				{/if}
			</h3>
			<div class="flex items-center gap-2">
				<Button variant="secondary" onclick={requestCloseSidebar}>Cerrar</Button>
				{#if !props.readOnly}
					<Button variant="success" onclick={() => void save('manual')} disabled={sidebarSaving}>
						{sidebarSaving ? 'Guardando...' : 'Guardar'}
					</Button>
				{/if}
			</div>
		</div>

		<div class="grid gap-3">
			<div class="grid gap-3 sm:grid-cols-2">
				<label class="text-sm">
					<span class="mb-1 block">Verso inicial</span>
					<input
						type="number"
						bind:value={form.v_ini}
						disabled={props.readOnly}
						class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					/>
				</label>
				<label class="text-sm">
					<span class="mb-1 block">Verso final</span>
					<input
						type="number"
						bind:value={form.v_fin}
						disabled={props.readOnly}
						class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					/>
				</label>
			</div>

			<label class="text-sm">
				<span class="mb-1 block">Estrofa *</span>
				<select
					bind:value={form.estrofa_tipo_id}
					disabled={props.readOnly}
					class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
				>
					{#each props.estrofaOptions as opt}
						<option value={opt.termino_id}>{opt.termino}</option>
					{/each}
				</select>
			</label>

			<div class="border border-[color:var(--border)] bg-white p-3">
				<div class="mb-2 text-sm font-medium">Metros *</div>
				<div class="grid gap-1 sm:grid-cols-2">
					{#each props.metroOptions as metro}
						<label class="flex items-center gap-2 text-sm">
							<input
								type="checkbox"
								checked={form.metro_ids.includes(metro.termino_id)}
								disabled={props.readOnly}
								onchange={() => toggleMetro(metro.termino_id)}
							/>
							{metro.termino}
						</label>
					{/each}
				</div>
			</div>

			<div class="grid gap-3 sm:grid-cols-2">
				<label class="text-sm">
					<span class="mb-1 block">Personajes genero</span>
					<select
						bind:value={form.personajes_genero}
						disabled={props.readOnly}
						class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					>
						<option value="mixto">mixto</option>
						<option value="solo_masculino">solo_masculino</option>
						<option value="solo_femenino">solo_femenino</option>
					</select>
				</label>
				<label class="text-sm">
					<span class="mb-1 block">Donaire</span>
					<select
						bind:value={form.personajes_donaire}
						disabled={props.readOnly}
						class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					>
						<option value="ausente">ausente</option>
						<option value="solo">solo</option>
						<option value="con_otros">con_otros</option>
					</select>
				</label>
				<label class="text-sm">
					<span class="mb-1 block">Sobrenatural</span>
					<select
						bind:value={form.personajes_sobrenatural}
						disabled={props.readOnly}
						class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					>
						<option value="ausente">ausente</option>
						<option value="solo">solo</option>
						<option value="con_otros">con_otros</option>
					</select>
				</label>
				<label class="text-sm">
					<span class="mb-1 block">Estado revision</span>
					<select
						bind:value={form.estado_revision}
						disabled={props.readOnly}
						class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					>
						{#each props.estadoRevisionOptions as opt}
							<option value={opt.termino_id}>{opt.termino}</option>
						{/each}
					</select>
				</label>
				<label class="text-sm sm:col-span-2">
					<span class="mb-1 block">Certeza</span>
					<select
						bind:value={form.certeza_editor}
						disabled={props.readOnly}
						class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					>
						{#each props.certezaOptions as opt}
							<option value={opt.termino_id}>{opt.termino}</option>
						{/each}
					</select>
				</label>
			</div>

			<label class="text-sm">
				<span class="mb-1 block">Observaciones publicas</span>
				<textarea
					rows={3}
					bind:value={form.observaciones}
					disabled={props.readOnly}
					class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
				></textarea>
			</label>
		</div>

		{#if editingId}
			<div class="mt-4">
				{#key editingId}
					<InternalCommentsPanel
						obraId={props.obraId}
						canComment={Boolean(props.canComment)}
						title="Comentarios internos de secuencia"
						context={{ secuencia_id: editingId }}
						collapsible={true}
						defaultCollapsed={true}
						collapseLabel="Ver comentarios"
					/>
				{/key}
			</div>
		{/if}
	</aside>
{/if}

{#if deleteTargetId}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
		<div class="card w-full max-w-md p-5">
			<h3 class="text-lg font-semibold">Eliminar secuencia</h3>
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">Esta accion no se puede deshacer.</p>
			<div class="mt-4 flex justify-end gap-2">
				<Button variant="secondary" onclick={() => (deleteTargetId = null)}>Cancelar</Button>
				<Button
					variant="danger"
					disabled={props.readOnly}
					onclick={() => {
						if (!deleteTargetId) return;
						void remove(deleteTargetId);
					}}
				>
					Eliminar
				</Button>
			</div>
		</div>
	</div>
{/if}

{#if showCloseWithoutSavingModal}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
		<div class="card w-full max-w-md p-5">
			<h3 class="text-lg font-semibold">Cambios sin guardar</h3>
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">Hay cambios sin guardar en este panel.</p>
			<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">Si continuas, perderas los cambios no guardados.</p>
			<div class="mt-4 flex justify-end gap-2">
				<Button variant="secondary" onclick={cancelCloseWithoutSaving}>Seguir editando</Button>
				<Button variant="danger" onclick={confirmCloseWithoutSaving}>Cerrar sin guardar</Button>
			</div>
		</div>
	</div>
{/if}
