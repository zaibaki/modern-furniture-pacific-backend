-- Modern Furniture Pacific — customer order requests from the AI assistant & site

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  reference text not null unique,
  product_handle text not null,
  product_title text not null,
  product_price text,
  option text,
  quantity integer not null default 1 check (quantity > 0),
  customer_name text not null,
  phone text not null,
  location text not null,
  notes text,
  status text not null default 'new' check (
    status in ('new', 'contacted', 'confirmed', 'dispatched', 'completed', 'cancelled')
  ),
  whatsapp_link text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists orders_created_at_idx on public.orders (created_at desc);
create index if not exists orders_status_idx on public.orders (status);

alter table public.orders enable row level security;

-- Customers can submit orders anonymously; only authenticated/service_role can read or update them.
grant insert on public.orders to anon, authenticated;
grant select, update, delete on public.orders to authenticated;

create policy "Anyone can submit orders" on public.orders
  for insert to anon, authenticated with check (true);

create policy "Authenticated users can view orders" on public.orders
  for select to authenticated using (true);

create policy "Authenticated users can update orders" on public.orders
  for update to authenticated using (true) with check (true);
