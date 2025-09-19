import 'dart:convert';
import 'package:crypto/crypto.dart';

class PayFastService {
  // Sandbox credentials
  static const String merchantId = "10035720";
  static const String merchantKey = "oa528zbm3y8r9";
  static const String passphrase =
      "fnnnssffbsfb"; // Sandbox passphrase is empty

  static const String returnUrl = "https://yourapp.com/success";
  static const String cancelUrl = "https://yourapp.com/cancel";
  static const String notifyUrl = "https://yourapp.com/notify";

  // Generate PayFast signature
  static String generateSignature(Map<String, String> data) {
    // 1. Sort keys alphabetically
    final sortedKeys = data.keys.toList()..sort();

    // 2. Build query string with URL-encoded values
    final paramString = sortedKeys
        .map((key) => "$key=${Uri.encodeQueryComponent(data[key]!)}")
        .join("&");

    // 3. Append passphrase only if not empty
    final stringToHash =
        passphrase.isNotEmpty
            ? "$paramString&passphrase=$passphrase"
            : paramString;

    // 4. Return MD5 hash
    return md5.convert(utf8.encode(stringToHash)).toString();
  }

  // Create sandbox payment URL
  static String createPaymentUrl({
    required double amount,
    required String itemName,
  }) {
    final data = {
      "amount": amount.toStringAsFixed(2), // must always have 2 decimals
      "item_name": itemName,
      "merchant_id": merchantId,
      "merchant_key": merchantKey,
      "return_url": returnUrl,
      "cancel_url": cancelUrl,
      "notify_url": notifyUrl,
    };

    final signature = generateSignature(data);

    final fullData = {...data, "signature": signature};

    final query = fullData.entries
        .map((e) => "${e.key}=${Uri.encodeQueryComponent(e.value)}")
        .join("&");

    return "https://sandbox.payfast.co.za/eng/process?$query";
  }
}
