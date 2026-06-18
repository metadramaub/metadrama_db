import { describe, expect, it } from 'vitest';
import {
	CATALOG_SECTION_IDS,
	FICHA_SECTION_IDS,
	buildSectionVisibilityMap,
	isSectionAvailable,
	isSectionVisible,
	scopeMeets,
	type PublicSection
} from './secciones-publicas';

function section(overrides: Partial<PublicSection> = {}): PublicSection {
	return {
		seccion_id: 'demo',
		label: 'Demo',
		descripcion: null,
		activa: true,
		scope_minimo: 'anon',
		orden: 0,
		...overrides
	};
}

describe('scopeMeets', () => {
	it('respeta la jerarquía anon < authenticated < admin_ip', () => {
		expect(scopeMeets('anon', 'anon')).toBe(true);
		expect(scopeMeets('anon', 'authenticated')).toBe(false);
		expect(scopeMeets('anon', 'admin_ip')).toBe(false);

		expect(scopeMeets('authenticated', 'anon')).toBe(true);
		expect(scopeMeets('authenticated', 'authenticated')).toBe(true);
		expect(scopeMeets('authenticated', 'admin_ip')).toBe(false);

		expect(scopeMeets('admin_ip', 'anon')).toBe(true);
		expect(scopeMeets('admin_ip', 'admin_ip')).toBe(true);
	});
});

describe('isSectionAvailable', () => {
	it('una sección desactivada nunca se ve, ni para admin/IP', () => {
		const off = section({ activa: false, scope_minimo: 'anon' });
		expect(isSectionAvailable(off, 'anon')).toBe(false);
		expect(isSectionAvailable(off, 'admin_ip')).toBe(false);
	});

	it('una sección activa con scope_minimo authenticated oculta al anónimo', () => {
		const restricted = section({ activa: true, scope_minimo: 'authenticated' });
		expect(isSectionAvailable(restricted, 'anon')).toBe(false);
		expect(isSectionAvailable(restricted, 'authenticated')).toBe(true);
		expect(isSectionAvailable(restricted, 'admin_ip')).toBe(true);
	});

	it('sección activa y pública se ve para todos', () => {
		const open = section({ activa: true, scope_minimo: 'anon' });
		expect(isSectionAvailable(open, 'anon')).toBe(true);
	});
});

describe('buildSectionVisibilityMap / isSectionVisible', () => {
	it('produce el mapa resuelto para el scope dado', () => {
		const sections = [
			section({ seccion_id: 'catalogo', scope_minimo: 'anon' }),
			section({ seccion_id: 'fuentes', scope_minimo: 'authenticated' }),
			section({ seccion_id: 'oculta', activa: false, scope_minimo: 'anon' })
		];

		const anonMap = buildSectionVisibilityMap(sections, 'anon');
		expect(isSectionVisible(anonMap, 'catalogo')).toBe(true);
		expect(isSectionVisible(anonMap, 'fuentes')).toBe(false);
		expect(isSectionVisible(anonMap, 'oculta')).toBe(false);

		const authMap = buildSectionVisibilityMap(sections, 'authenticated');
		expect(isSectionVisible(authMap, 'fuentes')).toBe(true);
		expect(isSectionVisible(authMap, 'oculta')).toBe(false);
	});

	it('sección desconocida = no visible (default seguro)', () => {
		const map = buildSectionVisibilityMap([], 'admin_ip');
		expect(isSectionVisible(map, 'no-existe')).toBe(false);
	});

	it('expone slugs estables para ficha y grupos del catálogo', () => {
		expect(FICHA_SECTION_IDS.sinopsisMetrica).toBe('ficha.sinopsis_metrica');
		expect(CATALOG_SECTION_IDS.filtrosBasicos).toBe('catalogo.filtros.basicos');
		expect(CATALOG_SECTION_IDS.laboratorio).toBe('catalogo.laboratorio');
	});
});
