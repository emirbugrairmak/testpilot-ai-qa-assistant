import type { GenerateResponse } from "../types/api";

type OutputPreviewProps = {
  result: GenerateResponse;
};

export function OutputPreview({ result }: OutputPreviewProps) {
  return (
    <section className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <p className="text-sm font-semibold text-slate-500">
            Generation #{result.generation_id}
          </p>
          <h2 className="mt-1 text-xl font-bold text-navy-800">
            {result.mode === "bug_report" ? "Bug report" : "Test artifacts"}
          </h2>
        </div>
        {result.watermark && (
          <span className="rounded-md bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">
            {result.watermark}
          </span>
        )}
      </div>

      {result.bug_report ? (
        <BugReportPreview result={result} />
      ) : (
        <TestSuitePreview result={result} />
      )}
    </section>
  );
}

function BugReportPreview({ result }: OutputPreviewProps) {
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
        <Meta label="Environment" value={bugReport.environment} />
      </div>

      <div>
        <h4 className="text-sm font-bold text-slate-800">Steps</h4>
        <ol className="mt-2 list-decimal space-y-1 pl-5 text-sm text-slate-700">
          {bugReport.steps_to_reproduce.map((step) => (
            <li key={step}>{step}</li>
          ))}
        </ol>
      </div>

      <div className="grid gap-4 md:grid-cols-2">
        <TextBlock label="Actual result" value={bugReport.actual_result} />
        <TextBlock label="Expected result" value={bugReport.expected_result} />
      </div>
    </div>
  );
}

function TestSuitePreview({ result }: OutputPreviewProps) {
  return (
    <div className="mt-5 space-y-5">
      {result.user_story && (
        <TextBlock label="User story" value={result.user_story} />
      )}

      {result.acceptance_criteria && result.acceptance_criteria.length > 0 && (
        <div>
          <h4 className="text-sm font-bold text-slate-800">
            Acceptance criteria
          </h4>
          <ul className="mt-2 list-disc space-y-1 pl-5 text-sm text-slate-700">
            {result.acceptance_criteria.map((item) => (
              <li key={item}>{item}</li>
            ))}
          </ul>
        </div>
      )}

      {result.test_plan && (
        <div className="rounded-lg border border-slate-200 bg-slate-50 p-4">
          <h4 className="text-sm font-bold text-slate-800">Test plan</h4>
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
          <h4 className="text-sm font-bold text-slate-800">Test cases</h4>
          <div className="mt-3 grid gap-3">
            {result.test_cases.slice(0, 4).map((testCase) => (
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
                <p className="mt-2 text-sm text-slate-700">
                  {testCase.expected_result}
                </p>
              </article>
            ))}
          </div>
        </div>
      )}
    </div>
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

function TextBlock({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <h4 className="text-sm font-bold text-slate-800">{label}</h4>
      <p className="mt-2 text-sm leading-6 text-slate-700">{value}</p>
    </div>
  );
}
