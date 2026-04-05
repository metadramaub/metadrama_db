import type { EditorProfile } from '$lib/types/obra.types';
import type { Tables } from '$lib/types/database.types';
import {
	buildComentarioContextLabel,
	formatComentarioTipoLabel,
	loadComentarioContextMaps,
	type ComentarioTipoTerm
} from '$lib/server/comentarios';

const ADMIN_ROLES = new Set(['admin', 'ip']);
const DEFAULT_DAYS = 7;
const UNREAD_COUNTABLE_TYPES = new Set<DashboardNotificationType>([
	'assigned_editor',
	'assigned_review',
	'state_change',
	'comment'
]);

export type DashboardKpis = {
	totalObras: number;
	totalBorrador: number;
	totalPendienteRevision: number;
	totalPublicadas: number;
};

export type DashboardAssignedObra = {
	obraId: string;
	titulo: string;
	estadoId: string;
	estadoTerm: string;
	updatedAt: string | null;
};

export type DashboardPublishedSummary = {
	total: number;
	items: Array<{
		obraId: string;
		titulo: string;
		updatedAt: string | null;
	}>;
};

export type DashboardActivityItem = {
	id: string;
	type: 'state_change' | 'comment';
	obraId: string;
	obraTitulo: string;
	description: string;
	eventAt: string | null;
	tab: 'datos' | 'revision' | 'secuencias' | 'estructura' | 'autoria' | 'observaciones';
};

export type DashboardNotificationType =
	| 'assigned_editor'
	| 'assigned_review'
	| 'state_change'
	| 'comment'
	| 'low_medium_certainty';

export type DashboardNotificationItem = {
	id: string;
	type: DashboardNotificationType;
	obraId: string;
	obraTitulo: string;
	description: string;
	eventAt: string | null;
	tab: 'datos' | 'revision' | 'secuencias' | 'estructura' | 'autoria' | 'observaciones';
	badgeCount?: number;
};

function isAdminOrIp(profile: EditorProfile): boolean {
	return ADMIN_ROLES.has(profile.roleTerm);
}

function cutoffIso(days: number): string {
	const now = Date.now();
	return new Date(now - days * 24 * 60 * 60 * 1000).toISOString();
}

async function loadEstadoTerms(locals: App.Locals, estadoIds: string[]) {
	if (estadoIds.length === 0) {
		return new Map<string, string>();
	}
	const { data, error } = await locals.supabase
		.from('vocabularios')
		.select('termino_id,termino')
		.eq('categoria', 'estado')
		.in('termino_id', estadoIds);
	if (error) {
		return new Map<string, string>();
	}
	return new Map((data ?? []).map((row) => [row.termino_id, row.termino.trim().toLowerCase()]));
}

async function loadEstadoIdsByTerm(locals: App.Locals) {
	const { data } = await locals.supabase
		.from('vocabularios')
		.select('termino_id,termino')
		.eq('categoria', 'estado')
		.in('termino', ['borrador', 'pendiente', 'en_revision', 'publicado']);
	const map = new Map<string, string>();
	for (const row of data ?? []) {
		map.set(row.termino.trim().toLowerCase(), row.termino_id);
	}
	return map;
}

async function loadAssignedScopeObraIds(locals: App.Locals, profile: EditorProfile): Promise<string[]> {
	if (isAdminOrIp(profile)) {
		const all = await locals.supabase.from('obras').select('obra_id').limit(2000);
		return [...new Set((all.data ?? []).map((row) => row.obra_id))];
	}

	const [asEditorResp, asReviewerResp] = await Promise.all([
		locals.supabase.from('obras').select('obra_id').eq('editor_asignado', profile.userId).limit(2000),
		locals.supabase.from('obras_revisores').select('obra_id').eq('revisor_id', profile.userId).limit(2000)
	]);

	const assigned = new Set<string>();
	for (const row of asEditorResp.data ?? []) {
		assigned.add(row.obra_id);
	}
	for (const row of asReviewerResp.data ?? []) {
		assigned.add(row.obra_id);
	}
	return [...assigned];
}

function normalizeObraTitle(value: string | null | undefined): string | null {
	const normalized = (value ?? '').trim();
	return normalized.length > 0 ? normalized : null;
}

