# Cara Menjalankan Wordly

Panduan untuk mesin ini (Windows 11, VS Code). Semua path sudah terpasang dan
terdaftar di PATH pengguna, jadi **buka terminal baru** dulu agar PATH terbaca.

## Yang sudah terpasang

| Komponen | Lokasi / versi |
|---|---|
| Flutter SDK | `D:\Development\Tools\flutter` (3.50.0 stable, Dart 3.14.0) |
| Android Studio | `C:\Program Files\Android\Android Studio` (2026.2.2.9) |
| Android SDK | `C:\Users\bayuo\AppData\Local\Android\Sdk` (API 36, build-tools 36.1.0) |
| JDK untuk Gradle | `C:\Program Files\Eclipse Adoptium\jdk-21.0.13.9-hotspot` |
| Emulator | AVD `Wordly_Pixel` — Android 16 (API 36), Pixel 7 |

`JAVA_HOME`, `ANDROID_HOME`, dan `ANDROID_SDK_ROOT` sudah diset di level user.

## Perintah harian

```powershell
cd D:\Development\Flutter\Wordly

flutter doctor          # cek kesehatan toolchain
flutter run             # jalankan app (emulator harus hidup)
flutter analyze         # cek error/lint tanpa menjalankan app
flutter test            # jalankan unit test
```

## Menyalakan emulator

Kalau emulator belum hidup:

```powershell
# lewat Android Studio: Device Manager → Wordly_Pixel → ▶
# atau lewat terminal (renderer software — paling stabil di mesin ini):
& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -avd Wordly_Pixel -no-boot-anim -no-snapshot-load -gpu swiftshader_indirect
```

> Catatan: `-gpu auto` (bawaan) sempat membuat emulator crash di mesin ini.
> `swiftshader_indirect` lebih lambat sedikit tetapi stabil. Screenshot yang
> diambil langsung setelah interaksi kadang masih frame lama — beri jeda 2–3 detik.

Cek perangkat yang terdeteksi:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
flutter devices
```

## Hot reload saat `flutter run`

Saat app berjalan, terminal `flutter run` menerima tombol:

| Tombol | Fungsi |
|---|---|
| `r` | hot reload (ubah UI tanpa restart) |
| `R` | hot restart (reset state) |
| `q` | keluar |

Di VS Code, cukup tekan `F5` (pilih device `Wordly_Pixel`).

## Fitur yang sudah bisa dipakai

- **Home** — kata hari ini, target harian, streak, jatuh tempo, riwayat singkat.
- **Explore** — 13 kategori (507 kata), filter level, pencarian Inggris ↔ Indonesia.
- **Detail kata** — 11 field, jadwal ulangan, bookmark, tombol "Sudah paham"/"Pelajari lagi" (SM-2).
- **Kata Saya** — Favorit, Riwayat, Belum Dikuasai, Dikuasai.
- **Practice → Flashcard** — pilih 5/10/12/20 kartu, balik kartu, geser kiri/kanan, ringkasan sesi, ulangi kata yang salah.

Belum dibangun: Quiz (6 mode), sesi Review terjadwal, audio/TTS, onboarding, pengaturan (target, ukuran teks), koleksi.

## Konten kosakata & basis data

```powershell
dart run tool\validate_vocab.dart     # validasi assets\vocab\*.json
```

- Konten ada di `assets/vocab/NN-kategori.json` (satu berkas per kategori).
- Aplikasi mengisi `vocab.db` otomatis saat pertama dijalankan. Versi konten
  dihitung dari isi berkas; **naikkan `"version"`** di berkas JSON setiap kali
  mengubah kata agar konten di perangkat diperbarui.
- Progres pengguna tersimpan terpisah di `user.db`, jadi impor ulang konten
  tidak menghapus progres.
- Setelah mengubah skema Drift: `dart run build_runner build`.

## Struktur folder

```
Wordly/
├─ lib/                 # kode aplikasi Flutter (Dart)
├─ assets/fonts/        # TTF siap pakai (Inter, Plus Jakarta Sans, Noto Sans)
├─ android/             # konfigurasi Android (applicationId id.wordly.app)
├─ docs/                # dokumen rancangan produk + panduan ini
├─ src/                 # MOCKUP HTML (referensi desain, bukan bagian app)
├─ mockups/             # screenshot mockup (referensi desain)
└─ tools/               # skrip Python untuk regenerasi mockup & font
```

> `src/`, `mockups/`, dan `tools/` sengaja **tidak** ikut di-build; itu bahan
> desain. Kalau tidak diperlukan lagi, bisa dipindah ke folder terpisah.

## Regenerasi aset

```powershell
# mockup HTML → PNG (butuh: pip install playwright; playwright install chromium)
python tools\render_mockups.py

# font: skrip konversi ada di riwayat kerja; output akhir di assets/fonts/
```

## Kalau ada masalah

| Gejala | Penyebab umum | Solusi |
|---|---|---|
| `flutter` tidak dikenali | terminal lama belum baca PATH | buka terminal baru / restart VS Code |
| Gradle gagal soal Java version | `JAVA_HOME` bukan JDK 21 | set `JAVA_HOME` ke JDK 21 |
| Emulator tidak muncul di `flutter devices` | emulator belum boot | tunggu, cek `adb devices` |
| Build lambat sekali | build pertama unduh Gradle | normal, hanya sekali |
| `Could not close incremental caches ... kotlin` | bug Kotlin di Windows | sudah diatasi lewat `kotlin.incremental=false` di `android/gradle.properties` |
