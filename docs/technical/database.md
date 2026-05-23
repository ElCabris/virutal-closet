# Crayoli Closet — Database Design
**Version:** 1.0 | **Engine:** PostgreSQL 16 | **ORM:** SQLAlchemy 2.0

---

## Schema Overview

```
users
  ↓ 1:1
style_profiles
  ↓ 1:N
  ↓─────────────────────────────────────────────────────
  ▼                                                     ▼
clothing_items                                         events
  ↓ M:N (via outfit_items)                              ↓ 1:N
outfits                                            outfit_plans
  ↓ 1:N
outfit_logs (wear history)
  ↓
recommendations
uploads
```

---

## Table Definitions

### Table: `users`

```sql
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           VARCHAR(320) UNIQUE NOT NULL,
    email_verified  BOOLEAN DEFAULT false,
    password_hash   VARCHAR(255),                    -- null for OAuth users
    display_name    VARCHAR(100) NOT NULL,
    avatar_url      TEXT,
    provider        VARCHAR(20) DEFAULT 'email',     -- email | google | apple
    provider_id     VARCHAR(255),                    -- OAuth sub
    timezone        VARCHAR(50) DEFAULT 'UTC',
    locale          VARCHAR(10) DEFAULT 'es',
    is_active       BOOLEAN DEFAULT true,
    is_verified     BOOLEAN DEFAULT false,

    -- Acceso y tier
    -- founder_access = true: acceso completo irrestricto a todas las funcionalidades
    -- Ana María siempre tiene founder_access = true
    founder_access  BOOLEAN DEFAULT false,
    tier            VARCHAR(20) DEFAULT 'essentials', -- essentials | premium | atelier | founder
    tier_expires_at TIMESTAMPTZ,                     -- null = sin expiración (founder)

    -- Privacy
    data_export_requested_at  TIMESTAMPTZ,
    deletion_requested_at     TIMESTAMPTZ,
    deleted_at               TIMESTAMPTZ,

    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Seed: Ana María siempre con founder_access completo
-- INSERT INTO users (email, display_name, founder_access, tier)
-- VALUES ('ana@crayoli.app', 'Ana María', true, 'founder')
-- ON CONFLICT (email) DO UPDATE SET founder_access = true, tier = 'founder';

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_provider ON users(provider, provider_id);
CREATE INDEX idx_users_active ON users(is_active) WHERE is_active = true;
```

### Table: `style_profiles`

```sql
CREATE TABLE style_profiles (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Onboarding choices
    aesthetic_tags          TEXT[] DEFAULT '{}',
    color_preferences       JSONB DEFAULT '{}',       -- {hex: affinity_score}
    lifestyle_weights       JSONB DEFAULT '{}',       -- {lifestyle_type: weight}
    onboarding_completed    BOOLEAN DEFAULT false,
    onboarding_completed_at TIMESTAMPTZ,

    -- Computed Style DNA
    aesthetic_embedding     VECTOR(128),              -- pgvector extension
    dominant_colors         TEXT[] DEFAULT '{}',      -- top 5 hex colors
    dominant_style_tags     TEXT[] DEFAULT '{}',      -- top 5 style descriptors
    avg_formality           DECIMAL(3,2) DEFAULT 2.5, -- 1.00-5.00
    style_persona           VARCHAR(100),             -- editorial label
    cold_start_complete     BOOLEAN DEFAULT false,
    onboarding_priors_weight DECIMAL(3,2) DEFAULT 1.0,

    -- Temporal patterns
    weekday_formality       JSONB DEFAULT '{}',       -- {0-6: avg_formality}
    seasonal_preferences    JSONB DEFAULT '{}',

    -- Learning metadata
    total_interactions      INT DEFAULT 0,
    last_updated_at         TIMESTAMPTZ DEFAULT NOW(),

    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_style_profiles_user ON style_profiles(user_id);
```

### Table: `clothing_items`

