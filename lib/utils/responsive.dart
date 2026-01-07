import 'package:flutter/material.dart';

class Responsive {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;

  static double getWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double getHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  // Responsive values
  static T valueWhen<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  // Responsive padding
  static EdgeInsets paddingWhen(
    BuildContext context, {
    EdgeInsets mobile = const EdgeInsets.all(16),
    EdgeInsets? tablet,
    EdgeInsets? desktop,
  }) {
    return valueWhen(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  // Responsive font size
  static double fontSizeWhen(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return valueWhen(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  // Responsive columns for GridView
  static int columnsWhen(
    BuildContext context, {
    int mobile = 1,
    int? tablet,
    int? desktop,
  }) {
    return valueWhen(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  // Responsive cross axis count for grids
  static int crossAxisCountWhen(
    BuildContext context, {
    int mobile = 2,
    int? tablet,
    int? desktop,
  }) {
    return valueWhen(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  // Get appropriate sidebar width
  static double getSidebarWidth(BuildContext context) {
    return valueWhen(
      context,
      mobile: 0, // No sidebar on mobile
      tablet: 250,
      desktop: 300,
    );
  }

  // Get appropriate content max width
  static double getContentMaxWidth(BuildContext context) {
    return valueWhen(
      context,
      mobile: double.infinity,
      tablet: 800,
      desktop: 1200,
    );
  }
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, bool isMobile, bool isTablet, bool isDesktop) builder;

  const ResponsiveBuilder({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return builder(
      context,
      Responsive.isMobile(context),
      Responsive.isTablet(context),
      Responsive.isDesktop(context),
    );
  }
}

class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveWidget({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, isMobile, isTablet, isDesktop) {
        if (isDesktop) return desktop ?? tablet ?? mobile;
        if (isTablet) return tablet ?? mobile;
        return mobile;
      },
    );
  }
}

// Card variants for different screen sizes
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? elevation;
  final Color? color;
  final BorderRadius? borderRadius;

  const ResponsiveCard({
    Key? key,
    required this.child,
    this.padding,
    this.elevation,
    this.color,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsivePadding = Responsive.paddingWhen(
      context,
      mobile: const EdgeInsets.all(16),
      tablet: const EdgeInsets.all(20),
      desktop: const EdgeInsets.all(24),
    );

    final responsiveElevation = Responsive.valueWhen(
      context,
      mobile: 2.0,
      tablet: 3.0,
      desktop: 4.0,
    );

    return Card(
      elevation: elevation ?? responsiveElevation,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
      ),
      child: Padding(
        padding: padding ?? responsivePadding,
        child: child,
      ),
    );
  }
}

// Grid layout that adapts to screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets padding;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double? childAspectRatio;

  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.padding = const EdgeInsets.all(16),
    this.mainAxisSpacing = 16,
    this.crossAxisSpacing = 16,
    this.childAspectRatio,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = Responsive.crossAxisCountWhen(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );

    final double aspectRatio = childAspectRatio ?? 
        Responsive.valueWhen(
          context,
          mobile: 1.2,
          tablet: 1.1,
          desktop: 1.0,
        );

    return GridView.count(
      padding: padding,
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      childAspectRatio: aspectRatio,
      children: children,
    );
  }
}
