import 'package:flutter/material.dart';
import '../colors.dart';
import '../typography.dart';

/// Transparent app bar for use on gradient backgrounds
class SteplyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool lightText;
  final bool centerTitle;

  const SteplyAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.lightText = false,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final color = lightText ? Colors.white : SteplyColors.textDark;
    return AppBar(
      title: title != null
          ? Text(
              title!,
              style: SteplyTypography.headlineMedium.copyWith(color: color),
            )
          : null,
      centerTitle: centerTitle,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: color,
      leading: leading,
      actions: actions,
    );
  }
}
