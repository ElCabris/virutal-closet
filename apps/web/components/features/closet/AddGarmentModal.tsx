"use client";

import { useCallback, useRef, useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { Upload, ImagePlus, X, Loader2 } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import { api } from "@/lib/api/client";
import { Sheet } from "@/components/ui/Sheet";
import { useToast } from "@/lib/hooks/useToast";
import type { Garment, UploadResponse } from "@/lib/types";
import { cn } from "@/lib/utils/cn";

const CATEGORIES = ["tops", "bottoms", "dresses", "outerwear", "shoes", "bags", "accessories"];
const SEASONS = ["spring", "summer", "fall", "winter"];
const OCCASIONS = ["casual", "office", "formal", "travel", "evening", "sport"];

const schema = z.object({
  name: z.string().optional(),
  brand: z.string().optional(),
  category: z.string().optional(),
  size: z.string().optional(),
  purchase_price: z.string().optional(),
  condition: z.string().default("good"),
  seasons: z.array(z.string()).default([]),
  occasions: z.array(z.string()).default([]),
  notes: z.string().optional(),
});
type FormData = z.infer<typeof schema>;

interface Props {
  open: boolean;
  onClose: () => void;
  onCreated?: (garment: Garment) => void;
}

type UploadStage = "idle" | "uploading" | "filling" | "saving";

export function AddGarmentModal({ open, onClose, onCreated }: Props) {
  const [stage, setStage] = useState<UploadStage>("idle");
  const [preview, setPreview] = useState<string | null>(null);
  const [uploadResult, setUploadResult] = useState<UploadResponse | null>(null);
  const [dragOver, setDragOver] = useState(false);
  const fileRef = useRef<HTMLInputElement>(null);
  const toast = useToast();
  const queryClient = useQueryClient();

  const {
    register,
    handleSubmit,
    reset,
    setValue,
    watch,
    formState: { errors },
  } = useForm<FormData>({ resolver: zodResolver(schema) });

  const selectedSeasons = watch("seasons") || [];
  const selectedOccasions = watch("occasions") || [];

  const handleClose = useCallback(() => {
    setStage("idle");
    setPreview((prev) => { if (prev) URL.revokeObjectURL(prev); return null; });
    setUploadResult(null);
    setDragOver(false);
    reset();
    onClose();
  }, [onClose, reset]);

  const handleFile = useCallback(async (file: File) => {
    if (!file.type.startsWith("image/")) {
      toast.error("Solo se permiten imágenes (JPEG, PNG, WEBP)");
      return;
    }
    if (file.size > 20 * 1024 * 1024) {
      toast.error("La imagen no puede superar 20 MB");
      return;
    }

    const objectUrl = URL.createObjectURL(file);
    setPreview(objectUrl);
    setStage("uploading");

    const form = new FormData();
    form.append("file", file);

    try {
      const { data } = await api.upload<UploadResponse>("/garments/upload", form);
      setUploadResult(data);
      setStage("filling");
    } catch {
      toast.error("Error al subir la imagen. Intenta de nuevo.");
      setStage("idle");
      URL.revokeObjectURL(objectUrl);
      setPreview(null);
    }
  }, [toast]);

  const onDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setDragOver(false);
    const file = e.dataTransfer.files[0];
    if (file) handleFile(file);
  }, [handleFile]);

  const { mutate: saveGarment, isPending: isSaving } = useMutation({
    mutationFn: async (data: FormData) => {
      if (!uploadResult) throw new Error("No upload");
      const payload = {
        name: data.name || null,
        brand: data.brand || null,
        category: data.category || null,
        size: data.size || null,
        purchase_price: data.purchase_price ? parseFloat(data.purchase_price) : null,
        condition: data.condition,
        seasons: data.seasons,
        occasions: data.occasions,
        notes: data.notes || null,
      };
      // Update the stub garment created during upload
      const { data: garment } = await api.patch<Garment>(`/garments/${uploadResult.garment_id}`, payload);
      return garment;
    },
    onSuccess: (garment) => {
      queryClient.invalidateQueries({ queryKey: ["garments"] });
      toast.success("Prenda agregada. La IA está analizando...");
      onCreated?.(garment);
      handleClose();
    },
    onError: () => toast.error("Error al guardar la prenda"),
  });

  const toggleArrayField = (field: "seasons" | "occasions", val: string) => {
    const current = field === "seasons" ? selectedSeasons : selectedOccasions;
    const next = current.includes(val) ? current.filter((v) => v !== val) : [...current, val];
    setValue(field, next);
  };

  return (
    <Sheet open={open} onClose={handleClose} title="Agregar prenda" side="right" size="md">
      <AnimatePresence mode="wait">
        {stage === "idle" && (
          <motion.div
            key="idle"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="space-y-4"
          >
            {/* Drop zone */}
            <div
              onDragOver={(e) => { e.preventDefault(); setDragOver(true); }}
              onDragLeave={() => setDragOver(false)}
              onDrop={onDrop}
              onClick={() => fileRef.current?.click()}
              className={cn(
                "border-2 border-dashed rounded-xl p-10 flex flex-col items-center gap-3 cursor-pointer transition-all duration-200",
                dragOver
                  ? "border-gold bg-[rgba(212,175,130,0.08)] scale-[1.01]"
                  : "border-[rgba(28,26,24,0.12)] hover:border-gold hover:bg-cream"
              )}
            >
              <div className="w-14 h-14 rounded-full bg-cream flex items-center justify-center">
                <ImagePlus size={24} className="text-stone" />
              </div>
              <div className="text-center">
                <p className="font-sans text-sm text-warm-black font-medium">
                  Arrastra una foto o haz clic
                </p>
                <p className="font-sans text-xs text-stone mt-1">JPEG, PNG o WEBP · máx. 20 MB</p>
              </div>
            </div>
            <input
              ref={fileRef}
              type="file"
              accept="image/jpeg,image/png,image/webp"
              className="hidden"
              onChange={(e) => e.target.files?.[0] && handleFile(e.target.files[0])}
            />
          </motion.div>
        )}

        {stage === "uploading" && (
          <motion.div
            key="uploading"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="flex flex-col items-center gap-6 py-16"
          >
            {preview && (
              <div className="w-32 h-44 rounded-xl overflow-hidden">
                <img src={preview} alt="" className="w-full h-full object-cover" />
              </div>
            )}
            <div className="flex items-center gap-3">
              <Loader2 size={18} className="animate-spin text-gold" />
              <p className="text-stone text-sm font-sans">Subiendo imagen...</p>
            </div>
          </motion.div>
        )}

        {stage === "filling" && (
          <motion.div
            key="filling"
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0 }}
          >
            <form onSubmit={handleSubmit((d) => saveGarment(d))} className="space-y-5">
              {/* Preview + color */}
              {preview && (
                <div className="flex items-start gap-4 mb-6">
                  <div className="w-20 h-28 rounded-lg overflow-hidden shrink-0">
                    <img src={preview} alt="" className="w-full h-full object-cover" />
                  </div>
                  <div>
                    <p className="text-xs text-stone font-sans mb-2">Colores detectados</p>
                    <div className="flex gap-1.5">
                      {uploadResult?.color_palette?.slice(0, 5).map((c, i) => (
                        <div
                          key={i}
                          className="w-6 h-6 rounded-full border border-[rgba(28,26,24,0.10)]"
                          style={{ backgroundColor: c.hex }}
                          title={c.name}
                        />
                      ))}
                    </div>
                    <p className="text-[10px] text-stone mt-2 font-sans">
                      La IA completará los detalles automáticamente
                    </p>
                  </div>
                </div>
              )}

              {/* Name */}
              <div>
                <label className="text-xs text-stone font-sans uppercase tracking-wider mb-1.5 block">Nombre</label>
                <input
                  {...register("name")}
                  placeholder="Ej. Blusa de lino blanca"
                  className="w-full h-11 px-3 rounded-lg border border-[rgba(28,26,24,0.10)] bg-ivory text-warm-black text-sm font-sans focus:border-gold focus:outline-none transition-colors"
                />
              </div>

              {/* Brand */}
              <div>
                <label className="text-xs text-stone font-sans uppercase tracking-wider mb-1.5 block">Marca</label>
                <input
                  {...register("brand")}
                  placeholder="Ej. Zara, COS, Massimo Dutti"
                  className="w-full h-11 px-3 rounded-lg border border-[rgba(28,26,24,0.10)] bg-ivory text-warm-black text-sm font-sans focus:border-gold focus:outline-none transition-colors"
                />
              </div>

              {/* Category */}
              <div>
                <label className="text-xs text-stone font-sans uppercase tracking-wider mb-1.5 block">Categoría</label>
                <select
                  {...register("category")}
                  className="w-full h-11 px-3 rounded-lg border border-[rgba(28,26,24,0.10)] bg-ivory text-warm-black text-sm font-sans focus:border-gold focus:outline-none transition-colors"
                >
                  <option value="">Sin categoría</option>
                  {CATEGORIES.map((c) => (
                    <option key={c} value={c}>{c.charAt(0).toUpperCase() + c.slice(1)}</option>
                  ))}
                </select>
              </div>

              {/* Size + Price */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-xs text-stone font-sans uppercase tracking-wider mb-1.5 block">Talla</label>
                  <input
                    {...register("size")}
                    placeholder="XS / S / M..."
                    className="w-full h-11 px-3 rounded-lg border border-[rgba(28,26,24,0.10)] bg-ivory text-warm-black text-sm font-sans focus:border-gold focus:outline-none transition-colors"
                  />
                </div>
                <div>
                  <label className="text-xs text-stone font-sans uppercase tracking-wider mb-1.5 block">Precio USD</label>
                  <input
                    {...register("purchase_price")}
                    type="number"
                    step="0.01"
                    placeholder="0.00"
                    className="w-full h-11 px-3 rounded-lg border border-[rgba(28,26,24,0.10)] bg-ivory text-warm-black text-sm font-sans focus:border-gold focus:outline-none transition-colors"
                  />
                </div>
              </div>

              {/* Seasons */}
              <div>
                <label className="text-xs text-stone font-sans uppercase tracking-wider mb-2 block">Temporadas</label>
                <div className="flex flex-wrap gap-2">
                  {SEASONS.map((s) => (
                    <button
                      key={s}
                      type="button"
                      onClick={() => toggleArrayField("seasons", s)}
                      className={cn(
                        "h-8 px-3 rounded-full text-xs font-sans transition-all duration-200",
                        selectedSeasons.includes(s)
                          ? "bg-warm-black text-ivory"
                          : "border border-[rgba(28,26,24,0.12)] text-warm-black hover:border-warm-black"
                      )}
                    >
                      {s}
                    </button>
                  ))}
                </div>
              </div>

              {/* Occasions */}
              <div>
                <label className="text-xs text-stone font-sans uppercase tracking-wider mb-2 block">Ocasiones</label>
                <div className="flex flex-wrap gap-2">
                  {OCCASIONS.map((o) => (
                    <button
                      key={o}
                      type="button"
                      onClick={() => toggleArrayField("occasions", o)}
                      className={cn(
                        "h-8 px-3 rounded-full text-xs font-sans transition-all duration-200",
                        selectedOccasions.includes(o)
                          ? "bg-warm-black text-ivory"
                          : "border border-[rgba(28,26,24,0.12)] text-warm-black hover:border-warm-black"
                      )}
                    >
                      {o}
                    </button>
                  ))}
                </div>
              </div>

              {/* Notes */}
              <div>
                <label className="text-xs text-stone font-sans uppercase tracking-wider mb-1.5 block">Notas</label>
                <textarea
                  {...register("notes")}
                  rows={3}
                  placeholder="Cualquier detalle adicional..."
                  className="w-full px-3 py-2.5 rounded-lg border border-[rgba(28,26,24,0.10)] bg-ivory text-warm-black text-sm font-sans focus:border-gold focus:outline-none transition-colors resize-none"
                />
              </div>

              <button
                type="submit"
                disabled={isSaving}
                className="w-full h-12 bg-warm-black text-ivory rounded-lg font-sans font-medium text-sm hover:bg-charcoal transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
              >
                {isSaving ? (
                  <>
                    <Loader2 size={16} className="animate-spin" />
                    Guardando...
                  </>
                ) : (
                  "Guardar prenda"
                )}
              </button>
            </form>
          </motion.div>
        )}
      </AnimatePresence>
    </Sheet>
  );
}
