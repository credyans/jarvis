import 'package:flutter/material.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_spacing.dart';
import 'package:jarvis/core/theme/app_typography.dart';

class JarvisInput extends StatefulWidget {
  final String? label;
  final String hintText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool isPassword;
  final Widget? prefix;
  final Widget? suffix;
  final String? errorText;
  final String? helperText;
  final bool isSuccess;
  final bool isLoading;
  final int? maxLength;
  final bool showCharacterCount;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;

  const JarvisInput({
    super.key,
    this.label,
    required this.hintText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.prefix,
    this.suffix,
    this.errorText,
    this.helperText,
    this.isSuccess = false,
    this.isLoading = false,
    this.maxLength,
    this.showCharacterCount = false,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
  });

  @override
  State<JarvisInput> createState() => _JarvisInputState();
}

class _JarvisInputState extends State<JarvisInput> {
  late bool _obscureText;
  FocusNode? _localFocusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? (_localFocusNode ??= FocusNode());
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _effectiveFocusNode.addListener(_handleFocusChange);
    });
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChange);
    _localFocusNode?.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _effectiveFocusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    // Define border side colors based on state
    Color borderSideColor = Colors.white.withOpacity(0.08);
    double borderWidth = 1.0;
    if (hasError) {
      borderSideColor = AppColors.error;
    } else if (widget.isSuccess) {
      borderSideColor = AppColors.success;
    } else if (_isFocused) {
      borderSideColor = AppColors.primary;
      borderWidth = 1.5;
    }

    Widget? suffixWidget;
    if (widget.isLoading) {
      suffixWidget = const SizedBox(
        width: 20,
        height: 20,
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    } else if (widget.isPassword) {
      suffixWidget = IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.textSecondary,
          size: 20,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    } else if (widget.isSuccess) {
      suffixWidget = const Icon(
        Icons.check_circle_outline,
        color: AppColors.success,
        size: 20,
      );
    } else {
      suffixWidget = widget.suffix;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label!,
                style: AppTypography.caption(color: AppColors.textSecondary).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.showCharacterCount && widget.maxLength != null && widget.controller != null)
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: widget.controller!,
                  builder: (context, value, child) {
                    return Text(
                      '${value.text.length}/${widget.maxLength}',
                      style: AppTypography.caption(color: AppColors.textTertiary),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 8.0),
        ],
        TextField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: _obscureText,
          maxLines: widget.maxLines,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          focusNode: _effectiveFocusNode,
          autofocus: widget.autofocus,
          enabled: widget.enabled,
          maxLength: widget.maxLength,
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
          style: AppTypography.body(color: widget.enabled ? AppColors.textPrimary : AppColors.textTertiary),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: AppTypography.body(color: AppColors.textTertiary),
            filled: true,
            fillColor: widget.enabled ? AppColors.surface : AppColors.surface.withOpacity(0.5),
            contentPadding: const EdgeInsets.all(16.0),
            prefixIcon: widget.prefix,
            suffixIcon: suffixWidget,
            errorText: widget.errorText,
            errorStyle: AppTypography.caption(color: AppColors.error),
            helperText: hasError ? null : widget.helperText,
            helperStyle: AppTypography.caption(color: AppColors.textSecondary),
            border: OutlineInputBorder(
              borderRadius: AppSpacing.inputRadius,
              borderSide: BorderSide(color: borderSideColor, width: borderWidth),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppSpacing.inputRadius,
              borderSide: BorderSide(color: borderSideColor, width: borderWidth),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppSpacing.inputRadius,
              borderSide: BorderSide(color: borderSideColor, width: borderWidth),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: AppSpacing.inputRadius,
              borderSide: BorderSide(color: Colors.white.withOpacity(0.04), width: 1.0),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppSpacing.inputRadius,
              borderSide: const BorderSide(color: AppColors.error, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppSpacing.inputRadius,
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
