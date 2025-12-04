import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cached WebView',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WebViewPage(),
    );
  }
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  bool isLoading = true;
  bool showOfflineWarning = false;
  
  final InAppWebViewSettings settings = InAppWebViewSettings(
    cacheEnabled: true,
    clearCache: false,
    javaScriptEnabled: true,
    domStorageEnabled: true,
    databaseEnabled: true,
    cacheMode: CacheMode.LOAD_CACHE_ELSE_NETWORK,
    allowFileAccessFromFileURLs: true,
    allowUniversalAccessFromFileURLs: true,
    mediaPlaybackRequiresUserGesture: false,
    useHybridComposition: true,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cached WebView'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                showOfflineWarning = false;
                isLoading = true;
              });
              webViewController?.reload();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            InAppWebView(
              key: webViewKey,
              initialUrlRequest: URLRequest(
                url: WebUri('https://eklavyaa.vercel.app/'),
              ),
              initialSettings: settings,
              onWebViewCreated: (controller) {
                webViewController = controller;
              },
              onLoadStart: (controller, url) {
                setState(() {
                  isLoading = true;
                });
              },
              onLoadStop: (controller, url) async {
                setState(() {
                  isLoading = false;
                  showOfflineWarning = false;
                });
              },
              onReceivedError: (controller, request, error) {
                // Check if it's an API request
                final isApiRequest = request.url?.toString().contains('/api/') == true;
                
                if (isApiRequest) {
                  // Show warning banner for API failures, but let page continue
                  setState(() {
                    showOfflineWarning = true;
                  });
                  print('API Error: ${error.description}');
                } else {
                  // For main page, just let it load from cache silently
                  setState(() {
                    isLoading = false;
                  });
                }
              },
              onReceivedHttpError: (controller, request, errorResponse) {
                // Check if it's an API request
                final isApiRequest = request.url?.toString().contains('/api/') == true;
                final statusCode = errorResponse.statusCode ?? 0;
                
                if (isApiRequest && statusCode >= 400) {
                  setState(() {
                    showOfflineWarning = true;
                  });
                }
              },
            ),
            if (isLoading)
              Container(
                color: Colors.white,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            if (showOfflineWarning)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.orange.shade100,
                  child: Row(
                    children: [
                      Icon(Icons.wifi_off, color: Colors.orange.shade800, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No internet - Some features may not work',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          setState(() {
                            showOfflineWarning = false;
                          });
                        },
                        color: Colors.orange.shade800,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
