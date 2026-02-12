-- Iteracion alertas-dashboard: eliminar rol operativo "revisor".
-- El flujo de revision sigue existiendo via asignaciones en obras_revisores (1..N).

DO $$
DECLARE
	v_editor_role uuid;
	v_revisor_role uuid;
BEGIN
	SELECT termino_id INTO v_editor_role
	FROM public.vocabularios
	WHERE categoria = 'role_editor'
		AND lower(termino) = 'editor'
	LIMIT 1;

	SELECT termino_id INTO v_revisor_role
	FROM public.vocabularios
	WHERE categoria = 'role_editor'
		AND lower(termino) = 'revisor'
	LIMIT 1;

	IF v_editor_role IS NULL THEN
		RAISE EXCEPTION 'No existe role_editor=editor en vocabularios';
	END IF;

	IF v_revisor_role IS NOT NULL THEN
		UPDATE public.editores
		SET role = v_editor_role
		WHERE role = v_revisor_role;

		UPDATE public.vocabularios
		SET activo = false,
			updated_at = now()
		WHERE categoria = 'role_editor'
			AND termino_id = v_revisor_role;
	END IF;
END;
$$;
