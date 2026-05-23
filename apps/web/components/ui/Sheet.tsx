"use client";

import { useEffect, useRef } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { X } from "lucide-react";
import { cn } from "@/lib/utils/cn";

interface SheetProps {
  open: boolean;
  onClose: () => void;
  title?: string;
  children: React.ReactNode;
  side?: "right" | "bottom";
  size?: "sm" | "md" | "lg";
}

export function Sheet({ open, onClose, title, children, side = "right", size = "md" }: SheetProps) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && onClose();
    document.addEventListener("keydown", onKey);
    return () => document.removeEventListener("keydown", onKey);
  }, [open, onClose]);

  useEffect(() => {
    document.body.style.overflow = open ? "hidden" : "";
    return () => { document.body.style.overflow = ""; };
  }, [open]);

  const widthClass = { sm: "max-w-sm", md: "max-w-md", lg: "max-w-lg" }[size];

  return (
    <AnimatePresence>
      {open && (
        <>
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
            className="fixed inset-0 z-40 bg-warm-black/20 backdrop-blur-sm"
            onClick={onClose}
            aria-hidden
          />

          {/* Panel */}
          <motion.div
            ref={ref}
            role="dialog"
            aria-modal
            initial={side === "right" ? { x: "100%" } : { y: "100%" }}
            animate={side === "right" ? { x: 0 } : { y: 0 }}
            exit={side === "right" ? { x: "100%" } : { y: "100%" }}
            transition={{ duration: 0.35, ease: [0.16, 1, 0.3, 1] }}
            className={cn(
              "fixed z-50 bg-white shadow-xl overflow-y-auto",
              side === "right"
                ? `top-0 right-0 h-full w-full ${widthClass}`
                : "bottom-0 left-0 right-0 rounded-t-2xl max-h-[92dvh]"
            )}
          >
            {/* Header */}
            <div className="flex items-center justify-between px-6 py-5 border-b border-[rgba(28,26,24,0.06)] sticky top-0 bg-white z-10">
              {title && (
                <h2 className="font-serif text-xl text-warm-black">{title}</h2>
              )}
              <button
                onClick={onClose}
                className="ml-auto w-8 h-8 flex items-center justify-center rounded-full hover:bg-cream transition-colors text-stone hover:text-warm-black"
                aria-label="Cerrar"
              >
                <X size={18} />
              </button>
            </div>
            <div className="px-6 py-6">{children}</div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}
