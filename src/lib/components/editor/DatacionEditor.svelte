<script lang="ts">
	import type { Datacion } from '$lib/dataciones';
	import { formatoDatacion } from '$lib/dataciones';
	import MarkdownEditorLite from '$lib/components/ui/markdown-editor-lite.svelte';
	let { value, disabled = false, onChange } = $props<{ value: Datacion; disabled?: boolean; onChange: (value: Datacion) => void }>();
	function change(patch: Partial<Datacion>) { onChange({ ...value, ...patch }); }
</script>

<fieldset class="space-y-3 border border-[color:var(--border)] p-4" {disabled}>
	<legend class="px-1 font-semibold">Datación {value.clase === 'referencia' ? 'de referencia' : 'métrica'}</legend>
	<div class="grid gap-3 md:grid-cols-2">
		<label class="form-field"><span class="form-label">Límite inicial</span>
			<input type="number" min="1200" max="2100" class="w-full rounded-md border px-3 py-2" value={value.inicio ?? ''}
				oninput={(e) => change({ inicio: e.currentTarget.value ? Number(e.currentTarget.value) : null })} />
			<select class="mt-1 w-full rounded-md border px-3 py-2" value={value.inicio_inclusivo ? 'incluido' : 'excluido'}
				onchange={(e) => change({ inicio_inclusivo: e.currentTarget.value === 'incluido' })}>
				<option value="incluido">Ese año o después (≥)</option><option value="excluido">Después de ese año (&gt;)</option>
			</select>
		</label>
		<label class="form-field"><span class="form-label">Límite final</span>
			<input type="number" min="1200" max="2100" class="w-full rounded-md border px-3 py-2" value={value.fin ?? ''}
				oninput={(e) => change({ fin: e.currentTarget.value ? Number(e.currentTarget.value) : null })} />
			<select class="mt-1 w-full rounded-md border px-3 py-2" value={value.fin_inclusivo ? 'incluido' : 'excluido'}
				onchange={(e) => change({ fin_inclusivo: e.currentTarget.value === 'incluido' })}>
				<option value="incluido">Ese año o antes (≤)</option><option value="excluido">Antes de ese año (&lt;)</option>
			</select>
		</label>
	</div>
	<label class="flex items-center gap-2"><input type="checkbox" checked={value.aproximada} onchange={(e) => change({ aproximada: e.currentTarget.checked })} /> Aproximada (c.)</label>
	<p class="text-sm text-[color:var(--muted-foreground)]">{formatoDatacion(value)}. Para un año concreto, repítelo en ambos límites.</p>
	<div class="form-field"><span class="form-label">Fuente de esta datación</span>
		<MarkdownEditorLite rows={3} value={value.fuente ?? ''} {disabled} onChange={(fuente) => change({ fuente: fuente || null })} />
	</div>
</fieldset>
