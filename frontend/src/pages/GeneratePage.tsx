import { ErrorAlert } from "../components/ErrorAlert";
import { EmptyState } from "../components/EmptyState";
import { GenerateForm } from "../components/GenerateForm";
import { LoadingState } from "../components/LoadingState";
import { useAuth } from "../hooks/useAuth";
import { useGenerate } from "../hooks/useGenerate";
import { useTemplates } from "../hooks/useTemplates";
import type { GenerateRequest, GenerationMode } from "../types/api";

type GeneratePageProps = {
  initialMode: GenerationMode;
  onModeChange: (mode: GenerationMode) => void;
  onResultReady: (generationId: number) => void;
};

export function GeneratePage({
  initialMode,
  onModeChange,
  onResultReady,
}: GeneratePageProps) {
  const mode = initialMode;
  const { user } = useAuth();
  const isPremium = user?.plan === "premium";
  const generateMutation = useGenerate();
  const templatesQuery = useTemplates(isPremium);

  function handleSubmit(payload: GenerateRequest) {
    generateMutation.mutate(payload, {
      onSuccess: (data) => onResultReady(data.generation_id),
    });
  }

  return (
    <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_minmax(360px,520px)]">
      <section className="rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
        <div>
          <p className="text-sm font-bold uppercase text-sky-700">Üretim</p>
          <h1 className="mt-2 text-3xl font-extrabold text-navy-800">
            QA çıktısı oluştur
          </h1>
          <p className="mt-2 max-w-2xl text-sm leading-6 text-slate-600">
            Bir mod seçin, alanları doldurun ve oluşturulan çıktıyı inceleyin.
          </p>
        </div>

        <div className="mt-6">
          <GenerateForm
            mode={mode}
            isSubmitting={generateMutation.isPending}
            isPremium={isPremium}
            templates={templatesQuery.data?.items ?? []}
            isTemplatesLoading={templatesQuery.isLoading}
            templatesError={
              templatesQuery.isError
                ? templatesQuery.error instanceof Error
                  ? templatesQuery.error.message
                  : "Templates yüklenemedi."
                : null
            }
            onModeChange={onModeChange}
            onSubmit={handleSubmit}
          />
        </div>
      </section>

      <aside className="space-y-4">
        {generateMutation.isPending && (
          <section className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
            <LoadingState label="Çıktı üretiliyor" />
          </section>
        )}

        {generateMutation.isError && (
          <ErrorAlert
            message={
              generateMutation.error instanceof Error
                ? generateMutation.error.message
                : "Üretim başarısız oldu."
            }
          />
        )}

        <EmptyState
          title="Sonuç sayfası"
          description="Başarılı üretimden sonra Export, Markdown ve detay bloklarının yer aldığı sonuç sayfasına yönlendirileceksiniz."
        />
      </aside>
    </div>
  );
}
