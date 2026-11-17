/// Format tanggal Indonesia tanpa dependency tambahan.
abstract final class DateId {
  static const List<String> _days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  /// Contoh: "Selasa, 17 November".
  static String longDate(DateTime date) {
    final day = _days[(date.weekday - 1) % 7];
    final month = _months[date.month - 1];
    return '$day, ${date.day} $month';
  }

  /// Sapaan sesuai jam perangkat.
  static String greeting(DateTime now) {
    final hour = now.hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 19) return 'Selamat sore';
    return 'Selamat malam';
  }

  static const List<String> _shortDays = [
    'Sn',
    'Sl',
    'Rb',
    'Km',
    'Jm',
    'Sb',
    'Mg',
  ];

  /// Singkatan dua huruf untuk label grafik: "Sn", "Sl", "Rb", ...
  static String shortDay(DateTime date) => _shortDays[(date.weekday - 1) % 7];
}
