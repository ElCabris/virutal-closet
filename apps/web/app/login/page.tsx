"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useAuthStore } from "@/lib/stores/authStore";
import { api } from "@/lib/api/client";

const schema = z.object({
  email: z.string().email("Email inválido"),
  password: z.string().min(6, "Mínimo 6 caracteres"),
});

type FormData = z.infer<typeof schema>;

export default function LoginPage() {
  const router = useRouter();
  const setAuth = useAuthStore((s) => s.setAuth);
  const [isLogin, setIsLogin] = useState(true);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormData>({ resolver: zodResolver(schema) });

  const onSubmit = async (data: FormData) => {
    setLoading(true);
    setError("");
    try {
      const endpoint = isLogin ? "/auth/login" : "/auth/signup";
      const body = isLogin
        ? data
        : { ...data, display_name: data.email.split("@")[0] };

      const res = await api.post<{ user: Parameters<typeof setAuth>[0]; tokens: { access_token: string } }>(endpoint, body);
      setAuth(res.data.user, res.data.tokens.access_token);
      router.push("/home");
    } catch (e: unknown) {
      const err = e as { response?: { data?: { detail?: string } } };
      setError(err.response?.data?.detail || "Algo salió mal. Intenta de nuevo.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-ivory flex flex-col items-center justify-center px-5">
      {/* Wordmark */}
      <div className="mb-12 text-center">
        <h1 className="font-serif text-2xl tracking-[0.25em] text-warm-black uppercase font-light">
          Crayoli
        </h1>
        <p className="text-stone text-sm mt-1 font-sans">Your closet, curated.</p>
      </div>

      <div className="w-full max-w-sm">
        {/* Headline */}
        <h2 className="font-serif text-3xl text-warm-black mb-8 leading-tight">
          {isLogin ? "Welcome back." : "Create your closet."}
        </h2>

        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          <div>
            <input
              {...register("email")}
              type="email"
              placeholder="Email address"
              autoComplete="email"
              className="w-full h-[52px] px-4 rounded-md border border-[rgba(28,26,24,0.10)] bg-white text-warm-black placeholder:text-stone text-[15px] outline-none focus:border-gold focus:ring-0 transition-colors duration-200"
            />
            {errors.email && (
              <p className="text-error-blush text-xs mt-1">{errors.email.message}</p>
            )}
          </div>

          <div>
            <input
              {...register("password")}
              type="password"
              placeholder="Password"
              autoComplete={isLogin ? "current-password" : "new-password"}
              className="w-full h-[52px] px-4 rounded-md border border-[rgba(28,26,24,0.10)] bg-white text-warm-black placeholder:text-stone text-[15px] outline-none focus:border-gold transition-colors duration-200"
            />
            {errors.password && (
              <p className="text-error-blush text-xs mt-1">{errors.password.message}</p>
            )}
          </div>

          {error && (
            <p className="text-error-blush text-sm bg-[rgba(196,122,122,0.08)] rounded-md px-3 py-2">
              {error}
            </p>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full h-[52px] bg-warm-black text-ivory rounded-md font-sans text-[15px] font-medium transition-all duration-200 hover:bg-charcoal disabled:opacity-50 disabled:cursor-not-allowed mt-2"
          >
            {loading ? "..." : isLogin ? "Continue" : "Create account"}
          </button>
        </form>

        {/* Divider */}
        <div className="flex items-center gap-3 my-6">
          <div className="flex-1 h-px bg-[rgba(28,26,24,0.08)]" />
          <span className="text-stone text-xs">or</span>
          <div className="flex-1 h-px bg-[rgba(28,26,24,0.08)]" />
        </div>

        {/* Hint: founder access */}
        <div className="bg-[rgba(212,175,130,0.08)] rounded-md px-4 py-3 mb-6 border border-[rgba(212,175,130,0.20)]">
          <p className="text-charcoal text-xs leading-relaxed">
            <span className="text-gold-dark font-medium">Ana María</span> — inicia sesión con{" "}
            <span className="font-medium">ana@crayoli.app</span> y password{" "}
            <span className="font-medium">Crayoli2026!</span> para acceso founder completo.
          </p>
        </div>

        {/* Toggle */}
        <p className="text-center text-stone text-sm">
          {isLogin ? "No tienes cuenta?" : "Ya tienes cuenta?"}{" "}
          <button
            onClick={() => { setIsLogin(!isLogin); setError(""); }}
            className="text-warm-black underline underline-offset-2"
          >
            {isLogin ? "Sign up." : "Log in."}
          </button>
        </p>
      </div>
    </div>
  );
}
