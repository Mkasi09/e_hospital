import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ServiceRequestPopup {
  static Future<void> show({
    required BuildContext context,
    required String userId,
  }) async {
    final servicesSnapshot =
        await FirebaseFirestore.instance.collection('services').get();
    final services = servicesSnapshot.docs;

    await showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: _ServiceRequestDialog(services: services, userId: userId),
          ),
    );
  }
}

class _ServiceRequestDialog extends StatefulWidget {
  final List<QueryDocumentSnapshot<Object?>> services;
  final String userId;

  const _ServiceRequestDialog({required this.services, required this.userId});

  @override
  State<_ServiceRequestDialog> createState() => _ServiceRequestDialogState();
}

class _ServiceRequestDialogState extends State<_ServiceRequestDialog> {
  String? _selectedServiceId;

  Future<void> _submitRequest() async {
    if (_selectedServiceId != null) {
      final selectedService = widget.services.firstWhere(
        (doc) => doc.id == _selectedServiceId,
      );
      final serviceData = selectedService.data() as Map<String, dynamic>;

      try {
        await FirebaseFirestore.instance.collection('service_requests').add({
          'patientId': widget.userId,
          'serviceId': _selectedServiceId,
          'serviceName': serviceData['name'],
          'price': serviceData['price'],
          'status': 'pending',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Service request submitted successfully!"),
            backgroundColor: Colors.teal[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to submit request: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please select a service"),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _cancelRequest() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(1), // margin from screen edges
      backgroundColor: Colors.transparent,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ===== Header =====
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFF00796B),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.teal[100],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.medical_services,
                          size: 32,
                          color: Color(0xFF00796B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Request Medical Service',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select a service from the list below',
                        style: TextStyle(fontSize: 14, color: Colors.teal[100]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // ===== Content =====
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ===== Dropdown =====
                      DropdownButtonFormField<String>(
                        value: _selectedServiceId,
                        decoration: InputDecoration(
                          labelText: 'Select a medical service',
                          filled: true,
                          fillColor: Colors.grey[50],
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color:
                                  _selectedServiceId != null
                                      ? Colors.teal[300]!
                                      : Colors.grey[300]!,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.teal[400]!,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        items:
                            widget.services.map((service) {
                              final data =
                                  service.data() as Map<String, dynamic>;
                              final serviceName = data['name'] ?? 'Unnamed';
                              return DropdownMenuItem<String>(
                                value: service.id,
                                child: Text(serviceName),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedServiceId = value;
                          });
                        },
                        hint: const Text('Select a medical service'),
                        isExpanded: true,
                        dropdownColor: Colors.white,
                      ),

                      // ===== Combined info + price box =====
                      if (_selectedServiceId != null) ...[
                        const SizedBox(height: 16),
                        Builder(
                          builder: (context) {
                            final selectedService = widget.services.firstWhere(
                              (service) => service.id == _selectedServiceId,
                            );
                            final data =
                                selectedService.data() as Map<String, dynamic>;
                            final price = data['price'] ?? 0;
                            final description = data['description'] ?? '';

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.teal[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.teal[100]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Price row
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.attach_money,
                                        color: Colors.teal[700],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Price: R$price',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.teal[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (description.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      description,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.teal[700],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  // Info row
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.teal[700],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'This service request will be reviewed by our medical team',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.teal[700],
                                          ),
                                          softWrap: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ===== Buttons =====
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _cancelRequest,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                                side: BorderSide(color: Colors.grey[300]!),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  _selectedServiceId != null
                                      ? _submitRequest
                                      : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00796B),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Submit',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.send, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
