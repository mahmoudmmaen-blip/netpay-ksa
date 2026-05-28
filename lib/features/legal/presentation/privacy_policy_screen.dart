import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/constants/app_constants.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// شاشة سياسة الخصوصية — تعرض HTML من الأصول أو رابط خارجي.
class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  late final WebViewController _controller;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadFlutterAsset(AppConstants.privacyPolicyAsset);
  }

  Future<void> _openExternal() async {
    final uri = Uri.parse(AppConstants.privacyPolicyUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'سياسة الخصوصية',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'فتح في المتصفح',
            onPressed: _openExternal,
            icon: const Icon(Icons.open_in_new_rounded),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Text(
            AppConstants.privacyPolicyUrl,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.emerald),
            ),
        ],
      ),
    );
  }
}
