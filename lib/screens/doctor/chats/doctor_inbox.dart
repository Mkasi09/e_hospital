import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../patient/chat/chats.dart';


class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Your Chats')),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('chats').onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('No chats yet'));
          }

          final data = snapshot.data!.snapshot.value as Map;
          final chats = data.entries.where((e) {
            final meta = (e.value as Map)['meta'];
            return meta['doctorId'] == currentUserId || meta['patientId'] == currentUserId;
          }).toList();

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chatId = chats[index].key;
              final meta = chats[index].value['meta'];

              final peerName = meta['doctorId'] == currentUserId
                  ? meta['patientName'] ?? 'Patient'
                  : meta['doctorName'] ?? 'Doctor';

              return ListTile(
                title: Text(peerName),
                subtitle: const Text('Tap to continue chat'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatId: chatId,
                        currentUserId: currentUserId,
                        peerName: peerName,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
