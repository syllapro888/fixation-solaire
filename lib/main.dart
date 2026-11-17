import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'updater.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: kGreen,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const FixationSolaireApp());
}

class FixationSolaireApp extends StatelessWidget {
  const FixationSolaireApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fixation Solaire',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: kGreen, useMaterial3: true),
      home: const CalculScreen(),
    );
  }
}

class CalculScreen extends StatefulWidget {
  const CalculScreen({super.key});

  @override
  State<CalculScreen> createState() => _CalculScreenState();
}

class _CalculScreenState extends State<CalculScreen> {
  late final WebViewController _web;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF2F4F1))
      ..addJavaScriptChannel('Natif', onMessageReceived: _onMessage)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          _web.runJavaScript(
              'window.setAppVersion && window.setAppVersion(${jsonEncode(appVersion)});');
          if (mounted) setState(() => _loading = false);
        },
        onNavigationRequest: (req) {
          // Les liens internet s'ouvrent dans le navigateur du téléphone.
          if (req.url.startsWith('http')) {
            launchUrl(Uri.parse(req.url), mode: LaunchMode.externalApplication);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadFlutterAsset('assets/app/index.html');

    // Vérification discrète des mises à jour au démarrage.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) checkForUpdate(context, silent: true);
      });
    });
  }

  Future<void> _onMessage(JavaScriptMessage m) async {
    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(m.message) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    if (!mounted) return;
    switch (msg['a']) {
      case 'update':
        await checkForUpdate(context, silent: false);
        break;
      case 'copy':
        await Clipboard.setData(ClipboardData(text: '${msg['t'] ?? ''}'));
        if (mounted) toast(context, '✅ Liste copiée');
        break;
      case 'whatsapp':
        final text = Uri.encodeComponent('${msg['t'] ?? ''}');
        final ok = await launchUrl(Uri.parse('https://wa.me/?text=$text'),
            mode: LaunchMode.externalApplication);
        if (!ok && mounted) toast(context, 'WhatsApp introuvable');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGreen,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            WebViewWidget(controller: _web),
            if (_loading)
              const ColoredBox(
                color: Color(0xFFF2F4F1),
                child: Center(child: CircularProgressIndicator(color: kGreen)),
              ),
          ],
        ),
      ),
    );
  }
}
