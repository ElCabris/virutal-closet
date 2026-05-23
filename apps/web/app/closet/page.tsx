"use client";

import { useEffect, useState } from "react";
import { useInfiniteQuery } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { Plus, SlidersHorizontal } from "lucide-react";
import { useAuthStore } from "@/lib/stores/authStore";
import { api } from "@/lib/api/client";
import { Sidebar } from "@/components/layout/Sidebar";
import { GarmentCard } from "@/components/features/closet/GarmentCard";
import { AddGarmentModal } from "@/components/features/closet/AddGarmentModal";
import type { PaginatedGarments } from "@/lib/types";

const CATEGORIES = [
  { id: "", label: "Todo" },
  { id: "tops", label: "Tops" },
  { id: "bottoms", label: "Bottoms" },
  { id: "dresses", label: "Vestidos" },
  { id: "outerwear", label: "Outerwear" },
  { id: "shoes", label: "Zapatos" },
  { id: "bags", label: "Bolsos" },
  { id: "accessories", label: "Accesorios" },
];

const SORTS = [
  { id: "recent", label: "Recientes" },
  { id: "most_worn", label: "Más usadas" },
  { id: "least_worn", label: "Menos usadas" },
  { id: "az", label: "A–Z" },
];

export default function ClosetPage() {
  const { isAuthenticated } = useAuthStore();
  const router = useRouter();
  const [activeCategory, setActiveCategory] = useState("");
  const [sort, setSort] = useState("recent");
  const [addOpen, setAddOpen] = useState(false);

  useEffect(() => {
    if (!isAuthenticated()) router.push("/login");
  }, [isAuthenticated, router]);

  const {
    data,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
    isLoading,
  } = useInfiniteQuery<PaginatedGarments>({
    queryKey: ["garments", activeCategory, sort],
    queryFn: ({ pageParam = 1 }) => {
      const params = new URLSearchParams({
        page: String(pageParam),
        page_size: "24",
        sort,
      });
      if (activeCategory) params.set("category", activeCategory);
      return api.get<PaginatedGarments>(`/garments?${params}`).then((r) => r.data);
    },
    getNextPageParam: (last) => (last.has_next ? last.page + 1 : undefined),
    initialPageParam: 1,
    enabled: isAuthenticated(),
  });

  const garments = data?.pages.flatMap((p) => p.items) ?? [];
  const total = data?.pages[0]?.total ?? 0;

  return (
    <div className="flex min-h-screen bg-ivory">
      <Sidebar active="closet" />

      <main className="flex-1 md:ml-64 px-5 md:px-10 py-8 pb-24 md:pb-8">
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div>
            <h1 className="font-serif text-4xl text-warm-black font-light">Mi Closet</h1>
            {total > 0 && (
              <p className="text-stone text-xs font-sans mt-1">
                {total} {total === 1 ? "prenda" : "prendas"}
              </p>
            )}
          </div>
          <button
            onClick={() => setAddOpen(true)}
            className="flex items-center gap-2 h-10 px-5 bg-warm-black text-ivory rounded-lg font-sans text-sm font-medium hover:bg-charcoal transition-colors"
          >
            <Plus size={16} />
            Agregar
          </button>
        </div>

        {/* Category filters */}
        <div className="flex gap-2 overflow-x-auto pb-2 mb-4 scrollbar-none -mx-1 px-1">
          {CATEGORIES.map((cat) => (
            <button
              key={cat.id}
              onClick={() => setActiveCategory(cat.id)}
              className={`flex-shrink-0 h-9 px-4 rounded-full font-sans text-sm transition-all duration-200 ${
                activeCategory === cat.id
                  ? "bg-warm-black text-ivory"
                  : "bg-white text-warm-black border border-[rgba(28,26,24,0.10)] hover:border-[rgba(28,26,24,0.20)]"
              }`}
            >
              {cat.label}
            </button>
          ))}
        </div>

        {/* Sort */}
        <div className="flex items-center gap-3 mb-6">
          <SlidersHorizontal size={14} className="text-stone" />
          <div className="flex gap-2">
            {SORTS.map((s) => (
              <button
                key={s.id}
                onClick={() => setSort(s.id)}
                className={`text-xs font-sans px-3 h-7 rounded-full transition-all ${
                  sort === s.id
                    ? "bg-cream text-warm-black font-medium"
                    : "text-stone hover:text-warm-black"
                }`}
              >
                {s.label}
              </button>
            ))}
          </div>
        </div>

        {/* Grid */}
        {isLoading ? (
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3">
            {Array.from({ length: 12 }).map((_, i) => (
              <div key={i} className="aspect-[5/7] rounded-lg skeleton" />
            ))}
          </div>
        ) : garments.length > 0 ? (
          <>
            <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3">
              {garments.map((g) => (
                <GarmentCard
                  key={g.id}
                  garment={g}
                  onClick={() => router.push(`/closet/${g.id}`)}
                />
              ))}
            </div>
            {hasNextPage && (
              <div className="flex justify-center mt-8">
                <button
                  onClick={() => fetchNextPage()}
                  disabled={isFetchingNextPage}
                  className="h-10 px-8 border border-[rgba(28,26,24,0.10)] rounded-full text-sm font-sans text-warm-black hover:bg-cream transition-colors disabled:opacity-50"
                >
                  {isFetchingNextPage ? "Cargando..." : "Ver más"}
                </button>
              </div>
            )}
          </>
        ) : (
          <div className="flex flex-col items-center justify-center py-24 text-center">
            <p className="font-serif text-3xl text-warm-black mb-3">Tu historia comienza aquí.</p>
            <p className="text-stone text-sm font-sans mb-8 max-w-sm">
              Agrega tu primera prenda y deja que Crayoli aprenda tu lenguaje.
            </p>
            <button
              onClick={() => setAddOpen(true)}
              className="px-8 py-3 bg-warm-black text-ivory rounded-lg font-sans text-sm font-medium hover:bg-charcoal transition-colors"
            >
              Agregar una prenda
            </button>
          </div>
        )}
      </main>

      <AddGarmentModal
        open={addOpen}
        onClose={() => setAddOpen(false)}
        onCreated={(g) => router.push(`/closet/${g.id}`)}
      />
    </div>
  );
}
