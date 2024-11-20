import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryOrange = Color(0xFFFF914D);
  static const Color secondaryRed = Color(0xFFFF3131);
  
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryOrange, secondaryRed],
  );
} 