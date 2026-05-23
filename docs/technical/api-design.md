# Crayoli Closet — API Design Specification
**Version:** 1.0 | **Style:** REST | **Format:** JSON | **Auth:** JWT Bearer

---

## 1. API Conventions

### Base URL
```
Production:  https://api.crayoli.app/v1
Staging:     https://api-staging.crayoli.app/v1
Development: http://localhost:8000/v1
```

### Standard Response Envelope

**Success:**
```json
{
  "success": true,
  "data": { ... },
  "meta": {
    "request_id": "req_01HX...",
    "timestamp": "2026-05-20T10:30:00Z"
  }
}
```

**Paginated:**
```json
{
  "success": true,
  "data": [ ... ],
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total": 142,
    "total_pages": 8,
    "has_next": true,
    "has_prev": false,
    "next_cursor": "eyJpZCI6IjEyMyJ9"
  },
  "meta": { "request_id": "req_01HX..." }
}
```

**Error:**
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Image file too large. Maximum 20MB.",
    "details": [
      { "field": "file", "message": "Max size exceeded" }
    ]
  },
  "meta": { "request_id": "req_01HX..." }
}
```

### Standard HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success (GET, PUT, PATCH) |
| 201 | Created (POST) |
| 204 | No content (DELETE) |
| 400 | Bad Request — validation error |
| 401 | Unauthorized — missing/invalid token |
| 403 | Forbidden — insufficient permissions |
| 404 | Not Found |
| 409 | Conflict — duplicate resource |
| 422 | Unprocessable Entity — semantic error |
| 429 | Too Many Requests — rate limited |
| 500 | Internal Server Error |
| 503 | Service Unavailable — AI service down |

### Authentication

```
Authorization: Bearer <access_token>
```

All endpoints require authentication unless marked `[PUBLIC]`.

---

## 2. Authentication Endpoints

### `POST /auth/signup` [PUBLIC]

**Request:**
```json
{
  "email": "ana@example.com",
  "password": "SecureP@ssword1",
  "display_name": "Ana María"
}
```

**Validation:**
- `email`: valid email format, not already registered
- `password`: min 8 chars, at least 1 uppercase, 1 number
- `display_name`: 1-100 chars

**Response 201:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "usr_01HX9QWERTY...",
      "email": "ana@example.com",
      "display_name": "Ana María",
      "created_at": "2026-05-20T10:00:00Z"
    },
    "tokens": {
      "access_token": "eyJhbGci...",
      "token_type": "Bearer",
      "expires_in": 900
    }
  }
}
```

*Note: Refresh token set as httpOnly cookie `crayoli_rt`*

---

### `POST /auth/login` [PUBLIC]

**Request:**
```json
{
  "email": "ana@example.com",
  "password": "SecureP@ssword1"
}
```

**Response 200:**
```json
{
  "success": true,
  "data": {
    "user": { "id": "...", "email": "...", "display_name": "..." },
    "tokens": {
      "access_token": "eyJhbGci...",
      "token_type": "Bearer",
      "expires_in": 900
    }
  }
}
```

**Error 401:**
```json
{
  "error": {
    "code": "INVALID_CREDENTIALS",
    "message": "Email or password is incorrect."
  }
}
```

---

### `POST /auth/refresh` [PUBLIC]

Uses `crayoli_rt` httpOnly cookie.

**Response 200:** New access_token + rotated refresh cookie.

---

### `POST /auth/logout`

Revokes current refresh token.

**Response 204:** No body.

---

### `POST /auth/oauth/google` [PUBLIC]

**Request:**
```json
{ "code": "4/0AfJohX...", "redirect_uri": "https://app.crayoli.app/auth/callback/google" }
```

**Response 200:** Same as login response.

---

## 3. Garment Endpoints

### `GET /garments`

List user's garment closet with filtering.

**Query Parameters:**

