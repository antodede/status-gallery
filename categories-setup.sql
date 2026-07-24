-- ============================================================
-- TAHAP 1 — Tabel `categories` untuk Status Gallery
-- Jalankan file ini di Supabase Dashboard > SQL Editor.
-- Aman dijalankan berkali-kali (pakai IF NOT EXISTS / ON CONFLICT).
-- ============================================================

-- 1) Tabel categories
create table if not exists public.categories (
  id          text primary key,              -- slug, contoh: "motivasi"
  name        text not null,                  -- nama tampilan, contoh: "Motivasi"
  icon        text not null default '🏷️',     -- emoji
  color       text not null default '#0D8B5B',-- hex warna
  sort_order  integer not null default 0,     -- urutan tampil (kecil = duluan)
  created_at  timestamptz not null default now()
);

-- 2) Aktifkan Row Level Security
alter table public.categories enable row level security;

-- 3) Policy: siapa saja (termasuk pengunjung anonim) boleh membaca
drop policy if exists "categories_select_public" on public.categories;
create policy "categories_select_public"
  on public.categories
  for select
  to anon, authenticated
  using (true);

-- 4) Policy: hanya user yang sudah login (admin) yang boleh insert/update/delete
drop policy if exists "categories_insert_auth" on public.categories;
create policy "categories_insert_auth"
  on public.categories
  for insert
  to authenticated
  with check (true);

drop policy if exists "categories_update_auth" on public.categories;
create policy "categories_update_auth"
  on public.categories
  for update
  to authenticated
  using (true)
  with check (true);

drop policy if exists "categories_delete_auth" on public.categories;
create policy "categories_delete_auth"
  on public.categories
  for delete
  to authenticated
  using (true);

-- 5) Seed data — 12 kategori yang sudah dipakai di index.html/admin.html.
--    Aman dijalankan ulang: kalau id sudah ada, data akan di-update
--    (bukan menambah duplikat).
insert into public.categories (id, name, icon, color, sort_order) values
  ('motivasi',   'Motivasi',  '💪',  '#0D8B5B', 1),
  ('lucu',       'Lucu',      '😂',  '#FFC107', 2),
  ('islami',     'Islami',    '🕌',  '#12B76A', 3),
  ('anime',      'Anime',     '🎌',  '#EE6C9B', 4),
  ('romantis',   'Romantis',  '💗',  '#F4568B', 5),
  ('sedih',      'Sedih',     '🌧️', '#5B7FBF', 6),
  ('ucapan',     'Ucapan',    '✉️',  '#8B5CF6', 7),
  ('hariraya',   'Hari Raya', '🎉',  '#F97316', 8),
  ('gaming',     'Gaming',    '🎮',  '#6366F1', 9),
  ('quotes',     'Quotes',    '💬',  '#0EA5A4', 10),
  ('teknologi',  'Teknologi', '💻',  '#334155', 11),
  ('estetik',    'Estetik',   '🌸',  '#D946AA', 12)
on conflict (id) do update
  set name = excluded.name,
      icon = excluded.icon,
      color = excluded.color,
      sort_order = excluded.sort_order;

-- ============================================================
-- Catatan:
-- - Tabel `images` sudah menyimpan kategori sebagai kolom teks
--   (`category`) berisi slug, jadi TIDAK perlu foreign key wajib
--   ke `categories.id` supaya menghapus kategori tidak ikut
--   menghapus/mengunci baris gambar. admin.html sengaja mengecek
--   dan memperingatkan jumlah gambar yang memakai kategori sebelum
--   menghapusnya (lihat tab "Kelola Kategori").
-- - Kalau nanti mau menambah relasi formal, bisa dibuat foreign key
--   dengan `on delete set null`, tapi itu di luar cakupan Tahap 1.
-- ============================================================
