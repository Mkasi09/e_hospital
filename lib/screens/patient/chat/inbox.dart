import 'package:e_hospital/screens/doctor/chats/my_patients_list.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../patient/chat/chats.dart';
import 'doctors_list.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  String _searchQuery = '';
  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();

    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
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
      appBar: AppBar(title: const Text('Inbox')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance.ref('chats').onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text('No chats found.'));
                }

                final data = snapshot.data!.snapshot.value as Map;
                final chats = data.entries.where((e) {
                  final meta = (e.value as Map)['meta'];
                  final isCurrentUserInChat = meta['doctorId'] == currentUserId || meta['patientId'] == currentUserId;

                  final peerName = (meta['doctorId'] == currentUserId)
                      ? meta['patientName'] ?? 'Patient'
                      : meta['doctorName'] ?? 'Doctor';

                  final matchesSearch = peerName.toLowerCase().contains(_searchQuery);

                  return isCurrentUserInChat && matchesSearch;
                }).toList();

                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chatId = chats[index].key;
                    final chat = chats[index].value as Map;
                    final meta = chat['meta'];
                    final messages = (chat['messages'] ?? {}) as Map;

                    final peerName =
                    (meta['doctorId'] == currentUserId)
                        ? meta['patientName'] ?? 'Patient'
                        : meta['doctorName'] ?? 'Doctor';
                    final peerId =
                    (meta['doctorId'] == currentUserId)
                        ? meta['patientId']
                        : meta['doctorId'];

                    // Get last message
                    String lastMessage = 'No messages yet';
                    int lastTimestamp = 0;

                    if (messages.isNotEmpty) {
                      final sortedMessages =
                      messages.entries.toList()..sort((a, b) {
                        final aTime = (a.value['timestamp'] ?? 0) as int;
                        final bTime = (b.value['timestamp'] ?? 0) as int;
                        return bTime.compareTo(aTime); // newest first
                      });

                      final latestMsg = sortedMessages.first.value;
                      lastMessage = latestMsg['text'] ?? '';
                      lastTimestamp = latestMsg['timestamp'] ?? 0;
                    }

                    final formattedTime = _formatTimestamp(lastTimestamp);

                    // Count unread messages
                    final unreadCount =
                        messages.entries.where((msg) {
                          final message = msg.value;
                          return message['receiverId'] == currentUserId &&
                              message['read'] == false;
                        }).length;

                    return ListTile(
                      leading: Stack(
                        children: [
                          const CircleAvatar(child: Icon(Icons.person)),
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
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          if (unreadCount > 0)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => ChatScreen(
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DoctorsListScreen()),
          );
        },
        icon: const Icon(Icons.person_search),
        label: const Text('Find Doctor'),
      ),
    );
  }
}
