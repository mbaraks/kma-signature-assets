import { redirect } from "next/navigation";
import { signOut } from "@/app/actions";
import { createClient } from "@/lib/supabase/server";

type Membership = {
  role: "platform_admin" | "organization_admin" | "department_manager" | "employee";
  status: "invited" | "active" | "suspended";
  organizations: { id: string; name: string; slug: string } | null;
};

export default async function DashboardPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data, error } = await supabase
    .from("organization_memberships")
    .select("role,status,organizations(id,name,slug)")
    .eq("user_id", user.id)
    .eq("status", "active");

  const memberships = (data ?? []) as unknown as Membership[];

  return (
    <div className="shell">
      <header className="topbar">
        <div className="brand">Company Email Signature Manager</div>
        <form action={signOut}><button className="button secondary" type="submit">Sign out</button></form>
      </header>
      <main className="main">
        <p className="eyebrow">Workspace overview</p>
        <h1>Welcome back</h1>
        <p className="lead">Signed in as {user.email}. Your access is determined by your active organization memberships and server-side database policies.</p>
        {error ? (
          <section className="panel" style={{ marginTop: 28 }}>
            <p className="error">We could not load your organization memberships. Please contact your administrator.</p>
          </section>
        ) : memberships.length === 0 ? (
          <section className="panel" style={{ marginTop: 28 }}>
            <h2>No active organization access</h2>
            <p className="muted">Your account is authenticated, but it has no active organization membership. Ask an organization administrator to provision your access.</p>
          </section>
        ) : (
          <>
            <div className="grid">
              {memberships.map((membership, index) => (
                <section className="panel" key={membership.organizations?.id ?? index}>
                  <p className="eyebrow">Organization</p>
                  <h2>{membership.organizations?.name ?? "Unavailable organization"}</h2>
                  <p className="muted">Role: {membership.role.replaceAll("_", " ")}</p>
                  <p className="muted">Workspace: {membership.organizations?.slug ?? "—"}</p>
                </section>
              ))}
            </div>
          </>
        )}
        <section className="panel" style={{ marginTop: 24 }}>
          <h2>Foundation milestone</h2>
          <p className="muted">This first release establishes authenticated access and organization-scoped membership. Branding, employee management, templates and signature generation will be added in sequence after security policies are configured and tested.</p>
        </section>
      </main>
    </div>
  );
}