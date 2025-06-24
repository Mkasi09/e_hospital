import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

static Future<void> _sendNotification({
required String userId,
required String title,
required String body,
required String type,
Map<String, dynamic>? additionalData,
}) async {
final fcmTokenDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
final fcmToken = fcmTokenDoc.data()?['fcmToken'];

// Add notification to Firestore (for in-app list)
await _notificationsRef.add({
'userId': userId,
'title': title,
'body': body,
'type': type,
'timestamp': Timestamp.now(),
'isRead': false,
'additionalData': additionalData,
});

if (fcmToken == null) {
print('No FCM token for user $userId');
return;
}

const serverKey = 'YOUR_FIREBASE_SERVER_KEY'; // Replace this with your actual FCM server key

final message = {
'to': fcmToken,
'notification': {
'title': title,
'body': body,
'sound': 'default',
},
'data': {
'click_action': 'FLUTTER_NOTIFICATION_CLICK',
'type': type,
...?additionalData,
}
};

final response = await http.post(
Uri.parse('https://fcm.googleapis.com/fcm/send'),
headers: {
'Content-Type': 'application/json',
'Authorization': 'key=$serverKey',
},
body: jsonEncode(message),
);

if (response.statusCode == 200) {
print('Push notification sent!');
} else {
print('Failed to send push notification: ${response.body}');
}
}
