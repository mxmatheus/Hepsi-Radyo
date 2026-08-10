import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'app_colors.dart';

class PaletteHelper {
  static Future<Color> extractDominantColor(String? imageUrl, {bool isDark = true}) async {
    if (imageUrl == null || imageUrl.isEmpty) {
      return isDark ? AppColors.racingGreenPrimary : AppColors.lightCard;
    }

    try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
        maximumColorCount: 12,
      );

      final color = paletteGenerator.dominantColor?.color ??
          paletteGenerator.vibrantColor?.color ??
          paletteGenerator.mutedColor?.color ??
          AppColors.racingGreenPrimary;

      // Blend with base brand identity
      return Color.alphaBlend(
        color.withOpacity(0.45),
        isDark ? AppColors.racingGreenDeepest : AppColors.lightCard,
      );
    } catch (_) {
      return isDark ? AppColors.racingGreenPrimary : AppColors.lightCard;
    }
  }
}
