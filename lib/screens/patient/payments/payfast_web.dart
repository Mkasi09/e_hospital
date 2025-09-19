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
              onNavigationRequest: (request) {
                final url = request.url;

                if (url.contains('return')) {
                  Navigator.pop(context, true); // payment success
                  return NavigationDecision.prevent;
                }
                if (url.contains('cancel')) {
                  Navigator.pop(context, false); // payment canceled
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
              onWebResourceError: (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Failed to load payment page: ${error.description}',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.url)); // pass Uri here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pay with PayFast")),
      body: WebViewWidget(controller: _controller),
    );
  }
}
