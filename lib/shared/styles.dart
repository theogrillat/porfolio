import 'package:flutter/material.dart';
import 'package:portfolio/shared/utils.dart';

Color hex(String hexString) {
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

class Constants {
  // desktop
  static int desktopYCount = 4;
  static int desktopXCount = 7;
  // mobile
  static int mobileYCount = 7;
  static int mobileXCount = 4;
  // common
  static double edgeWidth = 4;
  static double mainPadding(BuildContext context) {
    double val = 10;
    if (Breakpoints(context).isWide()) val = 80;
    if (Breakpoints(context).isDesktop()) val = 50;
    if (Breakpoints(context).isTablet()) val = 30;
    if (Breakpoints(context).isMobile()) val = 10;
    return val;
  }

  static double sidebarWidth(BuildContext context) {
    if (isPortrait(context)) return 0;
    if (Breakpoints(context).isWide()) return 80;
    if (Breakpoints(context).isDesktop()) return 50;
    if (Breakpoints(context).isTablet()) return 20;
    if (Breakpoints(context).isMobile()) return 20;
    return 20;
  }

  static double sidebarHeight(BuildContext context) {
    if (isPortrait(context)) return 40;
    if (Breakpoints(context).isWide()) return 0;
    if (Breakpoints(context).isDesktop()) return 0;
    if (Breakpoints(context).isTablet()) return 0;
    if (Breakpoints(context).isMobile()) return 0;
    return 0;
  }

  static int yCount(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;
    if (h >= w * 1) {
      return mobileYCount;
    } else {
      return desktopYCount;
    }
  }

  static int xCount(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;
    if (h >= w * 1) {
      return mobileXCount;
    } else {
      return desktopXCount;
    }
  }
}

class Shades {
  static final mainColor = Color.fromRGBO(226, 245, 228, 1);
  static final darkText = Colors.black;
}

class FontSize {
  BuildContext context;
  double get baseSize {
    bool isWide = Breakpoints(context).isWide();
    bool isDesktop = Breakpoints(context).isDesktop();
    bool isTablet = Breakpoints(context).isTablet();
    bool isMobile = Breakpoints(context).isMobile();

    if (isWide) return 18.0;
    if (isDesktop) return 16.0;
    if (isTablet) return 14.0;
    if (isMobile) return 11.0;

    return 18.0;
  }

  double get nano => 0.6 * baseSize; // 9,6
  double get micro => 0.6875 * baseSize; // 11
  double get mini => 0.75 * baseSize; // 12
  double get small => 0.8125 * baseSize; // 13
  double get regular => 0.9375 * baseSize; // 15
  double get large => 1.125 * baseSize; // 18
  double get title1 => 2.25 * baseSize; // 36
  double get title2 => 1.5 * baseSize; // 24
  double get title3 => 1.25 * baseSize; // 20

  FontSize(this.context);
}

class Typos {
  BuildContext context;

  Typos(this.context);

  TextStyle regular({
    Color? color,
    FontWeight? fontWeight,
    double? height,
  }) {
    return TextStyle(
      fontSize: FontSize(context).regular,
      fontWeight: fontWeight ?? FontWeight.w700,
      fontFamily: 'GoshaSans',
      color: color ?? Shades.darkText,
      height: height,
    );
  }

  TextStyle large({
    Color? color,
    FontWeight? fontWeight,
    double? height,
  }) {
    return TextStyle(
      fontSize: FontSize(context).large,
      fontWeight: fontWeight ?? FontWeight.w700,
      fontFamily: 'GoshaSans',
      color: color ?? Shades.darkText,
      height: height,
    );
  }

  TextStyle tag({
    Color? color,
    FontWeight? fontWeight,
    double? height,
  }) {
    bool isWide = Breakpoints(context).isWide();
    bool isDesktop = Breakpoints(context).isDesktop();
    bool isTablet = Breakpoints(context).isTablet();
    bool isMobile = Breakpoints(context).isMobile();

    double fontSize = FontSize(context).regular;

    if (isWide) fontSize = FontSize(context).small;
    if (isDesktop) fontSize = FontSize(context).mini;
    if (isTablet) fontSize = FontSize(context).micro;
    if (isMobile) fontSize = FontSize(context).nano;

    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w700,
      fontFamily: 'ibmPlexMono',
      color: color ?? Shades.darkText,
      height: height,
    );
  }
}
