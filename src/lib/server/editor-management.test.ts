import { beforeEach, describe, expect, it, vi } from 'vitest';

const mocks = vi.hoisted(() => ({
	profile: vi.fn(),
	getAdmin: vi.fn(),
	roles: vi.fn(),
	createUser: vi.fn(),
	deleteUser: vi.fn(),
	invite: vi.fn(),
	recover: vi.fn(),
	getUser: vi.fn(),
	from: vi.fn(),
	insert: vi.fn(),
	select: vi.fn(),
	single: vi.fn(),
	eq: vi.fn(),
	maybeSingle: vi.fn()
}));
vi.mock('$lib/server/auth', () => ({ requireEditorProfile: mocks.profile }));
vi.mock('$lib/server/supabase-admin', () => ({ getSupabaseAdmin: mocks.getAdmin }));
vi.mock('$lib/server/catalogos-internos', () => ({ loadInternalVocabulario: mocks.roles }));

import { authInvitationState, requireEditorManager } from './editor-management';
import { POST as createEditor } from '../../routes/api/editores/+server';
import { POST as inviteEditor } from '../../routes/api/editores/[id]/invitar/+server';
import { POST as recoverEditor } from '../../routes/api/editores/[id]/recuperar/+server';
import { POST as assignWorks } from '../../routes/api/obras/asignaciones-lote/+server';

const userId = 'a0545e64-475c-4f94-9ad5-45de872dc2f5';
const profileData = {
	nombre_completo: 'Ana',
	email: 'ana@example.com',
	institucion: '',
	orcid: ''
};
const event = (body: unknown = profileData) => ({
	locals: {} as App.Locals,
	request: new Request('https://example.com/api', { method: 'POST', body: JSON.stringify(body) }),
	params: { id: userId },
	url: new URL('https://example.com/api')
});
const handler = (fn: unknown) => fn as (value: ReturnType<typeof event>) => Promise<Response>;

beforeEach(() => {
	vi.resetAllMocks();
	mocks.profile.mockResolvedValue({ roleTerm: 'admin', activo: true });
	mocks.roles.mockResolvedValue([{ termino: 'editor', termino_id: 'role-editor' }]);
	const chain = {
		insert: mocks.insert,
		select: mocks.select,
		single: mocks.single,
		eq: mocks.eq,
		maybeSingle: mocks.maybeSingle
	};
	for (const fn of [mocks.from, mocks.insert, mocks.select, mocks.eq]) fn.mockReturnValue(chain);
	mocks.single.mockResolvedValue({ data: { user_id: userId }, error: null });
	mocks.maybeSingle.mockResolvedValue({
		data: { user_id: userId, email: profileData.email, activo: true },
		error: null
	});
	mocks.createUser.mockResolvedValue({ data: { user: { id: userId } }, error: null });
	mocks.deleteUser.mockResolvedValue({ error: null });
	mocks.getUser.mockResolvedValue({
		data: { user: { id: userId, email: profileData.email } },
		error: null
	});
	mocks.invite.mockResolvedValue({
		data: { user: { id: userId, invited_at: '2026-10-19' } },
		error: null
	});
	mocks.recover.mockResolvedValue({ data: {}, error: null });
	mocks.getAdmin.mockReturnValue({
		from: mocks.from,
		auth: {
			resetPasswordForEmail: mocks.recover,
			admin: {
				createUser: mocks.createUser,
				deleteUser: mocks.deleteUser,
				getUserById: mocks.getUser,
				inviteUserByEmail: mocks.invite
			}
		}
	});
});

describe('recuperación de contraseña desde la gestión editorial', () => {
	const acceptedAccount = () =>
		mocks.getUser.mockResolvedValue({
			data: {
				user: {
					id: userId,
					email: profileData.email,
					email_confirmed_at: '2026-10-19'
				}
			},
			error: null
		});
	it('envía al correo comprobado y permite abrir el enlace en otro navegador', async () => {
		acceptedAccount();
		expect((await handler(recoverEditor)(event())).status).toBe(200);
		expect(mocks.recover).toHaveBeenCalledWith(profileData.email, {
			redirectTo: 'https://example.com/auth/callback?type=recovery'
		});
		expect(mocks.createUser).not.toHaveBeenCalled();
		expect(mocks.invite).not.toHaveBeenCalled();
	});
	it('bloquea la recuperación antes de abrir Auth si quien la pide no es gestor', async () => {
		mocks.profile.mockResolvedValue({ roleTerm: 'editor', activo: true });
		await expect(handler(recoverEditor)(event())).rejects.toMatchObject({ status: 403 });
		expect(mocks.getAdmin).not.toHaveBeenCalled();
	});
	it.each(['pending', 'disabled', 'mismatched'])(
		'no envía correo para una cuenta %s',
		async (kind) => {
			if (kind === 'disabled')
				mocks.maybeSingle.mockResolvedValue({ data: { ...profileData, activo: false } });
			if (kind === 'mismatched')
				mocks.getUser.mockResolvedValue({
					data: { user: { email: 'otro@example.com', email_confirmed_at: '2026-10-19' } }
				});
			await expect(handler(recoverEditor)(event())).rejects.toMatchObject({
				status: kind === 'disabled' ? 422 : 409
			});
			expect(mocks.recover).not.toHaveBeenCalled();
		}
	);
	it.each([429, 500])('comunica el fallo de envío %s sin modificar la cuenta', async (status) => {
		acceptedAccount();
		mocks.recover.mockResolvedValue({ error: { status } });
		await expect(handler(recoverEditor)(event())).rejects.toMatchObject({
			status: status === 429 ? 429 : 502
		});
		expect(mocks.insert).not.toHaveBeenCalled();
		expect(mocks.deleteUser).not.toHaveBeenCalled();
	});
});

