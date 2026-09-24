<script lang="ts">
	// La cita de la ficha es la de «Cómo citar un análisis específico», la misma que lleva cada
	// gráfico descargado: dos citas distintas de lo mismo se acaban copiando las dos.
	import { anioDeFicha, citaDelAnalisis, textoDe } from '$lib/figuras/cita';

	const props = $props<{
		titulo: string;
		autorFicha: string | null;
		updatedAt: string | null;
		obraSlug: string;
	}>();

	let copied = $state(false);
	let copyError = $state<string | null>(null);
	let timer: ReturnType<typeof setTimeout> | null = null;

	function citationText(): string {
		return textoDe(
			citaDelAnalisis(
				{
					obraTitulo: props.titulo,
					obraSlug: props.obraSlug,
					autorFicha: props.autorFicha,
					anio: anioDeFicha(props.updatedAt)
				},
				new Date()
			)
		);
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
