import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'widgets/rag_chatbot_fab.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dronacharya',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.yellow),
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
  bool showOfflineScreen = false;
  
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
    allowsBackForwardNavigationGestures: true,
  );
  
  String lastFailedUrl = '';
  bool isNavigatingFromError = false;

  Future<bool> _handleBackPress() async {
    if (webViewController != null) {
      final currentUrl = await webViewController!.getUrl();
      final canGoBack = await webViewController!.canGoBack();
      
      // Check if we're on the dashboard
      final isDashboard = currentUrl?.toString().contains('/dashboard') ?? false;
      
      if (isDashboard) {
        // On dashboard, exit the app
        return true;
      } else if (canGoBack) {
        // Not on dashboard, go back in webview history
        await webViewController!.goBack();
        return false;
      } else {
        // Can't go back, navigate to dashboard
        webViewController!.loadUrl(
          urlRequest: URLRequest(
            url: WebUri('https://eklavyaa.vercel.app/dashboard'),
          ),
        );
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final shouldPop = await _handleBackPress();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
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
                
                // Add handler for Dashboard button
                controller.addJavaScriptHandler(
                  handlerName: 'goDashboard',
                  callback: (args) {
                    print('Dashboard button clicked - navigating to dashboard');
                    isNavigatingFromError = true;
                    controller.loadUrl(
                      urlRequest: URLRequest(
                        url: WebUri('https://eklavyaa.vercel.app/dashboard'),
                      ),
                    );
                    return true;
                  }
                );
              },
              onLoadStart: (controller, url) {
                print('Loading started: ${url?.toString()}');
                setState(() {
                  isLoading = true;
                });
              },
              onLoadStop: (controller, url) async {
                print('Loading finished: ${url?.toString()}');
                isNavigatingFromError = false;
                setState(() {
                  isLoading = false;
                  showOfflineWarning = false;
                  showOfflineScreen = false;
                });
              },
              onReceivedError: (controller, request, error) async {
                final url = request.url?.toString() ?? '';
                
                // Don't show error if we're navigating from error page
                if (isNavigatingFromError) {
                  print('Ignoring error during navigation from error page: $url');
                  return;
                }
                
                // Ignore errors for resources (images, css, js, fonts, gifs)
                if (url.contains('.png') || url.contains('.jpg') || 
                    url.contains('.css') || url.contains('.js') || 
                    url.contains('.woff') || url.contains('.svg') ||
                    url.contains('.gif') || url.contains('_next/image') || 
                    url.contains('avatar') || url.contains('/logo.') ||
                    url.contains('chatbase.co') || url.contains('embed.min.js')) {
                  return; // Let page continue loading without showing error
                }
                
                // Only handle main page navigation errors
                print('Showing error page for: $url - ${error.description}');
                lastFailedUrl = url;
                
                // Show custom error page
                await controller.loadData(data: '''
                  <!DOCTYPE html>
                  <html>
                  <head>
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <style>
                      * {
                        margin: 0;
                        padding: 0;
                        box-sizing: border-box;
                      }
                      body {
                        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
                        display: flex;
                        justify-content: center;
                        align-items: center;
                        min-height: 100vh;
                        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                        padding: 20px;
                      }
                      .container {
                        background: white;
                        border-radius: 20px;
                        padding: 48px 32px;
                        text-align: center;
                        max-width: 420px;
                        width: 100%;
                        box-shadow: 0 20px 60px rgba(0,0,0,0.3);
                      }
                      .icon-container {
                        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                        width: 100px;
                        height: 100px;
                        border-radius: 50%;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        margin: 0 auto 24px;
                        font-size: 50px;
                      }
                      h1 {
                        font-size: 28px;
                        color: #1a1a1a;
                        margin-bottom: 12px;
                        font-weight: 700;
                      }
                      p {
                        font-size: 16px;
                        color: #666;
                        margin-bottom: 32px;
                        line-height: 1.6;
                      }
                      .buttons {
                        display: flex;
                        flex-direction: column;
                        gap: 12px;
                      }
                      .btn {
                        padding: 16px 32px;
                        font-size: 16px;
                        border-radius: 12px;
                        cursor: pointer;
                        border: none;
                        font-weight: 600;
                        width: 100%;
                        -webkit-tap-highlight-color: transparent;
                        touch-action: manipulation;
                      }
                      .btn-primary {
                        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                        color: white;
                        box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
                      }
                      .btn-primary:active {
                        transform: scale(0.98);
                        box-shadow: 0 2px 8px rgba(102, 126, 234, 0.4);
                      }
                      .btn-secondary {
                        background: #f5f5f5;
                        color: #667eea;
                        border: 2px solid #e0e0e0;
                      }
                      .btn-secondary:active {
                        transform: translateY(2px);
                        background: #ebebeb;
                      }
                    </style>
                    <script>
                      function goDashboard() {
                        console.log('Button clicked');
                        if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                          console.log('Calling Flutter handler');
                          window.flutter_inappwebview.callHandler('goDashboard');
                        } else {
                          console.error('Flutter handler not available');
                        }
                      }
                      
                      // Ensure handler is ready
                      document.addEventListener('DOMContentLoaded', function() {
                        console.log('Page loaded, flutter_inappwebview:', window.flutter_inappwebview);
                      });
                    </script>
                  </head>
                  <body>
                    <div class="container">
                      <div class="icon-container">📡</div>
                      <h1>Connection Lost</h1>
                      <p>Unable to connect to the server. Please check your internet connection and try again.</p>
                      <div class="buttons">
                        <button class="btn btn-primary" onclick="goDashboard(); return false;">Return to Dashboard</button>
                      </div>
                    </div>
                  </body>
                  </html>
                ''');
                
                setState(() {
                  isLoading = false;
                });
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
            if (showOfflineScreen)
              Container(
                color: Colors.white,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          size: 100,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No Internet Connection',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'This feature needs an internet connection to work properly.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              showOfflineScreen = false;
                              isLoading = true;
                            });
                            webViewController?.reload();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            if (webViewController != null) {
                              webViewController!.goBack();
                              setState(() {
                                showOfflineScreen = false;
                              });
                            }
                          },
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Go Back'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
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
        floatingActionButton: const RAGChatbotFAB(),
      ),
    );
  }
}
