-- Display order for products, matching the order in the site's
-- products.json (the order the shop page lists them in).
-- The seed sets position from the JSON order. Without it the frontend
-- would have to guess (alphabetical), and the shop order would change
-- the moment the site switches to Supabase.
alter table public.products
  add column if not exists position integer not null default 0;

create index if not exists products_position_idx
  on public.products (position);
