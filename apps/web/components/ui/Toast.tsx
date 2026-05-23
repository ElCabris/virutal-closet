"use client";

import { useEffect } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { CheckCircle, XCircle, Info, X } from "lucide-react";
import { useToastStore, type ToastVariant } from "@/lib/hooks/useToast";
import { cn } from "@/lib/utils/cn";

const icons: Record<ToastVariant, React.ReactNode> = {
  success: <CheckCircle size={16} className="text-success-sage shrink-0" />,
  error:   <XCircle size={16} className="text-error-blush shrink-0" />,
  info:    <Info size={16} className="text-info-lavender shrink-0" />,
};

export function ToastProvider() {
  const { toasts, dismiss } = useToastStore();

  return (
    <div
      aria-live="polite"
      className="fixed bottom-6 right-6 z-[100] flex flex-col gap-2 pointer-events-none"
    >
      <AnimatePresence mode="popLayout">
        {toasts.map((t) => (
          <motion.div
            key={t.id}
            initial={{ opacity: 0, y: 12, scale: 0.96 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -8, scale: 0.96 }}
            transition={{ duration: 0.25, ease: [0.16, 1, 0.3, 1] }}
            className={cn(
              "pointer-events-auto flex items-center gap-3 px-4 py-3 rounded-lg shadow-lg",
              "bg-white border border-[rgba(28,26,24,0.08)] max-w-xs"
            )}
          >
            {icons[t.variant]}
            <p className="text-warm-black text-sm font-sans flex-1 leading-snug">{t.message}</p>
            <button
              onClick={() => dismiss(t.id)}
              className="text-stone hover:text-warm-black transition-colors"
              aria-label="Cerrar"
            >
              <X size={14} />
            </button>
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  );
}
