// doctors_list_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'chats.dart';

class DoctorsListScreen extends StatefulWidget {
  const DoctorsListScreen({super.key});

  @override
  State<DoctorsListScreen> createState() => _DoctorsListScreenState();
}

class _DoctorsListScreenState extends State<DoctorsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Future<void> _startChat(
    BuildContext context,
    String doctorId,
    String doctorName,
    String specialty,
    String? imageUrl,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final currentUserId = user.uid;
    final chatId = _generateChatId(currentUserId, doctorId);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // ✅ Get patient name
      final patientSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .get();
      final patientName = patientSnapshot.data()?['fullName'] ?? 'Patient';

      final chatRef = FirebaseDatabase.instance.ref('chats/$chatId');

      // Save/update chat metadata
      await chatRef.child('meta').update({
        'doctorId': doctorId,
        'patientId': currentUserId,
        'doctorName': doctorName,
        'patientName': patientName,
        'doctorSpecialty': specialty,
        'doctorImage': imageUrl,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });

      // Check if chat already has messag

      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();

      // ✅ Navigate to chat screen
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => ChatScreen(
                  chatId: chatId,
                  currentUserId: currentUserId,
                  peerName: doctorName,
                  peerId: doctorId,
                ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _generateChatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  bool _matchesSearch(Map<String, dynamic> doctor) {
    if (_searchQuery.isEmpty) return true;

    final query = _searchQuery.toLowerCase();
    final name = (doctor['name'] ?? '').toLowerCase();
    final specialty = (doctor['specialty'] ?? '').toLowerCase();

    return name.contains(query) || specialty.contains(query);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Available Doctors',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name or specialty...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: _clearSearch,
                          )
                          : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim();
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
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.blue[50],
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: _clearSearch,
                  ),
                ],
              ),
            ),

          // Doctors List
          Expanded(
            child: Container(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isEqualTo: 'doctor')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load doctors',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              // Retry logic if needed
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.medical_services_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No doctors available',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  // Filter doctors based on search
                  final filteredDoctors =
                      docs.where((doc) {
                        final doctor = doc.data() as Map<String, dynamic>;
                        return _matchesSearch(doctor);
                      }).toList();

                  // Show no results message
                  if (filteredDoctors.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No doctors found for "$_searchQuery"',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try searching with different terms',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _clearSearch,
                            child: const Text('Clear Search'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredDoctors.length,
                    separatorBuilder:
                        (context, index) => const SizedBox(height: 1),
                    itemBuilder: (context, index) {
                      final doc = filteredDoctors[index];
                      final doctor = doc.data() as Map<String, dynamic>;
                      final doctorId = doc.id;
                      final name = doctor['name'] ?? 'Dr. Unknown';
                      final specialty =
                          doctor['specialty'] ?? 'General Practitioner';
                      final imageUrl = doctor['imageUrl'];
                      final experience = doctor['experience'];
                      final rating = doctor['rating']?.toDouble();
                      final patients = doctor['patients'];

                      return DoctorCard(
                        name: name,
                        specialty: specialty,
                        imageUrl: imageUrl,
                        experience: experience,
                        rating: rating,
                        patients: patients,
                        searchQuery: _searchQuery,
                        onChatPressed:
                            () => _startChat(
                              context,
                              doctorId,
                              name,
                              specialty,
                              imageUrl,
                            ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DoctorCard extends StatelessWidget {
  final String name;
  final String specialty;
  final String? imageUrl;
  final int? experience;
  final double? rating;
  final int? patients;
  final String searchQuery;
  final VoidCallback onChatPressed;

  const DoctorCard({
    super.key,
    required this.name,
    required this.specialty,
    this.imageUrl,
    this.experience,
    this.rating,
    this.patients,
    required this.searchQuery,
    required this.onChatPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            // Doctor Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.teal[100],
                image:
                    imageUrl != null
                        ? DecorationImage(
                          image: NetworkImage(imageUrl!),
                          fit: BoxFit.cover,
                        )
                        : null,
              ),
              child:
                  imageUrl == null
                      ? Icon(Icons.person, size: 25, color: Colors.blue[800])
                      : null,
            ),
            const SizedBox(width: 16),

            // Doctor Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Highlighted Name
                  _buildHighlightedText(
                    text: name,
                    highlight: searchQuery,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Highlighted Specialty
                  _buildHighlightedText(
                    text: specialty,
                    highlight: searchQuery,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),

                  // Additional Info
                  Row(
                    children:
                        [
                          if (experience != null)
                            _buildInfoItem(
                              Icons.work_outline,
                              '$experience+ years',
                            ),
                          if (rating != null)
                            _buildInfoItem(
                              Icons.star,
                              rating!.toStringAsFixed(1),
                            ),
                          if (patients != null)
                            _buildInfoItem(
                              Icons.people_outline,
                              _formatPatients(patients!),
                            ),
                        ].whereType<Widget>().toList(),
                  ),
                ],
              ),
            ),

            // Chat Button
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: onChatPressed,
                icon: Icon(
                  Icons.chat_outlined,
                  color: Colors.blue[800],
                  size: 20,
                ),
                tooltip: 'Start Chat',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedText({
    required String text,
    required String highlight,
    required TextStyle style,
  }) {
    if (highlight.isEmpty) {
      return Text(text, style: style);
    }

    final matches = highlight.toLowerCase();
    final textLower = text.toLowerCase();
    final matchesIndices = <int>[];

    int startIndex = 0;
    while (startIndex < textLower.length) {
      final index = textLower.indexOf(matches, startIndex);
      if (index == -1) break;
      matchesIndices.addAll(List.generate(matches.length, (i) => index + i));
      startIndex = index + matches.length;
    }

    return RichText(
      text: TextSpan(
        children:
            text.split('').asMap().entries.map((entry) {
              final index = entry.key;
              final character = entry.value;

              return TextSpan(
                text: character,
                style:
                    matchesIndices.contains(index)
                        ? style.copyWith(
                          backgroundColor: Colors.yellow,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        )
                        : style,
              );
            }).toList(),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  String _formatPatients(int patients) {
    if (patients >= 1000) {
      return '${(patients / 1000).toStringAsFixed(1)}k';
    }
    return patients.toString();
  }
}
