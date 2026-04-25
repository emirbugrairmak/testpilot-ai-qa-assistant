import type { ReactNode } from "react";
import logoUrl from "../assets/testpilot-logo.png";
import { useAuth } from "../hooks/useAuth";
import type { GenerationMode } from "../types/api";
import { PlanBadge } from "./PlanBadge";

type Page =
  | "dashboard"
  | "generate"
  | "templates"
  | "batch"
  | "history"
  | "result"
  | "settings";
type NavigationPage =
  | "dashboard"
  | "generate"
  | "templates"
  | "batch"
  | "history"
  | "settings";

type LayoutProps = {
  page: Page;
  children: ReactNode;
  onNavigate: (page: NavigationPage, mode?: GenerationMode) => void;
};

export function Layout({ page, children, onNavigate }: LayoutProps) {
  const { user, logout } = useAuth();

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900">
      <header className="border-b border-slate-200 bg-white">
        <div className="mx-auto flex max-w-7xl flex-col gap-4 px-4 py-4 sm:px-6 lg:flex-row lg:items-center lg:justify-between lg:px-8">
          <div className="flex items-center gap-3">
            <img
              src={logoUrl}
              alt="TestPilot logo"
              className="h-11 w-11 rounded-lg object-cover"
            />
            <div>
              <p className="text-lg font-extrabold text-navy-800">TestPilot</p>
              <p className="text-sm font-medium text-slate-500">
                From idea to test cases, in minutes.
              </p>
            </div>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <nav className="flex flex-wrap rounded-lg border border-slate-200 bg-slate-50 p-1">
              <button
                type="button"
                onClick={() => onNavigate("dashboard")}
                className={navClass(page === "dashboard")}
              >
                Dashboard
              </button>
              <button
                type="button"
                onClick={() => onNavigate("generate")}
                className={navClass(page === "generate")}
              >
                Generate
              </button>
              <button
                type="button"
                onClick={() => onNavigate("templates")}
                className={navClass(page === "templates")}
              >
                Templates
              </button>
              <button
                type="button"
                onClick={() => onNavigate("batch")}
                className={navClass(page === "batch")}
              >
                Batch Generate
              </button>
              <button
                type="button"
                onClick={() => onNavigate("history")}
                className={navClass(page === "history" || page === "result")}
              >
                History
              </button>
              <button
                type="button"
                onClick={() => onNavigate("settings")}
                className={navClass(page === "settings")}
              >
                Settings
              </button>
            </nav>

            {user && <PlanBadge plan={user.plan} />}

            <button
              type="button"
              onClick={logout}
              className="rounded-lg border border-slate-300 px-3 py-2 text-sm font-bold text-slate-700 hover:border-accent-300 hover:text-accent-700"
            >
              Logout
            </button>
          </div>
        </div>
      </header>

      <main className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
        {children}
      </main>
    </div>
  );
}

function navClass(isActive: boolean) {
  return isActive
    ? "rounded-md bg-navy-800 px-3 py-2 text-sm font-bold text-white"
    : "rounded-md px-3 py-2 text-sm font-bold text-slate-600 hover:text-navy-800";
}
