-- =====================================================================
-- Jahe Merah Sabila 313 — skema database Supabase
-- Cara pakai: Supabase Dashboard > SQL Editor > New query > tempel > Run.
-- Jalankan SEKALI pada proyek baru.
--
-- Sesuai ERD: users (auth.users + profiles), alamat, produk, varian_produk,
-- keranjang, pesanan, detail_pesanan. Tabel kode_reset dan admin tidak
-- dibuat terpisah: kode reset password ditangani Supabase Auth (OTP email),
-- dan admin ditandai dengan profiles.role = 'admin'.
-- =====================================================================

-- ---------- Profil pengguna (data tambahan untuk auth.users) ----------
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nama text not null default '',
  no_hp text not null default '',
  role text not null default 'pembeli' check (role in ('pembeli', 'admin')),
  created_at timestamptz not null default now()
);

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

-- Saat pengguna mendaftar, buat baris profil dari data registrasi (nama, no_hp).
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, nama, no_hp)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'nama', ''),
    coalesce(new.raw_user_meta_data ->> 'no_hp', '')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------- Produk dan varian (harga per ukuran) ----------
create table public.produk (
  id bigint generated always as identity primary key,
  nama text not null,
  deskripsi text not null default '',
  gambar text,                                  -- URL foto (opsional)
  warna text not null default '#A8321F',        -- warna garis label kemasan
  aktif boolean not null default true
);

create table public.varian_produk (
  id bigint generated always as identity primary key,
  produk_id bigint not null references public.produk(id) on delete cascade,
  ukuran text not null check (ukuran in ('250 g', '500 g', '1 kg')),
  harga integer not null check (harga > 0),
  stok integer check (stok is null or stok >= 0),   -- null = stok tidak dihitung
  unique (produk_id, ukuran)
);

-- ---------- Alamat pengiriman ----------
create table public.alamat (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  label text not null default 'Rumah',
  nama_penerima text not null,
  no_hp text not null,
  alamat_lengkap text not null,
  kota text not null,
  kode_pos text not null,
  catatan text not null default '',
  is_utama boolean not null default false
);
-- Hanya boleh ada satu alamat utama per pengguna.
create unique index alamat_satu_utama on public.alamat (user_id) where is_utama;

-- ---------- Keranjang ----------
create table public.keranjang (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  varian_id bigint not null references public.varian_produk(id) on delete cascade,
  jumlah integer not null check (jumlah > 0),
  unique (user_id, varian_id)
);

-- ---------- Pesanan ----------
create table public.pesanan (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  tanggal timestamptz not null default now(),
  total integer not null,
  alamat_kirim text not null,                   -- salinan alamat saat checkout
  status text not null default 'menunggu'
    check (status in ('menunggu', 'diproses', 'selesai', 'batal')),
  kurir text check (kurir in ('JNE', 'J&T')),     -- diisi admin saat dikirim
  no_resi text,
  diperbarui timestamptz,                        -- terakhir status/kurir/resi berubah
  dibaca_pembeli timestamptz                     -- terakhir pembeli melihat perubahan
);

create table public.detail_pesanan (
  id bigint generated always as identity primary key,
  pesanan_id bigint not null references public.pesanan(id) on delete cascade,
  varian_id bigint references public.varian_produk(id) on delete set null,
  nama_produk text not null,                    -- salinan nama saat checkout
  ukuran text not null,
  jumlah integer not null check (jumlah > 0),
  harga_satuan integer not null                 -- salinan harga saat checkout
);

-- =====================================================================
-- Keamanan baris (RLS): pembeli hanya bisa melihat dan mengubah datanya sendiri.
-- =====================================================================
alter table public.profiles       enable row level security;
alter table public.produk         enable row level security;
alter table public.varian_produk  enable row level security;
alter table public.alamat         enable row level security;
alter table public.keranjang      enable row level security;
alter table public.pesanan        enable row level security;
alter table public.detail_pesanan enable row level security;

create policy "lihat profil sendiri" on public.profiles
  for select using (id = auth.uid() or public.is_admin());
create policy "ubah profil sendiri" on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());
-- Pembeli hanya boleh mengubah nama dan no_hp, bukan role.
revoke update on public.profiles from authenticated, anon;
grant update (nama, no_hp) on public.profiles to authenticated;

create policy "semua bisa lihat produk" on public.produk for select using (true);
create policy "admin kelola produk" on public.produk
  for all using (public.is_admin()) with check (public.is_admin());

create policy "semua bisa lihat varian" on public.varian_produk for select using (true);
create policy "admin kelola varian" on public.varian_produk
  for all using (public.is_admin()) with check (public.is_admin());

create policy "alamat sendiri" on public.alamat
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "keranjang sendiri" on public.keranjang
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Pesanan dibuat lewat fungsi buat_pesanan (tidak ada izin insert langsung).
create policy "lihat pesanan sendiri" on public.pesanan
  for select using (user_id = auth.uid() or public.is_admin());
create policy "admin ubah status pesanan" on public.pesanan
  for update using (public.is_admin()) with check (public.is_admin());

create policy "lihat detail pesanan sendiri" on public.detail_pesanan
  for select using (
    exists (
      select 1 from public.pesanan p
      where p.id = pesanan_id and (p.user_id = auth.uid() or public.is_admin())
    )
  );

-- =====================================================================
-- Fungsi yang dipanggil aplikasi (RPC)
-- =====================================================================

-- Menjadikan satu alamat sebagai alamat utama milik pengguna yang login.
create or replace function public.set_alamat_utama(p_id bigint) returns void
language plpgsql security invoker set search_path = public as $$
begin
  if not exists (select 1 from public.alamat where id = p_id and user_id = auth.uid()) then
    raise exception 'Alamat tidak ditemukan';
  end if;
  update public.alamat set is_utama = false where user_id = auth.uid() and is_utama and id <> p_id;
  update public.alamat set is_utama = true where id = p_id;