function setObraTitle(titleMap: Map<string, string>, obraId: string, title: string | null | undefined) {
	const normalized = normalizeObraTitle(title);
	if (!normalized) return;
	titleMap.set(obraId, normalized);
}

function resolveObraTitle(titleMap: Map<string, string>, obraId: string): string {
	return normalizeObraTitle(titleMap.get(obraId)) ?? 'Obra';
}

async function loadTitleMapForIds(locals: App.Locals, obraIds: string[]) {
	if (obraIds.length === 0) {
		return new Map<string, string>();
	}
	const { data } = await locals.supabase.from('obras').select('obra_id,titulo').in('obra_id', obraIds);
	const titleMap = new Map<string, string>();
	for (const row of data ?? []) {
		setObraTitle(titleMap, row.obra_id, row.titulo);
	}
	return titleMap;
}

async function hydrateMissingObraTitles(
	locals: App.Locals,
	titleMap: Map<string, string>,
	obraIds: string[]
) {
	const missingIds = [...new Set(obraIds)].filter((obraId) => !normalizeObraTitle(titleMap.get(obraId)));
	if (missingIds.length === 0) return;
	const resolvedTitles = await loadTitleMapForIds(locals, missingIds);
	for (const [obraId, title] of resolvedTitles.entries()) {
		setObraTitle(titleMap, obraId, title);
	}
}

function normalizeEventAt(value: string | null | undefined): string | null {
	if (!value) return null;
	const timestamp = Date.parse(value);
	if (Number.isNaN(timestamp)) return null;
	return new Date(timestamp).toISOString();
}

function compareByEventDesc(a: { eventAt: string | null }, b: { eventAt: string | null }) {
	const aTs = a.eventAt ? Date.parse(a.eventAt) : 0;
	const bTs = b.eventAt ? Date.parse(b.eventAt) : 0;
	return bTs - aTs;
}

function isUnreadCountableNotification(type: DashboardNotificationType): boolean {
	return UNREAD_COUNTABLE_TYPES.has(type);
}

function commentTab(
	comment: Pick<Tables<'comentarios_internos'>, 'seccion' | 'secuencia_id' | 'jornada_id' | 'cuadro_id'>
): 'datos' | 'revision' | 'secuencias' | 'estructura' | 'autoria' | 'observaciones' {
	if (comment.seccion === 'datos') return 'datos';
	if (comment.seccion === 'estructura') return 'estructura';
	if (comment.seccion === 'secuencias') return 'secuencias';
	if (comment.seccion === 'autoria') return 'autoria';
	if (comment.seccion === 'observaciones') return 'observaciones';
	if (comment.seccion === 'revision') return 'revision';
	if (comment.secuencia_id) return 'secuencias';
	if (comment.jornada_id || comment.cuadro_id) return 'estructura';
	return 'revision';
}

async function loadCommentContextLabels(
	locals: App.Locals,
	commentRows: Array<
		Pick<
			Tables<'comentarios_internos'>,
			| 'comentario_id'
			| 'seccion'
			| 'secuencia_id'
			| 'jornada_id'
			| 'cuadro_id'
			| 'tipo_comentario_id'
		>
	>
): Promise<{ contextByCommentId: Map<string, string>; typeByCommentId: Map<string, string> }> {
	if (commentRows.length === 0) {
		return {
			contextByCommentId: new Map(),
			typeByCommentId: new Map()
		};
	}

	const tipoIds = [
		...new Set(commentRows.map((row) => row.tipo_comentario_id).filter(Boolean) as string[])
	];

	const [contextMaps, tiposResp] = await Promise.all([
		loadComentarioContextMaps(locals, commentRows),
		tipoIds.length > 0
			? locals.supabase
					.from('vocabularios')
					.select('termino_id,termino')
					.eq('categoria', 'tipo_comentario')
					.in('termino_id', tipoIds)
			: Promise.resolve({
					data: [] as Pick<Tables<'vocabularios'>, 'termino_id' | 'termino'>[]
				})
	]);

	const tipoById = new Map(
		(tiposResp.data ?? []).map((row) => [
			row.termino_id,
			row.termino.trim().toLowerCase() as ComentarioTipoTerm
		])
	);
	const contextByCommentId = new Map<string, string>();
	const typeByCommentId = new Map<string, string>();

	for (const row of commentRows) {
		const context = buildComentarioContextLabel(row, contextMaps) ?? 'Revisión final';
		const tipoTerm = row.tipo_comentario_id ? (tipoById.get(row.tipo_comentario_id) ?? 'general') : 'general';

		contextByCommentId.set(row.comentario_id, context);
		typeByCommentId.set(row.comentario_id, formatComentarioTipoLabel(tipoTerm));
	}

	return {
		contextByCommentId,
		typeByCommentId
	};
}

