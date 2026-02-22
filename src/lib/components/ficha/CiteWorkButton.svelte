<script lang="ts">
	import { browser } from '$app/environment';

	const props = $props<{
		titulo: string;
		autorFicha: string | null;
		updatedAt: string | null;
		obraPath: string;
	}>();

	let copied = $state(false);
	let copyError = $state<string | null>(null);
	let timer: ReturnType<typeof setTimeout> | null = null;

	function yearLabel(): string {
		if (!props.updatedAt) return 's. f.';
		const date = new Date(props.updatedAt);
		if (Number.isNaN(date.valueOf())) return 's. f.';
		return String(date.getUTCFullYear());
	}

	function accessDateLabel(): string {
		return new Intl.DateTimeFormat('es-ES', {
			day: '2-digit',
			month: '2-digit',
			year: 'numeric'
		}).format(new Date());
	}

	function obraUrl(): string {
		if (!browser) return props.obraPath;
		return `${window.location.origin}${props.obraPath}`;
	}

	function citationText(): string {
		const autor = (props.autorFicha ?? '').trim() || 'Autoría de ficha no indicada';
		return `Análisis versológio de *${props.titulo}* en versologia.metadrama.ub. ${autor}. (${yearLabel()}). MetaDrama DB. Responsables del proyecto: Gastón Gilabert y David Merino Recalde. ${obraUrl()} (Consulta: ${accessDateLabel()}).`;
	}

	async function copyToClipboard() {
		copyError = null;
		const text = citationText();
		try {
			if (navigator.clipboard?.writeText) {
				await navigator.clipboard.writeText(text);
			} else {
				const textArea = document.createElement('textarea');
				textArea.value = text;
				textArea.style.position = 'fixed';
				textArea.style.opacity = '0';
				document.body.appendChild(textArea);
				textArea.focus();
				textArea.select();
				document.execCommand('copy');
				document.body.removeChild(textArea);
			}
			copied = true;
			if (timer) clearTimeout(timer);
			timer = setTimeout(() => {
				copied = false;
			}, 2200);
		} catch (error) {
			console.error(error);
			copyError = 'No se pudo copiar la cita.';
		}
	}
</script>

<div class="flex flex-wrap items-center gap-2">
	<button
		type="button"
		class="border border-[color:var(--gray-800)] bg-[color:var(--gray-800)] px-3 py-2 text-xs font-semibold tracking-[0.06em] text-white hover:bg-[color:var(--gray-700)]"
		onclick={copyToClipboard}
	>
		Citar esta obra
	</button>
	{#if copied}
		<span class="text-xs text-[color:var(--success)]">Cita copiada</span>
	{:else if copyError}
		<span class="text-xs text-[color:var(--danger)]">{copyError}</span>
	{/if}
</div>
