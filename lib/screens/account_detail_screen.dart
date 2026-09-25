import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/otp_account.dart';
import '../services/account_store.dart';
import '../services/otpauth_uri.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hesap Ayrıntıları'),
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _issuerCtrl,
              decoration: const InputDecoration(labelText: 'Servis adı', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _labelCtrl,
              decoration: const InputDecoration(labelText: 'Hesap / e-posta', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: const Text('Kaydet')),
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
              icon: Icon(_showQr ? Icons.visibility_off : Icons.qr_code),
              label: Text(_showQr ? 'QR Kodu Gizle' : 'Yedekleme QR Kodunu Göster'),
            ),
            if (_showQr) ...[
              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: QrImageView(data: uri, size: 220),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.account.secretBase32));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Gizli anahtar kopyalandı')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Gizli anahtarı kopyala'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
