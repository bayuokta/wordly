# Kebijakan Privasi — Wordly

Terakhir diperbarui: 17 November 2026

## Ringkasan

Wordly berjalan sepenuhnya di perangkat. Aplikasi **tidak mengumpulkan, mengirim,
atau menjual data pribadi** ke server mana pun. Tidak ada akun daring, iklan,
maupun SDK analitik pihak ketiga.

## Data yang disimpan di perangkat

- Kosakata dan materi belajar (bawaan aplikasi).
- Progres belajar: kata yang dipelajari, favorit, jadwal ulangan, riwayat jawaban.
- Akun lokal (opsional): nama, email, dan kata sandi yang sudah di-hash.
- Pengaturan: tema, level, target harian, ukuran teks, pengingat harian.

Semua data tersimpan pada basis data lokal aplikasi (`user.db`) dan tidak pernah
diunggah.

## Kata sandi

Kata sandi akun lokal di-hash memakai **PBKDF2-HMAC-SHA256** dengan salt acak.
Kata sandi asli tidak disimpan dan tidak dapat dibaca oleh siapa pun, termasuk
pembuat aplikasi.

## Izin perangkat

| Izin | Fungsi |
|---|---|
| Notifikasi | Pengingat belajar harian yang diaktifkan pengguna |
| Teks-ke-suara (TTS) | Melafalkan kata memakai mesin TTS bawaan perangkat |
| Mikrofon | Hanya saat Latihan pelafalan; suara diproses layanan pengenalan suara perangkat, tidak direkam/dikirim aplikasi |

Aplikasi **tidak** meminta izin lokasi, kamera, atau kontak.

## Berbagi data

Tidak ada data yang dibagikan atau dijual kepada pihak ketiga.

## Menyimpan & menghapus data

- Data bertahan selama aplikasi terpasang.
- Profil → **Hapus akun** menghapus akun beserta seluruh progresnya.
- Menghapus aplikasi menghapus semua data lokal.

## Anak-anak

Aplikasi tidak mengumpulkan data pribadi siapa pun. Konten ditujukan untuk
pelajar dan pengguna umum.

## Perubahan kebijakan

Jika kebijakan berubah (misalnya saat fitur sinkronisasi daring ditambahkan),
versi terbaru akan disertakan pada pembaruan aplikasi dan tanggal di atas
diperbarui.

## Kontak

Pertanyaan tentang privasi: **<isi alamat email kontak kamu>**