```sql
CREATE TABLE clothing_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Core identity
    name            VARCHAR(200),
    brand           VARCHAR(100),
    notes           TEXT,

    -- Status
    status          VARCHAR(20) DEFAULT 'active',    -- active | archived | processing
    ai_status       VARCHAR(20) DEFAULT 'pending',   -- pending | processing | complete | failed

    -- Images
    image_url_raw       TEXT,
    image_url_processed TEXT,
    image_url_thumb     TEXT,                        -- 200x280
    image_url_card      TEXT,                        -- 400x560
    image_url_detail    TEXT,                        -- 800x1120
    blur_hash           VARCHAR(100),                -- for placeholder loading
    image_count         SMALLINT DEFAULT 1,
    image_urls_extra    TEXT[] DEFAULT '{}',         -- additional angle images

    -- AI Classification
    category        VARCHAR(50),                     -- tops | bottoms | dresses | etc.
    subcategory     VARCHAR(100),                    -- shirt | blouse | etc.
    ai_category_confidence DECIMAL(4,3),
    formality       SMALLINT CHECK (formality BETWEEN 1 AND 5),
    seasons         TEXT[] DEFAULT '{}',             -- spring | summer | fall | winter
    occasions       TEXT[] DEFAULT '{}',
    style_tags      TEXT[] DEFAULT '{}',             -- AI-generated + user tags
    ai_style_label  VARCHAR(200),                    -- "structured ivory blazer"

    -- Color
    dominant_color  VARCHAR(7),                      -- hex
    color_palette   JSONB DEFAULT '[]',              -- [{hex, name, percentage}]

    -- Material & Pattern
    pattern         VARCHAR(50),                     -- solid | striped | floral | etc.
    texture         VARCHAR(50),
    materials       TEXT[] DEFAULT '{}',             -- estimated materials

    -- Embedding (also stored in Pinecone; kept here for fallback)
    embedding       VECTOR(768),                     -- CLIP ViT-L/14

    -- User-provided metadata
    purchase_date   DATE,
    purchase_price  DECIMAL(10,2),
    currency        VARCHAR(3) DEFAULT 'USD',
    condition       VARCHAR(20) DEFAULT 'good',      -- excellent | good | fair | worn
    care_symbols    TEXT[] DEFAULT '{}',
    size            VARCHAR(20),

    -- Usage tracking
    wear_count      INT DEFAULT 0,
    last_worn_at    DATE,
    is_favorite     BOOLEAN DEFAULT false,

    -- Tags
    user_tags       TEXT[] DEFAULT '{}',             -- user-added freeform tags

    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW(),
    deleted_at  TIMESTAMPTZ                          -- soft delete
);

-- Indexes
CREATE INDEX idx_clothing_user_active
    ON clothing_items(user_id, status)
    WHERE status = 'active' AND deleted_at IS NULL;

CREATE INDEX idx_clothing_category
    ON clothing_items(user_id, category)
    WHERE status = 'active';

CREATE INDEX idx_clothing_last_worn
    ON clothing_items(user_id, last_worn_at)
    WHERE status = 'active';

CREATE INDEX idx_clothing_favorite
    ON clothing_items(user_id, is_favorite)
    WHERE is_favorite = true;

-- Full-text search index
CREATE INDEX idx_clothing_fts
    ON clothing_items
    USING GIN(to_tsvector('english',
        coalesce(name, '') || ' ' ||
        coalesce(brand, '') || ' ' ||
        coalesce(ai_style_label, '') || ' ' ||
        array_to_string(style_tags, ' ') || ' ' ||
        array_to_string(user_tags, ' ')
    ));

-- Vector similarity index (pgvector)
CREATE INDEX idx_clothing_embedding
    ON clothing_items
    USING ivfflat(embedding vector_cosine_ops)
    WITH (lists = 100);

-- GIN for array searches
CREATE INDEX idx_clothing_tags_gin ON clothing_items USING GIN(style_tags);
CREATE INDEX idx_clothing_occasions_gin ON clothing_items USING GIN(occasions);
CREATE INDEX idx_clothing_seasons_gin ON clothing_items USING GIN(seasons);
```

### Table: `outfits`

```sql
CREATE TABLE outfits (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    name        VARCHAR(200),
    description TEXT,
    cover_image_url TEXT,

    -- Classification
    mood        VARCHAR(50),                         -- soft_girl | office | dinner | etc.
    occasion    VARCHAR(100),
    formality   SMALLINT,
    seasons     TEXT[] DEFAULT '{}',

    -- Source
    source      VARCHAR(20) DEFAULT 'user',          -- user | ai | calendar
    ai_context  JSONB,                               -- {weather, occasion, mood} at generation time

    -- Stats
    wear_count  INT DEFAULT 0,
    is_favorite BOOLEAN DEFAULT false,

    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW(),
    deleted_at  TIMESTAMPTZ
);

CREATE INDEX idx_outfits_user ON outfits(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_outfits_mood ON outfits(user_id, mood) WHERE deleted_at IS NULL;
```

### Table: `outfit_items`

```sql
CREATE TABLE outfit_items (
    outfit_id       UUID NOT NULL REFERENCES outfits(id) ON DELETE CASCADE,
    clothing_item_id UUID NOT NULL REFERENCES clothing_items(id),
    position        SMALLINT DEFAULT 0,             -- display order
    role            VARCHAR(30),                    -- top | bottom | shoes | bag | etc.

    PRIMARY KEY (outfit_id, clothing_item_id)
);

CREATE INDEX idx_outfit_items_clothing ON outfit_items(clothing_item_id);
```

