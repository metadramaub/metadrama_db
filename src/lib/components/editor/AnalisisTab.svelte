<script lang="ts">
	import { onDestroy } from 'svelte';
	import Button from '$lib/components/ui/button.svelte';
	import { pushToast } from '$lib/stores/toast';
	import { markSaved, patchCurrentObra, setDirty, setSaving } from '$lib/stores/currentObra';
	import { renderMarkdown } from '$lib/utils/markdown';

	const props = $props<{
		obraId: string;
		analisisInitial: string;
		bibliografiaInitial: string;
		readOnly?: boolean;
	}>();

	let analisis = $state(props.analisisInitial);
	let bibliografia = $state(props.bibliografiaInitial);
	let analisisPreview = $state(false);
	let bibliografiaPreview = $state(false);
	let savingNow = $state(false);
	let timer: ReturnType<typeof setTimeout> | null = null;
	let analisisRef = $state<HTMLTextAreaElement | null>(null);
	let bibliografiaRef = $state<HTMLTextAreaElement | null>(null);

	const analisisLength = $derived(analisis.trim().length);
	const bibliografiaLength = $derived(bibliografia.trim().length);
	const previewAnalisisHtml = $derived(renderMarkdown(analisis));
	const previewBibliografiaHtml = $derived(renderMarkdown(bibliografia));

	$effect(() => {
		analisis = props.analisisInitial ?? '';
		bibliografia = props.bibliografiaInitial ?? '';
	});

	function queueSave() {
		if (props.readOnly) return;
		setDirty(true);
		if (timer) clearTimeout(timer);
		timer = setTimeout(() => void save(), 10_000);
	}

	function applyFormat(
		target: 'analisis' | 'bibliografia',
		prefix: string,
		suffix = prefix
	) {
		if (props.readOnly) return;
		const ref = target === 'analisis' ? analisisRef : bibliografiaRef;
		const current = target === 'analisis' ? analisis : bibliografia;
		if (!ref) {
			const next = `${current}${prefix}${suffix}`;
			if (target === 'analisis') {
				analisis = next;
			} else {
				bibliografia = next;
			}
			queueSave();
			return;
		}

		const start = ref.selectionStart;
		const end = ref.selectionEnd;
		const selected = current.slice(start, end);
		const nextValue = `${current.slice(0, start)}${prefix}${selected}${suffix}${current.slice(end)}`;
		if (target === 'analisis') {
			analisis = nextValue;
		} else {
			bibliografia = nextValue;
		}
		queueSave();

		requestAnimationFrame(() => {
			const cursor = end + prefix.length + suffix.length;
			ref.focus();
			ref.setSelectionRange(cursor, cursor);
		});
	}

	async function save() {
		if (props.readOnly) return;
		if (savingNow) return;
		savingNow = true;
		setSaving(true);

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
			setSaving(false);
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo guardar analisis y bibliografia.');
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
		markSaved();
		pushToast('success', 'Analisis y bibliografia guardados');
	}

	onDestroy(() => {
		if (timer) clearTimeout(timer);
	});
</script>

