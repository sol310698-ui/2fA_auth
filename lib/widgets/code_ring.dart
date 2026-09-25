import 'package:flutter/material.dart';

/// Small circular countdown ring showing how much of the current TOTP
/// period remains, with the seconds-remaining number in the center.
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
    return SizedBox(
      width: 34,
      height: 34,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: fraction.clamp(0, 1),
            strokeWidth: 3,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(
              isLow ? Colors.redAccent : color,
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
  }
}
