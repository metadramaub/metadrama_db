<script lang="ts">
	import type { Tables } from '$lib/types/database.types';
	import Button from '$lib/components/ui/button.svelte';
	import { pushToast } from '$lib/stores/toast';

	const props = $props<{
		obraId: string;
		jornadasInitial: Tables<'jornadas'>[];
		cuadrosInitial: Tables<'cuadros'>[];
		certezaOptions: Array<Pick<Tables<'vocabularios'>, 'termino_id' | 'termino'>>;
		readOnly?: boolean;
		canComment?: boolean;
	}>();

	let jornadas = $state([...props.jornadasInitial]);
	let cuadros = $state([...props.cuadrosInitial]);
	const defaultCerteza = props.certezaOptions.at(0)?.termino_id ?? '';

	type SidebarMode = 'jornada-new' | 'jornada-edit' | 'cuadro-new' | 'cuadro-edit' | null;
	type DeleteTarget = {
		kind: 'jornada' | 'cuadro';
		id: string;
		title: string;
		description: string;
	};
	type CommentTarget = {
		kind: 'jornada' | 'cuadro';
		id: string;
		label: string;
	};

	let sidebarMode = $state<SidebarMode>(null);
	let editingJornadaId = $state<string | null>(null);
	let editingCuadroId = $state<string | null>(null);
	let deleteTarget = $state<DeleteTarget | null>(null);
	let commentTarget = $state<CommentTarget | null>(null);
	let commentType = $state<'general' | 'revision' | 'tecnico'>('general');
	let commentText = $state('');
	let commentSaving = $state(false);

	let jornadaForm = $state({
		jornada_num: props.jornadasInitial.length + 1,
		v_ini: 1,
		v_fin: 2
	});

	let cuadroForm = $state({
		jornada_id: props.jornadasInitial[0]?.jornada_id ?? '',
		cuadro_num: 1,
		v_ini: props.jornadasInitial[0]?.v_ini ?? 1,
		v_fin: props.jornadasInitial[0]?.v_fin ?? 2,
		descripcion: '',
		certeza_editor: defaultCerteza
	});

	function sortByVIni<T extends { v_ini: number }>(items: T[]): T[] {
		return [...items].sort((a, b) => a.v_ini - b.v_ini);
	}

	function getJornadaById(jornadaId: string) {
		return jornadas.find((item) => item.jornada_id === jornadaId) ?? null;
	}

	function getCuadros(jornadaId: string) {
		return sortByVIni(cuadros.filter((item) => item.jornada_id === jornadaId));
	}

	function resetJornadaForm() {
		jornadaForm = {
			jornada_num: jornadas.length + 1,
			v_ini: 1,
			v_fin: 2
		};
	}

	function resetCuadroForm(jornadaId?: string) {
		const selectedJornadaId = jornadaId ?? jornadas[0]?.jornada_id ?? '';
		const selectedJornada = getJornadaById(selectedJornadaId);
		cuadroForm = {
			jornada_id: selectedJornadaId,
			cuadro_num: selectedJornadaId ? getCuadros(selectedJornadaId).length + 1 : 1,
			v_ini: selectedJornada?.v_ini ?? 1,
			v_fin: selectedJornada?.v_fin ?? 2,
			descripcion: '',
			certeza_editor: defaultCerteza
		};
	}

	function onCuadroJornadaChange(nextJornadaId: string) {
		const nextJornada = getJornadaById(nextJornadaId);
		cuadroForm = {
			...cuadroForm,
			jornada_id: nextJornadaId,
			cuadro_num: nextJornadaId ? getCuadros(nextJornadaId).length + 1 : 1,
			v_ini: nextJornada?.v_ini ?? cuadroForm.v_ini,
			v_fin: nextJornada?.v_fin ?? cuadroForm.v_fin
		};
	}

	function openNewJornada() {
		if (props.readOnly) return;
		editingJornadaId = null;
		resetJornadaForm();
		sidebarMode = 'jornada-new';
	}

	function openEditJornada(jornada: Tables<'jornadas'>) {
		if (props.readOnly) return;
		editingJornadaId = jornada.jornada_id;
		jornadaForm = {
			jornada_num: jornada.jornada_num,
			v_ini: jornada.v_ini,
			v_fin: jornada.v_fin
		};
		sidebarMode = 'jornada-edit';
	}

	function openNewCuadro(jornada: Tables<'jornadas'>) {
		if (props.readOnly) return;
		editingCuadroId = null;
		resetCuadroForm(jornada.jornada_id);
		sidebarMode = 'cuadro-new';
	}

	function openEditCuadro(cuadro: Tables<'cuadros'>) {
		if (props.readOnly) return;
		editingCuadroId = cuadro.cuadro_id;
		cuadroForm = {
			jornada_id: cuadro.jornada_id,
			cuadro_num: cuadro.cuadro_num,
			v_ini: cuadro.v_ini,
			v_fin: cuadro.v_fin,
			descripcion: cuadro.descripcion ?? '',
			certeza_editor: cuadro.certeza_editor
		};
		sidebarMode = 'cuadro-edit';
	}

	function closeSidebar() {
		sidebarMode = null;
		editingJornadaId = null;
		editingCuadroId = null;
	}

	function openDeleteJornada(jornada: Tables<'jornadas'>) {
		if (props.readOnly) return;
		deleteTarget = {
			kind: 'jornada',
			id: jornada.jornada_id,
			title: `Eliminar Jornada ${jornada.jornada_num}`,
			description: 'Se eliminaran tambien los cuadros asociados.'
		};
	}

	function openDeleteCuadro(cuadro: Tables<'cuadros'>) {
		if (props.readOnly) return;
		deleteTarget = {
			kind: 'cuadro',
			id: cuadro.cuadro_id,
			title: `Eliminar Cuadro ${cuadro.cuadro_num}`,
			description: 'Esta accion no se puede deshacer.'
		};
	}

	function openCommentForJornada(jornada: Tables<'jornadas'>) {
		if (!props.canComment) return;
		commentTarget = {
			kind: 'jornada',
			id: jornada.jornada_id,
			label: `Jornada ${jornada.jornada_num} (vv. ${jornada.v_ini}-${jornada.v_fin})`
		};
		commentType = 'general';
		commentText = '';
	}

	function openCommentForCuadro(cuadro: Tables<'cuadros'>) {
		if (!props.canComment) return;
		commentTarget = {
			kind: 'cuadro',
			id: cuadro.cuadro_id,
			label: `Cuadro ${cuadro.cuadro_num} (vv. ${cuadro.v_ini}-${cuadro.v_fin})`
		};
		commentType = 'general';
		commentText = '';
	}

	function parseJornadaPayload() {
		return {
			jornada_num: Number(jornadaForm.jornada_num),
			v_ini: Number(jornadaForm.v_ini),
			v_fin: Number(jornadaForm.v_fin)
		};
	}

	function parseCuadroPayload() {
		return {
			jornada_id: cuadroForm.jornada_id,
			cuadro_num: Number(cuadroForm.cuadro_num),
			v_ini: Number(cuadroForm.v_ini),
			v_fin: Number(cuadroForm.v_fin),
			descripcion: cuadroForm.descripcion.trim() || null,
			certeza_editor: cuadroForm.certeza_editor
		};
	}

	function validateJornadaForm() {
		const payload = parseJornadaPayload();
		if (!Number.isFinite(payload.jornada_num) || payload.jornada_num < 1) {
			pushToast('error', 'Jornada invalida');
			return false;
		}
		if (!Number.isFinite(payload.v_ini) || !Number.isFinite(payload.v_fin) || payload.v_ini >= payload.v_fin) {
			pushToast('error', 'Rango de versos invalido');
			return false;
		}
		return true;
	}

	function validateCuadroForm() {
		const payload = parseCuadroPayload();
		if (!payload.jornada_id) {
			pushToast('error', 'Selecciona una jornada');
			return false;
		}
		if (!payload.certeza_editor) {
			pushToast('error', 'Selecciona certeza');
			return false;
		}
		if (!Number.isFinite(payload.cuadro_num) || payload.cuadro_num < 1) {
			pushToast('error', 'Cuadro invalido');
			return false;
		}
		if (!Number.isFinite(payload.v_ini) || !Number.isFinite(payload.v_fin) || payload.v_ini >= payload.v_fin) {
			pushToast('error', 'Rango de versos invalido');
			return false;
		}
		return true;
	}

	async function saveJornada() {
		if (props.readOnly) return;
		if (!validateJornadaForm()) return;
		const payload = parseJornadaPayload();
		const endpoint = editingJornadaId
			? `/api/obras/${props.obraId}/estructura/jornadas/${editingJornadaId}`
			: `/api/obras/${props.obraId}/estructura/jornadas`;
		const method = editingJornadaId ? 'PATCH' : 'POST';

		const response = await fetch(endpoint, {
			method,
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify(payload)
		});
		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo guardar la jornada');
			return;
		}

		const result = await response.json();
		if (editingJornadaId) {
			jornadas = sortByVIni(
				jornadas.map((item) => (item.jornada_id === editingJornadaId ? result.jornada : item))
			);
			pushToast('success', 'Jornada actualizada');
		} else {
			jornadas = sortByVIni([...jornadas, result.jornada]);
			pushToast('success', 'Jornada creada');
		}
		closeSidebar();
	}

	async function saveCuadro() {
		if (props.readOnly) return;
		if (!validateCuadroForm()) return;
		const payload = parseCuadroPayload();
		const endpoint = editingCuadroId
			? `/api/obras/${props.obraId}/estructura/cuadros/${editingCuadroId}`
			: `/api/obras/${props.obraId}/estructura/cuadros`;
		const method = editingCuadroId ? 'PATCH' : 'POST';

		const response = await fetch(endpoint, {
			method,
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify(payload)
		});
		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo guardar el cuadro');
			return;
		}

		const result = await response.json();
		if (editingCuadroId) {
			cuadros = sortByVIni(
				cuadros.map((item) => (item.cuadro_id === editingCuadroId ? result.cuadro : item))
			);
			pushToast('success', 'Cuadro actualizado');
		} else {
			cuadros = sortByVIni([...cuadros, result.cuadro]);
			pushToast('success', 'Cuadro creado');
		}
		closeSidebar();
	}

	async function saveSidebar() {
		if (sidebarMode === 'jornada-new' || sidebarMode === 'jornada-edit') {
			await saveJornada();
			return;
		}
		await saveCuadro();
	}

	async function confirmDelete() {
		if (props.readOnly) return;
		if (!deleteTarget) return;
		const target = deleteTarget;

		if (target.kind === 'jornada') {
			const response = await fetch(`/api/obras/${props.obraId}/estructura/jornadas/${target.id}`, {
				method: 'DELETE'
			});
			if (!response.ok) {
				const body = await response.json().catch(() => ({}));
				pushToast('error', body.message ?? 'No se pudo eliminar la jornada');
				return;
			}
			jornadas = jornadas.filter((item) => item.jornada_id !== target.id);
			cuadros = cuadros.filter((item) => item.jornada_id !== target.id);
			pushToast('success', 'Jornada eliminada');
		} else {
			const response = await fetch(`/api/obras/${props.obraId}/estructura/cuadros/${target.id}`, {
				method: 'DELETE'
			});
			if (!response.ok) {
				const body = await response.json().catch(() => ({}));
				pushToast('error', body.message ?? 'No se pudo eliminar el cuadro');
				return;
			}
			cuadros = cuadros.filter((item) => item.cuadro_id !== target.id);
			pushToast('success', 'Cuadro eliminado');
		}

		deleteTarget = null;
	}

	async function submitComment() {
		if (!props.canComment) return;
		if (!commentTarget || commentSaving) return;
		if (!commentText.trim()) {
			pushToast('error', 'Escribe un comentario interno antes de guardar.');
			return;
		}
		commentSaving = true;
		const contextPayload =
			commentTarget.kind === 'jornada'
				? { jornada_id: commentTarget.id }
				: { cuadro_id: commentTarget.id };
		const response = await fetch(`/api/obras/${props.obraId}/comentarios`, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({
				comentario: commentText.trim(),
				tipo_comentario: commentType,
				...contextPayload
			})
		});
		commentSaving = false;
		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo guardar el comentario interno.');
			return;
		}
		pushToast('success', 'Comentario interno guardado');
		commentTarget = null;
		commentText = '';
	}
