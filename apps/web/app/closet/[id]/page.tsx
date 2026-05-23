"use client";

import { useState, useEffect } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { ArrowLeft, Heart, Edit3, Trash2, Loader2, CheckCircle } from "lucide-react";
import { useAuthStore } from "@/lib/stores/authStore";
import { api } from "@/lib/api/client";
import { Sidebar } from "@/components/layout/Sidebar";
import { EditGarmentSheet } from "@/components/features/closet/EditGarmentSheet";
import { useToast } from "@/lib/hooks/useToast";
import type { Garment } from "@/lib/types";
import { cn } from "@/lib/utils/cn";

const AI_STATUS_LABELS: Record<string, string> = {
  queued:      "En cola",
  processing:  "Procesando",
  analyzing:   "Analizando con IA",
  complete:    "Análisis completo",
  failed:      "Error en análisis",
};

export default function GarmentDetailPage({ params }: { params: { id: string } }) {
  const { isAuthenticated } = useAuthStore();
  const router = useRouter();
  const queryClient = useQueryClient();
  const toast = useToast();
  const [editOpen, setEditOpen] = useState(false);
  const [isFav, setIsFav] = useState(false);

  useEffect(() => {
    if (!isAuthenticated()) router.push("/login");
  }, [isAuthenticated, router]);

  const { data: garment, isLoading } = useQuery<Garment>({
    queryKey: ["garment", params.id],
    queryFn: () => api.get<Garment>(`/garments/${params.id}`).then((r) => r.data),
    enabled: isAuthenticated(),
    refetchInterval: (q) => {
      const status = q.state.data?.ai_status;
      // Poll while AI is still processing
      return status && !["complete", "failed"].includes(status) ? 3000 : false;
    },
  });

  useEffect(() => {
    if (garment) setIsFav(garment.is_favorite);
  }, [garment]);

  const { mutate: logWear, isPending: isWearing } = useMutation({
    mutationFn: () => api.post<Garment>(`/garments/${params.id}/wear`),
    onSuccess: ({ data }) => {
      queryClient.setQueryData(["garment", params.id], data);
      queryClient.invalidateQueries({ queryKey: ["garments"] });
      toast.success("¡Registrado! Outfit del día guardado.");
    },
    onError: () => toast.error("Error al registrar el uso"),
  });

  const { mutate: toggleFav } = useMutation({
    mutationFn: () => api.patch<Garment>(`/garments/${params.id}`, { is_favorite: !isFav }),
    onMutate: () => setIsFav((v) => !v),
    onSuccess: ({ data }) => {
      queryClient.setQueryData(["garment", params.id], data);
      queryClient.invalidateQueries({ queryKey: ["garments"] });
    },
    onError: () => setIsFav((v) => !v),
  });

  const { mutate: deleteGarment, isPending: isDeleting } = useMutation({
    mutationFn: () => api.delete(`/garments/${params.id}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["garments"] });
      toast.success("Prenda eliminada");
      router.push("/closet");
    },
    onError: () => toast.error("Error al eliminar"),
  });

  if (isLoading) return <LoadingSkeleton />;
  if (!garment) return null;

  const cpw =
    garment.purchase_price && garment.wear_count > 0
      ? (garment.purchase_price / garment.wear_count).toFixed(2)
      : null;

  const isProcessing = !["complete", "failed"].includes(garment.ai_status);

  return (
    <div className="flex min-h-screen bg-ivory">
      <Sidebar active="closet" />

      <main className="flex-1 md:ml-64 px-5 md:px-10 py-8 max-w-2xl">
        {/* Top bar */}
        <div className="flex items-center justify-between mb-6">
          <button
            onClick={() => router.back()}
            className="flex items-center gap-2 text-stone text-sm font-sans hover:text-warm-black transition-colors"
          >
            <ArrowLeft size={16} />
            Mi Closet
          </button>
          <div className="flex items-center gap-2">
            <button
              onClick={() => setEditOpen(true)}
              className="w-9 h-9 flex items-center justify-center rounded-full border border-[rgba(28,26,24,0.10)] hover:bg-cream transition-colors"
              aria-label="Editar"
            >
              <Edit3 size={15} className="text-stone" />
            </button>
            <button
              onClick={() => {
                if (confirm("¿Eliminar esta prenda?")) deleteGarment();
              }}
              disabled={isDeleting}
              className="w-9 h-9 flex items-center justify-center rounded-full border border-[rgba(28,26,24,0.10)] hover:bg-[rgba(196,122,122,0.08)] hover:border-error-blush transition-colors"
              aria-label="Eliminar"
            >
              {isDeleting
                ? <Loader2 size={15} className="animate-spin text-stone" />
                : <Trash2 size={15} className="text-stone" />}
            </button>
          </div>
        </div>

        {/* Hero image */}
        <div
          className="aspect-[4/5] max-w-xs rounded-2xl overflow-hidden mb-6 relative"
          style={{ backgroundColor: garment.dominant_color || "#F5F0E8" }}
        >
          {garment.image_url_card ? (
            <img
              src={garment.image_url_card}
              alt={garment.name || ""}
              className="w-full h-full object-cover"
            />
          ) : (
            <div className="w-full h-full skeleton" />
          )}

          {isProcessing && (
            <div className="absolute bottom-3 left-3 flex items-center gap-2 bg-white/90 backdrop-blur-sm rounded-full px-3 py-1.5">
              <Loader2 size={12} className="animate-spin text-gold" />
              <span className="text-[11px] font-sans text-charcoal">
                {AI_STATUS_LABELS[garment.ai_status] || "Procesando..."}
              </span>
            </div>
          )}

          {garment.ai_status === "complete" && (
            <div className="absolute bottom-3 left-3 flex items-center gap-1.5 bg-white/90 backdrop-blur-sm rounded-full px-3 py-1.5">
              <CheckCircle size={12} className="text-success-sage" />
              <span className="text-[11px] font-sans text-charcoal">Análisis completo</span>
            </div>
          )}
        </div>

        {/* Color palette */}
        {garment.color_palette?.length > 0 && (
          <div className="flex gap-2 mb-6">
            {garment.color_palette.map((c, i) => (
              <div key={i} className="flex flex-col items-center gap-1">
                <div
                  className="w-8 h-8 rounded-full border border-[rgba(28,26,24,0.10)]"
                  style={{ backgroundColor: c.hex }}
                />
                <span className="text-[9px] text-stone font-sans">{c.name}</span>
              </div>
            ))}
          </div>
        )}

        {/* Name + brand */}
        <h1 className="font-serif text-3xl text-warm-black font-light leading-tight mb-1">
          {garment.name || garment.ai_style_label || garment.category || "Sin nombre"}
        </h1>
        {garment.brand && (
          <p className="text-stone text-sm font-sans mb-1">{garment.brand}</p>
        )}
        {garment.category && (
          <p className="text-xs text-stone font-sans mb-6 capitalize">{garment.category}</p>
        )}

        {/* Stats */}
        <div className="grid grid-cols-2 gap-3 mb-6">
          <StatCard label="Veces usada" value={String(garment.wear_count)} />
          <StatCard label="Costo por uso" value={cpw ? `$${cpw}` : "—"} />
        </div>

        {/* AI analysis */}
        {garment.ai_style_label && (
          <div className="bg-[rgba(212,175,130,0.06)] rounded-xl px-5 py-4 mb-6 border border-[rgba(212,175,130,0.15)]">
            <p className="text-xs text-stone font-sans uppercase tracking-widest mb-1">
              Análisis Crayoli
            </p>
            <p className="font-serif text-xl text-warm-black italic">{garment.ai_style_label}</p>
          </div>
        )}

        {/* Tags */}
        {(garment.style_tags?.length > 0 || garment.user_tags?.length > 0) && (
          <div className="flex flex-wrap gap-2 mb-6">
            {[...(garment.style_tags || []), ...(garment.user_tags || [])].map((tag) => (
              <span
                key={tag}
                className="text-xs font-sans text-charcoal bg-cream px-3 py-1 rounded-full border border-[rgba(28,26,24,0.06)]"
              >
                {tag}
              </span>
            ))}
          </div>
        )}

        {/* Metadata */}
        <div className="space-y-2 mb-8 text-sm font-sans">
          {garment.seasons?.length > 0 && (
            <MetaRow label="Temporadas" value={garment.seasons.join(", ")} />
          )}
          {garment.occasions?.length > 0 && (
            <MetaRow label="Ocasiones" value={garment.occasions.join(", ")} />
          )}
          {garment.size && <MetaRow label="Talla" value={garment.size} />}
          {garment.condition && <MetaRow label="Estado" value={garment.condition} />}
          {garment.purchase_price && (
            <MetaRow label="Precio" value={`$${garment.purchase_price} ${garment.currency}`} />
          )}
        </div>

        {/* Actions */}
        <div className="flex gap-3">
          <button
            onClick={() => logWear()}
            disabled={isWearing}
            className="flex-1 h-12 bg-warm-black text-ivory rounded-xl font-sans font-medium text-sm hover:bg-charcoal transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
          >
            {isWearing ? <Loader2 size={16} className="animate-spin" /> : null}
            Usar hoy
          </button>
          <button
            onClick={() => toggleFav()}
            className="w-12 h-12 border border-[rgba(28,26,24,0.10)] rounded-xl flex items-center justify-center hover:bg-cream transition-colors"
            aria-label={isFav ? "Quitar de favoritos" : "Favorito"}
          >
            <Heart
              size={18}
              className={cn("transition-colors", isFav ? "fill-mauve stroke-mauve" : "stroke-stone")}
            />
          </button>
        </div>
      </main>

      <EditGarmentSheet
        garment={garment}
        open={editOpen}
        onClose={() => setEditOpen(false)}
      />
    </div>
  );
}

function StatCard({ label, value }: { label: string; value: string }) {
  return (
    <div className="bg-white rounded-xl p-4 border border-[rgba(28,26,24,0.06)]">
      <p className="text-stone text-xs font-sans mb-1">{label}</p>
      <p className="font-serif text-2xl text-warm-black">{value}</p>
    </div>
  );
}

function MetaRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex gap-2">
      <span className="text-stone w-24 shrink-0">{label}</span>
      <span className="text-warm-black capitalize">{value}</span>
    </div>
  );
}

function LoadingSkeleton() {
  return (
    <div className="flex min-h-screen bg-ivory">
      <Sidebar active="closet" />
      <main className="flex-1 md:ml-64 px-5 md:px-10 py-8 max-w-2xl">
        <div className="space-y-4 animate-pulse">
          <div className="h-6 w-24 bg-cream rounded" />
          <div className="aspect-[4/5] max-w-xs bg-cream rounded-2xl" />
          <div className="h-8 w-64 bg-cream rounded" />
          <div className="h-4 w-32 bg-cream rounded" />
          <div className="grid grid-cols-2 gap-3">
            <div className="h-20 bg-cream rounded-xl" />
            <div className="h-20 bg-cream rounded-xl" />
          </div>
        </div>
      </main>
    </div>
  );
}
