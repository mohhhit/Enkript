import 'package:flutter/material.dart';
import '../utils/platform_utils.dart';

/// A responsive container that adapts layout based on platform
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ?? (PlatformUtils.isDesktop ? 500.0 : double.infinity);
    final effectivePadding = padding ?? EdgeInsets.all(PlatformUtils.defaultPadding);

    if (PlatformUtils.isDesktop) {
      // Desktop: Center content with max width
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
          child: Padding(
            padding: effectivePadding,
            child: child,
          ),
        ),
      );
    }

    // Mobile: Full width with padding
    return Padding(
      padding: effectivePadding,
      child: child,
    );
  }
}

/// A card that adapts its style based on platform
class PlatformCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const PlatformCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: PlatformUtils.isDesktop ? 2 : 1,
      margin: EdgeInsets.only(bottom: PlatformUtils.isDesktop ? 12 : 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding ?? EdgeInsets.all(PlatformUtils.isDesktop ? 16 : 12),
          child: child,
        ),
      ),
    );

    return card;
  }
}
