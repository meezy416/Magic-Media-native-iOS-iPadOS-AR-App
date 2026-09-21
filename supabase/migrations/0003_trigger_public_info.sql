-- Lets the external brand analytics page show a trigger's title without
-- needing the viewer to authenticate — same link-based-sharing pattern as
-- get_scan_count/get_scan_counts_daily, and just as narrow: only approved
-- triggers, only these three columns.

create or replace function public.get_trigger_public_info(p_trigger_id uuid)
returns table(title text, content_type text, created_at timestamptz)
language sql
security definer
set search_path = public
as $$
    select title, content_type, created_at
    from public.triggers
    where id = p_trigger_id and status = 'approved';
$$;

grant execute on function public.get_trigger_public_info(uuid) to anon, authenticated;
