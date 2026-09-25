import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/otp_account.dart';
import '../services/account_store.dart';
import '../services/totp_service.dart';
import '../theme/app_theme.dart';
import '../widgets/code_ring.dart';
import 'add_account_screen.dart';
import 'account_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _ticker;
  String _query = '';
  bool _searching = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AccountStore>().load();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _copy(String code, String name) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name kodu kopyalandı'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AccountStore>();

    if (!store.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final accounts = store.accounts.where((a) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return a.issuer.toLowerCase().contains(q) ||
          a.label.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Ara...',
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _query = v),
              )
            : const Text('2FA Kimlik Doğrulayıcı'),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) {
                _query = '';
                _searchCtrl.clear();
              }
            }),
          ),
        ],
      ),
      body: accounts.isEmpty
          ? _EmptyState(hasQuery: _query.isNotEmpty)
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
              itemCount: accounts.length,
              onReorder: (oldI, newI) {
                if (_query.isNotEmpty) return; // avoid confusing reorder while filtered
                store.reorder(oldI, newI);
              },
              itemBuilder: (context, i) {
                final account = accounts[i];
                return _AccountTile(
                  key: ValueKey(account.id),
                  account: account,
                  onCopy: _copy,
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddAccountScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Hesap Ekle'),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final OtpAccount account;
  final void Function(String code, String name) onCopy;

  const _AccountTile({super.key, required this.account, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    final store = context.read<AccountStore>();
    final color = AppTheme.colorFor(account.displayName);

    String code;
    Widget trailing;
    VoidCallback? onTap;

    if (account.type == OtpType.totp) {
      code = TotpService.generateTotp(account);
      final remaining = TotpService.secondsRemaining(account);
      trailing = CodeRing(
        secondsRemaining: remaining,
        period: account.period,
        color: color,
      );
      onTap = () => onCopy(code, account.displayName);
    } else {
      code = TotpService.generateHotp(account);
      trailing = IconButton(
        icon: const Icon(Icons.refresh),
        tooltip: 'Sonraki kod',
        onPressed: () => store.incrementHotpCounter(account.id),
      );
      onTap = () => onCopy(code, account.displayName);
    }

    final formatted = _formatCode(code);

    return Dismissible(
      key: ValueKey('dismiss-${account.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Hesabı sil'),
                content: Text('${account.displayName} silinsin mi?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Vazgeç'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Sil'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => store.deleteAccount(account.id),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          onTap: onTap,
          onLongPress: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AccountDetailScreen(account: account)),
          ),
          leading: CircleAvatar(
            backgroundColor: color,
            child: Text(
              account.displayName.isNotEmpty
                  ? account.displayName[0].toUpperCase()
                  : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            account.displayName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            formatted,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          trailing: trailing,
        ),
      ),
    );
  }

  String _formatCode(String code) {
    if (code.length <= 4) return code;
    final mid = (code.length / 2).ceil();
    return '${code.substring(0, mid)} ${code.substring(mid)}';
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasQuery;
  const _EmptyState({required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasQuery ? Icons.search_off : Icons.shield_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              hasQuery
                  ? 'Sonuç bulunamadı'
                  : 'Henüz hesap eklenmedi.\nSağ alttaki + ile QR tara veya elle ekle.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
