import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_hospital/screens/patient/payments/payfast.dart';
import 'package:e_hospital/screens/patient/payments/payfast_web.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class BillingAndPaymentScreen extends StatefulWidget {
  const BillingAndPaymentScreen({super.key});

  @override
  State<BillingAndPaymentScreen> createState() =>
      _BillingAndPaymentScreenState();
}

class _BillingAndPaymentScreenState extends State<BillingAndPaymentScreen> {
  final Map<String, bool> selectedBills = {};

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
        backgroundColor: const Color(0xFF00796B), // 🌿 Teal
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
                color: const Color(0xFF004D40), // darker teal
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

                  final bills = snapshot.data!.docs;

                  double totalSelected = 0.0;
                  for (var doc in bills) {
                    final id = doc.id;
                    final data = doc.data() as Map<String, dynamic>;
                    final amount = (data['amount'] ?? 0).toDouble();
                    if (selectedBills[id] == true &&
                        data['status'] == 'Unpaid') {
                      totalSelected += amount;
                    }
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          itemCount: bills.length,
                          separatorBuilder:
                              (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final doc = bills[index];
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

                            return CheckboxListTile(
                              value: isSelected,
                              onChanged:
                                  data['status'] == 'Paid'
                                      ? null
                                      : (val) {
                                        setState(() {
                                          selectedBills[docId] = val ?? false;
                                        });
                                      },
                              title: Text(
                                data['title'] ?? 'No Title',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      data['status'] == 'Paid'
                                          ? Colors.green.shade700
                                          : Colors.black87,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    'Amount: R${amount.toStringAsFixed(2)}',
                                    style: textTheme.bodyMedium,
                                  ),
                                  Text(
                                    'Date: $dateStr',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              secondary: Icon(
                                Icons.receipt_long,
                                size: 32,
                                color:
                                    data['status'] == 'Paid'
                                        ? Colors.green
                                        : Colors.red,
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                              activeColor: const Color(0xFF00796B), // teal
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50, // light teal background
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
                                color: const Color(0xFF00796B), // teal
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              totalSelected == 0.0
                                  ? null
                                  : () {
                                    final url = PayFastService.createPaymentUrl(
                                      amount: totalSelected,
                                      itemName: "Billing Payment",
                                    );

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                PayFastWebView(url: url),
                                      ),
                                    );
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
                            backgroundColor: const Color(0xFF00796B), // teal
                            disabledBackgroundColor: Colors.teal.shade50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
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
