// doctors_list_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'chats.dart';


class DoctorsListScreen extends StatelessWidget {
  const DoctorsListScreen({super.key});

  Future<void> _startChat(BuildContext context, String doctorId, String doctorName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final currentUserId = user.uid;
    final chatId = _generateChatId(currentUserId, doctorId);

    // Get current patient name from Firestore
    final patientSnapshot = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
    final patientName = patientSnapshot.data()?['fullName'] ?? 'Patient';

    final chatMetaRef = FirebaseDatabase.instance.ref('chats/$chatId/meta');
    await chatMetaRef.set({
      'doctorId': doctorId,
      'patientId': currentUserId,
      'doctorName': doctorName,
      'patientName': patientName,
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatId,
          currentUserId: currentUserId,
          peerName: doctorName,
        ),
      ),
    );
  }


  String _generateChatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Doctors')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'doctor')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doctor = docs[index].data() as Map<String, dynamic>;
              final doctorId = docs[index].id;
              return ListTile(
                title: Text(doctor['name'] ?? ''),
                subtitle: Text(doctor['specialty'] ?? ''),
                trailing: ElevatedButton(
                  onPressed: () => _startChat(context, doctorId, doctor['name']),
                  child: const Text('Chat'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
