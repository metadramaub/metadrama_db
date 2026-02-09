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
		notas_internas: string;
		metro_ids: string[];
	};

	let secuencias = $state([...props.secuenciasInitial]);
	let secuenciaMetros = $state([...props.secuenciasMetrosInitial]);
	let sidebarOpen = $state(false);
	let editingId = $state<string | null>(null);
	let filtroEstrofa = $state('');
	let filtroEstado = $state('');
	let filtroCerteza = $state('');

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
		notas_internas: '',
		metro_ids: []
	});

	function metrosForSecuencia(secuenciaId: string): string[] {
		return secuenciaMetros
			.filter((item) => item.secuencia_id === secuenciaId)
			.map((item) => item.metro_id);
	}

	function termById(options: Array<Pick<Tables<'vocabularios'>, 'termino_id' | 'termino'>>, id: string | null) {
		if (!id) return '—';
		return options.find((option) => option.termino_id === id)?.termino ?? '—';
	}

	const filteredSecuencias = $derived.by(() => {
		return secuencias
			.filter((secuencia) => !filtroEstrofa || secuencia.estrofa_tipo_id === filtroEstrofa)
			.filter((secuencia) => !filtroEstado || secuencia.estado_revision === filtroEstado)
			.filter((secuencia) => !filtroCerteza || secuencia.certeza_editor === filtroCerteza)
			.sort((a, b) => a.v_ini - b.v_ini);
	});

	function openNew() {
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
			notas_internas: '',
			metro_ids: []
		};
		sidebarOpen = true;
	}

	function openEdit(secuencia: Tables<'secuencias_metricas'>) {
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
			notas_internas: secuencia.notas_internas ?? '',
			metro_ids: metrosForSecuencia(secuencia.secuencia_id)
		};
		sidebarOpen = true;
	}

	function toggleMetro(metroId: string) {
		if (form.metro_ids.includes(metroId)) {
			form = { ...form, metro_ids: form.metro_ids.filter((id) => id !== metroId) };
			return;
		}
		form = { ...form, metro_ids: [...form.metro_ids, metroId] };
	}

	async function save() {
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

	async function remove(secuenciaId: string) {
		if (!confirm('¿Eliminar secuencia?')) return;
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
	}
</script>

<section class="space-y-4">
	<div class="flex items-end justify-between gap-4">
		<div>
			<h2 class="text-xl font-semibold">Secuencias métricas</h2>
			<p class="text-sm text-[color:var(--muted-foreground)]">Ordenadas por verso inicial.</p>
		</div>
		<Button onclick={openNew}>Nueva secuencia</Button>
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
									<Button variant="ghost" onclick={() => openEdit(secuencia)}>Editar</Button>
									<Button variant="danger" onclick={() => remove(secuencia.secuencia_id)}>Eliminar</Button>
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
						class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					/>
				</label>
				<label class="text-sm">
					<span class="mb-1 block">Verso final</span>
					<input
						type="number"
						bind:value={form.v_fin}
						class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					/>
				</label>
			</div>

			<label class="text-sm">
				<span class="mb-1 block">Estrofa *</span>
				<select
					bind:value={form.estrofa_tipo_id}
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
								onchange={() => toggleMetro(metro.termino_id)}
							/>
							{metro.termino}
						</label>
					{/each}
				</div>
			</div>

			<div class="grid gap-3 sm:grid-cols-2">
				<label class="text-sm">
					<span class="mb-1 block">Personajes género</span>
					<select
						bind:value={form.personajes_genero}
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
						class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					>
						<option value="ausente">ausente</option>
						<option value="solo">solo</option>
						<option value="con_otros">con_otros</option>
					</select>
				</label>
				<label class="text-sm">
					<span class="mb-1 block">Estado revisión</span>
					<select
						bind:value={form.estado_revision}
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
						class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					>
						{#each props.certezaOptions as opt}
							<option value={opt.termino_id}>{opt.termino}</option>
						{/each}
					</select>
				</label>
			</div>

			<label class="text-sm">
				<span class="mb-1 block">Observaciones públicas</span>
				<textarea
					rows={3}
					bind:value={form.observaciones}
					class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
				></textarea>
			</label>
			<label class="text-sm">
				<span class="mb-1 block">Notas internas</span>
				<textarea
					rows={3}
					bind:value={form.notas_internas}
					class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
				></textarea>
			</label>
		</div>

		<div class="mt-4 flex justify-end gap-2">
			<Button variant="ghost" onclick={() => (sidebarOpen = false)}>Cancelar</Button>
			<Button onclick={save}>Guardar</Button>
		</div>
	</aside>
{/if}
