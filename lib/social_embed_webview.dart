library social_embed_webview;

import 'package:flutter/material.dart';
import 'package:social_embed_webview/platforms/social-media-generic.dart';
import 'package:social_embed_webview/utils/common-utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io';

class SocialEmbed extends StatefulWidget {
  final SocialMediaGenericEmbedData socialMediaObj;
  final Color? backgroundColor;
  const SocialEmbed({Key? key, required this.socialMediaObj, this.backgroundColor}) : super(key: key);

  @override
  _SocialEmbedState createState() => _SocialEmbedState();
}

class _SocialEmbedState extends State<SocialEmbed> with WidgetsBindingObserver {
  double _height = 300;
  late final WebViewController wbController;
  late String htmlBody;

  @override
  void initState() {
    super.initState();
    // htmlBody = ;
    if (widget.socialMediaObj.supportMediaControll) WidgetsBinding.instance.addObserver(this);

    wbController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(Platform.isIOS ? "Mozilla/5.0 (iPhone; CPU iPhone OS 11_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E217" : "Mozilla/5.0 (Linux; Android 5.1.1; Android SDK built for x86 Build/LMY48X) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/39.0.0.0 Mobile Safari/537.36")
      ..addJavaScriptChannel('PageHeight', onMessageReceived: (JavaScriptMessage message) {
        _setHeight(double.parse(message.message));
      })
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (navigation) async {
            final url = navigation.url;
            if (navigation.isMainFrame && await canLaunch(url)) {
              launch(url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (url) {
            final color = colorToHtmlRGBA(getBackgroundColor(context));
            wbController.runJavaScript('document.body.style= "background-color: $color"');
            if (widget.socialMediaObj.aspectRatio == null) wbController.runJavaScript('setTimeout(() => sendHeight(), 0)');
          },
        ),
      )
      ..loadRequest(htmlToURI(getHtmlBody()));
  }

  @override
  void dispose() {
    if (widget.socialMediaObj.supportMediaControll) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.detached:
        wbController.runJavaScript(widget.socialMediaObj.stopVideoScript);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        wbController.runJavaScript(widget.socialMediaObj.pauseVideoScript);
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final wv = WebViewWidget(
      controller: wbController,
      // initialUrl: htmlToURI(getHtmlBody()),
      // userAgent: Platform.isIOS ? "Mozilla/5.0 (iPhone; CPU iPhone OS 11_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E217" : "Mozilla/5.0 (Linux; Android 5.1.1; Android SDK built for x86 Build/LMY48X) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/39.0.0.0 Mobile Safari/537.36",
      // javascriptChannels: <JavascriptChannel>[
      //   _getHeightJavascriptChannel()
      // ].toSet(),
      // javascriptMode: JavascriptMode.unrestricted,
      // initialMediaPlaybackPolicy: AutoMediaPlaybackPolicy.always_allow,
      // onWebViewCreated: (wbc) {
      //   wbController = wbc;
      // },
      // onPageFinished: (str) {
      //   final color = colorToHtmlRGBA(getBackgroundColor(context));
      //   wbController.runJavaScript('document.body.style= "background-color: $color"');
      //   if (widget.socialMediaObj.aspectRatio == null) wbController.runJavaScript('setTimeout(() => sendHeight(), 0)');
      // },
      // navigationDelegate: (navigation) async {
      //   final url = navigation.url;
      //   if (navigation.isForMainFrame && await canLaunch(url)) {
      //     launch(url);
      //     return NavigationDecision.prevent;
      //   }
      //   return NavigationDecision.navigate;
      // },
    );
    final ar = widget.socialMediaObj.aspectRatio;
    return (ar != null)
        ? ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height / 1.5,
              maxWidth: double.infinity,
            ),
            child: AspectRatio(aspectRatio: ar, child: wv),
          )
        : SizedBox(height: _height, child: wv);
  }

  // JavascriptChannel _getHeightJavascriptChannel() {
  //   return JavascriptChannel(
  //       name: 'PageHeight',
  //       onMessageReceived: (JavascriptMessage message) {
  //         _setHeight(double.parse(message.message));
  //       });
  // }

  void _setHeight(double height) {
    setState(() {
      _height = height + widget.socialMediaObj.bottomMargin;
    });
  }

  Color getBackgroundColor(BuildContext context) {
    return widget.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;
  }

  String getHtmlBody() => """
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
            *{box-sizing: border-box;margin:0px; padding:0px;}
              #widget {
                        display: flex;
                        justify-content: center;
                        margin: 0 auto;
                        max-width:100%;
                    }      
          </style>
        </head>
        <body>
          <div id="widget" style="${widget.socialMediaObj.htmlInlineStyling}">${widget.socialMediaObj.htmlBody}</div>
          ${(widget.socialMediaObj.aspectRatio == null) ? dynamicHeightScriptSetup : ''}
          ${(widget.socialMediaObj.canChangeSize) ? dynamicHeightScriptCheck : ''}
        </body>
      </html>
    """;

  static const String dynamicHeightScriptSetup = """
    <script type="text/javascript">
      const widget = document.getElementById('widget');
      const sendHeight = () => PageHeight.postMessage(widget.clientHeight);
    </script>
  """;

  static const String dynamicHeightScriptCheck = """
    <script type="text/javascript">
      const onWidgetResize = (widgets) => sendHeight();
      const resize_ob = new ResizeObserver(onWidgetResize);
      resize_ob.observe(widget);
    </script>
  """;
}
