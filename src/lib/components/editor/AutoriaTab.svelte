<script lang="ts">
	import { onMount, untrack } from 'svelte';
	import ChevronDown from 'lucide-svelte/icons/chevron-down';
	import ChevronRight from 'lucide-svelte/icons/chevron-right';
	import Trash2 from 'lucide-svelte/icons/trash-2';
	import Button from '$lib/components/ui/button.svelte';
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import FieldHelpTooltip from '$lib/components/ui/field-help-tooltip.svelte';
	import MarkdownEditorLite from '$lib/components/ui/markdown-editor-lite.svelte';
	import AuthorSelector from '$lib/components/editor/AuthorSelector.svelte';
	import InternalCommentsPanel from '$lib/components/editor/InternalCommentsPanel.svelte';
	import { pushToast } from '$lib/stores/toast';
	import { markSaved, patchCurrentObra, setDirty, setSaving } from '$lib/stores/currentObra';
	import type { Tables } from '$lib/types/database.types';
	import type { AutoriaApiPayload, AutoriaComposicionTerm } from '$lib/types/obra.types';
	import { canManageAutoriaMetricProfile } from '$lib/utils/permissions';
	import { displayTerm } from '$lib/utils/vocabulario';

	type CatalogItem = {
		termino_id: string;
		termino: string;
		etiqueta?: string | null;
	};

	type DraftEvidence = {
		local_id: string;
		atribucion_evidencia_id: string | null;
		tipo_atribucion_id: string;
		fuente_autoria: string;
	};

	type DraftProposal = {
		local_id: string;
		atribucion_id: string | null;
		composicion_autoria_id: string;
		perfil_metrico: boolean;
		autor_ids: string[];
		evidencias: DraftEvidence[];
	};

	type DraftGroup = {
		local_id: string;
		grupo_atribucion_id: string | null;
		jornada_id: string | null;
		propuestas: DraftProposal[];
	};

	type ScopeView = 'obra' | 'jornadas';

	const props = $props<{
		obraId: string;
		obra: Tables<'obras'>;
		roleTerm: string;
		saveRequestToken?: number;
		readOnly?: boolean;
		canComment?: boolean;
		focusComentarioId?: string | null;
		commentsReloadKey?: string | number | null;
		onMetricaDirty?: () => void;
	}>();

	const PERFIL_HELP =
		'Activa esta opción solo si la propuesta puede alimentar perfiles métricos de autor sin introducir ambigüedad.';
	const EVIDENCIAS_HELP =
		'Si varias fuentes sostienen la misma autoría, añádelas como evidencias de una misma propuesta. Crea una nueva propuesta solo cuando la autoría propuesta sea distinta.';

	let loading = $state(true);
	let loadingFromServer = $state(false);
	let savingNow = $state(false);
	let loadError = $state<string | null>(null);

	let jornadas = $state<Array<Pick<Tables<'jornadas'>, 'jornada_id' | 'jornada_num' | 'v_ini' | 'v_fin'>>>([]);
	let autores = $state<Array<Pick<Tables<'autores'>, 'autor_id' | 'nombre_completo' | 'nombre_normalizado'>>>([]);
	let tipos = $state<CatalogItem[]>([]);
	let composiciones = $state<CatalogItem[]>([]);
	let groups = $state<DraftGroup[]>([]);
	let baselineSnapshot = $state('');
	let scopeView = $state<ScopeView>('obra');
	let openProposalId = $state<string | null>(null);
	let openEvidenceIds = $state<string[]>([]);
	let lastAuthorResolveKey = '';

	function isEvidenceOpen(evidenceId: string): boolean {
		return openEvidenceIds.includes(evidenceId);
	}
	let lastHandledSaveRequestToken = $state(untrack(() => props.saveRequestToken ?? 0));

	const canComment = $derived(Boolean(props.canComment));
	const effectiveReadOnly = $derived(Boolean(props.readOnly));
	const canManagePerfilMetrico = $derived(canManageAutoriaMetricProfile(props.roleTerm));
	const tipoItems = $derived(tipos.map((item) => ({ id: item.termino_id, label: displayTerm(item) })));
	const composicionItems = $derived(
		composiciones
			.filter((item) => ['individual', 'colaborada', 'desconocida'].includes(normalizeTerm(item.termino)))
			.map((item) => ({ id: item.termino_id, label: labelForComposicion(normalizeTerm(item.termino)) }))
	);
	const authorOptions = $derived(
		autores.map((author) => ({
			autor_id: author.autor_id,
			nombre_completo: author.nombre_completo
		}))
	);
	const authorNameById = $derived(new Map(autores.map((author) => [author.autor_id, author.nombre_completo])));
	const tipoTermById = $derived(new Map(tipos.map((item) => [item.termino_id, displayTerm(item)])));
	const composicionTermById = $derived(
		new Map(composiciones.map((item) => [item.termino_id, normalizeTerm(item.termino) as AutoriaComposicionTerm]))
	);
	const globalGroups = $derived(groups.filter((group) => !group.jornada_id));
	const jornadaGroupCount = $derived(groups.filter((group) => group.jornada_id !== null).length);
	const groupsByJornadaId = $derived.by(() => {
		const map = new Map<string, DraftGroup[]>();
		for (const jornada of jornadas) map.set(jornada.jornada_id, []);
		for (const group of groups) {
			if (!group.jornada_id) continue;
			const current = map.get(group.jornada_id) ?? [];
			current.push(group);
			map.set(group.jornada_id, current);
		}
		return map;
	});

	function newLocalId(prefix: string): string {
		return `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
	}

	function normalizeTerm(value: string): string {
		return value
			.normalize('NFD')
			.replaceAll(/\p{M}/gu, '')
			.trim()
			.toLowerCase()
			.replaceAll(/[\s-]+/g, '_');
	}

	function uniqueIds(ids: string[]): string[] {
		return [...new Set(ids.map((id) => id.trim()).filter((id) => id.length > 0))];
	}

	function mergeAuthors(
		rows: Array<Pick<Tables<'autores'>, 'autor_id' | 'nombre_completo'> & { nombre_normalizado?: string | null }>
	) {
		if (rows.length === 0) return;
		const byId = new Map(autores.map((author) => [author.autor_id, author]));
		let changed = false;
		for (const row of rows) {
			const current = byId.get(row.autor_id);
			if (!current || current.nombre_completo !== row.nombre_completo) {
				byId.set(row.autor_id, {
					autor_id: row.autor_id,
					nombre_completo: row.nombre_completo,
					nombre_normalizado: row.nombre_normalizado ?? current?.nombre_normalizado ?? row.nombre_completo
				});
				changed = true;
			}
		}
		if (changed) {
			autores = [...byId.values()].sort((a, b) => a.nombre_completo.localeCompare(b.nombre_completo, 'es'));
		}
	}

	function collectMissingAuthorIds(sourceGroups: DraftGroup[]): string[] {
		const knownIds = new Set(autores.map((author) => author.autor_id));
		return uniqueIds(
			sourceGroups.flatMap((group) =>
				group.propuestas.flatMap((proposal) =>
					proposal.autor_ids.filter((authorId) => !knownIds.has(authorId))
				)
			)
		).sort((a, b) => a.localeCompare(b));
	}

	async function resolveMissingAuthorNames(missingIds: string[]) {
		if (missingIds.length === 0) return;
		const params = new URLSearchParams();
		params.set('ids', missingIds.join(','));
		const response = await fetch(`/api/autores/buscar?${params.toString()}`);
		if (!response.ok) return;
		const payload = await response.json().catch(() => ({}));
		const rows = (payload.authors ?? []) as Array<
			Pick<Tables<'autores'>, 'autor_id' | 'nombre_completo' | 'nombre_normalizado'>
		>;
		mergeAuthors(rows);
	}

	function getComposicionId(term: AutoriaComposicionTerm): string {
		return composiciones.find((item) => normalizeTerm(item.termino) === term)?.termino_id ?? composiciones[0]?.termino_id ?? '';
	}

	function labelForComposicion(term: string): string {
		if (term === 'individual') return 'individual';
		if (term === 'colaborada') return 'colaborada';
		if (term === 'desconocida') return 'desconocida';
		return term || 'sin composición';
	}

	function getComposicionTerm(composicionId: string): AutoriaComposicionTerm {
		return composicionTermById.get(composicionId) ?? 'individual';
	}

	function getTipoTerm(tipoId: string): string {
		return tipoTermById.get(tipoId) ?? 'Sin tipo';
	}

	function getAuthorSummary(authorIds: string[]): string {
		const names = uniqueIds(authorIds).map((authorId) => authorNameById.get(authorId) ?? authorId);
		if (names.length === 0) return 'Sin autores';
		if (names.length <= 3) return names.join(', ');
		return `${names.slice(0, 3).join(', ')} +${names.length - 3}`;
	}

	function getProposalSummary(proposal: DraftProposal): string {
		if (getComposicionTerm(proposal.composicion_autoria_id) === 'desconocida') return 'Autoría desconocida';
		return getAuthorSummary(proposal.autor_ids);
	}

	function joinHuman(items: string[], conjunction: 'y' | 'o' = 'y'): string {
		const filtered = items.map((item) => item.trim()).filter((item) => item.length > 0);
		if (filtered.length === 0) return '';
		if (filtered.length === 1) return filtered[0];
		if (filtered.length === 2) return `${filtered[0]} ${conjunction} ${filtered[1]}`;
		const last = filtered[filtered.length - 1] ?? '';
		return `${filtered.slice(0, -1).join(', ')} ${conjunction} ${last}`;
	}

	function getProposalEvidencePhrase(proposal: DraftProposal): string {
		const labels = proposal.evidencias.map((evidencia) => getTipoTerm(evidencia.tipo_atribucion_id)).filter(Boolean);
		if (labels.length === 0) return '';
		const noun = labels.length === 1 ? 'la evidencia de tipo' : 'las evidencias de tipo';
		return `, según ${noun} ${joinHuman(labels, 'y')}`;
	}

	// Frase de una propuesta para el resumen: "a Lope de Vega, según las evidencias de tipo Tradicional y Estilometría léxica".
	function getProposalNarrative(proposal: DraftProposal): string {
		const composicion = getComposicionTerm(proposal.composicion_autoria_id);
		if (composicion === 'desconocida') {
			return 'de autoría desconocida';
		}
		const names = uniqueIds(proposal.autor_ids).map((authorId) => authorNameById.get(authorId) ?? authorId);
		if (names.length === 0) {
			return 'con una atribución aún sin autor definido';
		}
		const who = composicion === 'colaborada' ? `la colaboración de ${joinHuman(names, 'y')}` : joinHuman(names, 'y');
		return `a ${who}${getProposalEvidencePhrase(proposal)}`;
	}

	function getJornadaLabel(jornadaId: string | null): string {
		if (!jornadaId) return 'La obra';
		const jornada = jornadas.find((item) => item.jornada_id === jornadaId);
		return jornada ? `La jornada ${jornada.jornada_num}` : 'La jornada';
	}

	function getGroupSummary(group: DraftGroup): string {
		const subject = group.jornada_id ? getJornadaLabel(group.jornada_id) : 'La obra';
		const withProposals = group.propuestas.filter(
			(proposal) =>
				getComposicionTerm(proposal.composicion_autoria_id) === 'desconocida' ||
				uniqueIds(proposal.autor_ids).length > 0 ||
				proposal.evidencias.length > 0
		);
		if (withProposals.length === 0) {
			return `${subject} todavía no tiene autoría registrada.`;
		}
		if (withProposals.length === 1) {
			return `${subject} se atribuye ${getProposalNarrative(withProposals[0])}.`;
		}
		const options = joinHuman(withProposals.map((proposal) => getProposalNarrative(proposal)), 'o');
		return `${subject} tiene una autoría disputada: se atribuye ${options}.`;
	}

	function getOverallSummary(): string {
		if (groups.length === 0) return 'No hay autorías registradas. Si la obra no tiene autor identificado, déjala sin propuestas.';
		return groups
			.map((group) => getGroupSummary(group))
			.join(' ');
	}

	function getUsedEvidenceTypeIds(proposal: DraftProposal): Set<string> {
		return new Set(proposal.evidencias.map((evidencia) => evidencia.tipo_atribucion_id).filter(Boolean));
	}

	function getFirstAvailableTipoId(proposal: DraftProposal | null = null): string {
		const used = proposal ? getUsedEvidenceTypeIds(proposal) : new Set<string>();
		return tipos.find((tipo) => !used.has(tipo.termino_id))?.termino_id ?? '';
	}

	function createEmptyEvidence(proposal: DraftProposal | null = null): DraftEvidence {
		return {
			local_id: newLocalId('evidencia'),
			atribucion_evidencia_id: null,
			tipo_atribucion_id: getFirstAvailableTipoId(proposal),
			fuente_autoria: ''
		};
	}

	function createEmptyProposal(): DraftProposal {
		const proposal: DraftProposal = {
			local_id: newLocalId('propuesta'),
			atribucion_id: null,
			composicion_autoria_id: getComposicionId('individual'),
			perfil_metrico: false,
			autor_ids: [],
			evidencias: []
		};
		proposal.evidencias = [createEmptyEvidence(proposal)];
		return proposal;
	}

	function createEmptyGroup(jornadaId: string | null): DraftGroup {
		return {
			local_id: newLocalId('grupo'),
			grupo_atribucion_id: null,
			jornada_id: jornadaId,
			propuestas: []
		};
	}

	function inferDefaultScope(nextGroups: DraftGroup[]): ScopeView {
		const hasJornada = nextGroups.some((group) => Boolean(group.jornada_id));
		const hasGlobal = nextGroups.some((group) => !group.jornada_id);
		if (hasJornada && !hasGlobal) return 'jornadas';
		return 'obra';
	}

	function normalizeSnapshot() {
		return JSON.stringify(
			groups.map((group) => ({
				jornada_id: group.jornada_id,
				propuestas: group.propuestas.map((proposal) => ({
					composicion_autoria_id: proposal.composicion_autoria_id,
					...(canManagePerfilMetrico ? { perfil_metrico: proposal.perfil_metrico } : {}),
					autor_ids: uniqueIds(proposal.autor_ids),
					evidencias: proposal.evidencias.map((evidencia) => ({
						tipo_atribucion_id: evidencia.tipo_atribucion_id,
						fuente_autoria: evidencia.fuente_autoria.trim()
					}))
				}))
			}))
		);
	}

	function syncDirty() {
		if (effectiveReadOnly) return;
		const dirty = normalizeSnapshot() !== baselineSnapshot;
		setDirty(dirty, 'autoria');
		if (!dirty) setSaving(false, 'autoria');
	}

	function applyServerState(payload: AutoriaApiPayload) {
		const nextComposicionTermById = new Map(
			payload.catalogos.composiciones.map((item) => [
				item.termino_id,
				normalizeTerm(item.termino) as AutoriaComposicionTerm
			])
		);
		const nextGroups: DraftGroup[] = payload.grupos.map((group) => ({
			local_id: group.grupo_atribucion_id,
			grupo_atribucion_id: group.grupo_atribucion_id,
			jornada_id: group.jornada_id,
			propuestas: group.propuestas.map((proposal) => {
				const composicionTerm = nextComposicionTermById.get(proposal.composicion_autoria_id) ?? 'individual';
				return {
					local_id: proposal.atribucion_id,
					atribucion_id: proposal.atribucion_id,
					composicion_autoria_id: proposal.composicion_autoria_id,
					perfil_metrico: proposal.perfil_metrico ?? false,
					autor_ids:
						composicionTerm === 'desconocida'
							? []
							: uniqueIds(proposal.autores.map((autor) => autor.autor_id)),
					evidencias: proposal.evidencias.map((evidencia) => ({
						local_id: evidencia.atribucion_evidencia_id ?? newLocalId('evidencia'),
						atribucion_evidencia_id: evidencia.atribucion_evidencia_id,
						tipo_atribucion_id: evidencia.tipo_atribucion_id,
						fuente_autoria: evidencia.fuente_autoria ?? ''
					}))
				};
			})
		}));

		jornadas = [...payload.jornadas];
		autores = [...payload.autores];
		tipos = [...payload.catalogos.tipos];
		composiciones = [...payload.catalogos.composiciones];
		groups = nextGroups;
		scopeView = inferDefaultScope(nextGroups);
		if (!nextGroups.some((group) => group.propuestas.some((proposal) => proposal.local_id === openProposalId))) {
			openProposalId = null;
		}

		patchCurrentObra({
			total_versos: payload.obra.total_versos ?? null
		});
		baselineSnapshot = normalizeSnapshot();
		setDirty(false, 'autoria');
		setSaving(false, 'autoria');
	}

	async function refreshFromServer(silent = false) {
		if (loadingFromServer) return;
		loadingFromServer = true;
		const response = await fetch(`/api/obras/${props.obraId}/autoria`);
		loadingFromServer = false;
		loading = false;

		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			const message = body?.message ?? 'No se pudo cargar la autoría de la obra.';
			loadError = message;
			if (!silent) pushToast('error', message);
			return;
		}

		loadError = null;
		const payload = (await response.json()) as AutoriaApiPayload;
		applyServerState(payload);
	}

	function addProposal(groupId: string) {
		const proposal = createEmptyProposal();
		groups = groups.map((group) =>
			group.local_id === groupId ? { ...group, propuestas: [...group.propuestas, proposal] } : group
		);
		openProposalId = proposal.local_id;
		syncDirty();
	}

	// Añade una propuesta al grupo (global o de la jornada indicada), creándolo si aún no existe.
	function addProposalToScope(jornadaId: string | null) {
		const existing = groups.find((group) =>
			jornadaId ? group.jornada_id === jornadaId : !group.jornada_id
		);
		if (existing) {
			addProposal(existing.local_id);
			return;
		}
		const group = createEmptyGroup(jornadaId);
		const proposal = createEmptyProposal();
		group.propuestas = [proposal];
		groups = [...groups, group];
		scopeView = jornadaId ? 'jornadas' : 'obra';
		openProposalId = proposal.local_id;
		syncDirty();
	}

	function removeProposal(groupId: string, proposalId: string) {
		groups = groups
			.map((group) =>
				group.local_id === groupId
					? { ...group, propuestas: group.propuestas.filter((proposal) => proposal.local_id !== proposalId) }
					: group
			)
			// Un grupo sin propuestas no aporta nada: se elimina automáticamente.
			.filter((group) => group.propuestas.length > 0);
		if (openProposalId === proposalId) openProposalId = null;
		syncDirty();
	}

	function patchProposal(groupId: string, proposalId: string, patch: Partial<DraftProposal>) {
		groups = groups.map((group) => {
			if (group.local_id !== groupId) return group;
			const propuestas = group.propuestas.map((proposal) => {
				if (proposal.local_id !== proposalId) return proposal;
				const next = { ...proposal, ...patch };
				const composicionTerm = getComposicionTerm(next.composicion_autoria_id);
				if (composicionTerm !== 'individual') next.perfil_metrico = false;
				if (composicionTerm === 'desconocida') next.autor_ids = [];
				return next;
			});
			return { ...group, propuestas };
		});
		syncDirty();
	}

	function addEvidence(groupId: string, proposalId: string) {
		let newEvidenceId: string | null = null;
		groups = groups.map((group) => {
			if (group.local_id !== groupId) return group;
			const propuestas = group.propuestas.map((proposal) => {
				if (proposal.local_id !== proposalId) return proposal;
				const evidencia = createEmptyEvidence(proposal);
				if (!evidencia.tipo_atribucion_id) return proposal;
				newEvidenceId = evidencia.local_id;
				return { ...proposal, evidencias: [...proposal.evidencias, evidencia] };
			});
			return { ...group, propuestas };
		});
		if (newEvidenceId) openEvidenceIds = [...openEvidenceIds, newEvidenceId];
		syncDirty();
	}

	function patchEvidence(groupId: string, proposalId: string, evidenceId: string, patch: Partial<DraftEvidence>) {
		groups = groups.map((group) => {
			if (group.local_id !== groupId) return group;
			const propuestas = group.propuestas.map((proposal) =>
				proposal.local_id === proposalId
					? {
							...proposal,
							evidencias: proposal.evidencias.map((evidencia) =>
								evidencia.local_id === evidenceId ? { ...evidencia, ...patch } : evidencia
							)
						}
					: proposal
			);
			return { ...group, propuestas };
		});
		syncDirty();
	}

	function removeEvidence(groupId: string, proposalId: string, evidenceId: string) {
		groups = groups.map((group) => {
			if (group.local_id !== groupId) return group;
			const propuestas = group.propuestas.map((proposal) =>
				proposal.local_id === proposalId
					? { ...proposal, evidencias: proposal.evidencias.filter((evidencia) => evidencia.local_id !== evidenceId) }
					: proposal
			);
			return { ...group, propuestas };
		});
		syncDirty();
	}

	function setScope(next: ScopeView) {
		scopeView = next;
	}

	function toggleProposalEditor(proposalId: string) {
		openProposalId = openProposalId === proposalId ? null : proposalId;
		openEvidenceIds = [];
	}

	function toggleEvidence(evidenceId: string) {
		openEvidenceIds = isEvidenceOpen(evidenceId)
			? openEvidenceIds.filter((id) => id !== evidenceId)
			: [...openEvidenceIds, evidenceId];
	}

	function evidenceSummary(evidencia: DraftEvidence): string {
		const plain = evidencia.fuente_autoria
			.replace(/\[([^\]]*)\]\([^)]*\)/g, '$1')
			.replace(/[#*`>_-]/g, ' ')
			.replace(/\s+/g, ' ')
			.trim();
		if (!plain) return 'Sin fuente';
		return plain.length > 80 ? `${plain.slice(0, 80)}…` : plain;
	}

	function validateClientPayload(): string | null {
		const jornadaSet = new Set(jornadas.map((jornada) => jornada.jornada_id));
		if (groups.filter((group) => !group.jornada_id).length > 1) {
			return 'Solo puede existir una autoría global para la obra completa.';
		}
		const jornadaGroupIds = groups.filter((group) => group.jornada_id).map((group) => group.jornada_id as string);
		if (new Set(jornadaGroupIds).size !== jornadaGroupIds.length) {
			return 'Solo puede existir un grupo de autoría por jornada.';
		}
		for (const group of groups) {
			if (group.jornada_id && !jornadaSet.has(group.jornada_id)) return 'Hay grupos asociados a jornadas inválidas.';
			const proposalKeys = new Set<string>();
			for (const proposal of group.propuestas) {
				if (!proposal.composicion_autoria_id) return 'Todas las propuestas deben tener tipología de autoría.';
				if (proposal.evidencias.length === 0) return 'Todas las propuestas deben tener al menos una evidencia.';

				const evidenceTypes = new Set<string>();
				for (const evidencia of proposal.evidencias) {
					if (!evidencia.tipo_atribucion_id) return 'Todas las evidencias deben tener tipo de atribución.';
					if (evidenceTypes.has(evidencia.tipo_atribucion_id)) {
						return 'No se puede repetir el tipo de evidencia dentro de una propuesta.';
					}
					evidenceTypes.add(evidencia.tipo_atribucion_id);
				}

				const composicionTerm = getComposicionTerm(proposal.composicion_autoria_id);
				const authorIds = uniqueIds(proposal.autor_ids);
				if (composicionTerm === 'individual' && authorIds.length !== 1) {
					return 'La tipología individual exige exactamente 1 autor.';
				}
				if (composicionTerm === 'colaborada' && authorIds.length < 2) {
					return 'La tipología colaborada exige 2 o más autores.';
				}
				if (composicionTerm === 'desconocida' && authorIds.length !== 0) {
					return 'La tipología desconocida no permite seleccionar autores.';
				}
				if (proposal.perfil_metrico && (composicionTerm !== 'individual' || authorIds.length !== 1)) {
					return 'Solo una propuesta individual con un único autor puede alimentar perfiles métricos.';
				}

				const proposalKey = `${composicionTerm}:${authorIds.sort().join(',')}`;
				if (proposalKeys.has(proposalKey)) {
					return 'Ya existe una propuesta con la misma composición y autores en este grupo. Añade las fuentes como evidencias.';
				}
				proposalKeys.add(proposalKey);
			}
		}
		return null;
	}

	function buildPayload() {
		return {
			grupos: groups.map((group) => ({
				grupo_atribucion_id: group.grupo_atribucion_id,
				jornada_id: group.jornada_id,
				propuestas: group.propuestas.map((proposal) => ({
					atribucion_id: proposal.atribucion_id,
					composicion_autoria_id: proposal.composicion_autoria_id,
					...(canManagePerfilMetrico ? { perfil_metrico: proposal.perfil_metrico } : {}),
					autores:
						getComposicionTerm(proposal.composicion_autoria_id) === 'desconocida'
							? []
							: uniqueIds(proposal.autor_ids).map((autor_id, index) => ({
									autor_id,
									orden: index + 1
								})),
					evidencias: proposal.evidencias.map((evidencia) => ({
						atribucion_evidencia_id: evidencia.atribucion_evidencia_id,
						tipo_atribucion_id: evidencia.tipo_atribucion_id,
						fuente_autoria: evidencia.fuente_autoria.trim() || null
					}))
				}))
			}))
		};
	}

	async function save() {
		if (effectiveReadOnly || loadingFromServer || loading || savingNow) return;
		const validationError = validateClientPayload();
		if (validationError) {
			pushToast('error', validationError);
			return;
		}

		savingNow = true;
		setSaving(true, 'autoria');
		const response = await fetch(`/api/obras/${props.obraId}/autoria`, {
			method: 'PUT',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify(buildPayload())
		});
		savingNow = false;

		if (!response.ok) {
			setSaving(false, 'autoria');
			const body = await response.json().catch(() => ({}));
			const detail = Array.isArray(body?.details) ? body.details[0]?.message : null;
			pushToast('error', detail ?? body.message ?? 'No se pudo guardar la autoría.');
			return;
		}

		const payload = (await response.json()) as AutoriaApiPayload;
		applyServerState(payload);
		markSaved('autoria');
		props.onMetricaDirty?.();
		pushToast('success', 'Autoría guardada');
	}

	$effect(() => {
		const nextToken = props.saveRequestToken ?? 0;
		if (nextToken <= lastHandledSaveRequestToken) return;
		lastHandledSaveRequestToken = nextToken;
		void save();
	});

	$effect(() => {
		const missingIds = collectMissingAuthorIds(groups);
		const key = missingIds.join(',');
		if (!key || key === lastAuthorResolveKey) return;
		lastAuthorResolveKey = key;
		void resolveMissingAuthorNames(missingIds);
	});

	onMount(() => {
		void refreshFromServer(true);
	});
