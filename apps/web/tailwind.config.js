/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}", "./lib/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        // Primary backgrounds
        ivory: "#FAF8F5",
        cream: "#F5F0E8",
        "warm-bg": "#EDE7DC",
        // Text
        "warm-black": "#1C1A18",
        charcoal: "#3D3935",
        stone: "#8A857F",
        // Accents
        gold: "#D4AF82",
        "gold-dark": "#9E7B5A",
        blush: "#E8D5C4",
        mauve: "#C9A99A",
        taupe: "#B8A99A",
        // Semantic
        "success-sage": "#7A9E7E",
        "warning-amber": "#C4924A",
        "error-blush": "#C47A7A",
        "info-lavender": "#9A9EC4",
      },
      fontFamily: {
        serif: ["var(--font-cormorant)", "Georgia", "serif"],
        sans: ["var(--font-inter)", "-apple-system", "BlinkMacSystemFont", "sans-serif"],
      },
      boxShadow: {
        xs: "0 1px 2px rgba(28, 26, 24, 0.04)",
        sm: "0 2px 8px rgba(28, 26, 24, 0.06), 0 1px 2px rgba(28, 26, 24, 0.04)",
        md: "0 4px 16px rgba(28, 26, 24, 0.08), 0 2px 4px rgba(28, 26, 24, 0.04)",
        lg: "0 8px 32px rgba(28, 26, 24, 0.10), 0 4px 8px rgba(28, 26, 24, 0.06)",
        xl: "0 16px 48px rgba(28, 26, 24, 0.12), 0 8px 16px rgba(28, 26, 24, 0.08)",
        "gold-glow": "0 0 24px rgba(212, 175, 130, 0.20)",
      },
      borderRadius: {
        xs: "4px",
        sm: "8px",
        md: "12px",
        lg: "16px",
        xl: "20px",
        "2xl": "24px",
        "3xl": "32px",
      },
      transitionDuration: {
        250: "250ms",
        350: "350ms",
        400: "400ms",
        600: "600ms",
        800: "800ms",
      },
      transitionTimingFunction: {
        "out-soft": "cubic-bezier(0.0, 0.0, 0.2, 1.0)",
        spring: "cubic-bezier(0.34, 1.56, 0.64, 1.0)",
        premium: "cubic-bezier(0.16, 1.0, 0.3, 1.0)",
        silky: "cubic-bezier(0.25, 0.46, 0.45, 0.94)",
      },
      animation: {
        shimmer: "shimmer 1.4s infinite",
        "fade-in": "fadeIn 0.4s ease-out-soft",
        "slide-up": "slideUp 0.4s ease-out-soft",
      },
      keyframes: {
        shimmer: {
          "0%": { backgroundPosition: "-200% 0" },
          "100%": { backgroundPosition: "200% 0" },
        },
        fadeIn: {
          from: { opacity: "0" },
          to: { opacity: "1" },
        },
        slideUp: {
          from: { opacity: "0", transform: "translateY(8px)" },
          to: { opacity: "1", transform: "translateY(0)" },
        },
      },
      spacing: {
        18: "72px",
        22: "88px",
      },
    },
  },
  plugins: [],
};
