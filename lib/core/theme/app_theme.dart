import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      textTheme: GoogleFonts.notoSansTextTheme(
        Typography.material2021().black,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      textTheme: GoogleFonts.notoSansTextTheme(
        Typography.material2021().white,
      ),
    );
  }
}
