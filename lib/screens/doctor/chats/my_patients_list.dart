// doctor_my_patients_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../patient/chat/chats.dart';

class MyPatientsScreen extends StatelessWidget {
  const MyPatientsScreen({super.key});

  Future<void> _startChat({
    required BuildContext context,
    required String patientId,
    required String patientName,
  }) async {
    final doctorId = FirebaseAuth.instance.currentUser!.uid;
    final chatId = _generateChatId(doctorId, patientId);

    final doctorSnapshot = await FirebaseFirestore.instance.collection('users').doc(doctorId).get();
    final doctorName = doctorSnapshot.data()?['name'] ?? 'Doctor';

    final chatMetaRef = FirebaseDatabase.instance.ref('chats/$chatId/meta');
    await chatMetaRef.set({
      'doctorId': doctorId,
      'patientId': patientId,
      'doctorName': doctorName,
      'patientName': patientName,
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatId,
          currentUserId: doctorId,
          peerName: patientName,
          peerId: patientId,
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
    final doctorId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("My Patients")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('doctorId', isEqualTo: doctorId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("No appointments found."));
          }

          // Collect unique patients
          final uniquePatients = <String, String>{}; // patientId: name
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final pid = data['patientId'];
            final pname = data['patientName'] ?? 'Patient';
            uniquePatients[pid] = pname;
          }

          return ListView.builder(
            itemCount: uniquePatients.length,
            itemBuilder: (context, index) {
              final patientId = uniquePatients.keys.elementAt(index);
              final patientName = uniquePatients[patientId]!;

              return ListTile(
                title: Text(patientName),
                subtitle: Text('Tap to start a chat'),
                trailing: ElevatedButton(
                  onPressed: () => _startChat(
                    context: context,
                    patientId: patientId,
                    patientName: patientName,
                  ),
                  child: const Text("Chat"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
