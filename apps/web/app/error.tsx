"use client";

import { useEffect } from "react";
import { RefreshCw } from "lucide-react";

interface Props {
  error: Error & { digest?: string };
  reset: () => void;
}

export default function GlobalError({ error, reset }: Props) {
  useEffect(() => {
    console.error("[Crayoli Error]", error);
  }, [error]);

  return (
    <div className="min-h-screen bg-ivory flex flex-col items-center justify-center px-6 text-center">
      <p className="text-stone text-xs font-sans uppercase tracking-widest mb-4">Error</p>
      <h1 className="font-serif text-4xl text-warm-black font-light mb-3">
        Algo salió mal.
      </h1>
      <p className="text-stone text-sm font-sans mb-8 max-w-sm">
        Hubo un problema inesperado. No te preocupes, tus datos están seguros.
      </p>
      <button
        onClick={reset}
        className="flex items-center gap-2 h-11 px-6 bg-warm-black text-ivory rounded-lg font-sans text-sm font-medium hover:bg-charcoal transition-colors"
      >
        <RefreshCw size={15} />
        Intentar de nuevo
      </button>
    </div>
  );
}
