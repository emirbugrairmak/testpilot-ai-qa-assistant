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
          <p className="text-sm font-bold uppercase text-sky-700">Generate</p>
          <h1 className="mt-2 text-3xl font-extrabold text-navy-800">
            Create QA output
          </h1>
          <p className="mt-2 max-w-2xl text-sm leading-6 text-slate-600">
            Pick a mode, fill the fields, and preview the generated artifact.
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
                  : "Could not load templates."
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
            <LoadingState label="Generating output" />
          </section>
        )}

        {generateMutation.isError && (
          <ErrorAlert
            message={
              generateMutation.error instanceof Error
                ? generateMutation.error.message
                : "Generation failed."
            }
          />
        )}

        <EmptyState
          title="Result page"
          description="After a successful generation, you will be taken to the result page where exports, markdown, and detailed blocks are available."
        />
      </aside>
    </div>
  );
}