### Table: `outfit_logs`

```sql
CREATE TABLE outfit_logs (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    outfit_id   UUID REFERENCES outfits(id),

    -- For ad-hoc wears (no saved outfit)
    clothing_item_ids UUID[] DEFAULT '{}',

    worn_on     DATE NOT NULL,
    occasion    VARCHAR(100),
    weather_temp_c DECIMAL(4,1),
    weather_condition VARCHAR(50),
    mood        VARCHAR(50),

    -- Source of this log
    source      VARCHAR(20) DEFAULT 'manual',       -- manual | ai_suggestion | calendar

    -- Feedback signals
    user_rating SMALLINT,                           -- 1-5 (optional post-wear rating)
    notes       TEXT,

    created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_outfit_logs_user_date
    ON outfit_logs(user_id, worn_on DESC);

CREATE INDEX idx_outfit_logs_outfit
    ON outfit_logs(outfit_id)
    WHERE outfit_id IS NOT NULL;
```

### Table: `recommendations`

```sql
CREATE TABLE recommendations (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Generation context
    generated_at    TIMESTAMPTZ DEFAULT NOW(),
    context         JSONB NOT NULL,                 -- full context snapshot
    expires_at      TIMESTAMPTZ,

    -- Results
    outfits         JSONB NOT NULL,                 -- [{outfit_data, score, reason}]
    algorithm_version VARCHAR(20),

    -- Interaction tracking
    shown_at        TIMESTAMPTZ,
    interacted_at   TIMESTAMPTZ,
    interaction     VARCHAR(20),                    -- worn | saved | dismissed | regenerated

    created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_recs_user_date ON recommendations(user_id, generated_at DESC);
CREATE INDEX idx_recs_interaction ON recommendations(user_id, interaction)
    WHERE interaction IS NOT NULL;
```

### Table: `events`

```sql
CREATE TABLE events (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    title       VARCHAR(200) NOT NULL,
    description TEXT,
    event_date  DATE NOT NULL,
    start_time  TIME,
    end_time    TIME,
    location    VARCHAR(300),

    -- Context for outfit suggestions
    occasion    VARCHAR(100),
    formality   SMALLINT,
    dress_code  VARCHAR(100),

    -- Linked outfit
    planned_outfit_id UUID REFERENCES outfits(id),
    logged_outfit_id  UUID REFERENCES outfits(id),

    -- Packing trip context
    is_trip         BOOLEAN DEFAULT false,
    trip_end_date   DATE,
    trip_destination VARCHAR(200),

    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_events_user_date ON events(user_id, event_date);
CREATE INDEX idx_events_upcoming ON events(user_id, event_date)
    WHERE event_date >= CURRENT_DATE;
```

### Table: `uploads`

```sql
CREATE TABLE uploads (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    s3_key      TEXT NOT NULL,
    s3_bucket   TEXT NOT NULL,
    file_size   INT,
    content_type VARCHAR(100),
    status      VARCHAR(20) DEFAULT 'pending',       -- pending | processing | complete | failed

    -- Linked entity
    entity_type VARCHAR(30),                         -- clothing_item | outfit | avatar
    entity_id   UUID,

    -- Error tracking
    error_message TEXT,
    retry_count   SMALLINT DEFAULT 0,

    created_at  TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE INDEX idx_uploads_user ON uploads(user_id, created_at DESC);
CREATE INDEX idx_uploads_entity ON uploads(entity_type, entity_id)
    WHERE entity_id IS NOT NULL;
```

### Table: `weather_cache`

```sql
CREATE TABLE weather_cache (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    city_key    VARCHAR(100) NOT NULL,              -- normalized city identifier
    date        DATE NOT NULL,
    hour        SMALLINT NOT NULL,                  -- 0-23 for hourly cache

    temp_c      DECIMAL(4,1),
    temp_c_min  DECIMAL(4,1),
    temp_c_max  DECIMAL(4,1),
    condition   VARCHAR(50),
    precipitation_mm DECIMAL(5,1),
    wind_kmh    DECIMAL(5,1),
    humidity    SMALLINT,
    icon        VARCHAR(20),

    fetched_at  TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE (city_key, date, hour)
);

CREATE INDEX idx_weather_lookup ON weather_cache(city_key, date, hour);
```

### Table: `wishlist_items`

```sql
CREATE TABLE wishlist_items (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    name        VARCHAR(200),
    brand       VARCHAR(100),
    image_url   TEXT,
    product_url TEXT,
    price       DECIMAL(10,2),
    currency    VARCHAR(3),
    category    VARCHAR(50),
    notes       TEXT,

    is_purchased    BOOLEAN DEFAULT false,
    purchased_at    DATE,

    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_wishlist_user ON wishlist_items(user_id) WHERE is_purchased = false;
```

