<script lang="ts">
	import { onDestroy } from 'svelte';
	import Button from '$lib/components/ui/button.svelte';
	import MarkdownEditorLite from '$lib/components/ui/markdown-editor-lite.svelte';
	import { pushToast } from '$lib/stores/toast';
	import { markSaved, patchCurrentObra, setDirty, setSaving } from '$lib/stores/currentObra';

	const props = $props<{
		obraId: string;
		analisisInitial: string;
		bibliografiaInitial: string;
		readOnly?: boolean;
	}>();

	let analisis = $state(props.analisisInitial);
	let bibliografia = $state(props.bibliografiaInitial);
	let savingNow = $state(false);
	let timer: ReturnType<typeof setTimeout> | null = null;

	const analisisLength = $derived(analisis.trim().length);
	const bibliografiaLength = $derived(bibliografia.trim().length);

	$effect(() => {
		analisis = props.analisisInitial ?? '';
		bibliografia = props.bibliografiaInitial ?? '';
	});

	function queueSave() {
		if (props.readOnly) return;
		setDirty(true, 'analisis');
		if (timer) clearTimeout(timer);
		timer = setTimeout(() => void save(), 10_000);
	}

	function onAnalisisChange(nextValue: string) {
		analisis = nextValue;
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
		setSaving(true, 'analisis');

		const response = await fetch(`/api/obras/${props.obraId}/analisis`, {
			method: 'PATCH',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({
				analisis_editor: analisis.trim() || null,
				bibliografia: bibliografia.trim() || null
			})
		});
		savingNow = false;

		if (!response.ok) {
			setSaving(false, 'analisis');
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo guardar análisis y bibliografía.');
			return;
		}

		const payload = await response.json();
		analisis = payload.obra.analisis_editor ?? '';
		bibliografia = payload.obra.bibliografia ?? '';
		patchCurrentObra({
			analisis_editor: payload.obra.analisis_editor,
			bibliografia: payload.obra.bibliografia,
			updated_at: payload.obra.updated_at
		});
		markSaved('analisis');
		pushToast('success', 'Análisis y bibliografía guardados');
	}

	onDestroy(() => {
		if (timer) clearTimeout(timer);
	});
</script>

<section class="space-y-4">
	<div class="flex flex-wrap items-center justify-between gap-3">
		<div>
			<h2 class="text-xl font-semibold">Análisis y bibliografía</h2>
		</div>
		<Button variant="success" onclick={save} disabled={savingNow || props.readOnly}>
			{savingNow ? 'Guardando...' : 'Guardar'}
		</Button>
	</div>

	<article class="card p-4">
		<div class="mb-3">
			<h3 class="text-lg font-semibold">Análisis del editor</h3>
			<p class="text-xs text-[color:var(--muted-foreground)]">Caracteres: {analisisLength}</p>
		</div>
		<MarkdownEditorLite
			rows={12}
			class="mt-1"
			minHeightClass="min-h-64"
			toolbarCompact={true}
			showPreviewToggle={true}
			value={analisis}
			disabled={props.readOnly}
			onChange={onAnalisisChange}
		/>
	</article>

	<article class="card p-4">
		<div class="mb-3">
			<h3 class="text-lg font-semibold">Bibliografía general</h3>
			<p class="text-xs text-[color:var(--muted-foreground)]">Caracteres: {bibliografiaLength}</p>
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
</section>
