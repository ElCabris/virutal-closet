"use client";

import { useEffect, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { useAuthStore } from "@/lib/stores/authStore";
import { api } from "@/lib/api/client";
import { Sidebar } from "@/components/layout/Sidebar";
import type { Garment, PaginatedGarments } from "@/lib/types";

const WEEKDAYS = ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"];
const MONTHS = [
  "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
  "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre",
];

function getDaysInMonth(year: number, month: number) {
  return new Date(year, month + 1, 0).getDate();
}
function getFirstDayOfMonth(year: number, month: number) {
  return new Date(year, month, 1).getDay();
}

export default function CalendarPage() {
  const { isAuthenticated } = useAuthStore();
  const router = useRouter();
  const today = new Date();
  const [current, setCurrent] = useState({ year: today.getFullYear(), month: today.getMonth() });
  const [selected, setSelected] = useState<number | null>(today.getDate());

  useEffect(() => {
    if (!isAuthenticated()) router.push("/login");
  }, [isAuthenticated, router]);

  const { data } = useQuery<PaginatedGarments>({
    queryKey: ["garments-worn"],
    queryFn: () =>
      api.get<PaginatedGarments>("/garments?sort=most_worn&page_size=50").then((r) => r.data),
    enabled: isAuthenticated(),
  });

  // Build wear map: date string → garments
  const wearMap = buildWearMap(data?.items || []);

  const daysInMonth = getDaysInMonth(current.year, current.month);
  const firstDay = getFirstDayOfMonth(current.year, current.month);

  const prev = () => setCurrent((c) => c.month === 0 ? { year: c.year - 1, month: 11 } : { ...c, month: c.month - 1 });
  const next = () => setCurrent((c) => c.month === 11 ? { year: c.year + 1, month: 0 } : { ...c, month: c.month + 1 });

  const selectedDate = selected
    ? `${current.year}-${String(current.month + 1).padStart(2, "0")}-${String(selected).padStart(2, "0")}`
    : null;
  const selectedGarments = selectedDate ? (wearMap[selectedDate] || []) : [];

  return (
    <div className="flex min-h-screen bg-ivory">
      <Sidebar active="calendar" />

      <main className="flex-1 md:ml-64 px-5 md:px-10 py-8 pb-24 md:pb-8 max-w-3xl">
        <h1 className="font-serif text-4xl text-warm-black font-light mb-2">Calendario</h1>
        <p className="text-stone text-sm font-sans mb-8">Tu historia de outfits día a día.</p>

        {/* Month nav */}
        <div className="flex items-center justify-between mb-6">
          <button onClick={prev} className="w-9 h-9 flex items-center justify-center rounded-full hover:bg-cream transition-colors">
            <ChevronLeft size={18} className="text-stone" />
          </button>
          <h2 className="font-serif text-xl text-warm-black">
            {MONTHS[current.month]} {current.year}
          </h2>
          <button onClick={next} className="w-9 h-9 flex items-center justify-center rounded-full hover:bg-cream transition-colors">
            <ChevronRight size={18} className="text-stone" />
          </button>
        </div>

        {/* Weekday headers */}
        <div className="grid grid-cols-7 mb-2">
          {WEEKDAYS.map((d) => (
            <div key={d} className="text-center text-[10px] font-sans text-stone uppercase tracking-wider py-1">
              {d}
            </div>
          ))}
        </div>

        {/* Calendar grid */}
        <div className="grid grid-cols-7 gap-1 mb-8">
          {Array.from({ length: firstDay }).map((_, i) => <div key={`e-${i}`} />)}
          {Array.from({ length: daysInMonth }).map((_, i) => {
            const day = i + 1;
            const dateKey = `${current.year}-${String(current.month + 1).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
            const hasWear = wearMap[dateKey]?.length > 0;
            const isToday = day === today.getDate() && current.month === today.getMonth() && current.year === today.getFullYear();
            const isSelected = day === selected;

            return (
              <button
                key={day}
                onClick={() => setSelected(day)}
                className={`
                  relative aspect-square flex flex-col items-center justify-center rounded-lg text-sm font-sans transition-all duration-150
                  ${isSelected ? "bg-warm-black text-ivory" : isToday ? "bg-cream text-warm-black font-medium" : "hover:bg-cream text-warm-black"}
                `}
              >
                {day}
                {hasWear && (
                  <div className={`absolute bottom-1 w-1 h-1 rounded-full ${isSelected ? "bg-ivory" : "bg-gold"}`} />
                )}
              </button>
            );
          })}
        </div>

        {/* Selected day detail */}
        {selected && (
          <section>
            <p className="text-xs text-stone tracking-[0.12em] uppercase font-sans mb-4">
              {String(selected).padStart(2, "0")} {MONTHS[current.month]}
            </p>

            {selectedGarments.length > 0 ? (
              <div className="grid grid-cols-3 md:grid-cols-4 gap-2">
                {selectedGarments.map((g) => (
                  <button
                    key={g.id}
                    onClick={() => router.push(`/closet/${g.id}`)}
                    className="group relative aspect-[5/7] rounded-xl overflow-hidden"
                    style={{ backgroundColor: g.dominant_color || "#F5F0E8" }}
                  >
                    {g.image_url_thumb && (
                      <img
                        src={g.image_url_thumb}
                        alt={g.name || ""}
                        className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                      />
                    )}
                    <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-warm-black/60 to-transparent p-2 opacity-0 group-hover:opacity-100 transition-opacity">
                      <p className="text-ivory text-[10px] font-sans truncate">{g.name || g.category}</p>
                    </div>
                  </button>
                ))}
              </div>
            ) : (
              <div className="text-center py-12 bg-white rounded-xl border border-[rgba(28,26,24,0.06)]">
                <p className="font-serif text-xl text-warm-black mb-2">Sin registros</p>
                <p className="text-stone text-sm font-sans">
                  Ve a tu closet y usa "Usar hoy" en una prenda para registrarla aquí.
                </p>
              </div>
            )}
          </section>
        )}
      </main>
    </div>
  );
}

function buildWearMap(garments: Garment[]): Record<string, Garment[]> {
  const map: Record<string, Garment[]> = {};
  for (const g of garments) {
    if (g.last_worn_at) {
      const key = g.last_worn_at.split("T")[0];
      map[key] = map[key] || [];
      map[key].push(g);
    }
  }
  return map;
}
