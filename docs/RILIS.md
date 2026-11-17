# Panduan Rilis (Android)

Dokumen ini menjelaskan cara menandatangani, membangun, dan menerbitkan APK Wordly.
**Jangan pernah** commit `android/key.properties` atau `*.jks` ke Git.

---

## 1. Keystore rilis

File: `android/app/wordly-release.jks`
Konfigurasi: `android/key.properties` (diabaikan Git)

| Item | Nilai |
|---|---|
| Alias | `wordly` |
| Algoritma | RSA 2048, SHA384withRSA |
| Masa berlaku | 10.000 hari (±27 tahun) |
| DN | `CN=Wordly, OU=Mobile, O=Wordly, L=Jakarta, ST=DKI Jakarta, C=ID` |
| SHA-256 sertifikat | `9c74080740c23424e6ddd98666890788dc58a7a7e1499412413cc4294854b15e` |

Lihat kata sandi di `android/key.properties`. **Simpan salinan keystore + kata
sandinya di tempat aman (password manager / backup terenkripsi).** Jika hilang,
aplikasi tidak bisa diperbarui di Google Play dengan identitas yang sama.

Perintah membuat keystore baru (bila perlu):

```powershell
keytool -genkeypair -v -keystore android\app\wordly-release.jks -alias wordly `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -dname "CN=Wordly, OU=Mobile, O=Wordly, L=Jakarta, ST=DKI Jakarta, C=ID"
```

---

## 2. Build

```powershell
flutter build apk --release                     # satu APK universal
flutter build apk --release --split-per-abi     # APK per arsitektur (lebih kecil)
flutter build appbundle --release               # untuk Google Play
```

`android/app/build.gradle.kts` otomatis memakai keystore rilis bila
`android/key.properties` ada; jika tidak, build fallback ke debug key.

Verifikasi tanda tangan:

```powershell
& "$env:ANDROID_HOME\build-tools\36.1.0\apksigner.bat" verify --print-certs `
  build\app\outputs\flutter-apk\app-release.apk
```

Hash untuk catatan rilis:

```powershell
Get-FileHash build\app\outputs\flutter-apk\app-release.apk -Algorithm SHA256
```

---

## 3. Menerbitkan ke GitHub

```powershell
git tag -a v0.1.1 -m "Wordly 0.1.1"
git push origin main --tags
gh release create v0.1.1 build\app\outputs\flutter-apk\app-release.apk#wordly-0.1.1.apk `
  --title "Wordly v0.1.1" --notes-file docs/rilis/v0.1.1.md --latest
```

---

## 4. CI/CD (GitHub Actions)

- `.github/workflows/ci.yml` — analyze, test, dan validator konten pada setiap push/PR.
- `.github/workflows/release.yml` — saat tag `v*` dibuat: build APK + AAB, hitung SHA256,
  unggah artefak, lalu publikasikan GitHub Release otomatis.

Agar artefak di CI ditandatangani keystore rilis, tambahkan **Repository secrets**:

| Secret | Isi |
|---|---|
| `KEYSTORE_BASE64` | hasil `base64 -w0 android/app/wordly-release.jks` |
| `KEYSTORE_PASSWORD` | kata sandi keystore |
| `KEY_ALIAS` | `wordly` |
| `KEY_PASSWORD` | kata sandi key (biasanya sama) |

Tanpa secrets, CI tetap membangun APK dengan debug key dan menampilkan peringatan.

## 5. Catatan penting saat ini

- **compileSdk 37** diperlukan oleh `flutter_local_notifications` 23.
  `android/app/build.gradle.kts` sudah menyetelnya eksplisit.
- **Core library desugaring** aktif (`desugar_jdk_libs:2.1.5`) untuk plugin
  notifikasi.
- v0.1.0 diterbitkan dengan **debug key**. Karena tanda tangan berubah, pengguna
  v0.1.0 harus **uninstall dulu** sebelum memasang v0.1.1 (Android menolak
  update dengan sertifikat berbeda).
- Sebelum ke Play Store: siapkan kebijakan privasi, ikon 512×512, screenshot
  toko, dan pastikan `targetSdk` memenuhi syarat Google Play saat itu.
