import { ErrorAlert } from "../components/ErrorAlert";
import { LoadingState } from "../components/LoadingState";
import { PlanBadge } from "../components/PlanBadge";
import { UsageCard } from "../components/UsageCard";
import { useAuth } from "../hooks/useAuth";
import { useHistory } from "../hooks/useHistory";
import { useUsage } from "../hooks/useUsage";
import type { GenerationMode } from "../types/api";

type DashboardPageProps = {
  onNewGeneration: (mode: GenerationMode) => void;
  onOpenResult: (generationId: number) => void;
};

export function DashboardPage({
  onNewGeneration,
  onOpenResult,
}: DashboardPageProps) {
  const { isAuthenticated, user } = useAuth();
  const usageQuery = useUsage(isAuthenticated);
  const historyQuery = useHistory({}, isAuthenticated);
  const recentHistory = historyQuery.data?.items.slice(0, 5) ?? [];

  return (
    <div className="space-y-8">
      <section className="flex flex-col gap-4 rounded-lg border border-slate-200 bg-white p-6 shadow-sm md:flex-row md:items-center md:justify-between">
        <div>
          <div className="flex flex-wrap items-center gap-3">
            <h1 className="text-3xl font-extrabold text-navy-800">
              Dashboard
            </h1>
            {user && <PlanBadge plan={user.plan} />}
          </div>
          <p className="mt-2 max-w-2xl text-sm leading-6 text-slate-600">
            Track usage, review recent generations, and start a new QA run.
          </p>
        </div>

        <div className="flex flex-wrap gap-2">
          <ActionButton label="New Mod A" onClick={() => onNewGeneration("mod_a")} />
          <ActionButton label="New Mod B" onClick={() => onNewGeneration("mod_b")} />
          <ActionButton
            label="New Bug Report"
            onClick={() => onNewGeneration("bug_report")}
          />
        </div>
      </section>

      <div className="grid gap-6 lg:grid-cols-[360px_1fr]">
        <div>
          {usageQuery.isLoading && <LoadingState label="Loading usage" />}
          {usageQuery.isError && (
            <ErrorAlert
              message={
                usageQuery.error instanceof Error
                  ? usageQuery.error.message
                  : "Could not load usage."
              }
            />
          )}
          {usageQuery.data && <UsageCard usage={usageQuery.data} />}
        </div>

        <section className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
          <div className="flex items-center justify-between gap-3">
            <div>
              <h2 className="text-xl font-bold text-navy-800">
                Recent history
              </h2>
              <p className="mt-1 text-sm text-slate-500">
                Latest generations for this API key.
              </p>
            </div>
            {historyQuery.data && (
              <span className="rounded-md bg-slate-100 px-3 py-1 text-xs font-bold text-slate-600">
                {historyQuery.data.count} records
              </span>
            )}
          </div>

          <div className="mt-5">
            {historyQuery.isLoading && <LoadingState label="Loading history" />}
            {historyQuery.isError && (
              <ErrorAlert
                message={
                  historyQuery.error instanceof Error
                    ? historyQuery.error.message
                    : "Could not load history."
                }
              />
            )}

            {historyQuery.data && recentHistory.length === 0 && (
              <p className="rounded-lg bg-slate-50 p-4 text-sm text-slate-600">
                No generations yet. Start with Mod A, Mod B, or a bug report.
              </p>
            )}

            {recentHistory.length > 0 && (
              <div className="divide-y divide-slate-100">
                {recentHistory.map((item) => (
                  <button
                    key={item.generation_id}
                    type="button"
                    onClick={() => onOpenResult(item.generation_id)}
                    className="block w-full py-4 text-left first:pt-0"
                  >
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="rounded-md bg-sky-50 px-2 py-1 text-xs font-bold text-sky-700">
                        {formatMode(item.mode)}
                      </span>
                      <span className="text-xs font-semibold text-slate-500">
                        #{item.generation_id}
                      </span>
                      <span className="text-xs text-slate-400">
                        {new Date(item.created_at).toLocaleString()}
                      </span>
                    </div>
                    <p className="mt-2 line-clamp-2 text-sm leading-6 text-slate-700">
                      {item.output_summary}
                    </p>
                  </button>
                ))}
              </div>
            )}
          </div>
        </section>
      </div>
    </div>
  );
}

function ActionButton({
  label,
  onClick,
}: {
  label: string;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="rounded-lg bg-navy-800 px-4 py-2 text-sm font-bold text-white hover:bg-navy-700"
    >
      {label}
    </button>
  );
}

function formatMode(mode: GenerationMode) {
  if (mode === "mod_a") {
    return "Mod A";
  }

  if (mode === "mod_b") {
    return "Mod B";
  }

  return "Bug Report";
}
