import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Displays a TOTP/HOTP code and animates a smooth scale+fade transition
/// whenever the code value changes (i.e. every period tick).
class AnimatedCodeText extends StatelessWidget {
  final String code;
  final Color color;

  const AnimatedCodeText({super.key, required this.code, required this.color});

  String _formatted() {
    if (code.length <= 4) return code;
    final mid = (code.length / 2).ceil();
    return '${code.substring(0, mid)} ${code.substring(mid)}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: Text(
        _formatted(),
        key: ValueKey(code),
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
