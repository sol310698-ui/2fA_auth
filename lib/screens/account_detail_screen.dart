import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/otp_account.dart';
import '../services/account_store.dart';
import '../services/otpauth_uri.dart';
import '../theme/app_theme.dart';

class AccountDetailScreen extends StatefulWidget {
  final OtpAccount account;
  const AccountDetailScreen({super.key, required this.account});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  late final TextEditingController _issuerCtrl =
      TextEditingController(text: widget.account.issuer);
  late final TextEditingController _labelCtrl =
      TextEditingController(text: widget.account.label);
  bool _showQr = false;

  @override
  void dispose() {
    _issuerCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updated = widget.account
      ..issuer = _issuerCtrl.text.trim()
      ..label = _labelCtrl.text.trim();
    await context.read<AccountStore>().updateAccount(updated);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hesabı sil'),
        content: const Text('Bu işlem geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AccountStore>().deleteAccount(widget.account.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final uri = OtpAuthUri.build(widget.account);
    final gradient = AppTheme.gradientFor(widget.account.displayName);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hesap Ayrıntıları'),
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: _delete),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.account.displayName.isNotEmpty
                      ? widget.account.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 30),
                ),
              ),
            ).animate().scale(
                  begin: const Offset(0.6, 0.6),
                  end: const Offset(1, 1),
                  duration: 380.ms,
                  curve: Curves.easeOutBack,
                ).fadeIn(duration: 250.ms),
            const SizedBox(height: 24),
            TextField(
              controller: _issuerCtrl,
              decoration: InputDecoration(
                labelText: 'Servis adı',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _labelCtrl,
              decoration: InputDecoration(
                labelText: 'Hesap / e-posta',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Kaydet'),
            ),
            const SizedBox(height: 28),
            Row(
              children: const [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Yedekleme'),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Bu hesabı başka bir cihaza veya başka bir kimlik doğrulayıcıya '
              'aktarmak için QR kodu göster ve karşı taraftan tara. Gizli '
              'anahtarı kimseyle paylaşma.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => setState(() => _showQr = !_showQr),
              icon: AnimatedRotation(
                turns: _showQr ? 0.5 : 0,
                duration: const Duration(milliseconds: 250),
                child: Icon(_showQr ? Icons.expand_less_rounded : Icons.qr_code_rounded),
              ),
              label: Text(_showQr ? 'QR Kodu Gizle' : 'Yedekleme QR Kodunu Göster'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              child: _showQr
                  ? Column(
                      children: [
                        const SizedBox(height: 20),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: gradient.first.withValues(alpha: 0.3),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: QrImageView(data: uri, size: 220),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 300.ms)
                            .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: widget.account.secretBase32));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Gizli anahtar kopyalandı')),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded),
                            label: const Text('Gizli anahtarı kopyala'),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}
