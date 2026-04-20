import type {
  AuthValidateResponse,
  GenerateRequest,
  GenerateResponse,
  HistoryListResponse,
  UsageResponse,
} from "../types/api";

const API_BASE_URL =
  import.meta.env.VITE_API_URL?.replace(/\/$/, "") || "http://localhost:8000";

const API_KEY_STORAGE_KEY = "testpilot_api_key";

type RequestOptions = {
  apiKey?: string | null;
  method?: "GET" | "POST" | "DELETE";
  body?: unknown;
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

export async function apiRequest<T>(
  path: string,
  { apiKey = getStoredApiKey(), method = "GET", body }: RequestOptions = {},
): Promise<T> {
  const headers = new Headers();

  if (apiKey) {
    headers.set("Authorization", `Bearer ${apiKey}`);
  }

  if (body !== undefined) {
    headers.set("Content-Type", "application/json");
  }

  const response = await fetch(`${API_BASE_URL}${path}`, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });

  if (!response.ok) {
    let message = "Something went wrong. Please try again.";

    try {
      const errorBody = (await response.json()) as { detail?: string };
      if (errorBody.detail) {
        message = errorBody.detail;
      }
    } catch {
      message = response.statusText || message;
    }

    throw new Error(message);
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

export function fetchHistory() {
  return apiRequest<HistoryListResponse>("/api/v1/history");
}

export function generateArtifact(payload: GenerateRequest) {
  return apiRequest<GenerateResponse>("/api/v1/generate", {
    method: "POST",
    body: payload,
  });
}
