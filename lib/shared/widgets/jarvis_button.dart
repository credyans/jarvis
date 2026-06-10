import 'package:flutter/material.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_spacing.dart';
import 'package:jarvis/core/theme/app_typography.dart';

class JarvisButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final bool isOutline;
  final IconData? icon;

  const JarvisButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.isOutline = false,
    this.icon,
  });

  @override
  State<JarvisButton> createState() => _JarvisButtonState();
}

class _JarvisButtonState extends State<JarvisButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 20.0,
            height: 20.0,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.isOutline ? AppColors.primary : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8.0),
        ] else if (widget.icon != null) ...[
          Icon(
            widget.icon,
            size: 20.0,
            color: widget.isOutline ? AppColors.primary : Colors.white,
          ),
          const SizedBox(width: 8.0),
        ],
        Text(
          widget.text,
          style: AppTypography.bodyMedium(
            color: widget.isOutline
                ? AppColors.primary
                : (widget.onPressed == null ? AppColors.textTertiary : Colors.white),
          ),
        ),
      ],
    );

    Widget innerButton = Container(
      height: 52.0,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: widget.isOutline
            ? Colors.transparent
            : (widget.onPressed == null ? AppColors.border : AppColors.primaryButton),
        borderRadius: AppSpacing.buttonRadius,
        border: widget.isOutline
            ? Border.all(color: AppColors.primary, width: 2.0)
            : null,
      ),
      child: buttonContent,
    );

    if (widget.isFullWidth) {
      innerButton = SizedBox(width: double.infinity, child: innerButton);
    } else {
      innerButton = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: innerButton,
      );
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.isLoading ? null : widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: innerButton,
      ),
    );
  }
}
