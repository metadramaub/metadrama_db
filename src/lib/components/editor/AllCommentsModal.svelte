<script lang="ts">
	import { goto } from '$app/navigation';
	import { portal } from '$lib/actions/portal';
	import Button from '$lib/components/ui/button.svelte';
	import InternalCommentsFeed from '$lib/components/editor/InternalCommentsFeed.svelte';
	import { pushToast } from '$lib/stores/toast';
	import { buildCommentTargetUrl } from '$lib/utils/comment-links';
	import type { ComentarioListItem } from '$lib/types/obra.types';

	const props = $props<{
		open: boolean;
		obraId: string;
		onClose: () => void;
	}>();

	let comments = $state<ComentarioListItem[]>([]);
	let commentsLoading = $state(false);
	let requestCounter = 0;
	let loadError = $state<string | null>(null);

	const subtitle = $derived.by(() => {
		if (commentsLoading) return 'Cargando comentarios...';
		return `${comments.length} comentarios`;
	});

	function handleContextClick(comment: ComentarioListItem) {
		props.onClose();
		void goto(buildCommentTargetUrl(props.obraId, comment));
	}

	async function loadComments() {
		const requestId = ++requestCounter;
		commentsLoading = true;
		loadError = null;

		const response = await fetch(`/api/obras/${props.obraId}/comentarios?limit=5000`);
		if (requestId !== requestCounter) return;

		commentsLoading = false;
		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			const errorMessage = body.message ?? 'No se pudieron cargar los comentarios internos.';
			loadError = errorMessage;
			comments = [];
			pushToast('error', errorMessage);
			return;
		}

		const payload = await response.json();
		if (requestId !== requestCounter) return;
		comments = (payload.items ?? []) as ComentarioListItem[];
	}

	$effect(() => {
		if (!props.open) return;
		void loadComments();

		const handleEscape = (event: KeyboardEvent) => {
			if (event.key !== 'Escape') return;
			props.onClose();
		};

		document.addEventListener('keydown', handleEscape);
		return () => {
			document.removeEventListener('keydown', handleEscape);
		};
	});
</script>

{#if props.open}
	<div use:portal class="fixed inset-0 z-[130]">
		<button
			type="button"
			class="absolute inset-0 bg-black/45"
			aria-label="Cerrar"
			onclick={props.onClose}
		></button>

		<div class="absolute inset-0 z-[1] p-4 md:px-10 lg:px-20">
			<div class="h-[calc(100dvh-2rem)] overflow-y-auto border border-[color:var(--border)] bg-[color:var(--gray-50)] shadow-2xl">
				<div class="sticky top-0 z-20 border-b border-[color:var(--border)] bg-white px-5 py-4">
					<div class="flex flex-wrap items-start justify-between gap-3">
						<div>
							<h2 class="text-xl font-semibold">Todos los comentarios de la obra</h2>
							<p class="text-sm text-[color:var(--muted-foreground)]">{subtitle}</p>
						</div>

						<Button variant="secondary" onclick={props.onClose}>Cerrar</Button>
					</div>
				</div>

				<div class="px-5 py-5">
					<InternalCommentsFeed
						comments={comments}
						loading={commentsLoading}
						emptyText={loadError ?? 'No hay comentarios internos en esta obra.'}
						showSequenceEstrofa={true}
						onContextClick={handleContextClick}
					/>
				</div>
			</div>
		</div>
	</div>
{/if}
