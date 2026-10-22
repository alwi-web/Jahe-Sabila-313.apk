// Edge Function "kirim-notif": mengirim push notification (Firebase Cloud Messaging HTTP v1)
// setiap ada pesanan baru (ke admin) atau status/resi pesanan berubah (ke pembeli).
//
// Dipanggil oleh Database Webhook Supabase pada tabel public.pesanan (Insert + Update).
// Secret yang dibutuhkan (Edge Functions > Secrets):
//   FCM_SERVICE_ACCOUNT = seluruh isi file JSON service account Firebase.
// SUPABASE_URL dan SUPABASE_SERVICE_ROLE_KEY sudah disediakan Supabase.
//
// Isi webhook tidak dipercaya mentah-mentah: pesanan dibaca ulang dari database, dan notifikasi
// hanya dikirim kalau pesanan baru dibuat / baru diubah (< 2 menit), jadi panggilan palsu
// tidak bisa dipakai untuk mengirim notifikasi sembarangan.

type Pesanan = {
  id: number;
  user_id: string;
  tanggal: string;
  total: number;
  status: string;
  kurir: string | null;
  no_resi: string | null;
  diperbarui: string | null;
};

export type Notif = { kepada: "admin" | "pembeli"; judul: string; isi: string };

const BARU_MS = 2 * 60 * 1000;

export function nomor(id: number): string {
  return String(id).padStart(3, "0");
}

export function rupiah(n: number): string {
  return "Rp " + Math.abs(n).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ".");
}

/** Menentukan notifikasi dari jenis kejadian, data lama (dari webhook), dan data terkini (dari database). */
export function susunNotif(
  jenis: string,
  lama: Partial<Pesanan> | null,
  kini: Pesanan,
  namaPembeli: string,
  sekarang = Date.now(),
): Notif[] {
  const no = nomor(kini.id);
  if (jenis === "INSERT") {
    if (sekarang - Date.parse(kini.tanggal) > BARU_MS) return [];
    return [{
      kepada: "admin",
      judul: `Pesanan baru #${no}`,
      isi: `${namaPembeli || "Pembeli"} · ${rupiah(kini.total)} · menunggu pembayaran`,
    }];
  }
  if (jenis !== "UPDATE" || !lama) return [];
  if (!kini.diperbarui || sekarang - Date.parse(kini.diperbarui) > BARU_MS) return [];

  const resiBaru = (kini.no_resi ?? "") !== (lama.no_resi ?? "") && !!kini.no_resi;
  if (resiBaru) {
    return [{
      kepada: "pembeli",
      judul: `Pesanan #${no} dikirim`,
      isi: kini.kurir ? `Kurir ${kini.kurir} · resi ${kini.no_resi}` : `Resi ${kini.no_resi}`,
    }];
  }
  if (kini.status === lama.status) return [];
  const teks: Record<string, [string, string]> = {
    menunggu: [`Pesanan #${no} menunggu pembayaran`, "Silakan lanjutkan pembayaran lewat WhatsApp toko."],
    diproses: [`Pesanan #${no} diproses`, "Pembayaran diterima, pesananmu sedang disiapkan."],
    selesai: [`Pesanan #${no} selesai`, "Terima kasih sudah berbelanja di Jahe Merah Sabila 313."],
    batal: [`Pesanan #${no} dibatalkan`, "Hubungi admin lewat WhatsApp kalau ada pertanyaan."],
  };
  const t = teks[kini.status];
  return t ? [{ kepada: "pembeli", judul: t[0], isi: t[1] }] : [];
}

// ---------------- Firebase (FCM HTTP v1) ----------------

type ServiceAccount = { client_email: string; private_key: string; project_id: string };

function b64url(data: Uint8Array | string): string {
  const bytes = typeof data === "string" ? new TextEncoder().encode(data) : data;
  let s = "";
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

/** JWT bertanda tangan RS256 untuk ditukar menjadi access token Google. */
export async function buatJwt(sa: ServiceAccount, sekarangDetik = Math.floor(Date.now() / 1000)): Promise<string> {
  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const klaim = b64url(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: sekarangDetik,
    exp: sekarangDetik + 3600,
  }));
  const pem = sa.private_key.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const kunci = await crypto.subtle.importKey(
    "pkcs8", der, { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"],
  );
  const ttd = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", kunci, new TextEncoder().encode(`${header}.${klaim}`));
  return `${header}.${klaim}.${b64url(new Uint8Array(ttd))}`;
}

