<script lang="ts">
	import { onMount } from 'svelte';
	import Button from '$lib/components/ui/button.svelte';
	import { pushToast } from '$lib/stores/toast';
	import { formatRelative } from '$lib/utils/formatters';
	import { currentObraStore, patchCurrentObra } from '$lib/stores/currentObra';
	import type { Tables } from '$lib/types/database.types';
	import type { EditorProfile, ObraAccessFlags } from '$lib/types/obra.types';

	type EstadoOption = Pick<Tables<'vocabularios'>, 'termino_id' | 'termino'>;
	type CommentType = 'general' | 'revision' | 'tecnico' | 'estado';
	type ComentarioRow = Tables<'comentarios_internos'> & {
		nombre_editor?: string;
		tipo_comentario_term?: string;
	};
	type ReviewerCandidate = {
		user_id: string;
		nombre_completo: string;
		email: string | null;
		selected: boolean;
	};
	type AssignedReviewer = {
		revisor_id: string;
		nombre_completo: string;
		email: string | null;
		created_at: string | null;
	};

	const props = $props<{
		obraId: string;
		obra: Tables<'obras'>;
		profile: EditorProfile;
		estadoTerm: string;
		estadoOptions: EstadoOption[];
		estadoRevisionOptions: EstadoOption[];
		jornadas: Tables<'jornadas'>[];
		cuadros: Tables<'cuadros'>[];
		secuencias: Tables<'secuencias_metricas'>[];
		rangos: Tables<'rangos'>[];
		editorAsignadoNombre: string | null;
		assignedReviewer: boolean;
		capabilities: ObraAccessFlags;
	}>();

	const obraLive = $derived(($currentObraStore.obra ?? props.obra) as Tables<'obras'>);

	let currentEstadoId = $state(props.obra.estado);
	let currentEstadoTerm = $state(props.estadoTerm);
	let estadoComentario = $state('');
	let visiblePublico = $state(Boolean(props.obra.visible_publico));

	let comments = $state<ComentarioRow[]>([]);
	let commentsLoading = $state(false);
	let postingComment = $state(false);
	let stateSaving = $state(false);
	let visibilitySaving = $state(false);
	let showAllComments = $state(false);
	let newComment = $state('');
	let newCommentType = $state<CommentType>('general');

	let reviewersLoading = $state(false);
	let reviewersSaving = $state(false);
	let assignedReviewers = $state<AssignedReviewer[]>([]);
	let reviewerCandidates = $state<ReviewerCandidate[]>([]);

	const canToggleVisible = $derived(Boolean(props.capabilities.canToggleVisibility));
	const canManageAssignments = $derived(Boolean(props.capabilities.canManageReviewers));
	const canComment = $derived(Boolean(props.capabilities.canComment));
	const canChangeState = $derived(Boolean(props.capabilities.canChangeState));
	const visibleComments = $derived(showAllComments ? comments : comments.slice(0, 5));

	const estadoTermById = $derived(
		new Map(
			props.estadoOptions.map((option: EstadoOption) => [
				option.termino_id,
				option.termino.trim().toLowerCase()
			])
		)
	);

	const validatedRevisionIds = $derived(
		new Set(
			props.estadoRevisionOptions
				.filter((option: EstadoOption) => option.termino.trim().toLowerCase() === 'validado')
				.map((option: EstadoOption) => option.termino_id)
		)
	);

	const checklist = $derived.by(() => {
		const secuenciasValidadas = props.secuencias.filter((item: Tables<'secuencias_metricas'>) =>
			validatedRevisionIds.has(item.estado_revision)
		).length;
		return [
			{
				label: 'Datos basicos completos',
				done: Boolean(obraLive.titulo?.trim() && obraLive.genero_id && obraLive.edicion?.trim()),
				detail: ''
			},
			{
				label: 'Estructura definida',
				done: props.jornadas.length > 0,
				detail: `${props.jornadas.length} jornadas, ${props.cuadros.length} cuadros`
			},
			{
				label: 'Secuencias metricas validadas',
				done: props.secuencias.length > 0 && secuenciasValidadas === props.secuencias.length,
				detail: `${secuenciasValidadas}/${props.secuencias.length}`
			},
			{
				label: 'Autoria asignada',
				done: (obraLive.autoria ?? []).length > 0,
				detail: `${(obraLive.autoria ?? []).length} autores`
			},
			{
				label: 'Analisis de obra',
				done: (obraLive.analisis_editor ?? '').trim().length > 100,
				detail: `${(obraLive.analisis_editor ?? '').trim().length} caracteres`
			},
			{
				label: 'Bibliografia anadida',
				done: (obraLive.bibliografia ?? '').trim().length > 0,
				detail: `${(obraLive.bibliografia ?? '').trim().length} caracteres`
			}
		];
	});

	function findEstadoIdByTerm(term: string): string | null {
		const lower = term.trim().toLowerCase();
		const found = props.estadoOptions.find(
			(option: EstadoOption) => option.termino.trim().toLowerCase() === lower
		);
		return found?.termino_id ?? null;
	}

	function commentContextLabel(comment: ComentarioRow): string | null {
		if (comment.secuencia_id) {
			const sec = props.secuencias.find(
				(item: Tables<'secuencias_metricas'>) => item.secuencia_id === comment.secuencia_id
			);
			return sec ? `Secuencia vv. ${sec.v_ini}-${sec.v_fin}` : 'Secuencia';
		}
		if (comment.cuadro_id) {
			const cua = props.cuadros.find((item: Tables<'cuadros'>) => item.cuadro_id === comment.cuadro_id);
			return cua ? `Cuadro ${cua.cuadro_num}` : 'Cuadro';
		}
		if (comment.jornada_id) {
			const jor = props.jornadas.find((item: Tables<'jornadas'>) => item.jornada_id === comment.jornada_id);
			return jor ? `Jornada ${jor.jornada_num}` : 'Jornada';
		}
		if (comment.rango_id) {
			return 'Rango de autoria';
		}
		return null;
	}

	async function loadComments() {
		commentsLoading = true;
		const response = await fetch(`/api/obras/${props.obraId}/comentarios`);
		commentsLoading = false;
		if (!response.ok) {
			pushToast('error', 'No se pudieron cargar los comentarios internos.');
			return;
		}
		const payload = await response.json();
		comments = payload.items ?? [];
	}

	async function loadReviewers() {
		reviewersLoading = true;
		const response = await fetch(`/api/obras/${props.obraId}/revisores`);
		reviewersLoading = false;
		if (!response.ok) {
			return;
		}
		const payload = await response.json();
		assignedReviewers = payload.assigned ?? [];
		reviewerCandidates = payload.candidates ?? [];
	}

	async function postInternalComment(text: string, tipo: CommentType = 'general') {
		const response = await fetch(`/api/obras/${props.obraId}/comentarios`, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ comentario: text, tipo_comentario: tipo })
		});
		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo publicar comentario.');
			return false;
		}
		await loadComments();
		return true;
	}

	async function saveEstado(targetEstadoId: string, comentario: string) {
		if (stateSaving) return;
		stateSaving = true;
		const response = await fetch(`/api/obras/${props.obraId}/estado`, {
			method: 'PATCH',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ estado: targetEstadoId, comentario: comentario.trim() || undefined })
		});
		stateSaving = false;

		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo cambiar el estado.');
			return false;
		}

		const payload = await response.json();
		currentEstadoId = payload.obra.estado;
		currentEstadoTerm = payload.estadoTerm ?? estadoTermById.get(payload.obra.estado) ?? currentEstadoTerm;
		estadoComentario = '';
		patchCurrentObra({
			estado: payload.obra.estado,
			updated_at: payload.obra.updated_at ?? obraLive.updated_at
		});
		pushToast('success', 'Estado actualizado');
		await loadComments();
		return true;
	}

	async function onGuardarEstado() {
		if (!canChangeState) return;
		await saveEstado(currentEstadoId, estadoComentario);
	}

	async function onEnviarRevision() {
		if (!canChangeState) return;
		const pendingId = findEstadoIdByTerm('pendiente');
		if (!pendingId) {
			pushToast('error', 'No existe estado pendiente en vocabularios.');
			return;
		}
		await saveEstado(pendingId, estadoComentario || 'Enviado a revision');
	}

	async function onGuardarVisibilidad() {
		if (visibilitySaving || !canToggleVisible) return;
		visibilitySaving = true;
		const response = await fetch(`/api/obras/${props.obraId}/visibilidad`, {
			method: 'PATCH',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ visible_publico: visiblePublico })
		});
		visibilitySaving = false;

		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo actualizar visibilidad.');
			return;
		}

		const payload = await response.json();
		patchCurrentObra({
			visible_publico: payload.obra.visible_publico,
			updated_at: payload.obra.updated_at ?? obraLive.updated_at
		});
		pushToast('success', 'Visibilidad actualizada');
	}

	async function onPublicarComentario() {
		if (!canComment) return;
		if (postingComment) return;
		if (!newComment.trim()) {
			pushToast('error', 'Escribe un comentario antes de publicar.');
			return;
		}
		postingComment = true;
		const ok = await postInternalComment(newComment.trim(), newCommentType);
		postingComment = false;
		if (!ok) return;
		newComment = '';
		pushToast('success', 'Comentario publicado');
	}

	function toggleReviewer(userId: string) {
		reviewerCandidates = reviewerCandidates.map((candidate) =>
			candidate.user_id === userId ? { ...candidate, selected: !candidate.selected } : candidate
		);
	}

	async function onGuardarRevisores() {
		if (!canManageAssignments || reviewersSaving) return;
		reviewersSaving = true;
		const reviewerIds = reviewerCandidates.filter((item) => item.selected).map((item) => item.user_id);
		const response = await fetch(`/api/obras/${props.obraId}/revisores`, {
			method: 'PUT',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ reviewer_ids: reviewerIds })
		});
		reviewersSaving = false;
		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudieron guardar los revisores asignados.');
			return;
		}
		const payload = await response.json();
		assignedReviewers = payload.assigned ?? [];
		reviewerCandidates = payload.candidates ?? [];
		pushToast('success', 'Asignacion de revisores actualizada');
	}

	onMount(() => {
		void loadComments();
		void loadReviewers();
	});