async function resolveLowMediumCertezaIds(locals: App.Locals): Promise<string[]> {
	const { data } = await locals.supabase
		.from('vocabularios')
		.select('termino_id')
		.eq('categoria', 'certeza_editor')
		.in('termino', ['baja', 'media']);
	return [...new Set((data ?? []).map((row) => row.termino_id))];
}

export async function getDashboardKpis(locals: App.Locals, profile: EditorProfile): Promise<DashboardKpis> {
	const estadoIdsByTerm = await loadEstadoIdsByTerm(locals);
	const borradorId = estadoIdsByTerm.get('borrador');
	const pendienteId = estadoIdsByTerm.get('pendiente');
	const enRevisionId = estadoIdsByTerm.get('en_revision');
	const publicadoId = estadoIdsByTerm.get('publicado');

	if (isAdminOrIp(profile)) {
		const [totalResp, borradorResp, pendienteResp, publicadoResp] = await Promise.all([
			locals.supabase.from('obras').select('obra_id', { count: 'exact', head: true }),
			borradorId
				? locals.supabase.from('obras').select('obra_id', { count: 'exact', head: true }).eq('estado', borradorId)
				: Promise.resolve({ count: 0 }),
			pendienteId || enRevisionId
				? locals.supabase
						.from('obras')
						.select('obra_id', { count: 'exact', head: true })
						.in('estado', [pendienteId, enRevisionId].filter(Boolean) as string[])
				: Promise.resolve({ count: 0 }),
			publicadoId
				? locals.supabase.from('obras').select('obra_id', { count: 'exact', head: true }).eq('estado', publicadoId)
				: Promise.resolve({ count: 0 })
		]);
		return {
			totalObras: totalResp.count ?? 0,
			totalBorrador: borradorResp.count ?? 0,
			totalPendienteRevision: pendienteResp.count ?? 0,
			totalPublicadas: publicadoResp.count ?? 0
		};
	}

	let query = locals.supabase.from('obras').select('estado').eq('editor_asignado', profile.userId).limit(2000);
	const { data } = await query;
	const rows = data ?? [];
	const total = rows.length;
	const borrador = borradorId ? rows.filter((row) => row.estado === borradorId).length : 0;
	const pendienteRevision = rows.filter(
		(row) => row.estado === pendienteId || row.estado === enRevisionId
	).length;
	const publicadas = publicadoId ? rows.filter((row) => row.estado === publicadoId).length : 0;
	return {
		totalObras: total,
		totalBorrador: borrador,
		totalPendienteRevision: pendienteRevision,
		totalPublicadas: publicadas
	};
}

export async function getAssignedEditorObras(
	locals: App.Locals,
	profile: EditorProfile
): Promise<DashboardAssignedObra[]> {
	const { data } = await locals.supabase
		.from('obras')
		.select('obra_id,titulo,estado,updated_at')
		.eq('editor_asignado', profile.userId)
		.order('updated_at', { ascending: false })
		.limit(200);

	const rows = data ?? [];
	const estadoMap = await loadEstadoTerms(
		locals,
		[...new Set(rows.map((row) => row.estado))]
	);

	return rows.map((row) => ({
		obraId: row.obra_id,
		titulo: row.titulo,
		estadoId: row.estado,
		estadoTerm: estadoMap.get(row.estado) ?? row.estado,
		updatedAt: row.updated_at
	}));
}

