"use client";

import { useEffect } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { Loader2 } from "lucide-react";
import { api } from "@/lib/api/client";
import { Sheet } from "@/components/ui/Sheet";
import { useToast } from "@/lib/hooks/useToast";
import type { Garment } from "@/lib/types";
import { cn } from "@/lib/utils/cn";

const CATEGORIES = ["tops", "bottoms", "dresses", "outerwear", "shoes", "bags", "accessories"];
const SEASONS = ["spring", "summer", "fall", "winter"];
const OCCASIONS = ["casual", "office", "formal", "travel", "evening", "sport"];
const CONDITIONS = ["new", "excellent", "good", "fair", "poor"];
const FORMALITY = [
  { v: 1, label: "Muy casual" },
  { v: 2, label: "Casual" },
  { v: 3, label: "Semi-formal" },
  { v: 4, label: "Formal" },
  { v: 5, label: "Muy formal" },
];

const schema = z.object({
  name: z.string().optional(),
  brand: z.string().optional(),
  category: z.string().optional(),
  subcategory: z.string().optional(),
  size: z.string().optional(),
  purchase_price: z.string().optional(),
  condition: z.string().optional(),
  formality: z.number().optional(),
  seasons: z.array(z.string()).default([]),
  occasions: z.array(z.string()).default([]),
  user_tags: z.array(z.string()).default([]),
  notes: z.string().optional(),
});
type FormData = z.infer<typeof schema>;

interface Props {
  garment: Garment | null;
  open: boolean;
  onClose: () => void;
}

