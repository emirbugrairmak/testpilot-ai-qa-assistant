import type { GenerationMode } from "../types/api";

type ModeSelectorProps = {
  value: GenerationMode;
  onChange: (mode: GenerationMode) => void;
};

const modes: Array<{
  value: GenerationMode;
  title: string;
  description: string;
}> = [
  {
    value: "mod_a",
    title: "Mod A",
    description: "Feature idea to test suite",
  },
  {
    value: "mod_b",
    title: "Mod B",
    description: "Story and AC to test cases",
  },
  {
    value: "bug_report",
    title: "Bug Report",
    description: "Issue notes to bug template",
  },
];

export function ModeSelector({ value, onChange }: ModeSelectorProps) {
  return (
    <div className="grid gap-3 md:grid-cols-3">
      {modes.map((mode) => {
        const isSelected = value === mode.value;

        return (
          <button
            key={mode.value}
            type="button"
            onClick={() => onChange(mode.value)}
            className={
              isSelected
                ? "rounded-lg border border-sky-400 bg-sky-50 p-4 text-left shadow-sm"
                : "rounded-lg border border-slate-200 bg-white p-4 text-left shadow-sm hover:border-sky-300"
            }
          >
            <span className="block text-sm font-bold text-navy-800">
              {mode.title}
            </span>
            <span className="mt-1 block text-sm text-slate-600">
              {mode.description}
            </span>
          </button>
        );
      })}
    </div>
  );
}
