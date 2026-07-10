-- ─── Garments: support multiple photos per garment ─────────────────────────────
alter table garments add column if not exists image_urls text[] not null default '{}';

update garments
set image_urls = array[image_url]
where image_url is not null and image_urls = '{}';

alter table garments drop column if exists image_url;
