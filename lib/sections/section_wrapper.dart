import 'package:flutter/material.dart';

class SectionWrapper extends StatelessWidget {
  final String title;
  final Widget child;
  final Color? backgroundColor;

  const SectionWrapper({
    super.key,
    required this.title,
    required this.child,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    final isMobile = size.width < 700;

    return Container(
      width: double.infinity,
      color: backgroundColor ?? Colors.transparent,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : size.width * 0.1,
        vertical: 100.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 32,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 80,
            height: 4,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFFFFD54F)]),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 64),
          child,
        ],
      ),
    );
  }
}