</script>

{#snippet evidenceEditor(group: DraftGroup, proposal: DraftProposal, evidencia: DraftEvidence)}
	{@const isOpen = isEvidenceOpen(evidencia.local_id)}
	<div class="flex items-center gap-2">
		<button
			type="button"
			class="flex min-w-0 flex-1 items-center gap-2 py-1 text-left"
			onclick={() => toggleEvidence(evidencia.local_id)}
		>
			<span class="shrink-0 text-[color:var(--muted-foreground)]">
				{#if isOpen}<ChevronDown size={16} />{:else}<ChevronRight size={16} />{/if}
			</span>
			<span class="shrink-0 text-sm font-medium text-[color:var(--gray-900)]">
				{getTipoTerm(evidencia.tipo_atribucion_id)}
			</span>
			{#if !isOpen}
				<span class="truncate text-sm text-[color:var(--muted-foreground)]">
					{evidenceSummary(evidencia)}
				</span>
			{/if}
		</button>
		<button
			type="button"
			class="shrink-0 p-1 text-[color:var(--muted-foreground)] hover:text-[color:var(--danger)] disabled:opacity-40"
			aria-label="Eliminar evidencia"
			onclick={() => removeEvidence(group.local_id, proposal.local_id, evidencia.local_id)}
			disabled={effectiveReadOnly || loadingFromServer || proposal.evidencias.length <= 1}
		>
			<Trash2 size={16} />
		</button>
	</div>

	{#if isOpen}
		<div class="mt-2 grid gap-3 pl-6 md:grid-cols-[minmax(0,16rem)_minmax(0,1fr)]">
			<label class="form-field">
				<span class="form-label">Tipo de evidencia</span>
				<CheckDropdown
					multiple={false}
					search={false}
					items={tipoItems}
					selectedIds={evidencia.tipo_atribucion_id ? [evidencia.tipo_atribucion_id] : []}
					placeholder="Selecciona tipo"
					disabled={effectiveReadOnly || loadingFromServer}
					onChange={(ids) =>
						patchEvidence(group.local_id, proposal.local_id, evidencia.local_id, {
							tipo_atribucion_id: (ids[0] as string | undefined) ?? ''
						})}
				/>
			</label>
			<div class="form-field">
				<span class="form-label">Fuente de autoría</span>
				<MarkdownEditorLite
					rows={3}
					class="mt-1"
					minHeightClass="min-h-24"
					value={evidencia.fuente_autoria}
					disabled={effectiveReadOnly || loadingFromServer}
					onChange={(nextValue) =>
						patchEvidence(group.local_id, proposal.local_id, evidencia.local_id, {
							fuente_autoria: nextValue
						})}
				/>
			</div>
		</div>
	{/if}
{/snippet}

{#snippet proposalEditor(group: DraftGroup, proposal: DraftProposal)}
	<div class="mt-3 border-t border-[color:var(--border)] pt-3">
		<div class="grid gap-3 md:grid-cols-2">
			<label class="form-field">
				<span class="form-label">Tipología de autoría</span>
				<CheckDropdown
					multiple={false}
					search={false}
					items={composicionItems}
					selectedIds={proposal.composicion_autoria_id ? [proposal.composicion_autoria_id] : []}
					placeholder="Selecciona tipología"
					disabled={effectiveReadOnly || loadingFromServer}
					onChange={(ids) =>
						patchProposal(group.local_id, proposal.local_id, {
							composicion_autoria_id: (ids[0] as string | undefined) ?? ''
						})}
				/>
			</label>
			<label class="form-field">
				<span class="form-label">Autores</span>
				<AuthorSelector
					knownAuthors={authorOptions}
					selectedIds={proposal.autor_ids}
					onAuthorSelected={(author) => mergeAuthors([author])}
					onChange={(ids) => patchProposal(group.local_id, proposal.local_id, { autor_ids: ids })}
					placeholder={
						getComposicionTerm(proposal.composicion_autoria_id) === 'desconocida'
							? 'Autoría desconocida'
							: 'Escribe y selecciona autores'
					}
					disabled={
						effectiveReadOnly ||
						loadingFromServer ||
						getComposicionTerm(proposal.composicion_autoria_id) === 'desconocida'
					}
				/>
			</label>
		</div>

		<div class="mt-4 border-t border-[color:var(--border)] pt-3">
			<span class="form-label-with-help mb-2 flex text-sm font-semibold text-[color:var(--gray-900)]">
				Evidencias
				<FieldHelpTooltip text={EVIDENCIAS_HELP} label="Ayuda sobre evidencias de atribución" />
			</span>
			{#if proposal.evidencias.length === 0}
				<p class="text-sm text-[color:var(--muted-foreground)]">
					Sin evidencias. Añade una solo si la autoría está disputada o discutida.
				</p>
			{:else}
				<div class="space-y-1">
					{#each proposal.evidencias as evidencia (evidencia.local_id)}
						<div>
							{@render evidenceEditor(group, proposal, evidencia)}
						</div>
					{/each}
				</div>
			{/if}
			{#if !effectiveReadOnly}
				<div class="mt-2">
					<Button
						variant="secondary"
						onclick={() => addEvidence(group.local_id, proposal.local_id)}
						disabled={loadingFromServer || !getFirstAvailableTipoId(proposal)}
					>
						Añadir evidencia
					</Button>
				</div>
			{/if}
		</div>

		{#if !effectiveReadOnly || canManagePerfilMetrico}
			<div class="mt-4 flex flex-wrap items-center justify-between gap-3 border-t border-[color:var(--border)] pt-3">
				{#if !effectiveReadOnly}
					<button
						type="button"
						class="inline-flex items-center gap-1.5 text-sm text-[color:var(--muted-foreground)] hover:text-[color:var(--danger)] disabled:opacity-40"
						onclick={() => removeProposal(group.local_id, proposal.local_id)}
						disabled={loadingFromServer}
					>
						<Trash2 size={16} />
						Eliminar propuesta
					</button>
				{/if}
				{#if canManagePerfilMetrico}
					<label class="ml-auto inline-flex items-center gap-2 text-sm">
						<input
							type="checkbox"
							checked={proposal.perfil_metrico}
							disabled={
								effectiveReadOnly ||
								loadingFromServer ||
								getComposicionTerm(proposal.composicion_autoria_id) !== 'individual' ||
								uniqueIds(proposal.autor_ids).length !== 1
							}
							onchange={(event) =>
								patchProposal(group.local_id, proposal.local_id, {
									perfil_metrico: event.currentTarget.checked
								})}
						/>
						<span class="form-label-with-help">
							Alimentar perfil métrico
							<FieldHelpTooltip text={PERFIL_HELP} label="Ayuda sobre perfil métrico" />
						</span>
					</label>
				{/if}
			</div>
		{/if}
	</div>
{/snippet}

{#snippet proposalCard(group: DraftGroup, proposal: DraftProposal)}
	{@const isOpen = openProposalId === proposal.local_id}
	<div class="border border-[color:var(--border)] bg-white p-3">
		<button
			type="button"
			class="flex w-full items-center justify-between gap-3 text-left"
			onclick={() => toggleProposalEditor(proposal.local_id)}
		>
			<div class="flex min-w-0 flex-wrap items-center gap-x-2 gap-y-1">
				<span class="shrink-0 text-[color:var(--muted-foreground)]">
					{#if isOpen}<ChevronDown size={16} />{:else}<ChevronRight size={16} />{/if}
				</span>
				<span class="text-sm font-semibold text-[color:var(--gray-900)]">{getProposalSummary(proposal)}</span>
				{#if proposal.evidencias.length > 0}
					{#each proposal.evidencias as evidencia (evidencia.local_id)}
						<span class="rounded-full border border-[color:var(--border)] bg-[color:var(--muted)] px-2 py-0.5 text-[11px] font-semibold text-[color:var(--gray-800)]">
							{getTipoTerm(evidencia.tipo_atribucion_id)}
						</span>
					{/each}
				{/if}
			</div>
			{#if canManagePerfilMetrico && proposal.perfil_metrico}
				<span class="shrink-0 rounded-full border border-sky-300 bg-sky-50 px-2 py-1 text-xs font-semibold text-sky-900">
					Perfil métrico
				</span>
			{/if}
		</button>
		{#if isOpen}
			{@render proposalEditor(group, proposal)}
		{/if}
	</div>
{/snippet}

{#snippet proposalsList(group: DraftGroup)}
	{#if group.propuestas.length > 1}
		<p class="mb-3 border-l-2 border-sky-300 bg-sky-50 px-3 py-2 text-sm text-sky-900">
			Los autores dentro de cada propuesta forman una misma autoría; las propuestas son alternativas entre sí.
		</p>
	{/if}

	<div class="space-y-3">
		{#each group.propuestas as proposal (proposal.local_id)}
			{@render proposalCard(group, proposal)}
		{/each}
	</div>
{/snippet}

<section class="space-y-4">
	{#if loading}
		<div class="card p-4">
			<p class="text-sm text-[color:var(--muted-foreground)]">Cargando módulo de autoría...</p>
		</div>
	{:else if loadError}
		<div class="card p-4">
			<p class="text-sm text-[color:var(--danger)]">{loadError}</p>
			<div class="mt-3">
				<Button variant="secondary" onclick={() => void refreshFromServer(false)} disabled={loadingFromServer}>
					Reintentar
				</Button>
			</div>
		</div>
	{:else}
		<div class="space-y-4">
			<div>
				<h2 class="text-lg font-semibold">Ámbito de atribución</h2>
				<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
					Registra una única autoría global para la obra completa. Si una jornada tiene una autoría propia, añádela en su jornada; dentro de una propuesta, varios autores indican colaboración y varias evidencias respaldan esa misma propuesta.
				</p>
				<div class="mt-3 inline-flex overflow-hidden rounded-md border border-[color:var(--border)] bg-white">
					<button
						type="button"
						class={`inline-flex items-center gap-2 px-3 py-2 text-sm font-medium ${
							scopeView === 'obra'
								? 'bg-[color:var(--gray-900)] text-white'
								: 'bg-white text-[color:var(--gray-900)]'
						}`}
						onclick={() => setScope('obra')}
					>
						Obra completa
						<span class="rounded-full border border-current px-2 py-0.5 text-xs">{globalGroups.length}</span>
					</button>
					<button
						type="button"
						class={`inline-flex items-center gap-2 border-l border-[color:var(--border)] px-3 py-2 text-sm font-medium ${
							scopeView === 'jornadas'
								? 'bg-[color:var(--gray-900)] text-white'
								: 'bg-white text-[color:var(--gray-900)]'
						}`}
						onclick={() => setScope('jornadas')}
					>
						Por jornadas
						<span class="rounded-full border border-current px-2 py-0.5 text-xs">{jornadaGroupCount}</span>
					</button>
				</div>
			</div>

			{#if scopeView === 'obra'}
				<section class="border-t border-[color:var(--border)] pt-4">
					<h3 class="mb-3 text-base font-semibold">Autoría global de la obra</h3>

					{#if globalGroups.length === 0}
						<p class="text-sm text-[color:var(--muted-foreground)]">Autoría no identificada.</p>
					{:else}
						{@render proposalsList(globalGroups[0])}
					{/if}

					{#if !effectiveReadOnly}
						<div class="mt-3">
							<Button
								variant="secondary"
								onclick={() => addProposalToScope(null)}
								disabled={loadingFromServer}
							>
								Añadir propuesta
							</Button>
						</div>
					{/if}
				</section>
			{:else}
				<section class="border-t border-[color:var(--border)] pt-4">
					<h3 class="mb-1 text-base font-semibold">Autoría por jornadas</h3>
					<p class="mb-4 text-sm text-[color:var(--muted-foreground)]">Añade una autoría de jornada solo cuando esa jornada necesite una atribución distinta de la global.</p>
					{#if jornadas.length === 0}
						<p class="text-sm text-[color:var(--muted-foreground)]">La obra aún no tiene jornadas definidas.</p>
					{:else}
						<div class="divide-y divide-[color:var(--border)]">
							{#each jornadas as jornada (jornada.jornada_id)}
								{@const jornadaGroup = (groupsByJornadaId.get(jornada.jornada_id) ?? [])[0]}
								<div class="py-4 first:pt-0 last:pb-0">
									<h4 class="mb-3 text-sm font-semibold">
										Jornada {jornada.jornada_num} (vv. {jornada.v_ini}-{jornada.v_fin})
									</h4>

									{#if !jornadaGroup}
										<p class="text-sm text-[color:var(--muted-foreground)]">Autoría no identificada.</p>
									{:else}
										{@render proposalsList(jornadaGroup)}
									{/if}

									{#if !effectiveReadOnly}
										<div class="mt-3">
											<Button
												variant="secondary"
												onclick={() => addProposalToScope(jornada.jornada_id)}
												disabled={loadingFromServer}
											>
												Añadir propuesta
											</Button>
										</div>
									{/if}
								</div>
							{/each}
						</div>
					{/if}
				</section>
			{/if}

			<div class="border-t border-[color:var(--border)] pt-4">
				<h3 class="mb-1 text-sm font-semibold text-[color:var(--muted-foreground)]">Resultado</h3>
				<p class="text-sm text-[color:var(--gray-900)]">
					{getOverallSummary()}
				</p>
			</div>
		</div>
	{/if}

	{#if !loading}
		<InternalCommentsPanel
			obraId={props.obraId}
			canComment={canComment}
			section="autoria"
			focusComentarioId={props.focusComentarioId}
			reloadKey={props.commentsReloadKey}
			title="Comentarios internos sobre autoría"
			emptyText="No hay comentarios internos sobre esta sección."
		/>
	{/if}
</section>
