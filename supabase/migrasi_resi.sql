-- Jalankan file ini kalau schema.sql sudah pernah dijalankan sebelumnya.
-- Menambah kolom kurir (JNE / J&T) dan nomor resi pengiriman ke tabel pesanan.
-- Admin sudah boleh mengubah baris pesanan lewat aturan RLS "admin ubah status pesanan".
-- Supabase Dashboard > SQL Editor > New query > tempel > Run. Aman dijalankan ulang.

alter table public.pesanan add column if not exists kurir text;
alter table public.pesanan add column if not exists no_resi text;

alter table public.pesanan drop constraint if exists pesanan_kurir_check;
alter table public.pesanan add constraint pesanan_kurir_check check (kurir in ('JNE', 'J&T'));
