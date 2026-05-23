export interface ColorSwatch {
  hex: string;
  name: string;
}

export interface Garment {
  id: string;
  user_id: string;
  name: string | null;
  brand: string | null;
  notes: string | null;
  category: string | null;
  subcategory: string | null;
  image_url_raw: string | null;
  image_url_card: string | null;
  image_url_thumb: string | null;
  image_url_processed: string | null;
  blur_hash: string | null;
  dominant_color: string | null;
  color_palette: ColorSwatch[];
  style_tags: string[];
  ai_style_label: string | null;
  formality: number | null;
  seasons: string[];
  occasions: string[];
  pattern: string | null;
  texture: string | null;
  materials: string[];
  purchase_price: number | null;
  currency: string;
  condition: string;
  size: string | null;
  user_tags: string[];
  wear_count: number;
  last_worn_at: string | null;
  is_favorite: boolean;
  status: string;
  ai_status: string;
  created_at: string;
  updated_at: string;
}

export interface PaginatedGarments {
  items: Garment[];
  total: number;
  page: number;
  page_size: number;
  total_pages: number;
  has_next: boolean;
  has_prev: boolean;
}

export interface OutfitItem {
  role: string | null;
  garment: Partial<Garment>;
}

export interface Recommendation {
  id: string;
  name: string;
  score: number;
  mood: string;
  context_label: string;
  palette_match: string;
  novelty_score: number;
  rationale: {
    color_harmony: string;
    balance: string;
    mood_fit: string;
  };
  items: OutfitItem[];
}

export interface WishlistItem {
  id: string;
  user_id: string;
  name: string;
  brand: string | null;
  category: string | null;
  image_url: string | null;
  product_url: string | null;
  target_price: number | null;
  current_price: number | null;
  currency: string;
  priority: string;
  notes: string | null;
  is_purchased: boolean;
  created_at: string;
  updated_at: string;
}

export interface AnalyticsSummary {
  total_garments: number;
  total_value: number;
  avg_cost_per_wear: number | null;
  most_worn: GarmentStat[];
  least_worn: GarmentStat[];
  never_worn: GarmentStat[];
  by_category: CategoryStat[];
  wear_logs_last_30d: number;
  favorite_count: number;
}

export interface GarmentStat {
  id: string;
  name: string | null;
  category: string | null;
  image_url_thumb: string | null;
  dominant_color: string | null;
  wear_count: number;
  last_worn_at: string | null;
  purchase_price: number | null;
  cost_per_wear: number | null;
}

export interface CategoryStat {
  category: string;
  count: number;
  percentage: number;
}

export interface UploadResponse {
  garment_id: string;
  image_url_raw: string;
  image_url_card: string;
  image_url_thumb: string;
  image_url_processed: string;
  dominant_color: string | null;
  color_palette: ColorSwatch[];
}

export interface StyleProfile {
  id: string;
  style_vibes: string[];
  color_palette_pref: string[];
  occasions: string[];
  climate: string | null;
  goals: string[];
  onboarding_completed: boolean;
}