<section class="space-y-4">
	<div class="card p-4">
		<div class="mb-3 flex flex-wrap items-center justify-between gap-3">
			<div>
				<h2 class="text-xl font-semibold">Analisis y bibliografia</h2>
				<p class="text-sm text-[color:var(--muted-foreground)]">
					Editor markdown con guardado conjunto para ambos bloques.
				</p>
			</div>
			<Button onclick={save} disabled={savingNow || props.readOnly}>
				{savingNow ? 'Guardando...' : 'Guardar seccion'}
			</Button>
		</div>

		<article class="rounded-md border border-[color:var(--border)] bg-white p-4">
			<div class="mb-3 flex flex-wrap items-center justify-between gap-2">
				<div>
					<h3 class="text-lg font-semibold">Analisis del editor</h3>
					<p class="text-xs text-[color:var(--muted-foreground)]">Caracteres: {analisisLength}</p>
				</div>
				<Button variant="secondary" onclick={() => (analisisPreview = !analisisPreview)}>
					{analisisPreview ? 'Editar' : 'Vista previa'}
				</Button>
			</div>

			<div class="mb-3 flex flex-wrap gap-2">
				<Button variant="ghost" onclick={() => applyFormat('analisis', '**', '**')} disabled={props.readOnly}
					>B</Button
				>
				<Button variant="ghost" onclick={() => applyFormat('analisis', '*', '*')} disabled={props.readOnly}
					>I</Button
				>
				<Button variant="ghost" onclick={() => applyFormat('analisis', '\n- ', '')} disabled={props.readOnly}
					>Lista</Button
				>
				<Button
					variant="ghost"
					onclick={() => applyFormat('analisis', '[', '](https://)')}
					disabled={props.readOnly}
					>Enlace</Button
				>
				<Button variant="ghost" onclick={() => applyFormat('analisis', '\n# ', '')} disabled={props.readOnly}
					>H1</Button
				>
				<Button variant="ghost" onclick={() => applyFormat('analisis', '\n## ', '')} disabled={props.readOnly}
					>H2</Button
				>
			</div>

			{#if analisisPreview}
				<div class="prose max-w-none rounded-md border border-[color:var(--border)] bg-[#fffdf8] p-3" style="--tw-prose-body: var(--foreground);">
					{@html previewAnalisisHtml}
				</div>
			{:else}
				<textarea
					bind:this={analisisRef}
					rows={12}
					class="min-h-64 w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					disabled={props.readOnly}
					bind:value={analisis}
					oninput={queueSave}
				></textarea>
			{/if}
		</article>

		<article class="mt-4 rounded-md border border-[color:var(--border)] bg-white p-4">
			<div class="mb-3 flex flex-wrap items-center justify-between gap-2">
				<div>
					<h3 class="text-lg font-semibold">Bibliografia general</h3>
					<p class="text-xs text-[color:var(--muted-foreground)]">Caracteres: {bibliografiaLength}</p>
				</div>
				<Button variant="secondary" onclick={() => (bibliografiaPreview = !bibliografiaPreview)}>
					{bibliografiaPreview ? 'Editar' : 'Vista previa'}
				</Button>
			</div>

			<div class="mb-3 flex flex-wrap gap-2">
				<Button variant="ghost" onclick={() => applyFormat('bibliografia', '**', '**')} disabled={props.readOnly}
					>B</Button
				>
				<Button variant="ghost" onclick={() => applyFormat('bibliografia', '*', '*')} disabled={props.readOnly}
					>I</Button
				>
				<Button
					variant="ghost"
					onclick={() => applyFormat('bibliografia', '\n- ', '')}
					disabled={props.readOnly}
					>Lista</Button
				>
				<Button
					variant="ghost"
					onclick={() => applyFormat('bibliografia', '[', '](https://)')}
					disabled={props.readOnly}
					>Enlace</Button
				>
				<Button variant="ghost" onclick={() => applyFormat('bibliografia', '\n# ', '')} disabled={props.readOnly}
					>H1</Button
				>
				<Button variant="ghost" onclick={() => applyFormat('bibliografia', '\n## ', '')} disabled={props.readOnly}
					>H2</Button
				>
			</div>

			{#if bibliografiaPreview}
				<div class="prose max-w-none rounded-md border border-[color:var(--border)] bg-[#fffdf8] p-3" style="--tw-prose-body: var(--foreground);">
					{@html previewBibliografiaHtml}
				</div>
			{:else}
				<textarea
					bind:this={bibliografiaRef}
					rows={12}
					class="min-h-56 w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					disabled={props.readOnly}
					bind:value={bibliografia}
					oninput={queueSave}
				></textarea>
			{/if}
		</article>
	</div>
</section>
