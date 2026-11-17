# Perancangan Wordly

> Dokumen perancangan **terkini (v0.2)** — menggambarkan aplikasi yang sudah
> dibangun, bukan sekadar rencana. Dokumen brief awal (v0.1) diarsipkan di
> [`docs/arsip/perancangan-v0.1.md`](docs/arsip/perancangan-v0.1.md).

| | |
|---|---|
| Produk | Wordly — belajar kosakata Inggris–Indonesia |
| Platform | Android (Flutter), offline-first |
| Versi | 0.1.0+1 |
| Status | Fungsional: belajar → latihan → ulang terjadwal sudah menutup siklus |
| Ukuran konten | 13 kategori · 507 kata |
| Bahasa UI | Indonesia |

---

## 1. Tujuan & Target Pengguna

**Tujuan**
- Menambah kosakata Inggris pengguna Indonesia dengan terjemahan akurat dan contoh natural.
- Membentuk kebiasaan harian (target + streak).
- Menjaga ingatan lewat pengulangan berjarak (SM-2) yang transparan.

**Target pengguna:** pelajar, mahasiswa, pekerja; pemula sampai mahir (A1–C2).

**Prinsip produk**
- **Offline penuh.** Tidak ada request jaringan saat belajar; TTS memakai mesin perangkat.
- **Tanpa akun.** Data di perangkat; backend hanya untuk fase berikutnya.
- **Tanpa data palsu.** Semua angka di UI berasal dari `user.db`; kosong berarti kosong.
- **Tidak ada tombol dekoratif.** Aksi mati dilarang; fitur yang belum ada ditandai jelas.

---

## 2. Fitur & Status

| Kode | Fitur | Status | Catatan |
|---|---|---|---|
| A | Onboarding (level + target) | ✅ | Sekali, bisa diubah di Pengaturan |
| B | Home dashboard | ✅ | Kata hari ini, target, streak, jatuh tempo, riwayat |
| C | Detail kata (11 field) | ✅ | + audio TTS, bookmark, jadwal ulangan |
| D | Explore: kategori & level | ✅ | 13 kategori, filter level |
| E | Kamus/pencarian EN↔ID | ✅ | FTS5 + fallback LIKE |
| F | My Words (favorit/riwayat/status) | ✅ | 4 tab |
| G | Flashcard | ✅ | 5–20 kartu, flip 3D, geser, requeue |
| H | Quiz 6 mode | ✅ | MCQ, EN→ID, ID→EN, rumpang, listening, ejaan |
| I | Spaced Repetition SM-2 | ✅ | Satu scheduler untuk semua mode |
| J | Review terjadwal | ✅ | Prioritas keterlambatan & kesalahan |
| K | Pengaturan | ✅ | Tema, level, target, ukuran teks |
| L | Statistik terperinci | ⏳ | Angka ringkas sudah ada; grafik aktivitas masih kosong |
| M | Koleksi kata buatan sendiri | ⏳ | Tabel DB sudah ada, UI belum |
| N | Notifikasi harian | ⏳ | Belum |
| O | Audio file/URL (selain TTS) | ⏳ | Kolom `audio_url` sudah tersedia |
| P | Sinkronisasi cloud | ⏳ | Kolom `sync_state`, `updated_at` sudah disiapkan |

---

## 3. Navigasi & Layar

Bottom navigation 5 tab (`StatefulShellRoute.indexedStack`, state tiap tab terjaga):

```
Home        → kata hari ini, target, aksi cepat (Flashcard/Quiz/Review), riwayat
Explore     → pencarian, filter level, grid kategori → daftar kata kategori
Practice    → Flashcard, Quiz, Review terjadwal
My Words    → Favorit | Riwayat | Belum | Dikuasai
Profile     → statistik ringkas, grafik 7 hari, pengaturan
```

Layar penuh (tanpa bottom nav):

```
/onboarding      (sebelum onboarding selesai)
/word/:id        Detail kata
/category/:id    Daftar kata per kategori
/flashcards      Setup → sesi → ringkasan
/quiz            Setup → sesi → ringkasan
/review          Antrean → sesi → selesai
```

---

## 4. Design System

Sumber kebenaran token: `lib/core/design/`. Mockup HTML/CSS di `src/` disimpan
sebagai referensi visual, bukan bagian build.

### 4.1 Warna

Dua palet lengkap (gelap = tema utama), diimplementasikan sebagai
`ThemeExtension<AppPalette>` sehingga dapat diakses lewat `context.palette`.

