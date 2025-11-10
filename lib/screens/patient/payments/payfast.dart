import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'payfast_web.dart';

/// Handles generating PayFast URL and navigating to payment page.
class PayFastService {
  static Future<bool> initiatePayment({
    required BuildContext context,
    required double amount,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // ✅ LIVE PayFast URL
    final payfastUrl =
        'https://www.payfast.co.za/eng/process?'
        'merchant_id=21461358&'
        'merchant_key=pty7ewgdz3yqn&'
        'return_url=https://yourapp.com/return&'
        'cancel_url=https://yourapp.com/cancel&'
        'notify_url=https://yourapp.com/notify&'
        'amount=${amount.toStringAsFixed(2)}&'
        'item_name=Billing Payment&'
        'custom_str1=$userId';

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PayFastWebView(url: payfastUrl)),
    );

    // Return true if payment successful
    return result == true;
  }
}
