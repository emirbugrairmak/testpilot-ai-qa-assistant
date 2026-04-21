import { useState } from "react";
import { EmptyState } from "../components/EmptyState";
import { ErrorAlert } from "../components/ErrorAlert";
import { LoadingState } from "../components/LoadingState";
import { useAuth } from "../hooks/useAuth";
import { useDeleteHistory } from "../hooks/useDeleteHistory";
import { useHistory } from "../hooks/useHistory";
import type { GenerationMode } from "../types/api";

type HistoryPageProps = {
  onOpenResult: (generationId: number) => void;
};

export function HistoryPage({ onOpenResult }: HistoryPageProps) {
  const { isAuthenticated } = useAuth();
  const [draftQuery, setDraftQuery] = useState("");
  const [filters, setFilters] = useState<{
    mode: GenerationMode | "all";
    q: string;
  }>({
    mode: "all",
    q: "",
  });

  const historyQuery = useHistory(filters, isAuthenticated);
  const deleteMutation = useDeleteHistory();

  function handleSearchSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setFilters((current) => ({
      ...current,
      q: draftQuery.trim(),
    }));
  }

  function handleDelete(generationId: number) {
    const confirmed = window.confirm("Delete this generation from history?");
    if (!confirmed) {
      return;
    }

    deleteMutation.mutate(generationId);
  }

  return (
    <div className="space-y-6">
      <section className="rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
        <div className="flex flex-col gap-3 md:flex-row md:items-end md:justify-between">
          <div>
            <p className="text-sm font-bold uppercase text-sky-700">History</p>
            <h1 className="mt-2 text-3xl font-extrabold text-navy-800">
              Review previous runs
            </h1>
            <p className="mt-2 text-sm leading-6 text-slate-600">
              Filter by mode, search output text, open results, or delete a record.
            </p>
          </div>

          {historyQuery.data?.limit ? (
            <div className="rounded-lg bg-sky-50 px-4 py-3 text-sm font-medium text-sky-700">
              Free plan history is limited to the last {historyQuery.data.limit} records.
            </div>
          ) : null}
        </div>

        <form
          onSubmit={handleSearchSubmit}
          className="mt-6 grid gap-3 md:grid-cols-[180px_minmax(0,1fr)_140px]"
        >
          <select
            value={filters.mode}
            onChange={(event) =>
              setFilters((current) => ({
                ...current,
                mode: event.target.value as GenerationMode | "all",
              }))
            }
            className="rounded-lg border border-slate-300 bg-white px-3 py-3 text-sm text-slate-800 outline-none focus:border-sky-400 focus:ring-2 focus:ring-sky-100"
          >
            <option value="all">All modes</option>
            <option value="mod_a">Mod A</option>
            <option value="mod_b">Mod B</option>
            <option value="bug_report">Bug Report</option>
          </select>

          <input
            value={draftQuery}
            onChange={(event) => setDraftQuery(event.target.value)}
            placeholder="Search in input or output"
            className="rounded-lg border border-slate-300 bg-white px-3 py-3 text-sm text-slate-800 outline-none focus:border-sky-400 focus:ring-2 focus:ring-sky-100"
          />

          <button
            type="submit"
            className="rounded-lg bg-navy-800 px-4 py-3 text-sm font-bold text-white hover:bg-navy-700"
          >
            Search
          </button>
        </form>
      </section>

      {deleteMutation.isError ? (
        <ErrorAlert
          message={
            deleteMutation.error instanceof Error
              ? deleteMutation.error.message
              : "Delete failed."
          }
        />
      ) : null}

      <section className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
        <div className="flex items-center justify-between gap-3">
          <h2 className="text-xl font-bold text-navy-800">Results</h2>
          {historyQuery.data ? (
            <span className="rounded-md bg-slate-100 px-3 py-1 text-xs font-bold text-slate-600">
              {historyQuery.data.count} records
            </span>
          ) : null}
        </div>

        <div className="mt-5">
          {historyQuery.isLoading ? <LoadingState label="Loading history" /> : null}
          {historyQuery.isError ? (
            <ErrorAlert
              message={
                historyQuery.error instanceof Error
                  ? historyQuery.error.message
                  : "Could not load history."
              }
            />
          ) : null}

          {historyQuery.data && historyQuery.data.items.length === 0 ? (
            <EmptyState
              title="No matching history"
              description="Try another mode filter or a different search phrase."
            />
          ) : null}

          {historyQuery.data && historyQuery.data.items.length > 0 ? (
            <div className="divide-y divide-slate-100">
              {historyQuery.data.items.map((item) => (
                <article
                  key={item.generation_id}
                  className="grid gap-4 py-4 md:grid-cols-[minmax(0,1fr)_120px]"
                >
                  <button
                    type="button"
                    onClick={() => onOpenResult(item.generation_id)}
                    className="text-left"
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
                    <p className="mt-2 text-sm leading-6 text-slate-700">
                      {item.output_summary}
                    </p>
                  </button>

                  <div className="flex items-start justify-end gap-2">
                    <button
                      type="button"
                      onClick={() => onOpenResult(item.generation_id)}
                      className="rounded-lg border border-slate-300 px-3 py-2 text-sm font-bold text-slate-700 hover:border-sky-300 hover:text-sky-700"
                    >
                      Open
                    </button>
                    <button
                      type="button"
                      onClick={() => handleDelete(item.generation_id)}
                      disabled={deleteMutation.isPending}
                      className="rounded-lg border border-red-200 px-3 py-2 text-sm font-bold text-red-700 hover:bg-red-50 disabled:cursor-not-allowed disabled:opacity-60"
                    >
                      Delete
                    </button>
                  </div>
                </article>
              ))}
            </div>
          ) : null}
        </div>
      </section>
    </div>
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
