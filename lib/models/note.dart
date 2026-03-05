import 'package:secure_notes/services/crypto_service.dart';

class Note {
  final String id;
  final String title;
  /// Content is stored encrypted using [CryptoService].
  final String content;
  final DateTime? reminder;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.reminder,
  });

  /// Returns the decrypted content. This uses the same static key/IV used for
  /// encryption, so the plaintext is recovered in memory only when needed.
  String get decryptedContent => CryptoService().decrypt(content);

  /// Convert to a map suitable for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'reminder': reminder?.millisecondsSinceEpoch,
    };
  }

  /// Restore from Firestore map.
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      reminder: map['reminder'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['reminder'] as int)
          : null,
    );
  }
}