---

## Key Queries

### Find similar garments (vector search)

```sql
-- pgvector cosine similarity
SELECT
    id, name, brand, category, image_url_card,
    1 - (embedding <=> $1::vector) AS similarity
FROM clothing_items
WHERE
    user_id = $2
    AND status = 'active'
    AND deleted_at IS NULL
    AND id != $3                              -- exclude self
ORDER BY embedding <=> $1::vector
LIMIT 20;
```

### Garment discovery — "forgotten" items

```sql
SELECT
    ci.*,
    EXTRACT(DAY FROM NOW() - ci.last_worn_at) AS days_since_worn
FROM clothing_items ci
WHERE
    ci.user_id = $1
    AND ci.status = 'active'
    AND ci.deleted_at IS NULL
    AND (
        ci.last_worn_at < NOW() - INTERVAL '30 days'
        OR ci.last_worn_at IS NULL
    )
ORDER BY
    ci.last_worn_at ASC NULLS FIRST,
    ci.wear_count ASC
LIMIT 10;
```

### Wear frequency analytics

```sql
SELECT
    ci.id,
    ci.name,
    ci.brand,
    ci.image_url_thumb,
    ci.category,
    ci.purchase_price,
    ci.wear_count,
    ci.last_worn_at,
    CASE
        WHEN ci.purchase_price > 0 AND ci.wear_count > 0
        THEN ROUND(ci.purchase_price / ci.wear_count, 2)
        ELSE NULL
    END AS cost_per_wear
FROM clothing_items ci
WHERE
    ci.user_id = $1
    AND ci.status = 'active'
    AND ci.deleted_at IS NULL
ORDER BY ci.wear_count DESC
LIMIT 20;
```

### Color DNA analytics

```sql
-- Aggregate color distribution across wardrobe
SELECT
    color_data->>'name' AS color_name,
    color_data->>'hex' AS hex,
    SUM((color_data->>'percentage')::DECIMAL) AS total_percentage,
    COUNT(*) AS garment_count
FROM clothing_items ci,
    jsonb_array_elements(ci.color_palette) AS color_data
WHERE
    ci.user_id = $1
    AND ci.status = 'active'
    AND ci.deleted_at IS NULL
GROUP BY color_name, hex
ORDER BY total_percentage DESC
LIMIT 10;
```

### Outfit history for calendar

```sql
SELECT
    ol.worn_on,
    ol.mood,
    ol.occasion,
    o.name AS outfit_name,
    o.id AS outfit_id,
    (
        SELECT jsonb_agg(jsonb_build_object(
            'id', ci.id,
            'image_url', ci.image_url_thumb,
            'category', ci.category
        ))
        FROM outfit_items oi
        JOIN clothing_items ci ON ci.id = oi.clothing_item_id
        WHERE oi.outfit_id = o.id
    ) AS items
FROM outfit_logs ol
LEFT JOIN outfits o ON o.id = ol.outfit_id
WHERE
    ol.user_id = $1
    AND ol.worn_on BETWEEN $2 AND $3
ORDER BY ol.worn_on DESC;
```

---

## Database Performance Strategy

### Connection Pooling
```
PgBouncer (transaction-mode pooling):
  max_client_conn: 200
  default_pool_size: 20
  pool_mode: transaction
```

### Partitioning
- `outfit_logs` → RANGE partition on `worn_on` by month
- `recommendations` → RANGE partition on `generated_at` by month
- Retention policy: archive logs older than 2 years

### Vacuum & Autovacuum Tuning
- `clothing_items`: aggressive autovacuum (updated frequently via wear tracking)
- `outfit_logs`: bulk-insert oriented, autovacuum can be relaxed

### Read Replica
- 1 read replica for analytics queries
- Analytics endpoints route to replica via SQLAlchemy read/write splitting

---

## Migration Strategy

```python
# Alembic migration example — adding embedding column
def upgrade():
    op.execute("CREATE EXTENSION IF NOT EXISTS vector")
    op.add_column('clothing_items',
        sa.Column('embedding', Vector(768), nullable=True)
    )
    op.create_index(
        'idx_clothing_embedding',
        'clothing_items',
        ['embedding'],
        postgresql_using='ivfflat',
        postgresql_with={'lists': 100},
        postgresql_ops={'embedding': 'vector_cosine_ops'}
    )

def downgrade():
    op.drop_index('idx_clothing_embedding')
    op.drop_column('clothing_items', 'embedding')
```

---

*Database Design v1.0 — Crayoli Engineering*
