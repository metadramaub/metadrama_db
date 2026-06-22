<script lang="ts">
	import { onDestroy, untrack } from 'svelte';
	import InternalCommentsPanel from '$lib/components/editor/InternalCommentsPanel.svelte';
	import FieldHelpTooltip from '$lib/components/ui/field-help-tooltip.svelte';
	import MarkdownEditorLite from '$lib/components/ui/markdown-editor-lite.svelte';
	import {
		OBRA_BIBLIOGRAFIA_ESPECIFICA_EJEMPLO_HTML,
		OBRA_REFERENCIAS_MULTIPLES_HELP
	} from '$lib/config/citation-examples';
	import { pushToast } from '$lib/stores/toast';
	import { markSaved, patchCurrentObra, setDirty, setSaving } from '$lib/stores/currentObra';

	const props = $props<{
		obraId: string;
		observacionesInitial: string;
		bibliografiaInitial: string;
		saveRequestToken?: number;
		readOnly?: boolean;
		canComment?: boolean;
		focusComentarioId?: string | null;
	}>();
	const PUBLIC_VISIBILITY_HELP = 'Este contenido se publica en la ficha pública de la obra.';

	let observaciones = $state(untrack(() => props.observacionesInitial));
	let bibliografia = $state(untrack(() => props.bibliografiaInitial));
	let savingNow = $state(false);
	let lastHandledSaveRequestToken = $state(untrack(() => props.saveRequestToken ?? 0));
	let timer: ReturnType<typeof setTimeout> | null = null;

	const observacionesLength = $derived(observaciones.trim().length);
	const bibliografiaLength = $derived(bibliografia.trim().length);

	$effect(() => {
		observaciones = props.observacionesInitial ?? '';
		bibliografia = props.bibliografiaInitial ?? '';
	});

	$effect(() => {
		const nextToken = props.saveRequestToken ?? 0;
		if (nextToken <= lastHandledSaveRequestToken) return;
		lastHandledSaveRequestToken = nextToken;
		void save();
	});

	function queueSave() {
		if (props.readOnly) return;
		setDirty(true, 'observaciones');
		if (timer) clearTimeout(timer);
		timer = setTimeout(() => void save(), 10_000);
	}

	function onObservacionesChange(nextValue: string) {
		observaciones = nextValue;
		queueSave();
	}

	function onBibliografiaChange(nextValue: string) {
		bibliografia = nextValue;
		queueSave();
	}

	async function save() {
		if (props.readOnly) return;
		if (savingNow) return;
		savingNow = true;
		setSaving(true, 'observaciones');

		const response = await fetch(`/api/obras/${props.obraId}/observaciones`, {
			method: 'PATCH',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({
				observaciones: observaciones.trim() || null,
				bibliografia: bibliografia.trim() || null
			})
		});
		savingNow = false;

		if (!response.ok) {
			setSaving(false, 'observaciones');
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudieron guardar las observaciones y la bibliografía métrica.');
			return;
		}

		const payload = await response.json();
		observaciones = payload.obra.observaciones ?? '';
		bibliografia = payload.obra.bibliografia ?? '';
		patchCurrentObra({
			observaciones: payload.obra.observaciones,
			bibliografia: payload.obra.bibliografia,
			updated_at: payload.obra.updated_at
		});
		markSaved('observaciones');
		pushToast('success', 'Observaciones y bibliografía métrica guardadas.');
	}

	onDestroy(() => {
		if (timer) clearTimeout(timer);
	});
</script>

<section class="space-y-4">
	<div>
		<div>
			<h2 class="text-xl font-semibold">Observaciones</h2>
		</div>
	</div>

	<article class="card p-4">
		<div class="mb-3">
			<h3 class="text-lg font-semibold">
				<span class="form-label-with-help">
					Observaciones
					<FieldHelpTooltip
						text={PUBLIC_VISIBILITY_HELP}
						label="Visibilidad pública de observaciones"
					/>
				</span>
			</h3>
			<p class="text-xs text-[color:var(--muted-foreground)]">Caracteres: {observacionesLength}</p>
		</div>
		<MarkdownEditorLite
			rows={12}
			class="mt-1"
			minHeightClass="min-h-64"
			toolbarCompact={true}
			showPreviewToggle={true}
			value={observaciones}
			disabled={props.readOnly}
			onChange={onObservacionesChange}
		/>
	</article>

	<article class="card p-4">
		<div class="mb-3">
			<h3 class="text-lg font-semibold">
				<span class="form-label-with-help">
					Bibliografía métrica
					<FieldHelpTooltip
						text={PUBLIC_VISIBILITY_HELP}
						label="Visibilidad pública de bibliografía métrica"
					/>
					<FieldHelpTooltip
						text={OBRA_REFERENCIAS_MULTIPLES_HELP}
						label="Ayuda para referencias múltiples en bibliografía métrica"
					/>
				</span>
			</h3>
			<p class="text-xs text-[color:var(--muted-foreground)]">Caracteres: {bibliografiaLength}</p>
			<p class="form-help">Ejemplo de cita: {@html OBRA_BIBLIOGRAFIA_ESPECIFICA_EJEMPLO_HTML}</p>
		</div>
		<MarkdownEditorLite
			rows={12}
			class="mt-1"
			minHeightClass="min-h-56"
			toolbarCompact={true}
			showPreviewToggle={true}
			value={bibliografia}
			disabled={props.readOnly}
			onChange={onBibliografiaChange}
		/>
	</article>

	<InternalCommentsPanel
		obraId={props.obraId}
		canComment={Boolean(props.canComment)}
		section="observaciones"
		focusComentarioId={props.focusComentarioId}
		title="Comentarios internos sobre observaciones"
		emptyText="No hay comentarios internos sobre esta sección."
	/>
</section>
