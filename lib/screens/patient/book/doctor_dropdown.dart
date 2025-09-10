import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(
    const MaterialApp(
      home: Scaffold(body: SafeArea(child: DoctorDropdownDemo())),
    ),
  );
}

class DoctorDropdownDemo extends StatefulWidget {
  const DoctorDropdownDemo({super.key});

  @override
  State<DoctorDropdownDemo> createState() => _DoctorDropdownDemoState();
}

class _DoctorDropdownDemoState extends State<DoctorDropdownDemo> {
  String? selectedHospital = "City General Hospital";
  Map<String, String>? selectedDoctor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Select a Doctor',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.teal[700],
            ),
          ),
        ),
        DoctorDropdown(
          hospital: selectedHospital,
          selectedDoctor: selectedDoctor,
          onDoctorSelected: (doctor) {
            setState(() {
              selectedDoctor = doctor;
            });
          },
        ),
        const SizedBox(height: 20),
        if (selectedDoctor != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              color: Colors.teal[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Doctor:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Name: ${selectedDoctor!['name']}'),
                    Text('Specialty: ${selectedDoctor!['specialty']}'),
                    Text('ID: ${selectedDoctor!['id']}'),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class DoctorDropdown extends StatefulWidget {
  final String? hospital;
  final Map<String, String>? selectedDoctor;
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

        if (snapshot.hasError ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
            child: Text(
              'No doctors found for this hospital',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        _allDoctors = snapshot.data!;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.teal.shade300),
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: () => _showDoctorPicker(context),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.medical_services,
                    color: Colors.teal.shade700,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Doctor',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.selectedDoctor != null
                            ? '${widget.selectedDoctor!['name']} - ${widget.selectedDoctor!['specialty']}'
                            : 'Tap to choose a doctor',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.teal.shade800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: Colors.teal.shade700),
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        TextEditingController searchController = TextEditingController();
        List<Map<String, String>> filteredDoctors = List.from(_allDoctors);

        return StatefulBuilder(
          builder: (context, setState) {
            void _filterDoctors(String query) {
              setState(() {
                filteredDoctors =
                    _allDoctors.where((doctor) {
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
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Select a Doctor',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: searchController,
                        onChanged: _filterDoctors,
                        decoration: InputDecoration(
                          hintText: 'Search by name or specialty',
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.teal.shade700,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.teal.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.teal.shade700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child:
                            filteredDoctors.isEmpty
                                ? Center(
                                  child: Text(
                                    'No doctors found',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                )
                                : ListView.builder(
                                  itemCount: filteredDoctors.length,
                                  itemBuilder: (context, index) {
                                    final doctor = filteredDoctors[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      color: Colors.teal.shade50,
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.teal.shade100,
                                          child: Icon(
                                            Icons.person,
                                            color: Colors.teal.shade700,
                                          ),
                                        ),
                                        title: Text(
                                          doctor['name'] ?? '',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal.shade800,
                                          ),
                                        ),
                                        subtitle: Text(
                                          doctor['specialty'] ?? '',
                                          style: TextStyle(
                                            color: Colors.teal.shade600,
                                          ),
                                        ),
                                        trailing: Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: Colors.teal.shade700,
                                        ),
                                        onTap: () {
                                          Navigator.pop(context);
                                          widget.onDoctorSelected(doctor);
                                        },
                                      ),
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
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'doctor')
            .where('hospitalName', isEqualTo: hospitalName)
            .get();

    return querySnapshot.docs
        .map((doc) {
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
        })
        .whereType<Map<String, String>>()
        .toList();
  }
}
