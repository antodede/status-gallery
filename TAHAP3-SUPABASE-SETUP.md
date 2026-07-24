# TAHAP 3 — Setup Login Email & Google di Supabase

Login email+password di `index.html` sudah otomatis jalan begitu file
ini dipakai (Supabase Auth aktif by default, tidak perlu setting
tambahan). Yang **perlu kamu siapkan manual** cuma provider Google.

## 1. Siapkan OAuth Client di Google Cloud Console

1. Buka https://console.cloud.google.com/ → pilih/bikin project.
2. Buka **APIs & Services > OAuth consent screen**.
   - User type: **External**.
   - Isi nama app ("Status Gallery"), email support, dan logo (opsional).
   - Scopes: biarkan default (`email`, `profile`, `openid`) sudah cukup.
   - Tambahkan email kamu di **Test users** kalau app masih status
     "Testing" (supaya kamu bisa coba login duluan sebelum app
     di-publish).
3. Buka **APIs & Services > Credentials** → **Create Credentials >
   OAuth client ID**.
   - Application type: **Web application**.
   - **Authorized redirect URIs** — isi persis URL callback dari
     Supabase (lihat langkah 2 di bawah untuk dapetin URL-nya).
4. Setelah dibuat, kamu akan dapat **Client ID** dan **Client
   Secret** — simpan, dipakai di langkah 2.

## 2. Aktifkan Google Provider di Supabase

1. Buka **Supabase Dashboard** → project kamu (`galery`) →
   **Authentication > Providers**.
2. Cari **Google**, klik untuk expand, aktifkan toggle-nya.
3. Supabase akan menampilkan **Callback URL (for OAuth)** — bentuknya
   kira-kira:
   `https://zffpheohnegwvvgcngfo.supabase.co/auth/v1/callback`
   Copy URL ini, lalu tempel ke **Authorized redirect URIs** di Google
   Cloud Console (langkah 1.3 di atas). Simpan perubahan di Google
   Cloud Console dulu.
4. Balik ke Supabase, isi **Client ID** dan **Client Secret** dari
   Google Cloud Console (langkah 1.4), lalu **Save**.

## 3. Authorized redirect URL untuk domain situs kamu

Supaya Supabase mau redirect balik ke `index.html` setelah login
Google berhasil (bukan cuma localhost), tambahkan juga domain situs
kamu di:

**Authentication > URL Configuration > Redirect URLs**, contoh:
- `https://andrichupu-art.github.io/aplikasi/index.html`
- (tambahkan juga `http://localhost:...` kalau masih testing lokal)

Tanpa ini, setelah tap "Lanjutkan dengan Google" pengguna akan
berhasil login di Google tapi gagal balik ke situs (redirect ditolak).

## 4. Testing

- Buka `index.html`, tap ikon akun di header (pojok kanan atas) →
  tap **Lanjutkan dengan Google** → pilih akun Google → harus balik
  otomatis ke situs dalam keadaan sudah login (avatar Google muncul
  di header).
- Refresh halaman → sesi harus tetap login (Supabase Auth otomatis
  menyimpan sesi di browser).
- Tap avatar → **Keluar** → harus logout bersih dan avatar kembali
  jadi ikon 👤.

---

## (Opsional) Tabel `profiles`

Untuk Tahap 3 ini **tabel tambahan belum wajib** — nama tampilan dan
foto profil sudah otomatis didapat dari Google (`user_metadata`), dan
untuk akun email+password situs cukup pakai bagian sebelum `@` di
email sebagai nama tampilan sementara.

Kalau nanti kamu mau pengguna bisa **mengedit nama tampilan sendiri**
(termasuk untuk akun email+password), baru saat itu perlu tabel
`profiles`. SQL di bawah ini sudah termasuk trigger otomatis supaya
baris `profiles` selalu dibuat begitu ada user baru daftar — jalankan
kapan saja saat fitur itu dibutuhkan (tidak perlu sekarang):

```sql
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url text,
  created_at timestamptz default now()
);

alter table profiles enable row level security;

create policy "Profil bisa dibaca siapa saja"
  on profiles for select
  using (true);

create policy "User hanya boleh ubah profil sendiri"
  on profiles for update
  using (auth.uid() = id);

-- Otomatis buat baris profiles saat ada user baru (email atau Google)
create or replace function handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', split_part(new.email,'@',1)),
    new.raw_user_meta_data->>'avatar_url'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();
```

Simpan file ini untuk referensi kalau nanti mau nambah fitur edit
profil.
