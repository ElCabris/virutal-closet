-- ─── Garments: track which currency each price was entered in ──────────────────
-- Garments can be bought in different currencies (e.g. imported vs local
-- purchases), so currency is tracked per garment rather than as a single
-- app-wide setting. Defaults to COP so existing rows and the app's primary
-- market don't require an explicit choice.
alter table garments
  add column if not exists currency text not null default 'COP';
