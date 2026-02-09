<script lang="ts">
	import { onMount } from 'svelte';
	import Button from '$lib/components/ui/button.svelte';
	import { pushToast } from '$lib/stores/toast';
	import { formatRelative } from '$lib/utils/formatters';
	import { currentObraStore, patchCurrentObra } from '$lib/stores/currentObra';
	import type { Tables } from '$lib/types/database.types';
	import type { EditorProfile } from '$lib/types/obra.types';

	type EstadoOption = Pick<Tables<'vocabularios'>, 'termino_id' | 'termino'>;
	type ComentarioRow = Tables<'comentarios_internos'> & { nombre_editor?: string };

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
	}>();

	const obraLive = $derived(($currentObraStore.obra ?? props.obra) as Tables<'obras'>);

	let currentEstadoId = $state(props.obra.estado);
	let currentEstadoTerm = $state(props.estadoTerm);
	let estadoComentario = $state('');
	let reviewerComentario = $state('');
	let visiblePublico = $state(Boolean(props.obra.visible_publico));

	let comments = $state<ComentarioRow[]>([]);
	let commentsLoading = $state(false);
	let postingComment = $state(false);
	let stateSaving = $state(false);
	let visibilitySaving = $state(false);
	let newComment = $state('');

	const canToggleVisible = $derived(['admin', 'ip'].includes(props.profile.roleTerm));
	const canReviewPanel = $derived(['admin', 'ip', 'revisor'].includes(props.profile.roleTerm));

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

	async function postInternalComment(text: string) {
		const response = await fetch(`/api/obras/${props.obraId}/comentarios`, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ comentario: text })
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
		await saveEstado(currentEstadoId, estadoComentario);
	}

	async function onEnviarRevision() {
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
		if (postingComment) return;
		if (!newComment.trim()) {
			pushToast('error', 'Escribe un comentario antes de publicar.');
			return;
		}
		postingComment = true;
		const ok = await postInternalComment(newComment.trim());
		postingComment = false;
		if (!ok) return;
		newComment = '';
		pushToast('success', 'Comentario publicado');
	}

	async function onPublicarRevision() {
		if (postingComment) return;
		if (!reviewerComentario.trim()) {
			pushToast('error', 'Escribe un comentario de revisor.');
			return;
		}
		postingComment = true;
		const ok = await postInternalComment(`[Revision] ${reviewerComentario.trim()}`);
		postingComment = false;
		if (!ok) return;
		reviewerComentario = '';
		pushToast('success', 'Comentario de revision publicado');
	}

	onMount(() => {
		void loadComments();
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
		<h3 class="mb-3 text-lg font-semibold">Comentarios internos</h3>
		{#if commentsLoading}
			<p class="text-sm text-[color:var(--muted-foreground)]">Cargando comentarios...</p>
		{:else if comments.length === 0}
			<p class="text-sm text-[color:var(--muted-foreground)]">No hay comentarios aun.</p>
		{:else}
			<div class="mb-3 space-y-2">
				{#each comments as comment}
					<div class="rounded-md border border-[color:var(--border)] bg-white p-3 text-sm">
						<div class="mb-1 text-xs text-[color:var(--muted-foreground)]">
							{comment.nombre_editor ?? 'Editor'} - {formatRelative(comment.created_at)}
						</div>
						<div class="whitespace-pre-wrap">{comment.comentario}</div>
					</div>
				{/each}
			</div>
		{/if}

		<label class="block text-sm">
			<span class="mb-1 block">Nuevo comentario</span>
			<textarea
				rows={3}
				class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
				bind:value={newComment}
			></textarea>
		</label>
		<div class="mt-2 flex justify-end">
			<Button onclick={onPublicarComentario} disabled={postingComment}>
				{postingComment ? 'Publicando...' : 'Publicar comentario'}
			</Button>
		</div>
	</div>

	{#if canReviewPanel}
		<div class="card p-4">
			<h3 class="mb-3 text-lg font-semibold">Panel de revisor</h3>
			<p class="mb-2 text-sm text-[color:var(--muted-foreground)]">
				Este panel solo publica comentarios de revision en el historial interno.
			</p>
			<label class="block text-sm">
				<span class="mb-1 block">Comentario del revisor</span>
				<textarea
					rows={3}
					class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					bind:value={reviewerComentario}
				></textarea>
			</label>
			<div class="mt-3 flex justify-end">
				<Button onclick={onPublicarRevision} disabled={postingComment}>
					{postingComment ? 'Publicando...' : 'Publicar comentario de revision'}
				</Button>
			</div>
		</div>
	{/if}

	<div class="card p-4">
		<h2 class="mb-3 text-xl font-semibold">Estado y visibilidad</h2>
		<div class="grid gap-3 md:grid-cols-2">
			<label class="text-sm">
				<span class="mb-1 block">Estado de la obra</span>
				<select
					class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					bind:value={currentEstadoId}
				>
					{#each props.estadoOptions as option}
						<option value={option.termino_id}>{option.termino}</option>
					{/each}
				</select>
			</label>
			<div class="rounded-md border border-[color:var(--border)] bg-white p-3 text-sm">
				<div><strong>Editor asignado:</strong> {obraLive.editor_asignado ?? 'Sin asignar'}</div>
				<div><strong>Ultima modificacion:</strong> {formatRelative(obraLive.updated_at)}</div>
				<div><strong>Estado actual:</strong> {currentEstadoTerm}</div>
			</div>
		</div>

		<label class="mt-3 block text-sm">
			<span class="mb-1 block">Comentario de cambio de estado (opcional)</span>
			<textarea
				rows={3}
				class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
				bind:value={estadoComentario}
			></textarea>
		</label>

		<div class="mt-3 flex flex-wrap gap-2">
			<Button onclick={onGuardarEstado} disabled={stateSaving}>{stateSaving ? 'Guardando...' : 'Guardar estado'}</Button>
			{#if currentEstadoTerm === 'borrador'}
				<Button variant="secondary" onclick={onEnviarRevision} disabled={stateSaving}>Enviar a revision</Button>
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
