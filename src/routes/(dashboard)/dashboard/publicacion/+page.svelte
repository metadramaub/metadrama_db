<script lang="ts">
	import type { PageData } from './$types';
	import type { PublicSection, SectionScope } from '$lib/secciones-publicas';

	let { data } = $props<{ data: PageData }>();

	const SCOPE_LABELS: Record<SectionScope, string> = {
		anon: 'Cualquiera (público)',
		authenticated: 'Solo con login',
		admin_ip: 'Solo admin/IP'
	};
	const SCOPE_ORDER: SectionScope[] = ['anon', 'authenticated', 'admin_ip'];

	// Estado local editable, copia de los datos cargados.
	let paginas = $state<PublicSection[]>(data.paginas.map((s: PublicSection) => ({ ...s })));
	let ficha = $state<PublicSection[]>(data.ficha.map((s: PublicSection) => ({ ...s })));

	// Estado por sección: 'idle' | 'saving' | 'saved' | 'error'
	let status = $state<Record<string, 'idle' | 'saving' | 'saved' | 'error'>>({});
	let errors = $state<Record<string, string>>({});

	async function patchSeccion(seccion: PublicSection, patch: Partial<Pick<PublicSection, 'activa' | 'scope_minimo'>>) {
		status = { ...status, [seccion.seccion_id]: 'saving' };
		errors = { ...errors, [seccion.seccion_id]: '' };
		try {
			const resp = await fetch(`/api/secciones-publicas/${encodeURIComponent(seccion.seccion_id)}`, {
				method: 'PATCH',
				headers: { 'content-type': 'application/json' },
				body: JSON.stringify(patch)
			});
			if (!resp.ok) {
				const detail = await resp.json().catch(() => ({}));
				throw new Error(detail.message ?? `Error ${resp.status}`);
			}
			status = { ...status, [seccion.seccion_id]: 'saved' };
			setTimeout(() => {
				status = { ...status, [seccion.seccion_id]: 'idle' };
			}, 1500);
		} catch (err) {
			status = { ...status, [seccion.seccion_id]: 'error' };
			errors = {
				...errors,
				[seccion.seccion_id]: err instanceof Error ? err.message : 'Error desconocido'
			};
		}
	}

	function toggleActiva(seccion: PublicSection) {
		seccion.activa = !seccion.activa;
		patchSeccion(seccion, { activa: seccion.activa });
	}

	function changeScope(seccion: PublicSection, value: SectionScope) {
		seccion.scope_minimo = value;
		patchSeccion(seccion, { scope_minimo: value });
	}
</script>

{#snippet seccionRow(seccion: PublicSection)}
	<div class="flex flex-wrap items-center gap-4 border-b border-[color:var(--border)] py-3 last:border-b-0">
		<div class="min-w-0 flex-1">
			<div class="font-semibold text-[color:var(--gray-900)]">{seccion.label}</div>
			{#if seccion.descripcion}
				<div class="text-xs text-[color:var(--muted-foreground)]">{seccion.descripcion}</div>
			{/if}
			<div class="mt-0.5 text-[11px] text-[color:var(--muted-foreground)]">{seccion.seccion_id}</div>
		</div>

		<label class="flex items-center gap-2 text-sm">
			<input type="checkbox" checked={seccion.activa} onchange={() => toggleActiva(seccion)} />
			<span class={seccion.activa ? 'font-semibold text-emerald-700' : 'text-[color:var(--muted-foreground)]'}>
				{seccion.activa ? 'Activa' : 'Apagada'}
			</span>
		</label>

		<label class="flex items-center gap-2 text-sm">
			<span class="text-xs text-[color:var(--muted-foreground)]">Visible para:</span>
			<select
				class="border border-[color:var(--border)] px-2 py-1 text-sm"
				value={seccion.scope_minimo}
				disabled={!seccion.activa}
				onchange={(e) => changeScope(seccion, e.currentTarget.value as SectionScope)}
			>
				{#each SCOPE_ORDER as scope}
					<option value={scope}>{SCOPE_LABELS[scope]}</option>
				{/each}
			</select>
		</label>

		<div class="w-24 text-right text-xs">
			{#if status[seccion.seccion_id] === 'saving'}
				<span class="text-[color:var(--muted-foreground)]">Guardando…</span>
			{:else if status[seccion.seccion_id] === 'saved'}
				<span class="text-emerald-700">Guardado ✓</span>
			{:else if status[seccion.seccion_id] === 'error'}
				<span class="text-red-600" title={errors[seccion.seccion_id]}>Error</span>
			{/if}
		</div>
	</div>
{/snippet}

<section class="space-y-6">
	<div>
		<h1 class="font-display text-3xl">PUBLICACIÓN</h1>
		<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
			Enciende o apaga secciones de la zona pública y define quién puede verlas. Los cambios
			se aplican al instante. No afectan al muro de publicación: una obra sigue necesitando estar
			publicada y visible para aparecer en público.
		</p>
	</div>

	<div class="card p-4">
		<h2 class="font-display text-xl">Páginas</h2>
		<div class="mt-2">
			{#each paginas as seccion (seccion.seccion_id)}
				{@render seccionRow(seccion)}
			{/each}
		</div>
	</div>

	<div class="card p-4">
		<h2 class="font-display text-xl">Secciones de la ficha de obra</h2>
		<div class="mt-2">
			{#each ficha as seccion (seccion.seccion_id)}
				{@render seccionRow(seccion)}
			{/each}
		</div>
	</div>
</section>
