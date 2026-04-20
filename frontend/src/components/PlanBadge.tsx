import type { Plan } from "../types/api";

type PlanBadgeProps = {
  plan: Plan;
};

export function PlanBadge({ plan }: PlanBadgeProps) {
  const isPremium = plan === "premium";

  return (
    <span
      className={
        isPremium
          ? "inline-flex rounded-md bg-accent-100 px-3 py-1 text-xs font-bold uppercase text-accent-700"
          : "inline-flex rounded-md bg-sky-100 px-3 py-1 text-xs font-bold uppercase text-sky-700"
      }
    >
      {isPremium ? "Premium" : "Free"}
    </span>
  );
}
