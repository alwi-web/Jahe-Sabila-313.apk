-- Jalankan file ini kalau schema.sql sudah pernah dijalankan sebelumnya. Aman dijalankan ulang.
-- Foto profil pengguna: kolom profiles.foto + Supabase Storage bucket "avatar" (publik untuk dibaca).
-- Setiap pengguna hanya boleh mengunggah/mengganti/menghapus file di folder miliknya (<user id>/...).
-- Supabase Dashboard > SQL Editor > New query > tempel > Run.

alter table public.profiles add column if not exists foto text;
-- Pengguna boleh mengubah kolom foto miliknya (role tetap tidak bisa diubah).
grant update (foto) on public.profiles to authenticated;

insert into storage.buckets (id, name, public)
values ('avatar', 'avatar', true)
on conflict (id) do nothing;

drop policy if exists "unggah foto profil sendiri" on storage.objects;
create policy "unggah foto profil sendiri" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatar' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "ubah foto profil sendiri" on storage.objects;
create policy "ubah foto profil sendiri" on storage.objects
  for update to authenticated
  using (bucket_id = 'avatar' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "hapus foto profil sendiri" on storage.objects;
create policy "hapus foto profil sendiri" on storage.objects
  for delete to authenticated
  using (bucket_id = 'avatar' and (storage.foldername(name))[1] = auth.uid()::text);
