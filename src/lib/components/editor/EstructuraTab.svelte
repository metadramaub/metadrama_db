<script lang="ts">
	import type { Tables } from '$lib/types/database.types';
	import Button from '$lib/components/ui/button.svelte';
	import { pushToast } from '$lib/stores/toast';

	const props = $props<{
		obraId: string;
		jornadasInitial: Tables<'jornadas'>[];
		cuadrosInitial: Tables<'cuadros'>[];
		certezaOptions: Array<Pick<Tables<'vocabularios'>, 'termino_id' | 'termino'>>;
	}>();

	let jornadas = $state([...props.jornadasInitial]);
	let cuadros = $state([...props.cuadrosInitial]);
	let showJornadaForm = $state(false);
	const initialJornadaNum = props.jornadasInitial.length + 1;
	let newJornada = $state({ jornada_num: initialJornadaNum, v_ini: 1, v_fin: 1 });

	const defaultCerteza = props.certezaOptions.at(0)?.termino_id ?? '';

	function getCuadros(jornadaId: string) {
		return cuadros.filter((item) => item.jornada_id === jornadaId).sort((a, b) => a.v_ini - b.v_ini);
	}

	async function addJornada() {
		const response = await fetch(`/api/obras/${props.obraId}/estructura/jornadas`, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify(newJornada)
		});
		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo crear la jornada');
			return;
		}

		const created = await response.json();
		jornadas = [...jornadas, created.jornada].sort((a, b) => a.v_ini - b.v_ini);
		showJornadaForm = false;
		newJornada = { jornada_num: jornadas.length + 1, v_ini: 1, v_fin: 1 };
		pushToast('success', 'Jornada creada');
	}

	async function editJornada(jornada: Tables<'jornadas'>) {
		const vIni = Number(prompt('Verso inicial', `${jornada.v_ini}`) ?? jornada.v_ini);
		const vFin = Number(prompt('Verso final', `${jornada.v_fin}`) ?? jornada.v_fin);
		if (!Number.isFinite(vIni) || !Number.isFinite(vFin)) return;

		const response = await fetch(`/api/obras/${props.obraId}/estructura/jornadas/${jornada.jornada_id}`, {
			method: 'PATCH',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ jornada_num: jornada.jornada_num, v_ini: vIni, v_fin: vFin })
		});
		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo actualizar la jornada');
			return;
		}
		const payload = await response.json();
		jornadas = jornadas.map((row) => (row.jornada_id === jornada.jornada_id ? payload.jornada : row));
		pushToast('success', 'Jornada actualizada');
	}

	async function removeJornada(jornadaId: string) {
		if (!confirm('¿Eliminar jornada y sus cuadros?')) return;
		const response = await fetch(`/api/obras/${props.obraId}/estructura/jornadas/${jornadaId}`, {
			method: 'DELETE'
		});
		if (!response.ok) {
			pushToast('error', 'No se pudo eliminar la jornada');
			return;
		}
		jornadas = jornadas.filter((jornada) => jornada.jornada_id !== jornadaId);
		cuadros = cuadros.filter((cuadro) => cuadro.jornada_id !== jornadaId);
		pushToast('success', 'Jornada eliminada');
	}

	async function addCuadro(jornada: Tables<'jornadas'>) {
		const cuadro_num = getCuadros(jornada.jornada_id).length + 1;
		const v_ini = Number(prompt('Verso inicial', `${jornada.v_ini}`) ?? jornada.v_ini);
		const v_fin = Number(prompt('Verso final', `${jornada.v_fin}`) ?? jornada.v_fin);
		const descripcion = prompt('Descripción (opcional)', '') ?? '';
		if (!Number.isFinite(v_ini) || !Number.isFinite(v_fin)) return;

		const response = await fetch(`/api/obras/${props.obraId}/estructura/cuadros`, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({
				jornada_id: jornada.jornada_id,
				cuadro_num,
				v_ini,
				v_fin,
				descripcion,
				certeza_editor: defaultCerteza
			})
		});
		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo crear el cuadro');
			return;
		}
		const payload = await response.json();
		cuadros = [...cuadros, payload.cuadro].sort((a, b) => a.v_ini - b.v_ini);
		pushToast('success', 'Cuadro creado');
	}

	async function editCuadro(cuadro: Tables<'cuadros'>) {
		const vIni = Number(prompt('Verso inicial', `${cuadro.v_ini}`) ?? cuadro.v_ini);
		const vFin = Number(prompt('Verso final', `${cuadro.v_fin}`) ?? cuadro.v_fin);
		const descripcion = prompt('Descripción', cuadro.descripcion ?? '') ?? cuadro.descripcion ?? '';

		const response = await fetch(`/api/obras/${props.obraId}/estructura/cuadros/${cuadro.cuadro_id}`, {
			method: 'PATCH',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({
				jornada_id: cuadro.jornada_id,
				cuadro_num: cuadro.cuadro_num,
				v_ini: vIni,
				v_fin: vFin,
				descripcion,
				certeza_editor: cuadro.certeza_editor
			})
		});

		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo editar el cuadro');
			return;
		}
		const payload = await response.json();
		cuadros = cuadros.map((row) => (row.cuadro_id === cuadro.cuadro_id ? payload.cuadro : row));
		pushToast('success', 'Cuadro actualizado');
	}

	async function removeCuadro(cuadroId: string) {
		if (!confirm('¿Eliminar cuadro?')) return;
		const response = await fetch(`/api/obras/${props.obraId}/estructura/cuadros/${cuadroId}`, {
			method: 'DELETE'
		});
		if (!response.ok) {
			pushToast('error', 'No se pudo eliminar el cuadro');
			return;
		}
		cuadros = cuadros.filter((row) => row.cuadro_id !== cuadroId);
		pushToast('success', 'Cuadro eliminado');
	}
