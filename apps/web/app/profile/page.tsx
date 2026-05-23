"use client";

import { useEffect, useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { LogOut, User, Palette, Globe, Loader2 } from "lucide-react";
import { useAuthStore } from "@/lib/stores/authStore";
import { api } from "@/lib/api/client";
import { Sidebar } from "@/components/layout/Sidebar";
import { useToast } from "@/lib/hooks/useToast";
import type { AuthUser } from "@/lib/stores/authStore";
import type { StyleProfile } from "@/lib/types";
import { cn } from "@/lib/utils/cn";

const profileSchema = z.object({ display_name: z.string().min(1, "Requerido") });
type ProfileForm = z.infer<typeof profileSchema>;

const STYLE_VIBES = ["minimal", "classic", "romantic", "streetwear", "sporty", "boho", "eclectic", "preppy"];
const COLOR_PREFS = ["neutrals", "earth", "bold", "monochrome", "pastels", "jewel"];
const CLIMATES = ["tropical", "temperate", "cold", "variable"];

export default function ProfilePage() {
  const { isAuthenticated, user, updateUser, logout } = useAuthStore();
  const router = useRouter();
  const toast = useToast();
  const queryClient = useQueryClient();

  useEffect(() => {
    if (!isAuthenticated()) router.push("/login");
  }, [isAuthenticated, router]);

  const { data: styleProfile } = useQuery<StyleProfile | null>({
    queryKey: ["style-profile"],
    queryFn: () => api.get<StyleProfile | null>("/profile/style").then((r) => r.data),
    enabled: isAuthenticated(),
  });

  const [vibes, setVibes] = useState<string[]>([]);
  const [colorPrefs, setColorPrefs] = useState<string[]>([]);
  const [climate, setClimate] = useState<string>("");

  useEffect(() => {
    if (styleProfile) {
      setVibes(styleProfile.style_vibes);
      setColorPrefs(styleProfile.color_palette_pref);
      setClimate(styleProfile.climate || "");
    }
  }, [styleProfile]);

  const { register, handleSubmit, formState: { errors } } = useForm<ProfileForm>({
    defaultValues: { display_name: user?.display_name || "" },
  });

  const { mutate: saveProfile, isPending: isSavingProfile } = useMutation({
    mutationFn: (data: ProfileForm) => api.patch<AuthUser>("/profile", data),
    onSuccess: ({ data }) => {
      updateUser({ display_name: data.display_name });
      toast.success("Perfil actualizado");
    },
    onError: () => toast.error("Error al guardar"),
  });

  const { mutate: saveStyle, isPending: isSavingStyle } = useMutation({
    mutationFn: () =>
      api.put("/profile/style", {
        style_vibes: vibes,
        color_palette_pref: colorPrefs,
        climate: climate || null,
        onboarding_completed: true,
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["style-profile"] });
      toast.success("Preferencias guardadas");
    },
    onError: () => toast.error("Error al guardar"),
  });

  const handleLogout = () => {
    logout();
    router.push("/login");
  };

  const toggle = (arr: string[], setArr: (v: string[]) => void, val: string) => {
    setArr(arr.includes(val) ? arr.filter((v) => v !== val) : [...arr, val]);
  };

  if (!user) return null;

  return (
    <div className="flex min-h-screen bg-ivory">
      <Sidebar active="profile" />

      <main className="flex-1 md:ml-64 px-5 md:px-10 py-8 pb-24 md:pb-8 max-w-2xl">
        {/* Avatar + name */}
        <div className="flex items-center gap-5 mb-10">
          <div className="w-16 h-16 rounded-full bg-blush flex items-center justify-center">
            <span className="font-serif text-2xl text-warm-black">
              {user.display_name.charAt(0)}
            </span>
          </div>
          <div>
            <h1 className="font-serif text-3xl text-warm-black font-light">{user.display_name}</h1>
            <p className="text-stone text-sm font-sans">{user.email}</p>
            {user.founder_access && (
              <span className="inline-block mt-1 text-xs font-sans text-gold-dark bg-[rgba(212,175,130,0.12)] px-3 py-0.5 rounded-full border border-[rgba(212,175,130,0.25)]">
                Founder Access
              </span>
            )}
          </div>
        </div>

        <div className="space-y-8">
          {/* Profile form */}
          <Section title="Información básica" icon={<User size={16} />}>
            <form onSubmit={handleSubmit((d) => saveProfile(d))} className="space-y-4">
              <div>
                <label className="label-xs">Nombre</label>
                <input {...register("display_name")} className={inputCls} />
                {errors.display_name && <p className="text-error-blush text-xs mt-1">{errors.display_name.message}</p>}
              </div>
              <button type="submit" disabled={isSavingProfile} className={saveBtnCls}>
                {isSavingProfile ? <><Loader2 size={14} className="animate-spin" />Guardando...</> : "Guardar"}
              </button>
            </form>
          </Section>

          {/* Style preferences */}
          <Section title="Estilo" icon={<Palette size={16} />}>
            <div className="space-y-5">
              <div>
                <label className="label-xs mb-3 block">Vibes</label>
                <div className="flex flex-wrap gap-2">
                  {STYLE_VIBES.map((v) => (
                    <Chip key={v} label={v} active={vibes.includes(v)} onToggle={() => toggle(vibes, setVibes, v)} />
                  ))}
                </div>
              </div>
              <div>
                <label className="label-xs mb-3 block">Paleta de colores</label>
                <div className="flex flex-wrap gap-2">
                  {COLOR_PREFS.map((c) => (
                    <Chip key={c} label={c} active={colorPrefs.includes(c)} onToggle={() => toggle(colorPrefs, setColorPrefs, c)} />
                  ))}
                </div>
              </div>
              <div>
                <label className="label-xs mb-3 block">Clima habitual</label>
                <div className="flex gap-2">
                  {CLIMATES.map((c) => (
                    <Chip key={c} label={c} active={climate === c} onToggle={() => setClimate(climate === c ? "" : c)} />
                  ))}
                </div>
              </div>
              <button
                onClick={() => saveStyle()}
                disabled={isSavingStyle}
                className={saveBtnCls}
              >
                {isSavingStyle ? <><Loader2 size={14} className="animate-spin" />Guardando...</> : "Guardar preferencias"}
              </button>
            </div>
          </Section>

          {/* Account */}
          <Section title="Cuenta" icon={<Globe size={16} />}>
            <div className="space-y-3">
              <div className="flex justify-between items-center py-3 border-b border-[rgba(28,26,24,0.06)]">
                <div>
                  <p className="text-sm font-sans text-warm-black">Plan</p>
                  <p className="text-xs text-stone capitalize">{user.tier}</p>
                </div>
              </div>
              <button
                onClick={handleLogout}
                className="flex items-center gap-3 w-full py-3 text-sm font-sans text-stone hover:text-error-blush transition-colors"
              >
                <LogOut size={16} />
                Cerrar sesión
              </button>
            </div>
          </Section>
        </div>
      </main>
    </div>
  );
}

