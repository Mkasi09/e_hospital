import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_hospital/screens/patient/payments/payfast.dart';
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

class _BillingAndPaymentScreenState extends State<BillingAndPaymentScreen>
    with SingleTickerProviderStateMixin {
  final Map<String, bool> selectedBills = {};
  late TabController _tabController;
  double _creditBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCreditBalance();
  }

  // Load user's credit balance
  Future<void> _loadCreditBalance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _creditBalance = (data['creditBalance'] ?? 0).toDouble();
        });
      }
    }
  }

  // Mark selected bills as Paid in Firestore and deduct from credit
  Future<void> _payWithCredit(List<String> billIds, double totalAmount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final batch = FirebaseFirestore.instance.batch();

    // Update bills status
    for (var id in billIds) {
      final ref = FirebaseFirestore.instance.collection('bills').doc(id);
      batch.update(ref, {
        'status': 'Paid',
        'paidAt': FieldValue.serverTimestamp(),
        'paymentMethod': 'Credit Balance',
      });
    }

    // Update user's credit balance
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    batch.update(userRef, {
      'creditBalance': FieldValue.increment(-totalAmount),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    await _loadCreditBalance(); // Refresh balance
  }

  // Add credit to user's balance
  Future<void> _addCredit(double amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final paid = await PayFastService.initiatePayment(
      context: context,
      amount: amount,
    );

    if (paid == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'creditBalance': FieldValue.increment(amount),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      await _loadCreditBalance(); // Refresh balance

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successfully added R${amount.toStringAsFixed(2)} credit!',
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: const Text(
                'Billing & Payments',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              centerTitle: true,
              backgroundColor: const Color(0xFF00796B),
              elevation: 0,
              pinned: true,
              floating: true,
              snap: true,
              expandedHeight: 200.0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: const Color(0xFF00796B),
                  padding: const EdgeInsets.only(top: kToolbarHeight + 20),
                  child: _buildCreditBalanceCard(isDark),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.7),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                tabs: const [Tab(text: 'Outstanding'), Tab(text: 'History')],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Outstanding Bills Tab
            _buildOutstandingTab(isDark),
            // History Tab
            _buildHistoryTab(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditBalanceCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.teal.shade600, Colors.teal.shade800],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Credit Balance',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'R${_creditBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showAddCreditDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.teal.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Add Credit',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutstandingTab(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('bills')
              .where(
                'userId',
                isEqualTo: FirebaseAuth.instance.currentUser?.uid,
              )
              .where('status', isNotEqualTo: 'Paid')
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade700),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            isDark,
            'No Outstanding Bills',
            'All your bills are settled',
            Icons.check_circle_outline,
          );
        }

        final outstandingBills = snapshot.data!.docs;
        double totalSelected = 0.0;
        for (var doc in outstandingBills) {
          final id = doc.id;
          final data = doc.data() as Map<String, dynamic>;
          final amount = (data['amount'] ?? 0).toDouble();
          if (selectedBills[id] == true) {
            totalSelected += amount;
          }
        }

        return Column(
          children: [
            // Selected Bills Summary
            if (totalSelected > 0) ...[
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.teal[800] : Colors.teal[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.teal.shade200.withOpacity(0.5),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Selected Amount:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.teal[900],
                          ),
                        ),
                        Text(
                          'R${totalSelected.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.teal[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final selectedIds =
                                  outstandingBills
                                      .where(
                                        (doc) => selectedBills[doc.id] == true,
                                      )
                                      .map((doc) => doc.id)
                                      .toList();

                              if (selectedIds.isEmpty) return;

                              if (_creditBalance >= totalSelected) {
                                // Pay with credit
                                await _payWithCredit(
                                  selectedIds,
                                  totalSelected,
                                );
                                setState(() {
                                  for (var id in selectedIds) {
                                    selectedBills[id] = false;
                                  }
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Paid R${totalSelected.toStringAsFixed(2)} with credit!',
                                    ),
                                    backgroundColor: Colors.green.shade600,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } else {
                                // Insufficient credit
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Insufficient credit. Need R${(totalSelected - _creditBalance).toStringAsFixed(2)} more',
                                    ),
                                    backgroundColor: Colors.orange.shade600,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00796B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.credit_card, size: 18),
                                SizedBox(width: 8),
                                Text('Pay with Credit'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final selectedIds =
                                  outstandingBills
                                      .where(
                                        (doc) => selectedBills[doc.id] == true,
                                      )
                                      .map((doc) => doc.id)
                                      .toList();

                              if (selectedIds.isEmpty) return;

                              final paid = await PayFastService.initiatePayment(
                                context: context,
                                amount: totalSelected,
                              );

                              if (paid == true) {
                                await _payWithCredit(
                                  selectedIds,
                                  totalSelected,
                                );
                                setState(() {
                                  for (var id in selectedIds) {
                                    selectedBills[id] = false;
                                  }
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Payment successful! R${totalSelected.toStringAsFixed(2)}',
                                    ),
                                    backgroundColor: Colors.green.shade600,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.teal.shade700,
                              side: BorderSide(color: Colors.teal.shade700),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.payment, size: 18),
                                SizedBox(width: 8),
                                Text('Pay Now'),
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

            // Bills List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: outstandingBills.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildBillCard(
                      outstandingBills[index],
                      true,
                      isDark,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistoryTab(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('bills')
              .where(
                'userId',
                isEqualTo: FirebaseAuth.instance.currentUser?.uid,
              )
              .where('status', isEqualTo: 'Paid')
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade700),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            isDark,
            'No Payment History',
            'Your paid bills will appear here',
            Icons.history_toggle_off,
          );
        }

        final paidBills = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: paidBills.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildBillCard(paidBills[index], false, isDark),
            );
          },
        );
      },
    );
  }

  Widget _buildBillCard(
    QueryDocumentSnapshot doc,
    bool isOutstanding,
    bool isDark,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    final docId = doc.id;
    final isSelected = selectedBills[docId] ?? false;
    final amount = (data['amount'] ?? 0).toDouble();
    final timestamp = data['timestamp'] as Timestamp?;
    final paidAt = data['paidAt'] as Timestamp?;
    final dateStr =
        timestamp != null
            ? DateFormat('MMM dd, yyyy').format(timestamp.toDate())
            : 'Unknown date';
    final paidDateStr =
        paidAt != null
            ? DateFormat('MMM dd, yyyy').format(paidAt.toDate())
            : null;
    final title = data['title'] ?? 'No Title';
    final description = data['description'] ?? 'No description provided';
    final paymentMethod = data['paymentMethod'] ?? 'Online Payment';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border:
            isOutstanding && isSelected
                ? Border.all(color: Colors.teal.shade400, width: 2)
                : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap:
              isOutstanding
                  ? () {
                    setState(() {
                      selectedBills[docId] = !isSelected;
                    });
                  }
                  : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Status/Checkbox
                if (isOutstanding)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Colors.teal.shade500
                              : Colors.transparent,
                      border: Border.all(
                        color:
                            isSelected
                                ? Colors.teal.shade500
                                : Colors.grey.shade400,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child:
                        isSelected
                            ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                            : null,
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green.shade600,
                      size: 16,
                    ),
                  ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.grey[800],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            'R${amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                                  isOutstanding
                                      ? Colors.orange.shade700
                                      : Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOutstanding ? dateStr : paidDateStr ?? dateStr,
                            style: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          if (!isOutstanding) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.credit_card,
                              size: 12,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              paymentMethod,
                              style: TextStyle(
                                color:
                                    isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
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

  Widget _buildEmptyState(
    bool isDark,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              style: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCreditDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Credit'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select amount to add to your credit balance:'),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      [100, 200, 500, 1000].map((amount) {
                        return ChoiceChip(
                          label: Text('R$amount'),
                          selected: false,
                          onSelected: (_) {
                            Navigator.pop(context);
                            _addCredit(amount.toDouble());
                          },
                        );
                      }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }
}
