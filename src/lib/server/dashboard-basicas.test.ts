import { describe, expect, it, vi } from 'vitest';
import type { EditorProfile } from '$lib/types/obra.types';
vi.mock('$lib/server/catalogos-internos', () => ({
	loadInternalVocabulario: async () => [
		{ termino_id: 'borrador', termino: 'borrador' },
		{ termino_id: 'publicado', termino: 'publicado' }
	]
}));
import { getDashboardKpis, getAssignedEditorObras, countUnreadNotifications } from './dashboard';

const profile = (roleTerm: string) => ({ roleTerm, userId: 'editor' }) as EditorProfile;
function entorno(conTipo = true) {
	const obras = [
		{
			obra_id: 'basica',
			titulo: 'Básica',
			tipo_ficha: 'minima',
			estado: 'borrador',
			editor_asignado: 'editor'
		},
		{
			obra_id: 'detallada',
			titulo: 'Detallada',
			tipo_ficha: 'completa',
			estado: 'borrador',
			editor_asignado: 'editor'
		},
		{
			obra_id: 'publicada',
			titulo: 'Publicada',
			tipo_ficha: 'completa',
			estado: 'publicado',
			editor_asignado: 'editor'
		}
	];
	const locals = {
		supabase: {
			from: (tabla: string) => {
				let rows = tabla === 'obras' ? [...obras] : [];
				let contar = false;
				const q = {
					select: (_s: string, options?: { count?: string }) => {
						contar = !!options?.count;
						return q;
					},
					eq: (key: string, value: unknown) => {
						if (key === 'tipo_ficha' && !conTipo) throw Error('Columna aún no instalada');
						rows = rows.filter((r) => r[key as keyof typeof r] === value);
						return q;
					},
					in: (key: string, values: unknown[]) => {
						rows = rows.filter((r) => values.includes(r[key as keyof typeof r]));
						return q;
					},
					order: () => q,
					limit: () => q,
					not: () => q,
					gte: () => q,
					gt: () => q,
					maybeSingle: async () => ({ data: null, error: null }),
					then: (resolve: (v: unknown) => unknown) =>
						Promise.resolve(
							resolve({ data: contar ? null : rows, count: rows.length, error: null })
						)
				};
				return q;
			}
		}
	} as unknown as App.Locals;
	return locals;
}
describe('contadores editoriales y fichas básicas', () => {
	it.each(['admin', 'editor'])(
		'el perfil %s cuenta solo las detalladas cuando se instala el importador',
		async (role) => {
			expect(await getDashboardKpis(entorno(), profile(role), true)).toEqual({
				totalObras: 2,
				totalBorrador: 1,
				totalPreviewListo: 0,
				totalPublicadas: 1
			});
		}
	);
	it('las básicas asignadas no aparecen como fichas detalladas por completar', async () => {
		expect(
			(await getAssignedEditorObras(entorno(), profile('editor'), true)).map((r) => r.obraId)
		).toEqual(['detallada', 'publicada']);
	});
	it('antes de la migración conserva las consultas sin pedir la columna futura', async () => {
		expect((await getDashboardKpis(entorno(false), profile('admin'))).totalObras).toBe(3);
		expect(await getAssignedEditorObras(entorno(false), profile('editor'))).toHaveLength(3);
	});
	it('el aviso de actividad usa el mismo universo editorial que la lista', async () => {
		expect(await countUnreadNotifications(entorno(), profile('admin'), 7, true)).toBe(4);
		expect(await countUnreadNotifications(entorno(false), profile('admin'))).toBe(6);
	});
});
