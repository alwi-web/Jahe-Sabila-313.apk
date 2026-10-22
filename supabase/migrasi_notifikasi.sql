-- Jalankan file ini kalau schema.sql sudah pernah dijalankan sebelumnya. Aman dijalankan ulang.
-- Token push notification (Firebase) per HP. Satu token = satu HP; kalau HP itu dipakai login
-- akun lain, tokennya pindah ke akun tersebut. Edge Function "kirim-notif" membaca tabel ini
-- dengan service role untuk mengirim notifikasi.
-- Supabase Dashboard > SQL Editor > New query > tempel > Run.

create table if not exists public.perangkat_notif (
  token text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  diperbarui timestamptz not null default now()
);
alter table public.perangkat_notif enable row level security;
-- Tidak ada policy: aplikasi hanya lewat dua fungsi di bawah; Edge Function memakai service role.

create or replace function public.simpan_token_notif(p_token text) returns void
language sql security definer set search_path = public as $$
  insert into public.perangkat_notif (token, user_id) values (p_token, auth.uid())
  on conflict (token) do update set user_id = auth.uid(), diperbarui = now();
$$;
revoke execute on function public.simpan_token_notif(text) from public, anon;
grant execute on function public.simpan_token_notif(text) to authenticated;

create or replace function public.hapus_token_notif(p_token text) returns void
language sql security definer set search_path = public as $$
  delete from public.perangkat_notif where token = p_token and user_id = auth.uid();
$$;
revoke execute on function public.hapus_token_notif(text) from public, anon;
grant execute on function public.hapus_token_notif(text) to authenticated;
