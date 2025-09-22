import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Color hex(String hexString) {
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

class Constants {
  static double edgeWidth = 4;
  static int yCount = 4;
  static int xCount = 7;
  static double mainPadding = 80;
}

class Shades {
  static final mainColor = Color.fromRGBO(226, 245, 228, 1);
  static final darkText = Colors.black;
}

class FontSize {
  final double _baseSize = 18;
  double get nano => 0.6 * _baseSize; // 9,6
  double get micro => 0.6875 * _baseSize; // 11
  double get mini => 0.75 * _baseSize; // 12
  double get small => 0.8125 * _baseSize; // 13
  double get regular => 0.9375 * _baseSize; // 15
  double get large => 1.125 * _baseSize; // 18
  double get title1 => 2.25 * _baseSize; // 36
  double get title2 => 1.5 * _baseSize; // 24
  double get title3 => 1.25 * _baseSize; // 20
}

class Typos {
  TextStyle regular({
    Color? color,
    FontWeight? fontWeight,
    double? height,
  }) {
    return TextStyle(
      fontSize: FontSize().regular,
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
      fontSize: FontSize().large,
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
    return TextStyle(
      fontSize: FontSize().large,
      fontWeight: fontWeight ?? FontWeight.w700,
      fontFamily: 'ibmPlexMono',
      color: color ?? Shades.darkText,
      height: height,
    );
  }
}