function Section({ title, icon, children }: { title: string; icon: React.ReactNode; children: React.ReactNode }) {
  return (
    <div className="bg-white rounded-2xl p-6 border border-[rgba(28,26,24,0.06)]">
      <div className="flex items-center gap-2 mb-5">
        <span className="text-stone">{icon}</span>
        <h2 className="font-sans text-sm font-medium text-warm-black uppercase tracking-wider">{title}</h2>
      </div>
      {children}
    </div>
  );
}

function Chip({ label, active, onToggle }: { label: string; active: boolean; onToggle: () => void }) {
  return (
    <button
      type="button"
      onClick={onToggle}
      className={cn(
        "h-8 px-3 rounded-full text-xs font-sans transition-all duration-200 capitalize",
        active
          ? "bg-warm-black text-ivory"
          : "border border-[rgba(28,26,24,0.12)] text-warm-black hover:border-warm-black"
      )}
    >
      {label}
    </button>
  );
}

const inputCls = "w-full h-11 px-3 rounded-lg border border-[rgba(28,26,24,0.10)] bg-ivory text-warm-black text-sm font-sans focus:border-gold focus:outline-none transition-colors";
const saveBtnCls = "flex items-center justify-center gap-2 h-10 px-6 bg-warm-black text-ivory rounded-lg font-sans text-sm font-medium hover:bg-charcoal transition-colors disabled:opacity-50";
