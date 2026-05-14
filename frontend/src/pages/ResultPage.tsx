import { EmptyState } from "../components/EmptyState";
import { ErrorAlert } from "../components/ErrorAlert";
import { ExportActions } from "../components/ExportActions";
import { LoadingState } from "../components/LoadingState";
import { OutputPreview } from "../components/OutputPreview";
import { PlanBadge } from "../components/PlanBadge";
import { useAuth } from "../hooks/useAuth";
import { useHistoryDetail } from "../hooks/useHistoryDetail";
import type { BugReport, GenerateResponse } from "../types/api";
import { cleanMarkdownListMarkers } from "../utils/textFormatting";

type ResultPageProps = {
  generationId: number;
  onBackToHistory: () => void;
};

export function ResultPage({
  generationId,
  onBackToHistory,
}: ResultPageProps) {
  const { isAuthenticated, user } = useAuth();
  const detailQuery = useHistoryDetail(generationId, isAuthenticated);

  if (detailQuery.isLoading) {
    return (
      <section className="rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
        <LoadingState label="Sonuç yükleniyor" />
      </section>
    );
  }

  if (detailQuery.isError) {
    return (
      <div className="space-y-4">
        <ErrorAlert
          message={
            detailQuery.error instanceof Error
              ? detailQuery.error.message
              : "Sonuç yüklenemedi."
          }
        />
        <button
          type="button"
          onClick={onBackToHistory}
          className="rounded-lg bg-navy-800 px-4 py-2 text-sm font-bold text-white hover:bg-navy-700"
        >
          History'ye dön
        </button>
      </div>
    );
  }

  if (!detailQuery.data || !user) {
    return (
      <EmptyState
        title="Sonuç kullanılamıyor"
        description="Seçili üretim açılamadı."
      />
    );
  }

  const normalizedOutput = normalizeLegacyOutput(
    detailQuery.data.output,
    detailQuery.data.input,
  );
  const result: GenerateResponse = {
    ...normalizedOutput,
    generation_id: detailQuery.data.generation_id,
    display_id: detailQuery.data.display_id,
    markdown: detailQuery.data.markdown,
  };
  const markdownPreview = cleanLegacyMarkdown(
    detailQuery.data.markdown,
    result.bug_report,
  );

  return (
    <div className="space-y-6">
      <section className="rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
          <div>
            <div className="flex flex-wrap items-center gap-3">
              <p className="text-sm font-bold uppercase text-sky-700">Sonuç</p>
              <PlanBadge plan={user.plan} />
            </div>
            <h1 className="mt-2 text-3xl font-extrabold text-navy-800">
              Üretim #{detailQuery.data.display_id}
            </h1>
            <p className="mt-2 text-sm leading-6 text-slate-600">
              Oluşturulma zamanı:{" "}
              {new Date(detailQuery.data.created_at).toLocaleString("tr-TR")}
            </p>
            {(result.plan_stamp || result.watermark) && (
              <p className="mt-1 text-xs font-medium text-slate-500">
                Kaynak: {formatPlanSource(result)}
              </p>
            )}
          </div>

          <button
            type="button"
            onClick={onBackToHistory}
            className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-bold text-slate-700 hover:border-sky-300 hover:text-sky-700"
          >
            History'ye dön
          </button>
        </div>
      </section>

      <div className="grid gap-6 xl:grid-cols-[minmax(0,1fr)_360px]">
        <div className="space-y-6">
          <OutputPreview result={result} fullDetails />

          <section className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
            <h2 className="text-lg font-bold text-navy-800">Markdown önizleme</h2>
            <pre className="mt-4 overflow-x-auto whitespace-pre-wrap rounded-lg bg-slate-50 p-4 text-sm leading-6 text-slate-700">
              {cleanMarkdownListMarkers(markdownPreview)}
            </pre>
          </section>
        </div>

        <aside className="space-y-6">
          <ExportActions
            generationId={detailQuery.data.generation_id}
            plan={user.plan}
            mode={result.mode}
          />

          <section className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
            <h2 className="text-lg font-bold text-navy-800">Girdi</h2>
            <pre className="mt-4 overflow-x-auto whitespace-pre-wrap rounded-lg bg-slate-50 p-4 text-sm leading-6 text-slate-700">
              {JSON.stringify(detailQuery.data.input, null, 2)}
            </pre>
          </section>
        </aside>
      </div>
    </div>
  );
}

function normalizeLegacyOutput(
  output: Omit<GenerateResponse, "generation_id" | "display_id">,
  input: Record<string, unknown>,
) {
  if (output.mode !== "bug_report" || !output.bug_report) {
    return output;
  }

  const { severity, priority } = normalizeSeverity(
    input.severity ?? output.bug_report.severity,
  );
  const labels = normalizeLabels(output.bug_report.labels, severity);

  return {
    ...output,
    tags: labels,
    bug_report: {
      ...output.bug_report,
      severity,
      priority,
      labels,
    },
  };
}

function normalizeSeverity(value: unknown) {
  const normalized = String(value ?? "").trim().toLowerCase();
  const severityKey =
    {
      critical: "kritik",
      blocker: "kritik",
      kritik: "kritik",
      high: "yüksek",
      major: "yüksek",
      yüksek: "yüksek",
      yuksek: "yüksek",
      medium: "orta",
      minor: "orta",
      orta: "orta",
      low: "düşük",
      trivial: "düşük",
      düşük: "düşük",
      dusuk: "düşük",
    }[normalized] ?? "orta";

  const severity =
    severityKey === "kritik"
      ? "Kritik"
      : severityKey === "yüksek"
        ? "Yüksek"
        : severityKey === "düşük"
          ? "Düşük"
          : "Orta";
  const priority =
    severityKey === "kritik"
      ? "P0"
      : severityKey === "yüksek"
        ? "P1"
        : severityKey === "düşük"
          ? "P3"
          : "P2";

  return { severity, priority };
}

function normalizeLabels(labels: string[] = [], severity: string) {
  const severityLabels = new Set([
    "critical",
    "blocker",
    "kritik",
    "high",
    "major",
    "yüksek",
    "yuksek",
    "medium",
    "minor",
    "orta",
    "low",
    "trivial",
    "düşük",
    "dusuk",
  ]);
  const cleaned = labels.filter(
    (label) => !severityLabels.has(label.trim().toLowerCase()),
  );
  const severityLabel = severity.toLowerCase();
  if (!cleaned.some((label) => label.trim().toLowerCase() === severityLabel)) {
    cleaned.push(severityLabel);
  }
  return cleaned;
}

function cleanLegacyMarkdown(markdown: string, bugReport?: BugReport) {
  return markdown
    .split("\n")
    .filter(
      (line) =>
        !/^\*\*(Mode|AI Provider|Generated):\*\*/.test(line.trim()),
    )
    .map((line) => {
      if (bugReport && /^\*\*Severity:\*\*/.test(line.trim())) {
        return `**Severity:** ${bugReport.severity}`;
      }
      if (bugReport && /^\*\*Priority:\*\*/.test(line.trim())) {
        return `**Priority:** ${bugReport.priority}`;
      }
      return line;
    })
    .join("\n")
    .trim();
}

function formatPlanSource(result: GenerateResponse) {
  if (result.plan_stamp?.label) {
    return result.plan_stamp.label;
  }

  if (result.watermark === "Generated by TestPilot (Free Plan)") {
    return "Free plan";
  }

  return result.watermark ?? "Free plan";
}
