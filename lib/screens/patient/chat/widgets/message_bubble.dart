import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final String messageId;
  final void Function() onReport;
  final void Function() onLongPress;
  final bool isDeleted;
  final bool isReported;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.messageId,
    required this.onReport,
    required this.onLongPress,
    this.isDeleted = false,
    this.isReported = false,
  });

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return DateFormat('HH:mm').format(date);
    }
    return DateFormat('MMM dd, HH:mm').format(date);
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Message preview
                if (!isDeleted)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isMe ? Icons.outgoing_mail : Icons.mail_lock,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message['text']?.toString() ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Options List
                ListTile(
                  leading: const Icon(Icons.content_copy),
                  title: const Text('Copy Text'),
                  onTap: () {
                    Navigator.pop(context);
                    _copyToClipboard(context);
                  },
                ),

                if (!isMe && !isDeleted) ...[
                  ListTile(
                    leading: const Icon(Icons.flag, color: Colors.orange),
                    title: const Text('Report Message'),
                    onTap: () {
                      Navigator.pop(context);
                      onReport();
                    },
                  ),
                ],

                if (isMe && !isDeleted) ...[
                  ListTile(
                    leading: const Icon(Icons.edit, color: Colors.blue),
                    title: const Text('Edit Message'),
                    onTap: () {
                      Navigator.pop(context);
                      _editMessage(context);
                    },
                  ),
                ],

                ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.grey),
                  title: const Text('Message Info'),
                  onTap: () {
                    Navigator.pop(context);
                    _showMessageInfo(context);
                  },
                ),

                if (isMe) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    title: const Text('Delete Message'),
                    onTap: () {
                      Navigator.pop(context);
                      _showDeleteConfirmation(context);
                    },
                  ),
                ],

                const Divider(),
                ListTile(
                  leading: const Icon(Icons.cancel),
                  title: const Text('Cancel'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    final text = message['text']?.toString() ?? '';
    // Use Clipboard.setData(ClipboardData(text: text)) in real implementation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _editMessage(BuildContext context) {
    // Implement edit message functionality
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Message'),
            content: TextField(
              controller: TextEditingController(
                text: message['text']?.toString() ?? '',
              ),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Edit your message...',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // Implement message update logic
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Message updated')),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showMessageInfo(BuildContext context) {
    final timestamp = message['timestamp'];
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Message Information'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Type', message['type']?.toString() ?? 'text'),
                _buildInfoRow(
                  'Sent',
                  DateFormat('MMM dd, yyyy - HH:mm').format(date),
                ),
                if (message['read'] == true) _buildInfoRow('Read', 'Yes'),
                if (message['edited'] == true) _buildInfoRow('Edited', 'Yes'),
                if (isDeleted) _buildInfoRow('Status', 'Deleted by admin'),
                if (isReported) _buildInfoRow('Status', 'Reported'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Message'),
            content: const Text(
              'Are you sure you want to delete this message?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Implement delete logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Message deleted')),
                  );
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = message['type'] == 'image' && message['imageUrl'] != null;
    final isDeleted = message['deleted'] == true;
    final isReported = message['reported'] == true;

    return GestureDetector(
      onLongPress: () => _showMessageOptions(context),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMe) ...[
                // Sender avatar for received messages
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, size: 18, color: Colors.grey[600]),
                ),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Message content
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            isDeleted
                                ? Colors.grey[100]
                                : isMe
                                ? Colors.blue[50]
                                : Colors.grey[200],
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft:
                              isMe
                                  ? const Radius.circular(16)
                                  : const Radius.circular(4),
                          bottomRight:
                              isMe
                                  ? const Radius.circular(4)
                                  : const Radius.circular(16),
                        ),
                        border: Border.all(
                          color:
                              isReported
                                  ? Colors.orange
                                  : isDeleted
                                  ? Colors.grey[400]!
                                  : isMe
                                  ? Colors.blue[200]!
                                  : Colors.grey[300]!,
                          width: isReported ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image message
                          if (hasImage && !isDeleted)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                message['imageUrl'],
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                                loadingBuilder: (
                                  context,
                                  child,
                                  loadingProgress,
                                ) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: double.infinity,
                                    height: 200,
                                    color: Colors.grey[300],
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value:
                                            loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: double.infinity,
                                    height: 200,
                                    color: Colors.grey[300],
                                    child: const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Failed to load image',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),

                          // Text message or deleted placeholder
                          if ((message['text'] != null &&
                                  message['text'].toString().isNotEmpty) ||
                              isDeleted)
                            Padding(
                              padding: EdgeInsets.only(
                                top: hasImage && !isDeleted ? 8 : 0,
                              ),
                              child: Text(
                                isDeleted
                                    ? '[Message deleted by admin]'
                                    : message['text'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontStyle:
                                      isDeleted
                                          ? FontStyle.italic
                                          : FontStyle.normal,
                                  color:
                                      isDeleted
                                          ? Colors.grey[600]
                                          : Colors.black87,
                                ),
                              ),
                            ),

                          // File attachment
                          if (message['type'] == 'file' &&
                              message['fileName'] != null &&
                              !isDeleted)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getFileIcon(message['fileName']),
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message['fileName'],
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (message['fileSize'] != null)
                                          Text(
                                            _formatFileSize(
                                              message['fileSize'],
                                            ),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Timestamp and status row
                    Padding(
                      padding: const EdgeInsets.only(top: 4, right: 8, left: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTimestamp(message['timestamp']),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 4),

                          // Status icons
                          if (isMe && !isDeleted) ...[
                            Icon(
                              message['read'] == true
                                  ? Icons.done_all
                                  : Icons.done,
                              size: 12,
                              color:
                                  message['read'] == true
                                      ? Colors.blue
                                      : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                          ],

                          if (isReported) ...[
                            Icon(Icons.flag, size: 12, color: Colors.orange),
                            const SizedBox(width: 4),
                          ],

                          if (isDeleted) ...[
                            Icon(
                              Icons.delete_outline,
                              size: 12,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                          ],

                          if (message['edited'] == true) ...[
                            Text(
                              'edited',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (isMe) ...[
                // Sender avatar for sent messages
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, size: 18, color: Colors.blue[800]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(dynamic fileSize) {
    if (fileSize == null) return '';

    final size =
        fileSize is int ? fileSize : int.tryParse(fileSize.toString()) ?? 0;

    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
