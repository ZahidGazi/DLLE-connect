import 'package:flutter/material.dart';

/// Breakpoints
/// Mobile  : width < 600
/// Tablet  : 600 <= width < 1200
/// Desktop : width >= 1200

class ResponsiveHelper {
  ResponsiveHelper._();

  // ── Breakpoint checks ──────────────────────────────────────────────────────
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= 600 && w < 1200;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  // ── Adaptive padding ───────────────────────────────────────────────────────
  static EdgeInsets padding(BuildContext context) {
    if (isDesktop(context)) return const EdgeInsets.all(32);
    if (isTablet(context)) return const EdgeInsets.all(24);
    return const EdgeInsets.all(16);
  }

  static EdgeInsets horizontalPadding(BuildContext context) {
    if (isDesktop(context)) return const EdgeInsets.symmetric(horizontal: 32);
    if (isTablet(context)) return const EdgeInsets.symmetric(horizontal: 24);
    return const EdgeInsets.symmetric(horizontal: 16);
  }

  // ── Grid columns ───────────────────────────────────────────────────────────
  /// For dashboard action cards (Coordinator dashboard)
  static int dashboardGridColumns(BuildContext context) {
    if (isDesktop(context)) return 4;
    if (isTablet(context)) return 3;
    return 2;
  }

  /// For list screens (events, announcements, students, courses, notifications)
  static int listGridColumns(BuildContext context) {
    if (isDesktop(context)) return 3;
    if (isTablet(context)) return 2;
    return 1;
  }

  // ── Max content width (for form / detail screens) ─────────────────────────
  static double maxFormWidth(BuildContext context) {
    if (isDesktop(context)) return 700;
    if (isTablet(context)) return 560;
    return double.infinity;
  }

  // ── Adaptive font sizes ────────────────────────────────────────────────────
  static double fontSize(BuildContext context, double base) {
    if (isDesktop(context)) return base * 1.25;
    if (isTablet(context)) return base * 1.1;
    return base;
  }

  // ── Adaptive icon sizes ────────────────────────────────────────────────────
  static double iconSize(BuildContext context, double base) {
    if (isDesktop(context)) return base * 1.3;
    if (isTablet(context)) return base * 1.15;
    return base;
  }

  // ── Adaptive image heights ─────────────────────────────────────────────────
  static double imageHeight(BuildContext context, double base) {
    if (isDesktop(context)) return base * 1.5;
    if (isTablet(context)) return base * 1.25;
    return base;
  }

  // ── Adaptive avatar radius ─────────────────────────────────────────────────
  static double avatarRadius(BuildContext context, double base) {
    if (isDesktop(context)) return base * 1.4;
    if (isTablet(context)) return base * 1.2;
    return base;
  }

  // ── Adaptive grid aspect ratio ─────────────────────────────────────────────
  static double gridAspectRatio(BuildContext context) {
    if (isDesktop(context)) return 1.1;
    if (isTablet(context)) return 1.05;
    return 1.0;
  }
}

/// A widget that centers its child and constrains it to [maxWidth].
/// Use this on form screens and detail screens so content does not
/// stretch across the full width of a tablet or desktop.
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final double effectiveMaxWidth =
        maxWidth ?? ResponsiveHelper.maxFormWidth(context);

    final Widget constrained = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
      child: padding != null
          ? Padding(padding: padding!, child: child)
          : child,
    );

    return Center(child: constrained);
  }
}
