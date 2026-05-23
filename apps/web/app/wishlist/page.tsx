"use client";

import { useEffect, useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { Plus, ExternalLink, Check, Trash2, Loader2 } from "lucide-react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useAuthStore } from "@/lib/stores/authStore";
import { api } from "@/lib/api/client";
import { Sidebar } from "@/components/layout/Sidebar";
import { Sheet } from "@/components/ui/Sheet";
import { useToast } from "@/lib/hooks/useToast";
import type { WishlistItem } from "@/lib/types";
import { cn } from "@/lib/utils/cn";

const PRIORITIES = ["low", "medium", "high"];
const PRIORITY_COLORS = { low: "bg-info-lavender/20 text-info-lavender", medium: "bg-warning-amber/20 text-warning-amber", high: "bg-error-blush/20 text-error-blush" };
const PRIORITY_LABELS = { low: "Baja", medium: "Media", high: "Alta" };

const schema = z.object({
  name: z.string().min(1, "Requerido"),
  brand: z.string().optional(),
  category: z.string().optional(),
  product_url: z.string().url("URL inválida").optional().or(z.literal("")),
  target_price: z.string().optional(),
  current_price: z.string().optional(),
  priority: z.string().default("medium"),
  notes: z.string().optional(),
});
type FormData = z.infer<typeof schema>;

export default function WishlistPage() {
  const { isAuthenticated } = useAuthStore();
  const router = useRouter();
  const toast = useToast();
  const queryClient = useQueryClient();
  const [addOpen, setAddOpen] = useState(false);

  useEffect(() => {
    if (!isAuthenticated()) router.push("/login");
  }, [isAuthenticated, router]);

  const { data: items, isLoading } = useQuery<WishlistItem[]>({
    queryKey: ["wishlist"],
    queryFn: () => api.get<WishlistItem[]>("/wishlist").then((r) => r.data),
    enabled: isAuthenticated(),
  });

  const { mutate: removeItem } = useMutation({
    mutationFn: (id: string) => api.delete(`/wishlist/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["wishlist"] });
      toast.success("Eliminado de la wishlist");
    },
  });

  const { mutate: markPurchased } = useMutation({
    mutationFn: (id: string) => api.patch(`/wishlist/${id}`, { is_purchased: true }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["wishlist"] });
      toast.success("¡Marcada como comprada!");
    },
  });

  const active = items?.filter((i) => !i.is_purchased) || [];
  const purchased = items?.filter((i) => i.is_purchased) || [];

  return (
    <div className="flex min-h-screen bg-ivory">
      <Sidebar active="wishlist" />

      <main className="flex-1 md:ml-64 px-5 md:px-10 py-8 pb-24 md:pb-8 max-w-3xl">
        <div className="flex items-center justify-between mb-2">
          <h1 className="font-serif text-4xl text-warm-black font-light">Wishlist</h1>
          <button
            onClick={() => setAddOpen(true)}
            className="flex items-center gap-2 h-10 px-5 bg-warm-black text-ivory rounded-lg font-sans text-sm font-medium hover:bg-charcoal transition-colors"
          >
            <Plus size={16} />
            Agregar
          </button>
        </div>
        <p className="text-stone text-sm font-sans mb-8">Las prendas que quieres, organizadas.</p>

        {isLoading ? (
          <div className="space-y-3 animate-pulse">
            {Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className="h-24 bg-cream rounded-xl" />
            ))}
          </div>
        ) : (
          <>
            {active.length === 0 && purchased.length === 0 ? (
              <div className="text-center py-24">
                <p className="font-serif text-2xl text-warm-black mb-2">Tu wishlist está vacía</p>
                <p className="text-stone text-sm font-sans mb-6">Agrega las prendas que deseas comprar.</p>
                <button
                  onClick={() => setAddOpen(true)}
                  className="px-6 py-3 bg-warm-black text-ivory rounded-lg font-sans text-sm font-medium hover:bg-charcoal transition-colors"
                >
                  Agregar prenda
                </button>
              </div>
            ) : (
              <div className="space-y-8">
                {active.length > 0 && (
                  <section>
                    <p className="text-xs text-stone tracking-[0.12em] uppercase mb-4 font-sans">
                      Pendientes ({active.length})
                    </p>
                    <div className="space-y-2">
                      {active.map((item) => (
                        <WishlistCard
                          key={item.id}
                          item={item}
                          onPurchase={() => markPurchased(item.id)}
                          onDelete={() => removeItem(item.id)}
                        />
                      ))}
                    </div>
                  </section>
                )}
                {purchased.length > 0 && (
                  <section>
                    <p className="text-xs text-stone tracking-[0.12em] uppercase mb-4 font-sans">
                      Compradas ({purchased.length})
                    </p>
                    <div className="space-y-2 opacity-60">
                      {purchased.map((item) => (
                        <WishlistCard
                          key={item.id}
                          item={item}
                          onDelete={() => removeItem(item.id)}
                        />
                      ))}
                    </div>
                  </section>
                )}
              </div>
            )}
          </>
        )}
      </main>

      <AddWishlistSheet
        open={addOpen}
        onClose={() => setAddOpen(false)}
        onAdded={() => queryClient.invalidateQueries({ queryKey: ["wishlist"] })}
      />
    </div>
  );
}

function WishlistCard({ item, onPurchase, onDelete }: { item: WishlistItem; onPurchase?: () => void; onDelete: () => void }) {
  return (
    <div className="flex items-center gap-4 p-4 bg-white rounded-xl border border-[rgba(28,26,24,0.06)]">
      {item.image_url ? (
        <div className="w-12 h-16 rounded-lg overflow-hidden shrink-0">
          <img src={item.image_url} alt="" className="w-full h-full object-cover" />
        </div>
      ) : (
        <div className="w-12 h-16 rounded-lg bg-cream shrink-0 flex items-center justify-center">
          <span className="text-stone text-xs font-sans">{item.category?.slice(0, 1).toUpperCase() || "?"}</span>
        </div>
      )}

      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2 mb-0.5">
          <p className={cn("text-sm font-sans font-medium truncate", item.is_purchased ? "line-through text-stone" : "text-warm-black")}>
            {item.name}
          </p>
          <span className={cn("text-[10px] font-sans px-2 py-0.5 rounded-full shrink-0", PRIORITY_COLORS[item.priority as keyof typeof PRIORITY_COLORS] || "")}>
            {PRIORITY_LABELS[item.priority as keyof typeof PRIORITY_LABELS]}
          </span>
        </div>
        {item.brand && <p className="text-xs text-stone font-sans">{item.brand}</p>}
        {(item.target_price || item.current_price) && (
          <p className="text-xs text-charcoal font-sans mt-1">
            {item.current_price ? `$${Number(item.current_price).toFixed(2)}` : ""}
            {item.target_price ? ` · objetivo $${Number(item.target_price).toFixed(2)}` : ""}
          </p>
        )}
      </div>

      <div className="flex items-center gap-1 shrink-0">
        {item.product_url && (
          <a
            href={item.product_url}
            target="_blank"
            rel="noopener noreferrer"
            className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-cream transition-colors"
          >
            <ExternalLink size={14} className="text-stone" />
          </a>
        )}
        {!item.is_purchased && onPurchase && (
          <button
            onClick={onPurchase}
            className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-[rgba(122,158,126,0.12)] transition-colors"
            aria-label="Marcar como comprada"
          >
            <Check size={14} className="text-success-sage" />
          </button>
        )}
        <button
          onClick={onDelete}
          className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-[rgba(196,122,122,0.08)] transition-colors"
          aria-label="Eliminar"
        >
          <Trash2 size={14} className="text-stone hover:text-error-blush" />
        </button>
      </div>
    </div>
  );
}

function AddWishlistSheet({ open, onClose, onAdded }: { open: boolean; onClose: () => void; onAdded: () => void }) {
  const toast = useToast();
  const { register, handleSubmit, reset, watch, setValue, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: { priority: "medium" },
  });
  const priority = watch("priority");

  const { mutate, isPending } = useMutation({
    mutationFn: (data: FormData) =>
      api.post("/wishlist", {
        ...data,
        product_url: data.product_url || null,
        target_price: data.target_price ? parseFloat(data.target_price) : null,
        current_price: data.current_price ? parseFloat(data.current_price) : null,
      }),
    onSuccess: () => {
      toast.success("Agregado a tu wishlist");
      reset();
      onAdded();
      onClose();
    },
    onError: () => toast.error("Error al agregar"),
  });

  return (
    <Sheet open={open} onClose={onClose} title="Agregar a wishlist" side="right" size="md">
      <form onSubmit={handleSubmit((d) => mutate(d))} className="space-y-5">
        <div>
          <label className="label-xs">Nombre *</label>
          <input {...register("name")} className={inputCls} placeholder="Ej. Blazer de lana" />
          {errors.name && <p className="text-error-blush text-xs mt-1">{errors.name.message}</p>}
        </div>
        <div>
          <label className="label-xs">Marca</label>
          <input {...register("brand")} className={inputCls} placeholder="Marca" />
        </div>
        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="label-xs">Precio actual</label>
            <input {...register("current_price")} type="number" step="0.01" className={inputCls} placeholder="0.00" />
          </div>
          <div>
            <label className="label-xs">Precio objetivo</label>
            <input {...register("target_price")} type="number" step="0.01" className={inputCls} placeholder="0.00" />
          </div>
        </div>
        <div>
          <label className="label-xs">URL del producto</label>
          <input {...register("product_url")} className={inputCls} placeholder="https://..." />
          {errors.product_url && <p className="text-error-blush text-xs mt-1">{errors.product_url.message}</p>}
        </div>
        <div>
          <label className="label-xs">Prioridad</label>
          <div className="flex gap-2">
            {PRIORITIES.map((p) => (
              <button
                key={p}
                type="button"
                onClick={() => setValue("priority", p)}
                className={cn(
                  "flex-1 h-9 rounded-lg text-xs font-sans border transition-all",
                  priority === p
                    ? "bg-warm-black text-ivory border-warm-black"
                    : "border-[rgba(28,26,24,0.12)] text-stone hover:border-warm-black"
                )}
              >
                {PRIORITY_LABELS[p as keyof typeof PRIORITY_LABELS]}
              </button>
            ))}
          </div>
        </div>
        <div>
          <label className="label-xs">Notas</label>
          <textarea {...register("notes")} rows={2} className="w-full px-3 py-2.5 rounded-lg border border-[rgba(28,26,24,0.10)] bg-ivory text-warm-black text-sm font-sans focus:border-gold focus:outline-none transition-colors resize-none" />
        </div>
        <button type="submit" disabled={isPending} className="w-full h-12 bg-warm-black text-ivory rounded-lg font-sans font-medium text-sm hover:bg-charcoal transition-colors disabled:opacity-50 flex items-center justify-center gap-2">
          {isPending ? <><Loader2 size={16} className="animate-spin" />Guardando...</> : "Agregar a wishlist"}
        </button>
      </form>
    </Sheet>
  );
}

const inputCls = "w-full h-11 px-3 rounded-lg border border-[rgba(28,26,24,0.10)] bg-ivory text-warm-black text-sm font-sans focus:border-gold focus:outline-none transition-colors";
