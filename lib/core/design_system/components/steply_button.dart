import 'package:flutter/material.dart';
import '../colors.dart';
import '../gradients.dart';
import '../spacing.dart';

enum SteplyButtonVariant { primary, accent, outline, ghost }

class SteplyButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final SteplyButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  const SteplyButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = SteplyButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    return GestureDetector(
      onTap: isDisabled ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(
          horizontal: SteplySpacing.lg,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          gradient: _gradient(isDisabled),
          color: _backgroundColor(isDisabled),
          borderRadius: BorderRadius.circular(SteplyRadius.md),
          border: variant == SteplyButtonVariant.outline
              ? Border.all(color: SteplyColors.greenDark.withOpacity(0.3))
              : null,
        ),
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _foregroundColor,
                ),
              ),
              const SizedBox(width: SteplySpacing.sm),
            ] else if (icon != null) ...[
              Icon(icon, size: 18, color: _foregroundColor),
              const SizedBox(width: SteplySpacing.sm),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _foregroundColor,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient? _gradient(bool isDisabled) {
    if (isDisabled) return null;
    switch (variant) {
      case SteplyButtonVariant.primary:
        return SteplyGradients.greenButton;
      case SteplyButtonVariant.accent:
        return SteplyGradients.accent;
      default:
        return null;
    }
  }

  Color? _backgroundColor(bool isDisabled) {
    if (variant == SteplyButtonVariant.primary ||
        variant == SteplyButtonVariant.accent) {
      return isDisabled ? SteplyColors.divider : null;
    }
    if (variant == SteplyButtonVariant.outline) return Colors.transparent;
    return Colors.transparent; // ghost
  }

  Color get _foregroundColor {
    switch (variant) {
      case SteplyButtonVariant.primary:
      case SteplyButtonVariant.accent:
        return Colors.white;
      case SteplyButtonVariant.outline:
      case SteplyButtonVariant.ghost:
        return SteplyColors.greenDark;
    }
  }
}