describe('alta e invitación', () => {
	it('crea la cuenta sin contraseña, sin confirmarla y sin enviar invitación', async () => {
		const response = await handler(createEditor)(event());
		expect(response.status).toBe(201);
		expect(mocks.createUser).toHaveBeenCalledWith({
			email: profileData.email,
			email_confirm: false
		});
		expect(mocks.insert).toHaveBeenCalledWith(
			expect.objectContaining({ role: 'role-editor', activo: true, user_id: userId })
		);
		expect(mocks.invite).not.toHaveBeenCalled();
	});
	it('retira únicamente la cuenta recién creada si falla el perfil', async () => {
		mocks.single.mockResolvedValue({ error: { code: '23505' } });
		await expect(handler(createEditor)(event())).rejects.toMatchObject({ status: 500 });
		expect(mocks.deleteUser).toHaveBeenCalledWith(userId);
		expect(mocks.invite).not.toHaveBeenCalled();
	});
	it('un duplicado no borra ni modifica una cuenta anterior', async () => {
		mocks.createUser.mockResolvedValue({ error: { code: 'email_exists' } });
		expect((await handler(createEditor)(event())).status).toBe(409);
		expect(mocks.insert).not.toHaveBeenCalled();
		expect(mocks.deleteUser).not.toHaveBeenCalled();
	});
	it('rechaza a un editor antes de abrir el cliente administrativo', async () => {
		mocks.profile.mockResolvedValue({ roleTerm: 'editor', activo: true });
		await expect(handler(createEditor)(event())).rejects.toMatchObject({ status: 403 });
		expect(mocks.getAdmin).not.toHaveBeenCalled();
	});
	it('solo envía la invitación por una acción explícita y al correo de la cuenta preparada', async () => {
		expect((await handler(inviteEditor)(event())).status).toBe(200);
		expect(mocks.invite).toHaveBeenCalledWith(profileData.email, {
			redirectTo: 'https://example.com/auth/callback?type=invite'
		});
		expect(mocks.createUser).not.toHaveBeenCalled();
	});
	it.each(['disabled', 'confirmed', 'mismatched'])('no invita una cuenta %s', async (kind) => {
		if (kind === 'disabled')
			mocks.maybeSingle.mockResolvedValue({ data: { ...profileData, activo: false } });
		else
			mocks.getUser.mockResolvedValue({
				data: {
					user: {
						email: kind === 'mismatched' ? 'otro@example.com' : profileData.email,
						email_confirmed_at: kind === 'confirmed' ? '2026-10-19' : null
					}
				}
			});
		await expect(handler(inviteEditor)(event())).rejects.toMatchObject({
			status: kind === 'disabled' ? 422 : 409
		});
		expect(mocks.invite).not.toHaveBeenCalled();
	});
	it('un fallo de correo conserva la cuenta y el perfil', async () => {
		mocks.invite.mockResolvedValue({ error: { status: 429 } });
		await expect(handler(inviteEditor)(event())).rejects.toMatchObject({ status: 429 });
		expect(mocks.deleteUser).not.toHaveBeenCalled();
		expect(mocks.insert).not.toHaveBeenCalled();
	});
	it('lee el estado de invitación desde Auth', () => {
		expect(authInvitationState({})).toBe('pending');
		expect(authInvitationState({ invited_at: '2026-10-19' })).toBe('sent');
		expect(
			authInvitationState({ invited_at: '2026-10-19', email_confirmed_at: '2026-10-19' })
		).toBe('accepted');
	});
	it('utiliza la sesión del gestor para el RPC y devuelve un conflicto revisable', async () => {
		const input = event({
			operation: 'editor',
			target: userId,
			works: [{ obra_id: userId, editor_asignado: null, reviewer_ids: [] }]
		});
		const rpc = vi
			.fn()
			.mockResolvedValue({ error: { code: 'PT409', message: 'Recarga la página' } });
		input.locals.supabase = { rpc } as unknown as App.Locals['supabase'];
		await expect(handler(assignWorks)(input)).rejects.toMatchObject({ status: 409 });
		expect(rpc).toHaveBeenCalledWith(
			'gestionar_asignaciones_lote',
			expect.objectContaining({ p_destino: userId })
		);
		expect(mocks.getAdmin).not.toHaveBeenCalled();
	});
	it('comprueba que el permiso depende del perfil autenticado', async () => {
		mocks.profile.mockRejectedValue({ status: 401 });
		await expect(requireEditorManager({} as App.Locals)).rejects.toMatchObject({ status: 401 });
	});
});
