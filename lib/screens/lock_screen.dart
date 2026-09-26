import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_auth/local_auth.dart';
import '../theme/app_theme.dart';

/// Shown before the app content when app-lock is enabled — either on
/// cold start, or whenever the app returns from the background.
class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _auth = LocalAuthentication();
  bool _checking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _authenticate() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) {
        setState(() => _error = 'Bu cihazda kilit açma desteklenmiyor');
        return;
      }
      final ok = await _auth.authenticate(
        localizedReason: 'Uygulamayı açmak için kimliğini doğrula',
        options: const AuthenticationOptions(stickyAuth: true),
      );
      if (ok) widget.onUnlocked();
    } catch (e) {
      setState(() => _error = 'Doğrulama başarısız, tekrar dene');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.heroGradientDecoration(context),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.fingerprint_rounded, color: Colors.white, size: 46),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.08, 1.08),
                    duration: 900.ms,
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(height: 24),
              const Text('Uygulama Kilitli', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                _checking ? 'Doğrulanıyor…' : 'Devam etmek için doğrula',
                style: TextStyle(color: Colors.grey.shade500),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _checking ? null : _authenticate,
                icon: const Icon(Icons.lock_open_rounded),
                label: const Text('Kilidi Aç'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
