import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/otp_account.dart';

/// Holds all OTP accounts in memory and persists them to encrypted
/// storage (flutter_secure_storage → Android Keystore backed). Secrets
/// never touch shared_preferences or plaintext files.
class AccountStore extends ChangeNotifier {
  static const _storageKey = 'otp_accounts_v1';
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final List<OtpAccount> _accounts = [];
  bool _loaded = false;

  List<OtpAccount> get accounts => List.unmodifiable(_accounts);
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final raw = await _storage.read(key: _storageKey);
    _accounts.clear();
    if (raw != null && raw.isNotEmpty) {
      final list = jsonDecode(raw) as List<dynamic>;
      _accounts.addAll(
        list.map((e) => OtpAccount.fromJson(e as Map<String, dynamic>)),
      );
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final raw = jsonEncode(_accounts.map((a) => a.toJson()).toList());
    await _storage.write(key: _storageKey, value: raw);
  }

  Future<void> addAccount(OtpAccount account) async {
    _accounts.add(account);
    await _persist();
    notifyListeners();
  }

  Future<void> updateAccount(OtpAccount updated) async {
    final idx = _accounts.indexWhere((a) => a.id == updated.id);
    if (idx == -1) return;
    _accounts[idx] = updated;
    await _persist();
    notifyListeners();
  }

  Future<void> deleteAccount(String id) async {
    _accounts.removeWhere((a) => a.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _accounts.removeAt(oldIndex);
    _accounts.insert(newIndex, item);
    await _persist();
    notifyListeners();
  }

  Future<void> incrementHotpCounter(String id) async {
    final idx = _accounts.indexWhere((a) => a.id == id);
    if (idx == -1) return;
    _accounts[idx].counter += 1;
    await _persist();
    notifyListeners();
  }

  bool secretAlreadyExists(String secretBase32) =>
      _accounts.any((a) => a.secretBase32 == secretBase32);
}
