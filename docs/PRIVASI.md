# Kebijakan Privasi — Wordly

Terakhir diperbarui: 19 November 2026

## Ringkasan

Wordly tetap **offline-first**: seluruh belajar berjalan di perangkat tanpa
perlu internet. Secara default, tidak ada data yang dikirim ke server.

Fitur **sinkronisasi opsional** hanya aktif bila pengguna **membuat akun**
(bukan tamu). Saat akun dibuat, aplikasi membuat akun di server Wordly Admin
milik pengelola aplikasi dan mengirim progres belajar agar bisa dipulihkan di
perangkat lain serta dilihat di panel admin. Mode tamu **tidak pernah**
mengirim data.

Tidak ada iklan, SDK analitik pihak ketiga, atau penjualan data.

## Data yang disimpan di perangkat

- Kosakata dan materi belajar (bawaan aplikasi, bisa diperbarui dari server).
- Progres belajar: kata yang dipelajari, favorit, jadwal ulangan, riwayat jawaban.
- Akun lokal (opsional): nama, email, dan kata sandi yang sudah di-hash.
- Pengaturan: tema, level, target harian, ukuran teks, pengingat harian.

## Data yang dikirim saat sinkronisasi (akun saja)

Saat pengguna memiliki akun, server menerima:

- Email, nama tampilan, dan kata sandi (dikirim sekali saat pembuatan akun
  server, lalu disimpan server sebagai hash bcrypt).
- Baris progres: status kata, jumlah pengulangan, jadwal ulang, jumlah benar/
  salah, riwayat jawaban, dan aktivitas harian.
- Versi konten terakhir yang tersimpan di perangkat.

Server **tidak** menerima lokasi, kontak, foto, atau rekaman suara. Proses
pelafalan tetap berjalan di perangkat.

## Kata sandi

- Kata sandi akun lokal di-hash memakai **PBKDF2-HMAC-SHA256** dengan salt acak.
- Kata sandi server di-hash memakai **bcrypt**.
- Token akses disimpan di preferensi perangkat dan bisa dicabut dengan keluar
  akun.

## Izin perangkat

| Izin | Fungsi |
|---|---|
| Notifikasi | Pengingat belajar harian yang diaktifkan pengguna |
| Teks-ke-suara (TTS) | Melafalkan kata memakai mesin TTS bawaan perangkat |
| Internet | Hanya untuk sinkronisasi akun; tidak dipakai saat belajar |
| Mikrofon | Hanya saat Latihan pelafalan; suara diproses di perangkat, tidak dikirim |

Aplikasi **tidak** meminta izin lokasi, kamera, atau kontak.

## Berbagi data

Data hanya dikirim ke server Wordly Admin yang digunakan pengelola aplikasi.
Data tidak dijual atau dibagikan kepada pihak ketiga. Gunakan HTTPS saat
menjalankan server di jaringan publik.

## Menyimpan & menghapus data

- Data lokal bertahan selama aplikasi terpasang.
- Profil → **Hapus akun** menghapus akun lokal beserta progresnya; token server
  juga dihapus dari perangkat.
- Menghapus aplikasi menghapus semua data lokal.

## Anak-anak

Aplikasi tidak menargetkan anak di bawah umur dan tidak mengumpulkan data pribadi
secara tersembunyi.

## Perubahan kebijakan

Versi terbaru akan disertakan pada pembaruan aplikasi dan tanggal di atas
diperbarui.

## Kontak

Pertanyaan tentang privasi: **<isi alamat email kontak kamu>**
