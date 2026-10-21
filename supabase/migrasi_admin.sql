-- Jalankan file ini HANYA kalau schema.sql versi sebelumnya sudah pernah dijalankan.
-- Isinya fungsi admin untuk mengubah status pesanan (dengan pengembalian stok saat dibatalkan)
-- dan penyimpanan foto produk.
-- Supabase Dashboard > SQL Editor > New query > tempel > Run.

-- Admin mengubah status pesanan. Kalau dibatalkan, stok dikembalikan;
-- kalau pembatalan dicabut, stok dipotong lagi (ditolak kalau stok tidak cukup).
create or replace function public.ubah_status_pesanan(p_id bigint, p_status text) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_lama text;
  v_kurang text;
begin
  if not public.is_admin() then
    raise exception 'Hanya admin yang boleh mengubah status';
  end if;
  if p_status not in ('menunggu', 'diproses', 'selesai', 'batal') then
    raise exception 'Status tidak dikenal: %', p_status;
  end if;

  select status into v_lama from public.pesanan where id = p_id for update;
  if not found then
    raise exception 'Pesanan tidak ditemukan';
  end if;

  if v_lama <> 'batal' and p_status = 'batal' then
    update public.varian_produk v
    set stok = v.stok + d.jumlah
    from public.detail_pesanan d
    where d.pesanan_id = p_id and d.varian_id = v.id and v.stok is not null;
  elsif v_lama = 'batal' and p_status <> 'batal' then
    select d.nama_produk || ' ' || d.ukuran into v_kurang
    from public.detail_pesanan d join public.varian_produk v on v.id = d.varian_id
    where d.pesanan_id = p_id and v.stok is not null and v.stok < d.jumlah
    limit 1;
    if v_kurang is not null then
      raise exception 'Stok tidak cukup: %', v_kurang;
    end if;
    update public.varian_produk v
    set stok = v.stok - d.jumlah
    from public.detail_pesanan d
    where d.pesanan_id = p_id and d.varian_id = v.id and v.stok is not null;
  end if;

  update public.pesanan set status = p_status where id = p_id;
end;
$$;

revoke execute on function public.ubah_status_pesanan(bigint, text) from public, anon;
grant execute on function public.ubah_status_pesanan(bigint, text) to authenticated;

-- =====================================================================
-- Foto produk: Supabase Storage, bucket "produk" (publik untuk dibaca).
-- Hanya admin yang boleh mengunggah, mengganti, dan menghapus foto.
-- =====================================================================
insert into storage.buckets (id, name, public)
values ('produk', 'produk', true)
on conflict (id) do nothing;

drop policy if exists "admin unggah foto produk" on storage.objects;
create policy "admin unggah foto produk" on storage.objects
  for insert to authenticated with check (bucket_id = 'produk' and public.is_admin());
drop policy if exists "admin ubah foto produk" on storage.objects;
create policy "admin ubah foto produk" on storage.objects
  for update to authenticated using (bucket_id = 'produk' and public.is_admin());
drop policy if exists "admin hapus foto produk" on storage.objects;
create policy "admin hapus foto produk" on storage.objects
  for delete to authenticated using (bucket_id = 'produk' and public.is_admin());
