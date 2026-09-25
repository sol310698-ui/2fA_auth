import 'dart:typed_data';
import 'package:base32/base32.dart';
import 'package:crypto/crypto.dart';
import '../models/otp_account.dart';

/// RFC 4226 (HOTP) + RFC 6238 (TOTP) implementation.
class TotpService {
  /// Current TOTP code for [account] at [now] (defaults to DateTime.now()).
  static String generateTotp(OtpAccount account, {DateTime? now}) {
    final time = now ?? DateTime.now().toUtc();
    final counter = time.millisecondsSinceEpoch ~/ 1000 ~/ account.period;
    return _hotp(account, counter);
  }

  static String generateHotp(OtpAccount account) {
    return _hotp(account, account.counter);
  }

  /// Seconds remaining in the current TOTP period (for the progress ring).
  static int secondsRemaining(OtpAccount account, {DateTime? now}) {
    final time = now ?? DateTime.now().toUtc();
    final seconds = time.millisecondsSinceEpoch ~/ 1000;
    final elapsed = seconds % account.period;
    return account.period - elapsed;
  }

  static String _hotp(OtpAccount account, int counter) {
    final key = _decodeSecret(account.secretBase32);
    final counterBytes = ByteData(8)..setInt64(0, counter, Endian.big);

    final Hmac hmac;
    switch (account.algorithm) {
      case OtpAlgorithm.sha1:
        hmac = Hmac(sha1, key);
        break;
      case OtpAlgorithm.sha256:
        hmac = Hmac(sha256, key);
        break;
      case OtpAlgorithm.sha512:
        hmac = Hmac(sha512, key);
        break;
    }

    final hash = hmac.convert(counterBytes.buffer.asUint8List()).bytes;
    final offset = hash[hash.length - 1] & 0x0f;
    final binary = ((hash[offset] & 0x7f) << 24) |
        ((hash[offset + 1] & 0xff) << 16) |
        ((hash[offset + 2] & 0xff) << 8) |
        (hash[offset + 3] & 0xff);

    final otp = binary % _pow10(account.digits);
    return otp.toString().padLeft(account.digits, '0');
  }

  static int _pow10(int n) {
    var v = 1;
    for (var i = 0; i < n; i++) {
      v *= 10;
    }
    return v;
  }

  static List<int> _decodeSecret(String secret) {
    final cleaned = secret.replaceAll(' ', '').toUpperCase();
    final padded = _padBase32(cleaned);
    return base32.decode(padded);
  }

  static String _padBase32(String input) {
    final remainder = input.length % 8;
    if (remainder == 0) return input;
    return input + ('=' * (8 - remainder));
  }

  /// Validates that a string is decodable as a base32 secret.
  static bool isValidSecret(String secret) {
    try {
      final key = _decodeSecret(secret);
      return key.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
