drop extension if exists "pg_net";

drop policy "admin_all_access" on "public"."editores";

drop policy "vocabularios_public_select" on "public"."vocabularios";


  create policy "editores_select_self"
  on "public"."editores"
  as permissive
  for select
  to authenticated
using (((user_id = auth.uid()) AND COALESCE(activo, true)));



  create policy "vocabularios_public_select"
  on "public"."vocabularios"
  as permissive
  for select
  to anon, authenticated
using ((activo = true));


CREATE TRIGGER protect_buckets_delete BEFORE DELETE ON storage.buckets FOR EACH STATEMENT EXECUTE FUNCTION storage.protect_delete();

CREATE TRIGGER protect_objects_delete BEFORE DELETE ON storage.objects FOR EACH STATEMENT EXECUTE FUNCTION storage.protect_delete();


