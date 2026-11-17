import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_palette.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/widgets/app_card.dart';

/// Kebijakan privasi singkat (offline, tanpa pengumpulan data).
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  static const List<(String, String)> _sections = [
    (
      'Ringkasan',
      'Wordly berjalan sepenuhnya di perangkatmu. Aplikasi tidak mengirim data ke server mana pun, '
          'tidak meminta akun daring, dan tidak memuat iklan atau pelacak.',
    ),
    (
      'Data yang disimpan di perangkat',
      '• Kosakata dan materi belajar (bawaan aplikasi).\n'
          '• Progres belajar: kata yang dipelajari, favorit, jadwal ulangan, riwayat jawaban.\n'
          '• Akun lokal (opsional): nama, email, dan kata sandi yang sudah di-hash.\n'
          '• Pengaturan: tema, level, target harian, ukuran teks, pengingat harian.\n'
          'Semua data ini tersimpan pada basis data lokal aplikasi dan tidak pernah diunggah.',
    ),
    (
      'Kata sandi',
      'Kata sandi akun lokal di-hash memakai PBKDF2-HMAC-SHA256 dengan salt acak. '
          'Kata sandi asli tidak disimpan dan tidak dapat dibaca oleh siapa pun, termasuk pembuat aplikasi.',
    ),
    (
      'Izin perangkat',
      '• Notifikasi: hanya untuk pengingat belajar harian yang kamu aktifkan sendiri.\n'
          '• Teks-ke-suara (TTS): memakai mesin TTS bawaan perangkat untuk melafalkan kata.\n'
          '• Mikrofon: hanya dipakai saat kamu memulai Latihan pelafalan. Suara diproses oleh '
          'layanan pengenalan suara perangkat dan tidak direkam atau dikirim oleh aplikasi.\n'
          'Aplikasi tidak meminta izin lokasi, kamera, atau kontak.',
    ),
    (
      'Berbagi data',
      'Tidak ada data yang dibagikan atau dijual kepada pihak ketiga. Aplikasi tidak menyertakan SDK iklan '
          'maupun analitik pihak ketiga.',
    ),
    (
      'Menghapus data',
      'Kamu dapat menghapus akun beserta seluruh progresnya dari Profil → Hapus akun. '
          'Menghapus aplikasi dari perangkat juga menghapus semua data yang tersimpan.',
    ),
    (
      'Anak-anak',
      'Aplikasi tidak mengumpulkan data pribadi siapa pun. Konten kosakata ditujukan untuk pelajar '
          'dan pengguna umum.',
    ),
    (
      'Perubahan kebijakan',
      'Jika kebijakan ini berubah (misalnya saat fitur sinkronisasi daring ditambahkan), '
          'versi terbaru akan disertakan pada pembaruan aplikasi.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    color: p.iconSoft,
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      'Kebijakan privasi',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  10,
                  AppSpacing.page,
                  AppSpacing.xl,
                ),
                children: [
                  Text('Terakhir diperbarui: 17 November 2026', style: context.tiny),
                  const SizedBox(height: 12),
                  for (final (title, body) in _sections) ...[
                    AppCard(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: p.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            body,
                            style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 12.5,
                              height: 1.6,
                              color: p.textSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
