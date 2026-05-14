import { useEffect, useState, type FormEvent } from "react";
import { ErrorAlert } from "../components/ErrorAlert";
import { LoadingState } from "../components/LoadingState";
import { useAuth } from "../hooks/useAuth";
import { useBatchGenerate } from "../hooks/useBatchGenerate";
import { useTemplates } from "../hooks/useTemplates";
import type { BatchGenerateRequest } from "../types/api";

type BatchMode = "mod_a" | "mod_b";
type BatchRow = {
  id: string;
  featureIdea: string;
  userStory: string;
  acceptanceCriteria: string;
};

type BatchGeneratePageProps = {
  onOpenResult: (generationId: number) => void;
};

const inputClass =
  "w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-800 outline-none transition focus:border-sky-400 focus:ring-2 focus:ring-sky-100";
const labelClass = "text-sm font-semibold text-slate-700";

export function BatchGeneratePage({ onOpenResult }: BatchGeneratePageProps) {
  const { user } = useAuth();
  const isPremium = user?.plan === "premium";
  const templatesQuery = useTemplates(isPremium);
  const batchMutation = useBatchGenerate();
  const [mode, setMode] = useState<BatchMode>("mod_a");
  const [templateId, setTemplateId] = useState("");
  const [rows, setRows] = useState<BatchRow[]>(() => [createRow(), createRow()]);

  useEffect(() => {
    setRows([createRow(), createRow()]);
  }, [mode]);

  useEffect(() => {
    const templates = templatesQuery.data?.items ?? [];
    if (!templates.some((template) => String(template.id) === templateId)) {
      setTemplateId("");
    }
  }, [templateId, templatesQuery.data?.items]);

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    const payload: BatchGenerateRequest =
      mode === "mod_a"
        ? {
            mode,
            items: rows
              .map((row) => ({ feature_idea: row.featureIdea.trim() }))
              .filter((item) => item.feature_idea.length > 0),
          }
        : {
            mode,
            items: rows
              .map((row) => ({
                user_story: row.userStory.trim(),
                acceptance_criteria: row.acceptanceCriteria.trim(),
              }))
              .filter(
                (item) =>
                  item.user_story.length > 0 ||
                  item.acceptance_criteria.length > 0,
              ),
          };

    if (templateId) {
      payload.template_id = Number(templateId);
    }

    batchMutation.mutate(payload);
  }

  function updateRow(id: string, patch: Partial<BatchRow>) {
    setRows((current) =>
      current.map((row) => (row.id === id ? { ...row, ...patch } : row)),
    );
  }

  function removeRow(id: string) {
    setRows((current) => current.filter((row) => row.id !== id));
  }

  if (!isPremium) {
    return (
      <section className="rounded-lg border border-amber-200 bg-amber-50 p-6 shadow-sm">
        <p className="text-sm font-bold uppercase text-amber-700">Premium</p>
        <h1 className="mt-2 text-3xl font-extrabold text-amber-950">
          Batch Generate yalnızca Premium planda kullanılabilir
        </h1>
        <p className="mt-2 max-w-2xl text-sm leading-6 text-amber-800">
          Tek istekte birden fazla Mod A veya Mod B çıktısı üretmek için Premium gerekir.
        </p>
      </section>
    );
  }

  return (
    <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_400px]">
      <section className="rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
        <p className="text-sm font-bold uppercase text-sky-700">Batch Generate</p>
        <h1 className="mt-2 text-3xl font-extrabold text-navy-800">
          Birden fazla QA çıktısı üret
        </h1>
        <p className="mt-2 max-w-2xl text-sm leading-6 text-slate-600">
          Premium Batch Generate, en fazla 10 öğe için Mod A ve Mod B akışlarını destekler.
        </p>

        <form onSubmit={handleSubmit} className="mt-6 space-y-5">
          <div className="grid gap-4 md:grid-cols-[180px_minmax(0,1fr)]">
            <div className="space-y-2">
              <label htmlFor="batch_mode" className={labelClass}>
                Mod
              </label>
              <select
                id="batch_mode"
                className={inputClass}
                value={mode}
                onChange={(event) => setMode(event.target.value as BatchMode)}
              >
                <option value="mod_a">Mod A</option>
                <option value="mod_b">Mod B</option>
              </select>
            </div>

            <div className="space-y-2">
              <label htmlFor="batch_template_id" className={labelClass}>
                Custom Template
              </label>
              <select
                id="batch_template_id"
                className={inputClass}
                value={templateId}
                onChange={(event) => setTemplateId(event.target.value)}
                disabled={
                  batchMutation.isPending ||
                  templatesQuery.isLoading ||
                  (templatesQuery.data?.items.length ?? 0) === 0
                }
              >
                <option value="">
                  {templatesQuery.isLoading
                    ? "Templates yükleniyor"
                    : (templatesQuery.data?.items.length ?? 0) === 0
                      ? "Henüz Template yok"
                      : "Template kullanma"}
                </option>
                {(templatesQuery.data?.items ?? []).map((template) => (
                  <option key={template.id} value={template.id}>
                    {template.name}
                  </option>
                ))}
              </select>
              {templatesQuery.isError ? (
                <p className="text-sm font-medium text-red-700">
                  {templatesQuery.error instanceof Error
                    ? templatesQuery.error.message
                    : "Templates yüklenemedi."}
                </p>
              ) : null}
            </div>
          </div>

          <div className="space-y-4">
            {rows.map((row, index) => (
              <article
                key={row.id}
                className="rounded-lg border border-slate-200 bg-slate-50 p-4"
              >
                <div className="mb-3 flex items-center justify-between gap-3">
                  <h2 className="text-sm font-bold text-navy-800">
                    Öğe {index + 1}
                  </h2>
                  <button
                    type="button"
                    onClick={() => removeRow(row.id)}
                    disabled={rows.length === 1 || batchMutation.isPending}
                    className="rounded-lg border border-slate-300 px-3 py-2 text-xs font-bold text-slate-700 hover:border-red-200 hover:text-red-700 disabled:cursor-not-allowed disabled:opacity-50"
                  >
                    Kaldır
                  </button>
                </div>

                {mode === "mod_a" ? (
                  <div className="space-y-2">
                    <label htmlFor={`feature_idea_${row.id}`} className={labelClass}>
                      Özellik fikri
                    </label>
                    <textarea
                      id={`feature_idea_${row.id}`}
                      className={inputClass}
                      rows={4}
                      minLength={5}
                      required
                      value={row.featureIdea}
                      onChange={(event) =>
                        updateRow(row.id, { featureIdea: event.target.value })
                      }
                      placeholder="E-posta ile şifre sıfırlama"
                    />
                  </div>
                ) : (
                  <div className="grid gap-4">
                    <div className="space-y-2">
                      <label
                        htmlFor={`user_story_${row.id}`}
                        className={labelClass}
                      >
                        User story
                      </label>
                      <textarea
                        id={`user_story_${row.id}`}
                        className={inputClass}
                        rows={3}
                        minLength={10}
                        required
                        value={row.userStory}
                        onChange={(event) =>
                          updateRow(row.id, { userStory: event.target.value })
                        }
                        placeholder="Bir kullanıcı olarak, profilimi güncellemek istiyorum."
                      />
                    </div>

                    <div className="space-y-2">
                      <label
                        htmlFor={`acceptance_criteria_${row.id}`}
                        className={labelClass}
                      >
                        AC
                      </label>
                      <textarea
                        id={`acceptance_criteria_${row.id}`}
                        className={inputClass}
                        rows={4}
                        minLength={10}
                        required
                        value={row.acceptanceCriteria}
                        onChange={(event) =>
                          updateRow(row.id, {
                            acceptanceCriteria: event.target.value,
                          })
                        }
                        placeholder="Giriş yapmış kullanıcı değişiklikleri kaydettiğinde profil güncellenmelidir."
                      />
                    </div>
                  </div>
                )}
              </article>
            ))}
          </div>

          <div className="flex flex-wrap gap-2">
            <button
              type="button"
              onClick={() => setRows((current) => [...current, createRow()])}
              disabled={rows.length >= 10 || batchMutation.isPending}
              className="rounded-lg border border-slate-300 px-4 py-3 text-sm font-bold text-slate-700 hover:border-sky-300 hover:text-sky-700 disabled:cursor-not-allowed disabled:opacity-60"
            >
              Öğe ekle
            </button>
            <button
              type="submit"
              disabled={batchMutation.isPending}
              className="rounded-lg bg-accent-500 px-4 py-3 text-sm font-bold text-white hover:bg-accent-600 disabled:cursor-not-allowed disabled:opacity-60"
            >
              {batchMutation.isPending ? "Üretiliyor" : "Batch Generate başlat"}
            </button>
          </div>
        </form>
      </section>

      <aside className="space-y-4">
        {batchMutation.isPending ? (
          <section className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
            <LoadingState label="Batch Generate çalışıyor" />
          </section>
        ) : null}

        {batchMutation.isError ? (
          <ErrorAlert
            message={
              batchMutation.error instanceof Error
                ? batchMutation.error.message
                : "Batch Generate başarısız oldu."
            }
          />
        ) : null}

        {batchMutation.data ? (
          <section className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
            <div className="flex items-center justify-between gap-3">
              <div>
                <h2 className="text-xl font-bold text-navy-800">
                  Batch Generate sonucu
                </h2>
                <p className="mt-1 text-sm text-slate-500">
                  {batchMutation.data.success_count} başarılı,{" "}
                  {batchMutation.data.failed_count} başarısız.
                </p>
              </div>
              <span className="rounded-md bg-slate-100 px-3 py-1 text-xs font-bold text-slate-600">
                {batchMutation.data.total_items} öğe
              </span>
            </div>

            <div className="mt-5 divide-y divide-slate-100">
              {batchMutation.data.results.map((item) => (
                <article key={item.index} className="py-4 first:pt-0">
                  <div className="flex flex-wrap items-center gap-2">
                    <span
                      className={
                        item.success
                          ? "rounded-md bg-emerald-50 px-2 py-1 text-xs font-bold text-emerald-700"
                          : "rounded-md bg-red-50 px-2 py-1 text-xs font-bold text-red-700"
                      }
                    >
                      {item.success ? "Başarılı" : "Başarısız"}
                    </span>
                    <span className="text-xs font-semibold text-slate-500">
                      Öğe {item.index + 1}
                    </span>
                  </div>

                  {item.success && item.generation_id ? (
                    <button
                      type="button"
                      onClick={() => onOpenResult(item.generation_id!)}
                      className="mt-2 text-sm font-bold text-sky-700 hover:text-sky-900"
                    >
                      Üretimi aç #{item.display_id ?? item.generation_id}
                    </button>
                  ) : null}

                  {!item.success ? (
                    <p className="mt-2 text-sm leading-6 text-red-700">
                      {item.error || "Bu öğe başarısız oldu."}
                    </p>
                  ) : null}
                </article>
              ))}
            </div>
          </section>
        ) : (
          <section className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
            <h2 className="text-xl font-bold text-navy-800">Sonuçlar</h2>
            <p className="mt-2 text-sm leading-6 text-slate-600">
              Her öğenin durumunu ve başarılı üretim numaralarını görmek için Batch Generate başlatın.
            </p>
          </section>
        )}
      </aside>
    </div>
  );
}

function createRow(): BatchRow {
  return {
    id: crypto.randomUUID(),
    featureIdea: "",
    userStory: "",
    acceptanceCriteria: "",
  };
}
