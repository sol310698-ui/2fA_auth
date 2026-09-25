import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/account_store.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const Auth2faApp());
}

class Auth2faApp extends StatelessWidget {
  const Auth2faApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AccountStore(),
      child: MaterialApp(
        title: '2FA Kimlik Doğrulayıcı',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
