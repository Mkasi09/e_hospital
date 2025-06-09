import 'package:flutter/material.dart';

class ChatsScreen extends StatelessWidget {
  final List<Map<String, String>> chats = [
    {
      'doctorName': 'Dr. Smith',
      'lastMessage': 'Please take rest and stay hydrated.',
      'time': '10:45 AM',
      'avatarUrl': 'https://example.com/doctor1.jpg',
    },
    {
      'doctorName': 'Dr. Johnson',
      'lastMessage': 'Have you taken your medication?',
      'time': 'Yesterday',
      'avatarUrl': 'https://example.com/doctor2.jpg',
    },
    {
      'doctorName': 'Dr. Lee',
      'lastMessage': 'Schedule a follow-up visit next week.',
      'time': 'Mon',
      'avatarUrl': 'https://example.com/doctor3.jpg',
    },
  ];

  ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats with Doctors'),
      ),
      body: ListView.separated(
        itemCount: chats.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final chat = chats[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(chat['avatarUrl']!),
            ),
            title: Text(chat['doctorName']!),
            subtitle: Text(
              chat['lastMessage']!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              chat['time']!,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            onTap: () {
              // TODO: Navigate to chat with this doctor
              // Navigator.push(context, MaterialPageRoute(builder: (_) => ChatWithDoctorScreen()));
            },
          );
        },
      ),
    );
  }
}
