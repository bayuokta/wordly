# Panduan Publikasi Google Play

Dokumen kerja untuk mengunggah Wordly ke Play Console. Bagian bertanda
`<...>` perlu kamu isi/ganti sebelum submit.

---

## 1. Identitas aplikasi

| Field | Nilai |
|---|---|
| Nama aplikasi (≤30) | `Wordly: Belajar Kosakata` |
| Package | `id.wordly.app` |
| Kategori | Education |
| Tag | Education, Languages |
| Harga | Gratis |
| Ikon | `assets/branding/play_store_icon_512.png` (512×512) |
| Feature graphic | belum ada — buat 1024×500 |
| Screenshot | `docs/store/` (1080×1920, minimal 2) |

## 2. Deskripsi

**Deskripsi singkat (≤80 karakter)**

```
Belajar 500+ kosakata Inggris–Indonesia offline dengan pengulangan berjarak.
```

**Deskripsi lengkap (≤4000 karakter)**

```
Wordly membantu kamu menambah kosakata bahasa Inggris dengan cara yang benar-benar
menempel: sedikit setiap hari, diulang tepat waktu.

BELAJAR
• 500+ kata dalam 13 kategori: percakapan harian, bisnis, akademik, perjalanan,
  teknologi, makanan, pendidikan, kesehatan, alam, perasaan, phrasal verbs, idiom,
  dan bahasa informal.
• Setiap kata dilengkapi terjemahan, definisi, transkrip fonetik (IPA), contoh
  kalimat beserta artinya, sinonim, dan antonim.
• Audio pelafalan memakai mesin teks-ke-suara perangkat.

LATIHAN
• Flashcard: balik kartu, geser untuk menilai, kata yang salah muncul lagi.
• Quiz 6 mode: pilihan ganda, Inggris→Indonesia, Indonesia→Inggris, isi rumpang,
  listening, dan ejaan.
• Latihan adaptif: soal lebih sering menampilkan kata yang kamu sering salah.

PENGULANGAN BERJARAK (SM-2)
• Setiap jawaban memperbarui jadwal ulangan kata secara otomatis.
• Antrean review harian memprioritaskan kata yang paling terlambat dan paling
  sering salah.
• Target harian dan streak membantu menjaga kebiasaan.

PRIBADI DAN OFFLINE
• Sepenuhnya offline. Tidak perlu internet setelah dipasang.
• Tanpa iklan, tanpa pelacak, tanpa pendaftaran wajib.
• Boleh memakai mode tamu, atau membuat akun lokal (opsional) untuk memisahkan
  progres antar pengguna di perangkat yang sama.
• Statistik: aktivitas 7/30 hari, kalender streak, akurasi, kata tersulit.

Cocok untuk pelajar, mahasiswa, dan pekerja yang ingin meningkatkan bahasa Inggris
sedikit demi sedikit setiap hari.
```

## 3. Data safety (Play Console)

| Pertanyaan | Jawaban |
|---|---|
| Apakah aplikasi mengumpulkan data? | **Tidak** |
| Data dibagikan ke pihak ketiga? | Tidak |
| Data dienkripsi saat transit? | Tidak berlaku (tidak ada transmisi) |
| Pengguna bisa meminta hapus data? | Ya — lewat Profil → Hapus akun |
| Izin sensitif | Tidak ada (hanya notifikasi & TTS) |
| SDK iklan/analitik | Tidak ada |

## 4. Content rating

- Kategori kuesioner: **Education / Reference**
- Kekerasan, seksual, narkoba, perjudian, bahasa kasar: **Tidak**
- Konten buatan pengguna: **Tidak** (akun lokal, tanpa unggahan)
- Iklan: **Tidak**

## 5. Checklist sebelum submit

- [ ] Ganti `<alamat email kontak>` di `docs/PRIVASI.md` & layar Kebijakan Privasi
- [ ] Publikasikan kebijakan privasi di URL publik (mis. GitHub Pages) dan tempel di Play Console
- [ ] Feature graphic 1024×500
- [ ] 2–8 screenshot 1080×1920 (tanpa teks status bar yang menyesatkan)
- [ ] Isi "What's new" (ambil dari catatan rilis GitHub)
- [ ] Unggah **AAB** (`flutter build appbundle --release`), bukan APK
- [ ] Uji internal testing di minimal satu perangkat nyata
- [ ] Pastikan `targetSdk` memenuhi syarat Google Play saat submit
- [ ] Simpan keystore + `key.properties` (lihat `docs/RILIS.md`)

## 6. Catatan rilis

- v0.1.0 memakai debug key → pengguna harus uninstall.
- Mulai v0.1.1 memakai keystore rilis (`CN=Wordly`), sehingga pembaruan
  berikutnya harus ditandatangani dengan keystore yang sama.
