import 'package:flutter/material.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_spacing.dart';
import 'package:jarvis/core/theme/app_typography.dart';

class ToastNotification {
  static void show(
    BuildContext context,
    String message, {
    String type = 'success', // success, error, info
    VoidCallback? onUndo,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        type: type,
        onUndo: onUndo,
        duration: onUndo != null ? const Duration(seconds: 7) : duration,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlayState.insert(overlayEntry);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final String type;
  final VoidCallback? onUndo;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.type,
    this.onUndo,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Auto dismiss after custom duration
    Future.delayed(widget.duration, () async {
      _dismiss();
    });
  }

  void _dismiss() async {
    if (_isDismissed) return;
    _isDismissed = true;
    if (mounted) {
      await _controller.reverse();
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case 'error':
        return AppColors.errorLight;
      case 'warning':
        return AppColors.warningLight;
      case 'info':
        return AppColors.secondaryLight;
      case 'success':
      default:
        return AppColors.successLight;
    }
  }

  Color _getBorderColor() {
    switch (widget.type) {
      case 'error':
        return AppColors.error.withOpacity(0.3);
      case 'warning':
        return AppColors.warning.withOpacity(0.3);
      case 'info':
        return AppColors.secondary.withOpacity(0.3);
      case 'success':
      default:
        return AppColors.success.withOpacity(0.3);
    }
  }

  String _getEmoji() {
    switch (widget.type) {
      case 'error':
        return '🚨';
      case 'warning':
        return '⚠️';
      case 'info':
        return '✨';
      case 'success':
      default:
        return '✅';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0, left: 20.0, right: 20.0),
          child: SlideTransition(
            position: _offsetAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: _getBackgroundColor(),
                    borderRadius: AppSpacing.buttonRadius,
                    border: Border.all(color: _getBorderColor(), width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getEmoji(),
                        style: const TextStyle(fontSize: 16.0),
                      ),
                      const SizedBox(width: 10.0),
                      Flexible(
                        child: Text(
                          widget.message,
                          style: AppTypography.caption(color: AppColors.textPrimary).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (widget.onUndo != null) ...[
                        const SizedBox(width: 12.0),
                        GestureDetector(
                          onTap: () {
                            widget.onUndo!();
                            _dismiss();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            child: Text(
                              'UNDO',
                              style: AppTypography.micro(color: Colors.white).copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 14.0),
                      GestureDetector(
                        onTap: _dismiss,
                        child: Icon(
                          Icons.close_rounded,
                          size: 20.0,
                          color: AppColors.textSecondary.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
