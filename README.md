# Modern Furniture Pacific — Supabase Backend

Supabase (Postgres) backend for the Modern Furniture Pacific website —
[zaibaki/modern-furniture-pacific](https://github.com/zaibaki/modern-furniture-pacific)
(live: https://modern-furniture-pacific-two.vercel.app).

All 35 products, 98 variants and 183 image paths from the site are stored
here. Prices are in Kenyan shillings (KES).

## What's inside

| Path | What it is |
|---|---|
| `supabase/migrations/20261123140000_init.sql` | Schema + RLS policies + grants |
| `supabase/migrations/20261123142900_product_position.sql` | `products.position` — display order (see below) |
| `supabase/seed.sql` | All data, generated from the site's `products.json` |
| `scripts/generate_seed.py` | The generator — re-run it to re-seed after the site data changes |
| `supabase/config.toml` | Local Supabase project config (from `supabase init`) |

## Schema

- **`categories`** — the product `category` values: Living Room, Bedroom,
  Dining, Tables (name + slug, both unique).
- **`products`** — one row per product: `shopify_id` (unique), `handle`
  (unique), `title`, `original_title`, `type`, `category_id` (FK),
  `collections` (text array of Shopify collection handles), `is_new`,
  `is_best_seller`, `vendor` (kept exactly as listed, including the
  `Mordern Furniture Pacific` spelling on 6 products), `description`,
  `price_min` / `price_max` (numeric, KES), `in_stock`, `original_url`,
  `position` (display order — the order in the site's `products.json`,
  which the shop page lists products in; set by the seed generator).
- **`product_variants`** — size/option rows: `option`, `price` (KES),
  `available`, `position`.
- **`product_images`** — image paths in display order: `path`
  (e.g. `/images/products/elegant-coffee-table-white-1.webp`), `position`,
  `is_premium` (false for all catalogue images; reserved for the
  premium/3D renders).
- **`business_info`** — single row for the site's header/footer data:
  name, tagline, phones, WhatsApp, email, hours, showrooms (JSON).

## Security (RLS)

- `anon` and `authenticated` roles can `SELECT` on all five tables —
  the public site reads with the anon key.
- Only `authenticated` users can insert/update/delete. The `service_role`
  key bypasses RLS entirely, so admin tooling should use that.
- Anonymous writes are denied (verified: anon `INSERT`/`DELETE` fail).

## Setup

Prerequisites: [Supabase CLI](https://supabase.com/docs/guides/cli)
(`brew install supabase` on macOS).

```bash
# 1. Create a project (dashboard, or CLI):
supabase projects create modern-furniture-pacific \
  --region eu-central-1 --db-password '<strong-random-password>'
#    Save the DB password in .env (gitignored) — see .env.example.
#    eu-central-1 (Frankfurt) matches the existing mc-beauty project.

# 2. Link this repo to the project:
supabase link --project-ref <project-ref>

# 3. Push the schema and load the data:
supabase db push
supabase db reset          # applies migrations + runs supabase/seed.sql
#    — or, to seed without resetting:
psql "$DATABASE_URL" -f supabase/seed.sql

# 4. Copy the API URL + anon key from the project dashboard into .env
#    for the site to use.
```

> **Status:** the Supabase project itself is not created yet — the CLI
> needs a login (`supabase login`) or the project creating in the
> dashboard first. The schema and seed in this repo are verified
> against PostgreSQL 16 locally (35 products, 98 variants, 183 images,
> anon-read + anon-write-denied checks pass).

## Connecting the frontend

The site ([zaibaki/modern-furniture-pacific](https://github.com/zaibaki/modern-furniture-pacific))
is already wired to talk to this backend — `src/lib/data.ts` fetches the
catalogue from Supabase when both env vars below are set, and falls back
to the baked-in `src/data/products.json` when they are not (or when the
fetch fails). The switch is automatic; no code change is needed. The
premium images are unaffected — they are local files either way.

Finish the live connection:

```bash
# 1. On the Mac, log the Supabase CLI in (one time):
supabase login

# 2. Create the project (dashboard, or CLI):
supabase projects create modern-furniture-pacific \
  --region eu-central-1 --db-password '<strong-random-password>'
#    Save the DB password in .env (gitignored) — see .env.example.
#    eu-central-1 (Frankfurt) matches the existing mc-beauty project.

# 3. Link this repo, push the schema, load the data:
supabase link --project-ref <project-ref>
supabase db push
supabase db reset          # applies migrations + runs supabase/seed.sql

# 4. In the Vercel dashboard, project modern-furniture-pacific-two →
#    Settings → Environment Variables, add:
#      NEXT_PUBLIC_SUPABASE_URL=https://<project-ref>.supabase.co
#      NEXT_PUBLIC_SUPABASE_ANON_KEY=<anon-public-key>
#    (from the Supabase project dashboard → Settings → API)

# 5. Redeploy the site (Vercel → Deployments → Redeploy, or push any
#    commit). The site switches to Supabase automatically on the next
#    build. Verify: the shop still lists all 35 products.
```

The anon key is publishable by design — RLS only allows public reads —
but it still goes in Vercel env vars / a local `.env`, never in git.
Until step 4 is done, the live site keeps reading its local JSON and
nothing changes for visitors.

## Re-generating the seed

The seed is generated, never hand-edited. If the site's product data
changes, re-run the generator from the site repo next door:

```bash
python3 scripts/generate_seed.py \
  --source ../modern-furniture-pacific/src/data/products.json
# writes supabase/seed.sql (deterministic, idempotent — safe to re-run)
```

## Example queries

```sql
-- List all products with their category and price range (KES)
select p.handle, p.title, c.name as category, p.price_min, p.price_max,
       p.in_stock
from products p
join categories c on c.id = p.category_id
order by p.title;

-- One product with its variants and images
select p.*, v.option, v.price as variant_price,
       i.path as image_path, i.position as image_position
from products p
left join product_variants v on v.product_id = p.id
left join product_images i on i.product_id = p.id
where p.handle = 'elegant-coffee-table-white'
order by v.position, i.position;

-- New arrivals
select handle, title, price_min from products where is_new order by title;

-- Business / contact info for the header and footer
select name, tagline, phone, whatsapp, email, hours, showrooms
from business_info;
```

## Images — paths only, files stay in the site repo

This backend stores image **paths**, not the image files. The 183
product photos live in the site repo
(`zaibaki/modern-furniture-pacific`, `public/images/products/`) and are
served by the site itself. If the images ever need to move into
Supabase, the migration path is a Storage bucket (`product-images`) with
the `path` column switched to the public Storage URL — that is a future
option, not in scope here.