export async function getPublishedAssignedSummary(
	locals: App.Locals,
	profile: EditorProfile
): Promise<DashboardPublishedSummary> {
	const estadoIdsByTerm = await loadEstadoIdsByTerm(locals);
	const publicadoId = estadoIdsByTerm.get('publicado');
	if (!publicadoId) {
		return { total: 0, items: [] };
	}

	const totalResp = await locals.supabase
		.from('obras')
		.select('obra_id', { count: 'exact', head: true })
		.eq('editor_asignado', profile.userId)
		.eq('estado', publicadoId);

	const listResp = await locals.supabase
		.from('obras')
		.select('obra_id,titulo,updated_at')
		.eq('editor_asignado', profile.userId)
		.eq('estado', publicadoId)
		.order('updated_at', { ascending: false })
		.limit(12);

	return {
		total: totalResp.count ?? 0,
		items: (listResp.data ?? []).map((row) => ({
			obraId: row.obra_id,
			titulo: row.titulo,
			updatedAt: row.updated_at
		}))
	};
}

export async function getRecentActivity(
	locals: App.Locals,
	profile: EditorProfile,
	days = DEFAULT_DAYS,
	limit = 20
): Promise<DashboardActivityItem[]> {
	const sinceIso = cutoffIso(days);
	const scopeIds = await loadAssignedScopeObraIds(locals, profile);
	const scoped = !isAdminOrIp(profile);

	let stateChangesQuery = locals.supabase
		.from('obras')
		.select('obra_id,titulo,estado,fecha_cambio_estado')
		.gte('fecha_cambio_estado', sinceIso)
		.order('fecha_cambio_estado', { ascending: false })
		.limit(200);

	let commentsQuery = locals.supabase
		.from('comentarios_internos')
		.select(
			'comentario_id,obra_id,created_at,seccion,secuencia_id,jornada_id,cuadro_id,tipo_comentario_id'
		)
		.gte('created_at', sinceIso)
		.order('created_at', { ascending: false })
		.limit(300);

	if (scoped) {
		if (scopeIds.length === 0) {
			return [];
		}
		stateChangesQuery = stateChangesQuery.in('obra_id', scopeIds);
		commentsQuery = commentsQuery.in('obra_id', scopeIds);
	}

	const [stateResp, commentsResp] = await Promise.all([stateChangesQuery, commentsQuery]);
	const stateRows = stateResp.data ?? [];
	const commentRows = commentsResp.data ?? [];
	const titleMap = new Map<string, string>();
	for (const row of stateRows) {
		setObraTitle(titleMap, row.obra_id, row.titulo);
	}
	await hydrateMissingObraTitles(
		locals,
		titleMap,
		commentRows.map((row) => row.obra_id)
	);

	const [estadoMap, commentMeta] = await Promise.all([
		loadEstadoTerms(
			locals,
			[...new Set(stateRows.map((row) => row.estado))]
		),
		loadCommentContextLabels(locals, commentRows)
	]);

	const activities: DashboardActivityItem[] = [
		...stateRows.map((row) => ({
			id: `state-${row.obra_id}-${row.fecha_cambio_estado ?? 'null'}`,
			type: 'state_change' as const,
			obraId: row.obra_id,
			obraTitulo: normalizeObraTitle(row.titulo) ?? resolveObraTitle(titleMap, row.obra_id),
			description: `Cambio de estado a ${estadoMap.get(row.estado) ?? row.estado}`,
			eventAt: normalizeEventAt(row.fecha_cambio_estado),
			tab: 'revision' as const
		})),
		...commentRows.map((row) => ({
			id: `comment-${row.comentario_id}`,
			type: 'comment' as const,
			obraId: row.obra_id,
			obraTitulo: resolveObraTitle(titleMap, row.obra_id),
			description: `Nuevo comentario (${commentMeta.typeByCommentId.get(row.comentario_id) ?? 'general'}) en ${commentMeta.contextByCommentId.get(row.comentario_id) ?? 'Revisión final'}`,
			eventAt: normalizeEventAt(row.created_at),
			tab: commentTab(row)
		}))
	];

	return activities.sort(compareByEventDesc).slice(0, limit);
}

