import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  }
  
  runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WebViewApp(),
    )
  );
}

class WebViewApp extends StatefulWidget {
  const WebViewApp({super.key});
  
  @override
  _WebViewAppState createState() => new _WebViewAppState();
  
}

class _WebViewAppState extends State<WebViewApp> {
  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;

  InAppWebViewGroupOptions grpOtions = InAppWebViewGroupOptions(
    crossPlatform: InAppWebViewOptions(
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: false,
      javaScriptEnabled: true
      // allowsInlineMediaPlayback: true,
      // iframeAllow: "camera; microphone",
      // iframeAllowFullscreen: true
    ),
    android: AndroidInAppWebViewOptions(
      useHybridComposition: true,
    ),
  );
  
  PullToRefreshController? pullToRefreshController;
  String url = "https://app.l1bank.com";
  double progress = 0;
  // final urlController = TextEditingController();
  
  @override
  void initState() {
    super.initState();

    pullToRefreshController = kIsWeb ? null : PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.blue,
      ),
      onRefresh: () async {
        if (defaultTargetPlatform == TargetPlatform.android) {
          webViewController?.reload();
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
              // TextField(
              //   decoration: const InputDecoration(prefixIcon: Icon(Icons.search)),
              //   controller: urlController,
              //   keyboardType: TextInputType.url,
              //   onSubmitted: (value) {
              //     var url = Uri.parse(value);
              //     if (url.scheme.isEmpty) {
              //       url = Uri.parse("https://www.google.com/search?q=$value");
              //     }
              //     webViewController?.loadUrl(urlRequest: URLRequest(url: url));
              //   },
              // ),
              Expanded(
                child: Stack(
                  children: [
                    InAppWebView(
                      key: webViewKey,
                      initialUrlRequest: URLRequest(url: Uri.parse("https://app.l1bank.com/")),
                      initialOptions: grpOtions,
                      pullToRefreshController: pullToRefreshController,
                      onWebViewCreated: (controller) {
                        webViewController = controller;
                      },
                      onLoadStart: (controller, url) {
                        setState(() {
                          this.url = url.toString();
                        });
                      },
                      // onPermissionRequest: (controller, request) async {
                      //   return PermissionResponse(
                      //       resources: request.resources,
                      //       action: PermissionResponseAction.GRANT);
                      // },
                      shouldOverrideUrlLoading:
                          (controller, navigationAction) async {
                        var uri = navigationAction.request.url!;

                        if (![
                          "http",
                          "https",
                          "file",
                          "chrome",
                          "data",
                          "javascript",
                          "about"
                        ].contains(uri.scheme)) {
                          if (await canLaunchUrl(uri)) {
                            // Launch the App
                            await launchUrl(
                              uri,
                            );
                            // and cancel the request
                            return NavigationActionPolicy.CANCEL;
                          }
                        }

                        return NavigationActionPolicy.ALLOW;
                      },
                      onLoadStop: (controller, url) async {
                        pullToRefreshController?.endRefreshing();
                        setState(() {
                          this.url = url.toString();
                          
                        });
                      },
                      onLoadError: (controller, url, code, message) {
                        pullToRefreshController?.endRefreshing();
                      },
                      onProgressChanged: (controller, progress) {
                        if (progress == 100) {
                          pullToRefreshController?.endRefreshing();
                        }
                        setState(() {
                          this.progress = progress / 100;
                        });
                      },
                      onUpdateVisitedHistory: (controller, url, androidIsReload) {
                        setState(() {
                          this.url = url.toString();
                          
                        });
                      },
                      onConsoleMessage: (controller, consoleMessage) {
                        print(consoleMessage);
                      },
                      onReceivedServerTrustAuthRequest: (controller, challenge) async {
                        print(challenge);
                        return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
                      }
                    ),
                    progress < 1.0
                        ? LinearProgressIndicator(value: progress)
                        : Container(),
                  ],
                ),
              ),
          ]
        )
      )
    );
  }
}
