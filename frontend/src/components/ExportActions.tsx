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
      setMessage("CSV ve Jira Export seçenekleri Premium planda kullanılabilir.");
      return;
    }

    downloadMutation.mutate(
      { generationId, format },
      {
        onSuccess: (filename) => {
          setMessage(`İndirme başladı: ${filename}`);
        },
        onError: (error) => {
          setMessage(
            error instanceof Error ? error.message : "Export tamamlanamadı.",
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
            Mevcut sonucu ihtiyacınız olan formatta indirin.
          </p>
        </div>
        {downloadMutation.isPending && (
          <span className="text-sm font-semibold text-sky-700">Dosya hazırlanıyor</span>
        )}
      </div>

      <div className="mt-4 grid grid-cols-1 gap-3 min-[360px]:grid-cols-2">
        {exportOptions.map((option) => (
          <button
            key={option.format}
            type="button"
            onClick={() => handleDownload(option.format, option.premiumOnly)}
            className="min-w-0 rounded-lg border border-slate-200 bg-slate-50 px-3 py-3 text-left hover:border-sky-300 hover:bg-sky-50"
          >
            <span className="block truncate text-sm font-bold text-navy-800">
              {option.label}
            </span>
            <span className="mt-1 block text-xs leading-4 text-slate-500">
              {option.premiumOnly
                ? "Premium Export"
                : plan === "free"
                  ? "İmzalı Free provenance içerir"
                  : "Tüm planlarda kullanılabilir"}
            </span>
          </button>
        ))}
      </div>

      {message ? (
        <div className="mt-4">
          {message.startsWith("İndirme başladı") ? (
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
