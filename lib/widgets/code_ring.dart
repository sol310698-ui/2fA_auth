import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Circular countdown ring showing how much of the current TOTP period
/// remains, with the seconds-remaining number in the center. Pulses and
/// glows red in the final seconds to draw the eye before the code flips.
class CodeRing extends StatelessWidget {
  final int secondsRemaining;
  final int period;
  final Color color;

  const CodeRing({
    super.key,
    required this.secondsRemaining,
    required this.period,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = secondsRemaining / period;
    final isLow = secondsRemaining <= 5;
    final ringColor = isLow ? Colors.redAccent : color;

    Widget ring = SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isLow)
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withValues(alpha: 0.45),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: fraction, end: fraction),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, _) => CircularProgressIndicator(
              value: value.clamp(0, 1),
              strokeWidth: 3,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(ringColor),
            ),
          ),
          Text(
            '$secondsRemaining',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isLow ? Colors.redAccent : null,
            ),
          ),
        ],
      ),
    );

    if (isLow) {
      ring = ring
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.12, 1.12),
            duration: 500.ms,
            curve: Curves.easeInOut,
          );
    }
    return ring;
  }
}