export async function getNotifications(
	locals: App.Locals,
	profile: EditorProfile,
	days = DEFAULT_DAYS,
	limit = 100
): Promise<DashboardNotificationItem[]> {
	const sinceIso = cutoffIso(days);
	const admin = isAdminOrIp(profile);
	const scopeIds = await loadAssignedScopeObraIds(locals, profile);

	let editAssignmentsQuery = locals.supabase
		.from('obras')
		.select('obra_id,titulo,created_at')
		.not('editor_asignado', 'is', null)
		.gte('created_at', sinceIso)
		.order('created_at', { ascending: false })
		.limit(300);

	let reviewAssignmentsQuery = locals.supabase
		.from('obras_revisores')
		.select('obra_id,created_at,revisor_id')
		.gte('created_at', sinceIso)
		.order('created_at', { ascending: false })
		.limit(400);

	let stateChangesQuery = locals.supabase
		.from('obras')
		.select('obra_id,titulo,estado,fecha_cambio_estado')
		.gte('fecha_cambio_estado', sinceIso)
		.order('fecha_cambio_estado', { ascending: false })
		.limit(300);

	let commentsQuery = locals.supabase
		.from('comentarios_internos')
		.select(
			'comentario_id,obra_id,created_at,seccion,secuencia_id,jornada_id,cuadro_id,tipo_comentario_id'
		)
		.gte('created_at', sinceIso)
		.order('created_at', { ascending: false })
		.limit(400);

	if (!admin) {
		editAssignmentsQuery = editAssignmentsQuery.eq('editor_asignado', profile.userId);
		reviewAssignmentsQuery = reviewAssignmentsQuery.eq('revisor_id', profile.userId);

		if (scopeIds.length === 0) {
			return [];
		}
		stateChangesQuery = stateChangesQuery.in('obra_id', scopeIds);
		commentsQuery = commentsQuery.in('obra_id', scopeIds);
	}

	const [editAssignResp, reviewAssignResp, stateResp, commentsResp] = await Promise.all([
		editAssignmentsQuery,
		reviewAssignmentsQuery,
		stateChangesQuery,
		commentsQuery
	]);

	const editAssignRows = editAssignResp.data ?? [];
	const reviewAssignRows = reviewAssignResp.data ?? [];
	const stateRows = stateResp.data ?? [];
	const commentRows = commentsResp.data ?? [];

	const titleMap = new Map<string, string>();
	for (const row of editAssignRows) {
		setObraTitle(titleMap, row.obra_id, row.titulo);
	}
	for (const row of stateRows) {
		setObraTitle(titleMap, row.obra_id, row.titulo);
	}
	await hydrateMissingObraTitles(locals, titleMap, [
		...reviewAssignRows.map((row) => row.obra_id),
		...commentRows.map((row) => row.obra_id),
		...stateRows.map((row) => row.obra_id)
	]);

	const [estadoMap, commentMeta] = await Promise.all([
		loadEstadoTerms(
			locals,
			[...new Set(stateRows.map((row) => row.estado))]
		),
		loadCommentContextLabels(locals, commentRows)
	]);

	const feed: DashboardNotificationItem[] = [
		...editAssignRows.map((row) => ({
			id: `assign-editor-${row.obra_id}-${row.created_at ?? 'null'}`,
			type: 'assigned_editor' as const,
			obraId: row.obra_id,
			obraTitulo: resolveObraTitle(titleMap, row.obra_id),
			description: 'Nueva obra asignada para edición',
			eventAt: normalizeEventAt(row.created_at),
			tab: 'datos' as const
		})),
		...reviewAssignRows.map((row) => ({
			id: `assign-review-${row.obra_id}-${row.revisor_id}-${row.created_at}`,
			type: 'assigned_review' as const,
			obraId: row.obra_id,
			obraTitulo: resolveObraTitle(titleMap, row.obra_id),
			description: 'Nueva obra asignada para revisión',
			eventAt: normalizeEventAt(row.created_at),
			tab: 'revision' as const
		})),
		...stateRows.map((row) => ({
			id: `state-${row.obra_id}-${row.fecha_cambio_estado ?? 'null'}`,
			type: 'state_change' as const,
			obraId: row.obra_id,
			obraTitulo: normalizeObraTitle(row.titulo) ?? resolveObraTitle(titleMap, row.obra_id),
			description: `Cambio de estado a ${estadoMap.get(row.estado) ?? row.estado}`,
			eventAt: normalizeEventAt(row.fecha_cambio_estado),
			tab: 'revision' as const
		})),
		...commentRows.map((row) => ({
			id: `comment-${row.comentario_id}`,
			type: 'comment' as const,
			obraId: row.obra_id,
			obraTitulo: resolveObraTitle(titleMap, row.obra_id),
			description: `Nuevo comentario (${commentMeta.typeByCommentId.get(row.comentario_id) ?? 'general'}) en ${commentMeta.contextByCommentId.get(row.comentario_id) ?? 'Revisión final'}`,
			eventAt: normalizeEventAt(row.created_at),
			tab: commentTab(row)
		}))
	];

	if (admin) {
		const lowMedIds = await resolveLowMediumCertezaIds(locals);
		if (lowMedIds.length > 0) {
			const { data: lowRows } = await locals.supabase
				.from('secuencias_metricas')
				.select('obra_id,secuencia_id,updated_at,certeza_editor')
				.in('certeza_editor', lowMedIds)
				.order('updated_at', { ascending: false })
				.limit(4000);

			const grouped = new Map<string, { total: number; latest: string | null }>();
			for (const row of lowRows ?? []) {
				const current = grouped.get(row.obra_id) ?? { total: 0, latest: null };
				current.total += 1;
				const normalized = normalizeEventAt(row.updated_at);
				if (!current.latest || (normalized && Date.parse(normalized) > Date.parse(current.latest))) {
					current.latest = normalized;
				}
				grouped.set(row.obra_id, current);
			}

			await hydrateMissingObraTitles(locals, titleMap, [...grouped.keys()]);

			for (const [obraId, info] of grouped.entries()) {
				feed.push({
					id: `certainty-${obraId}`,
					type: 'low_medium_certainty',
					obraId,
					obraTitulo: resolveObraTitle(titleMap, obraId),
					description: 'Secuencias con certeza baja/media',
					eventAt: info.latest,
					tab: 'secuencias',
					badgeCount: info.total
				});
			}
		}
	}

	return feed.sort(compareByEventDesc).slice(0, limit);
}

