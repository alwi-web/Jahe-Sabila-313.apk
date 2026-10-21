-- Jalankan file ini kalau schema.sql sudah pernah dijalankan sebelumnya. Aman dijalankan ulang.
-- 1) Pesanan "menunggu" yang lewat 3 jam dibatalkan otomatis (stok dikembalikan).
-- 2) Pesanan mencatat kapan status/resi berubah (diperbarui) dan kapan pembeli melihatnya
--    (dibaca_pembeli), untuk notif merah di aplikasi pembeli.
-- Supabase Dashboard > SQL Editor > New query > tempel > Run.

alter table public.pesanan add column if not exists diperbarui timestamptz;
alter table public.pesanan add column if not exists dibaca_pembeli timestamptz;

-- Setiap perubahan status, kurir, atau resi menandai pesanan sebagai diperbarui.
create or replace function public.tandai_pesanan_diperbarui() returns trigger
language plpgsql as $$
begin
  if new.status is distinct from old.status
     or new.kurir is distinct from old.kurir
     or new.no_resi is distinct from old.no_resi then
    new.diperbarui := now();
  end if;
  return new;
end;
$$;

drop trigger if exists pesanan_diperbarui on public.pesanan;
create trigger pesanan_diperbarui before update on public.pesanan
  for each row execute function public.tandai_pesanan_diperbarui();

-- Membatalkan pesanan "menunggu" yang dibuat lebih dari 3 jam lalu dan mengembalikan stoknya.
-- Mengembalikan jumlah pesanan yang dibatalkan.
create or replace function public.batalkan_pesanan_kedaluwarsa() returns integer
language plpgsql security definer set search_path = public as $$
declare
  v_ids bigint[];
begin
  select coalesce(array_agg(id), '{}') into v_ids
  from (
    select id from public.pesanan
    where status = 'menunggu' and tanggal < now() - interval '3 hours'
    for update skip locked
  ) t;

  if cardinality(v_ids) = 0 then
    return 0;
  end if;

  update public.varian_produk v
  set stok = v.stok + d.jumlah
  from public.detail_pesanan d
  where d.pesanan_id = any(v_ids) and d.varian_id = v.id and v.stok is not null;

  update public.pesanan set status = 'batal' where id = any(v_ids);
  return cardinality(v_ids);
end;
$$;
revoke execute on function public.batalkan_pesanan_kedaluwarsa() from public, anon;
grant execute on function public.batalkan_pesanan_kedaluwarsa() to authenticated;

-- Pembeli menandai perubahan pesanannya sudah dilihat (notif merah hilang).
create or replace function public.tandai_pesanan_dibaca() returns void
language sql security definer set search_path = public as $$
  update public.pesanan set dibaca_pembeli = now()
  where user_id = auth.uid() and diperbarui is not null;
$$;
revoke execute on function public.tandai_pesanan_dibaca() from public, anon;
grant execute on function public.tandai_pesanan_dibaca() to authenticated;

-- Jalankan pembatalan otomatis tiap 10 menit, walaupun tidak ada yang membuka aplikasi.
-- (Kalau bagian ini gagal, aktifkan dulu pg_cron di Database > Extensions lalu jalankan 3 baris ini lagi.
--  Tanpa jadwal ini, pembatalan tetap terjadi setiap kali aplikasi memuat daftar pesanan.)
create extension if not exists pg_cron with schema pg_catalog;
select cron.unschedule(jobid) from cron.job where jobname = 'batalkan-pesanan-kedaluwarsa';
select cron.schedule('batalkan-pesanan-kedaluwarsa', '*/10 * * * *', 'select public.batalkan_pesanan_kedaluwarsa()');
