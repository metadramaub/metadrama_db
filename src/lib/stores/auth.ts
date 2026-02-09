import { writable } from 'svelte/store';
import type { Session, User } from '@supabase/supabase-js';
import type { EditorProfile } from '$lib/types/obra.types';

export interface AuthState {
	session: Session | null;
	user: User | null;
	profile: EditorProfile | null;
}

export const authStore = writable<AuthState>({
	session: null,
	user: null,
	profile: null
});

export function setAuthState(state: AuthState) {
	authStore.set(state);
}
