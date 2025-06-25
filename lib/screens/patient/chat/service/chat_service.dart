import 'dart:convert';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;

class ChatService {
  static final _db = FirebaseDatabase.instance;

  static Future<void> markMessagesAsRead(String chatId, String currentUserId) async {
    final snapshot = await _db.ref('chats/$chatId/messages').get();
    if (snapshot.exists) {
      final messages = Map<String, dynamic>.from(snapshot.value as Map);
      for (var entry in messages.entries) {
        final msg = Map<String, dynamic>.from(entry.value);
        if (msg['receiverId'] == currentUserId && msg['read'] == false) {
          await _db.ref('chats/$chatId/messages/${entry.key}/read').set(true);
        }
      }
    }
  }

  static Future<void> setTypingStatus(String chatId, String userId, bool isTyping) {
    return _db.ref('chats/$chatId/typing/$userId').set(isTyping);
  }

  static Future<void> sendMessage(String text, String chatId, String senderId, String receiverId) async {
    final message = {
      'text': text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'senderId': senderId,
      'receiverId': receiverId,
      'read': false,
    };
    await _db.ref('chats/$chatId/messages').push().set(message);
    await _db.ref('chats/$chatId/meta').update({'lastUpdated': DateTime.now().millisecondsSinceEpoch});
  }

  static Future<void> uploadAndSendImage(File image, String chatId, String senderId, String receiverId) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/dzz3iovq5/raw/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = 'ehospital'
      ..files.add(await http.MultipartFile.fromPath('file', image.path));
    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final decoded = json.decode(responseData);
      final imageUrl = decoded['secure_url'];

      final message = {
        'senderId': senderId,
        'receiverId': receiverId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'type': 'image',
        'content': imageUrl,
        'read': false,
      };
      await _db.ref('chats/$chatId/messages').push().set(message);
    } else {
      print('Image upload failed');
    }
  }
}
