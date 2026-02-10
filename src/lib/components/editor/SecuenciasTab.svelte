<script lang="ts">
	import type { Tables } from '$lib/types/database.types';
	import Button from '$lib/components/ui/button.svelte';
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
	let commentTargetId = $state<string | null>(null);
	let commentType = $state<'general' | 'revision' | 'tecnico'>('general');
	let commentText = $state('');
	let commentSaving = $state(false);

	const defaultEstado = props.estadoRevisionOptions[0]?.termino_id ?? '';
	const defaultCerteza = props.certezaOptions[0]?.termino_id ?? '';
	const defaultEstrofa = props.estrofaOptions[0]?.termino_id ?? '';

	let form = $state<FormState>({
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
	});

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

	function openNew() {
		if (props.readOnly) return;
		editingId = null;
		form = {
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
		sidebarOpen = true;
	}

	function openEdit(secuencia: Tables<'secuencias_metricas'>) {
		if (props.readOnly) return;
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
	}

	function toggleMetro(metroId: string) {
		if (props.readOnly) return;
		if (form.metro_ids.includes(metroId)) {
			form = { ...form, metro_ids: form.metro_ids.filter((id) => id !== metroId) };
			return;
		}
		form = { ...form, metro_ids: [...form.metro_ids, metroId] };
	}

	async function save() {
		if (props.readOnly) return;
		const endpoint = editingId
			? `/api/obras/${props.obraId}/secuencias/${editingId}`
			: `/api/obras/${props.obraId}/secuencias`;
		const method = editingId ? 'PATCH' : 'POST';

		const response = await fetch(endpoint, {
			method,
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify(form)
		});
		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo guardar la secuencia');
			return;
		}

		const payload = await response.json();
		if (editingId) {
			secuencias = secuencias.map((item) => (item.secuencia_id === editingId ? payload.secuencia : item));
			secuenciaMetros = secuenciaMetros.filter((item) => item.secuencia_id !== editingId);
			secuenciaMetros = [
				...secuenciaMetros,
				...payload.metro_ids.map((metroId: string) => ({ secuencia_id: editingId, metro_id: metroId }))
			];
			pushToast('success', 'Secuencia actualizada');
		} else {
			secuencias = [...secuencias, payload.secuencia].sort((a, b) => a.v_ini - b.v_ini);
			secuenciaMetros = [
				...secuenciaMetros,
				...payload.metro_ids.map((metroId: string) => ({
					secuencia_id: payload.secuencia.secuencia_id,
					metro_id: metroId
				}))
			];
			pushToast('success', 'Secuencia creada');
		}

		sidebarOpen = false;
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
		pushToast('success', 'Secuencia eliminada');
		deleteTargetId = null;
	}

	function openComment(secuenciaId: string) {
		if (!props.canComment) return;
		commentTargetId = secuenciaId;
		commentType = 'general';
		commentText = '';
	}

	function commentTargetLabel() {
		if (!commentTargetId) return '';
		const secuencia = secuencias.find((item) => item.secuencia_id === commentTargetId);
		if (!secuencia) return 'Secuencia';
		return `Secuencia vv. ${secuencia.v_ini}-${secuencia.v_fin}`;
	}

	async function saveComment() {
		if (!props.canComment) return;
		if (!commentTargetId || commentSaving) return;
		if (!commentText.trim()) {
			pushToast('error', 'Escribe un comentario interno.');
			return;
		}
		commentSaving = true;
		const response = await fetch(`/api/obras/${props.obraId}/comentarios`, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({
				comentario: commentText.trim(),
				tipo_comentario: commentType,
				secuencia_id: commentTargetId
			})
		});
		commentSaving = false;
		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo guardar el comentario.');
			return;
		}
		pushToast('success', 'Comentario interno guardado');
		commentTargetId = null;
		commentText = '';
	}
</script>

<section class="space-y-4">
	<div class="flex items-end justify-between gap-4">
		<div>
			<h2 class="text-xl font-semibold">Secuencias metricas</h2>
			<p class="text-sm text-[color:var(--muted-foreground)]">Ordenadas por verso inicial.</p>
		</div>
		<Button onclick={openNew} disabled={props.readOnly}>Nueva secuencia</Button>
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
									<Button variant="ghost" onclick={() => openEdit(secuencia)} disabled={props.readOnly}
										>Editar</Button
									>
									<Button
										variant="ghost"
										onclick={() => openComment(secuencia.secuencia_id)}
										disabled={!props.canComment}
										>Comentar</Button
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
</section>

{#if sidebarOpen}
	<aside class="fixed right-0 top-0 z-40 h-screen w-full max-w-xl overflow-y-auto border-l border-[color:var(--border)] bg-[#fffaf4] p-5 shadow-xl">
		<div class="mb-4 flex items-center justify-between">
			<h3 class="text-lg font-semibold">
				{#if editingId}Editar secuencia{:else}Nueva secuencia{/if}
			</h3>
			<Button variant="ghost" onclick={() => (sidebarOpen = false)}>Cerrar</Button>
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

			<div class="rounded-md border border-[color:var(--border)] bg-white p-3">
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

		<div class="mt-4 flex justify-end gap-2">
			<Button variant="ghost" onclick={() => (sidebarOpen = false)}>Cancelar</Button>
			<Button onclick={save} disabled={props.readOnly}>Guardar</Button>
		</div>
	</aside>
{/if}

{#if deleteTargetId}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
		<div class="card w-full max-w-md p-5">
			<h3 class="text-lg font-semibold">Eliminar secuencia</h3>
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">Esta accion no se puede deshacer.</p>
			<div class="mt-4 flex justify-end gap-2">
				<Button variant="ghost" onclick={() => (deleteTargetId = null)}>Cancelar</Button>
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

{#if commentTargetId}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
		<div class="card w-full max-w-xl p-5">
			<h3 class="text-lg font-semibold">Comentario interno</h3>
			<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">{commentTargetLabel()}</p>

			<label class="mt-3 block text-sm">
				<span class="mb-1 block">Tipo</span>
				<select
					bind:value={commentType}
					disabled={!props.canComment}
					class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
				>
					<option value="general">general</option>
					<option value="revision">revision</option>
					<option value="tecnico">tecnico</option>
				</select>
			</label>

			<label class="mt-3 block text-sm">
				<span class="mb-1 block">Comentario</span>
				<textarea
					rows={4}
					bind:value={commentText}
					disabled={!props.canComment}
					class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
				></textarea>
			</label>

			<div class="mt-4 flex justify-end gap-2">
				<Button variant="ghost" onclick={() => (commentTargetId = null)}>Cancelar</Button>
				<Button onclick={saveComment} disabled={commentSaving || !props.canComment}>
					{commentSaving ? 'Guardando...' : 'Guardar comentario'}
				</Button>
			</div>
		</div>
	</div>
{/if}