</script>

<section class="space-y-4">
	<div class="card p-4">
		<h3 class="mb-3 text-lg font-semibold">Checklist de completitud</h3>
		<div class="space-y-2 text-sm">
			{#each checklist as item}
				<div class="flex items-start justify-between gap-3 rounded-md border border-[color:var(--border)] bg-white px-3 py-2">
					<div>
						<span class={item.done ? 'font-medium text-[color:var(--success)]' : 'font-medium text-[color:var(--danger)]'}>
							{item.done ? '[OK]' : '[PEND]'} {item.label}
						</span>
					</div>
					{#if item.detail}
						<span class="text-[color:var(--muted-foreground)]">{item.detail}</span>
					{/if}
				</div>
			{/each}
		</div>
	</div>

	<div class="card p-4">
		<div class="mb-3 flex items-center justify-between gap-2">
			<h3 class="text-lg font-semibold">Comentarios internos</h3>
			{#if comments.length > 5}
				<Button variant="ghost" onclick={() => (showAllComments = !showAllComments)}>
					{showAllComments ? 'Ver menos' : 'Ver todos'}
				</Button>
			{/if}
		</div>
		{#if commentsLoading}
			<p class="text-sm text-[color:var(--muted-foreground)]">Cargando comentarios...</p>
		{:else if comments.length === 0}
			<p class="text-sm text-[color:var(--muted-foreground)]">No hay comentarios aun.</p>
		{:else}
			<div class="mb-3 space-y-2">
				{#each visibleComments as comment}
					<div class="rounded-md border border-[color:var(--border)] bg-white p-3 text-sm">
						<div class="mb-1 text-xs text-[color:var(--muted-foreground)]">
							{comment.nombre_editor ?? 'Editor'} - {formatRelative(comment.created_at)}
						</div>
						<div class="mb-1 flex flex-wrap gap-2">
							<span class="rounded-full bg-[color:var(--muted)] px-2 py-0.5 text-xs">
								{comment.tipo_comentario_term ?? 'general'}
							</span>
							{#if commentContextLabel(comment)}
								<span class="rounded-full bg-[#fff0d7] px-2 py-0.5 text-xs">{commentContextLabel(comment)}</span>
							{/if}
						</div>
						<div class="whitespace-pre-wrap">{comment.comentario}</div>
					</div>
				{/each}
			</div>
		{/if}

		<div class="rounded-md border border-[color:var(--border)] bg-white p-3">
			<label class="block text-sm">
				<span class="mb-1 block">Tipo de comentario</span>
				<select
					class="mb-2 w-full rounded-md border border-[color:var(--border)] px-3 py-2 text-sm"
					disabled={!canComment}
					bind:value={newCommentType}
				>
					<option value="general">general</option>
					<option value="revision">revision</option>
					<option value="tecnico">tecnico</option>
					<option value="estado">estado</option>
				</select>
			</label>
			<label class="block text-sm">
				<span class="mb-1 block">Nuevo comentario</span>
				<textarea
					rows={3}
					class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					disabled={!canComment}
					bind:value={newComment}
				></textarea>
			</label>
			<div class="mt-2 flex justify-end">
				<Button onclick={onPublicarComentario} disabled={postingComment || !canComment}>
					{postingComment ? 'Publicando...' : 'Publicar comentario'}
				</Button>
			</div>
		</div>
	</div>

	<div class="card p-4">
		<h3 class="mb-3 text-lg font-semibold">Panel de revision y asignacion</h3>
		{#if props.assignedReviewer}
			<p class="mb-2 text-sm text-[color:var(--muted-foreground)]">
				Tienes esta obra asignada para revision.
			</p>
		{/if}
		{#if reviewersLoading}
			<p class="text-sm text-[color:var(--muted-foreground)]">Cargando revisores...</p>
		{:else}
			<div class="mb-3">
				<div class="mb-2 text-sm font-medium">Revisores asignados</div>
				{#if assignedReviewers.length === 0}
					<p class="text-sm text-[color:var(--muted-foreground)]">No hay revisores asignados.</p>
				{:else}
					<ul class="space-y-1 text-sm">
						{#each assignedReviewers as reviewer}
							<li>
								{reviewer.nombre_completo}
								{#if reviewer.email}
									<span class="text-[color:var(--muted-foreground)]">({reviewer.email})</span>
								{/if}
							</li>
						{/each}
					</ul>
				{/if}
			</div>

			{#if canManageAssignments}
				<div class="rounded-md border border-[color:var(--border)] bg-white p-3">
					<div class="mb-2 text-sm font-medium">Asignar revisores</div>
					<div class="grid gap-1 sm:grid-cols-2">
						{#each reviewerCandidates as candidate}
							<label class="flex items-center gap-2 text-sm">
								<input
									type="checkbox"
									checked={candidate.selected}
									onchange={() => toggleReviewer(candidate.user_id)}
								/>
								<span>{candidate.nombre_completo}</span>
							</label>
						{/each}
					</div>
					<div class="mt-3 flex justify-end">
						<Button onclick={onGuardarRevisores} disabled={reviewersSaving}>
							{reviewersSaving ? 'Guardando...' : 'Guardar asignaciones'}
						</Button>
					</div>
				</div>
			{/if}
		{/if}
	</div>

	<div class="card p-4">
		<h2 class="mb-3 text-xl font-semibold">Estado y visibilidad</h2>
		<div class="grid gap-3 md:grid-cols-2">
			<label class="text-sm">
				<span class="mb-1 block">Estado de la obra</span>
				<select
					class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					disabled={!canChangeState}
					bind:value={currentEstadoId}
				>
					{#each props.estadoOptions as option}
						<option value={option.termino_id}>{option.termino}</option>
					{/each}
				</select>
			</label>
			<div class="rounded-md border border-[color:var(--border)] bg-white p-3 text-sm">
				<div><strong>Editor asignado:</strong> {props.editorAsignadoNombre ?? 'Sin asignar'}</div>
				<div><strong>Ultima modificacion:</strong> {formatRelative(obraLive.updated_at)}</div>
				<div><strong>Estado actual:</strong> {currentEstadoTerm}</div>
			</div>
		</div>

		<label class="mt-3 block text-sm">
			<span class="mb-1 block">Comentario de cambio de estado (opcional)</span>
			<textarea
				rows={3}
				class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
				disabled={!canChangeState}
				bind:value={estadoComentario}
			></textarea>
		</label>

		<div class="mt-3 flex flex-wrap gap-2">
			<Button onclick={onGuardarEstado} disabled={stateSaving || !canChangeState}>
				{stateSaving ? 'Guardando...' : 'Guardar estado'}
			</Button>
			{#if currentEstadoTerm === 'borrador' && canChangeState}
				<Button variant="secondary" onclick={onEnviarRevision} disabled={stateSaving || !canChangeState}>
					Enviar a revision
				</Button>
			{/if}
		</div>

		{#if canToggleVisible}
			<div class="mt-4 rounded-md border border-[color:var(--border)] bg-white p-3">
				<label class="flex items-center gap-2 text-sm">
					<input type="checkbox" bind:checked={visiblePublico} />
					Visible en web publica
				</label>
				<div class="mt-2">
					<Button variant="ghost" onclick={onGuardarVisibilidad} disabled={visibilitySaving}>
						{visibilitySaving ? 'Guardando...' : 'Guardar visibilidad'}
					</Button>
				</div>
			</div>
		{/if}
	</div>
</section>
