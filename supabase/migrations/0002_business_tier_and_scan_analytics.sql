-- Business tier tagging + scan analytics for the brand/business offering.
--
-- Compliance note: `profiles.is_business` is intentionally admin-only (no
-- client-side write policy). The app never reads or branches on this flag —
-- "priority review" is a manual operational choice made in Supabase Studio,
-- not an app feature. Making it an in-app toggle/purchase would require
-- Apple's In-App Purchase system (Guideline 3.1.1 / 3.1.3(g)); keeping it
-- entirely out of the app's code avoids that.

create table public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    is_business boolean not null default false,
    business_name text,
    created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Users can read their own profile"
    on public.profiles for select
    to authenticated
    using (id = auth.uid());

-- No insert/update policy for authenticated/anon — profiles are created and
-- is_business is set only via the Studio table editor (service role).

create table public.trigger_scans (
    id uuid primary key default gen_random_uuid(),
    trigger_id uuid not null references public.triggers(id) on delete cascade,
    scanned_at timestamptz not null default now()
);

alter table public.trigger_scans enable row level security;

-- Anyone can log a scan of an approved trigger — scanning doesn't require
-- sign-in in the app, so this must work for the anon role too.
create policy "Anyone can log a scan of an approved trigger"
    on public.trigger_scans for insert
    to anon, authenticated
    with check (
        exists (
            select 1 from public.triggers t
            where t.id = trigger_scans.trigger_id
              and t.status = 'approved'
        )
    );

-- A trigger's owner can read their own raw scan rows.
create policy "Owners can read scan rows for their own triggers"
    on public.trigger_scans for select
    to authenticated
    using (
        exists (
            select 1 from public.triggers t
            where t.id = trigger_scans.trigger_id
              and t.owner_id = auth.uid()
        )
    );

-- Narrow, read-only functions for the external analytics page, so it can
-- show a count/trend for a given trigger without needing the viewer to
-- authenticate as the trigger's owner (link-based sharing, like a view
-- counter) and without exposing raw scan rows.

create or replace function public.get_scan_count(p_trigger_id uuid)
returns bigint
language sql
security definer
set search_path = public
as $$
    select count(*) from public.trigger_scans where trigger_id = p_trigger_id;
$$;

grant execute on function public.get_scan_count(uuid) to anon, authenticated;

create or replace function public.get_scan_counts_daily(p_trigger_id uuid, p_days int default 30)
returns table(day date, scans bigint)
language sql
security definer
set search_path = public
as $$
    select date_trunc('day', scanned_at)::date as day, count(*) as scans
    from public.trigger_scans
    where trigger_id = p_trigger_id
      and scanned_at >= now() - (p_days || ' days')::interval
    group by 1
    order by 1;
$$;

grant execute on function public.get_scan_counts_daily(uuid, int) to anon, authenticated;
