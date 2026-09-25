enum OtpType { totp, hotp }

enum OtpAlgorithm { sha1, sha256, sha512 }

class OtpAccount {
  final String id;
  String issuer;
  String label;
  String secretBase32;
  OtpType type;
  OtpAlgorithm algorithm;
  int digits;
  int period; // TOTP only, seconds
  int counter; // HOTP only
  String? iconTag; // optional visual tag (initial letter color seed)

  OtpAccount({
    required this.id,
    required this.issuer,
    required this.label,
    required this.secretBase32,
    this.type = OtpType.totp,
    this.algorithm = OtpAlgorithm.sha1,
    this.digits = 6,
    this.period = 30,
    this.counter = 0,
    this.iconTag,
  });

  String get displayName => issuer.isNotEmpty ? issuer : label;

  Map<String, dynamic> toJson() => {
        'id': id,
        'issuer': issuer,
        'label': label,
        'secret': secretBase32,
        'type': type.name,
        'algorithm': algorithm.name,
        'digits': digits,
        'period': period,
        'counter': counter,
        'iconTag': iconTag,
      };

  factory OtpAccount.fromJson(Map<String, dynamic> json) => OtpAccount(
        id: json['id'] as String,
        issuer: json['issuer'] as String? ?? '',
        label: json['label'] as String? ?? '',
        secretBase32: json['secret'] as String,
        type: OtpType.values.firstWhere(
          (e) => e.name == (json['type'] as String? ?? 'totp'),
          orElse: () => OtpType.totp,
        ),
        algorithm: OtpAlgorithm.values.firstWhere(
          (e) => e.name == (json['algorithm'] as String? ?? 'sha1'),
          orElse: () => OtpAlgorithm.sha1,
        ),
        digits: json['digits'] as int? ?? 6,
        period: json['period'] as int? ?? 30,
        counter: json['counter'] as int? ?? 0,
        iconTag: json['iconTag'] as String?,
      );
}
