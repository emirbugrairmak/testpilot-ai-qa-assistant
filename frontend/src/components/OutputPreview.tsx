import type { GenerateResponse } from "../types/api";
import { cleanListItem } from "../utils/textFormatting";

type OutputPreviewProps = {
  result: GenerateResponse;
  fullDetails?: boolean;
};

export function OutputPreview({
  result,
  fullDetails = false,
}: OutputPreviewProps) {
  return (
    <section className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
      <div>
        <p className="text-sm font-semibold text-slate-500">
          Üretim #{result.generation_id}
        </p>
        <h2 className="mt-1 text-xl font-bold text-navy-800">
          {result.mode === "bug_report" ? "Bug Report" : "Test çıktıları"}
        </h2>
      </div>

      {result.bug_report ? (
        <BugReportPreview result={result} fullDetails={fullDetails} />
      ) : (
        <TestSuitePreview result={result} fullDetails={fullDetails} />
      )}
    </section>
  );
}

function BugReportPreview({
  result,
  fullDetails,
}: OutputPreviewProps) {
  const bugReport = result.bug_report;

  if (!bugReport) {
    return null;
  }

  return (
    <div className="mt-5 space-y-5">
      <div>
        <h3 className="text-lg font-bold text-slate-900">{bugReport.title}</h3>
        <p className="mt-2 text-sm leading-6 text-slate-700">
          {bugReport.summary}
        </p>
      </div>

      <div className="grid gap-3 md:grid-cols-3">
        <Meta label="Severity" value={bugReport.severity} />
        <Meta label="Priority" value={bugReport.priority} />
        <Meta label="Ortam" value={bugReport.environment} />
      </div>

      <div>
        <h4 className="text-sm font-bold text-slate-800">Adımlar</h4>
        <ol className="mt-2 list-decimal space-y-1 pl-5 text-sm text-slate-700">
          {bugReport.steps_to_reproduce.map((step) => (
            <li key={step}>{cleanListItem(step)}</li>
          ))}
        </ol>
      </div>

      <div className="grid gap-4 md:grid-cols-2">
        <TextBlock label="Gerçekleşen sonuç" value={bugReport.actual_result} />
        <TextBlock label="Beklenen sonuç" value={bugReport.expected_result} />
      </div>

      {fullDetails && bugReport.labels.length > 0 ? (
        <div>
          <h4 className="text-sm font-bold text-slate-800">Etiketler</h4>
          <div className="mt-2 flex flex-wrap gap-2">
            {bugReport.labels.map((label) => (
              <span
                key={label}
                className="rounded-md bg-sky-50 px-2 py-1 text-xs font-semibold text-sky-700 ring-1 ring-sky-100"
              >
                {label}
              </span>
            ))}
          </div>
        </div>
      ) : null}
    </div>
  );
}

function TestSuitePreview({
  result,
  fullDetails,
}: OutputPreviewProps) {
  const visibleCases = fullDetails
    ? result.test_cases ?? []
    : result.test_cases?.slice(0, 4) ?? [];

  return (
    <div className="mt-5 space-y-5">
      {result.user_story && (
        <TextBlock label="User story" value={result.user_story} />
      )}

      {result.acceptance_criteria && result.acceptance_criteria.length > 0 && (
        <div>
          <h4 className="text-sm font-bold text-slate-800">
            AC / Acceptance Criteria
          </h4>
          <div className="mt-3 grid gap-3">
            {result.acceptance_criteria.map((item, index) => (
              <AcceptanceCriteriaCard item={item} key={`${index}-${item}`} />
            ))}
          </div>
        </div>
      )}

      {result.test_plan && (
        <div className="rounded-lg border border-slate-200 bg-slate-50 p-4">
          <h4 className="text-sm font-bold text-slate-800">Test planı</h4>
          <p className="mt-2 text-sm leading-6 text-slate-700">
            {result.test_plan.objective}
          </p>
          <p className="mt-2 text-sm leading-6 text-slate-700">
            {result.test_plan.approach}
          </p>
        </div>
      )}

      {result.test_cases && result.test_cases.length > 0 && (
        <div>
          <h4 className="text-sm font-bold text-slate-800">Test Cases</h4>
          <div className="mt-3 grid gap-3">
            {visibleCases.map((testCase) => (
              <article
                key={testCase.id}
                className="rounded-lg border border-slate-200 bg-white p-4"
              >
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <h5 className="font-bold text-navy-800">
                    {testCase.id} · {testCase.title}
                  </h5>
                  <span className="rounded-md bg-accent-50 px-2 py-1 text-xs font-bold text-accent-700">
                    {testCase.priority}
                  </span>
                </div>
                <div className="mt-3">
                  <p className="text-xs font-bold uppercase text-slate-500">
                    Beklenen Sonuç
                  </p>
                  <p className="mt-1 text-sm text-slate-700">
                    {cleanListItem(testCase.expected_result)}
                  </p>
                </div>
                {fullDetails ? (
                  <>
                    <p className="mt-2 text-sm text-slate-600">
                      <span className="font-semibold text-slate-800">
                        Ön koşullar:
                      </span>{" "}
                      {cleanListItem(testCase.preconditions)}
                    </p>
                    <ol className="mt-3 list-decimal space-y-1 pl-5 text-sm text-slate-700">
                      {testCase.steps.map((step) => (
                        <li key={step}>{cleanListItem(step)}</li>
                      ))}
                    </ol>
                    {testCase.tags.length > 0 ? (
                      <div className="mt-3 flex flex-wrap gap-2">
                        {testCase.tags.map((tag) => (
                          <span
                            key={tag}
                            className="rounded-md bg-sky-50 px-2 py-1 text-xs font-semibold text-sky-700"
                          >
                            {tag}
                          </span>
                        ))}
                      </div>
                    ) : null}
                  </>
                ) : null}
              </article>
            ))}
          </div>
          {!fullDetails && (result.test_cases?.length ?? 0) > visibleCases.length ? (
            <p className="mt-3 text-xs font-medium text-slate-500">
              Tüm Test Case listesini incelemek için sonuç sayfasını açın.
            </p>
          ) : null}
        </div>
      )}
    </div>
  );
}

