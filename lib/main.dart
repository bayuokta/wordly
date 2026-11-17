import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const WordlySmokeTest());
}

/// Layar uji setup: memastikan tema gelap, tiga keluarga font, dan simbol IPA
/// benar-benar ter-render di perangkat. Akan diganti oleh UI asli Wordly.
class WordlySmokeTest extends StatelessWidget {
  const WordlySmokeTest({super.key});

  static const Color bg = Color(0xFF0E1116);
  static const Color surface = Color(0xFF171B22);
  static const Color border = Color(0xFF2A3040);
  static const Color primary = Color(0xFF7C9CFF);
  static const Color accent = Color(0xFFF2C46D);
  static const Color text = Color(0xFFF2F4F8);
  static const Color muted = Color(0xFF9AA3B5);
  static const Color ipa = Color(0xFFAEB8CC);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wordly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        fontFamily: 'Inter',
      ),
      home: const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 24),
                _BrandRow(),
                Spacer(),
                _WordCard(),
                Spacer(),
                _Footer(),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF93ACFF), Color(0xFF7C9CFF), Color(0xFF5F7FE6)],
            ),
          ),
          alignment: Alignment.center,
          child: const Text(
            'W',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0B1020),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wordly',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: WordlySmokeTest.text,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'English · Indonesia',
              style: TextStyle(fontSize: 11.5, color: WordlySmokeTest.muted),
            ),
          ],
        ),
      ],
    );
  }
}

class _WordCard extends StatelessWidget {
  const _WordCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WordlySmokeTest.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: WordlySmokeTest.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'SETUP BERHASIL',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.9,
              color: Color(0xFF7E89A0),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'resilient',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 40,
              height: 1.1,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.2,
              color: WordlySmokeTest.text,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            '/rɪˈzɪl.i.ənt/',
            style: TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 14,
              color: WordlySmokeTest.ipa,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'tangguh; cepat pulih dari kesulitan',
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: Color(0xFFD9DFEC),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'She is resilient and never gives up easily.',
            style: TextStyle(fontSize: 13, height: 1.5, color: WordlySmokeTest.muted),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _chip('adjective', WordlySmokeTest.primary, const Color(0x227C9CFF)),
              const SizedBox(width: 6),
              _chip('C1', WordlySmokeTest.accent, const Color(0x22F2C46D)),
              const SizedBox(width: 6),
              _chip('Advanced', WordlySmokeTest.muted, const Color(0xFF1F2430)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color, Color background) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Font: Plus Jakarta Sans · Inter · Noto Sans',
          style: TextStyle(fontSize: 11.5, color: WordlySmokeTest.muted),
        ),
        SizedBox(height: 4),
        Text(
          'Flutter 3.50.0 · Android API 36 · applicationId id.wordly.app',
          style: TextStyle(fontSize: 11.5, height: 1.45, color: Color(0xFF6C778E)),
        ),
      ],
    );
  }
}
