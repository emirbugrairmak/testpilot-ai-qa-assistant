import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import {
  clearStoredApiKey,
  getStoredApiKey,
  storeApiKey,
  validateApiKey,
} from "../services/api";
import type { AuthValidateResponse } from "../types/api";

type AuthContextValue = {
  apiKey: string | null;
  user: AuthValidateResponse | null;
  isAuthenticated: boolean;
  isRestoring: boolean;
  isLoggingIn: boolean;
  loginError: string | null;
  login: (apiKey: string) => Promise<void>;
  logout: () => void;
  clearLoginError: () => void;
};

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const queryClient = useQueryClient();
  const [apiKey, setApiKey] = useState<string | null>(() => getStoredApiKey());
  const [user, setUser] = useState<AuthValidateResponse | null>(null);
  const [isRestoring, setIsRestoring] = useState(Boolean(getStoredApiKey()));
  const [loginError, setLoginError] = useState<string | null>(null);

  const validateMutation = useMutation({
    mutationFn: validateApiKey,
    onSuccess: (data, key) => {
      storeApiKey(key);
      setApiKey(key);
      setUser(data);
      setLoginError(null);
      queryClient.invalidateQueries();
    },
    onError: (error) => {
      setLoginError(error instanceof Error ? error.message : "Invalid API key");
    },
  });

  useEffect(() => {
    const storedKey = getStoredApiKey();

    if (!storedKey) {
      setIsRestoring(false);
      return;
    }

    validateApiKey(storedKey)
      .then((data) => {
        setApiKey(storedKey);
        setUser(data);
        setLoginError(null);
      })
      .catch(() => {
        clearStoredApiKey();
        setApiKey(null);
        setUser(null);
      })
      .finally(() => setIsRestoring(false));
  }, []);

  const login = useCallback(
    async (key: string) => {
      await validateMutation.mutateAsync(key.trim());
    },
    [validateMutation],
  );

  const logout = useCallback(() => {
    clearStoredApiKey();
    setApiKey(null);
    setUser(null);
    setLoginError(null);
    queryClient.clear();
  }, [queryClient]);

  const value = useMemo<AuthContextValue>(
    () => ({
      apiKey,
      user,
      isAuthenticated: Boolean(apiKey && user),
      isRestoring,
      isLoggingIn: validateMutation.isPending,
      loginError,
      login,
      logout,
      clearLoginError: () => setLoginError(null),
    }),
    [
      apiKey,
      isRestoring,
      login,
      loginError,
      logout,
      user,
      validateMutation.isPending,
    ],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);

  if (!context) {
    throw new Error("useAuth must be used within AuthProvider");
  }

  return context;
}
