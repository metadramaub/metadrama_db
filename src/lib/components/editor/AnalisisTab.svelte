<script lang="ts">
	import { onDestroy } from 'svelte';
	import Button from '$lib/components/ui/button.svelte';
	import { pushToast } from '$lib/stores/toast';
	import { markSaved, setDirty, setSaving } from '$lib/stores/currentObra';

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

	const analisisLength = $derived(analisis.trim().length);

	function queueSave() {
		setDirty(true);
		if (timer) clearTimeout(timer);
		timer = setTimeout(() => void save(), 10_000);
	}

	function applyFormat(prefix: string, suffix = prefix) {
		if (!analisisRef) {
			analisis = `${analisis}${prefix}${suffix}`;
			queueSave();
			return;
		}

		const start = analisisRef.selectionStart;
		const end = analisisRef.selectionEnd;
		const selected = analisis.slice(start, end);
		const next = `${analisis.slice(0, start)}${prefix}${selected}${suffix}${analisis.slice(end)}`;
		analisis = next;
		queueSave();

		requestAnimationFrame(() => {
			if (!analisisRef) return;
			const cursor = end + prefix.length + suffix.length;
			analisisRef.focus();
			analisisRef.setSelectionRange(cursor, cursor);
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
			pushToast('error', body.message ?? 'No se pudo guardar el analisis.');
			return;
		}

		markSaved();
		pushToast('success', 'Analisis guardado');
	}

	onDestroy(() => {
		if (timer) clearTimeout(timer);
	});
</script>

<section class="space-y-4">
	<div class="card p-4">
		<div class="mb-3 flex flex-wrap items-center justify-between gap-3">
			<div>
				<h2 class="text-xl font-semibold">Analisis del editor</h2>
				<p class="text-sm text-[color:var(--muted-foreground)]">
					Este texto se mostrara en la web publica en iteraciones futuras.
				</p>
			</div>
			<div class="text-sm text-[color:var(--muted-foreground)]">Caracteres: {analisisLength}</div>
		</div>

		<div class="mb-3 flex flex-wrap gap-2">
			<Button variant="ghost" onclick={() => applyFormat('**', '**')}>B</Button>
			<Button variant="ghost" onclick={() => applyFormat('*', '*')}>I</Button>
			<Button variant="ghost" onclick={() => applyFormat('\n- ', '')}>Lista</Button>
			<Button variant="ghost" onclick={() => applyFormat('[', '](https://)')}>Enlace</Button>
			<Button variant="ghost" onclick={() => applyFormat('\n# ', '')}>H1</Button>
			<Button variant="ghost" onclick={() => applyFormat('\n## ', '')}>H2</Button>
		</div>

		<div class="mb-3 flex justify-end gap-2">
			<Button variant="secondary" onclick={() => (preview = !preview)}>{preview ? 'Editar' : 'Vista previa'}</Button>
			<Button onclick={save} disabled={savingNow}>{savingNow ? 'Guardando...' : 'Guardar'}</Button>
		</div>

		{#if preview}
			<pre class="min-h-64 whitespace-pre-wrap rounded-md border border-[color:var(--border)] bg-[#fffdf8] p-3 text-sm">{analisis || 'Sin contenido.'}</pre>
		{:else}
			<textarea
				bind:this={analisisRef}
				rows={14}
				class="min-h-64 w-full rounded-md border border-[color:var(--border)] px-3 py-2"
				value={analisis}
				oninput={(event) => {
					analisis = event.currentTarget.value;
					queueSave();
				}}
			></textarea>
		{/if}
	</div>

	<div class="card p-4">
		<label class="block text-sm">
			<span class="mb-1 block text-base font-semibold">Bibliografia general</span>
			<textarea
				rows={8}
				class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
				value={bibliografia}
				oninput={(event) => {
					bibliografia = event.currentTarget.value;
					queueSave();
				}}
			></textarea>
		</label>
	</div>
</section>
