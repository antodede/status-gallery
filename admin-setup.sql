-- ============================================================
-- STATUS GALLERY — SETUP SUPABASE UNTUK ADMIN UPLOAD
-- Jalankan seluruh isi file ini di Supabase Dashboard > SQL Editor
-- ============================================================

-- 1) TABEL IMAGES
create table if not exists public.images (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  category text not null,
  orientation text not null check (orientation in ('portrait','landscape','square')),
  width int,
  height int,
  size_kb int,
  tags text[] default '{}',
  storage_path text not null,
  url text not null,
  views int not null default 0,
  downloads int not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists images_category_idx on public.images (category);
create index if not exists images_created_at_idx on public.images (created_at desc);

-- 2) ROW LEVEL SECURITY
alter table public.images enable row level security;

-- Semua orang boleh membaca (untuk ditampilkan di website publik)
create policy "Public can read images"
  on public.images for select
  using (true);

-- Hanya user yang sudah login (admin) yang boleh tambah/ubah/hapus
create policy "Authenticated can insert images"
  on public.images for insert
  to authenticated
  with check (true);

create policy "Authenticated can update images"
  on public.images for update
  to authenticated
  using (true);

create policy "Authenticated can delete images"
  on public.images for delete
  to authenticated
  using (true);

-- 3) STORAGE BUCKET
insert into storage.buckets (id, name, public)
values ('status-images', 'status-images', true)
on conflict (id) do nothing;

-- Semua orang boleh membaca file di bucket (agar gambar bisa tampil di website)
create policy "Public can read status-images"
  on storage.objects for select
  using (bucket_id = 'status-images');

-- Hanya user login yang boleh upload/update/hapus file
create policy "Authenticated can upload status-images"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'status-images');

create policy "Authenticated can update status-images"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'status-images');

create policy "Authenticated can delete status-images"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'status-images');

-- ============================================================
-- LANGKAH SELANJUTNYA (di luar SQL Editor):
-- 1. Authentication > Users > Add user, buat akun admin (email + password)
-- 2. Project Settings > API, salin "Project URL" dan "anon public key"
-- 3. Tempel keduanya ke CONFIG di bagian atas admin.html
-- 4. Buka admin.html, login pakai akun admin yang dibuat di langkah 1
-- ============================================================
