import 'package:flutter/material.dart';
import '../colors.dart';
import '../spacing.dart';
import '../typography.dart';

class InsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? child;
  final Color? accentColor;
  final VoidCallback? onTap;

  const InsightCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.child,
    this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? SteplyColors.greenDark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(SteplySpacing.md),
        decoration: BoxDecoration(
          color: SteplyColors.cloudWhite,
          borderRadius: BorderRadius.circular(SteplyRadius.xl),
          border: Border.all(color: SteplyColors.divider.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(SteplyRadius.sm),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: SteplySpacing.sm + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: SteplyTypography.titleMedium),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: SteplyTypography.bodySmall.copyWith(
                            color: SteplyColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: SteplyColors.textLight,
                  ),
              ],
            ),
            if (child != null) ...[
              const SizedBox(height: SteplySpacing.sm + 4),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}
