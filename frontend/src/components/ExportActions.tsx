import { useState } from "react";
import { useExportDownload } from "../hooks/useExportDownload";
import type { ExportFormat, Plan } from "../types/api";
import { ErrorAlert } from "./ErrorAlert";

type ExportActionsProps = {
  generationId: number;
  plan: Plan;
};

const exportOptions: Array<{
  format: ExportFormat;
  label: string;
  premiumOnly: boolean;
}> = [
  { format: "json", label: "JSON", premiumOnly: false },
  { format: "markdown", label: "Markdown", premiumOnly: false },
  { format: "csv", label: "CSV", premiumOnly: true },
  { format: "jira", label: "Jira", premiumOnly: true },
];

export function ExportActions({ generationId, plan }: ExportActionsProps) {
  const [message, setMessage] = useState<string | null>(null);
  const downloadMutation = useExportDownload();

  function handleDownload(format: ExportFormat, premiumOnly: boolean) {
    setMessage(null);

    if (premiumOnly && plan === "free") {
      setMessage("CSV and Jira exports are available on the premium plan.");
      return;
    }

    downloadMutation.mutate(
      { generationId, format },
      {
        onSuccess: (filename) => {
          setMessage(`Download started: ${filename}`);
        },
        onError: (error) => {
          setMessage(
            error instanceof Error ? error.message : "Export could not be completed.",
          );
        },
      },
    );
  }

  return (
    <section className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h2 className="text-lg font-bold text-navy-800">Export</h2>
          <p className="mt-1 text-sm text-slate-500">
            Download the current result in the format you need.
          </p>
        </div>
        {downloadMutation.isPending && (
          <span className="text-sm font-semibold text-sky-700">Preparing file</span>
        )}
      </div>

      <div className="mt-4 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        {exportOptions.map((option) => (
          <button
            key={option.format}
            type="button"
            onClick={() => handleDownload(option.format, option.premiumOnly)}
            className="rounded-lg border border-slate-200 bg-slate-50 px-4 py-3 text-left hover:border-sky-300 hover:bg-sky-50"
          >
            <span className="block text-sm font-bold text-navy-800">
              {option.label}
            </span>
            <span className="mt-1 block text-xs text-slate-500">
              {option.premiumOnly ? "Premium export" : "Available on all plans"}
            </span>
          </button>
        ))}
      </div>

      {message ? (
        <div className="mt-4">
          {message.startsWith("Download started") ? (
            <div className="rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm font-medium text-emerald-700">
              {message}
            </div>
          ) : (
            <ErrorAlert message={message} />
          )}
        </div>
      ) : null}
    </section>
  );
}