</script>

<section class="space-y-4">
	<div class="flex items-center justify-between">
		<h2 class="text-xl font-semibold">Jornadas y cuadros</h2>
		<Button variant="secondary" onclick={openNewJornada} disabled={props.readOnly}>Anadir jornada</Button>
	</div>

	{#each sortByVIni(jornadas) as jornada}
		<article class="card p-4">
			<div class="mb-3 flex items-center justify-between gap-2">
				<h3 class="text-lg font-semibold">
					Jornada {jornada.jornada_num} (vv. {jornada.v_ini}-{jornada.v_fin})
				</h3>
				<div class="flex gap-2">
					<Button variant="ghost" onclick={() => openEditJornada(jornada)} disabled={props.readOnly}
						>Editar</Button
					>
					<Button
						variant="ghost"
						onclick={() => openCommentForJornada(jornada)}
						disabled={!props.canComment}
						>Comentar</Button
					>
					<Button variant="danger" onclick={() => openDeleteJornada(jornada)} disabled={props.readOnly}
						>Eliminar</Button
					>
				</div>
			</div>

			<div class="mb-2 flex items-center justify-between">
				<div class="text-xs uppercase tracking-wide text-[color:var(--muted-foreground)]">Cuadros</div>
				<Button variant="secondary" onclick={() => openNewCuadro(jornada)} disabled={props.readOnly}
					>Anadir cuadro</Button
				>
			</div>

			<div class="space-y-2">
				{#if getCuadros(jornada.jornada_id).length === 0}
					<p class="text-sm text-[color:var(--muted-foreground)]">Sin cuadros en esta jornada.</p>
				{:else}
					{#each getCuadros(jornada.jornada_id) as cuadro}
						<div class="rounded-md border border-[color:var(--border)] bg-white p-3">
							<div class="flex items-start justify-between gap-2">
								<div>
									<div class="font-medium">
										Cuadro {cuadro.cuadro_num}: vv. {cuadro.v_ini}-{cuadro.v_fin}
									</div>
									{#if cuadro.descripcion}
										<div class="mt-1 text-sm text-[color:var(--muted-foreground)]">{cuadro.descripcion}</div>
									{/if}
								</div>
								<div class="flex gap-2">
									<Button variant="ghost" onclick={() => openEditCuadro(cuadro)} disabled={props.readOnly}
										>Editar</Button
									>
									<Button
										variant="ghost"
										onclick={() => openCommentForCuadro(cuadro)}
										disabled={!props.canComment}
										>Comentar</Button
									>
									<Button variant="danger" onclick={() => openDeleteCuadro(cuadro)} disabled={props.readOnly}
										>Eliminar</Button
									>
								</div>
							</div>
						</div>
					{/each}
				{/if}
			</div>
		</article>
	{/each}
</section>

{#if sidebarMode}
	<aside class="fixed right-0 top-0 z-40 h-screen w-full max-w-xl overflow-y-auto border-l border-[color:var(--border)] bg-[#fffaf4] p-5 shadow-xl">
		<div class="mb-4 flex items-center justify-between">
			<h3 class="text-lg font-semibold">
				{#if sidebarMode === 'jornada-new'}Nueva jornada{/if}
				{#if sidebarMode === 'jornada-edit'}Editar jornada{/if}
				{#if sidebarMode === 'cuadro-new'}Nuevo cuadro{/if}
				{#if sidebarMode === 'cuadro-edit'}Editar cuadro{/if}
			</h3>
			<Button variant="ghost" onclick={closeSidebar}>Cerrar</Button>
		</div>

		<div class="grid gap-3">
			{#if sidebarMode === 'jornada-new' || sidebarMode === 'jornada-edit'}
				<div class="grid gap-3 sm:grid-cols-3">
					<label class="text-sm">
						<span class="mb-1 block">Jornada #</span>
						<input
							type="number"
							bind:value={jornadaForm.jornada_num}
							min="1"
							disabled={props.readOnly}
							class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
						/>
					</label>
					<label class="text-sm">
						<span class="mb-1 block">Verso inicial</span>
						<input
							type="number"
							bind:value={jornadaForm.v_ini}
							disabled={props.readOnly}
							class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
						/>
					</label>
					<label class="text-sm">
						<span class="mb-1 block">Verso final</span>
						<input
							type="number"
							bind:value={jornadaForm.v_fin}
							disabled={props.readOnly}
							class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
						/>
					</label>
				</div>
			{:else}
				<label class="text-sm">
					<span class="mb-1 block">Jornada</span>
					<select
						bind:value={cuadroForm.jornada_id}
						disabled={props.readOnly}
						onchange={(event) => onCuadroJornadaChange((event.currentTarget as HTMLSelectElement).value)}
						class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					>
						{#each sortByVIni(jornadas) as jornada}
							<option value={jornada.jornada_id}>
								Jornada {jornada.jornada_num} (vv. {jornada.v_ini}-{jornada.v_fin})
							</option>
						{/each}
					</select>
				</label>
				<div class="grid gap-3 sm:grid-cols-3">
					<label class="text-sm">
						<span class="mb-1 block">Cuadro #</span>
						<input
							type="number"
							bind:value={cuadroForm.cuadro_num}
							min="1"
							disabled={props.readOnly}
							class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
						/>
					</label>
					<label class="text-sm">
						<span class="mb-1 block">Verso inicial</span>
						<input
							type="number"
							bind:value={cuadroForm.v_ini}
							disabled={props.readOnly}
							class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
						/>
					</label>
					<label class="text-sm">
						<span class="mb-1 block">Verso final</span>
						<input
							type="number"
							bind:value={cuadroForm.v_fin}
							disabled={props.readOnly}
							class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
						/>
					</label>
				</div>
				<label class="text-sm">
					<span class="mb-1 block">Certeza</span>
					<select
						bind:value={cuadroForm.certeza_editor}
						disabled={props.readOnly}
						class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					>
						{#each props.certezaOptions as option}
							<option value={option.termino_id}>{option.termino}</option>
						{/each}
					</select>
				</label>
				<label class="text-sm">
					<span class="mb-1 block">Descripcion</span>
					<textarea
						rows={3}
						bind:value={cuadroForm.descripcion}
						disabled={props.readOnly}
						class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					></textarea>
				</label>
			{/if}
		</div>

		<div class="mt-4 flex justify-end gap-2">
			<Button variant="ghost" onclick={closeSidebar}>Cancelar</Button>
			<Button onclick={saveSidebar} disabled={props.readOnly}>Guardar</Button>
		</div>
	</aside>
{/if}

{#if deleteTarget}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
		<div class="card w-full max-w-md p-5">
			<h3 class="text-lg font-semibold">{deleteTarget.title}</h3>
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">{deleteTarget.description}</p>
			<div class="mt-4 flex justify-end gap-2">
				<Button variant="ghost" onclick={() => (deleteTarget = null)}>Cancelar</Button>
				<Button variant="danger" onclick={confirmDelete} disabled={props.readOnly}>Eliminar</Button>
			</div>
		</div>
	</div>
{/if}

{#if commentTarget}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
		<div class="card w-full max-w-xl p-5">
			<h3 class="text-lg font-semibold">Comentario interno</h3>
			<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">{commentTarget.label}</p>

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
				<Button variant="ghost" onclick={() => (commentTarget = null)}>Cancelar</Button>
				<Button onclick={submitComment} disabled={commentSaving || !props.canComment}>
					{commentSaving ? 'Guardando...' : 'Guardar comentario'}
				</Button>
			</div>
		</div>
	</div>
{/if}
