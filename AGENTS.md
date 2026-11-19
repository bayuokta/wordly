# AGENTS.md

Panduan untuk agen AI dan kontributor manusia yang mengubah repo ini.
Baca `docs/PERANCANGAN.md` dulu untuk memahami produk; dokumen ini fokus pada
**cara kerja yang benar di dalam kode**.

---

## 1. Ringkasan proyek

Wordly adalah aplikasi Flutter (Android, offline-first) untuk belajar kosakata
Inggris–Indonesia: 1.007 kata dalam 13 kategori, latihan (flashcard & 6 mode kuis),
dan pengulangan berjarak SM-2. Tanpa akun, tanpa jaringan.

- Flutter 3.50.0 · Dart 3.14 · material_ui (bukan `flutter/material.dart`)
- Riverpod 3.5 · Drift (SQLite) · go_router 18 · flutter_tts · shared_preferences

---

## 2. Aturan yang tidak boleh dilanggar

1. **Impor Material** selalu `package:material_ui/material_ui.dart`.
   `package:flutter/material.dart` sudah deprecated di Flutter 3.50.
2. **Warna tidak boleh hardcoded** di widget. Gunakan `context.palette.<token>`
   atau `Theme.of(context)`. Token baru ditambahkan di `lib/core/design/app_palette.dart`
   (gelap **dan** terang).
3. **Tidak ada data dummy.** Angka, daftar, dan progres harus berasal dari
   `vocab.db`/`user.db`. Jika data belum ada, tampilkan `EmptyState`.
4. **Tidak ada tombol dekoratif.** Setiap tombol harus melakukan sesuatu; fitur
   yang belum siap ditandai `Fase N`/`Siap` atau disembunyikan.
5. **UI berbahasa Indonesia**, identifier kode berbahasa Inggris.
6. Jangan menyalin aset/branding/konten dari aplikasi atau kamus berhak cipta.

---

## 3. Perintah penting

```bash
flutter pub get
flutter analyze                                # wajib 0 issue
flutter test                                   # wajib hijau
dart run build_runner build                    # setelah mengubah skema Drift
dart run tool/validate_vocab.dart              # wajib 0 error sebelum commit konten
dart run flutter_launcher_icons                # setelah mengubah aset ikon
dart run flutter_native_splash:create          # setelah mengubah aset splash
flutter run                                    # jalankan di emulator/perangkat
flutter build apk --debug                      # verifikasi build
```

Di mesin Windows ini `flutter` sudah ada di PATH; `JAVA_HOME` harus JDK 21.
Detail lingkungan ada di `docs/CARA-JALAN.md`.

---

## 4. Peta repo & tempat menaruh kode

```
lib/app/            bootstrap, router, shell, MaterialApp
lib/core/design/    palet, tipografi, spacing, tema  ← token desain
lib/core/db/        database Drift, seeder, repository, provider
lib/core/settings/  AppSettings + SettingsController
lib/core/srs/       algoritma SM-2 (murni, mudah dites)
lib/core/widgets/   komponen reusable (AppButton, AppCard, WordRow, FlipCard, ...)
lib/features/<fitur>/presentation/   halaman
lib/features/<fitur>/domain/         model/logika spesifik fitur
assets/vocab/*.json konten kosakata
assets/fonts/       TTF statis (Inter, Plus Jakarta Sans, Noto Sans)
assets/branding/    ikon & logo splash
tool/               validator konten, generator aset brand/mockup
docs/               panduan & screenshot; src/ & mockups/ = referensi desain
```

Aturan penempatan:
- Komponen dipakai ≥2 fitur → `lib/core/widgets/`.
- Logika tanpa I/O (mis. algoritma) → `domain/` atau `core/`, harus ada unit test.
- Query database → repository/DAO, **jangan** di widget.

---

### Lapisan sinkronisasi (`lib/core/sync/`)

- `api_client.dart` — HTTP + bearer token, pesan error bahasa Indonesia.
- `sync_service.dart` — push/pull progres; push `user_words` dengan
  `sync_state != synced`, `review_logs`, `daily_activities`. Saat pull,
  `review_log` dicek dulu berdasarkan `vocab_id + reviewed_at` agar tidak dobel.
- `content_sync.dart` — manifest + delta konten; **ID kata tidak boleh diubah**.
  Kata dari `disabled_ids` ditandai `is_active = false`, bukan dihapus.
- `sync_coordinator.dart` — jalan di latar belakang, maksimal sekali per menit.
- `sync_bootstrap.dart` — dipasang di `app.dart`; **jangan** menunggu jaringan
  sebelum render dan **jangan** memanggil sync dari halaman belajar.
- Base URL: `String.fromEnvironment('WORDLY_API_BASE')`, default `10.0.2.2:8000`.
- Tamu/belum login harus return lebih awal sebelum menyentuh provider database.

## 5. Database & data

- **Dua database terpisah:** `vocab.db` (konten, read-only saat runtime) dan
  `user.db` (akun, sesi, progres). Jangan gabungkan.
- **Semua tabel progres punya `user_id`** (akun 1 = Tamu). Setiap query di
  `UserDatabase` **wajib** difilter `user_id`; jangan pernah membaca progres
  tanpa parameter pengguna.
