# Wordly – English Indonesia

Aplikasi mobile (Android-first) untuk belajar kosakata bahasa Inggris bagi pengguna Indonesia. Offline-first, tanpa registrasi, dengan sistem pengulangan berjarak (spaced repetition) agar kosakata benar-benar teringat.

> Status: dokumen perancangan & panduan pengembangan (v0.1). Nama "Wordly" bersifat sementara.

---

## Daftar Isi

1. [Tujuan & Target Pengguna](#1-tujuan--target-pengguna)
2. [Fitur Utama](#2-fitur-utama)
3. [Struktur Halaman & Navigasi](#3-struktur-halaman--navigasi)
4. [Design System](#4-design-system)
5. [Tech Stack](#5-tech-stack)
6. [Arsitektur Aplikasi](#6-arsitektur-aplikasi)
7. [Database Schema](#7-database-schema)
8. [Spaced Repetition (SM-2)](#8-spaced-repetition-sm-2)
9. [Konten Kosakata](#9-konten-kosakata)
10. [Audio Pronunciation](#10-audio-pronunciation)
11. [UX: Loading, Empty & Error State](#11-ux-loading-empty--error-state)
12. [Setup & Menjalankan Proyek](#12-setup--menjalankan-proyek)
13. [Build APK](#13-build-apk)
14. [Roadmap Implementasi](#14-roadmap-implementasi)
15. [Checklist QA](#15-checklist-qa)
16. [Persiapan Sinkronisasi Cloud](#16-persiapan-sinkronisasi-cloud)
17. [Backend (Python + FastAPI)](#17-backend-python--fastapi)
18. [Aturan Proyek & Lisensi](#18-aturan-proyek--lisensi)

---

## 1. Tujuan & Target Pengguna

**Tujuan**
- Memperkaya kosakata bahasa Inggris pengguna.
- Menyediakan terjemahan Inggris → Indonesia yang tepat dan contoh kalimat natural.
- Membangun kebiasaan belajar harian (goal, streak).
- Memperkuat ingatan lewat pengulangan dan latihan interaktif.

**Target pengguna**
- Pemula yang baru belajar bahasa Inggris.
- Pelajar dan mahasiswa.
- Pekerja yang ingin meningkatkan kemampuan bahasa Inggris.
- Siapa pun yang ingin memperkaya vocabulary sehari-hari.

**Bahasa:** antarmuka Indonesia; materi belajar English–Indonesia.

---

## 2. Fitur Utama

| Kode | Fitur | Ringkasan |
|------|-------|-----------|
| A | Home Dashboard | Greeting, Word of the Day, goal harian, progres, streak, ringkasan kata dikuasai, quick access |
| B | Daily Vocabulary | Detail kata lengkap (11 field), audio, bookmark, "sudah paham", "pelajari lagi", prev/next |
| C | Categories | 13 kategori dengan deskripsi, jumlah kata, progres, daftar kata |
| D | Difficulty Levels | Beginner (A1–A2), Intermediate (B1–B2), Advanced (C1–C2); dapat diganti kapan saja |
| E | Dictionary | Cari Inggris/Indonesia, autocomplete, filter kategori & level, detail, favorit |
| F | My Words | Favorit, riwayat, belum/sudah dikuasai, filter, sorting, koleksi buatan sendiri |
| G | Flashcards | Tap untuk balik, swipe kanan = dikuasai, swipe kiri = ulangi, pilih jumlah kartu |
| H | Quiz & Practice | 6 jenis latihan + skor, progres, feedback, penjelasan, ringkasan |
| I | Spaced Repetition | SM-2; status New/Learning/Review/Mastered; kata sering salah muncul lebih sering |
| J | Statistics | Total dipelajari/dikuasai, jumlah latihan, akurasi, streak, aktivitas harian, grafik mingguan/bulanan |
| K | Settings | Tema, goal harian, notifikasi, level, audio, bahasa, ukuran teks, reset progres, tentang |

**Kategori:** Daily Conversation, Business English, Academic English, Travel, Technology, Food & Drinks, Education, Health, Nature, Feelings & Emotions, Phrasal Verbs, Idioms, Slang & Informal English.

**Jenis latihan:** Multiple Choice, English→Indonesian, Indonesian→English, Fill in the Blank, Listening Quiz, Spelling Practice.

---

## 3. Struktur Halaman & Navigasi

Bottom navigation (5 menu):

```
Home        → Dashboard, Word of the Day, Daily Vocabulary
Explore     → Kategori, Level, Dictionary/Search
Practice    → Flashcards, Quiz (6 mode), Review SRS hari ini
My Words    → Favorit, Riwayat, Dikuasai/Belum, Koleksi
Profile     → Statistik, Settings, Tentang
```

Peta layar:

```
Home
 ├─ Word of the Day → Word Detail
 ├─ Daily Vocabulary (pager prev/next)
 └─ Quick access → Flashcards / Quiz / Review

Explore
 ├─ Category List → Category Detail → Word List → Word Detail
 ├─ Level Picker
 └─ Search (autocomplete + filter) → Word Detail

Practice
 ├─ Flashcard Setup → Flashcard Session → Summary
 ├─ Quiz Setup (mode, jumlah, kategori) → Quiz Session → Summary
 └─ SRS Review Session → Summary

My Words
 ├─ Tab: Favorit | Riwayat | Belum Dikuasai | Dikuasai
 └─ Collections → Collection Detail (tambah/hapus kata)

Profile
 ├─ Statistics (harian, mingguan, bulanan)
 └─ Settings (tema, goal, notifikasi, level, audio, bahasa, teks, reset, tentang)
```

Alur pertama kali: *Onboarding singkat* (pilih level + goal harian) → Home. Tanpa login.

---

## 4. Design System

Arah visual: modern, minimalis, elegan, premium; **dark mode sebagai tema utama**; berbasis card; whitespace lega; animasi halus. Identitas visual original (tidak meniru aplikasi referensi mana pun).

### 4.1 Warna (Dark – utama)

| Token | Hex | Pemakaian |
|-------|-----|-----------|
| `bg` | `#0E1116` | Latar halaman |
| `surface` | `#171B22` | Card |
| `surfaceElevated` | `#1F2430` | Card terangkat, sheet |
| `border` | `#2A3040` | Garis halus |
| `primary` | `#7C9CFF` | Aksi utama, fokus |
| `accent` | `#F2C46D` | Highlight, streak, Word of the Day |
| `success` | `#4FD1A1` | Benar, dikuasai |
| `warning` | `#F5A25D` | Perlu diulang |
| `error` | `#F27C8D` | Salah, error |
| `textPrimary` | `#F2F4F8` | Teks utama |
| `textSecondary` | `#9AA3B5` | Teks pendukung |

### 4.2 Warna (Light)

`bg #F7F8FB`, `surface #FFFFFF`, `border #E3E7EF`, `primary #4A6BE0`, `accent #D99A2B`, `textPrimary #151922`, `textSecondary #5C6578`. Warna semantik (success/warning/error) disesuaikan kontrasnya (WCAG AA).

### 4.3 Tipografi

- Font tampilan: **Plus Jakarta Sans** (judul, angka). Font isi: **Inter**. IPA: **Noto Sans** (dukungan simbol fonetik).
- Skala (sp, dikalikan faktor ukuran teks pengguna 0.85 / 1.0 / 1.15 / 1.3):

| Token | Ukuran / Berat |
|-------|----------------|
| `displayLarge` | 36 / 700 (kata utama) |
| `headline` | 24 / 700 |
| `title` | 18 / 600 |
| `body` | 15 / 400 |
| `bodySmall` | 13 / 400 |
| `label` | 12 / 600 (uppercase tracking +0.4) |

### 4.4 Spacing & Radius

- Spacing (kelipatan 4): `xs 4`, `sm 8`, `md 12`, `lg 16`, `xl 24`, `xxl 32`, `xxxl 48`.
- Padding halaman: 20. Jarak antar card: 12–16.
- Radius: `sm 8` (chip, input kecil), `md 14` (tombol, input), `lg 20` (card), `xl 28` (sheet, hero card), `full 999` (badge, pill).

### 4.5 Komponen & State

| Komponen | Varian | State |
|----------|--------|-------|
| `AppButton` | primary, secondary (outline), text, danger | default, pressed, disabled, loading |
| `AppCard` | flat, elevated, hero (gradient halus) | default, pressed |
| `WordCard` | ringkas (list), fokus (Word of the Day) | normal, favorit, dikuasai |
| `Chip/Pill` | level, kategori, POS | selected, unselected |
| `ProgressBar` / `ProgressRing` | linear, circular | animasi nilai |
| `AudioButton` | ikon speaker | idle, playing, unavailable |
| `StatTile` | angka + label + ikon | default |
| `QuizOption` | pilihan jawaban | default, selected, correct, wrong, disabled |
| `EmptyState`, `ErrorState`, `Skeleton` | — | — |
| `SearchField` | autocomplete | idle, fokus, ada hasil, kosong |

**Ikonografi:** satu set ikon outline konsisten (Material Symbols Rounded, stroke 1.75–2). **Animasi:** durasi 180–320 ms, kurva `easeOutCubic`; flip kartu 3D 350 ms; transisi halaman fade-through; haptic ringan pada jawaban benar/salah.

---

## 5. Tech Stack

| Kebutuhan | Pilihan |
|-----------|---------|
| Framework | Flutter (stable terbaru), Dart |
| State management | Riverpod (`flutter_riverpod`, `riverpod_annotation`) |
| Database lokal | SQLite via **Drift** (type-safe, migrasi, query reaktif) |
| Pengaturan sederhana | `shared_preferences` |
| Navigasi | `go_router` (dengan `StatefulShellRoute` untuk bottom nav) |
| Audio | `just_audio` (file lokal/URL) + `flutter_tts` sebagai fallback |
| Notifikasi | `flutter_local_notifications` + `timezone` |
| Grafik | `fl_chart` |
| Model data | `freezed` + `json_serializable` |
| Font | `google_fonts` (di-bundle sebagai aset agar offline) |
| Test | `flutter_test`, `mocktail`, `integration_test` |
| Lint | `flutter_lints` / `very_good_analysis` |

---

## 6. Arsitektur Aplikasi

Pendekatan **feature-first + clean architecture ringan**: tiap fitur punya lapisan `data`, `domain`, `presentation`.

```
lib/
├─ main.dart
├─ app/
│  ├─ app.dart                 # MaterialApp.router, tema
│  ├─ router.dart              # go_router
│  └─ bootstrap.dart           # init DB, seed, prefs
├─ core/
│  ├─ design/                  # colors, typography, spacing, radius, theme
│  ├─ widgets/                 # komponen reusable
│  ├─ db/                      # Drift: tabel, DAO, migrasi
│  ├─ audio/                   # AudioService (file → URL → TTS fallback)
│  ├─ notifications/
│  ├─ error/                   # Failure, AppException, error handler
│  └─ utils/                   # tanggal, string, debouncer
├─ features/
│  ├─ home/
│  ├─ daily/                   # Daily Vocabulary + Word Detail
│  ├─ explore/                 # kategori, level
│  ├─ dictionary/              # search + autocomplete
│  ├─ my_words/                # favorit, riwayat, koleksi
│  ├─ flashcards/
│  ├─ quiz/
│  ├─ srs/                     # scheduler SM-2, review queue
│  ├─ stats/
│  ├─ settings/
│  └─ onboarding/
└─ data_seed/
   └─ assets/vocab/            # vocab_*.json (per kategori) + audio/
```

**Prinsip**
- Repository pattern: UI → Provider (Riverpod) → Repository → DAO. UI tidak pernah mengakses DB langsung.
- Provider berbasis `Stream` dari Drift agar UI otomatis ter-update.
- Semua operasi I/O mengembalikan `Result`/`AsyncValue`; error ditangkap dan dipetakan ke pesan ramah pengguna.
- Tidak ada data dummy hardcoded: seluruh daftar kata, progres, dan statistik berasal dari database.

---

## 7. Database Schema

Dua database/area terpisah agar konten dapat diperbarui tanpa menyentuh progres pengguna.

### 7.1 `vocab.db` — konten (read-only di runtime)

```sql
CREATE TABLE category (
  id            INTEGER PRIMARY KEY,
  slug          TEXT NOT NULL UNIQUE,
  name          TEXT NOT NULL,
  description   TEXT NOT NULL,
  icon          TEXT,
  sort_order    INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE vocabulary (
  id                 INTEGER PRIMARY KEY,
  word               TEXT NOT NULL,
  word_normalized    TEXT NOT NULL,          -- lowercase, tanpa tanda baca (untuk search)
  translation        TEXT NOT NULL,
  definition         TEXT NOT NULL,
  pronunciation_ipa  TEXT,
  part_of_speech     TEXT NOT NULL,          -- noun|verb|adjective|adverb|phrasal_verb|idiom|...
  difficulty_level   TEXT NOT NULL CHECK (difficulty_level IN ('beginner','intermediate','advanced')),
  cefr               TEXT CHECK (cefr IN ('A1','A2','B1','B2','C1','C2')),
  category_id        INTEGER NOT NULL REFERENCES category(id),
  example_sentence   TEXT NOT NULL,
  example_translation TEXT NOT NULL,
  synonyms           TEXT NOT NULL DEFAULT '[]',   -- JSON array
  antonyms           TEXT NOT NULL DEFAULT '[]',   -- JSON array
  audio_url          TEXT,                         -- path aset lokal atau URL
  created_at         TEXT NOT NULL,
  UNIQUE (word_normalized, part_of_speech, category_id)
);

CREATE INDEX idx_vocab_word      ON vocabulary(word_normalized);
CREATE INDEX idx_vocab_category  ON vocabulary(category_id);
CREATE INDEX idx_vocab_level     ON vocabulary(difficulty_level);

-- Pencarian cepat untuk 10.000+ kata (Inggris + Indonesia)
CREATE VIRTUAL TABLE vocabulary_fts USING fts5(
  word, translation, content='vocabulary', content_rowid='id', prefix='2 3 4'
);
```

### 7.2 `user.db` — progres pengguna

```sql
CREATE TABLE user_word (          -- 1 baris per kata yang pernah disentuh
  vocab_id        INTEGER PRIMARY KEY,
  status          TEXT NOT NULL DEFAULT 'new' CHECK (status IN ('new','learning','review','mastered')),
  is_favorite     INTEGER NOT NULL DEFAULT 0,
  -- SM-2
  repetitions     INTEGER NOT NULL DEFAULT 0,
  ease_factor     REAL    NOT NULL DEFAULT 2.5,
  interval_days   INTEGER NOT NULL DEFAULT 0,
  due_at          TEXT,                      -- ISO8601; NULL = belum dijadwalkan
  lapses          INTEGER NOT NULL DEFAULT 0, -- berapa kali salah (prioritas)
  correct_count   INTEGER NOT NULL DEFAULT 0,
  wrong_count     INTEGER NOT NULL DEFAULT 0,
  first_seen_at   TEXT,
  last_reviewed_at TEXT,
  updated_at      TEXT NOT NULL,
  sync_state      TEXT NOT NULL DEFAULT 'local'  -- siap sync cloud
);
CREATE INDEX idx_user_word_due    ON user_word(due_at);
CREATE INDEX idx_user_word_status ON user_word(status);

CREATE TABLE review_log (         -- riwayat semua jawaban (sumber statistik)
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  vocab_id    INTEGER NOT NULL,
  mode        TEXT NOT NULL,      -- flashcard|mcq|en_id|id_en|fill_blank|listening|spelling|srs
  quality     INTEGER NOT NULL,   -- 0..5
  is_correct  INTEGER NOT NULL,
  reviewed_at TEXT NOT NULL
);
CREATE INDEX idx_review_time ON review_log(reviewed_at);

CREATE TABLE collection (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  name       TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE collection_word (
  collection_id INTEGER NOT NULL REFERENCES collection(id) ON DELETE CASCADE,
  vocab_id      INTEGER NOT NULL,
  added_at      TEXT NOT NULL,
  PRIMARY KEY (collection_id, vocab_id)
);

CREATE TABLE daily_activity (     -- agregat per hari (streak & grafik)
  day            TEXT PRIMARY KEY,  -- YYYY-MM-DD (waktu lokal)
  words_learned  INTEGER NOT NULL DEFAULT 0,
  reviews_done   INTEGER NOT NULL DEFAULT 0,
  correct        INTEGER NOT NULL DEFAULT 0,
  wrong          INTEGER NOT NULL DEFAULT 0,
  goal_met       INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE word_of_day (
  day      TEXT PRIMARY KEY,
  vocab_id INTEGER NOT NULL
);
```

`vocab_id` merujuk ke `vocab.db` (dilakukan di lapisan aplikasi karena beda file). Dengan pemisahan ini, pembaruan konten cukup mengganti `vocab.db` (dengan `content_version`) tanpa memengaruhi progres.

### 7.3 `shared_preferences`

`theme_mode`, `learning_level`, `daily_goal`, `notifications_enabled`, `notification_time`, `audio_autoplay`, `audio_speed`, `app_language`, `text_scale`, `onboarding_done`, `vocab_content_version`.

### 7.4 Seeding

Saat first run, `bootstrap.dart` membaca `assets/vocab/*.json`, memvalidasi (skema, duplikasi, level), lalu mengimpor ke `vocab.db` dalam satu transaksi. Versi konten disimpan; bila versi di aset lebih baru, lakukan upsert berdasarkan `id` stabil.

---

## 8. Spaced Repetition (SM-2)

**Status kata**

| Status | Arti |
|--------|------|
| `new` | Belum pernah dipelajari |
| `learning` | Sedang dipelajari (`repetitions` < 2 atau baru salah) |
| `review` | Sudah lolos, dijadwalkan ulang berkala |
| `mastered` | `interval_days` ≥ 21 dan `repetitions` ≥ 4 (turun ke `review` bila salah) |

**Kualitas jawaban (`q`, 0–5)**: Salah = 1 · Benar tapi ragu/hint = 3 · Benar = 4 · Benar mudah (swipe kanan / cepat) = 5.

**Algoritma (SM-2 yang disesuaikan)**

```
if q < 3:
    repetitions = 0
    interval_days = 0           # muncul lagi di sesi yang sama / 10 menit
    lapses += 1
    status = learning
else:
    repetitions += 1
    if repetitions == 1: interval_days = 1
    elif repetitions == 2: interval_days = 3      # 3 hari agar lebih cocok untuk vocab
    else: interval_days = round(interval_days * ease_factor)
    ease_factor = max(1.3, ease_factor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)))
    status = mastered if (interval_days >= 21 and repetitions >= 4) else review

due_at = now + interval_days
```

**Prioritas antrean review** (urut): (1) kata `due_at` ≤ sekarang yang paling terlambat, (2) kata dengan `lapses` tinggi / `wrong_count / total` besar (diberi bobot tambahan agar lebih sering muncul), (3) kata `new` sesuai sisa goal harian dan level pengguna.

**Pengaruh latihan:** semua mode (flashcard, quiz, review) menulis ke `review_log` dan memanggil scheduler yang sama sehingga progres konsisten.

---

## 9. Konten Kosakata

**Target awal:** minimal 500 kata, struktur siap sampai 10.000+.

**Distribusi awal yang disarankan**

| Level | Jumlah | Catatan |
|-------|--------|---------|
| Beginner (A1–A2) | ~200 | Kata harian, kegiatan, benda, perasaan dasar |
| Intermediate (B1–B2) | ~200 | Kerja, perjalanan, teknologi, phrasal verbs |
| Advanced (C1–C2) | ~100 | Akademik, idiom, nuansa |

Setiap kategori minimal 25–30 kata agar progres kategori bermakna.

**Format JSON per entri**

```json
{
  "id": 101,
  "word": "resilient",
  "translation": "tangguh; cepat pulih",
  "definition": "Able to recover quickly from difficulties.",
  "pronunciation_ipa": "/rɪˈzɪl.i.ənt/",
  "part_of_speech": "adjective",
  "difficulty_level": "advanced",
  "cefr": "C1",
  "category": "feelings-emotions",
  "example_sentence": "She is resilient and never gives up easily.",
  "example_translation": "Dia tangguh dan tidak mudah menyerah.",
  "synonyms": ["tough", "adaptable"],
  "antonyms": ["fragile", "vulnerable"],
  "audio_url": "audio/resilient.mp3",
  "created_at": "2026-11-17T00:00:00Z"
}
```

**Pedoman kualitas**
- Terjemahan akurat sesuai konteks; beri beberapa padanan bila perlu, pisahkan dengan `;`.
- Contoh kalimat natural, singkat (≤ 15 kata untuk Beginner), dan terjemahannya bukan kata-per-kata.
- Penentuan level mengacu pada CEFR (rujukan daftar kosakata CEFR yang berlisensi terbuka, lalu ditinjau manual).
- Tidak ada duplikasi (kunci `word_normalized + part_of_speech + category`); satu kata multi-makna dibuat entri terpisah hanya bila maknanya benar-benar berbeda.
- Wajib melalui skrip validasi (`tool/validate_vocab.dart`): field wajib terisi, IPA valid, level/kategori sah, tanpa duplikasi, sinonim ≠ kata itu sendiri.
- Seluruh konten ditulis/ditinjau sendiri atau bersumber lisensi terbuka; **jangan menyalin** dari kamus/aplikasi berhak cipta.

---

## 10. Audio Pronunciation

Urutan fallback (di `AudioService`):

1. **File audio lokal** di `assets/vocab/audio/` (rekaman sendiri atau sumber berlisensi terbuka, mis. CC0/CC-BY dengan atribusi di halaman "Tentang").
2. **URL `audio_url`** bila diisi dan perangkat online (di-cache ke penyimpanan lokal setelah diunduh).
3. **Text-to-Speech perangkat** (`flutter_tts`, locale `en-US`) — selalu tersedia offline di sebagian besar perangkat Android.
4. Jika semuanya gagal: tombol audio berstatus *unavailable* dan muncul snackbar singkat "Audio tidak tersedia".

Pengaturan: kecepatan pemutaran (0.75× / 1× ), putar otomatis di Daily Vocabulary.

---

## 11. UX: Loading, Empty & Error State

| Situasi | Perilaku |
|---------|----------|
| Memuat daftar/detail | Skeleton shimmer (bukan spinner penuh layar) |
| Favorit kosong | Ilustrasi sederhana + "Belum ada kata favorit" + tombol "Jelajahi kata" |
| Pencarian tanpa hasil | "Kata tidak ditemukan" + saran periksa ejaan / ubah filter |
| Belum ada review jatuh tempo | "Semua beres hari ini 🎉" + tombol belajar kata baru |
| Gagal baca DB / seed | Layar error dengan tombol "Coba lagi" dan opsi reset data konten |
| Audio gagal | Snackbar non-blokir (lihat bagian audio) |
| Reset progres | Dialog konfirmasi dua langkah |

Semua interaksi memberi umpan balik visual (animasi tekan, perubahan warna jawaban, haptic). Onboarding maksimal 2 layar.

---

## 12. Setup & Menjalankan Proyek

Prasyarat: Flutter SDK (stable), Android SDK, JDK 17, emulator atau perangkat Android (API 24+).

```bash
git clone <repo-url> wordly
cd wordly

flutter pub get
dart run build_runner build --delete-conflicting-outputs   # drift, freezed, riverpod
dart run tool/validate_vocab.dart                          # validasi konten

flutter run
```

Perintah berguna:

```bash
flutter analyze
flutter test
flutter test integration_test
dart format .
```

---

## 13. Build APK

```bash
# Debug
flutter build apk --debug

# Release (per ABI, ukuran lebih kecil)
flutter build apk --release --split-per-abi

# Untuk Google Play
flutter build appbundle --release
```

Siapkan keystore (`android/key.properties`, jangan di-commit), isi `applicationId` (mis. `id.wordly.app`), ikon adaptif, dan splash screen original.

---

## 14. Roadmap Implementasi

Urutan pengerjaan sesuai prioritas:

| Fase | Cakupan | Output |
|------|---------|--------|
| 0 | Analisis, struktur halaman, arsitektur, schema | Dokumen ini |
| 1 | **UI/UX & design system** | Tema gelap/terang, komponen reusable, router + bottom nav |
| 2 | **Home Dashboard** | Greeting, Word of the Day, goal, streak, ringkasan (dari DB) |
| 3 | **Vocabulary Database** | Schema, seeding 500+ kata, validator |
| 4 | **Daily Vocabulary** | Detail kata, audio, bookmark, paham/ulang, prev/next |
| 5 | **Dictionary & Search** | FTS5, autocomplete, filter kategori/level |
| 6 | **Favorites / My Words** | Favorit, riwayat, status, sorting, koleksi |
| 7 | **Flashcards** | Flip, swipe, jumlah kartu, progres |
| 8 | **Quiz** | 6 mode, skor, feedback, penjelasan, ringkasan |
| 9 | **Spaced Repetition** | SM-2, antrean review, prioritas kata sering salah |
| 10 | **Statistics & Settings** | Grafik, streak, notifikasi, reset, tentang |
| 11 | Hardening | Bug fix, QA, performa, build APK |

Setiap fase selesai dengan: kode berjalan, test unit untuk logika inti, dan pengecekan manual layar terkait.

---

## 15. Checklist QA

- [ ] Aplikasi berjalan penuh offline (mode pesawat).
- [ ] Seed konten sukses pada instalasi baru; tidak ada duplikasi kata.
- [ ] Semua tombol di semua halaman berfungsi (tidak ada tombol dekoratif).
- [ ] Favorit, status paham/ulang, dan koleksi tersimpan setelah aplikasi ditutup dan dibuka kembali.
- [ ] Goal harian & streak benar saat pergantian hari dan zona waktu.
- [ ] SM-2: jawaban salah → kata muncul lebih cepat; jawaban benar → interval membesar; status berpindah semestinya.
- [ ] Semua 6 mode quiz menghasilkan skor, penjelasan, dan ringkasan yang benar.
- [ ] Pencarian Inggris & Indonesia, autocomplete, dan filter bekerja pada 10.000 kata uji (< 100 ms).
- [ ] Fallback audio (file → URL → TTS → pesan) teruji.
- [ ] Dark/Light mode, ukuran teks 4 tingkat, dan layar kecil (360 dp) tidak overflow.
- [ ] Reset progres menghapus progres namun tidak konten.
- [ ] Notifikasi harian terjadwal dan bisa dimatikan.
- [ ] `flutter analyze` bersih; `flutter test` hijau; APK release terpasang dan berjalan.

---

## 16. Persiapan Sinkronisasi Cloud

Belum diimplementasikan, tetapi arsitektur sudah siap (desain backend lengkap ada di [bagian 17](#17-backend-python--fastapi)):

- Kolom `updated_at` dan `sync_state` pada tabel progres.
- Akses data hanya lewat repository (mudah menambahkan `RemoteDataSource`).
- ID kata stabil dan konten terpisah dari progres, sehingga hanya data pengguna yang perlu disinkronkan.
- Strategi konflik yang disarankan: *last-write-wins* per baris `user_word`, penggabungan `review_log` (append-only).

---

## 17. Backend (Python + FastAPI)

Backend bersifat **opsional dan tambahan**: aplikasi tetap 100% berfungsi offline tanpa akun. Backend dipakai untuk tiga hal saja:

1. **Content delivery** — memperbarui paket kosakata tanpa rilis ulang aplikasi.
2. **Sinkronisasi progres** (opsional) — cadangan dan pindah perangkat bagi pengguna yang login.
3. **Admin konten** — mengelola kosakata, kategori, dan audio.

### 17.1 Prinsip

- **Offline-first:** klien tidak pernah menunggu server; sinkronisasi berjalan di latar belakang.
- **Login opsional:** pengguna anonim tetap bisa belajar penuh. Akun hanya untuk sync.
- **Server tidak menjalankan SM-2:** klien yang menghitung jadwal; server hanya menyimpan dan menggabungkan state (satu sumber logika).
- **Konten dan progres terpisah**, sejalan dengan `vocab.db` / `user.db` di aplikasi.

### 17.2 Tech Stack

| Kebutuhan | Pilihan |
|-----------|---------|
| Framework | FastAPI + Uvicorn (Gunicorn worker di produksi) |
| Validasi/skema | Pydantic v2 |
| ORM | SQLAlchemy 2.0 (async) + asyncpg |
| Migrasi | Alembic |
| Database | PostgreSQL 16 |
| Cache / rate limit | Redis (opsional di tahap awal) |
| Auth | JWT (access 15 menit + refresh 30 hari), hash password dengan Argon2 |
| Login sosial (opsional) | Google Sign-In (verifikasi ID token) |
| Penyimpanan audio | Object storage kompatibel S3 (mis. MinIO/Cloudflare R2) atau folder statis di belakang reverse proxy |
| Tugas latar | ARQ atau Celery (build paket konten, bersih-bersih) |
| Test | pytest, httpx `AsyncClient`, testcontainers |
| Lint/format | ruff, mypy |
| Dependency | `uv` atau Poetry |
| Deploy | Docker + Docker Compose, reverse proxy Caddy/Nginx (HTTPS), GitHub Actions |

### 17.3 Struktur Proyek

```
wordly-api/
├─ app/
│  ├─ main.py                  # FastAPI app, router, middleware
│  ├─ core/
│  │  ├─ config.py             # pydantic-settings (env)
│  │  ├─ security.py           # JWT, hashing
│  │  ├─ deps.py               # dependency: db session, current_user, admin
│  │  └─ errors.py             # exception handler, format error seragam
│  ├─ db/
│  │  ├─ base.py
│  │  ├─ session.py            # async engine & sessionmaker
│  │  └─ models/               # user.py, vocab.py, progress.py, content_pack.py
│  ├─ schemas/                 # Pydantic: request/response
│  ├─ routers/
│  │  ├─ auth.py
│  │  ├─ content.py            # manifest, delta, download pack
│  │  ├─ sync.py               # push/pull progres
│  │  ├─ vocab.py              # (admin) CRUD kosakata
│  │  ├─ stats.py              # ringkasan server-side (opsional)
│  │  └─ health.py
│  ├─ services/
│  │  ├─ content_service.py    # build manifest & pack
│  │  ├─ sync_service.py       # merge logic
│  │  └─ audio_service.py
│  └─ tasks/                   # ARQ/Celery jobs
├─ migrations/                 # Alembic
├─ tests/
├─ scripts/
│  ├─ import_vocab.py          # impor JSON → DB (reuse validator klien)
│  └─ build_content_pack.py    # hasilkan vocab.db (SQLite) + manifest
├─ Dockerfile
├─ docker-compose.yml
├─ pyproject.toml
└─ .env.example
```

Pola: `router → service → repository/model`. Router tipis (validasi + panggil service), logika bisnis di `services/`.

### 17.4 Skema Database (PostgreSQL)

```sql
-- Akun
CREATE TABLE app_user (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email         CITEXT UNIQUE,
  password_hash TEXT,                       -- NULL jika login Google
  google_sub    TEXT UNIQUE,
  display_name  TEXT,
  role          TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user','admin')),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_login_at TIMESTAMPTZ
);

CREATE TABLE refresh_token (
  id          UUID PRIMARY KEY,
  user_id     UUID NOT NULL REFERENCES app_user(id) ON DELETE CASCADE,
  token_hash  TEXT NOT NULL,
  device_id   TEXT,
  expires_at  TIMESTAMPTZ NOT NULL,
  revoked_at  TIMESTAMPTZ
);

-- Konten (sumber kebenaran kosakata)
CREATE TABLE category (
  id SERIAL PRIMARY KEY, slug TEXT UNIQUE NOT NULL, name TEXT NOT NULL,
  description TEXT NOT NULL, icon TEXT, sort_order INT NOT NULL DEFAULT 0
);

CREATE TABLE vocabulary (
  id                  INT PRIMARY KEY,           -- ID stabil, sama dengan di klien
  word                TEXT NOT NULL,
  word_normalized     TEXT NOT NULL,
  translation         TEXT NOT NULL,
  definition          TEXT NOT NULL,
  pronunciation_ipa   TEXT,
  part_of_speech      TEXT NOT NULL,
  difficulty_level    TEXT NOT NULL,
  cefr                TEXT,
  category_id         INT NOT NULL REFERENCES category(id),
  example_sentence    TEXT NOT NULL,
  example_translation TEXT NOT NULL,
  synonyms            JSONB NOT NULL DEFAULT '[]',
  antonyms            JSONB NOT NULL DEFAULT '[]',
  audio_url           TEXT,
  is_active           BOOLEAN NOT NULL DEFAULT TRUE,   -- soft delete
  content_version     INT NOT NULL,                    -- naik tiap perubahan
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (word_normalized, part_of_speech, category_id)
);
CREATE INDEX idx_vocab_version ON vocabulary(content_version);

CREATE TABLE content_release (          -- riwayat rilis paket konten
  version     INT PRIMARY KEY,
  notes       TEXT,
  pack_url    TEXT NOT NULL,            -- vocab.db (SQLite) lengkap
  pack_sha256 TEXT NOT NULL,
  pack_size   BIGINT NOT NULL,
  word_count  INT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Progres pengguna (untuk sync)
CREATE TABLE user_word (
  user_id        UUID NOT NULL REFERENCES app_user(id) ON DELETE CASCADE,
  vocab_id       INT  NOT NULL,
  status         TEXT NOT NULL,
  is_favorite    BOOLEAN NOT NULL DEFAULT FALSE,
  repetitions    INT NOT NULL,
  ease_factor    REAL NOT NULL,
  interval_days  INT NOT NULL,
  due_at         TIMESTAMPTZ,
  lapses         INT NOT NULL,
  correct_count  INT NOT NULL,
  wrong_count    INT NOT NULL,
  updated_at     TIMESTAMPTZ NOT NULL,    -- dari klien (dasar last-write-wins)
  server_seq     BIGINT NOT NULL,         -- untuk pull incremental
  PRIMARY KEY (user_id, vocab_id)
);

CREATE TABLE review_log (
  id          UUID PRIMARY KEY,           -- dibuat klien (idempotent)
  user_id     UUID NOT NULL REFERENCES app_user(id) ON DELETE CASCADE,
  vocab_id    INT NOT NULL,
  mode        TEXT NOT NULL,
  quality     SMALLINT NOT NULL,
  is_correct  BOOLEAN NOT NULL,
  reviewed_at TIMESTAMPTZ NOT NULL,
  server_seq  BIGINT NOT NULL
);

CREATE TABLE collection (
  id UUID PRIMARY KEY, user_id UUID NOT NULL REFERENCES app_user(id) ON DELETE CASCADE,
  name TEXT NOT NULL, updated_at TIMESTAMPTZ NOT NULL,
  deleted BOOLEAN NOT NULL DEFAULT FALSE, server_seq BIGINT NOT NULL
);
CREATE TABLE collection_word (
  collection_id UUID NOT NULL REFERENCES collection(id) ON DELETE CASCADE,
  vocab_id INT NOT NULL, added_at TIMESTAMPTZ NOT NULL,
  removed BOOLEAN NOT NULL DEFAULT FALSE, server_seq BIGINT NOT NULL,
  PRIMARY KEY (collection_id, vocab_id)
);

CREATE TABLE user_settings (
  user_id UUID PRIMARY KEY REFERENCES app_user(id) ON DELETE CASCADE,
  data JSONB NOT NULL, updated_at TIMESTAMPTZ NOT NULL
);
```

`server_seq` diambil dari sequence per-user/global sehingga klien cukup menyimpan `last_seq` untuk menarik perubahan sejak terakhir sync.

### 17.5 Endpoint API (prefix `/api/v1`)

| Grup | Method & Path | Auth | Fungsi |
|------|---------------|------|--------|
| Health | `GET /health` | — | Cek layanan & DB |
| Auth | `POST /auth/register` | — | Daftar email + password |
| | `POST /auth/login` | — | Dapatkan access + refresh token |
| | `POST /auth/google` | — | Tukar ID token Google |
| | `POST /auth/refresh` | refresh | Rotasi refresh token |
| | `POST /auth/logout` | user | Cabut refresh token |
| | `DELETE /auth/me` | user | Hapus akun & seluruh data |
| Content | `GET /content/manifest` | — | Versi konten terbaru, ukuran, hash, URL pack |
| | `GET /content/delta?since=<version>` | — | Perubahan kata (upsert + id yang dinonaktifkan) sejak versi tertentu |
| | `GET /content/pack/{version}` | — | Unduh `vocab.db` penuh (redirect ke storage) |
| Sync | `POST /sync/push` | user | Kirim perubahan progres dari klien |
| | `GET /sync/pull?since_seq=<n>` | user | Ambil perubahan dari perangkat lain |
| Profil | `GET /me` · `PATCH /me` | user | Profil & pengaturan |
| Admin | `GET/POST /admin/vocab` | admin | Daftar & tambah kata |
| | `PUT/DELETE /admin/vocab/{id}` | admin | Ubah / nonaktifkan kata |
| | `POST /admin/vocab/import` | admin | Impor massal JSON (dengan validasi) |
| | `POST /admin/audio` | admin | Unggah audio |
| | `POST /admin/content/release` | admin | Bangun & publikasikan versi konten baru |

Format error seragam:

```json
{ "error": { "code": "validation_error", "message": "Field 'word' wajib diisi", "details": [] } }
```

### 17.6 Strategi Konten (Delta + Pack)

1. Klien menyimpan `vocab_content_version` lokal.
2. Saat online, klien memanggil `GET /content/manifest`.
3. Bila versi server lebih baru:
   - selisih kecil → `GET /content/delta?since=N` lalu upsert ke `vocab.db`;
   - selisih besar atau instalasi baru → unduh `pack` penuh (SQLite), verifikasi `sha256`, lalu ganti file secara atomik.
4. Progres pengguna tidak tersentuh karena memakai `vocab_id` stabil.
5. Kata yang dihapus hanya dinonaktifkan (`is_active = false`) agar progres lama tidak yatim; klien menyembunyikannya dari daftar.

### 17.7 Strategi Sinkronisasi Progres

- **Unit sinkron:** baris `user_word`, `collection`, `collection_word`, `user_settings`, serta `review_log` (append-only).
- **Push:** klien mengirim semua baris dengan `sync_state != 'synced'`.
- **Resolusi konflik:** *last-write-wins* per baris berdasarkan `updated_at` klien; `review_log` digabung (idempoten lewat UUID dari klien); `correct_count`/`wrong_count` dihitung ulang dari `review_log` bila terjadi konflik agar tidak hilang.
- **Pull:** klien meminta perubahan dengan `server_seq > last_seq` dan menerapkannya ke `user.db`.
- **Idempotensi:** push yang diulang tidak menggandakan data.
- **Pemicu:** saat aplikasi dibuka, setelah sesi belajar selesai, dan periodik via WorkManager (hanya bila ada koneksi).

Contoh skema request:

```python
from datetime import datetime
from uuid import UUID
from pydantic import BaseModel, Field

class UserWordIn(BaseModel):
    vocab_id: int
    status: str = Field(pattern="^(new|learning|review|mastered)$")
    is_favorite: bool
    repetitions: int = Field(ge=0)
    ease_factor: float = Field(ge=1.3, le=3.5)
    interval_days: int = Field(ge=0)
    due_at: datetime | None
    lapses: int = Field(ge=0)
    correct_count: int = Field(ge=0)
    wrong_count: int = Field(ge=0)
    updated_at: datetime

class ReviewLogIn(BaseModel):
    id: UUID
    vocab_id: int
    mode: str
    quality: int = Field(ge=0, le=5)
    is_correct: bool
    reviewed_at: datetime

class SyncPushRequest(BaseModel):
    device_id: str
    words: list[UserWordIn] = []
    reviews: list[ReviewLogIn] = []
    # collections, collection_words, settings: pola serupa

class SyncPushResponse(BaseModel):
    accepted: int
    server_seq: int          # seq tertinggi setelah merge
```

Kerangka endpoint:

```python
@router.post("/sync/push", response_model=SyncPushResponse)
async def push(body: SyncPushRequest,
               user: User = Depends(current_user),
               db: AsyncSession = Depends(get_db)):
    return await sync_service.merge(db, user.id, body)
```

### 17.8 Keamanan

- HTTPS wajib; HSTS di reverse proxy.
- Password di-hash Argon2; refresh token disimpan sebagai hash dan dirotasi tiap pemakaian (deteksi pemakaian ulang).
- Rate limiting pada `/auth/*` dan `/sync/*` (mis. `slowapi` + Redis).
- Validasi ketat via Pydantic; batasi ukuran payload sync (mis. maks 2.000 baris per request).
- CORS dibatasi (hanya relevan untuk panel admin web).
- Endpoint admin dilindungi `role == 'admin'`; semua perubahan konten dicatat (`updated_at`, `content_version`).
- Secret hanya via environment/secret manager; `.env` tidak masuk git.
- Hak pengguna: hapus akun menghapus seluruh progres (`ON DELETE CASCADE`); sediakan kebijakan privasi (wajib untuk Play Store).
- Log tidak boleh memuat password, token, atau email lengkap.

### 17.9 Deployment

```yaml
# docker-compose.yml (ringkas)
services:
  api:
    build: .
    env_file: .env
    depends_on: [db, redis]
    command: gunicorn app.main:app -k uvicorn.workers.UvicornWorker -w 2 -b 0.0.0.0:8000
  db:
    image: postgres:16
    volumes: [pgdata:/var/lib/postgresql/data]
  redis:
    image: redis:7
  caddy:
    image: caddy:2
    ports: ["80:80", "443:443"]
    volumes: [./Caddyfile:/etc/caddy/Caddyfile, caddy_data:/data]
volumes: { pgdata: {}, caddy_data: {} }
```

- Bisa dijalankan di VPS kecil atau server sendiri; backup PostgreSQL harian (`pg_dump`) ke penyimpanan terpisah.
- CI/CD: GitHub Actions → ruff + mypy + pytest → build image → deploy.
- Observabilitas dasar: endpoint `/health`, log terstruktur (JSON), Sentry (opsional).
- Dokumentasi API otomatis tersedia di `/docs` (Swagger); matikan atau lindungi di produksi.

### 17.10 Integrasi dengan Flutter

- Tambah `dio` + interceptor (otomatis menyisipkan token dan refresh saat 401).
- Buat `RemoteDataSource` (Auth, Content, Sync) di setiap fitur sesuai arsitektur bagian 6; repository menggabungkan `LocalDataSource` dan `RemoteDataSource`.
- `SyncService` di klien: antrean perubahan (`sync_state`), retry dengan exponential backoff, berjalan via `workmanager`.
- Simpan token dengan `flutter_secure_storage`.
- Opsi pembangkitan klien dari OpenAPI (`openapi-generator`) agar model Dart selalu selaras dengan backend.

### 17.11 Roadmap Backend

| Fase | Cakupan |
|------|---------|
| B1 | Setup proyek, konfigurasi, Docker, `/health`, koneksi DB, Alembic |
| B2 | Model konten + `scripts/import_vocab.py` + endpoint `content/manifest` & `delta` |
| B3 | Pembangun paket konten (`vocab.db` + hash) dan `content/pack` |
| B4 | Auth: register/login/refresh/logout, hapus akun |
| B5 | Sync push/pull + test konflik & idempotensi |
| B6 | Endpoint admin + unggah audio + rilis konten |
| B7 | Rate limit, logging, backup, CI/CD, deploy |

Urutan yang disarankan: kerjakan B1–B3 dulu (konten update-able) karena manfaatnya paling langsung; B4–B5 baru dikerjakan setelah aplikasi offline stabil.

---

## 18. Aturan Proyek & Lisensi

- Bangun produk yang benar-benar berfungsi, bukan mockup; jangan ada placeholder pada fungsi inti.
- Identitas visual, logo, dan aset **harus original**; dilarang menyalin aset atau branding aplikasi referensi.
- Gunakan hanya aset audio/konten berlisensi legal dan cantumkan atribusi di halaman "Tentang".
- Lisensi kode: tentukan sebelum rilis (mis. proprietary atau MIT). Lisensi konten kosakata dicatat terpisah.
