-- ─── Garment images: normalize into a dedicated 1:N table ──────────────────────
create table if not exists garment_images (
  id           uuid primary key default uuid_generate_v4(),
  garment_id   uuid not null references garments(id) on delete cascade,
  user_id      uuid not null references auth.users(id) on delete cascade,
  storage_path text not null,
  position     int not null default 0,
  created_at   timestamptz default now() not null
);

create index if not exists garment_images_garment_id_idx
  on garment_images(garment_id, position);

alter table garment_images enable row level security;

create policy "Users can manage own garment images"
  on garment_images for all using (auth.uid() = user_id);

-- Backfill from the existing image_urls array, recovering the storage path
-- from the public URL (bucket = 'garments').
insert into garment_images (garment_id, user_id, storage_path, position, created_at)
select
  g.id,
  g.user_id,
  regexp_replace(url, '^.*/storage/v1/object/public/garments/', ''),
  ord - 1,
  g.created_at
from garments g,
     unnest(g.image_urls) with ordinality as t(url, ord)
where g.image_urls <> '{}';

alter table garments drop column if exists image_urls;
