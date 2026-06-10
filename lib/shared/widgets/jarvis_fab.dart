import 'package:flutter/material.dart';
import 'package:jarvis/core/theme/app_colors.dart';

class JarvisFab extends StatefulWidget {
  final VoidCallback onTap;

  const JarvisFab({super.key, required this.onTap});

  @override
  State<JarvisFab> createState() => _JarvisFabState();
}

class _JarvisFabState extends State<JarvisFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 58.0,
          height: 58.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.jarvisButtonGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 15.0,
                spreadRadius: 2.0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 26.0,
          ),
        ),
      ),
    );
  }
}
