import 'package:uuid/uuid.dart';
import '../models/otp_account.dart';

/// Parses / builds standard `otpauth://totp/...` and `otpauth://hotp/...`
/// URIs, as produced by Google Authenticator, Authy, GitHub, etc.
class OtpAuthUri {
  static const _uuid = Uuid();

  static OtpAccount? parse(String raw) {
    Uri uri;
    try {
      uri = Uri.parse(raw.trim());
    } catch (_) {
      return null;
    }
    if (uri.scheme != 'otpauth') return null;

    final type = uri.host.toLowerCase() == 'hotp' ? OtpType.hotp : OtpType.totp;

    // Path is like "/Issuer:accountLabel" or "/accountLabel"
    var path = uri.path;
    if (path.startsWith('/')) path = path.substring(1);
    path = Uri.decodeComponent(path);

    String issuer = uri.queryParameters['issuer'] ?? '';
    String label = path;
    if (path.contains(':')) {
      final parts = path.split(':');
      if (issuer.isEmpty) issuer = parts.first.trim();
      label = parts.sublist(1).join(':').trim();
    }

    final secret = uri.queryParameters['secret'];
    if (secret == null || secret.isEmpty) return null;

    final algParam = (uri.queryParameters['algorithm'] ?? 'SHA1').toUpperCase();
    final algorithm = switch (algParam) {
      'SHA256' => OtpAlgorithm.sha256,
      'SHA512' => OtpAlgorithm.sha512,
      _ => OtpAlgorithm.sha1,
    };

    final digits = int.tryParse(uri.queryParameters['digits'] ?? '') ?? 6;
    final period = int.tryParse(uri.queryParameters['period'] ?? '') ?? 30;
    final counter = int.tryParse(uri.queryParameters['counter'] ?? '') ?? 0;

    return OtpAccount(
      id: _uuid.v4(),
      issuer: issuer,
      label: label,
      secretBase32: secret,
      type: type,
      algorithm: algorithm,
      digits: digits,
      period: period,
      counter: counter,
    );
  }

  /// Builds an otpauth:// URI for exporting/backing up an account (e.g. to
  /// show as a QR code that another authenticator app, or this app on
  /// another device, can scan back in).
  static String build(OtpAccount account) {
    final algName = switch (account.algorithm) {
      OtpAlgorithm.sha1 => 'SHA1',
      OtpAlgorithm.sha256 => 'SHA256',
      OtpAlgorithm.sha512 => 'SHA512',
    };
    final typeName = account.type == OtpType.totp ? 'totp' : 'hotp';
    final labelPart = account.issuer.isNotEmpty
        ? '${account.issuer}:${account.label}'
        : account.label;

    final params = <String, String>{
      'secret': account.secretBase32,
      'issuer': account.issuer,
      'algorithm': algName,
      'digits': '${account.digits}',
    };
    if (account.type == OtpType.totp) {
      params['period'] = '${account.period}';
    } else {
      params['counter'] = '${account.counter}';
    }

    final query = params.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    return 'otpauth://$typeName/${Uri.encodeComponent(labelPart)}?$query';
  }
}