| Param | Type | Description |
|-------|------|-------------|
| `category` | string | Filter by category (tops, bottoms, etc.) |
| `subcategory` | string | Filter by subcategory |
| `color` | string | Hex color — finds color-similar items |
| `season` | string[] | season filter (comma-separated) |
| `occasion` | string | Occasion filter |
| `pattern` | string | Pattern filter |
| `favorite` | boolean | Show only favorites |
| `status` | string | active (default) \| archived |
| `unworn_days` | integer | Items not worn in N+ days |
| `sort` | string | recent \| most_worn \| least_worn \| az \| by_color |
| `q` | string | Full-text search |
| `page` | integer | Page number (default: 1) |
| `page_size` | integer | Items per page (default: 20, max: 100) |

**Request:**
```
GET /garments?category=tops&sort=most_worn&page=1&page_size=20
Authorization: Bearer eyJ...
```

**Response 200:**
```json
{
  "success": true,
  "data": [
    {
      "id": "gmt_01HX...",
      "name": "White Silk Blouse",
      "brand": "COS",
      "category": "tops",
      "subcategory": "blouse",
      "image_url_card": "https://cdn.crayoli.app/...",
      "blur_hash": "LFEyux~qM{ae",
      "dominant_color": "#F5F0E8",
      "color_palette": [
        { "hex": "#F5F0E8", "name": "Ivory", "percentage": 0.82 },
        { "hex": "#E8E0D0", "name": "Cream", "percentage": 0.12 }
      ],
      "style_tags": ["minimalist", "structured", "office", "silk"],
      "ai_style_label": "structured ivory blouse",
      "formality": 3,
      "wear_count": 12,
      "last_worn_at": "2026-05-08",
      "is_favorite": true,
      "status": "active",
      "ai_status": "complete"
    }
  ],
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total": 58,
    "total_pages": 3,
    "has_next": true,
    "has_prev": false
  }
}
```

---

### `POST /garments/upload/presign`

Get presigned S3 URL for direct client upload.

**Request:**
```json
{
  "file_name": "blouse.jpg",
  "content_type": "image/jpeg",
  "file_size": 2457600
}
```

**Validation:**
- `content_type`: must be `image/jpeg`, `image/png`, `image/heic`, `image/webp`
- `file_size`: max 20MB (20971520 bytes)

**Response 200:**
```json
{
  "success": true,
  "data": {
    "upload_id": "upl_01HX...",
    "presigned_url": "https://crayoli-images.s3.amazonaws.com/...",
    "presigned_fields": {
      "key": "uploads/usr_01HX.../2026/05/20/raw_abc123.jpg",
      "Content-Type": "image/jpeg",
      "X-Amz-Credential": "...",
      "X-Amz-Signature": "..."
    },
    "expires_at": "2026-05-20T10:30:30Z"
  }
}
```

*Client uploads directly to S3, then calls `/garments` POST with upload_id.*

---

### `POST /garments`

Create garment record after upload.

**Request:**
```json
{
  "upload_id": "upl_01HX...",
  "name": "White Silk Blouse",
  "brand": "COS",
  "category": "tops",
  "purchase_date": "2025-03-15",
  "purchase_price": 99.00,
  "currency": "USD",
  "notes": "Perfect for office",
  "user_tags": ["work", "silk", "versatile"]
}
```

*All fields except `upload_id` are optional — AI will classify automatically.*

**Response 201:**
```json
{
  "success": true,
  "data": {
    "id": "gmt_01HX...",
    "status": "active",
    "ai_status": "processing",
    "image_url_thumb": null,
    "message": "Your garment is being analyzed. It will appear shortly."
  }
}
```

*Client subscribes to WebSocket for completion notification.*

---

### `GET /garments/:id`

Full garment detail.

**Response 200:**
```json
{
  "success": true,
  "data": {
    "id": "gmt_01HX...",
    "name": "White Silk Blouse",
    "brand": "COS",
    "category": "tops",
    "subcategory": "blouse",
    "image_url_raw": "https://s3.../raw.jpg",
    "image_url_processed": "https://cdn.crayoli.app/.../processed.webp",
    "image_url_card": "https://cdn.crayoli.app/.../card.webp",
    "image_url_detail": "https://cdn.crayoli.app/.../detail.webp",
    "image_urls_extra": [],
    "blur_hash": "LFEyux~qM{ae",
    "dominant_color": "#F5F0E8",
    "color_palette": [ ... ],
    "pattern": "solid",
    "texture": "smooth",
    "materials": ["silk", "polyester"],
    "style_tags": ["minimalist", "structured", "silk"],
    "ai_style_label": "structured ivory blouse",
    "ai_category_confidence": 0.94,
    "formality": 3,
    "seasons": ["spring", "fall"],
    "occasions": ["work", "lunch", "events"],
    "purchase_date": "2025-03-15",
    "purchase_price": 99.00,
    "currency": "USD",
    "condition": "excellent",
    "size": "S",
    "wear_count": 12,
    "last_worn_at": "2026-05-08",
    "is_favorite": true,
    "notes": "Perfect for office",
    "user_tags": ["work", "silk"],
    "ai_status": "complete",
    "created_at": "2026-03-20T14:00:00Z",
    "updated_at": "2026-05-08T09:00:00Z"
  }
}
```