| Token | Gelap | Terang |
|---|---|---|
| `bg` | `#0E1116` | `#F7F8FB` |
| `surface` | `#171B22` | `#FFFFFF` |
| `surfaceElevated` | `#1F2430` | `#F0F3F9` |
| `border` | `#2A3040` | `#E3E7EF` |
| `primary` | `#7C9CFF` | `#4A6BE0` |
| `accent` | `#F2C46D` | `#D99A2B` |
| `success` / `warning` / `error` | `#4FD1A1` / `#F5A25D` / `#F27C8D` | disesuaikan kontras |
| `textPrimary` / `textSecondary` | `#F2F4F8` / `#9AA3B5` | `#151922` / `#5C6578` |

Turunan semantik (`primarySoft`, `primaryLine`, `successText`, dll.) juga ada di
palet, termasuk gradien `heroGradient`, `flashGradient`, `brandGradient`, dan
`avatarGradient`.

**Aturan:** warna **tidak boleh** ditulis literal di widget. Selalu lewat
`context.palette` atau `Theme.of(context)`.

### 4.2 Tipografi

| Peran | Font | Contoh pemakaian |
|---|---|---|
| Display | Plus Jakarta Sans 600/700/800 | judul, kata utama, angka statistik |
| Body | Inter 400/500/600 | teks isi, label, tombol |
| IPA | Noto Sans 400/500 | transkrip fonetik |

Skala: display 40/33/26, headline 19/16, title 18/15/14, body 15/13/11.5,
label 10.5–12. Ukuran teks pengguna (85–130%) diterapkan lewat `TextScaler`.

### 4.3 Spacing, radius, gerak

- Spacing kelipatan 4: 4 / 8 / 12 / 16 / 24 / 32 / 48; padding halaman 20.
- Radius: 8 (chip kecil), 14 (tombol/input), 20 (card), 24 (hero), 26 (flashcard), 999 (pill).
- Animasi 180–320 ms `easeOutCubic`; flip kartu 350 ms.

### 4.4 Komponen

`AppCard` (flat/elevated/hero/primary/accent + animasi tekan), `AppButton`
(primary/ghost/warn/success/text × medium/small, loading), `AppChip` +
`StatusPill`, `AppProgressBar`, `AppProgressRing`, `IconTile`, `SectionHeader`,
`PageHeader`, `EmptyState`, `WordRow`/`WordListCard`, `FlipCard`.

---

## 5. Arsitektur

Pendekatan **feature-first + clean architecture ringan**: UI → provider → repository → DAO.
UI tidak pernah menyentuh database langsung.

```
lib/
├─ main.dart                 # bootstrap DB + prefs, lalu runApp
├─ app/
│  ├─ app.dart               # MaterialApp.router, tema, TextScaler, gate onboarding
│  ├─ router.dart            # go_router: 5 branch + layar penuh
│  ├─ bootstrap.dart         # buka vocab.db & user.db, jalankan seeder
│  └─ shell/                 # AppShell + AppNavBar
├─ core/
│  ├─ audio/tts_service.dart # flutter_tts + speakWord(context, text)
│  ├─ db/
│  │  ├─ content/            # ContentDatabase (vocab.db), tabel, seeder
│  │  ├─ user/               # UserDatabase (user.db), tabel progres
│  │  ├─ vocab_repository.dart  # gabungan konten + progres
│  │  └─ database_providers.dart
│  ├─ design/                # palet, tipografi, spacing, tema
│  ├─ settings/              # AppSettings + SettingsController (persisten)
│  ├─ srs/sm2.dart           # scheduler murni (unit tested)
│  ├─ utils/                 # format tanggal Indonesia
│  └─ widgets/               # komponen reusable
└─ features/
   ├─ onboarding/ home/ explore/ word_detail/ my_words/
   ├─ flashcards/ quiz/ review/ practice/ profile/
   └─ (settings digabung di profile)
```

**Pola penting**
- `ProviderScope` menerima override database & `SharedPreferences` dari `main()`
  sehingga seluruh UI bisa membaca data secara sinkron.
- `vocabRepositoryProvider` dibuat ulang saat level/target berubah, sehingga
  antrean & kata harian otomatis mengikuti pengaturan.
- Semua operasi tulis memanggil `ref.invalidate(...)` pada provider terkait agar
  Home/Profil/Kata Saya ikut segar tanpa refresh manual.

---

## 6. Database (Drift)

Dua file terpisah agar pembaruan konten tidak menyentuh progres pengguna.

### 6.1 `vocab.db` — konten (diisi dari aset)

