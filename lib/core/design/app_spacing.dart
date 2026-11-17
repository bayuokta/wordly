import 'package:material_ui/material_ui.dart';

/// Spacing & radius Wordly (kelipatan 4, sesuai design system).
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Padding horizontal halaman.
  static const double page = 20;

  /// Jarak antar card.
  static const double cardGap = 12;
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double hero = 24;
  static const double flashcard = 26;
  static const double pill = 999;

  static BorderRadius get brSm => BorderRadius.circular(sm);
  static BorderRadius get brMd => BorderRadius.circular(md);
  static BorderRadius get brLg => BorderRadius.circular(lg);
  static BorderRadius get brXl => BorderRadius.circular(xl);
  static BorderRadius get brHero => BorderRadius.circular(hero);
  static BorderRadius get brPill => BorderRadius.circular(pill);
}

/// Durasi animasi (design system: 180–320 ms, easeOutCubic).
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 320);
  static const Duration cardFlip = Duration(milliseconds: 350);

  static const Curve curve = Curves.easeOutCubic;
}
