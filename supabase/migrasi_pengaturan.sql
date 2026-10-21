-- Jalankan file ini kalau schema.sql sudah pernah dijalankan sebelumnya.
-- Membuat tabel pengaturan_toko (nomor WhatsApp toko yang bisa diubah admin dari aplikasi).
-- Supabase Dashboard > SQL Editor > New query > tempel > Run. Aman dijalankan ulang.

create table if not exists public.pengaturan_toko (
  id integer primary key default 1 check (id = 1),
  no_wa text not null
);
alter table public.pengaturan_toko enable row level security;

drop policy if exists "semua boleh lihat pengaturan toko" on public.pengaturan_toko;
create policy "semua boleh lihat pengaturan toko" on public.pengaturan_toko
  for select using (true);

drop policy if exists "admin ubah pengaturan toko" on public.pengaturan_toko;
create policy "admin ubah pengaturan toko" on public.pengaturan_toko
  for all using (public.is_admin()) with check (public.is_admin());

insert into public.pengaturan_toko (id, no_wa) values (1, '6288808425275') on conflict (id) do nothing;
