-- ─── Garment images: normalize into a dedicated 1:N table ──────────────────────
-- A garment can have any number of photos. Modeling this as a text[] column
-- on garments would violate 1NF (each photo has its own identity/lifecycle),
-- forces full-array read-modify-write on every add/remove (lost-update risk
-- under concurrent writers), and can't enforce referential integrity. A
-- dedicated table with a FK + ON DELETE CASCADE fixes all three.
create table if not exists garment_images (
  id           uuid primary key default uuid_generate_v4(),
  garment_id   uuid not null references garments(id) on delete cascade,
  user_id      uuid not null references auth.users(id) on delete cascade,
  storage_path text not null,
  position     int not null default 0,
  created_at   timestamptz default now() not null
);

-- Primary access pattern: "all images for one garment, in display order."
create index if not exists garment_images_garment_id_idx
  on garment_images(garment_id, position);

-- RLS predicate column. Every query against this table is filtered by
-- auth.uid() = user_id (directly, or indirectly through the RLS policy),
-- so it needs its own index rather than relying on the garment_id one.
create index if not exists garment_images_user_id_idx
  on garment_images(user_id);

alter table garment_images enable row level security;

create policy "Users can manage own garment images"
  on garment_images for all using (auth.uid() = user_id);

alter table garments drop column if exists image_url;
