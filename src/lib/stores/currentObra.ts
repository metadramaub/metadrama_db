import { writable } from 'svelte/store';
import type { Tables } from '$lib/types/database.types';

export interface CurrentObraState {
	obra: Tables<'obras'> | null;
	dirty: boolean;
	saving: boolean;
	conflict: boolean;
	lastSavedAt: string | null;
}

const initialState: CurrentObraState = {
	obra: null,
	dirty: false,
	saving: false,
	conflict: false,
	lastSavedAt: null
};

export const currentObraStore = writable<CurrentObraState>(initialState);

export function setCurrentObra(obra: Tables<'obras'> | null) {
	currentObraStore.update((state) => ({
		...state,
		obra,
		dirty: false,
		conflict: false
	}));
}

export function setDirty(dirty: boolean) {
	currentObraStore.update((state) => ({ ...state, dirty }));
}

export function setSaving(saving: boolean) {
	currentObraStore.update((state) => ({ ...state, saving }));
}

export function setConflict(conflict: boolean) {
	currentObraStore.update((state) => ({ ...state, conflict }));
}

export function markSaved() {
	currentObraStore.update((state) => ({
		...state,
		dirty: false,
		saving: false,
		lastSavedAt: new Date().toISOString()
	}));
}
