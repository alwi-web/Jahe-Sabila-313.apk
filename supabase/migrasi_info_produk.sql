-- Jalankan file ini kalau schema.sql sudah pernah dijalankan sebelumnya. Aman dijalankan ulang.
-- Informasi tambahan produk yang diisi admin dan tampil di halaman detail produk.
-- Admin sudah boleh mengubah tabel produk lewat aturan RLS "admin kelola produk".

alter table public.produk add column if not exists komposisi text;
alter table public.produk add column if not exists saran_penyajian text;
alter table public.produk add column if not exists saran_penyimpanan text;
