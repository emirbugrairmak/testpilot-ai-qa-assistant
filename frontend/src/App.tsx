import { useEffect, useMemo, useState } from "react";
import { Layout } from "./components/Layout";
import { LoadingState } from "./components/LoadingState";
import { useAuth } from "./hooks/useAuth";
import { BatchGeneratePage } from "./pages/BatchGeneratePage";
import { DashboardPage } from "./pages/DashboardPage";
import { GeneratePage } from "./pages/GeneratePage";
import { HistoryPage } from "./pages/HistoryPage";
import { LoginPage } from "./pages/LoginPage";
import { ResultPage } from "./pages/ResultPage";
import { SettingsPage } from "./pages/SettingsPage";
import { TemplatesPage } from "./pages/TemplatesPage";
import type { GenerationMode } from "./types/api";

type Route =
  | { page: "login" }
  | { page: "dashboard" }
  | { page: "generate"; mode: GenerationMode }
  | { page: "templates" }
  | { page: "batch" }
  | { page: "history" }
  | { page: "result"; generationId: number }
  | { page: "settings" };

function App() {
  const { isAuthenticated, isRestoring } = useAuth();
  const [route, setRoute] = useState<Route>(() => parseRoute());

  useEffect(() => {
    function handleHashChange() {
      setRoute(parseRoute());
    }

    window.addEventListener("hashchange", handleHashChange);
    return () => window.removeEventListener("hashchange", handleHashChange);
  }, []);

  useEffect(() => {
    if (isRestoring) {
      return;
    }

    if (!isAuthenticated && route.page !== "login") {
      navigate("login");
      return;
    }

    if (isAuthenticated && route.page === "login") {
      navigate("dashboard");
    }
  }, [isAuthenticated, isRestoring, route.page]);

  const activeGenerateMode = useMemo(
    () => (route.page === "generate" ? route.mode : "mod_a"),
    [route],
  );

  if (isRestoring) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-slate-50">
        <LoadingState label="Restoring session" />
      </div>
    );
  }

  if (!isAuthenticated || route.page === "login") {
    return <LoginPage onLoginSuccess={() => navigate("dashboard")} />;
  }

  return (
    <Layout
      page={route.page}
      onNavigate={(page, mode = "mod_a") => {
        if (page === "generate") {
          navigate("generate", mode);
          return;
        }

        if (page === "history") {
          navigate("history");
          return;
        }

        if (page === "templates") {
          navigate("templates");
          return;
        }

        if (page === "batch") {
          navigate("batch");
          return;
        }

        if (page === "settings") {
          navigate("settings");
          return;
        }

        navigate("dashboard");
      }}
    >
      {route.page === "dashboard" ? (
        <DashboardPage
          onNewGeneration={(mode) => navigate("generate", mode)}
          onOpenResult={(generationId) => navigate("result", generationId)}
        />
      ) : null}

      {route.page === "generate" ? (
        <GeneratePage
          key={activeGenerateMode}
          initialMode={activeGenerateMode}
          onModeChange={(mode) => navigate("generate", mode)}
          onResultReady={(generationId) => navigate("result", generationId)}
        />
      ) : null}

      {route.page === "history" ? (
        <HistoryPage onOpenResult={(generationId) => navigate("result", generationId)} />
      ) : null}

      {route.page === "templates" ? <TemplatesPage /> : null}

      {route.page === "batch" ? (
        <BatchGeneratePage
          onOpenResult={(generationId) => navigate("result", generationId)}
        />
      ) : null}

      {route.page === "result" ? (
        <ResultPage
          generationId={route.generationId}
          onBackToHistory={() => navigate("history")}
        />
      ) : null}

      {route.page === "settings" ? <SettingsPage /> : null}
    </Layout>
  );
}

function navigate(page: "login"): void;
function navigate(page: "dashboard"): void;
function navigate(page: "history"): void;
function navigate(page: "templates"): void;
function navigate(page: "batch"): void;
function navigate(page: "settings"): void;
function navigate(page: "generate", mode?: GenerationMode): void;
function navigate(page: "result", generationId: number): void;
function navigate(
  page:
    | "login"
    | "dashboard"
    | "generate"
    | "templates"
    | "batch"
    | "history"
    | "result"
    | "settings",
  value?: GenerationMode | number,
) {
  if (page === "generate") {
    const mode = (typeof value === "string" ? value : "mod_a") as GenerationMode;
    window.location.hash = `/generate?mode=${mode}`;
    return;
  }

  if (page === "result") {
    window.location.hash = `/result/${value}`;
    return;
  }

  window.location.hash = `/${page}`;
}

function parseRoute(): Route {
  const hash = window.location.hash.replace(/^#/, "") || "/dashboard";
  const [path, search = ""] = hash.split("?");

  if (path === "/login") {
    return { page: "login" };
  }

  if (path === "/generate") {
    const params = new URLSearchParams(search);
    const mode = normalizeMode(params.get("mode"));
    return { page: "generate", mode };
  }

  if (path === "/history") {
    return { page: "history" };
  }

  if (path === "/templates") {
    return { page: "templates" };
  }

  if (path === "/batch") {
    return { page: "batch" };
  }

  if (path === "/settings") {
    return { page: "settings" };
  }

  if (path.startsWith("/result/")) {
    const generationId = Number(path.replace("/result/", ""));
    if (Number.isFinite(generationId) && generationId > 0) {
      return { page: "result", generationId };
    }
  }

  return { page: "dashboard" };
}

function normalizeMode(value: string | null): GenerationMode {
  if (value === "mod_b" || value === "bug_report") {
    return value;
  }

  return "mod_a";
}

export default App;
