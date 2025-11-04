import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:e_hospital/screens/patient/payments/payfast_web.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BillingAndPaymentScreen extends StatefulWidget {
  const BillingAndPaymentScreen({super.key});

  @override
  State<BillingAndPaymentScreen> createState() =>
      _BillingAndPaymentScreenState();
}

class _BillingAndPaymentScreenState extends State<BillingAndPaymentScreen> {
  final Map<String, bool> selectedBills = {};

  // Mark selected bills as Paid in Firestore
  Future<void> _markBillsAsPaid(List<String> billIds) async {
    final batch = FirebaseFirestore.instance.batch();
    for (var id in billIds) {
      final ref = FirebaseFirestore.instance.collection('bills').doc(id);
      batch.update(ref, {'status': 'Paid'});
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Billing & Payment',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF00796B),
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Billing Summary',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF004D40),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('bills')
                        .where(
                          'userId',
                          isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                        )
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'No billing records found.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    );
                  }

                  // Separate bills by status
                  final bills = snapshot.data!.docs;
                  final outstandingBills =
                      bills.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return (data['status'] ?? 'Unpaid') != 'Paid';
                      }).toList();

                  final paidBills =
                      bills.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return (data['status'] ?? 'Unpaid') == 'Paid';
                      }).toList();

                  // Calculate total selected
                  double totalSelected = 0.0;
                  for (var doc in outstandingBills) {
                    final id = doc.id;
                    final data = doc.data() as Map<String, dynamic>;
                    final amount = (data['amount'] ?? 0).toDouble();
                    if (selectedBills[id] == true) {
                      totalSelected += amount;
                    }
                  }

                  // Function to build a list of bills
                  Widget buildBillList(List<QueryDocumentSnapshot> billsList) {
                    if (billsList.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'No bills here.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return Column(
                      children:
                          billsList.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final docId = doc.id;
                            final isSelected = selectedBills[docId] ?? false;
                            final amount = (data['amount'] ?? 0).toDouble();
                            final timestamp = data['timestamp'] as Timestamp?;
                            final dateStr =
                                timestamp != null
                                    ? DateFormat.yMMMd().format(
                                      timestamp.toDate(),
                                    )
                                    : 'Unknown date';

                            return ExpansionTile(
                              title: Text(
                                data['title'] ?? 'No Title',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      data['status'] == 'Paid'
                                          ? Colors.green.shade700
                                          : Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                'Amount: R${amount.toStringAsFixed(2)} | Date: $dateStr',
                                style: const TextStyle(fontSize: 14),
                              ),
                              leading:
                                  data['status'] == 'Paid'
                                      ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      )
                                      : Checkbox(
                                        value: isSelected,
                                        onChanged: (val) {
                                          setState(() {
                                            selectedBills[docId] = val ?? false;
                                          });
                                        },
                                      ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Bill ID: $docId',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      data['status'] == 'Paid'
                                          ? const Text(
                                            'Paid',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                          : const SizedBox.shrink(),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                    );
                  }

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        // Outstanding Bills
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Outstanding Bills',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        buildBillList(outstandingBills),
                        const SizedBox(height: 20),
                        // Paid Bills
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Paid Bills',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        buildBillList(paidBills),
                        const SizedBox(height: 20),

                        // Total Selected and Pay button
                        if (totalSelected > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.teal.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Selected:',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'R${totalSelected.toStringAsFixed(2)}',
                                  style: textTheme.titleLarge?.copyWith(
                                    color: const Color(0xFF00796B),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),
                        if (totalSelected > 0)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final selectedIds =
                                    outstandingBills
                                        .where(
                                          (doc) =>
                                              selectedBills[doc.id] == true,
                                        )
                                        .map((doc) => doc.id)
                                        .toList();

                                if (selectedIds.isEmpty) return;

                                final payfastUrl =
                                    'https://sandbox.payfast.co.za/eng/process?' +
                                    'merchant_id=10000100&' +
                                    'merchant_key=46f0cd694581a&' +
                                    'return_url=https://yourapp.com/return&' +
                                    'cancel_url=https://yourapp.com/cancel&' +
                                    'notify_url=https://yourapp.com/notify&' +
                                    'amount=${totalSelected.toStringAsFixed(2)}&' +
                                    'item_name=Billing Payment&' +
                                    'custom_str1=${FirebaseAuth.instance.currentUser?.uid ?? ''}';

                                final paid = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            PayFastWebView(url: payfastUrl),
                                  ),
                                );

                                if (paid == true) {
                                  await _markBillsAsPaid(selectedIds);
                                  setState(() {
                                    for (var id in selectedIds) {
                                      selectedBills[id] = false;
                                    }
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Payment successful!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(
                                Icons.payment,
                                color: Color(0xFFE0F2F1),
                              ),
                              label: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Text(
                                  'Pay Selected',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00796B),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}
