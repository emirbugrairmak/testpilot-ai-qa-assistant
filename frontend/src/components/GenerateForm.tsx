import { useEffect, useState, type FormEvent } from "react";
import type { GenerateRequest, GenerationMode, Template } from "../types/api";
import { ModeSelector } from "./ModeSelector";

type GenerateFormProps = {
  mode: GenerationMode;
  isSubmitting: boolean;
  isPremium: boolean;
  templates: Template[];
  isTemplatesLoading: boolean;
  templatesError?: string | null;
  onModeChange: (mode: GenerationMode) => void;
  onSubmit: (payload: GenerateRequest) => void;
};

const inputClass =
  "w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-800 outline-none transition focus:border-sky-400 focus:ring-2 focus:ring-sky-100";
const labelClass = "text-sm font-semibold text-slate-700";

export function GenerateForm({
  mode,
  isSubmitting,
  isPremium,
  templates,
  isTemplatesLoading,
  templatesError,
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
  const [templateId, setTemplateId] = useState("");

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

  useEffect(() => {
    if (!templates.some((template) => String(template.id) === templateId)) {
      setTemplateId("");
    }
  }, [templateId, templates]);

  function withTemplate<T extends GenerateRequest>(payload: T): T {
    if (!isPremium || !templateId) {
      return payload;
    }

    return {
      ...payload,
      template_id: Number(templateId),
    };
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (mode === "mod_a") {
      onSubmit(withTemplate({
        mode,
        feature_idea: featureIdea.trim(),
      }));
      return;
    }

    if (mode === "mod_b") {
      onSubmit(withTemplate({
        mode,
        user_story: userStory.trim(),
        acceptance_criteria: acceptanceCriteria.trim(),
      }));
      return;
    }

    onSubmit(withTemplate({
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
    }));
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-5">
      <ModeSelector value={mode} onChange={onModeChange} />

      <div className="space-y-2 rounded-lg border border-slate-200 bg-slate-50 p-4">
        <label htmlFor="template_id" className={labelClass}>
          Custom Template
        </label>

        {isPremium ? (
          <>
            <select
              id="template_id"
              className={inputClass}
              value={templateId}
              onChange={(event) => setTemplateId(event.target.value)}
              disabled={isSubmitting || isTemplatesLoading || templates.length === 0}
            >
              <option value="">
                {isTemplatesLoading
                  ? "Templates yükleniyor"
                  : templates.length === 0
                    ? "Henüz Template yok"
                    : "Template kullanma"}
              </option>
              {templates.map((template) => (
                <option key={template.id} value={template.id}>
                  {template.name}
                </option>
              ))}
            </select>
            {templatesError ? (
              <p className="text-sm font-medium text-red-700">{templatesError}</p>
            ) : (
              <p className="text-sm text-slate-500">
                Template seçerek çıktıyı güvenlik, edge case veya regresyon gibi belirli bir odağa yönlendirebilirsiniz.
              </p>
            )}
          </>
        ) : (
          <p className="rounded-lg border border-amber-200 bg-amber-50 px-3 py-2 text-sm font-semibold text-amber-800">
            Custom Templates yalnızca Premium planda kullanılabilir.
          </p>
        )}
      </div>

      {mode === "mod_a" && (
        <div className="space-y-2">
          <label htmlFor="feature_idea" className={labelClass}>
            Özellik fikri
          </label>
          <textarea
            id="feature_idea"
            className={inputClass}
            rows={6}
            minLength={5}
            required
            value={featureIdea}
            onChange={(event) => setFeatureIdea(event.target.value)}
            placeholder="Kullanıcı e-posta ve şifre ile giriş yapabilsin"
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
              placeholder="Bir kullanıcı olarak, hesabıma tekrar erişebilmek için şifremi sıfırlamak istiyorum."
            />
          </div>

          <div className="space-y-2">
            <label htmlFor="acceptance_criteria" className={labelClass}>
              AC
            </label>
            <textarea
              id="acceptance_criteria"
              className={inputClass}
              rows={6}
              minLength={10}
              required
              value={acceptanceCriteria}
              onChange={(event) => setAcceptanceCriteria(event.target.value)}
              placeholder="Kayıtlı kullanıcı şifre sıfırlama talep ettiğinde, sıfırlama e-postası gönderilmelidir."
            />
          </div>
        </div>
      )}

      {mode === "bug_report" && (
        <div className="grid gap-4">
          <div className="grid gap-4 md:grid-cols-[1fr_180px]">
            <div className="space-y-2">
              <label htmlFor="bug_title" className={labelClass}>
                Başlık
              </label>
              <input
                id="bug_title"
                className={inputClass}
                minLength={3}
                required
                value={bugTitle}
                onChange={(event) => setBugTitle(event.target.value)}
                placeholder="Giriş butonu pasif kalıyor"
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
                <option value="Critical">Kritik</option>
                <option value="High">Yüksek</option>
                <option value="Medium">Orta</option>
                <option value="Low">Düşük</option>
              </select>
            </div>
          </div>

          <div className="space-y-2">
            <label htmlFor="steps" className={labelClass}>
              Yeniden üretme adımları
            </label>
            <textarea
              id="steps"
              className={inputClass}
              rows={5}
              required
              value={steps}
              onChange={(event) => setSteps(event.target.value)}
              placeholder={"Giriş sayfasını aç\nGeçerli e-posta ve şifre gir\nGiriş butonuna tıkla"}
            />
          </div>

          <div className="grid gap-4 md:grid-cols-2">
            <div className="space-y-2">
              <label htmlFor="actual_result" className={labelClass}>
                Gerçekleşen sonuç
              </label>
              <textarea
                id="actual_result"
                className={inputClass}
                rows={4}
                required
                value={actualResult}
                onChange={(event) => setActualResult(event.target.value)}
                placeholder="Giriş butonu pasif kalıyor."
              />
            </div>

            <div className="space-y-2">
              <label htmlFor="expected_result" className={labelClass}>
                Beklenen sonuç
              </label>
              <textarea
                id="expected_result"
                className={inputClass}
                rows={4}
                required
                value={expectedResult}
                onChange={(event) => setExpectedResult(event.target.value)}
                placeholder="Kullanıcı giriş formunu gönderebilmelidir."
              />
            </div>
          </div>

          <div className="space-y-2">
            <label htmlFor="environment" className={labelClass}>
              Ortam
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
        {isSubmitting ? "Üretiliyor" : "Üret"}
      </button>
    </form>
  );
}
