import type {
  AuthValidateResponse,
  BatchGenerateRequest,
  BatchGenerateResponse,
  DeleteHistoryResponse,
  ExportFormat,
  GenerateRequest,
  GenerateResponse,
  HistoryDetailResponse,
  HistoryListResponse,
  HistoryQueryParams,
  SystemStatusResponse,
  Template,
  TemplateListResponse,
  TemplatePayload,
  UsageResponse,
} from "../types/api";

const API_BASE_URL =
  import.meta.env.VITE_API_URL?.replace(/\/$/, "") || "http://localhost:8000";

const API_KEY_STORAGE_KEY = "testpilot_api_key";

type RequestOptions = {
  apiKey?: string | null;
  method?: "GET" | "POST" | "PUT" | "DELETE";
  body?: unknown;
  timeoutMs?: number;
};

export function getStoredApiKey() {
  return localStorage.getItem(API_KEY_STORAGE_KEY);
}

export function storeApiKey(apiKey: string) {
  localStorage.setItem(API_KEY_STORAGE_KEY, apiKey);
}

export function clearStoredApiKey() {
  localStorage.removeItem(API_KEY_STORAGE_KEY);
}

function buildAuthHeaders(apiKey = getStoredApiKey(), hasBody = false) {
  const headers = new Headers();

  if (apiKey) {
    headers.set("Authorization", `Bearer ${apiKey}`);
  }

  if (hasBody) {
    headers.set("Content-Type", "application/json");
  }

  return headers;
}

export async function apiRequest<T>(
  path: string,
  { apiKey = getStoredApiKey(), method = "GET", body, timeoutMs }: RequestOptions = {},
): Promise<T> {
  const controller = timeoutMs ? new AbortController() : undefined;
  const timeoutId = timeoutMs
    ? window.setTimeout(() => controller?.abort(), timeoutMs)
    : undefined;

  let response: Response;
  try {
    response = await fetch(`${API_BASE_URL}${path}`, {
      method,
      headers: buildAuthHeaders(apiKey, body !== undefined),
      body: body === undefined ? undefined : JSON.stringify(body),
      signal: controller?.signal,
    });
  } catch (error) {
    if (error instanceof DOMException && error.name === "AbortError") {
      throw new Error("Üretim zaman aşımına uğradı. Lütfen bağlantıyı kontrol edip tekrar deneyin.");
    }

    if (error instanceof TypeError) {
      throw new Error("Backend bağlantısı kurulamadı. API servisinin çalıştığından emin olun.");
    }

    throw error;
  } finally {
    if (timeoutId) {
      window.clearTimeout(timeoutId);
    }
  }

  if (!response.ok) {
    let message = "Bir sorun oluştu. Lütfen tekrar deneyin.";

    try {
      const errorBody = (await response.json()) as { detail?: string };
      if (errorBody.detail) {
        message = localizeApiError(errorBody.detail);
      }
    } catch {
      message = response.statusText || message;
    }

    throw new Error(message);
  }

  if (response.status === 204) {
    return undefined as T;
  }

  return (await response.json()) as T;
}

export function validateApiKey(apiKey: string) {
  return apiRequest<AuthValidateResponse>("/api/v1/auth/validate", {
    apiKey,
    method: "POST",
  });
}

export function fetchUsage() {
  return apiRequest<UsageResponse>("/api/v1/usage");
}

export function fetchSystemStatus() {
  return apiRequest<SystemStatusResponse>("/health", {
    apiKey: null,
  });
}

export function fetchHistory(params: HistoryQueryParams = {}) {
  const searchParams = new URLSearchParams();

  if (params.mode && params.mode !== "all") {
    searchParams.set("mode", params.mode);
  }

  if (params.q?.trim()) {
    searchParams.set("q", params.q.trim());
  }

  const query = searchParams.toString();
  const path = query ? `/api/v1/history?${query}` : "/api/v1/history";

  return apiRequest<HistoryListResponse>(path);
}

export function fetchHistoryDetail(generationId: number) {
  return apiRequest<HistoryDetailResponse>(`/api/v1/history/${generationId}`);
}

export function deleteHistoryItem(generationId: number) {
  return apiRequest<DeleteHistoryResponse>(`/api/v1/history/${generationId}`, {
    method: "DELETE",
  });
}

export function generateArtifact(payload: GenerateRequest) {
  return apiRequest<GenerateResponse>("/api/v1/generate", {
    method: "POST",
    body: payload,
    timeoutMs: 75000,
  });
}

export function fetchTemplates() {
  return apiRequest<TemplateListResponse>("/api/v1/templates");
}

export function createTemplate(payload: TemplatePayload) {
  return apiRequest<Template>("/api/v1/templates", {
    method: "POST",
    body: payload,
  });
}

export function updateTemplate({
  id,
  payload,
}: {
  id: number;
  payload: TemplatePayload;
}) {
  return apiRequest<Template>(`/api/v1/templates/${id}`, {
    method: "PUT",
    body: payload,
  });
}

export function deleteTemplate(id: number) {
  return apiRequest<void>(`/api/v1/templates/${id}`, {
    method: "DELETE",
  });
}

export function batchGenerate(payload: BatchGenerateRequest) {
  return apiRequest<BatchGenerateResponse>("/api/v1/generate/batch", {
    method: "POST",
    body: payload,
  });
}

export async function downloadExportFile(
  generationId: number,
  format: ExportFormat,
  apiKey = getStoredApiKey(),
) {
  const response = await fetch(
    `${API_BASE_URL}/api/v1/export/${generationId}/${format}`,
    {
      method: "GET",
      headers: buildAuthHeaders(apiKey),
    },
  );

  if (!response.ok) {
    let message = "Export başarısız oldu.";

    try {
      const errorBody = (await response.json()) as { detail?: string };
      if (errorBody.detail) {
        message = localizeApiError(errorBody.detail);
      }
    } catch {
      message = response.statusText || message;
    }

    throw new Error(message);
  }

  const blob = await response.blob();
  const disposition = response.headers.get("Content-Disposition") || "";
  const filenameMatch = disposition.match(/filename="?(.*?)"?$/i);
  const filename = filenameMatch?.[1] || `testpilot-export-${generationId}.${format}`;

  return { blob, filename };
}

function localizeApiError(message: string) {
  if (message.startsWith("Gemini generation failed:")) {
    return "Gemini yanıtı alınamadı. Lütfen bağlantıyı kontrol edip tekrar deneyin.";
  }

  if (message.includes("GEMINI_API_KEY is empty")) {
    return "Gemini API key bulunamadı. Backend ortam ayarlarını kontrol edin.";
  }

  const knownMessages: Record<string, string> = {
    "Invalid or inactive API key": "Geçersiz veya pasif erişim anahtarı.",
    "Generation not found": "Üretim bulunamadı.",
    "This export format is available for premium plans only":
      "Bu Export formatı yalnızca Premium planda kullanılabilir.",
    "Batch generation is available for Premium plan users only.":
      "Batch Generate yalnızca Premium plan kullanıcıları için kullanılabilir.",
    "Batch mode is not supported for bug_report. Use single /generate instead.":
      "Bug Report için Batch Generate desteklenmez. Tekli üretim ekranını kullanın.",
  };

  return knownMessages[message] ?? message;
}
