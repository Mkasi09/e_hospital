import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorDropdown extends StatelessWidget {
  final String? hospital;
  final String? selectedDoctor;
  final Function(String?) onDoctorSelected;

  const DoctorDropdown({
    super.key,
    required this.hospital,
    required this.selectedDoctor,
    required this.onDoctorSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (hospital == null) {
      return const SizedBox();
    }

    return FutureBuilder<List<String>>(
      future: _fetchDoctors(hospital!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: LinearProgressIndicator(),
          );
        }

        if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Text('No doctors found for this hospital'),
          );
        }

        final doctors = snapshot.data!;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: GestureDetector(
            onTap: () {
              _showDoctorPicker(context, doctors);
            },
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.medical_services, color: Colors.blueAccent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Doctor',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedDoctor ?? 'Tap to choose a doctor',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDoctorPicker(BuildContext context, List<String> doctors) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView.builder(
        itemCount: doctors.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(doctors[index]),
            onTap: () {
              Navigator.pop(context);
              onDoctorSelected(doctors[index]);
            },
          );
        },
      ),
    );
  }

  Future<List<String>> _fetchDoctors(String hospitalName) async {
    final doc = await FirebaseFirestore.instance
        .collection('hospitals')
        .where('name', isEqualTo: hospitalName)
        .limit(1)
        .get();

    if (doc.docs.isNotEmpty) {
      return List<String>.from(doc.docs.first.data()['doctors']);
    }

    return [];
  }
}
