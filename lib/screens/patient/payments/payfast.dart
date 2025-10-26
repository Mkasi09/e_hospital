import 'dart:convert';
import 'package:crypto/crypto.dart';

class PayFastService {
  // 🔴 LIVE CREDENTIALS
  static const String merchantId = "21461358";
  static const String merchantKey = "pty7ewgdz3yqn";
  static const String passphrase = ""; // live passphrase

  // ✅ Redirect URLs — replace with your real hosted URLs
  static const String returnUrl = "https://yourapp.com/success";
  static const String cancelUrl = "https://yourapp.com/cancel";
  static const String notifyUrl = "https://yourapp.com/notify";

  // ✅ Generate PayFast signature (MD5)
  static String generateSignature(Map<String, String> data) {
    final sortedKeys = data.keys.toList()..sort();

    final paramString = sortedKeys
        .map((key) => "$key=${Uri.encodeQueryComponent(data[key]!)}")
        .join("&");

    final stringToHash = passphrase.isNotEmpty
        ? "$paramString&passphrase=$passphrase"
        : paramString;

    return md5.convert(utf8.encode(stringToHash)).toString();
  }

  // ✅ Create LIVE PayFast payment URL
  static String createPaymentUrl({
    required double amount,
    required String itemName,
    String? buyerEmail,
    String? buyerName,
  }) {
    final data = {
      "merchant_id": merchantId,
      "merchant_key": merchantKey,
      "return_url": returnUrl,
      "cancel_url": cancelUrl,
      "notify_url": notifyUrl,
      "amount": amount.toStringAsFixed(2),
      "item_name": itemName,
      if (buyerEmail != null) "email_address": buyerEmail,
      if (buyerName != null) "name_first": buyerName,
    };

    final signature = generateSignature(data);
    final fullData = {...data, "signature": signature};

    final query = fullData.entries
        .map((e) => "${e.key}=${Uri.encodeQueryComponent(e.value)}")
        .join("&");

    // 🔴 LIVE endpoint for real transactions
    return "https://www.payfast.co.za/eng/process?$query";
  }
}
