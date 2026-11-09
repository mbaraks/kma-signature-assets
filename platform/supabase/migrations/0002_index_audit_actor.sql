-- Phase 1 follow-up: index audit actor foreign key for lookup and delete checks.
create index if not exists audit_logs_actor_user_id_idx
  on public.audit_logs(actor_user_id);