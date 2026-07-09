<script lang="ts">
	import { onMount, type Snippet } from 'svelte';

	let {
		title,
		description,
		citation,
		bibtex,
		ris,
		filename,
		children
	} = $props<{
		title: string;
		description?: string;
		citation: string;
		bibtex: string;
		ris: string;
		filename: string;
		children: Snippet;
	}>();

	let feedback = $state<string | null>(null);
	let feedbackIsError = $state(false);
	let feedbackTimer: ReturnType<typeof setTimeout> | undefined;
	let formatMenu: HTMLDetailsElement;

	onMount(() => {
		function closeOnOutsideClick(event: PointerEvent) {
			if (formatMenu.open && !formatMenu.contains(event.target as Node)) {
				formatMenu.open = false;
			}
		}

		function closeOnEscape(event: KeyboardEvent) {
			if (event.key === 'Escape' && formatMenu.open) {
				formatMenu.open = false;
				formatMenu.querySelector('summary')?.focus();
			}
		}

		document.addEventListener('pointerdown', closeOnOutsideClick);
		document.addEventListener('keydown', closeOnEscape);

		return () => {
			document.removeEventListener('pointerdown', closeOnOutsideClick);
			document.removeEventListener('keydown', closeOnEscape);
		};
	});

	function showFeedback(message: string, isError = false) {
		feedback = message;
		feedbackIsError = isError;
		if (feedbackTimer) clearTimeout(feedbackTimer);
		feedbackTimer = setTimeout(() => {
			feedback = null;
		}, 2400);
	}

	async function copyText(text: string, label: string) {
		try {
			if (navigator.clipboard?.writeText) {
				await navigator.clipboard.writeText(text);
			} else {
				const textArea = document.createElement('textarea');
				textArea.value = text;
				textArea.style.position = 'fixed';
				textArea.style.opacity = '0';
				document.body.appendChild(textArea);
				textArea.select();
				document.execCommand('copy');
				textArea.remove();
			}
			showFeedback(`${label} copiado`);
		} catch (error) {
			console.error(error);
			showFeedback('No se pudo copiar', true);
		} finally {
			if (formatMenu) formatMenu.open = false;
		}
	}

	function download(text: string, extension: 'bib' | 'ris', label: string) {
		const blob = new Blob([text], { type: 'text/plain;charset=utf-8' });
		const url = URL.createObjectURL(blob);
		const link = document.createElement('a');
		link.href = url;
		link.download = `${filename}.${extension}`;
		link.click();
		URL.revokeObjectURL(url);
		showFeedback(`${label} descargado`);
		if (formatMenu) formatMenu.open = false;
	}
</script>

<article class="flex h-full flex-col bg-white p-6 md:p-8">
	<div class="flex-1">
		<h2 class="font-display text-2xl text-[color:var(--gray-900)]">{title}</h2>
		{#if description}
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">{description}</p>
		{/if}
		<div class="mt-5 text-sm leading-7 text-[color:var(--gray-700)]">
			{@render children()}
		</div>
	</div>

	<div class="mt-7">
		<div class="flex flex-wrap gap-2">
			<button
				type="button"
				class="border border-[color:var(--gray-800)] bg-[color:var(--gray-800)] px-3 py-2 text-xs font-semibold tracking-[0.06em] text-white transition-colors hover:bg-[color:var(--gray-700)]"
				onclick={() => copyText(citation, 'Cita')}
			>
				COPIAR CITA
			</button>

			<details class="relative" bind:this={formatMenu}>
				<summary
					class="cursor-pointer list-none border border-[color:var(--border)] bg-white px-3 py-2 text-xs font-semibold tracking-[0.06em] text-[color:var(--gray-800)] transition-colors hover:bg-[color:var(--muted)]"
				>
					MÁS FORMATOS ▾
				</summary>
				<div
					class="absolute bottom-full left-0 z-20 mb-2 grid min-w-52 border border-[color:var(--border)] bg-white shadow-lg"
				>
					<button
						type="button"
						class="px-3 py-2 text-left text-xs hover:bg-[color:var(--muted)]"
						onclick={() => copyText(bibtex, 'BibTeX')}
					>Copiar BibTeX</button>
					<button
						type="button"
						class="border-t border-[color:var(--border)] px-3 py-2 text-left text-xs hover:bg-[color:var(--muted)]"
						onclick={() => download(bibtex, 'bib', 'BibTeX')}
					>Descargar BibTeX (.bib)</button>
					<button
						type="button"
						class="border-t border-[color:var(--border)] px-3 py-2 text-left text-xs hover:bg-[color:var(--muted)]"
						onclick={() => download(ris, 'ris', 'RIS')}
					>Descargar RIS (.ris)</button>
				</div>
			</details>
		</div>

		<p
			class={`mt-3 min-h-5 text-xs ${feedbackIsError ? 'text-[color:var(--danger)]' : 'text-[color:var(--success)]'}`}
			aria-live="polite"
		>
			{feedback ?? ''}
		</p>
	</div>
</article>
