-- Company Email Signature Manager
-- Phase 1: secure multi-company foundation.
-- Apply through the Supabase SQL editor or Supabase CLI after reviewing the target project.

create extension if not exists pgcrypto;

create type public.organization_member_role as enum (
  'platform_admin',
  'organization_admin',
  'department_manager',
  'employee'
);

create type public.membership_status as enum ('invited', 'active', 'suspended');

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) between 2 and 160),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  status text not null default 'active' check (status in ('active', 'suspended')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.organization_memberships (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.organization_member_role not null default 'employee',
  status public.membership_status not null default 'invited',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, user_id)
);

create index organization_memberships_user_status_idx
  on public.organization_memberships(user_id, status);
create index organization_memberships_org_role_idx
  on public.organization_memberships(organization_id, role, status);

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  actor_user_id uuid references auth.users(id) on delete set null,
  action text not null check (length(trim(action)) between 2 and 120),
  entity_type text not null check (length(trim(entity_type)) between 2 and 80),
  entity_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index audit_logs_org_created_idx
  on public.audit_logs(organization_id, created_at desc);

-- Security-definer helpers avoid recursive membership-table RLS evaluation.
create or replace function public.is_active_org_member(target_org uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.organization_memberships m
    where m.organization_id = target_org
      and m.user_id = (select auth.uid())
      and m.status = 'active'
  );
$$;

create or replace function public.has_org_admin_role(target_org uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.organization_memberships m
    where m.organization_id = target_org
      and m.user_id = (select auth.uid())
      and m.status = 'active'
      and m.role in ('organization_admin', 'platform_admin')
  );
$$;

alter table public.organizations enable row level security;
alter table public.profiles enable row level security;
alter table public.organization_memberships enable row level security;
alter table public.audit_logs enable row level security;

create policy "members can view their organizations"
  on public.organizations for select to authenticated
  using (public.is_active_org_member(id));

create policy "users can view their own profile"
  on public.profiles for select to authenticated
  using (id = (select auth.uid()));
create policy "users can insert their own profile"
  on public.profiles for insert to authenticated
  with check (id = (select auth.uid()));
create policy "users can update their own profile"
  on public.profiles for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

create policy "members can view memberships in their organizations"
  on public.organization_memberships for select to authenticated
  using (
    user_id = (select auth.uid())
    or public.has_org_admin_role(organization_id)
  );
create policy "organization admins can add memberships"
  on public.organization_memberships for insert to authenticated
  with check (public.has_org_admin_role(organization_id));
create policy "organization admins can update memberships"
  on public.organization_memberships for update to authenticated
  using (public.has_org_admin_role(organization_id))
  with check (public.has_org_admin_role(organization_id));
create policy "organization admins can remove memberships"
  on public.organization_memberships for delete to authenticated
  using (public.has_org_admin_role(organization_id));

create policy "organization admins can view audit logs"
  on public.audit_logs for select to authenticated
  using (public.has_org_admin_role(organization_id));

-- No client-side UPDATE/DELETE policy exists for audit_logs: entries are immutable
-- to ordinary authenticated users. Trusted server-side jobs can append via service role.
grant usage on schema public to authenticated;
grant select on public.organizations to authenticated;
grant select, insert, update on public.profiles to authenticated;
grant select, insert, update, delete on public.organization_memberships to authenticated;
grant select on public.audit_logs to authenticated;

-- Deliberately no public signup, no default organization, and no seeded admin account.
-- Provision the first organization administrator through a trusted, audited admin process.