</script>

<section class="space-y-4">
	<div class="flex items-center justify-between">
		<h2 class="text-xl font-semibold">Jornadas y cuadros</h2>
		<Button variant="secondary" onclick={() => (showJornadaForm = !showJornadaForm)}>Añadir jornada</Button>
	</div>

	{#if showJornadaForm}
		<div class="card grid gap-3 p-4 md:grid-cols-4">
			<label class="text-sm">
				<span class="mb-1 block">Jornada #</span>
				<input
					type="number"
					bind:value={newJornada.jornada_num}
					class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
				/>
			</label>
			<label class="text-sm">
				<span class="mb-1 block">V. inicio</span>
				<input
					type="number"
					bind:value={newJornada.v_ini}
					class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
				/>
			</label>
			<label class="text-sm">
				<span class="mb-1 block">V. fin</span>
				<input
					type="number"
					bind:value={newJornada.v_fin}
					class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
				/>
			</label>
			<div class="flex items-end">
				<Button class="w-full" onclick={addJornada}>Guardar jornada</Button>
			</div>
		</div>
	{/if}

	{#each [...jornadas].sort((a, b) => a.v_ini - b.v_ini) as jornada}
		<article class="card p-4">
			<div class="mb-3 flex items-center justify-between gap-2">
				<h3 class="text-lg font-semibold">
					Jornada {jornada.jornada_num} (vv. {jornada.v_ini}-{jornada.v_fin})
				</h3>
				<div class="flex gap-2">
					<Button variant="ghost" onclick={() => editJornada(jornada)}>Editar</Button>
					<Button variant="danger" onclick={() => removeJornada(jornada.jornada_id)}>Eliminar</Button>
				</div>
			</div>

			<div class="mb-2 flex items-center justify-between">
				<div class="text-xs uppercase tracking-wide text-[color:var(--muted-foreground)]">Cuadros</div>
				<Button variant="secondary" onclick={() => addCuadro(jornada)}>Añadir cuadro</Button>
			</div>

			<div class="space-y-2">
				{#if getCuadros(jornada.jornada_id).length === 0}
					<p class="text-sm text-[color:var(--muted-foreground)]">Sin cuadros en esta jornada.</p>
				{:else}
					{#each getCuadros(jornada.jornada_id) as cuadro}
						<div class="rounded-md border border-[color:var(--border)] bg-white p-3">
							<div class="flex items-start justify-between gap-2">
								<div>
									<div class="font-medium">
										Cuadro {cuadro.cuadro_num}: vv. {cuadro.v_ini}-{cuadro.v_fin}
									</div>
									{#if cuadro.descripcion}
										<div class="mt-1 text-sm text-[color:var(--muted-foreground)]">{cuadro.descripcion}</div>
									{/if}
								</div>
								<div class="flex gap-2">
									<Button variant="ghost" onclick={() => editCuadro(cuadro)}>Editar</Button>
									<Button variant="danger" onclick={() => removeCuadro(cuadro.cuadro_id)}>Eliminar</Button>
								</div>
							</div>
						</div>
					{/each}
				{/if}
			</div>
		</article>
	{/each}
</section>
