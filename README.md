# 2FA Kimlik Doğrulayıcı (auth2fa)

Google Authenticator'a benzer, tamamen kendi Flutter uygulaman. Sırlar
telefonda `flutter_secure_storage` ile (Android Keystore destekli)
şifreli tutulur, hiçbir sunucuya gitmez.

## Özellikler
- TOTP (zaman tabanlı) ve HOTP (sayaç tabanlı) kod üretimi — RFC 6238 / RFC 4226
- SHA1 / SHA256 / SHA512, 6 veya 8 haneli kod desteği
- QR kod tarayarak hesap ekleme (`otpauth://` standart formatı — Google,
  GitHub, Microsoft vb. her yerden kopyalanan QR'ları okur)
- Elle hesap ekleme (servis adı + gizli anahtar)
- Kod listesi: canlı geri sayım halkası, dokununca panoya kopyalama,
  arama, sürükle-bırak sıralama, sağa kaydır = sil
- Hesap yedekleme: her hesap için QR kod olarak dışa aktarım
- Açık/koyu tema (sistem temasını takip eder)
- GitHub Actions ile otomatik APK derleme (keystore imzalı, imza
  anahtarı yoksa debug imzasıyla düşer)

## Proje yapısı
```
lib/
  models/otp_account.dart        Hesap modeli
  services/totp_service.dart     TOTP/HOTP hesaplama (RFC 6238/4226)
  services/otpauth_uri.dart      otpauth:// URI ayrıştırma/oluşturma
  services/account_store.dart    Şifreli depolama + state
  screens/home_screen.dart       Ana liste
  screens/add_account_screen.dart Hesap ekleme (QR + elle)
  screens/scan_screen.dart       Kamera QR tarama
  screens/account_detail_screen.dart Düzenle/sil/yedekle
  theme/app_theme.dart           Açık/koyu tema
scripts/patch_android.sh         CI'da android/ iskeleti oluşunca
                                  kamera izni + imzalama yamasını uygular
.github/workflows/build.yml      Derleme + artifact temizliği
```

`android/`, `ios/` vb. platform klasörleri **repoya commitlenmez** —
her derlemede CI (`flutter create --platforms=android .`) tarafından
sıfırdan oluşturulur, sonra `scripts/patch_android.sh` kamera iznini ve
imzalama ayarını ekler. Bu, skt_takip'teki gibi repo'yu hafif tutar.

## Termux'ta ilk teslimat

```bash
cd /sdcard/Download
unzip -o auth2fa.zip -d auth2fa_src

# Eğer 2FA_auth reposu Termux'ta henüz klonlanmadıysa:
cd ~
git clone https://github.com/<KULLANICI_ADIN>/2FA_auth.git
cd 2FA_auth

# Zip içeriğini repo köküne kopyala (SONDAKİ NOKTA ŞART — gizli
# dosyaları da (.github, .gitignore) taşımak için)
cp -rf /sdcard/Download/auth2fa_src/. ~/2FA_auth/

git add -A
git commit -m "2FA kimlik doğrulayıcı: ilk sürüm (TOTP/HOTP, QR tarama, yedekleme)"
git push origin main
```

Sonraki güncellemelerde de aynı `cp -rf .../. ~/2FA_auth/` + `git add -A
&& git commit && git push origin main` deseni kullanılır.

Push sonrası GitHub Actions otomatik derler; **Actions** sekmesinden
`auth2fa-release-apk` artifact'ini indirebilirsin.

## Release imzalama (opsiyonel ama önerilir)

İmza anahtarı eklenmezse APK debug imzasıyla derlenir (kurulabilir,
test için yeterli ama Play Store'a uygun değildir ve her CI çalışmasında
farklı davranmaz — debug key sabittir). Gerçek bir sürüm anahtarı için:

```bash
keytool -genkey -v -keystore release.keystore -alias auth2fa \
  -keyalg RSA -keysize 2048 -validity 10000
base64 -w0 release.keystore > release.keystore.b64
cat release.keystore.b64   # çıktıyı kopyala
```

GitHub reposunda **Settings → Secrets and variables → Actions** altına
şu 4 secret'ı ekle:
- `KEYSTORE_BASE64` — yukarıdaki base64 çıktısı
- `KEYSTORE_PASSWORD` — keystore parolan
- `KEY_ALIAS` — `auth2fa` (yukarıda verdiğin alias)
- `KEY_PASSWORD` — anahtar parolan

Bu secret'lar varsa CI otomatik olarak release imzasıyla derler.

## Notlar
- `mobile_scanner` kamera izni ister; `scripts/patch_android.sh`
  bunu her scaffold'da otomatik `AndroidManifest.xml`'e ekler.
- Gizli anahtarlar yalnızca cihazda `flutter_secure_storage`
  (Android Keystore / EncryptedSharedPreferences) içinde tutulur.
