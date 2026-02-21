import 'package:flutter/material.dart';
import '../colors.dart';
import '../spacing.dart';
import '../typography.dart';

class SteplyEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;
  final Color? iconColor;

  const SteplyEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.buttonLabel,
    this.onButtonPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? SteplyColors.greenDark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SteplySpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: SteplySpacing.lg),
            Text(
              title,
              style: SteplyTypography.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SteplySpacing.sm),
            Text(
              description,
              textAlign: TextAlign.center,
              style: SteplyTypography.bodyMedium.copyWith(
                color: SteplyColors.textMuted,
                height: 1.6,
              ),
            ),
            if (buttonLabel != null && onButtonPressed != null) ...[
              const SizedBox(height: SteplySpacing.lg),
              FilledButton.icon(
                onPressed: onButtonPressed,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(buttonLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
