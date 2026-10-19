import type { Tables } from './database.types';

export type EditorOption = Pick<Tables<'editores'>, 'user_id' | 'nombre_completo' | 'activo'>;
export type AssignmentWork = {
	obra_id: string;
	titulo: string;
	editor_asignado: string | null;
	reviewer_ids: string[];
};
export type AssignmentOperation = 'editor' | 'add_reviewer' | 'remove_reviewer';
export type ManagedEditor = Tables<'editores'> & {
	roleTerm: string;
	invitationStatus: 'pending' | 'sent' | 'accepted';
	invitedAt: string | null;
	lastSignInAt: string | null;
	editingCount: number;
	reviewingCount: number;
};
