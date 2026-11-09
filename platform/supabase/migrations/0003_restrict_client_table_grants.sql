-- Phase 1 security correction: remove Supabase default table grants from client roles.
-- Re-apply only the minimal privileges needed by the application.
revoke all privileges on table
  public.organizations,
  public.profiles,
  public.organization_memberships,
  public.audit_logs
from anon, authenticated;

grant select on public.organizations to authenticated;
grant select, insert on public.profiles to authenticated;
grant update (display_name) on public.profiles to authenticated;
grant select on public.organization_memberships to authenticated;
grant select on public.audit_logs to authenticated;

-- Keep trusted server-side provisioning access. The service-role key must never
-- be shipped to browsers or included in NEXT_PUBLIC_ environment variables.
grant all privileges on table
  public.organizations,
  public.profiles,
  public.organization_memberships,
  public.audit_logs
to service_role;