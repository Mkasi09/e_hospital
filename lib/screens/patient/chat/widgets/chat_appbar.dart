import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

import '../../../doctor/patients/doctors_patient_history_screen.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String peerId;
  final String peerName;

  const ChatAppBar({super.key, required this.peerId, required this.peerName});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
      iconTheme: const IconThemeData(color: Colors.black),
      title: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('status/$peerId').onValue,
        builder: (context, snapshot) {
          String statusText = 'Offline';
          TextStyle statusStyle = const TextStyle(fontSize: 12, color: Colors.grey);

          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
            if (data['online'] == true) {
              statusText = 'Online';
              statusStyle = const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500);
            } else if (data.containsKey('lastSeen')) {
              final lastSeen = DateTime.fromMillisecondsSinceEpoch(data['lastSeen']);
              final formatted = DateFormat('MMM dd, hh:mm a').format(lastSeen);
              statusText = 'Last seen: $formatted';
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(peerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
              Text(statusText, style: statusStyle),
            ],
          );
        },
      ),
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            // Handle menu option selected
            switch (value) {
              case 'view_profile':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserDetailsScreen(userId: peerId),
                  ),
                );
                break;
              case 'block_user':
              // Block logic
                break;
              case 'delete_chat':
              // Delete chat logic
                break;
            }
          },
          icon: const Icon(Icons.more_vert, color: Colors.black),
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem(
              value: 'view_profile',
              child: Text('View Profile'),
            ),
            const PopupMenuItem(
              value: 'block_user',
              child: Text('Block User'),
            ),
            const PopupMenuItem(
              value: 'delete_chat',
              child: Text('Delete Chat'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
