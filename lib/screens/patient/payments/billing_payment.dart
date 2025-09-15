import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

void main() {
  runApp(const MaterialApp(home: BillingAndPaymentScreen()));
}

class BillingAndPaymentScreen extends StatefulWidget {
  const BillingAndPaymentScreen({super.key});

  @override
  State<BillingAndPaymentScreen> createState() =>
      _BillingAndPaymentScreenState();
}

class _BillingAndPaymentScreenState extends State<BillingAndPaymentScreen> {
  final Map<String, bool> selectedBills = {};
  bool _isProcessing = false;

  // PAYFAST SANDBOX SETTINGS - UPDATED WITH PASSPHRASE
  static const String merchantId = "10000100";
  static const String merchantKey = "46f0cd694581a";
  static const String passphrase =
      "jt7NOE43FZPn"; // Added passphrase from Python code
  static const String returnUrl = "https://www.yourdomain.com/success";
  static const String cancelUrl = "https://www.yourdomain.com/cancel";
  static const String notifyUrl = "https://www.yourdomain.com/notify";

  String generateSignature(Map<String, dynamic> data) {
    final filtered = Map.fromEntries(
      data.entries.where(
        (e) =>
            e.value != null &&
            e.value.toString().isNotEmpty &&
            e.key != 'signature',
      ),
    );

    final sortedKeys = filtered.keys.toList()..sort();

    final paramString = sortedKeys
        .map((key) {
          final value = filtered[key].toString();
          final encoded = Uri.encodeQueryComponent(
            value,
          ).replaceAll('%20', '+');
          return "$key=$encoded";
        })
        .join("&");

    final stringToHash =
        "$paramString&passphrase=${Uri.encodeQueryComponent(passphrase).replaceAll('%20', '+')}";

    final signature = md5.convert(utf8.encode(stringToHash)).toString();

    debugPrint("---- PayFast Signature Debug ----");
    debugPrint("Param String: $paramString");
    debugPrint("String to Hash: $stringToHash");
    debugPrint("Generated Signature: $signature");
    debugPrint("--------------------------------");

    return signature;
  }

  String createPayFastUrl({required double amount, required String itemName}) {
    final user = FirebaseAuth.instance.currentUser;

    // Generate unique payment ID
    final paymentId =
        "${DateTime.now().millisecondsSinceEpoch}${user?.uid.substring(0, 5)}";

    // Determine first & last name
    final displayName = (user?.displayName ?? "").trim();
    String firstName;
    String lastName;
    if (displayName.isNotEmpty) {
      final parts = displayName.split(" ");
      firstName = parts.first;
      lastName = parts.length > 1 ? parts.sublist(1).join(" ") : "User";
    } else {
      final email = user?.email ?? "user@example.com";
      firstName = email.split("@").first;
      lastName = "User";
    }

    final formattedAmount = amount.toStringAsFixed(2);

    // Build PayFast data map
    final data = {
      "amount": formattedAmount,
      "cancel_url": cancelUrl,
      "email_address": user?.email ?? "user@example.com",
      "item_name": itemName,
      "m_payment_id": paymentId,
      "merchant_id": merchantId,
      "merchant_key": merchantKey,
      "name_first": firstName,
      "name_last": lastName,
      "notify_url": notifyUrl,
      "return_url": returnUrl,
    };

    // Generate correct signature
    final signature = generateSignature(data);

    // Build URL parameters for GET request (URL-encoded)
    final urlParams = data.entries
        .map(
          (e) =>
              "${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}",
        )
        .join("&");

    return "https://sandbox.payfast.co.za/eng/process?$urlParams&signature=$signature";
  }

  // Open PayFast WebView
  void openPayFastWebView(double amount, List<String> billIds) {
    setState(() {
      _isProcessing = true;
    });

    final url = createPayFastUrl(amount: 200.00, itemName: "Billing Payment");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => Scaffold(
              appBar: AppBar(
                title: const Text("Pay with PayFast"),
                backgroundColor: const Color(0xFF00796B),
              ),
              body: WebViewWidget(
                controller:
                    WebViewController()
                      ..setJavaScriptMode(JavaScriptMode.unrestricted)
                      ..setNavigationDelegate(
                        NavigationDelegate(
                          onNavigationRequest: (request) {
                            debugPrint("Navigation to: ${request.url}");

                            if (request.url.contains(returnUrl) ||
                                request.url.contains(
                                  "payfast.co.za/eng/process/return",
                                )) {
                              _updateBillStatus(billIds);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Payment successful!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              return NavigationDecision.prevent;
                            } else if (request.url.contains(cancelUrl)) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Payment cancelled.'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return NavigationDecision.prevent;
                            }
                            return NavigationDecision.navigate;
                          },
                          onPageStarted: (url) {
                            debugPrint('Page started loading: $url');
                          },
                          onPageFinished: (url) {
                            debugPrint('Page finished loading: $url');
                          },
                          onWebResourceError: (error) {
                            debugPrint(
                              'Web resource error: ${error.description}',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Payment error: ${error.description}',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            Navigator.pop(context);
                            setState(() {
                              _isProcessing = false;
                            });
                          },
                        ),
                      )
                      ..loadRequest(Uri.parse(url)),
              ),
            ),
      ),
    ).then((_) {
      setState(() {
        _isProcessing = false;
      });
    });
  }

  // Update Firestore bill status
  Future<void> _updateBillStatus(List<String> billIds) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (var id in billIds) {
        batch.update(FirebaseFirestore.instance.collection('bills').doc(id), {
          'status': 'Paid',
          'paidDate': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      setState(() {
        selectedBills.clear();
      });
    } catch (e) {
      debugPrint("Error updating bill status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error updating payment status.'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No billing records found.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final bills = snapshot.data!.docs;
                  double totalSelected = 0.0;
                  List<String> selectedBillIds = [];

                  for (var doc in bills) {
                    final id = doc.id;
                    final data = doc.data() as Map<String, dynamic>;
                    final amount = (data['amount'] ?? 0).toDouble();
                    if (selectedBills[id] == true &&
                        data['status'] == 'Unpaid') {
                      totalSelected += amount;
                      selectedBillIds.add(id);
                    }
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          itemCount: bills.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
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
                            final isPaid = data['status'] == 'Paid';

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: CheckboxListTile(
                                value: isSelected,
                                onChanged:
                                    isPaid
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
                                        isPaid
                                            ? Colors.green.shade700
                                            : Colors.black87,
                                    decoration:
                                        isPaid
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
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
                                    if (isPaid)
                                      Text(
                                        'Paid',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                                secondary: Icon(
                                  Icons.receipt_long,
                                  size: 32,
                                  color: isPaid ? Colors.green : Colors.red,
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                activeColor: const Color(0xFF00796B),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
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
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              totalSelected == 0.0 || _isProcessing
                                  ? null
                                  : () {
                                    openPayFastWebView(
                                      totalSelected,
                                      selectedBillIds,
                                    );
                                  },
                          icon: const Icon(
                            Icons.payment,
                            color: Color(0xFFE0F2F1),
                          ),
                          label: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child:
                                _isProcessing
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                    : const Text(
                                      'Pay Selected',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00796B),
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