async function accessToken(sa: ServiceAccount): Promise<string> {
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: await buatJwt(sa),
    }),
  });
  if (!res.ok) throw new Error(`Token Google gagal: ${res.status} ${await res.text()}`);
  return (await res.json()).access_token;
}

// ---------------- Supabase (REST dengan service role) ----------------

function db(path: string, init: RequestInit = {}) {
  const url = Deno.env.get("SUPABASE_URL")!;
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  return fetch(`${url}/rest/v1/${path}`, {
    ...init,
    headers: { apikey: key, Authorization: `Bearer ${key}`, "Content-Type": "application/json", ...init.headers },
  });
}

async function ambil<T>(path: string): Promise<T[]> {
  const res = await db(path);
  if (!res.ok) throw new Error(`Supabase ${path}: ${res.status} ${await res.text()}`);
  return await res.json();
}

async function tanganiWebhook(req: Request): Promise<Response> {
  const payload = await req.json();
  if (payload?.table !== "pesanan" || !payload?.record?.id) return new Response("abaikan");

  const [kini] = await ambil<Pesanan>(
    `pesanan?id=eq.${Number(payload.record.id)}&select=id,user_id,tanggal,total,status,kurir,no_resi,diperbarui`,
  );
  if (!kini) return new Response("pesanan tidak ada");
  const [profil] = await ambil<{ nama: string | null }>(`profiles?id=eq.${kini.user_id}&select=nama`);
  const daftar = susunNotif(payload.type, payload.old_record ?? null, kini, profil?.nama ?? "");
  if (daftar.length === 0) return new Response("tidak ada notifikasi");

  const sa: ServiceAccount = JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT")!);
  const akses = await accessToken(sa);
  let terkirim = 0;

  for (const n of daftar) {
    let ids = [kini.user_id];
    if (n.kepada === "admin") {
      ids = (await ambil<{ id: string }>("profiles?role=eq.admin&select=id")).map((p) => p.id);
    }
    if (ids.length === 0) continue;
    const tokens = await ambil<{ token: string }>(`perangkat_notif?user_id=in.(${ids.join(",")})&select=token`);
    for (const { token } of tokens) {
      const res = await fetch(`https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`, {
        method: "POST",
        headers: { Authorization: `Bearer ${akses}`, "Content-Type": "application/json" },
        body: JSON.stringify({
          message: {
            token,
            notification: { title: n.judul, body: n.isi },
            android: {
              priority: "HIGH",
              notification: { channel_id: "pesanan", default_sound: true, notification_priority: "PRIORITY_HIGH" },
            },
          },
        }),
      });
      if (res.ok) {
        terkirim++;
        continue;
      }
      const galat = await res.text();
      console.error("FCM gagal", res.status, galat);
      // Hapus token hanya kalau memang tidak berlaku lagi (aplikasi dihapus / data dibersihkan),
      // bukan untuk 400 lain (mis. isi pesan salah) yang akan menghapus token yang masih sah.
      if (res.status === 404 || galat.includes("UNREGISTERED") || galat.includes("registration token")) {
        await db(`perangkat_notif?token=eq.${encodeURIComponent(token)}`, { method: "DELETE" });
      }
    }
  }
  console.log(`pesanan #${nomor(kini.id)} ${payload.type}: ${daftar.map((n) => n.kepada).join(",")}, terkirim ${terkirim}`);
  return new Response(`terkirim ${terkirim}`);
}

// Deno (Supabase Edge Functions) menjalankan server; saat diuji dengan Node, bagian ini dilewati.
// deno-lint-ignore no-explicit-any
const D = (globalThis as any).Deno;
if (D?.serve) {
  D.serve(async (req: Request) => {
    try {
      return await tanganiWebhook(req);
    } catch (e) {
      console.error(e);
      return new Response(String(e), { status: 500 });
    }
  });
}
