import 'package:e_hospital/screens/doctor/chats/my_patients_list.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../patient/chat/chats.dart';


class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();

    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return DateFormat('hh:mm a').format(date);
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }
  Widget _buildStatusDot(String userId) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('status/$userId/online').onValue,
      builder: (context, snapshot) {
        final isOnline = snapshot.data?.snapshot.value == true;
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: isOnline ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('chats').onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('No chats found.'));
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
              final chat = chats[index].value as Map;
              final meta = chat['meta'];
              final messages = (chat['messages'] ?? {}) as Map;

              final peerName = (meta['doctorId'] == currentUserId)
                  ? meta['patientName'] ?? 'Patient'
                  : meta['doctorName'] ?? 'Doctor';
              final peerId = (meta['doctorId'] == currentUserId)
                  ? meta['patientId']
                  : meta['doctorId'];


              // Get last message
              final lastMessage = messages.entries.isNotEmpty
                  ? (messages.entries.last.value['text'] ?? '')
                  : 'No messages yet';

              // Get last timestamp
              final lastTimestamp = meta['lastUpdated'] ?? 0;
              final formattedTime = _formatTimestamp(lastTimestamp);

              // Count unread messages
              final unreadCount = messages.entries.where((msg) {
                final message = msg.value;
                return message['receiverId'] == currentUserId && message['read'] == false;
              }).length;

              return ListTile(
                leading: Stack(
                  children: [
                    const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: _buildStatusDot(peerId), // <- pass peerId
                    ),
                  ],
                ),
                title: Text(peerName),
                subtitle: Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formattedTime,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (unreadCount > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatId: chatId,
                        currentUserId: currentUserId,
                        peerName: peerName,
                        peerId: peerId,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyPatientsScreen()),
          );
        },
        icon: const Icon(Icons.person_search),
        label: const Text('My Patients'),
      ),
    );
  }
}
