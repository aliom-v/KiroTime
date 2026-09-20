import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'kiro_theme.dart';

export 'kiro_theme.dart';

/// 浅色"液态玻璃"面板：毛玻璃模糊 + 渐变高光 + 柔和描边与阴影。
///
/// 通过 BackdropFilter 模糊背后内容，再用一层通透的白色渐变叠加，
/// 模拟 iOS 26 Liquid Glass 的层次感。可直接单独使用，也可作为卡片/操作条底座。
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.blur = 18,
    this.fillOpacity = 0.55,
    this.borderColor = KiroPalette.glassBorder,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final double fillOpacity;
  final Color borderColor;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  KiroPalette.glassFillTop.withValues(
                    alpha: fillOpacity,
                  ),
                  KiroPalette.glassFillBottom.withValues(
                    alpha: fillOpacity * 0.82,
                  ),
                ],
              ),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: shadow ? KiroPalette.softShadow : null,
            ),
            child: Padding(
              padding: padding ?? EdgeInsets.zero,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// 玻璃圆形操作按钮（用于顶栏：新增/设置/导入）。
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 42,
    this.iconColor = KiroPalette.primary,
    this.filled = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final Color iconColor;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final button = ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: filled
              ? KiroPalette.primary.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.45),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                icon,
                size: size * 0.5,
                color: onPressed == null
                    ? KiroPalette.textTertiary
                    : iconColor,
              ),
            ),
          ),
        ),
      ),
    );
    return Tooltip(message: tooltip, child: button);
  }
}

/// 玻璃"胶囊"按钮（用于横向排列的操作用，例如导入页的地址）。
class GlassChipButton extends StatelessWidget {
  const GlassChipButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.selected = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: selected
              ? KiroPalette.primary.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.42),
          shape: StadiumBorder(
            side: BorderSide(
              color: selected
                  ? KiroPalette.primary.withValues(alpha: 0.55)
                  : KiroPalette.glassBorder,
            ),
          ),
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(
                      icon,
                      size: 16,
                      color: selected
                          ? KiroPalette.primary
                          : KiroPalette.textSecondary,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? KiroPalette.primary
                          : KiroPalette.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 整页浅色渐变背景，放在最底层供玻璃面板模糊。
class KiroCanvas extends StatelessWidget {
  const KiroCanvas({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: KiroPalette.canvasGradient,
        ),
      ),
      child: child,
    );
  }
}
