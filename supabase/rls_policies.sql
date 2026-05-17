-- Tinka Supabase RLS setup
-- Run this in Supabase Dashboard -> SQL Editor.
-- It makes every user own only their own rows, including child tables.

alter table if exists public.combo_items
    add column if not exists user_id uuid references auth.users(id) on delete cascade;

alter table if exists public.sale_items
    add column if not exists user_id uuid references auth.users(id) on delete cascade;

update public.combo_items ci
set user_id = c.user_id
from public.combos c
where ci.combo_id = c.id
  and ci.user_id is null;

update public.sale_items si
set user_id = s.user_id
from public.sales s
where si.sale_id = s.id
  and si.user_id is null;

alter table public.business_profiles enable row level security;
alter table public.products enable row level security;
alter table public.combos enable row level security;
alter table public.combo_items enable row level security;
alter table public.sales enable row level security;
alter table public.sale_items enable row level security;
alter table public.chat_messages enable row level security;

drop policy if exists "Users can read own business profile" on public.business_profiles;
drop policy if exists "Users can insert own business profile" on public.business_profiles;
drop policy if exists "Users can update own business profile" on public.business_profiles;
drop policy if exists "Users can delete own business profile" on public.business_profiles;

create policy "Users can read own business profile"
on public.business_profiles for select
using (auth.uid() = user_id);

create policy "Users can insert own business profile"
on public.business_profiles for insert
with check (auth.uid() = user_id);

create policy "Users can update own business profile"
on public.business_profiles for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can delete own business profile"
on public.business_profiles for delete
using (auth.uid() = user_id);

drop policy if exists "Users can read own products" on public.products;
drop policy if exists "Users can insert own products" on public.products;
drop policy if exists "Users can update own products" on public.products;
drop policy if exists "Users can delete own products" on public.products;

create policy "Users can read own products"
on public.products for select
using (auth.uid() = user_id);

create policy "Users can insert own products"
on public.products for insert
with check (auth.uid() = user_id);

create policy "Users can update own products"
on public.products for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can delete own products"
on public.products for delete
using (auth.uid() = user_id);

drop policy if exists "Users can read own combos" on public.combos;
drop policy if exists "Users can insert own combos" on public.combos;
drop policy if exists "Users can update own combos" on public.combos;
drop policy if exists "Users can delete own combos" on public.combos;

create policy "Users can read own combos"
on public.combos for select
using (auth.uid() = user_id);

create policy "Users can insert own combos"
on public.combos for insert
with check (auth.uid() = user_id);

create policy "Users can update own combos"
on public.combos for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can delete own combos"
on public.combos for delete
using (auth.uid() = user_id);

drop policy if exists "Users can read own combo items" on public.combo_items;
drop policy if exists "Users can insert own combo items" on public.combo_items;
drop policy if exists "Users can update own combo items" on public.combo_items;
drop policy if exists "Users can delete own combo items" on public.combo_items;

create policy "Users can read own combo items"
on public.combo_items for select
using (auth.uid() = user_id);

create policy "Users can insert own combo items"
on public.combo_items for insert
with check (
    auth.uid() = user_id
    and exists (
        select 1 from public.combos c
        where c.id = combo_id and c.user_id = auth.uid()
    )
);

create policy "Users can update own combo items"
on public.combo_items for update
using (auth.uid() = user_id)
with check (
    auth.uid() = user_id
    and exists (
        select 1 from public.combos c
        where c.id = combo_id and c.user_id = auth.uid()
    )
);

create policy "Users can delete own combo items"
on public.combo_items for delete
using (auth.uid() = user_id);

drop policy if exists "Users can read own sales" on public.sales;
drop policy if exists "Users can insert own sales" on public.sales;
drop policy if exists "Users can update own sales" on public.sales;
drop policy if exists "Users can delete own sales" on public.sales;

create policy "Users can read own sales"
on public.sales for select
using (auth.uid() = user_id);

create policy "Users can insert own sales"
on public.sales for insert
with check (auth.uid() = user_id);

create policy "Users can update own sales"
on public.sales for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can delete own sales"
on public.sales for delete
using (auth.uid() = user_id);

drop policy if exists "Users can read own sale items" on public.sale_items;
drop policy if exists "Users can insert own sale items" on public.sale_items;
drop policy if exists "Users can update own sale items" on public.sale_items;
drop policy if exists "Users can delete own sale items" on public.sale_items;

create policy "Users can read own sale items"
on public.sale_items for select
using (auth.uid() = user_id);

create policy "Users can insert own sale items"
on public.sale_items for insert
with check (
    auth.uid() = user_id
    and exists (
        select 1 from public.sales s
        where s.id = sale_id and s.user_id = auth.uid()
    )
);

create policy "Users can update own sale items"
on public.sale_items for update
using (auth.uid() = user_id)
with check (
    auth.uid() = user_id
    and exists (
        select 1 from public.sales s
        where s.id = sale_id and s.user_id = auth.uid()
    )
);

create policy "Users can delete own sale items"
on public.sale_items for delete
using (auth.uid() = user_id);

drop policy if exists "Users can read own chat messages" on public.chat_messages;
drop policy if exists "Users can insert own chat messages" on public.chat_messages;
drop policy if exists "Users can update own chat messages" on public.chat_messages;
drop policy if exists "Users can delete own chat messages" on public.chat_messages;

create policy "Users can read own chat messages"
on public.chat_messages for select
using (auth.uid() = user_id);

create policy "Users can insert own chat messages"
on public.chat_messages for insert
with check (auth.uid() = user_id);

create policy "Users can update own chat messages"
on public.chat_messages for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can delete own chat messages"
on public.chat_messages for delete
using (auth.uid() = user_id);