---

### `PATCH /garments/:id`

Partial update. Allows editing name, brand, tags, etc.

**Request:**
```json
{
  "name": "Ivory Silk Blouse",
  "is_favorite": true,
  "user_tags": ["work", "silk", "office"],
  "occasions": ["work", "events"]
}
```

**Response 200:** Updated garment object.

---

### `DELETE /garments/:id`

Soft delete (moves to archived, not permanently removed).

**Response 204:** No body.

---

### `POST /garments/:id/archive`

Archive a garment (removes from active view but keeps record).

**Response 200:**
```json
{ "success": true, "data": { "id": "gmt_01HX...", "status": "archived" } }
```

---

### `GET /garments/:id/similar`

Find visually similar garments in user's closet.

**Query params:** `limit` (default: 10, max: 30)

**Response 200:**
```json
{
  "success": true,
  "data": {
    "garment_id": "gmt_01HX...",
    "similar": [
      {
        "id": "gmt_02HX...",
        "name": "Cream Button Blouse",
        "image_url_card": "...",
        "similarity_score": 0.89,
        "shared_attributes": ["neutral", "minimalist", "tops"]
      }
    ]
  }
}
```

---

### `POST /garments/:id/wear`

Log a wear event for this garment.

**Request:**
```json
{
  "worn_on": "2026-05-20",
  "occasion": "work",
  "mood": "office"
}
```

**Response 200:**
```json
{
  "success": true,
  "data": {
    "garment_id": "gmt_01HX...",
    "wear_count": 13,
    "last_worn_at": "2026-05-20"
  }
}
```

---

## 4. Recommendations Endpoints

### `GET /recommendations`

Get AI outfit recommendations for current context.

**Query Parameters:**

| Param | Type | Description |
|-------|------|-------------|
| `occasion` | string | Event context (work, dinner, casual, etc.) |
| `mood` | string | Mood tag (soft_girl, office, cozy, etc.) |
| `date` | string | Target date YYYY-MM-DD (default: today) |
| `count` | integer | Number of outfits (default: 3, max: 6) |
| `force_refresh` | boolean | Skip cache, regenerate |

**Request:**
```
GET /recommendations?occasion=work&mood=office&date=2026-05-20
Authorization: Bearer eyJ...
```

**Response 200:**
```json
{
  "success": true,
  "data": {
    "context": {
      "date": "2026-05-20",
      "weather": {
        "temp_c": 14.0,
        "condition": "partly_cloudy",
        "precipitation_mm": 0.0
      },
      "occasion": "work",
      "mood": "office"
    },
    "outfits": [
      {
        "id": "rec_outfit_abc...",
        "name": "Polished Tuesday",
        "confidence": "perfect_match",
        "score": 0.94,
        "context_label": "For light office · 14°C",
        "items": [
          {
            "role": "top",
            "garment": {
              "id": "gmt_01HX...",
              "name": "White Silk Blouse",
              "image_url_card": "...",
              "category": "tops",
              "dominant_color": "#F5F0E8"
            }
          },
          {
            "role": "bottom",
            "garment": {
              "id": "gmt_02HX...",
              "name": "High-Waist Trousers",
              "image_url_card": "...",
              "category": "bottoms",
              "dominant_color": "#1C1A18"
            }
          },
          {
            "role": "shoes",
            "garment": { ... }
          },
          {
            "role": "bag",
            "garment": { ... }
          }
        ],
        "reasoning": {
          "color_harmony": "Classic monochromatic — ivory and black create effortless contrast.",
          "weather_fit": "Layered for 14°C — add the blazer if it gets cooler.",
          "style_alignment": "Matches your preference for structured minimalism."
        },
        "color_palette": ["#F5F0E8", "#1C1A18", "#C9A99A"]
      },
      { ... },
      { ... }
    ],
    "recommendation_id": "rec_01HX...",
    "cached": false,
    "generated_at": "2026-05-20T10:30:00Z"
  }
}
```

