import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PayFastWebView extends StatefulWidget {
  final String url;
  const PayFastWebView({super.key, required this.url});

  @override
  State<PayFastWebView> createState() => _PayFastWebViewState();
}

class _PayFastWebViewState extends State<PayFastWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onNavigationRequest: (NavigationRequest request) {
                if (request.url.contains('yourapp.com/return')) {
                  Navigator.pop(context, true);
                  return NavigationDecision.prevent;
                } else if (request.url.contains('yourapp.com/cancel')) {
                  Navigator.pop(context, false);
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PayFast Payment'),
        backgroundColor: const Color(0xFF00796B),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
