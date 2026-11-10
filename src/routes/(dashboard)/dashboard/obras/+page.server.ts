import { relacionObras } from '$lib/server/modelo-obras';
import { modeloEditorialActivo } from '$lib/server/modelo-obras';
import type { PageServerLoad } from './$types';
import { buildObraCapabilities, canStartComplete } from '$lib/server/auth';
import { loadInternalVocabulario } from '$lib/server/catalogos-internos';
import { resolveDashboardObrasScopePlan } from '$lib/server/dashboard-obras';
import { loadAssignmentWorks } from '$lib/server/editor-management';
import type { Tables } from '$lib/types/database.types';
import { error } from '@sveltejs/kit';
import type { ObraControlRow } from '$lib/types/control-obras.types';
import { z } from 'zod';

const SCOPE_COOKIE = 'dashboard_obras_scope';
const OBRAS_LIST_SELECT = 'obra_id,titulo,slug,estado,editor_asignado,updated_at,visible_publico';
type DashboardObraRow = ObraControlRow;

export const load: PageServerLoad = async ({ locals, parent, url, cookies }) => {
	const parentData = await parent();
	const profile = parentData.profile;

	// Ámbito "Mis obras / Todas las obras": se recuerda por sesión. Si la URL no trae
	// ?scope, se usa la cookie de sesión (última selección); el resuelto se re-persiste.
	const explicitScope = url.searchParams.get('scope');
	const rawScope = (explicitScope ?? cookies.get(SCOPE_COOKIE) ?? '').trim().toLowerCase();
	let scope = rawScope === 'all' ? 'all' : 'mine';
	const isAdminOrIp = profile.roleTerm === 'admin' || profile.roleTerm === 'ip';
	if (scope === 'all' && !isAdminOrIp) {
		if(explicitScope==='all') throw error(403, 'El control de todas las obras está reservado a admin/IP.');
		scope='mine';
	}
	cookies.set(SCOPE_COOKIE, scope, { path: '/dashboard/obras', sameSite: 'lax' });
	// La RPC no existe antes de la migración: no se consulta una columna futura en ese caso.
	const capacidadImportador = parentData.importador;

	const reviewerAssignedResp = await locals.supabase
		.from('obras_revisores')
		.select('obra_id')
		.eq('revisor_id', profile.userId);
	if (reviewerAssignedResp.error) {
		throw error(
			500,
			`No se pudieron cargar asignaciones de revisor: ${reviewerAssignedResp.error.message}`
		);
	}
	const reviewerAssignedIds = [
		...new Set((reviewerAssignedResp.data ?? []).map((row) => row.obra_id))
	];
	const reviewerAssignedSet = new Set(reviewerAssignedIds);

	let query = locals.supabase
		.from(relacionObras())
		.select(modeloEditorialActivo() ? 'obra_id,titulo,slug,estado,editor_asignado,updated_at,visible_publico,tipo_ficha,fecha_inicio_trad,fecha_fin_trad,dataciones,autores,corpus,importacion_id,inicio_elaboracion,procedencia_registro' : OBRAS_LIST_SELECT)
		.order('updated_at', { ascending: false });
	if (capacidadImportador && !modeloEditorialActivo()) query = query.eq('tipo_ficha', 'completa');

	if (scope === 'mine') {
		const scopePlan = resolveDashboardObrasScopePlan(scope, profile.userId, reviewerAssignedIds);
		if (scopePlan.mode === 'editor_or_reviewer') {
			query = query.or(
				`editor_asignado.eq.${scopePlan.editorAssignedUserId},obra_id.in.(${scopePlan.reviewerAssignedIds.join(',')})`
			);
		} else if (scopePlan.mode === 'editor_only') {
			query = query.eq('editor_asignado', scopePlan.editorAssignedUserId);
		}
	}

	// Administración necesita el corpus completo para repartirlo, sin el antiguo límite de 200.
	const allAssignmentWorks = isAdminOrIp
		? await loadAssignmentWorks(locals, capacidadImportador !== null)
		: null;
	const { data: obras, error: obrasError } = allAssignmentWorks
		? {
				data: allAssignmentWorks.filter(
					(work) =>
						scope === 'all' ||
						work.editor_asignado === profile.userId ||
						reviewerAssignedSet.has(work.obra_id)
				),
				error: null
			}
		: await query.limit(200);
	if (obrasError) {
		throw error(500, `No se pudieron cargar las obras: ${obrasError.message}`);
	}

	const obraRows = (obras ?? []) as DashboardObraRow[];
	const editorIds = [
		...new Set(obraRows.map((obra) => obra.editor_asignado).filter(Boolean) as string[])
	];

	const [estadoOptions, editoresResp, editoresOptionsResp] = await Promise.all([
		loadInternalVocabulario(locals.supabase, ['estado']),
		editorIds.length > 0
			? locals.supabase.from('editores').select('user_id,nombre_completo').in('user_id', editorIds)
			: Promise.resolve({ data: [] }),
		isAdminOrIp
			? locals.supabase
					.from('editores')
					.select('user_id,nombre_completo,activo')
					.order('nombre_completo')
			: Promise.resolve({ data: [] })
	]);

	const editoresError = 'error' in editoresResp ? editoresResp.error : null;
	const editoresOptionsError = 'error' in editoresOptionsResp ? editoresOptionsResp.error : null;
	if (editoresError) {
		throw error(500, `No se pudieron cargar los editores: ${editoresError.message}`);
	}
	if (editoresOptionsError) {
		throw error(500, `No se pudo cargar el listado de editores: ${editoresOptionsError.message}`);
	}

	const estadoMap = new Map(
		estadoOptions.map((estadoItem) => [estadoItem.termino_id, estadoItem.termino])
	);
	const editoresMap = new Map(
		(editoresResp.data ?? []).map((row) => [row.user_id, row.nombre_completo])
	);

	let corpusOptions: {codigo:string;nombre:string}[]=[];
	if(modeloEditorialActivo()&&isAdminOrIp){
		const r=await locals.supabase.rpc('listar_corpus_gestion' as never);
		if(r.error)throw error(500,'No se pudieron cargar los corpus.');
		corpusOptions=z.array(z.object({codigo:z.string(),nombre:z.string()})).parse(r.data);
	}
	return {
		corpusOptions,
		modeloEditorial: modeloEditorialActivo(),
		puedeVerBasicas: capacidadImportador?.puede_importar ?? false,
		profile,
		scope,
		estadoOptions,
		editorOptions: editoresOptionsResp.data ?? [],
		obras: obraRows.map((obra) => {
			const estadoTerm = estadoMap.get(obra.estado) ?? obra.estado;
			const capabilities = buildObraCapabilities(
				profile,
				obra,
				estadoTerm.toLowerCase(),
				reviewerAssignedSet.has(obra.obra_id)
			);
			return {
				...obra,
				canStartComplete: modeloEditorialActivo() && canStartComplete(profile, obra),
				reviewer_ids:
					allAssignmentWorks?.find((work) => work.obra_id === obra.obra_id)?.reviewer_ids ?? [],
					estadoTerm: obra.tipo_ficha==='sin_ficha' ? 'Sin ficha' : obra.tipo_ficha==='basica' ? 'Básica' : estadoTerm,
				editorNombre: obra.editor_asignado
					? (editoresMap.get(obra.editor_asignado) ?? 'Sin nombre')
					: 'Sin asignar',
				...capabilities
			};
		})
	};
};
