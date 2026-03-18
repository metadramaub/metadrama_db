<script lang="ts">
	import { onDestroy } from 'svelte';
	import Button from '$lib/components/ui/button.svelte';
	import MarkdownEditorLite from '$lib/components/ui/markdown-editor-lite.svelte';
	import { pushToast } from '$lib/stores/toast';
	import { markSaved, patchCurrentObra, setDirty, setSaving } from '$lib/stores/currentObra';

	const props = $props<{
		obraId: string;
		observacionesInitial: string;
		bibliografiaInitial: string;
		readOnly?: boolean;
	}>();

	let observaciones = $state(props.observacionesInitial);
	let bibliografia = $state(props.bibliografiaInitial);
	let savingNow = $state(false);
	let timer: ReturnType<typeof setTimeout> | null = null;

	const observacionesLength = $derived(observaciones.trim().length);
	const bibliografiaLength = $derived(bibliografia.trim().length);

	$effect(() => {
		observaciones = props.observacionesInitial ?? '';
		bibliografia = props.bibliografiaInitial ?? '';
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
			pushToast('error', body.message ?? 'No se pudieron guardar las observaciones y la bibliografía.');
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
		pushToast('success', 'Observaciones y bibliografía guardadas.');
	}

	onDestroy(() => {
		if (timer) clearTimeout(timer);
	});
</script>

<section class="space-y-4">
	<div class="flex flex-wrap items-center justify-between gap-3">
		<div>
			<h2 class="text-xl font-semibold">Observaciones</h2>
		</div>
		<Button variant="success" onclick={save} disabled={savingNow || props.readOnly}>
			{savingNow ? 'Guardando...' : 'Guardar'}
		</Button>
	</div>

	<article class="card p-4">
		<div class="mb-3">
			<h3 class="text-lg font-semibold">Otras observaciones</h3>
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
			<h3 class="text-lg font-semibold">Bibliografía específica</h3>
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
