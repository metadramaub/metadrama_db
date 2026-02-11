import { writable } from 'svelte/store';
import type { Tables } from '$lib/types/database.types';

export type ObraDirtyScope = 'datos' | 'autoria' | 'analisis' | 'global';

export interface CurrentObraState {
	obra: Tables<'obras'> | null;
	dirty: boolean;
	saving: boolean;
	conflict: boolean;
	lastSavedAt: string | null;
	dirtyByScope: Partial<Record<ObraDirtyScope, boolean>>;
	savingByScope: Partial<Record<ObraDirtyScope, boolean>>;
}

const initialState: CurrentObraState = {
	obra: null,
	dirty: false,
	saving: false,
	conflict: false,
	lastSavedAt: null,
	dirtyByScope: {},
	savingByScope: {}
};

export const currentObraStore = writable<CurrentObraState>(initialState);

function recomputeDirty(dirtyByScope: Partial<Record<ObraDirtyScope, boolean>>) {
	return Object.values(dirtyByScope).some(Boolean);
}

function recomputeSaving(savingByScope: Partial<Record<ObraDirtyScope, boolean>>) {
	return Object.values(savingByScope).some(Boolean);
}

export function setCurrentObra(obra: Tables<'obras'> | null) {
	currentObraStore.update((state) => ({
		...state,
		obra,
		dirty: false,
		conflict: false,
		saving: false,
		dirtyByScope: {},
		savingByScope: {}
	}));
}

export function patchCurrentObra(patch: Partial<Tables<'obras'>>) {
	currentObraStore.update((state) => {
		if (!state.obra) return state;
		return {
			...state,
			obra: {
				...state.obra,
				...patch
			}
		};
	});
}

export function setDirty(dirty: boolean, scope: ObraDirtyScope = 'global') {
	currentObraStore.update((state) => {
		const dirtyByScope = { ...state.dirtyByScope, [scope]: dirty };
		return {
			...state,
			dirtyByScope,
			dirty: recomputeDirty(dirtyByScope)
		};
	});
}

export function setSaving(saving: boolean, scope: ObraDirtyScope = 'global') {
	currentObraStore.update((state) => {
		const savingByScope = { ...state.savingByScope, [scope]: saving };
		return {
			...state,
			savingByScope,
			saving: recomputeSaving(savingByScope)
		};
	});
}

export function setConflict(conflict: boolean) {
	currentObraStore.update((state) => ({ ...state, conflict }));
}

export function markSaved(scope: ObraDirtyScope = 'global') {
	currentObraStore.update((state) => ({
		...state,
		dirtyByScope: {
			...state.dirtyByScope,
			[scope]: false
		},
		savingByScope: {
			...state.savingByScope,
			[scope]: false
		},
		dirty: recomputeDirty({
			...state.dirtyByScope,
			[scope]: false
		}),
		saving: recomputeSaving({
			...state.savingByScope,
			[scope]: false
		}),
		lastSavedAt: new Date().toISOString()
	}));
}
