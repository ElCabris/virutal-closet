export default function Loading() {
  return (
    <div className="min-h-screen bg-ivory flex items-center justify-center">
      <div className="flex flex-col items-center gap-4">
        <div className="w-6 h-6 border-2 border-gold border-t-transparent rounded-full animate-spin" />
        <p className="text-stone text-xs font-sans tracking-widest uppercase">Crayoli</p>
      </div>
    </div>
  );
}