- Repository menerima `userId` dari `sessionProvider`; jangan menyimpan
  salinan `userId` di widget atau meng-hardcode `guestUserId`.
- Kata sandi **hanya** lewat `PasswordHasher` (PBKDF2). Jangan pernah menyimpan
  teks asli, mencatatnya ke log, atau mengembalikannya di UI.
- Akun pertama mewarisi progres Tamu (`claimGuestProgress`). Hati-hati saat
  mengubah alur ini—jangan sampai progres pengguna hilang.
- ID kata harus **stabil** karena `user.db` hanya menyimpan `vocab_id`. Jangan
  mengubah ID yang sudah ada; tambahkan ID baru.
- Setelah mengubah tabel: `dart run build_runner build`, lalu naikkan
  `schemaVersion` + tulis migrasi bila data pengguna tidak boleh hilang.
- Pembacaan lintas-DB dilakukan di `VocabRepository` (bukan join SQL).
- Setiap operasi tulis progres harus lewat `VocabRepository.answer()` agar
  `user_words`, `review_logs`, dan `daily_activities` tetap konsisten.

### Menambah kata

1. Edit `assets/vocab/NN-kategori.json` (13 field wajib, lihat `docs/PERANCANGAN.md` §8).
2. ID baru melanjutkan rentang kategori (mis. kategori 1 → `10xx`).
3. Naikkan `"version"` berkas (opsional; tanda tangan konten juga berubah karena
   jumlah kata berubah).
4. `dart run tool/validate_vocab.dart` → harus 0 error.
5. Uji aplikasi: konten harus terimpor ulang otomatis, progres lama tetap ada.

---

## 6. State management (Riverpod)

- Data disiapkan di `main()` (database + prefs) lalu di-override ke `ProviderScope`;
  UI boleh membaca secara sinkron.
- Provider turunan didefinisikan di `lib/core/db/database_providers.dart`.
- Repository di-*rebuild* saat pengaturan berubah (level/target), jadi jangan
  menyimpan salinan level di tempat lain.
- Setelah menulis progres, **invalidate** provider terkait:
  `homeSnapshotProvider`, `reviewQueueProvider`, `favoritesProvider`,
  `learningWordsProvider`, `masteredWordsProvider`, `historyProvider`,
  `wordDetailProvider(id)`.
- Jangan menangani login langsung di UI; gunakan `sessionProvider`
  (`signIn`, `signUp`, `signOut`, `deleteAccount`) yang juga mengurus token.

---

## 7. Konvensi UI

- Semua halaman memakai `SafeArea(bottom: false)` + `ListView` agar aman di 360 dp.
- Jarak/ukuran memakai `AppSpacing`/`AppRadius`, bukan angka liar.
- Animasi memakai `AppMotion` (180–320 ms, `easeOutCubic`).
- Teks mengikuti tema (`Theme.of(context).textTheme`, `context.eyebrow`,
  `context.tiny`) supaya `TextScaler` pengguna ikut berlaku.
- Chip status memakai `AppChip`/`StatusPill`; jangan membuat pill baru.
- Setiap kondisi kosong memakai `EmptyState` dengan ajakan tindakan.

---

## 8. Test & definition of done

Sebuah perubahan dianggap selesai bila:

- [ ] `flutter analyze` → **No issues found**
- [ ] `flutter test` → semua lolos (tambah tes untuk logika baru)
- [ ] `dart run tool/validate_vocab.dart` → 0 error (bila menyentuh konten)
- [ ] Dijalankan minimal sekali di emulator; screenshot layar terkait disimpan ke
      `docs/screenshots/` bila tampilan berubah
- [ ] Tidak ada teks Inggris yang bocor ke UI, tidak ada warna hardcoded
- [ ] Pesan commit deskriptif (`feat:`, `fix:`, `docs:`, `content:`, `chore:`)

---

## 9. Jebakan lingkungan (Windows)

| Gejala | Penyebab | Solusi |
|---|---|---|
| `flutter` tidak dikenali | terminal lama | buka terminal baru |
| Gradle gagal soal Java | `JAVA_HOME` bukan JDK 21 | arahkan ke JDK 21 |
| `Could not close incremental caches … kotlin` | bug Kotlin di Windows | sudah dimatikan lewat `kotlin.incremental=false` |
| Unduhan Gradle macet | `services.gradle.org` lambat | unduh manual dari `downloads.gradle.org` ke cache wrapper |
| NDK tidak terpasang otomatis | `sdkmanager` lama deprecated | `android sdk install "ndk;28.2.13676358"` |
| Emulator mati sendiri | renderer GPU | jalankan dengan `-gpu swiftshader_indirect` |
| Screenshot tampak frame lama | renderer software | beri jeda 2–3 detik sebelum `screencap` |

---

## 10. Yang jangan dilakukan

- Menambah dependency berat tanpa kebutuhan jelas (offline-first!).
- Memanggil jaringan pada alur belajar inti.
- Mengubah `AppPalette` hanya di satu mode (gelap/terang harus sepasang).
- Menghapus/mengganti ID kata atau mengosongkan `user.db` saat memperbarui konten.
- Membuat layar yang "terlihat selesai" tetapi tombolnya tidak berfungsi.
- Commit file build (`build/`), `.dart_tool/`, atau rahasia/keystore.
