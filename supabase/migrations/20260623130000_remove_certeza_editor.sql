DO $$
DECLARE
	v_revision_tipo_id uuid;
	v_fallback_user_id uuid;
	v_needs_comment_migration boolean;
	v_needs_fallback_user boolean;
BEGIN
	SELECT EXISTS (
		SELECT 1
		FROM public.secuencias_metricas sm
		JOIN public.vocabularios c ON c.termino_id = sm.certeza_editor
		WHERE c.categoria = 'certeza_editor'
			AND lower(c.termino) IN ('baja', 'media')
		UNION ALL
		SELECT 1
		FROM public.cuadros cu
		JOIN public.vocabularios c ON c.termino_id = cu.certeza_editor
		WHERE c.categoria = 'certeza_editor'
			AND lower(c.termino) IN ('baja', 'media')
	)
	INTO v_needs_comment_migration;

	IF NOT v_needs_comment_migration THEN
		RETURN;
	END IF;

	SELECT termino_id
	INTO v_revision_tipo_id
	FROM public.vocabularios
	WHERE categoria = 'tipo_comentario'
		AND termino = 'revision'
	LIMIT 1;

	IF v_revision_tipo_id IS NULL THEN
		RAISE EXCEPTION 'No se encontró el vocabulario tipo_comentario/revision para migrar certezas a comentarios internos';
	END IF;

	SELECT EXISTS (
		SELECT 1
		FROM public.secuencias_metricas sm
		JOIN public.vocabularios c ON c.termino_id = sm.certeza_editor
		JOIN public.obras o ON o.obra_id = sm.obra_id
		WHERE c.categoria = 'certeza_editor'
			AND lower(c.termino) IN ('baja', 'media')
			AND o.editor_asignado IS NULL
		UNION ALL
		SELECT 1
		FROM public.cuadros cu
		JOIN public.vocabularios c ON c.termino_id = cu.certeza_editor
		JOIN public.jornadas j ON j.jornada_id = cu.jornada_id
		JOIN public.obras o ON o.obra_id = j.obra_id
		WHERE c.categoria = 'certeza_editor'
			AND lower(c.termino) IN ('baja', 'media')
			AND o.editor_asignado IS NULL
	)
	INTO v_needs_fallback_user;

	IF v_needs_fallback_user THEN
		SELECT e.user_id
		INTO v_fallback_user_id
		FROM public.editores e
		LEFT JOIN public.vocabularios r ON r.termino_id = e.role
		WHERE coalesce(e.activo, true)
		ORDER BY
			CASE lower(coalesce(r.termino, ''))
				WHEN 'admin' THEN 1
				WHEN 'ip' THEN 2
				ELSE 3
			END,
			e.created_at ASC
		LIMIT 1;

		IF v_fallback_user_id IS NULL THEN
			RAISE EXCEPTION 'No hay editores activos para asignar los comentarios internos de la migración de certezas';
		END IF;
	END IF;

	INSERT INTO public.comentarios_internos (
		obra_id,
		user_id,
		comentario,
		tipo_comentario_id,
		secuencia_id,
		seccion,
		visible_publico,
		created_at,
		updated_at
	)
	SELECT
		sm.obra_id,
		coalesce(o.editor_asignado, v_fallback_user_id),
		format('Certeza %s declarada', lower(c.termino)),
		v_revision_tipo_id,
		sm.secuencia_id,
		'secuencias',
		false,
		now(),
		now()
	FROM public.secuencias_metricas sm
	JOIN public.vocabularios c ON c.termino_id = sm.certeza_editor
	JOIN public.obras o ON o.obra_id = sm.obra_id
	WHERE c.categoria = 'certeza_editor'
		AND lower(c.termino) IN ('baja', 'media')
		AND NOT EXISTS (
			SELECT 1
			FROM public.comentarios_internos ci
			WHERE ci.secuencia_id = sm.secuencia_id
				AND ci.tipo_comentario_id = v_revision_tipo_id
				AND ci.comentario = format('Certeza %s declarada', lower(c.termino))
		);

	INSERT INTO public.comentarios_internos (
		obra_id,
		user_id,
		comentario,
		tipo_comentario_id,
		cuadro_id,
		seccion,
		visible_publico,
		created_at,
		updated_at
	)
	SELECT
		j.obra_id,
		coalesce(o.editor_asignado, v_fallback_user_id),
		format('Certeza %s declarada', lower(c.termino)),
		v_revision_tipo_id,
		cu.cuadro_id,
		'estructura',
		false,
		now(),
		now()
	FROM public.cuadros cu
	JOIN public.vocabularios c ON c.termino_id = cu.certeza_editor
	JOIN public.jornadas j ON j.jornada_id = cu.jornada_id
	JOIN public.obras o ON o.obra_id = j.obra_id
	WHERE c.categoria = 'certeza_editor'
		AND lower(c.termino) IN ('baja', 'media')
		AND NOT EXISTS (
			SELECT 1
			FROM public.comentarios_internos ci
			WHERE ci.cuadro_id = cu.cuadro_id
				AND ci.tipo_comentario_id = v_revision_tipo_id
				AND ci.comentario = format('Certeza %s declarada', lower(c.termino))
		);
END $$;

ALTER TABLE public.cuadros
	DROP CONSTRAINT IF EXISTS cuadros_certeza_editor_fkey;

ALTER TABLE public.secuencias_metricas
	DROP CONSTRAINT IF EXISTS secuencias_metricas_certeza_editor_fkey;

ALTER TABLE public.cuadros
	DROP COLUMN IF EXISTS certeza_editor;

ALTER TABLE public.secuencias_metricas
	DROP COLUMN IF EXISTS certeza_editor;

DELETE FROM public.vocabularios
WHERE categoria = 'certeza_editor';