---

### `POST /recommendations/:id/interact`

Record user interaction with a recommendation.

**Request:**
```json
{
  "interaction": "worn",
  "outfit_index": 0
}
```

`interaction` values: `worn` | `saved` | `dismissed` | `regenerated`

**Response 200:** Updated recommendation record with interaction recorded.

---

### `GET /recommendations/moods`

Get outfit suggestions filtered by mood.

**Query params:** `mood` (required), `count` (default: 6)

**Response:** Same structure as `/recommendations`

---

## 5. Outfits Endpoints

### `GET /outfits`

List saved outfits.

**Query params:** `mood`, `occasion`, `favorite`, `sort`, `page`

### `POST /outfits`

Save a new outfit.

**Request:**
```json
{
  "name": "Tuesday Meeting Look",
  "items": [
    { "clothing_item_id": "gmt_01HX...", "role": "top" },
    { "clothing_item_id": "gmt_02HX...", "role": "bottom" },
    { "clothing_item_id": "gmt_03HX...", "role": "shoes" }
  ],
  "mood": "office",
  "occasion": "work",
  "seasons": ["spring", "fall"]
}
```

**Response 201:** Full outfit object.

### `GET /outfits/:id`

Outfit detail with all items and wear history.

### `PATCH /outfits/:id`

Update outfit (name, items, mood).

### `DELETE /outfits/:id`

Soft delete outfit.

### `POST /outfits/:id/wear`

Log this outfit as worn today.

**Request:**
```json
{
  "worn_on": "2026-05-20",
  "occasion": "work",
  "weather_temp_c": 14.0,
  "weather_condition": "partly_cloudy",
  "mood": "office",
  "rating": 5
}
```

---

## 6. Analytics Endpoints

### `GET /analytics/overview`

Wardrobe statistics summary.

**Response 200:**
```json
{
  "success": true,
  "data": {
    "total_items": 142,
    "total_value": 8240.00,
    "currency": "USD",
    "avg_cost_per_wear": 12.30,
    "items_by_category": {
      "tops": 42,
      "bottoms": 28,
      "dresses": 15,
      "shoes": 22,
      "bags": 12,
      "outerwear": 8,
      "accessories": 15
    },
    "wear_stats": {
      "total_outfit_logs": 89,
      "avg_wears_per_item": 4.2,
      "most_worn_category": "tops"
    }
  }
}
```

---

### `GET /analytics/most-worn`

Top worn items.

**Query params:** `limit` (default: 10), `period` (30d | 90d | 1y | all)

**Response 200:**
```json
{
  "success": true,
  "data": {
    "period": "90d",
    "items": [
      {
        "garment": { "id": "...", "name": "White Silk Blouse", "image_url_thumb": "..." },
        "wear_count": 12,
        "cost_per_wear": 8.25,
        "last_worn_at": "2026-05-08"
      }
    ]
  }
}
```

---

### `GET /analytics/forgotten`

Items not worn recently.

**Query params:** `days` (default: 30), `limit` (default: 10)

### `GET /analytics/color-dna`

Color distribution across wardrobe.

**Response 200:**
```json
{
  "success": true,
  "data": {
    "palette": [
      { "hex": "#F5F0E8", "name": "Ivory", "percentage": 0.34, "garment_count": 48 },
      { "hex": "#1C1A18", "name": "Black", "percentage": 0.22, "garment_count": 31 }
    ],
    "dominant_color": "#F5F0E8",
    "palette_archetype": "Warm Neutrals"
  }
}
```

### `GET /analytics/cost-per-wear`

Cost efficiency ranking for all items with prices.

---

## 7. Calendar / Events Endpoints

### `GET /calendar`

Calendar data with outfit plans.

