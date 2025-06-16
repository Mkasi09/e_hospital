import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorDropdown extends StatefulWidget {
  final String? hospital;
  final Map<String, String>? selectedDoctor; // {id: "...", name: "Dr. A", specialty: "Cardiology"}
  final Function(Map<String, String>?) onDoctorSelected;

  const DoctorDropdown({
    Key? key,
    required this.hospital,
    required this.selectedDoctor,
    required this.onDoctorSelected,
  }) : super(key: key);

  @override
  State<DoctorDropdown> createState() => _DoctorDropdownState();
}

class _DoctorDropdownState extends State<DoctorDropdown> {
  List<Map<String, String>> _allDoctors = [];

  @override
  Widget build(BuildContext context) {
    if (widget.hospital == null || widget.hospital!.isEmpty) {
      return const SizedBox();
    }

    return FutureBuilder<List<Map<String, String>>>(
      future: _fetchDoctors(widget.hospital!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: LinearProgressIndicator(),
          );
        }

        if (snapshot.hasError || snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Text('No doctors found for this hospital'),
          );
        }

        _allDoctors = snapshot.data!;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
            color: Theme
                .of(context)
                .colorScheme
                .surface,
          ),
          child: GestureDetector(
            onTap: () => _showDoctorPicker(context),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                      Icons.medical_services, color: Colors.blueAccent),
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
                        widget.selectedDoctor != null
                            ? '${widget.selectedDoctor!['name']} - ${widget
                            .selectedDoctor!['specialty']}'
                            : 'Tap to choose a doctor',
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

  void _showDoctorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        TextEditingController searchController = TextEditingController();
        List<Map<String, String>> filteredDoctors = List.from(_allDoctors);

        return StatefulBuilder(
          builder: (context, setState) {
            void _filterDoctors(String query) {
              setState(() {
                filteredDoctors = _allDoctors.where((doctor) {
                  final name = doctor['name']!.toLowerCase();
                  final specialty = doctor['specialty']!.toLowerCase();
                  return name.contains(query.toLowerCase()) ||
                      specialty.contains(query.toLowerCase());
                }).toList();
              });
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: MediaQuery
                      .of(context)
                      .size
                      .height * 0.7,
                  child: Column(
                    children: [
                      TextField(
                        controller: searchController,
                        onChanged: _filterDoctors,
                        decoration: InputDecoration(
                          hintText: 'Search by name or specialty',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredDoctors.length,
                          itemBuilder: (context, index) {
                            final doctor = filteredDoctors[index];
                            return ListTile(
                              title: Text(doctor['name'] ?? ''),
                              subtitle: Text(doctor['specialty'] ?? ''),
                              onTap: () {
                                Navigator.pop(context);
                                widget.onDoctorSelected(doctor);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, String>>> _fetchDoctors(String hospitalName) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .where('hospitalName', isEqualTo: hospitalName)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      final id = doc.id;
      final name = data['name'];
      final specialty = data['specialty'];
      if (name != null) {
        return {
          'id': id.toString(),
          'name': name.toString(),
          'specialty': (specialty ?? 'Unknown').toString(),
        };
      }
      return null;
    }).whereType<Map<String, String>>().toList();
  }
}