# Supabase Security Advisor Notes

Date: 2026-02-11

## Scope
- Project: `metadrama_db`
- Source: Supabase Security Advisor warnings

## Warning Register

### 1) `function_search_path_mutable` (resolved in code)
- Affected functions:
  - `public.actualizar_autoria_obra`
  - `public.actualizar_updated_at`
- Mitigation applied:
  - Added `set search_path = ''`
  - Qualified table references with `public.*` where needed
- Migration:
  - `supabase/migrations/20260211090000_harden_trigger_functions_search_path.sql`

### 2) `auth_leaked_password_protection` (accepted risk on Free/Hobby)
- Status: accepted risk (plan limitation)
- Reason:
  - Leaked password protection is not available on current Supabase plan (Free/Hobby)
- Compensating controls:
  - `minimum_password_length = 12`
  - `password_requirements = "lower_upper_letters_digits_symbols"`
  - `secure_password_change = true`
  - Controlled onboarding model (invite/admin), no public signup flow in app code

## Manual dashboard checklist (hosted project)
- Verify Auth password policy in Supabase Dashboard matches this baseline.
- Keep leaked password warning documented until plan upgrade enables it.

## Validation checklist
- Re-run Security Advisor and confirm:
  - `function_search_path_mutable` warnings are gone.
  - `auth_leaked_password_protection` remains expected on Free/Hobby.
