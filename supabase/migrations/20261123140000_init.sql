-- Modern Furniture Pacific — initial schema
-- Generated from the live site data (site/src/data/products.json, 35 products).
-- Prices are in Kenyan shillings (KES), stored as numeric.
-- Images are stored as paths only; the files live in the site repo
-- (zaibaki/modern-furniture-pacific, public/images/...), not here.

-- ---------------------------------------------------------------------------
-- categories: the product `category` values from the site data
-- (Living Room, Bedroom, Dining, Tables)
-- ---------------------------------------------------------------------------
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  slug text not null unique,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- products: one row per Shopify product on the site
-- ---------------------------------------------------------------------------
create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  shopify_id bigint not null unique,
  handle text not null unique,
  title text not null,
  original_title text,
  type text,
  category_id uuid references public.categories (id),
  collections text[] not null default '{}',
  is_new boolean not null default false,
  is_best_seller boolean not null default false,
  vendor text,
  description text,
  price_min numeric(12, 2) not null,
  price_max numeric(12, 2) not null,
  in_stock boolean not null default true,
  original_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists products_handle_idx on public.products (handle);
create index if not exists products_category_id_idx on public.products (category_id);
create index if not exists products_type_idx on public.products (type);

-- ---------------------------------------------------------------------------
-- product_variants: size/option rows per product (price per option, KES)
-- ---------------------------------------------------------------------------
create table if not exists public.product_variants (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products (id) on delete cascade,
  option text not null,
  price numeric(12, 2) not null,
  available boolean not null default true,
  position integer not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists product_variants_product_id_idx
  on public.product_variants (product_id);

-- ---------------------------------------------------------------------------
-- product_images: image paths per product, in display order.
-- Paths are relative to the site repo's public/ dir
-- (e.g. /images/products/elegant-coffee-table-white-1.webp).
-- is_premium is reserved for the premium/3D renders that live in the
-- site repo; the seed sets it false for all 183 catalogue images.
-- ---------------------------------------------------------------------------
create table if not exists public.product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products (id) on delete cascade,
  path text not null,
  position integer not null default 0,
  is_premium boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists product_images_product_id_idx
  on public.product_images (product_id);

-- ---------------------------------------------------------------------------
-- business_info: single-row store for the site's header/footer data
-- (name, tagline, phones, WhatsApp, email, hours, showrooms).
-- Seeded from the `business` block in products.json.
-- ---------------------------------------------------------------------------
create table if not exists public.business_info (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  tagline text,
  phone text[] not null default '{}',
  whatsapp text,
  email text,
  hours text,
  showrooms jsonb not null default '[]'::jsonb,
  source_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Row Level Security: public read, writes only for authenticated users.
-- The service_role key bypasses RLS entirely, so admin tooling that
-- uses it can write regardless of these policies. Anonymous users
-- cannot insert, update or delete anything.
--
-- NOTE: RLS policies alone do not grant access — the roles also need
-- table-level GRANTs, which are included below. Without them, even a
-- passing policy would return "permission denied for table".
-- ---------------------------------------------------------------------------
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.product_variants enable row level security;
alter table public.product_images enable row level security;
alter table public.business_info enable row level security;

grant usage on schema public to anon, authenticated;

grant select on public.categories to anon, authenticated;
grant select on public.products to anon, authenticated;
grant select on public.product_variants to anon, authenticated;
grant select on public.product_images to anon, authenticated;
grant select on public.business_info to anon, authenticated;

grant insert, update, delete on public.categories to authenticated;
grant insert, update, delete on public.products to authenticated;
grant insert, update, delete on public.product_variants to authenticated;
grant insert, update, delete on public.product_images to authenticated;
grant insert, update, delete on public.business_info to authenticated;

create policy "Public read access" on public.categories
  for select to anon, authenticated using (true);

create policy "Public read access" on public.products
  for select to anon, authenticated using (true);

create policy "Public read access" on public.product_variants
  for select to anon, authenticated using (true);

create policy "Public read access" on public.product_images
  for select to anon, authenticated using (true);

create policy "Public read access" on public.business_info
  for select to anon, authenticated using (true);

create policy "Authenticated users can insert" on public.categories
  for insert to authenticated with check (true);

create policy "Authenticated users can update" on public.categories
  for update to authenticated using (true) with check (true);

create policy "Authenticated users can delete" on public.categories
  for delete to authenticated using (true);

create policy "Authenticated users can insert" on public.products
  for insert to authenticated with check (true);

create policy "Authenticated users can update" on public.products
  for update to authenticated using (true) with check (true);

create policy "Authenticated users can delete" on public.products
  for delete to authenticated using (true);

create policy "Authenticated users can insert" on public.product_variants
  for insert to authenticated with check (true);

create policy "Authenticated users can update" on public.product_variants
  for update to authenticated using (true) with check (true);

create policy "Authenticated users can delete" on public.product_variants
  for delete to authenticated using (true);

create policy "Authenticated users can insert" on public.product_images
  for insert to authenticated with check (true);

create policy "Authenticated users can update" on public.product_images
  for update to authenticated using (true) with check (true);

create policy "Authenticated users can delete" on public.product_images
  for delete to authenticated using (true);

create policy "Authenticated users can insert" on public.business_info
  for insert to authenticated with check (true);

create policy "Authenticated users can update" on public.business_info
  for update to authenticated using (true) with check (true);

create policy "Authenticated users can delete" on public.business_info
  for delete to authenticated using (true);
