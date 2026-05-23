"use client";

import { useEffect } from "react";
import { useQuery } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { TrendingUp, Heart, Package, DollarSign } from "lucide-react";
import { useAuthStore } from "@/lib/stores/authStore";
import { api } from "@/lib/api/client";
import { Sidebar } from "@/components/layout/Sidebar";
import type { AnalyticsSummary, GarmentStat } from "@/lib/types";

export default function AnalyticsPage() {
  const { isAuthenticated } = useAuthStore();
  const router = useRouter();

  useEffect(() => {
    if (!isAuthenticated()) router.push("/login");
  }, [isAuthenticated, router]);

  const { data, isLoading } = useQuery<AnalyticsSummary>({
    queryKey: ["analytics"],
    queryFn: () => api.get<AnalyticsSummary>("/analytics").then((r) => r.data),
    enabled: isAuthenticated(),
  });

  return (
    <div className="flex min-h-screen bg-ivory">
      <Sidebar active="analytics" />

      <main className="flex-1 md:ml-64 px-5 md:px-10 py-8 pb-24 md:pb-8 max-w-4xl">
        <h1 className="font-serif text-4xl text-warm-black font-light mb-2">Analytics</h1>
        <p className="text-stone text-sm font-sans mb-10">Tu closet, en números.</p>

        {isLoading ? (
          <AnalyticsSkeleton />
        ) : data ? (
          <div className="space-y-10">
            {/* Summary cards */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
              <SummaryCard
                icon={<Package size={18} className="text-stone" />}
                label="Prendas"
                value={String(data.total_garments)}
              />
              <SummaryCard
                icon={<DollarSign size={18} className="text-stone" />}
                label="Valor total"
                value={`$${Number(data.total_value).toFixed(0)}`}
              />
              <SummaryCard
                icon={<TrendingUp size={18} className="text-stone" />}
                label="Costo/uso prom."
                value={data.avg_cost_per_wear ? `$${Number(data.avg_cost_per_wear).toFixed(2)}` : "—"}
              />
              <SummaryCard
                icon={<Heart size={18} className="text-stone" />}
                label="Favoritas"
                value={String(data.favorite_count)}
              />
            </div>

            {/* Category breakdown */}
            {data.by_category.length > 0 && (
              <section>
                <SectionTitle>Por categoría</SectionTitle>
                <div className="space-y-3">
                  {data.by_category.map((cat) => (
                    <div key={cat.category}>
                      <div className="flex justify-between mb-1">
                        <span className="text-sm font-sans text-warm-black capitalize">{cat.category}</span>
                        <span className="text-sm font-sans text-stone">{cat.count} · {cat.percentage}%</span>
                      </div>
                      <div className="h-1.5 bg-cream rounded-full overflow-hidden">
                        <div
                          className="h-full bg-warm-black rounded-full transition-all duration-700"
                          style={{ width: `${cat.percentage}%` }}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              </section>
            )}

            {/* Most worn */}
            {data.most_worn.length > 0 && (
              <section>
                <SectionTitle>Más usadas</SectionTitle>
                <div className="space-y-2">
                  {data.most_worn.map((g) => (
                    <GarmentStatRow key={g.id} stat={g} onClick={() => router.push(`/closet/${g.id}`)} />
                  ))}
                </div>
              </section>
            )}

            {/* Never worn */}
            {data.never_worn.length > 0 && (
              <section>
                <SectionTitle>Nunca usadas ({data.never_worn.length})</SectionTitle>
                <p className="text-stone text-xs font-sans mb-4">
                  Considera usarlas o donarlas para liberar espacio.
                </p>
                <div className="grid grid-cols-3 md:grid-cols-5 gap-2">
                  {data.never_worn.slice(0, 10).map((g) => (
                    <button
                      key={g.id}
                      onClick={() => router.push(`/closet/${g.id}`)}
                      className="group relative aspect-[5/7] rounded-lg overflow-hidden cursor-pointer"
                      style={{ backgroundColor: g.dominant_color || "#F5F0E8" }}
                    >
                      {g.image_url_thumb && (
                        <img
                          src={g.image_url_thumb}
                          alt=""
                          className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                        />
                      )}
                    </button>
                  ))}
                </div>
              </section>
            )}
          </div>
        ) : (
          <EmptyState />
        )}
      </main>
    </div>
  );
}

function SummaryCard({ icon, label, value }: { icon: React.ReactNode; label: string; value: string }) {
  return (
    <div className="bg-white rounded-xl p-4 border border-[rgba(28,26,24,0.06)]">
      <div className="flex items-center gap-2 mb-3">{icon}<span className="text-xs text-stone font-sans">{label}</span></div>
      <p className="font-serif text-2xl text-warm-black">{value}</p>
    </div>
  );
}

function GarmentStatRow({ stat, onClick }: { stat: GarmentStat; onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      className="w-full flex items-center gap-4 p-3 rounded-xl bg-white border border-[rgba(28,26,24,0.06)] hover:shadow-sm transition-all text-left"
    >
      <div
        className="w-10 h-14 rounded-md shrink-0 overflow-hidden"
        style={{ backgroundColor: stat.dominant_color || "#F5F0E8" }}
      >
        {stat.image_url_thumb && (
          <img src={stat.image_url_thumb} alt="" className="w-full h-full object-cover" />
        )}
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-sm font-sans text-warm-black font-medium truncate">
          {stat.name || stat.category || "Sin nombre"}
        </p>
        <p className="text-xs text-stone font-sans capitalize">{stat.category}</p>
      </div>
      <div className="text-right shrink-0">
        <p className="font-serif text-lg text-warm-black">{stat.wear_count}x</p>
        {stat.cost_per_wear && (
          <p className="text-xs text-stone font-sans">${Number(stat.cost_per_wear).toFixed(2)}/uso</p>
        )}
      </div>
    </button>
  );
}

function SectionTitle({ children }: { children: React.ReactNode }) {
  return (
    <p className="text-xs text-stone tracking-[0.12em] uppercase mb-4 font-sans">{children}</p>
  );
}

function EmptyState() {
  return (
    <div className="text-center py-24">
      <p className="font-serif text-2xl text-warm-black mb-2">Sin datos aún</p>
      <p className="text-stone text-sm font-sans">Agrega prendas a tu closet para ver estadísticas.</p>
    </div>
  );
}

function AnalyticsSkeleton() {
  return (
    <div className="space-y-6 animate-pulse">
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        {Array.from({ length: 4 }).map((_, i) => (
          <div key={i} className="h-24 bg-cream rounded-xl" />
        ))}
      </div>
      <div className="h-40 bg-cream rounded-xl" />
      <div className="h-40 bg-cream rounded-xl" />
    </div>
  );
}
