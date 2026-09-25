import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';
import '../services/otpauth_uri.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  final _controller = MobileScannerController();
  late final AnimationController _scanAnim;
  bool _handled = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    _scanAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanAnim.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      final account = OtpAuthUri.parse(raw);
      if (account != null) {
        _handled = true;
        Navigator.of(context).pop(account);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const boxSize = 250.0;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('QR Kodu Tara'),
        actions: [
          IconButton(
            icon: Icon(_torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded),
            onPressed: () {
              setState(() => _torchOn = !_torchOn);
              _controller.toggleTorch();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Kamera başlatılamadı:\n${error.errorCode}\n${error.errorDetails?.message ?? ''}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Dim overlay with a transparent scan window cut out.
          IgnorePointer(
            child: CustomPaint(
              size: Size.infinite,
              painter: _ScanOverlayPainter(boxSize: boxSize),
            ),
          ),
          // Corner brackets + moving scan line, centered.
          Center(
            child: SizedBox(
              width: boxSize,
              height: boxSize,
              child: Stack(
                children: [
                  ..._buildCorners(),
                  AnimatedBuilder(
                    animation: _scanAnim,
                    builder: (context, _) => Positioned(
                      top: 4 + _scanAnim.value * (boxSize - 8),
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2.5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.accent.withValues(alpha: 0),
                              AppTheme.accent,
                              AppTheme.accent.withValues(alpha: 0),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accent.withValues(alpha: 0.8),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: const Text(
              'İki faktörlü doğrulama QR kodunu kareye hizala',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                shadows: [Shadow(blurRadius: 6, color: Colors.black)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    const len = 28.0;
    const thick = 4.0;
    Widget corner({required Alignment align, required bool top, required bool left}) {
      return Align(
        alignment: align,
        child: Container(
          width: len,
          height: len,
          decoration: BoxDecoration(
            border: Border(
              top: top ? const BorderSide(color: AppTheme.accent, width: thick) : BorderSide.none,
              bottom: !top ? const BorderSide(color: AppTheme.accent, width: thick) : BorderSide.none,
              left: left ? const BorderSide(color: AppTheme.accent, width: thick) : BorderSide.none,
              right: !left ? const BorderSide(color: AppTheme.accent, width: thick) : BorderSide.none,
            ),
            borderRadius: BorderRadius.only(
              topLeft: top && left ? const Radius.circular(12) : Radius.zero,
              topRight: top && !left ? const Radius.circular(12) : Radius.zero,
              bottomLeft: !top && left ? const Radius.circular(12) : Radius.zero,
              bottomRight: !top && !left ? const Radius.circular(12) : Radius.zero,
            ),
          ),
        ),
      );
    }

    return [
      corner(align: Alignment.topLeft, top: true, left: true),
      corner(align: Alignment.topRight, top: true, left: false),
      corner(align: Alignment.bottomLeft, top: false, left: true),
      corner(align: Alignment.bottomRight, top: false, left: false),
    ];
  }
}

class _ScanOverlayPainter extends CustomPainter {
  final double boxSize;
  _ScanOverlayPainter({required this.boxSize});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final windowRect = Rect.fromCenter(center: center, width: boxSize, height: boxSize);
    final windowPath = Path()
      ..addRRect(RRect.fromRectAndRadius(windowRect, const Radius.circular(16)));
    final fullPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final overlayPath = Path.combine(PathOperation.difference, fullPath, windowPath);
    canvas.drawPath(overlayPath, Paint()..color = Colors.black.withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter oldDelegate) => false;
}
