import type { UsageResponse } from "../types/api";

type UsageCardProps = {
  usage: UsageResponse;
};

export function UsageCard({ usage }: UsageCardProps) {
  const usedPercent =
    usage.monthly_limit > 0
      ? Math.min((usage.usage_count / usage.monthly_limit) * 100, 100)
      : 0;

  return (
    <section className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="text-sm font-semibold text-slate-500">Monthly usage</p>
          <p className="mt-2 text-3xl font-bold text-navy-800">
            {usage.usage_count}
            <span className="text-base font-semibold text-slate-500">
              {" "}
              / {usage.monthly_limit}
            </span>
          </p>
        </div>
        <div className="rounded-md bg-sky-50 px-3 py-2 text-right">
          <p className="text-xs font-semibold text-slate-500">Remaining</p>
          <p className="text-lg font-bold text-sky-700">{usage.remaining}</p>
        </div>
      </div>

      <div className="mt-5 h-2 overflow-hidden rounded-md bg-slate-100">
        <div
          className="h-full rounded-md bg-sky-400"
          style={{ width: `${usedPercent}%` }}
        />
      </div>

      <p className="mt-3 text-xs font-medium text-slate-500">
        Resets at {new Date(usage.usage_reset_at).toLocaleDateString()}
      </p>
    </section>
  );
}
