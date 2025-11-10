import 'package:e_hospital/screens/patient/chat/service/chat_service.dart';
import 'package:e_hospital/screens/patient/chat/widgets/chat_appbar.dart';
import 'package:e_hospital/screens/patient/chat/widgets/message_bubble.dart';
import 'package:e_hospital/screens/patient/chat/widgets/message_input_field.dart';
import 'package:e_hospital/screens/patient/chat/widgets/typing_indicator.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String peerName;
  final String peerId;
  final String? peerSpecialty;
  final String? peerImage;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.peerId,
    required this.peerName,
    this.peerSpecialty,
    this.peerImage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    ChatService.markMessagesAsRead(widget.chatId, widget.currentUserId);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    ChatService.setTypingStatus(widget.chatId, widget.currentUserId, false);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.teal[50]!.withOpacity(0.3), Colors.grey[50]!],
                ),
              ),
              child: StreamBuilder<DatabaseEvent>(
                stream:
                    FirebaseDatabase.instance
                        .ref('chats/${widget.chatId}/messages')
                        .orderByChild('timestamp')
                        .onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingState();
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.snapshot.value == null) {
                    return _buildEmptyState();
                  }

                  final messages = Map<String, dynamic>.from(
                    snapshot.data!.snapshot.value as Map,
                  );
                  final sorted =
                      messages.entries.toList()..sort(
                        (a, b) => (a.value['timestamp'] as int).compareTo(
                          b.value['timestamp'] as int,
                        ),
                      );

                  return StreamBuilder<DatabaseEvent>(
                    stream:
                        FirebaseDatabase.instance
                            .ref(
                              'chats/${widget.chatId}/typing/${widget.peerId}',
                            )
                            .onValue,
                    builder: (context, typingSnapshot) {
                      final isTyping =
                          typingSnapshot.hasData &&
                          typingSnapshot.data!.snapshot.value == true;

                      return Column(
                        children: [
                          // Date Header
                          if (sorted.isNotEmpty)
                            _buildDateHeader(
                              sorted.first.value['timestamp'] as int,
                            ),

                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: sorted.length + (isTyping ? 1 : 0),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (context, index) {
                                if (index < sorted.length) {
                                  final messageEntry = sorted[index];
                                  final messageKey =
                                      messageEntry.key; // Get the message key
                                  final msg = Map<String, dynamic>.from(
                                    messageEntry.value,
                                  );

                                  // Show date header for new days
                                  if (index > 0) {
                                    final prevEntry = sorted[index - 1];
                                    final prevMsg = Map<String, dynamic>.from(
                                      prevEntry.value,
                                    );
                                    if (_isDifferentDay(
                                      prevMsg['timestamp'] as int,
                                      msg['timestamp'] as int,
                                    )) {
                                      return Column(
                                        children: [
                                          _buildDateHeader(
                                            msg['timestamp'] as int,
                                          ),
                                          MessageBubble(
                                            message: msg,
                                            isMe:
                                                msg['senderId'] ==
                                                widget.currentUserId,
                                            messageId: messageKey,
                                            onReport:
                                                () => _showReportDialog(
                                                  messageKey,
                                                  msg,
                                                ),
                                            onLongPress:
                                                () {}, // Handled internally
                                            isDeleted: msg['deleted'] == true,
                                            isReported: _isMessageReported(
                                              messageKey,
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                  }

                                  return MessageBubble(
                                    message: msg,
                                    isMe:
                                        msg['senderId'] == widget.currentUserId,
                                    messageId: messageKey,
                                    onReport:
                                        () =>
                                            _showReportDialog(messageKey, msg),
                                    onLongPress: () {}, // Handled internally
                                    isDeleted: msg['deleted'] == true,
                                    isReported: _isMessageReported(messageKey),
                                  );
                                } else {
                                  return const TypingIndicator();
                                }
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
          MessageInputField(
            controller: _messageController,
            chatId: widget.chatId,
            currentUserId: widget.currentUserId,
            peerId: widget.peerId,
            scrollController: _scrollController,
            focusNode: _focusNode,
          ),
        ],
      ),
    );
  }

  // Check if a message is reported
  bool _isMessageReported(String messageId) {
    // You'll need to implement this based on your reports structure
    // For now, return false - you can implement this later
    return false;
  }

  // Enhanced Report Dialog with reasons
  void _showReportDialog(String messageId, Map<String, dynamic> message) {
    final reasons = [
      'Inappropriate content',
      'Harassment or bullying',
      'Spam or misleading information',
      'Privacy violation',
      'Medical misinformation',
      'Other',
    ];

    String? selectedReason;
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.flag, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Report Message'),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Message:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          message['text']?.toString() ?? '',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Select reason:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...reasons
                          .map(
                            (reason) => RadioListTile<String>(
                              title: Text(reason),
                              value: reason,
                              groupValue: selectedReason,
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedReason = value;
                                });
                              },
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          )
                          .toList(),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Additional details (optional)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed:
                        selectedReason == null
                            ? null
                            : () {
                              _submitReport(
                                messageId,
                                message,
                                selectedReason!,
                                descriptionController.text,
                              );
                              Navigator.pop(context);
                            },
                    child: const Text(
                      'Report',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }

  // Submit report to Firebase
  void _submitReport(
    String messageId,
    Map<String, dynamic> message,
    String reason,
    String description,
  ) async {
    try {
      final reportData = {
        'messageId': messageId,
        'messageText': message['text']?.toString() ?? '',
        'senderId': message['senderId']?.toString() ?? '',
        'senderName':
            message['senderId'] == widget.currentUserId
                ? 'You'
                : widget.peerName,
        'reportedBy': widget.currentUserId,
        'reportedByName': 'User', // You might want to get the actual user name
        'reason': reason,
        'description': description,
        'timestamp': ServerValue.timestamp,
        'status': 'pending',
        'chatId': widget.chatId,
      };

      await _databaseRef
          .child('reports')
          .child(widget.chatId)
          .child(messageId)
          .set(reportData);

      // Also add to chat's reports for easy access
      await _databaseRef
          .child('chats')
          .child(widget.chatId)
          .child('reports')
          .child(messageId)
          .set(reportData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message reported successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to report message: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, size: 24),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          // Peer Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.teal[100],
              image:
                  widget.peerImage != null
                      ? DecorationImage(
                        image: NetworkImage(widget.peerImage!),
                        fit: BoxFit.cover,
                      )
                      : null,
            ),
            child:
                widget.peerImage == null
                    ? Icon(Icons.person, size: 20, color: Colors.teal[800])
                    : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.peerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.peerSpecialty != null)
                  Text(
                    widget.peerSpecialty!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.teal[100],
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Online Status Indicator
        StreamBuilder<DatabaseEvent>(
          stream:
              FirebaseDatabase.instance
                  .ref('status/${widget.peerId}/online')
                  .onValue,
          builder: (context, snapshot) {
            final isOnline = snapshot.data?.snapshot.value == true;
            return Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isOnline ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isOnline ? 'Online' : 'Offline',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDateHeader(int timestamp) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.teal[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _formatDate(timestamp),
        style: TextStyle(
          color: Colors.teal[800],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, yyyy').format(date);
    }
  }

  bool _isDifferentDay(int timestamp1, int timestamp2) {
    final date1 = DateTime.fromMillisecondsSinceEpoch(timestamp1);
    final date2 = DateTime.fromMillisecondsSinceEpoch(timestamp2);

    return date1.year != date2.year ||
        date1.month != date2.month ||
        date1.day != date2.day;
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.teal[700]!),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading messages...',
            style: TextStyle(color: Colors.teal[700], fontSize: 16),
          ),
        ],
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
            'Start the conversation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.teal[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to begin your chat',
            style: TextStyle(color: Colors.teal[500]),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.teal[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.teal[100]!),
            ),
            child: Column(
              children: [
                Icon(Icons.medical_services, size: 32, color: Colors.teal[600]),
                const SizedBox(height: 8),
                Text(
                  'Medical Chat',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.teal[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You can discuss your health concerns here',
                  style: TextStyle(fontSize: 12, color: Colors.teal[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
