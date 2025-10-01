import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HospitalDropdown extends StatelessWidget {
  final String? selectedHospital;
  final Function(String, List<Map<String, String>>) onHospitalSelected;

  const HospitalDropdown({
    super.key,
    required this.selectedHospital,
    required this.onHospitalSelected,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: selectedHospital);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.local_hospital, color: Colors.blueAccent),
          ),
          const SizedBox(width: 14),
         Expanded(
            child: TypeAheadFormField<String>(
              textFieldConfiguration: TextFieldConfiguration(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Search Hospital',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              suggestionsCallback: (pattern) async {
                if (pattern.isEmpty) return [];
                final snapshot =
                    await FirebaseFirestore.instance
                        .collection('hospitals')
                        .where('name', isGreaterThanOrEqualTo: pattern)
                        .where('name', isLessThan: pattern + 'z')
                        .get();

                return snapshot.docs
                    .map((doc) => doc['name'] as String)
                    .toList();
              },
              itemBuilder:
                  (context, suggestion) => ListTile(title: Text(suggestion)),
              onSuggestionSelected: (selected) async {
                final hospitalQuery =
                    await FirebaseFirestore.instance
                        .collection('hospitals')
                        .where('name', isEqualTo: selected)
                        .limit(1)
                        .get();

                if (hospitalQuery.docs.isNotEmpty) {
                  final hospitalDoc = hospitalQuery.docs.first;
                  final hospitalName = hospitalDoc['name'];

                  // Now fetch doctors where hospitalId matches this hospital
                  final doctorsQuery =
                      await FirebaseFirestore.instance
                          .collection('doctors')
                          .where('hospitalId', isEqualTo: hospitalDoc.id)
                          .get();

                  final doctorsList =
                      doctorsQuery.docs.map((doc) {
                        final data = doc.data();
                        return {
                          'doctorId': data['doctorId'] as String,
                          'name': data['name'] as String,
                          'specialty': data['specialty'] as String,
                        };
                      }).toList();

                  onHospitalSelected(hospitalName, doctorsList);
                }
              },
              noItemsFoundBuilder:
                  (context) => const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('No hospital found.'),
                  ),
              validator:
                  (value) => value!.isEmpty ? 'Please select a hospital' : null,
            ),
          ),
        ],
      ),
    );
  }
}