**Query params:** `start` (date), `end` (date)

**Response 200:**
```json
{
  "success": true,
  "data": {
    "days": [
      {
        "date": "2026-05-20",
        "weather": { "temp_c": 14.0, "condition": "partly_cloudy" },
        "events": [
          {
            "id": "evt_01HX...",
            "title": "Team meeting",
            "occasion": "work",
            "formality": 3
          }
        ],
        "planned_outfit": {
          "id": "out_01HX...",
          "name": "Polished Tuesday",
          "cover_image_url": "..."
        },
        "has_log": false
      }
    ]
  }
}
```

### `POST /events`

Create calendar event.

### `PATCH /events/:id`

Update event (including assigning planned outfit).

### `DELETE /events/:id`

Delete event.

---

## 8. Profile & Style Endpoints

### `GET /profile`

User profile + style profile.

**Response 200:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "usr_01HX...",
      "email": "ana@example.com",
      "display_name": "Ana María",
      "avatar_url": "...",
      "created_at": "2026-01-15T10:00:00Z"
    },
    "style_profile": {
      "onboarding_completed": true,
      "aesthetic_tags": ["minimal_chic", "soft_feminine"],
      "dominant_colors": ["#F5F0E8", "#1C1A18", "#C9A99A"],
      "dominant_style_tags": ["minimalist", "structured", "elegant"],
      "avg_formality": 3.2,
      "style_persona": "The Quiet Minimalist",
      "cold_start_complete": true,
      "total_interactions": 47
    }
  }
}
```

### `PATCH /profile`

Update display name, avatar, timezone.

### `PUT /profile/style`

Update style profile from onboarding or settings.

**Request:**
```json
{
  "aesthetic_tags": ["minimal_chic"],
  "color_preferences": {
    "#F5F0E8": 0.9,
    "#1C1A18": 0.8,
    "#C9A99A": 0.7
  },
  "lifestyle_weights": {
    "office": 0.4,
    "casual": 0.3,
    "events": 0.2,
    "travel": 0.1
  }
}
```

---

## 9. Search Endpoint

### `GET /search`

Global search across garments, outfits, and suggestions.

**Query params:** `q` (required), `type` (garments | outfits | all), `limit`

**Response 200:**
```json
{
  "success": true,
  "data": {
    "query": "silk blouse",
    "garments": [
      { "id": "...", "name": "White Silk Blouse", "image_url_thumb": "...", "category": "tops" }
    ],
    "outfits": [
      { "id": "...", "name": "Tuesday Meeting", "cover_image_url": "..." }
    ],
    "total": 5
  }
}
```

---

## 10. WebSocket API

### Connection

```
wss://api.crayoli.app/v1/ws?token=<access_token>
```

### Server → Client Events

**Garment processing complete:**
```json
{
  "event": "garment.processed",
  "data": {
    "garment_id": "gmt_01HX...",
    "status": "complete",
    "garment": { /* full garment object */ }
  }
}
```

**Garment processing failed:**
```json
{
  "event": "garment.process_failed",
  "data": {
    "garment_id": "gmt_01HX...",
    "error": "Low quality image — please try a clearer photo."
  }
}
```

**Daily recommendation ready:**
```json
{
  "event": "recommendations.ready",
  "data": {
    "date": "2026-05-20",
    "preview": {
      "outfit_count": 3,
      "top_outfit_name": "Polished Tuesday",
      "weather": { "temp_c": 14.0, "condition": "partly_cloudy" }
    }
  }
}
```

### Client → Server Events

**Ping:**
```json
{ "event": "ping" }
```

---

## 11. Rate Limits

| Endpoint Group | Limit |
|----------------|-------|
| Auth (login/signup) | 10 requests / 15 minutes |
| Garment upload | 50 uploads / hour |
| Recommendations | 100 requests / hour |
| All other endpoints | 1000 requests / hour |

Rate limit headers on every response:
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 847
X-RateLimit-Reset: 1716203400
X-RateLimit-Window: 3600
```

**429 Response:**
```json
{
  "error": {
    "code": "RATE_LIMITED",
    "message": "Too many requests. Please slow down.",
    "retry_after": 120
  }
}
```

---

*API Design v1.0 — Crayoli Engineering*
