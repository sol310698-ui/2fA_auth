import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/otp_account.dart';
import '../services/account_store.dart';
import '../services/totp_service.dart';
import '../theme/app_theme.dart';
import 'scan_screen.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _issuerCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();
  final _secretCtrl = TextEditingController();
  OtpAlgorithm _algorithm = OtpAlgorithm.sha1;
  OtpType _type = OtpType.totp;
  int _digits = 6;
  int _period = 30;

  @override
  void dispose() {
    _issuerCtrl.dispose();
    _labelCtrl.dispose();
    _secretCtrl.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final account = await Navigator.of(context).push<OtpAccount>(
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
    if (account == null || !mounted) return;
    final store = context.read<AccountStore>();
    if (store.secretAlreadyExists(account.secretBase32)) {
      _showDuplicateWarning();
      return;
    }
    await store.addAccount(account);
    if (mounted) Navigator.of(context).pop();
  }

  void _showDuplicateWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bu hesap zaten ekli görünüyor')),
    );
  }

  Future<void> _saveManual() async {
    if (!_formKey.currentState!.validate()) return;
    final secret = _secretCtrl.text.trim().replaceAll(' ', '');
    final store = context.read<AccountStore>();
    if (store.secretAlreadyExists(secret)) {
      _showDuplicateWarning();
      return;
    }
    final account = OtpAccount(
      id: const Uuid().v4(),
      issuer: _issuerCtrl.text.trim(),
      label: _labelCtrl.text.trim(),
      secretBase32: secret,
      type: _type,
      algorithm: _algorithm,
      digits: _digits,
      period: _period,
    );
    await store.addAccount(account);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hesap Ekle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: _scan,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'QR Kod Tara',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .shimmer(delay: 900.ms, duration: 2200.ms, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 24),
            Row(
              children: const [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('veya elle gir'),
                ),
                Expanded(child: Divider()),
              ],
            ).animate(delay: 100.ms).fadeIn(duration: 300.ms),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _issuerCtrl,
                    decoration: InputDecoration(
                      labelText: 'Servis adı (ör. Google, GitHub)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _labelCtrl,
                    decoration: InputDecoration(
                      labelText: 'Hesap / e-posta',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _secretCtrl,
                    decoration: InputDecoration(
                      labelText: 'Gizli anahtar (Base32)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Zorunlu';
                      if (!TotpService.isValidSecret(v.trim())) {
                        return 'Geçersiz Base32 anahtarı';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<OtpType>(
                          value: _type,
                          decoration: InputDecoration(
                            labelText: 'Tür',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          items: const [
                            DropdownMenuItem(value: OtpType.totp, child: Text('TOTP (zaman)')),
                            DropdownMenuItem(value: OtpType.hotp, child: Text('HOTP (sayaç)')),
                          ],
                          onChanged: (v) => setState(() => _type = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _digits,
                          decoration: InputDecoration(
                            labelText: 'Basamak',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 6, child: Text('6')),
                            DropdownMenuItem(value: 8, child: Text('8')),
                          ],
                          onChanged: (v) => setState(() => _digits = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<OtpAlgorithm>(
                          value: _algorithm,
                          decoration: InputDecoration(
                            labelText: 'Algoritma',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          items: const [
                            DropdownMenuItem(value: OtpAlgorithm.sha1, child: Text('SHA1')),
                            DropdownMenuItem(value: OtpAlgorithm.sha256, child: Text('SHA256')),
                            DropdownMenuItem(value: OtpAlgorithm.sha512, child: Text('SHA512')),
                          ],
                          onChanged: (v) => setState(() => _algorithm = v!),
                        ),
                      ),
                      if (_type == OtpType.totp) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: '$_period',
                            decoration: InputDecoration(
                              labelText: 'Periyot (sn)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => _period = int.tryParse(v) ?? 30,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saveManual,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Kaydet'),
                  ),
                ],
              ),
            ).animate(delay: 150.ms).fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0),
          ],
        ),
      ),
    );
  }
}
