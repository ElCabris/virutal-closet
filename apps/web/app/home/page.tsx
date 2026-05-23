"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { useEffect } from "react";
import { useAuthStore } from "@/lib/stores/authStore";
import { api } from "@/lib/api/client";
import { Sidebar } from "@/components/layout/Sidebar";
import { GarmentCard } from "@/components/features/closet/GarmentCard";
import { useToast } from "@/lib/hooks/useToast";
import type { Garment, PaginatedGarments, Recommendation } from "@/lib/types";

export default function HomePage() {
  const { user, isAuthenticated } = useAuthStore();
  const router = useRouter();
  const toast = useToast();
  const queryClient = useQueryClient();

  useEffect(() => {
    if (!isAuthenticated()) router.push("/login");
  }, [isAuthenticated, router]);

  const { data: garmentsData } = useQuery<PaginatedGarments>({
    queryKey: ["garments", "", "recent"],
    queryFn: () => api.get<PaginatedGarments>("/garments?page_size=8").then((r) => r.data),
    enabled: isAuthenticated(),
  });

  const { data: recsData } = useQuery<{ outfits: Recommendation[] }>({
    queryKey: ["recommendations", "casual"],
    queryFn: () =>
      api.get<{ outfits: Recommendation[] }>("/recommendations?mood=casual&count=3").then((r) => r.data),
    enabled: isAuthenticated(),
  });

  const { mutate: saveOutfit } = useMutation({
    mutationFn: (rec: Recommendation) =>
      api.post("/outfits/save-recommendation", {
        recommendation_id: rec.id,
        name: rec.name,
        mood: rec.mood,
        garment_ids: rec.items.map((i) => i.garment?.id).filter(Boolean),
        roles: Object.fromEntries(rec.items.map((i) => [i.garment?.id, i.role])),
        ai_score: rec.score,
        palette_match: rec.palette_match,
      }),
    onSuccess: () => {
      toast.success("Outfit guardado");
      queryClient.invalidateQueries({ queryKey: ["outfits"] });
    },
  });

  const greetingHour = new Date().getHours();
  const greeting =
    greetingHour < 12 ? "Buenos días" : greetingHour < 18 ? "Buenas tardes" : "Buenas noches";

  const garments = garmentsData?.items || [];

  if (!user) return null;

  return (
    <div className="flex min-h-screen bg-ivory">
      <Sidebar active="home" />

      <main className="flex-1 md:ml-64 px-5 md:px-10 py-8 max-w-5xl pb-24 md:pb-8">
        {/* Header */}
        <div className="mb-10">
          <p className="text-stone text-sm font-sans mb-1">{greeting},</p>
          <h1 className="font-serif text-4xl text-warm-black font-light leading-tight">
            {user.display_name}.
          </h1>
          {user.founder_access && (
            <span className="inline-block mt-2 text-xs font-sans text-gold-dark bg-[rgba(212,175,130,0.12)] px-3 py-1 rounded-full border border-[rgba(212,175,130,0.25)]">
              Founder Access — acceso completo
            </span>
          )}
        </div>

        {/* Today's Recommendations */}
        {recsData?.outfits && recsData.outfits.length > 0 && (
          <section className="mb-12">
            <p className="text-xs text-stone tracking-[0.12em] uppercase mb-5 font-sans">
              Sugerencias de hoy
            </p>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {recsData.outfits.map((outfit) => (
                <div
                  key={outfit.id}
                  className="bg-white rounded-2xl overflow-hidden shadow-xs border border-[rgba(28,26,24,0.06)] hover:shadow-md transition-all duration-300"
                >
                  {/* Mini garment grid */}
                  <div className="grid grid-cols-2 gap-0.5 aspect-square">
                    {outfit.items.slice(0, 4).map((item, i) => (
                      <div
                        key={i}
                        className="overflow-hidden"
                        style={{ backgroundColor: item.garment?.dominant_color || "#F5F0E8" }}
                      >
                        {item.garment?.image_url_thumb && (
                          <img
                            src={item.garment.image_url_thumb}
                            alt={String(item.garment.name || "")}
                            className="w-full h-full object-cover"
                          />
                        )}
                      </div>
                    ))}
                  </div>
                  <div className="p-4">
                    <h3 className="font-serif text-lg text-warm-black mb-1">{outfit.name}</h3>
                    <p className="text-stone text-xs font-sans mb-4">{outfit.context_label}</p>
                    <div className="flex gap-2">
                      <button className="flex-1 h-9 bg-warm-black text-ivory rounded-lg text-xs font-sans font-medium hover:bg-charcoal transition-colors">
                        Usar hoy
                      </button>
                      <button
                        onClick={() => saveOutfit(outfit)}
                        className="flex-1 h-9 border border-[rgba(28,26,24,0.10)] text-warm-black rounded-lg text-xs font-sans hover:bg-cream transition-colors"
                      >
                        Guardar
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </section>
        )}

        {/* Recent Closet */}
        <section>
          <div className="flex items-center justify-between mb-5">
            <p className="text-xs text-stone tracking-[0.12em] uppercase font-sans">
              Tu closet reciente
            </p>
            <button
              onClick={() => router.push("/closet")}
              className="text-warm-black text-sm font-sans hover:underline underline-offset-2"
            >
              Ver todo →
            </button>
          </div>

          {garments.length > 0 ? (
            <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
              {garments.slice(0, 8).map((g) => (
                <GarmentCard key={g.id} garment={g} onClick={() => router.push(`/closet/${g.id}`)} />
              ))}
            </div>
          ) : (
            <div className="text-center py-16 bg-white rounded-2xl border border-[rgba(28,26,24,0.06)]">
              <p className="font-serif text-2xl text-warm-black mb-2">Tu historia comienza aquí.</p>
              <p className="text-stone text-sm font-sans mb-6">
                Agrega tu primera prenda y deja que Crayoli aprenda tu lenguaje.
              </p>
              <button
                onClick={() => router.push("/closet")}
                className="px-6 py-3 bg-warm-black text-ivory rounded-lg font-sans text-sm font-medium hover:bg-charcoal transition-colors"
              >
                Agregar una prenda
              </button>
            </div>
          )}
        </section>
      </main>
    </div>
  );
}
