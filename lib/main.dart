import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/account_store.dart';
import 'services/settings_store.dart';
import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const Auth2faApp());
}

class Auth2faApp extends StatelessWidget {
  const Auth2faApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AccountStore()),
        ChangeNotifierProvider(create: (_) => SettingsStore()..load()),
      ],
      child: Consumer<SettingsStore>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: '2FA Kimlik Doğrulayıcı',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: settings.themeMode,
            home: const _AppGate(),
          );
        },
      ),
    );
  }
}

/// Decides whether to show the lock screen or the real app, and
/// re-locks automatically whenever the app is fully backgrounded (if
/// app lock is enabled in settings).
class _AppGate extends StatefulWidget {
  const _AppGate();

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> with WidgetsBindingObserver {
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.paused) return;
    final settings = context.read<SettingsStore>();
    if (settings.lockEnabled && _unlocked) {
      setState(() => _unlocked = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsStore>();
    if (!settings.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (settings.lockEnabled && !_unlocked) {
      return LockScreen(onUnlocked: () => setState(() => _unlocked = true));
    }
    return const HomeScreen();
  }
}
