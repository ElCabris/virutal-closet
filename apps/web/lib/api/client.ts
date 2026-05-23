const BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000/v1";

// Singleton promise to prevent parallel refresh races
let refreshPromise: Promise<string | null> | null = null;

function getToken(): string | null {
  if (typeof window === "undefined") return null;
  try {
    const stored = localStorage.getItem("crayoli-auth");
    if (!stored) return null;
    return JSON.parse(stored)?.state?.token ?? null;
  } catch {
    return null;
  }
}

function setToken(token: string): void {
  try {
    const stored = localStorage.getItem("crayoli-auth");
    if (!stored) return;
    const parsed = JSON.parse(stored);
    parsed.state.token = token;
    localStorage.setItem("crayoli-auth", JSON.stringify(parsed));
  } catch {}
}

async function silentRefresh(): Promise<string | null> {
  if (refreshPromise) return refreshPromise;

  refreshPromise = (async () => {
    try {
      const res = await fetch(`${BASE_URL}/auth/refresh`, {
        method: "POST",
        credentials: "include",
      });
      if (!res.ok) return null;
      const data = await res.json();
      const newToken: string = data.access_token;
      setToken(newToken);
      return newToken;
    } catch {
      return null;
    } finally {
      refreshPromise = null;
    }
  })();

  return refreshPromise;
}

async function request<T>(
  method: string,
  path: string,
  body?: unknown,
  opts: { isRetry?: boolean; isFormData?: boolean } = {}
): Promise<{ data: T; status: number }> {
  const token = getToken();
  const headers: Record<string, string> = {};
  if (token) headers["Authorization"] = `Bearer ${token}`;
  if (!opts.isFormData) headers["Content-Type"] = "application/json";

  const res = await fetch(`${BASE_URL}${path}`, {
    method,
    headers,
    credentials: "include",
    body: body instanceof FormData ? body : body ? JSON.stringify(body) : undefined,
  });

  // Attempt silent refresh on 401 (once per request)
  if (res.status === 401 && !opts.isRetry) {
    const newToken = await silentRefresh();
    if (newToken) {
      return request<T>(method, path, body, { ...opts, isRetry: true });
    }
    // Refresh failed — clear auth and let caller handle
    try {
      const stored = localStorage.getItem("crayoli-auth");
      if (stored) {
        const parsed = JSON.parse(stored);
        parsed.state.token = null;
        parsed.state.user = null;
        localStorage.setItem("crayoli-auth", JSON.stringify(parsed));
      }
    } catch {}
    window.dispatchEvent(new CustomEvent("auth:expired"));
  }

  const data = await res.json().catch(() => null);

  if (!res.ok) {
    const error = new Error(data?.detail || "Request failed") as Error & {
      response: { data: typeof data; status: number };
    };
    error.response = { data, status: res.status };
    throw error;
  }

  return { data: data as T, status: res.status };
}

async function upload<T>(path: string, formData: FormData): Promise<{ data: T; status: number }> {
  return request<T>("POST", path, formData, { isFormData: true });
}

export const api = {
  get:    <T>(path: string) => request<T>("GET", path),
  post:   <T>(path: string, body?: unknown) => request<T>("POST", path, body),
  patch:  <T>(path: string, body?: unknown) => request<T>("PATCH", path, body),
  put:    <T>(path: string, body?: unknown) => request<T>("PUT", path, body),
  delete: <T>(path: string) => request<T>("DELETE", path),
  upload: <T>(path: string, formData: FormData) => upload<T>(path, formData),
};
