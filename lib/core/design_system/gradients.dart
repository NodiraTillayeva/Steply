import 'package:flutter/material.dart';
import 'colors.dart';

/// Steply brand gradients
class SteplyGradients {
  SteplyGradients._();

  // Main background gradient (vertical)
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [SteplyColors.greenDark, SteplyColors.greenMedium, SteplyColors.greenLight],
    stops: [0.0, 0.5, 1.0],
  );

  // Button/accent gradient
  static const LinearGradient accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [SteplyColors.orangeLight, SteplyColors.orangePrimary, SteplyColors.orangeMedium],
  );

  // Card surface gradient (subtle)
  static const LinearGradient card = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [SteplyColors.cloudWhite, Color(0xFFF5F3EE)],
  );

  // Green button gradient
  static const LinearGradient greenButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [SteplyColors.greenMedium, SteplyColors.greenDark],
  );

  // Warm overlay gradient (for map overlays, etc.)
  static const LinearGradient warmOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0x33557B30)],
  );
}
