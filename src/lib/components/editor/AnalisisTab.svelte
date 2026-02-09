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
	}>();

	let analisis = $state(props.analisisInitial);
	let bibliografia = $state(props.bibliografiaInitial);
	let preview = $state(false);
	let savingNow = $state(false);
	let timer: ReturnType<typeof setTimeout> | null = null;
	let analisisRef = $state<HTMLTextAreaElement | null>(null);
	let bibliografiaRef = $state<HTMLTextAreaElement | null>(null);
	let activeEditor = $state<'analisis' | 'bibliografia'>('analisis');

	const analisisLength = $derived(analisis.trim().length);
	const bibliografiaLength = $derived(bibliografia.trim().length);
	const previewAnalisisHtml = $derived(renderMarkdown(analisis));
	const previewBibliografiaHtml = $derived(renderMarkdown(bibliografia));

	function queueSave() {
		setDirty(true);
		if (timer) clearTimeout(timer);
		timer = setTimeout(() => void save(), 10_000);
	}

	function getActiveRef(): HTMLTextAreaElement | null {
		return activeEditor === 'analisis' ? analisisRef : bibliografiaRef;
	}

	function getActiveValue(): string {
		return activeEditor === 'analisis' ? analisis : bibliografia;
	}

	function setActiveValue(value: string) {
		if (activeEditor === 'analisis') {
			analisis = value;
			return;
		}
		bibliografia = value;
	}

	function applyFormat(prefix: string, suffix = prefix) {
		const targetRef = getActiveRef();
		const currentValue = getActiveValue();
		if (!targetRef) {
			setActiveValue(`${currentValue}${prefix}${suffix}`);
			queueSave();
			return;
		}

		const start = targetRef.selectionStart;
		const end = targetRef.selectionEnd;
		const selected = currentValue.slice(start, end);
		const nextValue = `${currentValue.slice(0, start)}${prefix}${selected}${suffix}${currentValue.slice(end)}`;
		setActiveValue(nextValue);
		queueSave();

		requestAnimationFrame(() => {
			const ref = getActiveRef();
			if (!ref) return;
			const cursor = end + prefix.length + suffix.length;
			ref.focus();
			ref.setSelectionRange(cursor, cursor);
		});
	}

	async function save() {
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
					Editor markdown. El guardado aplica a ambos campos.
				</p>
			</div>
			<div class="flex items-center gap-2">
				<Button variant="secondary" onclick={() => (preview = !preview)}>{preview ? 'Editar' : 'Vista previa'}</Button>
				<Button onclick={save} disabled={savingNow}>
					{savingNow ? 'Guardando...' : 'Guardar analisis y bibliografia'}
				</Button>
			</div>
		</div>

		<div class="mb-3 flex flex-wrap gap-2">
			<Button variant="ghost" onclick={() => applyFormat('**', '**')}>B</Button>
			<Button variant="ghost" onclick={() => applyFormat('*', '*')}>I</Button>
			<Button variant="ghost" onclick={() => applyFormat('\n- ', '')}>Lista</Button>
			<Button variant="ghost" onclick={() => applyFormat('[', '](https://)')}>Enlace</Button>
			<Button variant="ghost" onclick={() => applyFormat('\n# ', '')}>H1</Button>
			<Button variant="ghost" onclick={() => applyFormat('\n## ', '')}>H2</Button>
		</div>

		{#if preview}
			<div class="grid gap-4 lg:grid-cols-2">
				<div class="rounded-md border border-[color:var(--border)] bg-[#fffdf8] p-3">
					<div class="mb-2 text-sm font-semibold">Vista previa - Analisis ({analisisLength} caracteres)</div>
					<div class="prose max-w-none space-y-2" style="--tw-prose-body: var(--foreground);">{@html previewAnalisisHtml}</div>
				</div>
				<div class="rounded-md border border-[color:var(--border)] bg-[#fffdf8] p-3">
					<div class="mb-2 text-sm font-semibold">Vista previa - Bibliografia ({bibliografiaLength} caracteres)</div>
					<div class="prose max-w-none space-y-2" style="--tw-prose-body: var(--foreground);">{@html previewBibliografiaHtml}</div>
				</div>
			</div>
		{:else}
			<div class="grid gap-4 lg:grid-cols-2">
				<label class="block text-sm">
					<span class="mb-1 block text-base font-semibold">Analisis del editor</span>
					<textarea
						bind:this={analisisRef}
						rows={14}
						class="min-h-64 w-full rounded-md border border-[color:var(--border)] px-3 py-2"
						value={analisis}
						onfocus={() => (activeEditor = 'analisis')}
						oninput={(event) => {
							analisis = event.currentTarget.value;
							queueSave();
						}}
					></textarea>
					<span class="mt-1 block text-xs text-[color:var(--muted-foreground)]">Caracteres: {analisisLength}</span>
				</label>

				<label class="block text-sm">
					<span class="mb-1 block text-base font-semibold">Bibliografia general</span>
					<textarea
						bind:this={bibliografiaRef}
						rows={14}
						class="min-h-64 w-full rounded-md border border-[color:var(--border)] px-3 py-2"
						value={bibliografia}
						onfocus={() => (activeEditor = 'bibliografia')}
						oninput={(event) => {
							bibliografia = event.currentTarget.value;
							queueSave();
						}}
					></textarea>
					<span class="mt-1 block text-xs text-[color:var(--muted-foreground)]">Caracteres: {bibliografiaLength}</span>
				</label>
			</div>
		{/if}
	</div>
</section>
