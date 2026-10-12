import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';

/// The store's printable invoice, rendered from its HTML.
class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key, required this.invoiceId, required this.invoiceNo});
  final int invoiceId;
  final String invoiceNo;
  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final _web = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(Colors.white);
  bool _loading = true;
  String? _error;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final app = context.read<AppState>();
      final html = await app.repo.invoiceHtml(widget.invoiceId);
      await _web.loadHtmlString(html, baseUrl: app.baseUrl);
    } catch (e) {
      _error = '$e';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _share() async {
    final app = context.read<AppState>();
    if (app.isStatic) {
      toast(context, 'PDF sharing is available when the API is active', success: false);
      return;
    }
    setState(() => _sharing = true);
    try {
      final bytes = await app.repo.invoicePdf(widget.invoiceId);
      if (bytes == null) throw 'PDF not available';
      final name = 'invoice-${widget.invoiceNo.isEmpty ? widget.invoiceId : widget.invoiceNo}.pdf';
      await Share.shareXFiles([XFile.fromData(bytes, mimeType: 'application/pdf', name: name)], fileNameOverrides: [name]);
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.invoiceNo.isEmpty ? 'Invoice' : 'Invoice ${widget.invoiceNo}'),
          actions: [
            IconButton(
              tooltip: 'Share PDF',
              onPressed: _sharing ? null : _share,
              icon: _sharing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: CaColors.brand))
                  : const Icon(Icons.ios_share),
            ),
          ],
        ),
        body: _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: CaColors.slate500)),
                    TextButton(onPressed: _load, child: const Text('Retry')),
                  ]),
                ),
              )
            : Stack(children: [
                WebViewWidget(controller: _web),
                if (_loading) const Center(child: CircularProgressIndicator(color: CaColors.brand)),
              ]),
      );
}
