-- Jalankan setelah Edge Function "kirim-notif" di-deploy. Aman dijalankan ulang.
-- Pengganti Database Webhook di dashboard: setiap insert/update pada pesanan memanggil
-- Edge Function kirim-notif lewat pg_net, dengan isi yang sama seperti Database Webhook.
-- Kunci di header adalah anon key (publik, sama dengan di aplikasi); Edge Function selalu
-- membaca ulang pesanan dari database, jadi isi panggilan tidak dipercaya mentah-mentah.

create extension if not exists pg_net;

create or replace function public.panggil_kirim_notif() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  perform net.http_post(
    url := 'https://paslqibvuumnpooubkyk.supabase.co/functions/v1/kirim-notif',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBhc2xxaWJ2dXVtbnBvb3Via3lrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI1ODU2NzIsImV4cCI6MjEwODE2MTY3Mn0.dzsq65alJL_JZcVNEPqK8nRV-h6DjkRiO1_acE4ep8o'
    ),
    body := jsonb_build_object(
      'type', TG_OP,
      'table', TG_TABLE_NAME,
      'schema', TG_TABLE_SCHEMA,
      'record', to_jsonb(new),
      'old_record', case when TG_OP = 'UPDATE' then to_jsonb(old) end
    )
  );
  return new;
end;
$$;

drop trigger if exists notif_pesanan on public.pesanan;
create trigger notif_pesanan after insert or update on public.pesanan
  for each row execute function public.panggil_kirim_notif();
