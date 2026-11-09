import { signIn } from "@/app/actions";

type Props = { searchParams: Promise<{ error?: string }> };

export default async function LoginPage({ searchParams }: Props) {
  const { error } = await searchParams;
  return (
    <main className="main" style={{ maxWidth: 460 }}>
      <p className="eyebrow">KMA · Company Email Signature Manager</p>
      <h1>Sign in to your workspace</h1>
      <p className="lead">Access is provided by your organization administrator. Public self-registration is disabled.</p>
      <section className="panel" style={{ marginTop: 26 }}>
        {error && <p className="error" role="alert">{error}</p>}
        <form action={signIn}>
          <div className="field">
            <label htmlFor="email">Work email</label>
            <input id="email" name="email" type="email" autoComplete="username" required />
          </div>
          <div className="field">
            <label htmlFor="password">Password</label>
            <input id="password" name="password" type="password" autoComplete="current-password" required />
          </div>
          <button className="button" type="submit">Sign in</button>
        </form>
      </section>
      <p className="muted" style={{ marginTop: 18 }}>Microsoft organizational sign-in is a planned integration, subject to KMA IT approval.</p>
    </main>
  );
}