-- Magic Media: community-uploaded AR triggers.
-- Lives alongside this project's existing n8n tables (public.documents, public.n8n_chat_histories).

create table public.triggers (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid not null references auth.users(id) on delete cascade,
    title text not null,
    target_image_path text not null,
    physical_width_meters real not null check (physical_width_meters > 0),
    content_type text not null check (content_type in ('video', 'audio', 'model')),
    content_path text not null,
    status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
    created_at timestamptz not null default now()
);

create table public.reports (
    id uuid primary key default gen_random_uuid(),
    trigger_id uuid not null references public.triggers(id) on delete cascade,
    reporter_id uuid not null references auth.users(id) on delete cascade,
    reason text not null,
    created_at timestamptz not null default now()
);

alter table public.triggers enable row level security;
alter table public.reports enable row level security;

create policy "Approved triggers are readable by anyone signed in; owners can read their own regardless of status"
    on public.triggers for select
    to authenticated
    using (status = 'approved' or owner_id = auth.uid());

create policy "Users can insert their own triggers"
    on public.triggers for insert
    to authenticated
    with check (owner_id = auth.uid());

create policy "Owners can update their own triggers"
    on public.triggers for update
    to authenticated
    using (owner_id = auth.uid())
    with check (owner_id = auth.uid());

create policy "Owners can delete their own triggers"
    on public.triggers for delete
    to authenticated
    using (owner_id = auth.uid());

create policy "Users can file reports as themselves"
    on public.reports for insert
    to authenticated
    with check (reporter_id = auth.uid());

-- Storage buckets for target images and playable content. Both private;
-- clients read via short-lived signed URLs (see TriggerService.swift).
insert into storage.buckets (id, name, public)
values ('trigger-targets', 'trigger-targets', false),
       ('trigger-content', 'trigger-content', false);

create policy "Users can upload their own trigger targets"
    on storage.objects for insert
    to authenticated
    with check (bucket_id = 'trigger-targets' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Users can upload their own trigger content"
    on storage.objects for insert
    to authenticated
    with check (bucket_id = 'trigger-content' and (storage.foldername(name))[1] = auth.uid()::text);

-- Only the owner or, once approved, any signed-in user can read a given file —
-- mirrors the triggers-table SELECT policy so pending uploads can't be read via
-- a guessed/enumerated storage path even though the bucket itself is private.
create policy "Read own or approved trigger targets"
    on storage.objects for select
    to authenticated
    using (
        bucket_id = 'trigger-targets'
        and (
            (storage.foldername(name))[1] = auth.uid()::text
            or exists (
                select 1 from public.triggers t
                where t.target_image_path = storage.objects.name
                  and t.status = 'approved'
            )
        )
    );

create policy "Read own or approved trigger content"
    on storage.objects for select
    to authenticated
    using (
        bucket_id = 'trigger-content'
        and (
            (storage.foldername(name))[1] = auth.uid()::text
            or exists (
                select 1 from public.triggers t
                where t.content_path = storage.objects.name
                  and t.status = 'approved'
            )
        )
    );
