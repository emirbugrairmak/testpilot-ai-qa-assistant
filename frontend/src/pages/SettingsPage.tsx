import { ErrorAlert } from "../components/ErrorAlert";
import { LoadingState } from "../components/LoadingState";
import { PlanBadge } from "../components/PlanBadge";
import { UsageCard } from "../components/UsageCard";
import { useAuth } from "../hooks/useAuth";
import { useUsage } from "../hooks/useUsage";

export function SettingsPage() {
  const { apiKey, isAuthenticated, logout, user } = useAuth();
  const usageQuery = useUsage(isAuthenticated);

  return (
    <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_360px]">
      <section className="space-y-6 rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
        <div>
          <p className="text-sm font-bold uppercase text-sky-700">Settings</p>
          <h1 className="mt-2 text-3xl font-extrabold text-navy-800">
            Account and usage
          </h1>
          <p className="mt-2 text-sm leading-6 text-slate-600">
            Review your current plan, API key status, and usage summary.
          </p>
        </div>

        <div className="grid gap-4">
          <div className="rounded-lg border border-slate-200 bg-slate-50 p-4">
            <p className="text-sm font-semibold text-slate-500">Current plan</p>
            <div className="mt-3">
              {user ? <PlanBadge plan={user.plan} /> : null}
            </div>
          </div>

          <div className="rounded-lg border border-slate-200 bg-slate-50 p-4">
            <p className="text-sm font-semibold text-slate-500">Stored API key</p>
            <p className="mt-3 font-mono text-sm font-semibold text-navy-800">
              {maskApiKey(apiKey)}
            </p>
          </div>

          <div className="rounded-lg border border-slate-200 bg-slate-50 p-4">
            <p className="text-sm font-semibold text-slate-500">Demo help</p>
            <p className="mt-3 text-sm leading-6 text-slate-700">
              Free plan supports JSON and Markdown exports. Premium adds CSV and Jira exports, plus unlimited history.
            </p>
          </div>
        </div>

        <button
          type="button"
          onClick={logout}
          className="rounded-lg bg-accent-500 px-4 py-3 text-sm font-bold text-white hover:bg-accent-600"
        >
          Logout
        </button>
      </section>

      <aside className="space-y-4">
        {usageQuery.isLoading ? <LoadingState label="Loading usage" /> : null}
        {usageQuery.isError ? (
          <ErrorAlert
            message={
              usageQuery.error instanceof Error
                ? usageQuery.error.message
                : "Could not load usage."
            }
          />
        ) : null}
        {usageQuery.data ? <UsageCard usage={usageQuery.data} /> : null}
      </aside>
    </div>
  );
}

function maskApiKey(value: string | null) {
  if (!value) {
    return "No API key stored";
  }

  if (value.length <= 8) {
    return `${value.slice(0, 2)}••••`;
  }

  return `${value.slice(0, 4)}••••••${value.slice(-4)}`;
}
