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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String _formatTimestamp(int timestamp) {
    if (timestamp == 0) return '';

    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return DateFormat('hh:mm a').format(date);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(date);
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
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isOnline ? Colors.green : Colors.grey[400],
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        );
      },
    );
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map? _cachedChats;

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ), // Primary teal
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  prefixIcon: Icon(Icons.search, color: Colors.teal[700]),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.teal[700]),
                            onPressed: _clearSearch,
                          )
                          : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
          ),

          // Search Info Chip
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Chip(
                    label: Text(
                      'Search: "$_searchQuery"',
                      style: TextStyle(fontSize: 12, color: Colors.teal[700]),
                    ),
                    backgroundColor: Colors.teal[50],
                    deleteIcon: Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.teal[700],
                    ),
                    onDeleted: _clearSearch,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Chats List
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance.ref('chats').onValue,
              builder: (context, snapshot) {
                final currentUserId = FirebaseAuth.instance.currentUser!.uid;

                // 🔹 Persistent cache to avoid flicker
                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  _cachedChats = snapshot.data!.snapshot.value as Map;
                }

                // Use cached data if Firebase hasn't sent new data yet
                final data = _cachedChats ?? {};

                if (data.isEmpty) {
                  return _buildEmptyState();
                }

                final chats =
                    data.entries.where((e) {
                      final meta = (e.value as Map)['meta'];
                      final isCurrentUserInChat =
                          meta['doctorId'] == currentUserId ||
                          meta['patientId'] == currentUserId;

                      final peerName =
                          (meta['doctorId'] == currentUserId)
                              ? meta['patientName'] ?? 'Patient'
                              : meta['doctorName'] ?? 'Doctor';

                      final matchesSearch = peerName.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      );

                      return isCurrentUserInChat && matchesSearch;
                    }).toList();

                if (chats.isEmpty) {
                  return _buildNoResultsState();
                }

                // ✅ Real-time list with cache
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: chats.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final chatId = chats[index].key;
                    final chat = chats[index].value as Map;
                    final meta = chat['meta'];
                    final messages = (chat['messages'] ?? {}) as Map;

                    final isDoctorInChat = meta['doctorId'] == currentUserId;
                    final peerName =
                        isDoctorInChat
                            ? meta['patientName'] ?? 'Patient'
                            : meta['doctorName'] ?? 'Doctor';
                    final peerId =
                        isDoctorInChat ? meta['patientId'] : meta['doctorId'];
                    final peerSpecialty = meta['doctorSpecialty'];
                    final peerImage =
                        meta['doctorImage'] ?? meta['patientImage'];

                    // Last message
                    String lastMessage = 'Start a conversation';
                    int lastTimestamp = meta['lastUpdated'] ?? 0;
                    String lastSender = '';

                    if (messages.isNotEmpty) {
                      final sortedMessages =
                          messages.entries.toList()..sort((a, b) {
                            final aTime = (a.value['timestamp'] ?? 0) as int;
                            final bTime = (b.value['timestamp'] ?? 0) as int;
                            return bTime.compareTo(aTime);
                          });

                      final latestMsg = sortedMessages.first.value;
                      lastMessage = latestMsg['text'] ?? '';
                      lastTimestamp = latestMsg['timestamp'] ?? lastTimestamp;
                      lastSender = latestMsg['senderId'] ?? '';
                    }

                    final formattedTime = _formatTimestamp(lastTimestamp);
                    final isLastMessageFromMe = lastSender == currentUserId;

                    // Unread count
                    final unreadCount =
                        messages.entries.where((msg) {
                          final message = msg.value;
                          return message['receiverId'] == currentUserId &&
                              message['read'] == false;
                        }).length;

                    return _ChatListItem(
                      peerName: peerName,
                      peerSpecialty: isDoctorInChat ? null : peerSpecialty,
                      peerImage: peerImage,
                      peerId: peerId,
                      lastMessage: lastMessage,
                      formattedTime: formattedTime,
                      unreadCount: unreadCount,
                      isLastMessageFromMe: isLastMessageFromMe,
                      isOnline: false,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DoctorsListScreen()),
          );
        },
        backgroundColor: const Color(0xFF00796B), // Primary teal
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.person_add_alt_1, size: 28),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.teal[300]),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.teal[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a chat with a doctor to get help',
            style: TextStyle(color: Colors.teal[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.teal[300]),
          const SizedBox(height: 16),
          Text(
            'No conversations found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.teal[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different terms',
            style: TextStyle(color: Colors.teal[500]),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _clearSearch,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF00796B),
              side: BorderSide(color: Colors.teal[700]!),
            ),
            child: const Text('Clear Search'),
          ),
        ],
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final String peerName;
  final String? peerSpecialty;
  final String? peerImage;
  final String peerId;
  final String lastMessage;
  final String formattedTime;
  final int unreadCount;
  final bool isLastMessageFromMe;
  final bool isOnline;
  final VoidCallback onTap;

  const _ChatListItem({
    required this.peerName,
    this.peerSpecialty,
    this.peerImage,
    required this.peerId,
    required this.lastMessage,
    required this.formattedTime,
    required this.unreadCount,
    required this.isLastMessageFromMe,
    required this.isOnline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:
              unreadCount > 0
                  ? Border.all(color: Colors.teal[100]!, width: 2)
                  : null,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.teal[100],
                  image:
                      peerImage != null
                          ? DecorationImage(
                            image: NetworkImage(peerImage!),
                            fit: BoxFit.cover,
                          )
                          : null,
                ),
                child:
                    peerImage == null
                        ? Icon(Icons.person, size: 24, color: Colors.teal[800])
                        : null,
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green : Colors.grey[400],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  peerName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                    color: Colors.teal[900],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formattedTime,
                style: TextStyle(
                  fontSize: 12,
                  color: unreadCount > 0 ? Colors.teal[700] : Colors.grey[500],
                  fontWeight:
                      unreadCount > 0 ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              if (peerSpecialty != null)
                Text(
                  peerSpecialty!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.teal[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 2),
              Row(
                children: [
                  if (isLastMessageFromMe)
                    Icon(Icons.done_all, size: 14, color: Colors.teal[600]),
                  if (isLastMessageFromMe) const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      lastMessage,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            unreadCount > 0
                                ? Colors.teal[800]
                                : Colors.grey[600],
                        fontWeight:
                            unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing:
              unreadCount > 0
                  ? Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00796B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                  : null,
          onTap: onTap,
        ),
      ),
    );
  }
}
