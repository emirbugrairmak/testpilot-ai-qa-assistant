import { useEffect, useMemo, useState, type FormEvent } from "react";
import { EmptyState } from "../components/EmptyState";
import { ErrorAlert } from "../components/ErrorAlert";
import { LoadingState } from "../components/LoadingState";
import { useAuth } from "../hooks/useAuth";
import {
  useCreateTemplate,
  useDeleteTemplate,
  useUpdateTemplate,
} from "../hooks/useTemplateMutations";
import { useTemplates } from "../hooks/useTemplates";
import type { Template } from "../types/api";

const inputClass =
  "w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-800 outline-none transition focus:border-sky-400 focus:ring-2 focus:ring-sky-100";
const labelClass = "text-sm font-semibold text-slate-700";

export function TemplatesPage() {
  const { user } = useAuth();
  const isPremium = user?.plan === "premium";
  const templatesQuery = useTemplates(isPremium);
  const createMutation = useCreateTemplate();
  const updateMutation = useUpdateTemplate();
  const deleteMutation = useDeleteTemplate();
  const [editingTemplate, setEditingTemplate] = useState<Template | null>(null);
  const [name, setName] = useState("");
  const [promptText, setPromptText] = useState("");

  const isSaving = createMutation.isPending || updateMutation.isPending;
  const mutationError = useMemo(() => {
    const error =
      createMutation.error || updateMutation.error || deleteMutation.error;
    return error instanceof Error ? error.message : null;
  }, [createMutation.error, deleteMutation.error, updateMutation.error]);

  useEffect(() => {
    if (!editingTemplate) {
      setName("");
      setPromptText("");
      return;
    }

    setName(editingTemplate.name);
    setPromptText(editingTemplate.prompt_text);
  }, [editingTemplate]);

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    const payload = {
      name: name.trim(),
      prompt_text: promptText.trim(),
    };

    if (editingTemplate) {
      updateMutation.mutate(
        { id: editingTemplate.id, payload },
        {
          onSuccess: () => setEditingTemplate(null),
        },
      );
      return;
    }

    createMutation.mutate(payload, {
      onSuccess: () => {
        setName("");
        setPromptText("");
      },
    });
  }

  function handleEdit(template: Template) {
    setEditingTemplate(template);
    window.scrollTo({ top: 0, behavior: "smooth" });
  }

  function handleDelete(template: Template) {
    const confirmed = window.confirm(`"${template.name}" Template'i silinsin mi?`);
    if (!confirmed) {
      return;
    }

    deleteMutation.mutate(template.id, {
      onSuccess: () => {
        if (editingTemplate?.id === template.id) {
          setEditingTemplate(null);
        }
      },
    });
  }

  if (!isPremium) {
    return (
      <PremiumWarning
        title="Custom Templates yalnızca Premium planda kullanılabilir"
        description="Yeniden kullanılabilir Prompt Templates oluşturmak ve üretim sırasında kullanmak için Premium gerekir."
      />
    );
  }

  return (
    <div className="grid gap-6 lg:grid-cols-[420px_minmax(0,1fr)]">
      <section className="rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
        <p className="text-sm font-bold uppercase text-sky-700">Templates</p>
        <h1 className="mt-2 text-3xl font-extrabold text-navy-800">
          {editingTemplate ? "Template'i düzenle" : "Template oluştur"}
        </h1>
        <p className="mt-2 text-sm leading-6 text-slate-600">
          Premium üretim akışlarında kullanmak üzere tekrar kullanılabilir Template yönergeleri kaydedin.
        </p>

        <form onSubmit={handleSubmit} className="mt-6 space-y-4">
          <div className="space-y-2">
            <label htmlFor="template_name" className={labelClass}>
              Ad
            </label>
            <input
              id="template_name"
              className={inputClass}
              required
              minLength={1}
              maxLength={200}
              value={name}
              onChange={(event) => setName(event.target.value)}
              placeholder="Güvenlik odağı"
            />
          </div>

          <div className="space-y-2">
            <label htmlFor="prompt_text" className={labelClass}>
              Prompt metni
            </label>
            <textarea
              id="prompt_text"
              className={inputClass}
              required
              minLength={10}
              maxLength={10000}
              rows={9}
              value={promptText}
              onChange={(event) => setPromptText(event.target.value)}
              placeholder="Erişilebilirlik, güvenlik ve edge-case kapsamını her zaman ekle."
            />
          </div>

          {mutationError ? <ErrorAlert message={mutationError} /> : null}

          <div className="flex flex-wrap gap-2">
            <button
              type="submit"
              disabled={isSaving}
              className="rounded-lg bg-accent-500 px-4 py-3 text-sm font-bold text-white hover:bg-accent-600 disabled:cursor-not-allowed disabled:opacity-60"
            >
              {isSaving
                ? "Kaydediliyor"
                : editingTemplate
                  ? "Template'i güncelle"
                  : "Template oluştur"}
            </button>

            {editingTemplate ? (
              <button
                type="button"
                onClick={() => setEditingTemplate(null)}
                className="rounded-lg border border-slate-300 px-4 py-3 text-sm font-bold text-slate-700 hover:border-sky-300 hover:text-sky-700"
              >
                İptal
              </button>
            ) : null}
          </div>
        </form>
      </section>

      <section className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
        <div className="flex items-center justify-between gap-3">
          <div>
            <h2 className="text-xl font-bold text-navy-800">
              Templates
            </h2>
            <p className="mt-1 text-sm text-slate-500">
              Üretim veya Batch Generate ekranında kullanmak için bir Template seçin.
            </p>
          </div>
          {templatesQuery.data ? (
            <span className="rounded-md bg-slate-100 px-3 py-1 text-xs font-bold text-slate-600">
              {templatesQuery.data.count} Template
            </span>
          ) : null}
        </div>

        <div className="mt-5">
          {templatesQuery.isLoading ? (
            <LoadingState label="Templates yükleniyor" />
          ) : null}

          {templatesQuery.isError ? (
            <ErrorAlert
              message={
                templatesQuery.error instanceof Error
                  ? templatesQuery.error.message
                  : "Templates yüklenemedi."
              }
            />
          ) : null}

          {templatesQuery.data && templatesQuery.data.items.length === 0 ? (
            <EmptyState
              title="Henüz Template yok"
              description="Premium üretimlerde yeniden kullanmak için ilk Custom Template'inizi oluşturun."
            />
          ) : null}

          {templatesQuery.data && templatesQuery.data.items.length > 0 ? (
            <div className="divide-y divide-slate-100">
              {templatesQuery.data.items.map((template) => (
                <article
                  key={template.id}
                  className="grid gap-4 py-4 md:grid-cols-[minmax(0,1fr)_150px]"
                >
                  <div>
                    <div className="flex flex-wrap items-center gap-2">
                      <h3 className="text-base font-bold text-navy-800">
                        {template.name}
                      </h3>
                      <span className="rounded-md bg-sky-50 px-2 py-1 text-xs font-bold text-sky-700">
                        #{template.id}
                      </span>
                    </div>
                    <p className="mt-2 line-clamp-3 whitespace-pre-line text-sm leading-6 text-slate-600">
                      {template.prompt_text}
                    </p>
                    <p className="mt-2 text-xs font-medium text-slate-400">
                      Güncellendi:{" "}
                      {new Date(template.updated_at).toLocaleString("tr-TR")}
                    </p>
                  </div>

                  <div className="flex items-start justify-end gap-2">
                    <button
                      type="button"
                      onClick={() => handleEdit(template)}
                      className="rounded-lg border border-slate-300 px-3 py-2 text-sm font-bold text-slate-700 hover:border-sky-300 hover:text-sky-700"
                    >
                      Düzenle
                    </button>
                    <button
                      type="button"
                      onClick={() => handleDelete(template)}
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
    </div>
  );
}

function PremiumWarning({
  title,
  description,
}: {
  title: string;
  description: string;
}) {
  return (
    <section className="rounded-lg border border-amber-200 bg-amber-50 p-6 shadow-sm">
      <p className="text-sm font-bold uppercase text-amber-700">Premium</p>
      <h1 className="mt-2 text-3xl font-extrabold text-amber-950">{title}</h1>
      <p className="mt-2 max-w-2xl text-sm leading-6 text-amber-800">
        {description}
      </p>
    </section>
  );
}
