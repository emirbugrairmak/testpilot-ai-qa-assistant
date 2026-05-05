import { useState } from "react";
import { ConfirmDialog } from "../components/ConfirmDialog";
import { EmptyState } from "../components/EmptyState";
import { ErrorAlert } from "../components/ErrorAlert";
import { LoadingState } from "../components/LoadingState";
import { useAuth } from "../hooks/useAuth";
import { useDeleteHistory } from "../hooks/useDeleteHistory";
import { useHistory } from "../hooks/useHistory";
import type { GenerationMode, HistoryItem } from "../types/api";

type HistoryPageProps = {
  onOpenResult: (generationId: number) => void;
};

export function HistoryPage({ onOpenResult }: HistoryPageProps) {
  const { isAuthenticated } = useAuth();
  const [draftQuery, setDraftQuery] = useState("");
  const [deleteTarget, setDeleteTarget] = useState<HistoryItem | null>(null);
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

  function handleDeleteConfirm() {
    if (!deleteTarget) {
      return;
    }

    deleteMutation.mutate(deleteTarget.generation_id, {
      onSuccess: () => setDeleteTarget(null),
    });
  }

  return (
    <div className="space-y-6">
      <section className="rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
        <div className="flex flex-col gap-3 md:flex-row md:items-end md:justify-between">
          <div>
            <p className="text-sm font-bold uppercase text-sky-700">History</p>
            <h1 className="mt-2 text-3xl font-extrabold text-navy-800">
              Önceki History kayıtlarını inceleyin
            </h1>
            <p className="mt-2 text-sm leading-6 text-slate-600">
              Moda göre filtreleyin, metin içinde arayın, sonuçları açın veya kayıtları silin.
            </p>
          </div>

          {historyQuery.data?.limit ? (
            <div className="rounded-lg bg-sky-50 px-4 py-3 text-sm font-medium text-sky-700">
              Free planında History son {historyQuery.data.limit} kayıtla sınırlıdır.
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
            <option value="all">Tüm modlar</option>
            <option value="mod_a">Mod A</option>
            <option value="mod_b">Mod B</option>
            <option value="bug_report">Bug Report</option>
          </select>

          <input
            value={draftQuery}
            onChange={(event) => setDraftQuery(event.target.value)}
            placeholder="Girdi veya çıktıda ara"
            className="rounded-lg border border-slate-300 bg-white px-3 py-3 text-sm text-slate-800 outline-none focus:border-sky-400 focus:ring-2 focus:ring-sky-100"
          />

          <button
            type="submit"
            className="rounded-lg bg-navy-800 px-4 py-3 text-sm font-bold text-white hover:bg-navy-700"
          >
            Ara
          </button>
        </form>
      </section>

      {deleteMutation.isError ? (
        <ErrorAlert
          message={
            deleteMutation.error instanceof Error
              ? deleteMutation.error.message
              : "Silme işlemi başarısız oldu."
          }
        />
      ) : null}

      <section className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
        <div className="flex items-center justify-between gap-3">
          <h2 className="text-xl font-bold text-navy-800">Sonuçlar</h2>
          {historyQuery.data ? (
            <span className="rounded-md bg-slate-100 px-3 py-1 text-xs font-bold text-slate-600">
              {historyQuery.data.count} kayıt
            </span>
          ) : null}
        </div>

        <div className="mt-5">
          {historyQuery.isLoading ? <LoadingState label="History yükleniyor" /> : null}
          {historyQuery.isError ? (
            <ErrorAlert
              message={
                historyQuery.error instanceof Error
                  ? historyQuery.error.message
                  : "History yüklenemedi."
              }
            />
          ) : null}

          {historyQuery.data && historyQuery.data.items.length === 0 ? (
            <EmptyState
              title="Eşleşen History kaydı yok"
              description="Başka bir mod filtresi veya farklı bir arama ifadesi deneyin."
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
                      <span className={modeBadgeClass(item.mode)}>
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
                      Aç
                    </button>
                    <button
                      type="button"
                      onClick={() => setDeleteTarget(item)}
                      disabled={deleteMutation.isPending}
                      className="rounded-lg border border-red-200 px-3 py-2 text-sm font-bold text-red-700 hover:bg-red-50 disabled:cursor-not-allowed disabled:opacity-60"
                    >
                      Sil
                    </button>
                  </div>
                </article>
              ))}
            </div>
          ) : null}
        </div>
      </section>

      {deleteTarget ? (
        <ConfirmDialog
          title={`Üretim #${deleteTarget.generation_id} silinsin mi?`}
          description={`${formatMode(deleteTarget.mode)} kaydı History'den kalıcı olarak silinecek.`}
          isPending={deleteMutation.isPending}
          onCancel={() => setDeleteTarget(null)}
          onConfirm={handleDeleteConfirm}
        />
      ) : null}
    </div>
  );
}

function modeBadgeClass(mode: GenerationMode) {
  const base = "rounded-md px-2 py-1 text-xs font-bold";

  if (mode === "mod_a") {
    return `${base} bg-sky-50 text-sky-700 ring-1 ring-sky-100`;
  }

  if (mode === "mod_b") {
    return `${base} bg-emerald-50 text-emerald-700 ring-1 ring-emerald-100`;
  }

  return `${base} bg-amber-50 text-amber-700 ring-1 ring-amber-100`;
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
