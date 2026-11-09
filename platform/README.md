# Company Email Signature Manager — platform foundation

This application is being developed alongside the existing root-level KMA signature generator. The original `index.html`, `styles.css`, and `images/` assets remain untouched.

## Stack

- Next.js 15.5, React 19, TypeScript
- Supabase Auth and PostgreSQL
- Supabase Row Level Security (RLS)
- Zod is included for subsequent request/schema validation

## Local setup

1. Install Node.js 20.9 or newer.
2. From this directory, run `npm install`.
3. Copy `.env.example` to `.env.local` and set the Supabase project URL and publishable key.
4. Apply `supabase/migrations/0001_secure_multi_company_foundation.sql` to a new Supabase project after review.
5. Provision the first organization and administrator through a trusted process; this migration intentionally creates neither a public signup route nor a default privileged account.
6. Run `npm run dev`.

## Security notes

- Never put a Supabase service-role key in browser code or a `NEXT_PUBLIC_*` variable.
- RLS is the database enforcement layer; middleware is only a session/navigation aid and is not authorization by itself.
- All privileged writes and role changes must be authorized server-side and audited.
- Organization administrators are scoped to memberships in their own organization.
- Department-manager scoping will be added with the department/employee schema in a later milestone.
- Microsoft Entra ID sign-in requires KMA IT approval and is not configured in this scaffold.

## Current scope

This is a foundation scaffold, not a production-ready release. Branding, employee directory, CSV import, approved templates, signature generation, self-service, audit-write workflows, and Outlook deployment/testing remain future milestones.
