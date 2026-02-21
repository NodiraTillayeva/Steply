import 'package:flutter/material.dart';
import '../colors.dart';
import '../spacing.dart';
import '../typography.dart';

class PlaceCard extends StatelessWidget {
  final String name;
  final String description;
  final String? imageUrl;
  final String? dateText;
  final List<PlaceCardAction>? actions;
  final VoidCallback? onTap;
  final Widget? trailing;

  const PlaceCard({
    super.key,
    required this.name,
    required this.description,
    this.imageUrl,
    this.dateText,
    this.actions,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            if (imageUrl != null && imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(SteplyRadius.xl),
                ),
                child: Image.network(
                  imageUrl!,
                  width: double.infinity,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(SteplySpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (imageUrl == null || imageUrl!.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(Icons.place,
                              size: 18, color: SteplyColors.orangePrimary),
                        ),
                      Expanded(
                        child: Text(name, style: SteplyTypography.titleMedium),
                      ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SteplyTypography.bodySmall.copyWith(
                      color: SteplyColors.textMuted,
                    ),
                  ),
                  if (dateText != null) ...[
                    const SizedBox(height: SteplySpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: SteplyColors.orangePrimary.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(SteplyRadius.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.event,
                              size: 13, color: SteplyColors.orangeMedium),
                          const SizedBox(width: 4),
                          Text(
                            dateText!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: SteplyColors.orangeMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (actions != null && actions!.isNotEmpty) ...[
                    const SizedBox(height: SteplySpacing.sm + 4),
                    Row(
                      children: actions!
                          .map((a) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _PlaceActionChip(action: a),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceCardAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const PlaceCardAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _PlaceActionChip extends StatelessWidget {
  final PlaceCardAction action;

  const _PlaceActionChip({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: SteplyColors.greenDark.withOpacity(0.06),
          borderRadius: BorderRadius.circular(SteplyRadius.full),
          border: Border.all(
            color: SteplyColors.greenDark.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(action.icon, size: 14, color: SteplyColors.greenDark),
            const SizedBox(width: 4),
            Text(
              action.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: SteplyColors.greenDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