end;
$$;

-- Mengubah isi keranjang menjadi pesanan dalam satu transaksi:
-- cek alamat dan stok, simpan pesanan + detail (dengan harga saat ini),
-- kurangi stok, lalu kosongkan keranjang. Mengembalikan id pesanan.
create or replace function public.buat_pesanan(p_alamat_id bigint) returns bigint
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_alamat public.alamat;
  v_total integer;
  v_id bigint;
  v_kurang text;
begin
  if v_uid is null then
    raise exception 'Belum login';
  end if;

  select * into v_alamat from public.alamat where id = p_alamat_id and user_id = v_uid;
  if not found then
    raise exception 'Alamat pengiriman tidak ditemukan';
  end if;

  if not exists (select 1 from public.keranjang where user_id = v_uid) then
    raise exception 'Keranjang masih kosong';
  end if;

  select p.nama || ' ' || v.ukuran into v_kurang
  from public.keranjang k
  join public.varian_produk v on v.id = k.varian_id
  join public.produk p on p.id = v.produk_id
  where k.user_id = v_uid and v.stok is not null and v.stok < k.jumlah
  limit 1;
  if v_kurang is not null then
    raise exception 'Stok tidak cukup: %', v_kurang;
  end if;

  select sum(k.jumlah * v.harga) into v_total
  from public.keranjang k join public.varian_produk v on v.id = k.varian_id
  where k.user_id = v_uid;

  insert into public.pesanan (user_id, total, alamat_kirim)
  values (
    v_uid,
    v_total,
    v_alamat.nama_penerima || ' (' || v_alamat.no_hp || ')' || E'\n'
      || v_alamat.alamat_lengkap || ', ' || v_alamat.kota || ' ' || v_alamat.kode_pos
      || case when v_alamat.catatan <> '' then E'\nCatatan: ' || v_alamat.catatan else '' end
  )
  returning id into v_id;

  insert into public.detail_pesanan (pesanan_id, varian_id, nama_produk, ukuran, jumlah, harga_satuan)
  select v_id, v.id, p.nama, v.ukuran, k.jumlah, v.harga
  from public.keranjang k
  join public.varian_produk v on v.id = k.varian_id
  join public.produk p on p.id = v.produk_id
  where k.user_id = v_uid;

  update public.varian_produk v
  set stok = v.stok - k.jumlah
  from public.keranjang k
  where k.varian_id = v.id and k.user_id = v_uid and v.stok is not null;

  delete from public.keranjang where user_id = v_uid;
  return v_id;
end;
$$;

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
revoke execute on function public.buat_pesanan(bigint) from public, anon;
grant execute on function public.buat_pesanan(bigint) to authenticated;
revoke execute on function public.set_alamat_utama(bigint) from public, anon;
grant execute on function public.set_alamat_utama(bigint) to authenticated;

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

-- =====================================================================
-- Data awal: 3 varian x 3 ukuran dengan harga toko
-- =====================================================================
with p as (
  insert into public.produk (nama, deskripsi, warna) values
    ('Jahe Merah dengan Gula Pasir', 'Jahe merah dengan tambahan gula pasir.', '#B8412C'),
    ('Jahe Merah dengan Gula Merah', 'Jahe merah dengan tambahan gula merah.', '#7A4A1E'),
    ('Jahe Merah Tanpa Gula',        'Jahe merah murni, tanpa tambahan gula.', '#3F6B4F')
  returning id, nama
)
insert into public.varian_produk (produk_id, ukuran, harga)
select p.id, v.ukuran, v.harga
from p
join (values
  ('Jahe Merah dengan Gula Pasir', '250 g', 28000),
  ('Jahe Merah dengan Gula Pasir', '500 g', 55000),
  ('Jahe Merah dengan Gula Pasir', '1 kg', 105000),
  ('Jahe Merah dengan Gula Merah', '250 g', 30000),
  ('Jahe Merah dengan Gula Merah', '500 g', 58000),
  ('Jahe Merah dengan Gula Merah', '1 kg', 111000),
  ('Jahe Merah Tanpa Gula',        '250 g', 25000),
  ('Jahe Merah Tanpa Gula',        '500 g', 48000),
  ('Jahe Merah Tanpa Gula',        '1 kg',  95000)
) as v(nama, ukuran, harga) on v.nama = p.nama;

-- Menjadikan akun tertentu admin (jalankan setelah akun itu mendaftar):
-- update public.profiles set role = 'admin'
-- where id = (select id from auth.users where email = 'email-admin@contoh.com');

-- ---------- Pengaturan toko ----------
-- Satu baris (id = 1). Semua orang boleh membaca nomor WhatsApp toko, hanya admin yang boleh mengubah.
create table if not exists public.pengaturan_toko (
  id integer primary key default 1 check (id = 1),
  no_wa text not null
);
alter table public.pengaturan_toko enable row level security;
create policy "semua boleh lihat pengaturan toko" on public.pengaturan_toko
  for select using (true);
create policy "admin ubah pengaturan toko" on public.pengaturan_toko
  for all using (public.is_admin()) with check (public.is_admin());
insert into public.pengaturan_toko (id, no_wa) values (1, '6281935131106') on conflict (id) do nothing;

-- ---------- Batal otomatis & notif pembeli ----------
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

-- ---------- Foto profil ----------
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

-- ---------- Push notification ----------
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

-- ---------- Informasi produk ----------
alter table public.produk add column if not exists komposisi text;
alter table public.produk add column if not exists saran_penyajian text;
alter table public.produk add column if not exists saran_penyimpanan text;
