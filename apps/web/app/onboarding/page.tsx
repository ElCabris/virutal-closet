"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useMutation } from "@tanstack/react-query";
import { motion, AnimatePresence } from "framer-motion";
import { ArrowRight, ArrowLeft, Loader2 } from "lucide-react";
import { api } from "@/lib/api/client";
import { cn } from "@/lib/utils/cn";

const STEPS = [
  {
    id: "vibes",
    title: "¿Cuál es tu estilo?",
    subtitle: "Selecciona todos los que te representen.",
    multi: true,
    options: [
      { id: "minimal", label: "Minimal", emoji: "◾" },
      { id: "classic", label: "Clásico", emoji: "🏛" },
      { id: "romantic", label: "Romántico", emoji: "🌸" },
      { id: "streetwear", label: "Streetwear", emoji: "🧢" },
      { id: "sporty", label: "Deportivo", emoji: "⚡" },
      { id: "boho", label: "Bohemio", emoji: "🌿" },
      { id: "eclectic", label: "Ecléctico", emoji: "🎭" },
      { id: "preppy", label: "Preppy", emoji: "📚" },
    ],
  },
  {
    id: "colors",
    title: "¿Qué paleta te define?",
    subtitle: "Tu closet en colores.",
    multi: true,
    options: [
      { id: "neutrals", label: "Neutros", emoji: "🤍" },
      { id: "earth", label: "Tierra", emoji: "🌱" },
      { id: "bold", label: "Colores vivos", emoji: "🎨" },
      { id: "monochrome", label: "Monocromático", emoji: "🖤" },
      { id: "pastels", label: "Pasteles", emoji: "🍦" },
      { id: "jewel", label: "Joya", emoji: "💎" },
    ],
  },
  {
    id: "climate",
    title: "¿Dónde vives?",
    subtitle: "Tu clima habitual define muchas elecciones.",
    multi: false,
    options: [
      { id: "tropical", label: "Tropical", emoji: "🌴" },
      { id: "temperate", label: "Templado", emoji: "🌤" },
      { id: "cold", label: "Frío", emoji: "❄️" },
      { id: "variable", label: "Variable", emoji: "🌈" },
    ],
  },
];

export default function OnboardingPage() {
  const router = useRouter();
  const [step, setStep] = useState(0);
  const [selections, setSelections] = useState<Record<string, string | string[]>>({});

  const current = STEPS[step];

  const toggle = (optionId: string) => {
    if (current.multi) {
      const prev = (selections[current.id] as string[]) || [];
      const next = prev.includes(optionId) ? prev.filter((v) => v !== optionId) : [...prev, optionId];
      setSelections((s) => ({ ...s, [current.id]: next }));
    } else {
      setSelections((s) => ({ ...s, [current.id]: optionId }));
    }
  };

  const isSelected = (optionId: string) => {
    const val = selections[current.id];
    return Array.isArray(val) ? val.includes(optionId) : val === optionId;
  };

  const canContinue = current.multi
    ? ((selections[current.id] as string[]) || []).length > 0
    : !!selections[current.id];

  const { mutate: finish, isPending } = useMutation({
    mutationFn: () =>
      api.put("/profile/style", {
        style_vibes: selections["vibes"] || [],
        color_palette_pref: selections["colors"] || [],
        climate: selections["climate"] || null,
        onboarding_completed: true,
      }),
    onSuccess: () => router.push("/home"),
  });

  const handleNext = () => {
    if (step < STEPS.length - 1) {
      setStep((s) => s + 1);
    } else {
      finish();
    }
  };

  const progress = ((step + 1) / STEPS.length) * 100;

  return (
    <div className="min-h-screen bg-ivory flex flex-col">
      {/* Progress */}
      <div className="h-0.5 bg-cream">
        <motion.div
          className="h-full bg-gold"
          animate={{ width: `${progress}%` }}
          transition={{ duration: 0.4, ease: "easeOut" }}
        />
      </div>

      <div className="flex-1 flex flex-col items-center justify-center px-6 py-12">
        {/* Logo */}
        <div className="mb-12 text-center">
          <h1 className="font-serif text-2xl tracking-[0.25em] text-warm-black uppercase font-light">
            Crayoli
          </h1>
        </div>

        <AnimatePresence mode="wait">
          <motion.div
            key={step}
            initial={{ opacity: 0, x: 24 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -24 }}
            transition={{ duration: 0.3, ease: [0.16, 1, 0.3, 1] }}
            className="w-full max-w-lg"
          >
            <p className="text-stone text-xs font-sans uppercase tracking-widest mb-3">
              {step + 1} / {STEPS.length}
            </p>
            <h2 className="font-serif text-4xl text-warm-black font-light mb-2 leading-tight">
              {current.title}
            </h2>
            <p className="text-stone text-sm font-sans mb-10">{current.subtitle}</p>

            <div className="grid grid-cols-2 gap-3">
              {current.options.map((opt) => (
                <button
                  key={opt.id}
                  onClick={() => toggle(opt.id)}
                  className={cn(
                    "flex items-center gap-3 px-5 py-4 rounded-xl border-2 text-left transition-all duration-200",
                    isSelected(opt.id)
                      ? "border-warm-black bg-warm-black text-ivory"
                      : "border-[rgba(28,26,24,0.10)] bg-white hover:border-warm-black"
                  )}
                >
                  <span className="text-xl">{opt.emoji}</span>
                  <span className={cn("font-sans text-sm", isSelected(opt.id) ? "text-ivory" : "text-warm-black")}>
                    {opt.label}
                  </span>
                </button>
              ))}
            </div>
          </motion.div>
        </AnimatePresence>

        {/* Navigation */}
        <div className="flex items-center gap-4 mt-12 w-full max-w-lg">
          {step > 0 && (
            <button
              onClick={() => setStep((s) => s - 1)}
              className="w-12 h-12 border border-[rgba(28,26,24,0.10)] rounded-full flex items-center justify-center hover:bg-cream transition-colors"
            >
              <ArrowLeft size={18} className="text-stone" />
            </button>
          )}
          <button
            onClick={handleNext}
            disabled={!canContinue || isPending}
            className="flex-1 h-12 bg-warm-black text-ivory rounded-full font-sans font-medium text-sm hover:bg-charcoal transition-colors disabled:opacity-40 flex items-center justify-center gap-2"
          >
            {isPending ? (
              <><Loader2 size={16} className="animate-spin" />Listo...</>
            ) : step === STEPS.length - 1 ? (
              "Comenzar →"
            ) : (
              <>Continuar <ArrowRight size={16} /></>
            )}
          </button>
        </div>

        <button
          onClick={() => router.push("/home")}
          className="mt-6 text-stone text-sm font-sans hover:text-warm-black transition-colors"
        >
          Saltar por ahora
        </button>
      </div>
    </div>
  );
}
