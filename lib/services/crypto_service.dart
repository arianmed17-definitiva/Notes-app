import 'package:encrypt/encrypt.dart';

/// Simple symmetric AES encryption helper.
///
/// In a real app the key/IV would be stored securely (e.g. keystore/secure
/// storage) or derived from a user secret. Here we hardcode values just for
/// demonstration.
class CryptoService {
  // 32-byte key (AES-256). Must be exactly 32 chars when using utf8.
  static final _key = Key.fromUtf8('my32lengthsupersecretnooneknows1');
  // 16-byte IV (AES block size). Reusing a fixed IV is insecure but ok for demo.
  static final _iv = IV.fromLength(16);

  final Encrypter _encrypter = Encrypter(AES(_key, mode: AESMode.cbc));

  /// Encrypts [plain] and returns a base64 string.
  String encrypt(String plain) {
    final encrypted = _encrypter.encrypt(plain, iv: _iv);
    return encrypted.base64;
  }

  /// Decrypts a base64 [cipherText] back to plain text.
  String decrypt(String cipherText) {
    return _encrypter.decrypt64(cipherText, iv: _iv);
  }
}