async function getActivityLastSeenAt(locals: App.Locals, userId: string): Promise<string | null> {
	const { data } = await locals.supabase
		.from('dashboard_activity_state')
		.select('last_seen_at')
		.eq('user_id', userId)
		.maybeSingle();
	return normalizeEventAt(data?.last_seen_at ?? null);
}

export async function markDashboardActivitySeen(
	locals: App.Locals,
	profile: EditorProfile
): Promise<{ lastSeenAt: string | null; errorMessage: string | null }> {
	const nowIso = new Date().toISOString();
	const { error } = await locals.supabase
		.from('dashboard_activity_state')
		.upsert(
			{
				user_id: profile.userId,
				last_seen_at: nowIso,
				updated_at: nowIso
			},
			{ onConflict: 'user_id' }
		);
	if (error) {
		return {
			lastSeenAt: null,
			errorMessage: error.message
		};
	}
	return {
		lastSeenAt: nowIso,
		errorMessage: null
	};
}

export async function countUnreadNotifications(
	locals: App.Locals,
	profile: EditorProfile,
	days = DEFAULT_DAYS
): Promise<number> {
	const [notifications, lastSeenAt] = await Promise.all([
		getNotifications(locals, profile, days, 500),
		getActivityLastSeenAt(locals, profile.userId)
	]);

	const countableNotifications = notifications.filter((item) =>
		isUnreadCountableNotification(item.type)
	);

	if (!lastSeenAt) {
		return countableNotifications.length;
	}
	const lastSeenTs = Date.parse(lastSeenAt);
	if (Number.isNaN(lastSeenTs)) {
		return countableNotifications.length;
	}
	return countableNotifications.filter((item) => {
		if (!item.eventAt) return false;
		const eventTs = Date.parse(item.eventAt);
		return !Number.isNaN(eventTs) && eventTs > lastSeenTs;
	}).length;
}
