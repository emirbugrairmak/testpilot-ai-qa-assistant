import { useState, type FormEvent } from "react";
import logoUrl from "../assets/testpilot-logo.png";
import { ErrorAlert } from "../components/ErrorAlert";
import { LoadingState } from "../components/LoadingState";
import { useAuth } from "../hooks/useAuth";
import { createFreeAccess, createPremiumAccess } from "../services/api";
import type { AccessKeyCreateResponse } from "../types/api";

type LoginPageProps = {
  onLoginSuccess: () => void;
};

type AccessFlow = "free" | "premium";

const developerDemoKeys = [
  { label: "Free demo", key: "tp_free_demo_key" },
  { label: "Premium demo", key: "tp_premium_demo_key" },
];

export function LoginPage({ onLoginSuccess }: LoginPageProps) {
  const { login, isLoggingIn, loginError, clearLoginError } = useAuth();
  const [apiKey, setApiKey] = useState("");
  const [accessFlow, setAccessFlow] = useState<AccessFlow>("free");
  const [freeOwnerName, setFreeOwnerName] = useState("");
  const [premiumOwnerName, setPremiumOwnerName] = useState("");
  const [createdAccess, setCreatedAccess] = useState<AccessKeyCreateResponse | null>(null);
  const [accessError, setAccessError] = useState<string | null>(null);
  const [isCreatingAccess, setIsCreatingAccess] = useState(false);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    clearLoginError();
    try {
      await login(apiKey);
      onLoginSuccess();
    } catch {
      // useAuth kullanıcıya lokalize edilmiş hatayı zaten gösteriyor.
    }
  }

  async function handleCreateFreeAccess() {
    clearLoginError();
    setAccessError(null);
    setIsCreatingAccess(true);
    try {
      const response = await createFreeAccess({
        owner_name: freeOwnerName.trim() || undefined,
      });
      setCreatedAccess(response);
      setApiKey(response.access_key);
    } catch (error) {
      setAccessError(
        error instanceof Error
          ? error.message
          : "Free erişim anahtarı oluşturulamadı.",
      );
    } finally {
      setIsCreatingAccess(false);
    }
  }

  async function handleCreatePremiumAccess(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    clearLoginError();
    setAccessError(null);
    const ownerName = premiumOwnerName.trim();
    if (!ownerName) {
      setAccessError("Premium access key için ad, ekip veya kurum adı girin.");
      return;
    }

    setIsCreatingAccess(true);
    try {
      const response = await createPremiumAccess({
        owner_name: ownerName,
        plan_summary: "Premium monthly simulation - 200 generations/month",
      });
      setCreatedAccess(response);
      setApiKey(response.access_key);
    } catch (error) {
      setAccessError(
        error instanceof Error
          ? error.message
          : "Premium erişim anahtarı oluşturulamadı.",
      );
    } finally {
      setIsCreatingAccess(false);
    }
  }

  async function handleContinueWithCreatedAccess() {
    if (!createdAccess) return;

    clearLoginError();
    try {
      await login(createdAccess.access_key);
      onLoginSuccess();
    } catch {
      // Hata useAuth üzerinden gösterilir.
    }
  }

  return (
    <main className="min-h-screen bg-slate-50">
      <div className="mx-auto grid min-h-screen max-w-6xl items-center gap-10 px-4 py-10 sm:px-6 lg:grid-cols-[1fr_460px] lg:px-8">
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
              QA çalışma alanınızı erişim anahtarıyla açın.
            </h1>
            <p className="mt-4 text-lg leading-8 text-slate-600">
              QA üretim alanınıza erişmek için erişim anahtarınızı girin veya
              yeni bir Free/Premium erişim oluşturun. Aynı anahtarla
              döndüğünüzde planınız, kullanımınız ve geçmiş kayıtlarınız
              korunur.
            </p>
          </div>
        </section>

        <section className="rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
          <div>
            <p className="text-sm font-bold uppercase text-sky-700">
              Çalışma alanı erişimi
            </p>
            <h2 className="mt-2 text-2xl font-bold text-navy-800">
              Access key ile devam edin
            </h2>
            <p className="mt-2 text-sm leading-6 text-slate-600">
              Mevcut anahtarınızı girin veya yeni bir plan anahtarı edinin.
              Email, parola veya ödeme hesabı oluşturulmaz.
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
                placeholder="tp_free_... veya tp_premium_..."
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
              {isLoggingIn ? "Doğrulanıyor" : "Çalışma alanına gir"}
            </button>

            {isLoggingIn && <LoadingState label="Erişim anahtarı kontrol ediliyor" />}
          </form>

          <div className="mt-6 border-t border-slate-200 pt-6">
            <div className="grid grid-cols-2 gap-2 rounded-lg bg-slate-100 p-1">
              <button
                type="button"
                onClick={() => {
                  setAccessFlow("free");
                  setAccessError(null);
                }}
                className={`rounded-md px-3 py-2 text-sm font-bold ${
                  accessFlow === "free"
                    ? "bg-white text-navy-800 shadow-sm"
                    : "text-slate-600 hover:text-navy-800"
                }`}
              >
                Free erişim al
              </button>
              <button
                type="button"
                onClick={() => {
                  setAccessFlow("premium");
                  setAccessError(null);
                }}
                className={`rounded-md px-3 py-2 text-sm font-bold ${
                  accessFlow === "premium"
                    ? "bg-white text-navy-800 shadow-sm"
                    : "text-slate-600 hover:text-navy-800"
                }`}
              >
                Premium al
              </button>
            </div>

            {accessFlow === "free" ? (
              <div className="mt-4 space-y-4 rounded-lg border border-slate-200 bg-slate-50 p-4">
                <div>
                  <p className="text-sm font-bold text-navy-800">
                    Free çalışma alanı
                  </p>
                  <p className="mt-1 text-sm leading-6 text-slate-600">
                    30 üretim/ay, Markdown/JSON export ve son 15 History kaydı.
                  </p>
                </div>
                <div className="space-y-2">
                  <label
                    htmlFor="free_owner"
                    className="text-sm font-semibold text-slate-700"
                  >
                    Anahtar etiketi
                  </label>
                  <input
                    id="free_owner"
                    className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-sm text-slate-800 outline-none focus:border-sky-400 focus:ring-2 focus:ring-sky-100"
                    value={freeOwnerName}
                    onChange={(event) => setFreeOwnerName(event.target.value)}
                    placeholder="Örn. Emir QA denemesi"
                  />
                </div>
                <button
                  type="button"
                  onClick={handleCreateFreeAccess}
                  disabled={isCreatingAccess}
                  className="inline-flex w-full justify-center rounded-lg border border-sky-300 bg-white px-4 py-3 text-sm font-bold text-sky-700 hover:bg-sky-50 disabled:cursor-not-allowed disabled:opacity-60"
                >
                  {isCreatingAccess ? "Oluşturuluyor" : "Free access key oluştur"}
                </button>
              </div>
            ) : (
              <form
                onSubmit={handleCreatePremiumAccess}
                className="mt-4 space-y-4 rounded-lg border border-slate-200 bg-slate-50 p-4"
              >
                <div>
                  <p className="text-sm font-bold text-navy-800">
                    Premium satın alma simülasyonu
                  </p>
                  <p className="mt-1 text-sm leading-6 text-slate-600">
                    200 üretim/ay, CSV/Jira export, batch generate, custom
                    templates ve sınırsız History.
                  </p>
                </div>
                <div className="rounded-lg border border-accent-100 bg-white px-3 py-3">
                  <p className="text-xs font-bold uppercase text-accent-600">
                    Plan özeti
                  </p>
                  <p className="mt-1 text-sm font-semibold text-slate-800">
                    Premium Monthly - satın alma simülasyonu, gerçek ödeme yok.
                  </p>
                </div>
                <div className="space-y-2">
                  <label
                    htmlFor="premium_owner"
                    className="text-sm font-semibold text-slate-700"
                  >
                    Ad, ekip veya kurum adı
                  </label>
                  <input
                    id="premium_owner"
                    className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-sm text-slate-800 outline-none focus:border-sky-400 focus:ring-2 focus:ring-sky-100"
                    value={premiumOwnerName}
                    onChange={(event) => setPremiumOwnerName(event.target.value)}
                    placeholder="Örn. Atlas QA Team"
                    required
                    minLength={2}
                  />
                </div>
                <button
                  type="submit"
                  disabled={isCreatingAccess}
                  className="inline-flex w-full justify-center rounded-lg border border-accent-300 bg-accent-500 px-4 py-3 text-sm font-bold text-white shadow-sm hover:bg-accent-600 disabled:cursor-not-allowed disabled:opacity-60"
                >
                  {isCreatingAccess ? "Onaylanıyor" : "Satın almayı onayla"}
                </button>
              </form>
            )}

            {accessError && (
              <div className="mt-4">
                <ErrorAlert message={accessError} />
              </div>
            )}

            {createdAccess && (
              <div className="mt-4 rounded-lg border border-sky-200 bg-sky-50 p-4">
                <p className="text-sm font-bold text-navy-800">
                  {createdAccess.plan === "premium" ? "Premium" : "Free"} access key hazır
                </p>
                <input
                  readOnly
                  value={createdAccess.access_key}
                  className="mt-3 w-full rounded-lg border border-sky-200 bg-white px-3 py-2.5 text-xs font-semibold text-slate-800 outline-none"
                />
                <p className="mt-2 text-xs leading-5 text-slate-600">
                  Bu anahtar kalıcıdır. Aynı anahtarla tekrar girdiğinizde bu
                  çalışma alanının verileri geri gelir.
                </p>
                <button
                  type="button"
                  onClick={handleContinueWithCreatedAccess}
                  disabled={isLoggingIn}
                  className="mt-3 inline-flex w-full justify-center rounded-lg bg-navy-800 px-4 py-3 text-sm font-bold text-white hover:bg-navy-700 disabled:cursor-not-allowed disabled:opacity-60"
                >
                  Bu key ile çalışma alanına gir
                </button>
              </div>
            )}
          </div>

          <div className="mt-6 border-t border-slate-200 pt-4">
            <p className="text-xs font-bold uppercase text-slate-500">
              Geliştirici demo keyleri
            </p>
            <div className="mt-2 flex flex-wrap gap-2">
              {developerDemoKeys.map((item) => (
                <button
                  key={item.key}
                  type="button"
                  onClick={() => {
                    clearLoginError();
                    setCreatedAccess(null);
                    setApiKey(item.key);
                  }}
                  className="rounded-md border border-slate-200 bg-white px-3 py-2 text-xs font-bold text-slate-600 hover:border-sky-200 hover:text-sky-700"
                >
                  {item.label}
                </button>
              ))}
            </div>
          </div>
        </section>
      </div>
    </main>
  );
}
