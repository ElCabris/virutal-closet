"use client";

import { useState } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { Heart } from "lucide-react";
import { api } from "@/lib/api/client";
import { cn } from "@/lib/utils/cn";

import type { Garment } from "@/lib/types";

interface Props {
  garment: Garment;
  onClick?: () => void;
}


export function GarmentCard({ garment, onClick }: Props) {
  const [isFav, setIsFav] = useState(garment.is_favorite);
  const queryClient = useQueryClient();

  const { mutate: toggleFav } = useMutation({
    mutationFn: () =>
      api.patch(`/garments/${garment.id}`, { is_favorite: !isFav }),
    onMutate: () => setIsFav((v) => !v),
    onError: () => setIsFav((v) => !v),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["garments"] }),
  });

  const isProcessing = garment.ai_status === "processing" || garment.ai_status === "pending";

  return (
    <div
      className="group relative bg-white rounded-lg overflow-hidden shadow-xs hover:shadow-md transition-all duration-250 ease-silky hover:-translate-y-1 cursor-pointer border border-[rgba(28,26,24,0.04)]"
      onClick={onClick}
    >
      {/* Image area */}
      <div
        className="aspect-[5/7] relative overflow-hidden"
        style={{ backgroundColor: garment.dominant_color || "#F5F0E8" }}
      >
        {garment.image_url_card ? (
          <img
            src={garment.image_url_card}
            alt={garment.name || garment.category || "Prenda"}
            className="w-full h-full object-cover"
            loading="lazy"
          />
        ) : (
          <div className="w-full h-full skeleton" />
        )}

        {isProcessing && (
          <div className="absolute inset-0 bg-[rgba(250,248,245,0.6)] flex items-center justify-center">
            <div className="w-5 h-5 border-2 border-gold border-t-transparent rounded-full animate-spin" />
          </div>
        )}

        {/* Favorite button */}
        <button
          onClick={(e) => { e.stopPropagation(); toggleFav(); }}
          className="absolute top-2 right-2 w-7 h-7 flex items-center justify-center rounded-full bg-white/80 backdrop-blur-sm opacity-0 group-hover:opacity-100 transition-opacity duration-200"
          aria-label={isFav ? "Quitar de favoritos" : "Agregar a favoritos"}
        >
          <Heart
            size={13}
            className={cn(
              "transition-colors duration-200",
              isFav ? "fill-mauve stroke-mauve" : "stroke-stone"
            )}
          />
        </button>

        {/* Wear count badge */}
        {garment.wear_count > 0 && (
          <div className="absolute bottom-2 left-2 bg-white/80 backdrop-blur-sm rounded-full px-2 py-0.5 opacity-0 group-hover:opacity-100 transition-opacity duration-200">
            <span className="text-[10px] text-charcoal font-sans">{garment.wear_count}x</span>
          </div>
        )}
      </div>

      {/* Card info */}
      <div className="px-3 py-2.5">
        <p className="text-warm-black text-xs font-sans font-medium truncate leading-tight">
          {garment.name || garment.ai_style_label || garment.category || "Sin nombre"}
        </p>
        {garment.brand && (
          <p className="text-stone text-[10px] font-sans truncate mt-0.5">{garment.brand}</p>
        )}
        {/* Color dots */}
        {garment.color_palette?.length > 0 && (
          <div className="flex gap-1 mt-2">
            {garment.color_palette.slice(0, 3).map((c, i) => (
              <div
                key={i}
                className="w-2 h-2 rounded-full border border-[rgba(28,26,24,0.10)]"
                style={{ backgroundColor: c.hex }}
                title={c.name}
              />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
