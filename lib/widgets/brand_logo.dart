import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BrandLogo extends StatelessWidget {
  final double size;
  final bool showTitle;
  final bool titleOnDarkBackground;
  final MainAxisAlignment alignment;

  const BrandLogo({
    super.key,
    this.size = 72,
    this.showTitle = true,
    this.titleOnDarkBackground = false,
    this.alignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = titleOnDarkBackground ? Colors.white : AppColors.textPrimary;
    final subtitleColor = titleOnDarkBackground ? Colors.white70 : AppColors.textSecondary;

    return Column(
      mainAxisAlignment: alignment,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.22),
          child: Image.asset(
            'assets/app_icon.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
        if (showTitle) ...[
          SizedBox(height: size * 0.22),
          Text(
            'BANCO PICHINCHA',
            style: TextStyle(
              color: titleColor,
              fontSize: size * 0.28,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'PERÚ',
            style: TextStyle(
              color: subtitleColor,
              fontSize: size * 0.16,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
        ],
      ],
    );
  }
}

class BrandMark extends StatelessWidget {
  final double size;

  const BrandMark({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.2),
      child: Image.asset(
        'assets/app_icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