```
categories(id, slug, name, description, icon, sort_order)
vocabularies(id, word, word_normalized, translation, definition,
             pronunciation_ipa, part_of_speech, difficulty_level, cefr,
             category_id → categories.id, example_sentence,
             example_translation, synonyms JSON, antonyms JSON,
             audio_url, created_at)
  UNIQUE (word_normalized, part_of_speech, category_id)

vocabulary_fts (FTS5: word, translation, content='vocabularies')
  + trigger ai / ad / au untuk sinkronisasi indeks
```

### 6.2 `user.db` — progres

```
user_words(vocab_id PK, status, is_favorite, repetitions, ease_factor,
           interval_days, due_at, lapses, correct_count, wrong_count,
           first_seen_at, last_reviewed_at, updated_at, sync_state)
review_logs(id, vocab_id, mode, quality, is_correct, reviewed_at)
collections(id, name, created_at, updated_at)
collection_words(collection_id, vocab_id, added_at)
daily_activities(day PK, words_learned, reviews_done, correct, wrong, goal_met)
word_of_day(day PK, vocab_id)
```

`vocab_id` tidak memakai foreign key karena beda file database; konsistensi
dijaga di lapisan aplikasi + ID kata yang stabil.

### 6.3 Seeding & versi konten

- `VocabSeeder` membaca semua `assets/vocab/*.json` lewat `AssetManifest`.
- "Tanda tangan" konten = `path:version:jumlah_kata` per berkas. Bila berbeda
  dari `shared_preferences`, konten diimpor ulang (hapus konten, bukan progres).
- Impor berjalan dalam satu transaksi; ID ganda ditolak.

---

## 7. Spaced Repetition (SM-2)

Implementasi: `lib/core/srs/sm2.dart` (murni, tanpa I/O) + 10 unit test.

**Kualitas jawaban (`q`)**
| Kondisi | q |
|---|---|
| Salah | 1 |
| Benar dengan petunjuk | 3 |
| Benar | 4 |
| Benar & mudah (swipe kanan) | 5 |

**Algoritma**
```
q < 3 : repetitions = 0, interval = 0, lapses + 1,
        status = learning, due = now + 10 menit
q ≥ 3 : repetitions + 1
        interval = 1 (rep 1) | 3 (rep 2) | round(interval × ease)
        ease = clamp(ease + 0.1 − (5−q)(0.08 + (5−q)·0.02), 1.3, 3.5)
        status = mastered bila interval ≥ 21 dan repetitions ≥ 4, selain itu review
        due = now + interval hari
```

**Status kata:** `new` → `learning` → `review` → `mastered` (turun ke `learning` bila salah).

**Antrean review** (`reviewQueue`): hanya kata `due_at ≤ sekarang`, diurutkan
paling terlambat → `lapses` terbanyak → rasio salah tertinggi.

**Sinkronisasi progres:** semua mode (detail kata, flashcard, quiz, review)
memanggil `repository.answer()` yang sama → menulis `user_words`, `review_logs`,
dan `daily_activities` sekaligus.

---

## 8. Konten Kosakata

- 13 kategori × 39 kata = **507 kata** (target minimum 500 tercapai).
- Berkas: `assets/vocab/NN-nama-kategori.json` dengan struktur:

```json
{
  "version": 2,
  "category": {"id": 1, "slug": "daily-conversation", "name": "Daily Conversation",
               "description": "...", "icon": "chat", "order": 1},
  "words": [
    {"id": 1001, "word": "hello", "translation": "halo",
     "definition": "A greeting used when you meet someone.",
     "ipa": "/həˈləʊ/", "pos": "interjection", "level": "beginner", "cefr": "A1",
     "example": "Hello, nice to meet you.",
     "example_id": "Halo, senang bertemu denganmu.",
     "synonyms": ["hi"], "antonyms": []}
  ]
}
```

- Validasi wajib sebelum commit:

```bash
dart run tool/validate_vocab.dart
# 13 kategori · 507 kata · 0 error · 0 peringatan
```

Validator memeriksa: field wajib, format IPA, level/CEFR/POS sah, ID & kata
duplikat, sinonim/antonim tidak memuat kata itu sendiri, minimal 10 kata/kategori.

- Pedoman penulisan: terjemahan sesuai konteks (beberapa padanan dipisah `;`),
  contoh kalimat natural ≤ 15 kata untuk pemula, ejaan `example_id` bukan
  terjemahan kata-per-kata.

---

## 9. Audio

| Urutan | Sumber | Status |
|---|---|---|
| 1 | File audio di `assets/vocab/audio/` | ⏳ belum ada berkasnya |
| 2 | URL `audio_url` | ⏳ kolom tersedia |
| 3 | **TTS perangkat** (`flutter_tts`, en-US, rate 0,45) | ✅ dipakai sekarang |
| 4 | Tidak ada audio | ✅ snackbar "Audio tidak tersedia" |

