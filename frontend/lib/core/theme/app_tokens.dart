import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 10;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double page = 20;
}

abstract final class AppRadii {
  static const double icon = 12;
  static const double control = 14;
  static const double card = 16;
  static const double panel = 20;
  static const double profile = 24;
  static const double pill = 99;

  static BorderRadius get iconBorder =>
      BorderRadius.circular(AppRadii.icon);
  static BorderRadius get controlBorder =>
      BorderRadius.circular(AppRadii.control);
  static BorderRadius get cardBorder =>
      BorderRadius.circular(AppRadii.card);
  static BorderRadius get panelBorder =>
      BorderRadius.circular(AppRadii.panel);
  static BorderRadius get pillBorder =>
      BorderRadius.circular(AppRadii.pill);
}

abstract final class AppShadows {
  static const List<BoxShadow> control = [
    BoxShadow(
      color: Color(0x1A3B5970),
      blurRadius: 6,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x1A3B5970),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}

abstract final class AppDurations {
  static const Duration quick = Duration(milliseconds: 120);
  static const Duration navigation = Duration(milliseconds: 200);
}