function AcceptanceCriteriaCard({ item }: { item: string }) {
  const parts = acceptanceCriteriaParts(item);

  if (parts.length === 0) {
    return null;
  }

  return (
    <article className="rounded-lg border border-slate-900 bg-white p-4">
      <div className="grid gap-3">
        {parts.map((part, index) =>
          part.label ? (
            <div
              key={`${index}-${part.label}-${part.value}`}
              className="grid grid-cols-[76px_minmax(0,1fr)] gap-4 text-sm leading-6 md:text-base"
            >
              <span className="font-extrabold text-navy-800">
                {part.label}
              </span>
              <span className="text-slate-900">{part.value}</span>
            </div>
          ) : (
            <p
              key={`${index}-${part.value}`}
              className="text-sm leading-6 text-slate-900 md:text-base"
            >
              {part.value}
            </p>
          ),
        )}
      </div>
    </article>
  );
}

function Meta({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-lg border border-slate-200 bg-slate-50 p-3">
      <p className="text-xs font-semibold text-slate-500">{label}</p>
      <p className="mt-1 text-sm font-bold text-navy-800">{value}</p>
    </div>
  );
}

function acceptanceCriteriaParts(item: string) {
  const cleanItem = stripLeadingBullet(item).replace(/\s+/g, " ").trim();

  if (!cleanItem) {
    return [];
  }

  const markerPattern = /\b(Given|When|Then|And|But)\b/gi;
  const matches = Array.from(cleanItem.matchAll(markerPattern));

  if (matches.length === 0) {
    return [{ label: "", value: cleanItem }];
  }

  const parts: Array<{ label: string; value: string }> = [];
  const leadingText = cleanItem.slice(0, matches[0].index ?? 0).trim();
  if (leadingText) {
    parts.push({ label: "", value: leadingText });
  }

  matches.forEach((match, index) => {
    const start = match.index ?? 0;
    const nextStart =
      index + 1 < matches.length
        ? matches[index + 1].index ?? cleanItem.length
        : cleanItem.length;
    const text = cleanItem.slice(start, nextStart).trim();
    if (text) {
      parts.push(gherkinPart(text));
    }
  });

  return parts;
}

function stripLeadingBullet(value: string) {
  return value.replace(/^\s*(?:[-*•]\s+|\d+[.)]\s*)/, "");
}

function gherkinPart(value: string) {
  const normalized = value.replace(
    /^(given|when|then|and|but)\b/i,
    (word) => {
      const lower = word.toLowerCase();
      if (lower === "given") return "Given";
      if (lower === "when") return "When";
      if (lower === "then") return "Then";
      if (lower === "and") return "And";
      if (lower === "but") return "But";
      return word;
    },
  );
  const separator = normalized.indexOf(" ");

  if (separator === -1) {
    return { label: normalized, value: "" };
  }

  return {
    label: normalized.slice(0, separator),
    value: stripLeadingPunctuation(normalized.slice(separator + 1)),
  };
}

function stripLeadingPunctuation(value: string) {
  return value.replace(/^\s*[:-]\s*/, "").trim();
}

function TextBlock({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <h4 className="text-sm font-bold text-slate-800">{label}</h4>
      <p className="mt-2 text-sm leading-6 text-slate-700">
        {cleanListItem(value)}
      </p>
    </div>
  );
}
