"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { Home, Shirt, Sparkles, Calendar, BarChart3, Heart, LogOut, User } from "lucide-react";
import { useAuthStore } from "@/lib/stores/authStore";
import { cn } from "@/lib/utils/cn";

const NAV = [
  { href: "/home",      label: "Home",      icon: Home },
  { href: "/closet",    label: "Closet",    icon: Shirt },
  { href: "/discover",  label: "Discover",  icon: Sparkles },
  { href: "/calendar",  label: "Calendar",  icon: Calendar },
  { href: "/analytics", label: "Analytics", icon: BarChart3 },
  { href: "/wishlist",  label: "Wishlist",  icon: Heart },
  { href: "/profile",   label: "Perfil",    icon: User },
];

interface Props {
  active: string;
}

export function Sidebar({ active }: Props) {
  const { user, logout } = useAuthStore();
  const router = useRouter();

  const handleLogout = () => {
    logout();
    router.push("/login");
  };

  return (
    <>
      {/* Desktop sidebar */}
      <aside className="hidden md:flex flex-col fixed left-0 top-0 h-full w-64 bg-white border-r border-[rgba(28,26,24,0.06)] px-6 py-8 z-10">
        {/* Wordmark */}
        <div className="mb-10">
          <h1 className="font-serif text-xl tracking-[0.20em] text-warm-black uppercase font-light">
            Crayoli
          </h1>
          <p className="text-stone text-xs font-sans mt-0.5 tracking-wide">Closet</p>
        </div>

        {/* User */}
        {user && (
          <div className="flex items-center gap-3 mb-8 pb-6 border-b border-[rgba(28,26,24,0.06)]">
            <div className="w-8 h-8 rounded-full bg-blush flex items-center justify-center">
              <span className="text-warm-black text-xs font-serif font-medium">
                {user.display_name.charAt(0)}
              </span>
            </div>
            <div className="min-w-0">
              <p className="text-warm-black text-sm font-sans font-medium truncate">
                {user.display_name}
              </p>
              {user.founder_access && (
                <p className="text-gold-dark text-[10px] font-sans">Founder</p>
              )}
            </div>
          </div>
        )}

        {/* Nav */}
        <nav className="flex-1 space-y-1">
          {NAV.map(({ href, label, icon: Icon }) => {
            const isActive = active === href.replace("/", "");
            return (
              <Link
                key={href}
                href={href}
                className={cn(
                  "flex items-center gap-3 h-10 px-3 rounded-md text-sm font-sans transition-all duration-200",
                  isActive
                    ? "bg-cream text-warm-black font-medium"
                    : "text-stone hover:text-warm-black hover:bg-ivory"
                )}
              >
                <Icon
                  size={16}
                  className={cn(isActive ? "text-warm-black" : "text-stone")}
                />
                {label}
                {isActive && (
                  <div className="ml-auto w-1 h-4 bg-gold rounded-full" />
                )}
              </Link>
            );
          })}
        </nav>

        {/* Logout */}
        <button
          onClick={handleLogout}
          className="flex items-center gap-3 h-10 px-3 rounded-md text-sm font-sans text-stone hover:text-warm-black hover:bg-ivory transition-all duration-200 w-full"
        >
          <LogOut size={16} />
          Salir
        </button>
      </aside>

      {/* Mobile bottom nav */}
      <nav className="md:hidden fixed bottom-0 left-0 right-0 bg-white border-t border-[rgba(28,26,24,0.06)] flex z-10">
        {NAV.slice(0, 5).map(({ href, label, icon: Icon }) => {
          const isActive = active === href.replace("/", "");
          return (
            <Link
              key={href}
              href={href}
              className={cn(
                "flex-1 flex flex-col items-center justify-center py-3 gap-1",
                isActive ? "text-warm-black" : "text-stone"
              )}
            >
              <Icon size={18} />
              <span className="text-[9px] font-sans">{label}</span>
              {isActive && (
                <div className="absolute bottom-0 w-4 h-0.5 bg-gold rounded-full" />
              )}
            </Link>
          );
        })}
      </nav>
    </>
  );
}