Titik pemakaian: Detail Kata, kartu Kata Hari Ini (Home), Quiz listening & ejaan.
TTS bersifat *best-effort*: aktivasi suara bergantung perangkat.

---

## 10. Pengaturan & Persistensi

Disimpan di `shared_preferences` (dimuat sebelum `runApp`, jadi tidak ada
kedipan UI):

| Kunci | Nilai | Efek |
|---|---|---|
| `learning_level` | beginner/intermediate/advanced | kata hari ini, antrean, pool kuis |
| `daily_goal` | 5/10/20 | ring target, goal & streak |
| `text_scale` | 0.85/1/1.15/1.3 | `TextScaler` seluruh aplikasi |
| `theme_mode` | dark/light/system | tema |
| `onboarding_done` | bool | gate layar onboarding |
| `audio_autoplay` | bool | disiapkan, belum dipakai |
| `vocab_content_signature` | string | deteksi konten baru |

---

## 11. UX: State Kosong, Loading, Error

- Daftar kosong → `EmptyState` dengan penjelasan + aksi (mis. "Jelajahi kosakata").
- Review tanpa jatuh tempo → "Semua beres hari ini 🎉" + tombol belajar kata baru.
- Pencarian tanpa hasil → "Kata tidak ditemukan" + saran ubah filter.
- Error database → pesan + penyebab, bukan layar putih.
- Loading awal tidak ada karena seeding selesai sebelum `runApp`.

---

## 12. Branding

- Ikon & splash dibuat dari token desain (`tool/make_brand_assets.py`, Pillow):
  latar `#0E1116`, glow biru, huruf W gradien `#93ACFF → #5F7FE6`.
- Adaptive icon Android (foreground/background) via `flutter_launcher_icons`.
- Splash (warna + logo, termasuk Android 12+) via `flutter_native_splash`.
- Font memakai lisensi SIL Open Font License (Plus Jakarta Sans, Inter, Noto Sans).

---

## 13. Kualitas

| Aspek | Kondisi saat ini |
|---|---|
| `flutter analyze` | 0 issue |
| `flutter test` | 12 tes (10 SM-2 + 2 pengaturan/tema) |
| Build | `flutter build apk --debug` sukses |
| Verifikasi visual | Semua layar dijalankan di emulator Android 16 (lihat `docs/screenshots/`) |
| Konten | 507 kata tervalidasi |

**Belum ada:** tes widget per layar, tes integrasi end-to-end, tes performa pada
10.000 kata, dan build release yang ditandatangani.

---

## 14. Roadmap Sisa

| Prioritas | Pekerjaan |
|---|---|
| 1 | Build APK release + keystore + uji di perangkat nyata |
| 2 | Koleksi kata (tabel & UI) |
| 3 | Statistik terperinci: grafik mingguan/bulanan dari `daily_activities` |
| 4 | Notifikasi harian (`flutter_local_notifications` + `timezone`) |
| 5 | Audio file/URL + atribusi lisensi di halaman Tentang |
| 6 | Sinkronisasi cloud (FastAPI + PostgreSQL sesuai brief v0.1) |

---

## 15. Risiko & Catatan Teknis

| Risiko | Mitigasi saat ini |
|---|---|
| Flutter 3.50 memakai paket `material_ui`, bukan `flutter/material.dart` | Semua impor memakai `package:material_ui/material_ui.dart` |
| JDK 25 tidak didukung Gradle | Dipakai JDK 21 (`JAVA_HOME` + `flutter config --jdk-dir`) |
| Kotlin gagal menutup cache di Windows | `kotlin.incremental=false` di `android/gradle.properties` |
| Emulator crash dengan `-gpu auto` | Pakai `-gpu swiftshader_indirect` (lihat `docs/CARA-JALAN.md`) |
| TTS tidak tersedia di sebagian perangkat | Fallback snackbar, tidak memblokir alur |
| Ukuran layar 360 dp | Semua halaman memakai `ListView`/scroll; belum diuji menyeluruh |

---

## 16. Referensi

- Brief awal & rencana backend lengkap: [`docs/arsip/perancangan-v0.1.md`](docs/arsip/perancangan-v0.1.md)
- Panduan menjalankan di mesin pengembangan: [`docs/CARA-JALAN.md`](docs/CARA-JALAN.md)
- Panduan kontribusi/agen: [`AGENTS.md`](AGENTS.md)
- Mockup HTML & screenshot desain: `src/` dan `mockups/`
