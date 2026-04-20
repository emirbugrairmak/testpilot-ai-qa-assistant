import { useEffect, useState, type FormEvent } from "react";
import type { GenerateRequest, GenerationMode } from "../types/api";
import { ModeSelector } from "./ModeSelector";

type GenerateFormProps = {
  mode: GenerationMode;
  isSubmitting: boolean;
  onModeChange: (mode: GenerationMode) => void;
  onSubmit: (payload: GenerateRequest) => void;
};

const inputClass =
  "w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-800 outline-none transition focus:border-sky-400 focus:ring-2 focus:ring-sky-100";
const labelClass = "text-sm font-semibold text-slate-700";

export function GenerateForm({
  mode,
  isSubmitting,
  onModeChange,
  onSubmit,
}: GenerateFormProps) {
  const [featureIdea, setFeatureIdea] = useState("");
  const [userStory, setUserStory] = useState("");
  const [acceptanceCriteria, setAcceptanceCriteria] = useState("");
  const [bugTitle, setBugTitle] = useState("");
  const [steps, setSteps] = useState("");
  const [actualResult, setActualResult] = useState("");
  const [expectedResult, setExpectedResult] = useState("");
  const [environment, setEnvironment] = useState("");
  const [severity, setSeverity] = useState("Medium");

  useEffect(() => {
    setFeatureIdea("");
    setUserStory("");
    setAcceptanceCriteria("");
    setBugTitle("");
    setSteps("");
    setActualResult("");
    setExpectedResult("");
    setEnvironment("");
    setSeverity("Medium");
  }, [mode]);

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (mode === "mod_a") {
      onSubmit({
        mode,
        feature_idea: featureIdea.trim(),
      });
      return;
    }

    if (mode === "mod_b") {
      onSubmit({
        mode,
        user_story: userStory.trim(),
        acceptance_criteria: acceptanceCriteria.trim(),
      });
      return;
    }

    onSubmit({
      mode,
      title: bugTitle.trim(),
      steps_to_reproduce: steps
        .split("\n")
        .map((step) => step.trim())
        .filter(Boolean),
      actual_result: actualResult.trim(),
      expected_result: expectedResult.trim(),
      environment: environment.trim(),
      severity,
    });
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-5">
      <ModeSelector value={mode} onChange={onModeChange} />

      {mode === "mod_a" && (
        <div className="space-y-2">
          <label htmlFor="feature_idea" className={labelClass}>
            Feature idea
          </label>
          <textarea
            id="feature_idea"
            className={inputClass}
            rows={6}
            minLength={5}
            required
            value={featureIdea}
            onChange={(event) => setFeatureIdea(event.target.value)}
            placeholder="User login with email and password"
          />
        </div>
      )}

      {mode === "mod_b" && (
        <div className="grid gap-4">
          <div className="space-y-2">
            <label htmlFor="user_story" className={labelClass}>
              User story
            </label>
            <textarea
              id="user_story"
              className={inputClass}
              rows={4}
              minLength={10}
              required
              value={userStory}
              onChange={(event) => setUserStory(event.target.value)}
              placeholder="As a user, I want to reset my password so that I can regain access."
            />
          </div>

          <div className="space-y-2">
            <label htmlFor="acceptance_criteria" className={labelClass}>
              Acceptance criteria
            </label>
            <textarea
              id="acceptance_criteria"
              className={inputClass}
              rows={6}
              minLength={10}
              required
              value={acceptanceCriteria}
              onChange={(event) => setAcceptanceCriteria(event.target.value)}
              placeholder="Given a registered user, when they request a password reset, then a reset email is sent."
            />
          </div>
        </div>
      )}

      {mode === "bug_report" && (
        <div className="grid gap-4">
          <div className="grid gap-4 md:grid-cols-[1fr_180px]">
            <div className="space-y-2">
              <label htmlFor="bug_title" className={labelClass}>
                Title
              </label>
              <input
                id="bug_title"
                className={inputClass}
                minLength={3}
                required
                value={bugTitle}
                onChange={(event) => setBugTitle(event.target.value)}
                placeholder="Login button stays disabled"
              />
            </div>

            <div className="space-y-2">
              <label htmlFor="severity" className={labelClass}>
                Severity
              </label>
              <select
                id="severity"
                className={inputClass}
                value={severity}
                onChange={(event) => setSeverity(event.target.value)}
              >
                <option>Critical</option>
                <option>High</option>
                <option>Medium</option>
                <option>Low</option>
              </select>
            </div>
          </div>

          <div className="space-y-2">
            <label htmlFor="steps" className={labelClass}>
              Steps to reproduce
            </label>
            <textarea
              id="steps"
              className={inputClass}
              rows={5}
              required
              value={steps}
              onChange={(event) => setSteps(event.target.value)}
              placeholder={"Open the login page\nEnter a valid email and password\nTry to click Login"}
            />
          </div>

          <div className="grid gap-4 md:grid-cols-2">
            <div className="space-y-2">
              <label htmlFor="actual_result" className={labelClass}>
                Actual result
              </label>
              <textarea
                id="actual_result"
                className={inputClass}
                rows={4}
                required
                value={actualResult}
                onChange={(event) => setActualResult(event.target.value)}
                placeholder="The Login button remains disabled."
              />
            </div>

            <div className="space-y-2">
              <label htmlFor="expected_result" className={labelClass}>
                Expected result
              </label>
              <textarea
                id="expected_result"
                className={inputClass}
                rows={4}
                required
                value={expectedResult}
                onChange={(event) => setExpectedResult(event.target.value)}
                placeholder="The user can submit the login form."
              />
            </div>
          </div>

          <div className="space-y-2">
            <label htmlFor="environment" className={labelClass}>
              Environment
            </label>
            <input
              id="environment"
              className={inputClass}
              required
              value={environment}
              onChange={(event) => setEnvironment(event.target.value)}
              placeholder="Chrome 123, macOS"
            />
          </div>
        </div>
      )}

      <button
        type="submit"
        disabled={isSubmitting}
        className="inline-flex w-full justify-center rounded-lg bg-accent-500 px-4 py-3 text-sm font-bold text-white shadow-sm hover:bg-accent-600 disabled:cursor-not-allowed disabled:opacity-60 md:w-auto"
      >
        {isSubmitting ? "Generating" : "Generate"}
      </button>
    </form>
  );
}
