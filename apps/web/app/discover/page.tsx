"use client";

import { useEffect, useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { Bookmark, RefreshCw, Loader2 } from "lucide-react";
import { useAuthStore } from "@/lib/stores/authStore";
import { api } from "@/lib/api/client";
import { Sidebar } from "@/components/layout/Sidebar";
import { useToast } from "@/lib/hooks/useToast";
import type { Recommendation } from "@/lib/types";

const MOODS = [
  { id: "casual",    label: "Casual",    emoji: "☀️" },
  { id: "office",    label: "Office",    emoji: "💼" },
  { id: "dinner",    label: "Dinner",    emoji: "🍷" },
  { id: "elegant",   label: "Elegant",   emoji: "✨" },
  { id: "soft_girl", label: "Soft Girl", emoji: "🌸" },
  { id: "cozy",      label: "Cozy",      emoji: "🧸" },
  { id: "travel",    label: "Travel",    emoji: "✈️" },
  { id: "academia",  label: "Academia",  emoji: "📚" },
];

export default function DiscoverPage() {
  const { isAuthenticated } = useAuthStore();
  const router = useRouter();
  const toast = useToast();
  const queryClient = useQueryClient();
  const [activeMood, setActiveMood] = useState("casual");

  useEffect(() => {
    if (!isAuthenticated()) router.push("/login");
  }, [isAuthenticated, router]);

  const { data, isLoading, refetch, isFetching } = useQuery<{ outfits: Recommendation[]; context: { garment_count?: number } }>({
    queryKey: ["recommendations", activeMood],
    queryFn: () =>
      api.get<{ outfits: Recommendation[]; context: { garment_count?: number } }>(
        `/recommendations?mood=${activeMood}&count=6`
      ).then((r) => r.data),
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
    onError: () => toast.error("Error al guardar"),
  });

  return (
    <div className="flex min-h-screen bg-ivory">
      <Sidebar active="discover" />

      <main className="flex-1 md:ml-64 px-5 md:px-10 py-8 pb-24 md:pb-8">
        {/* Header */}
        <div className="flex items-center justify-between mb-2">
          <h1 className="font-serif text-4xl text-warm-black font-light">Discover</h1>
          <button
            onClick={() => refetch()}
            disabled={isFetching}
            className="flex items-center gap-2 h-9 px-4 border border-[rgba(28,26,24,0.10)] rounded-full text-sm font-sans text-stone hover:text-warm-black hover:bg-cream transition-all"
          >
            <RefreshCw size={14} className={isFetching ? "animate-spin" : ""} />
            Refresh
          </button>
        </div>
        <p className="text-stone text-sm font-sans mb-8">Looks curados por Crayoli, solo para ti.</p>

        {/* Mood selector */}
        <div className="flex gap-2 overflow-x-auto pb-3 mb-8 scrollbar-none -mx-1 px-1">
          {MOODS.map((m) => (
            <button
              key={m.id}
              onClick={() => setActiveMood(m.id)}
              className={`flex-shrink-0 flex items-center gap-2 h-10 px-4 rounded-full font-sans text-sm transition-all duration-200 ${
                activeMood === m.id
                  ? "bg-warm-black text-ivory"
                  : "bg-white border border-[rgba(28,26,24,0.10)] text-warm-black hover:border-[rgba(28,26,24,0.20)]"
              }`}
            >
              <span>{m.emoji}</span>
              {m.label}
            </button>
          ))}
        </div>

        {isLoading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="h-80 bg-cream rounded-xl skeleton" />
            ))}
          </div>
        ) : !data?.outfits?.length ? (
          <div className="text-center py-24">
            <p className="font-serif text-2xl text-warm-black mb-2">Agrega más prendas</p>
            <p className="text-stone text-sm font-sans">
              Necesitas al menos 2 prendas con análisis completo para recibir sugerencias.
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {data.outfits.map((outfit) => (
              <OutfitCard key={outfit.id} outfit={outfit} onSave={() => saveOutfit(outfit)} />
            ))}
          </div>
        )}
      </main>
    </div>
  );
}

function OutfitCard({ outfit, onSave }: { outfit: Recommendation; onSave: () => void }) {
  const router = useRouter();

  return (
    <div className="bg-white rounded-2xl overflow-hidden border border-[rgba(28,26,24,0.06)] hover:shadow-md transition-all duration-300">
      {/* Garment grid */}
      <div className="grid grid-cols-2 gap-0.5 aspect-square">
        {outfit.items.slice(0, 4).map((item, i) => (
          <div
            key={i}
            className="relative overflow-hidden"
            style={{ backgroundColor: item.garment?.dominant_color || "#F5F0E8" }}
          >
            {item.garment?.image_url_thumb ? (
              <img
                src={item.garment.image_url_thumb}
                alt={item.garment.name || ""}
                className="w-full h-full object-cover"
              />
            ) : (
              <div className="w-full h-full" />
            )}
          </div>
        ))}
      </div>

      {/* Info */}
      <div className="p-4">
        <div className="flex items-start justify-between mb-1">
          <h3 className="font-serif text-lg text-warm-black leading-tight">{outfit.name}</h3>
          <div className="flex items-center gap-1 shrink-0 ml-2">
            <div className="h-1 w-1 rounded-full bg-success-sage" />
            <span className="text-[11px] text-stone font-sans">{Math.round(outfit.score * 100)}%</span>
          </div>
        </div>
        <p className="text-stone text-xs font-sans mb-3">{outfit.context_label}</p>
        <p className="text-xs text-charcoal font-sans mb-4 bg-cream rounded-lg px-3 py-2">
          {outfit.rationale.color_harmony}
        </p>

        <div className="flex gap-2">
          <button
            onClick={() => {
              const firstGarmentId = outfit.items[0]?.garment?.id;
              if (firstGarmentId) router.push(`/closet/${firstGarmentId}`);
            }}
            className="flex-1 h-9 bg-warm-black text-ivory rounded-lg text-xs font-sans font-medium hover:bg-charcoal transition-colors"
          >
            Usar hoy
          </button>
          <button
            onClick={(e) => { e.stopPropagation(); onSave(); }}
            className="w-9 h-9 border border-[rgba(28,26,24,0.10)] rounded-lg flex items-center justify-center hover:bg-cream transition-colors"
            aria-label="Guardar outfit"
          >
            <Bookmark size={15} className="text-stone" />
          </button>
        </div>
      </div>
    </div>
  );
}
