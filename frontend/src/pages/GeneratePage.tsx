import { useState } from "react";
import { ErrorAlert } from "../components/ErrorAlert";
import { GenerateForm } from "../components/GenerateForm";
import { LoadingState } from "../components/LoadingState";
import { OutputPreview } from "../components/OutputPreview";
import { useGenerate } from "../hooks/useGenerate";
import type { GenerateRequest, GenerateResponse, GenerationMode } from "../types/api";

type GeneratePageProps = {
  initialMode: GenerationMode;
};

export function GeneratePage({ initialMode }: GeneratePageProps) {
  const [mode, setMode] = useState<GenerationMode>(initialMode);
  const [result, setResult] = useState<GenerateResponse | null>(null);
  const generateMutation = useGenerate();

  function handleModeChange(nextMode: GenerationMode) {
    setMode(nextMode);
    setResult(null);
  }

  function handleSubmit(payload: GenerateRequest) {
    setResult(null);
    generateMutation.mutate(payload, {
      onSuccess: (data) => setResult(data),
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
            onModeChange={handleModeChange}
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

        {result ? (
          <OutputPreview result={result} />
        ) : (
          <section className="rounded-lg border border-dashed border-slate-300 bg-white p-5 text-sm leading-6 text-slate-600">
            Your generated test suite or bug report preview will appear here.
          </section>
        )}
      </aside>
    </div>
  );
}
