import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../services/settings_store.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = LocalAuthentication();
  bool _lockSupported = true;

  @override
  void initState() {
    super.initState();
    _checkSupport();
  }

  Future<void> _checkSupport() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (mounted) setState(() => _lockSupported = supported);
    } catch (_) {
      if (mounted) setState(() => _lockSupported = false);
    }
  }

  Future<void> _toggleLock(bool value, SettingsStore settings) async {
    if (value) {
      try {
        final ok = await _auth.authenticate(
          localizedReason: 'Kilidi etkinleştirmek için kimliğini doğrula',
          options: const AuthenticationOptions(stickyAuth: true),
        );
        if (!ok) return;
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doğrulama başarısız')),
        );
        return;
      }
    }
    await settings.setLockEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsStore>();
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle('Görünüm'),
          Card(
            child: Column(
              children: [
                _ThemeOption(
                  icon: Icons.brightness_auto_rounded,
                  label: 'Sistem',
                  selected: settings.themeMode == ThemeMode.system,
                  onTap: () => settings.setThemeMode(ThemeMode.system),
                ),
                _ThemeOption(
                  icon: Icons.light_mode_rounded,
                  label: 'Açık',
                  selected: settings.themeMode == ThemeMode.light,
                  onTap: () => settings.setThemeMode(ThemeMode.light),
                ),
                _ThemeOption(
                  icon: Icons.dark_mode_rounded,
                  label: 'Koyu',
                  selected: settings.themeMode == ThemeMode.dark,
                  onTap: () => settings.setThemeMode(ThemeMode.dark),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.06, end: 0),
          const SizedBox(height: 22),
          const _SectionTitle('Güvenlik'),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.fingerprint_rounded),
              title: const Text('Uygulama kilidi'),
              subtitle: Text(
                _lockSupported
                    ? 'Açılışta ve arka plandan dönüşte parmak izi / yüz / PIN iste'
                    : 'Bu cihazda desteklenmiyor',
              ),
              value: settings.lockEnabled,
              onChanged: _lockSupported ? (v) => _toggleLock(v, settings) : null,
            ),
          ).animate(delay: 80.ms).fadeIn(duration: 250.ms).slideY(begin: 0.06, end: 0),
          const SizedBox(height: 22),
          const _SectionTitle('Hakkında'),
          Card(
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(Icons.shield_moon_rounded),
                  title: Text('2FA Kimlik Doğrulayıcı'),
                  subtitle: Text('Sürüm 1.0.0 · tamamen bu cihazda çalışır'),
                ),
                ListTile(
                  leading: Icon(Icons.lock_person_rounded),
                  title: Text('Gizlilik'),
                  subtitle: Text('Sırlar hiçbir sunucuya gönderilmez, yalnızca şifreli yerel depoda tutulur.'),
                ),
              ],
            ),
          ).animate(delay: 160.ms).fadeIn(duration: 250.ms).slideY(begin: 0.06, end: 0),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey.shade600),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: selected ? AppTheme.primary : null),
      title: Text(label),
      trailing: selected ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary) : null,
      onTap: onTap,
    );
  }
}
