import 'package:flutter/material.dart';

class AppRadius {
  const AppRadius._();

  static const double xs = 6;
  static const double sm = 10;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double pill = 999;

  static BorderRadius get input => BorderRadius.circular(md);
  static BorderRadius get button => BorderRadius.circular(md);
  static BorderRadius get card => BorderRadius.circular(lg);
  static BorderRadius get heroCard => BorderRadius.circular(xl);
  static BorderRadius get dialog => BorderRadius.circular(xl);
  static BorderRadius get pillShape => BorderRadius.circular(pill);
}
