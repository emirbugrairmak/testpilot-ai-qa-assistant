import { ErrorAlert } from "../components/ErrorAlert";
import { LoadingState } from "../components/LoadingState";
import { PlanBadge } from "../components/PlanBadge";
import { UsageCard } from "../components/UsageCard";
import { useAuth } from "../hooks/useAuth";
import { useUsage } from "../hooks/useUsage";

export function SettingsPage() {
  const { apiKey, isAuthenticated, logout, user } = useAuth();
  const usageQuery = useUsage(isAuthenticated);

  return (
    <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_360px]">
      <section className="space-y-6 rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
        <div>
          <p className="text-sm font-bold uppercase text-sky-700">Ayarlar</p>
          <h1 className="mt-2 text-3xl font-extrabold text-navy-800">
            Hesap ve kullanım
          </h1>
          <p className="mt-2 text-sm leading-6 text-slate-600">
            Mevcut planınızı, erişim anahtarı durumunu ve kullanım özetinizi inceleyin.
          </p>
        </div>

        <div className="grid gap-4">
          <div className="rounded-lg border border-slate-200 bg-slate-50 p-4">
            <p className="text-sm font-semibold text-slate-500">Mevcut plan</p>
            <div className="mt-3">
              {user ? <PlanBadge plan={user.plan} /> : null}
            </div>
          </div>

          <div className="rounded-lg border border-slate-200 bg-slate-50 p-4">
            <p className="text-sm font-semibold text-slate-500">Hesap / Çalışma alanı</p>
            <p className="mt-3 text-sm font-bold text-navy-800">
              {user?.owner_name?.trim() || "Access key oturumu"}
            </p>
          </div>

          <div className="rounded-lg border border-slate-200 bg-slate-50 p-4">
            <p className="text-sm font-semibold text-slate-500">Kayıtlı erişim anahtarı</p>
            <p className="mt-3 break-all font-mono text-sm font-semibold text-navy-800">
              {apiKey || "Kayıtlı erişim anahtarı yok"}
            </p>
          </div>

          <div className="rounded-lg border border-slate-200 bg-slate-50 p-4">
            <p className="text-sm font-semibold text-slate-500">Plan özeti</p>
            <p className="mt-3 text-sm leading-6 text-slate-700">
              Free plan JSON ve Markdown Export destekler. Premium; CSV/Jira Export, temiz PDF, Templates, Batch Generate ve daha geniş History kullanımı ekler.
            </p>
          </div>
        </div>

        <button
          type="button"
          onClick={logout}
          className="rounded-lg bg-accent-500 px-4 py-3 text-sm font-bold text-white hover:bg-accent-600"
        >
          Çıkış yap
        </button>
      </section>

      <aside className="space-y-4">
        {usageQuery.isLoading ? <LoadingState label="Kullanım bilgisi yükleniyor" /> : null}
        {usageQuery.isError ? (
          <ErrorAlert
            message={
              usageQuery.error instanceof Error
                ? usageQuery.error.message
                : "Kullanım bilgisi yüklenemedi."
            }
          />
        ) : null}
        {usageQuery.data ? <UsageCard usage={usageQuery.data} /> : null}
      </aside>
    </div>
  );
}
