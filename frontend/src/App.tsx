import { useEffect, useMemo, useState } from "react";
import { Layout } from "./components/Layout";
import { LoadingState } from "./components/LoadingState";
import { useAuth } from "./hooks/useAuth";
import { DashboardPage } from "./pages/DashboardPage";
import { GeneratePage } from "./pages/GeneratePage";
import { LoginPage } from "./pages/LoginPage";
import type { GenerationMode } from "./types/api";

type Route =
  | { page: "login" }
  | { page: "dashboard" }
  | { page: "generate"; mode: GenerationMode };

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
      page={route.page === "generate" ? "generate" : "dashboard"}
      onNavigate={(page, mode = "mod_a") => {
        if (page === "generate") {
          navigate("generate", mode);
          return;
        }

        navigate("dashboard");
      }}
    >
      {route.page === "generate" ? (
        <GeneratePage key={activeGenerateMode} initialMode={activeGenerateMode} />
      ) : (
        <DashboardPage
          onNewGeneration={(mode) => navigate("generate", mode)}
        />
      )}
    </Layout>
  );
}

function navigate(page: "login"): void;
function navigate(page: "dashboard"): void;
function navigate(page: "generate", mode?: GenerationMode): void;
function navigate(page: "login" | "dashboard" | "generate", mode = "mod_a") {
  if (page === "generate") {
    window.location.hash = `/generate?mode=${mode}`;
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

  return { page: "dashboard" };
}

function normalizeMode(value: string | null): GenerationMode {
  if (value === "mod_b" || value === "bug_report") {
    return value;
  }

  return "mod_a";
}

export default App;
