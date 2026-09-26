import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/otp_account.dart';
import '../services/account_store.dart';
import '../services/totp_service.dart';
import '../theme/app_theme.dart';
import '../widgets/code_ring.dart';
import '../widgets/animated_code_text.dart';
import 'add_account_screen.dart';
import 'account_detail_screen.dart';
import 'settings_screen.dart';

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

  void _copy(String code) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: code));
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
      extendBodyBehindAppBar: false,
      body: Container(
        decoration: AppTheme.heroGradientDecoration(context),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, accounts.length),
              Expanded(
                child: accounts.isEmpty
                    ? _EmptyState(hasQuery: _query.isNotEmpty)
                        .animate()
                        .fadeIn(duration: 400.ms)
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 100),
                        itemCount: accounts.length,
                        onReorder: (oldI, newI) {
                          if (_query.isNotEmpty) return;
                          store.reorder(oldI, newI);
                        },
                        itemBuilder: (context, i) {
                          final account = accounts[i];
                          return _AccountTile(
                            key: ValueKey(account.id),
                            account: account,
                            index: i,
                            onCopy: _copy,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _AnimatedFab(
        onPressed: () => Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, anim, __) => const AddAccountScreen(),
            transitionsBuilder: (_, anim, __, child) => SlideTransition(
              position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 320),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: _searching
                ? TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Ara...',
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.1, end: 0)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '2FA Kimlik Doğrulayıcı',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        count == 0
                            ? 'Hesap yok'
                            : '$count hesap · canlı kodlar',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ).animate().fadeIn(duration: 250.ms),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) {
                _query = '';
                _searchCtrl.clear();
              }
            }),
          ),
          if (!_searching) ...[
            const SizedBox(width: 8),
            IconButton.filledTonal(
              icon: const Icon(Icons.settings_rounded),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnimatedFab extends StatefulWidget {
  final VoidCallback onPressed;
  const _AnimatedFab({required this.onPressed});

  @override
  State<_AnimatedFab> createState() => _AnimatedFabState();
}

class _AnimatedFabState extends State<_AnimatedFab> with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: FloatingActionButton.extended(
          onPressed: widget.onPressed,
          icon: const Icon(Icons.qr_code_scanner_rounded),
          label: const Text('Hesap Ekle'),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .shimmer(duration: 2400.ms, delay: 1200.ms, color: Colors.white.withValues(alpha: 0.25)),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final OtpAccount account;
  final int index;
  final void Function(String code) onCopy;

  const _AccountTile({
    super.key,
    required this.account,
    required this.index,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final store = context.read<AccountStore>();
    final gradient = AppTheme.gradientFor(account.displayName);

    String code;
    Widget trailing;
    VoidCallback? onTap;

    if (account.type == OtpType.totp) {
      code = TotpService.generateTotp(account);
      final remaining = TotpService.secondsRemaining(account);
      trailing = CodeRing(
        secondsRemaining: remaining,
        period: account.period,
        color: gradient.first,
      );
      onTap = () => onCopy(code);
    } else {
      code = TotpService.generateHotp(account);
      trailing = IconButton(
        icon: const Icon(Icons.refresh_rounded),
        tooltip: 'Sonraki kod',
        onPressed: () {
          HapticFeedback.selectionClick();
          store.incrementHotpCounter(account.id);
        },
      );
      onTap = () => onCopy(code);
    }

    return Dismissible(
      key: ValueKey('dismiss-${account.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.danger,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
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
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            onLongPress: () => Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, anim, __) => AccountDetailScreen(account: account),
                transitionsBuilder: (_, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
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
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      account.displayName.isNotEmpty
                          ? account.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        if (account.label.isNotEmpty && account.label != account.displayName)
                          Text(
                            account.label,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 2),
                        AnimatedCodeText(code: code, color: gradient.first),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate(delay: (index * 45).ms)
        .fadeIn(duration: 340.ms, curve: Curves.easeOut)
        .slideY(begin: 0.12, end: 0, duration: 340.ms, curve: Curves.easeOutCubic);
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
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.18),
                    AppTheme.accent.withValues(alpha: 0.18),
                  ],
                ),
              ),
              child: Icon(
                hasQuery ? Icons.search_off_rounded : Icons.shield_moon_rounded,
                size: 44,
                color: AppTheme.primary,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.06, 1.06),
                  duration: 1400.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 20),
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
