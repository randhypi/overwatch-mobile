import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

final appTheme = ThemeData(
  scaffoldBackgroundColor: AppColors.background,
  primaryColor: AppColors.primary,
  useMaterial3: true,
  brightness: Brightness.dark,
  fontFamily: GoogleFonts.inter().fontFamily,
  
  textTheme: TextTheme(
    bodyMedium: TextStyle(color: AppColors.primaryText),
    bodySmall: TextStyle(color: AppColors.secondaryText),
  ),
  
  cardTheme: CardTheme(
    color: AppColors.cardBg,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
      side: BorderSide(color: AppColors.divider, width: 0.5),
    ),
  ),
  
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.headerBg,
    elevation: 0,
    titleTextStyle: GoogleFonts.inter(
      color: AppColors.primaryText,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
  ),
);
