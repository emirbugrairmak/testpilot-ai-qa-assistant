import { useState, type FormEvent } from "react";
import logoUrl from "../assets/testpilot-logo.png";
import { ErrorAlert } from "../components/ErrorAlert";
import { LoadingState } from "../components/LoadingState";
import { useAuth } from "../hooks/useAuth";

type LoginPageProps = {
  onLoginSuccess: () => void;
};

const accessOptions = [
  {
    key: "tp_free_demo_key",
    title: "Deneme erişimi",
    plan: "Free çalışma alanı",
    description: "Aylık 30 üretim, Markdown/JSON dışa aktarımı ve son 15 kayıt.",
  },
  {
    key: "tp_premium_demo_key",
    title: "Profesyonel erişim",
    plan: "Premium çalışma alanı",
    description: "Yüksek limit, sınırsız History, CSV/Jira Export ve Template akışları.",
  },
];

export function LoginPage({ onLoginSuccess }: LoginPageProps) {
  const { login, isLoggingIn, loginError, clearLoginError } = useAuth();
  const [apiKey, setApiKey] = useState("");

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    clearLoginError();
    await login(apiKey);
    onLoginSuccess();
  }

  return (
    <main className="min-h-screen bg-slate-50">
      <div className="mx-auto grid min-h-screen max-w-6xl items-center gap-10 px-4 py-10 sm:px-6 lg:grid-cols-[1fr_420px] lg:px-8">
        <section className="space-y-7">
          <div className="flex items-center gap-4">
            <img
              src={logoUrl}
              alt="TestPilot logo"
              className="h-16 w-16 rounded-lg object-cover shadow-sm"
            />
            <div>
              <p className="text-3xl font-extrabold text-navy-800">
                TestPilot
              </p>
              <p className="text-base font-semibold text-sky-700">
                AI QA Asistanı
              </p>
            </div>
          </div>

          <div className="max-w-2xl">
            <h1 className="text-4xl font-extrabold leading-tight text-navy-800">
              QA çalışmalarınızı tek bir erişim anahtarıyla başlatın.
            </h1>
            <p className="mt-4 text-lg leading-8 text-slate-600">
              TestPilot, çalışma alanı anahtarınızı doğrular; kullanım limitinizi,
              History kayıtlarınızı ve AI destekli test çıktılarınızı aynı
              profesyonel akışta toplar.
            </p>
          </div>

          <div className="grid max-w-2xl gap-3 sm:grid-cols-3">
            {["Fikirden Test Cases", "User Story'den Test Cases", "Bug Report"].map((item) => (
              <div
                key={item}
                className="rounded-lg border border-slate-200 bg-white px-4 py-3 text-sm font-bold text-slate-700 shadow-sm"
              >
                {item}
              </div>
            ))}
          </div>
        </section>

        <section className="rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
          <div>
            <p className="text-sm font-bold uppercase text-sky-700">
              Çalışma alanı erişimi
            </p>
            <h2 className="mt-2 text-2xl font-bold text-navy-800">
              Erişim anahtarınızı doğrulayın
            </h2>
            <p className="mt-2 text-sm leading-6 text-slate-600">
              Davet, deneme veya ekip anahtarınızı girin. Anahtar planınızı ve
              kullanım haklarınızı belirler; ayrı bir kayıt adımı gerekmez.
            </p>
          </div>

          <form onSubmit={handleSubmit} className="mt-6 space-y-4">
            <div className="space-y-2">
              <label
                htmlFor="api_key"
                className="text-sm font-semibold text-slate-700"
              >
                Erişim anahtarı
              </label>
              <input
                id="api_key"
                className="w-full rounded-lg border border-slate-300 bg-white px-3 py-3 text-sm text-slate-800 outline-none focus:border-sky-400 focus:ring-2 focus:ring-sky-100"
                value={apiKey}
                onChange={(event) => setApiKey(event.target.value)}
                placeholder="Çalışma alanı erişim anahtarınızı girin"
                required
                type="password"
              />
            </div>

            {loginError && <ErrorAlert message={loginError} />}

            <button
              type="submit"
              disabled={isLoggingIn}
              className="inline-flex w-full justify-center rounded-lg bg-accent-500 px-4 py-3 text-sm font-bold text-white shadow-sm hover:bg-accent-600 disabled:cursor-not-allowed disabled:opacity-60"
            >
              {isLoggingIn ? "Doğrulanıyor" : "Çalışma alanına devam et"}
            </button>

            {isLoggingIn && <LoadingState label="Erişim anahtarı kontrol ediliyor" />}
          </form>

          <div className="mt-6 space-y-3">
            <div>
              <p className="font-bold text-slate-800">Hazır erişim seçenekleri</p>
              <p className="mt-1 text-sm leading-6 text-slate-500">
                Ürün akışını incelemek için bir çalışma alanı tipi seçin.
              </p>
            </div>

            {accessOptions.map((option) => {
              const selected = apiKey === option.key;

              return (
                <button
                  key={option.key}
                  type="button"
                  onClick={() => {
                    clearLoginError();
                    setApiKey(option.key);
                  }}
                  aria-pressed={selected}
                  className={`w-full rounded-lg border px-4 py-3 text-left transition ${
                    selected
                      ? "border-sky-300 bg-sky-50 ring-2 ring-sky-100"
                      : "border-slate-200 bg-slate-50 hover:border-sky-200 hover:bg-white"
                  }`}
                >
                  <span className="flex items-center justify-between gap-3">
                    <span className="text-sm font-bold text-navy-800">
                      {option.title}
                    </span>
                    <span className="rounded-md bg-white px-2 py-1 text-xs font-bold text-slate-600">
                      {selected ? "Seçildi" : "Seç"}
                    </span>
                  </span>
                  <span className="mt-1 block text-xs font-semibold uppercase text-sky-700">
                    {option.plan}
                  </span>
                  <span className="mt-2 block text-sm leading-6 text-slate-600">
                    {option.description}
                  </span>
                </button>
              );
            })}
          </div>
        </section>
      </div>
    </main>
  );
}
