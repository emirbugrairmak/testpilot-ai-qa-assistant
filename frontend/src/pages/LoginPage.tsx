import { useState, type FormEvent } from "react";
import logoUrl from "../assets/testpilot-logo.png";
import { ErrorAlert } from "../components/ErrorAlert";
import { LoadingState } from "../components/LoadingState";
import { useAuth } from "../hooks/useAuth";

type LoginPageProps = {
  onLoginSuccess: () => void;
};

export function LoginPage({ onLoginSuccess }: LoginPageProps) {
  const { login, isLoggingIn, loginError, clearLoginError } = useAuth();
  const [apiKey, setApiKey] = useState("tp_free_demo_key");

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    clearLoginError();
    await login(apiKey);
    onLoginSuccess();
  }

  return (
    <main className="min-h-screen bg-slate-50">
      <div className="mx-auto grid min-h-screen max-w-6xl items-center gap-10 px-4 py-10 sm:px-6 lg:grid-cols-[1fr_420px] lg:px-8">
        <section className="space-y-7">
          <div className="flex items-center gap-4">
            <img
              src={logoUrl}
              alt="TestPilot logo"
              className="h-16 w-16 rounded-lg object-cover shadow-sm"
            />
            <div>
              <p className="text-3xl font-extrabold text-navy-800">
                TestPilot
              </p>
              <p className="text-base font-semibold text-sky-700">
                AI QA Assistant
              </p>
            </div>
          </div>

          <div className="max-w-2xl">
            <h1 className="text-4xl font-extrabold leading-tight text-navy-800">
              Turn product notes into QA artifacts with a clean workflow.
            </h1>
            <p className="mt-4 text-lg leading-8 text-slate-600">
              Validate your API key, check usage, review recent generations,
              and create test cases or bug reports from one focused workspace.
            </p>
          </div>

          <div className="grid max-w-2xl gap-3 sm:grid-cols-3">
            {["Mod A", "Mod B", "Bug Report"].map((item) => (
              <div
                key={item}
                className="rounded-lg border border-slate-200 bg-white px-4 py-3 text-sm font-bold text-slate-700 shadow-sm"
              >
                {item}
              </div>
            ))}
          </div>
        </section>

        <section className="rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
          <div>
            <h2 className="text-2xl font-bold text-navy-800">Sign in</h2>
            <p className="mt-2 text-sm leading-6 text-slate-600">
              Use one of the demo API keys or paste your own key.
            </p>
          </div>

          <form onSubmit={handleSubmit} className="mt-6 space-y-4">
            <div className="space-y-2">
              <label
                htmlFor="api_key"
                className="text-sm font-semibold text-slate-700"
              >
                API key
              </label>
              <input
                id="api_key"
                className="w-full rounded-lg border border-slate-300 bg-white px-3 py-3 text-sm text-slate-800 outline-none focus:border-sky-400 focus:ring-2 focus:ring-sky-100"
                value={apiKey}
                onChange={(event) => setApiKey(event.target.value)}
                placeholder="tp_free_demo_key"
                required
              />
            </div>

            {loginError && <ErrorAlert message={loginError} />}

            <button
              type="submit"
              disabled={isLoggingIn}
              className="inline-flex w-full justify-center rounded-lg bg-accent-500 px-4 py-3 text-sm font-bold text-white shadow-sm hover:bg-accent-600 disabled:cursor-not-allowed disabled:opacity-60"
            >
              {isLoggingIn ? "Validating" : "Continue"}
            </button>

            {isLoggingIn && <LoadingState label="Checking API key" />}
          </form>

          <div className="mt-6 rounded-lg bg-slate-50 p-4 text-sm text-slate-600">
            <p className="font-bold text-slate-800">Demo keys</p>
            <p className="mt-2 font-mono text-xs">tp_free_demo_key</p>
            <p className="mt-1 font-mono text-xs">tp_premium_demo_key</p>
          </div>
        </section>
      </div>
    </main>
  );
}