export function EditGarmentSheet({ garment, open, onClose }: Props) {
  const toast = useToast();
  const queryClient = useQueryClient();

  const { register, handleSubmit, reset, setValue, watch } = useForm<FormData>({
    resolver: zodResolver(schema),
  });

  const seasons = watch("seasons") || [];
  const occasions = watch("occasions") || [];

  useEffect(() => {
    if (garment) {
      reset({
        name: garment.name || "",
        brand: garment.brand || "",
        category: garment.category || "",
        subcategory: garment.subcategory || "",
        size: garment.size || "",
        purchase_price: garment.purchase_price?.toString() || "",
        condition: garment.condition || "good",
        formality: garment.formality || undefined,
        seasons: garment.seasons || [],
        occasions: garment.occasions || [],
        user_tags: garment.user_tags || [],
        notes: garment.notes || "",
      });
    }
  }, [garment, reset]);

  const toggle = (field: "seasons" | "occasions", val: string) => {
    const current = field === "seasons" ? seasons : occasions;
    const next = current.includes(val)
      ? current.filter((v: string) => v !== val)
      : [...current, val];
    setValue(field, next);
  };

  const { mutate, isPending } = useMutation({
    mutationFn: async (data: FormData) => {
      const { data: updated } = await api.patch<Garment>(`/garments/${garment!.id}`, {
        name: data.name || null,
        brand: data.brand || null,
        category: data.category || null,
        subcategory: data.subcategory || null,
        size: data.size || null,
        purchase_price: data.purchase_price ? parseFloat(data.purchase_price) : null,
        condition: data.condition,
        formality: data.formality,
        seasons: data.seasons,
        occasions: data.occasions,
        user_tags: data.user_tags,
        notes: data.notes || null,
      });
      return updated;
    },
    onSuccess: (updated) => {
      queryClient.invalidateQueries({ queryKey: ["garments"] });
      queryClient.setQueryData(["garment", updated.id], updated);
      toast.success("Cambios guardados");
      onClose();
    },
    onError: () => toast.error("Error al guardar los cambios"),
  });

  if (!garment) return null;

  return (
    <Sheet open={open} onClose={onClose} title="Editar prenda" side="right" size="md">
      <form onSubmit={handleSubmit((d) => mutate(d))} className="space-y-5">
        {/* Name */}
        <Field label="Nombre">
          <input
            {...register("name")}
            className={inputCls}
            placeholder="Nombre de la prenda"
          />
        </Field>

        {/* Brand */}
        <Field label="Marca">
          <input {...register("brand")} className={inputCls} placeholder="Marca" />
        </Field>

        {/* Category */}
        <Field label="Categoría">
          <select {...register("category")} className={inputCls}>
            <option value="">Sin categoría</option>
            {CATEGORIES.map((c) => (
              <option key={c} value={c}>{c.charAt(0).toUpperCase() + c.slice(1)}</option>
            ))}
          </select>
        </Field>

        {/* Subcategory */}
        <Field label="Subcategoría">
          <input {...register("subcategory")} className={inputCls} placeholder="Ej. blazer, pantalón palazzo" />
        </Field>

        {/* Size + Price */}
        <div className="grid grid-cols-2 gap-3">
          <Field label="Talla">
            <input {...register("size")} className={inputCls} placeholder="XS / S / M..." />
          </Field>
          <Field label="Precio USD">
            <input
              {...register("purchase_price")}
              type="number"
              step="0.01"
              className={inputCls}
              placeholder="0.00"
            />
          </Field>
        </div>

        {/* Condition */}
        <Field label="Estado">
          <select {...register("condition")} className={inputCls}>
            {CONDITIONS.map((c) => (
              <option key={c} value={c}>{c.charAt(0).toUpperCase() + c.slice(1)}</option>
            ))}
          </select>
        </Field>

        {/* Formality */}
        <Field label="Formalidad">
          <div className="flex gap-2">
            {FORMALITY.map(({ v, label }) => (
              <button
                key={v}
                type="button"
                onClick={() => setValue("formality", v)}
                title={label}
                className={cn(
                  "flex-1 h-9 rounded-md text-xs font-sans border transition-all",
                  watch("formality") === v
                    ? "bg-warm-black text-ivory border-warm-black"
                    : "border-[rgba(28,26,24,0.12)] text-stone hover:border-warm-black"
                )}
              >
                {v}
              </button>
            ))}
          </div>
        </Field>

        {/* Seasons */}
        <Field label="Temporadas">
          <div className="flex flex-wrap gap-2">
            {SEASONS.map((s) => (
              <Chip key={s} label={s} active={seasons.includes(s)} onToggle={() => toggle("seasons", s)} />
            ))}
          </div>
        </Field>

        {/* Occasions */}
        <Field label="Ocasiones">
          <div className="flex flex-wrap gap-2">
            {OCCASIONS.map((o) => (
              <Chip key={o} label={o} active={occasions.includes(o)} onToggle={() => toggle("occasions", o)} />
            ))}
          </div>
        </Field>

        {/* Notes */}
        <Field label="Notas">
          <textarea
            {...register("notes")}
            rows={3}
            className="w-full px-3 py-2.5 rounded-lg border border-[rgba(28,26,24,0.10)] bg-ivory text-warm-black text-sm font-sans focus:border-gold focus:outline-none transition-colors resize-none"
            placeholder="Notas adicionales..."
          />
        </Field>

        <button
          type="submit"
          disabled={isPending}
          className="w-full h-12 bg-warm-black text-ivory rounded-lg font-sans font-medium text-sm hover:bg-charcoal transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
        >
          {isPending ? <><Loader2 size={16} className="animate-spin" /> Guardando...</> : "Guardar cambios"}
        </button>
      </form>
    </Sheet>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <label className="text-xs text-stone font-sans uppercase tracking-wider mb-1.5 block">{label}</label>
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
        "h-8 px-3 rounded-full text-xs font-sans transition-all duration-200",
        active
          ? "bg-warm-black text-ivory"
          : "border border-[rgba(28,26,24,0.12)] text-warm-black hover:border-warm-black"
      )}
    >
      {label}
    </button>
  );
}

const inputCls =
  "w-full h-11 px-3 rounded-lg border border-[rgba(28,26,24,0.10)] bg-ivory text-warm-black text-sm font-sans focus:border-gold focus:outline-none transition-colors";
