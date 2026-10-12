import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../scan/scan_screen.dart';
import '../shell/shell_screen.dart';

class PriceCheckTab extends StatefulWidget {
  const PriceCheckTab({super.key});
  @override
  State<PriceCheckTab> createState() => _PriceCheckTabState();
}

class _PriceCheckTabState extends State<PriceCheckTab> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<StoreLocation> _locations = const [];
  int? _locationId;
  List<Product>? _results;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    try {
      final r = await context.read<AppState>().repo.locations();
      if (!mounted) return;
      setState(() {
        _locations = r.locations;
        _locationId = r.currentId ?? (r.locations.isEmpty ? null : r.locations.first.id);
      });
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => _run(q));
  }

  Future<void> _run(String q) async {
    q = q.trim();
    if (q.isEmpty) {
      setState(() => _results = null);
      return;
    }
    setState(() => _loading = true);
    try {
      final rows = await context.read<AppState>().repo.products(q: q, locationId: _locationId, limit: 30);
      if (mounted && _search.text.trim() == q) setState(() => _results = rows);
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _scan() async {
    final code = await scanBarcode(context);
    if (code == null || !mounted) return;
    _search.text = code;
    _run(code);
  }

  @override
  Widget build(BuildContext context) => TabScroll(children: [
        PageTitle(
          title: 'Price Check',
          trailing: SizedBox(width: 110, child: CaButton(label: 'SCAN', icon: Icons.qr_code_scanner, compact: true, onPressed: _scan)),
        ),
        if (_locations.isNotEmpty) ...[
          CaSelect<int>(
            value: _locationId,
            items: {for (final l in _locations) l.id: l.label},
            onChanged: (v) {
              setState(() => _locationId = v);
              _run(_search.text);
            },
          ),
          const SizedBox(height: 12),
        ],
        CaSearchField(controller: _search, hint: 'Enter Product Name / SKU', onChanged: _onSearch, onSubmitted: _run),
        const SizedBox(height: 16),
        if (_loading && _results == null)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: CaColors.brand)))
        else if (_results == null)
          const EmptyCard('Search or scan a product to see price')
        else if (_results!.isEmpty)
          const EmptyCard('No products')
        else
          for (final p in _results!)
            CaCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                ProductImage(url: p.image, size: 64, radius: 12),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, height: 1.3)),
                    const SizedBox(height: 2),
                    Text('SKU: ${p.sku.isEmpty ? '-' : p.sku}', style: const TextStyle(fontSize: 12, color: CaColors.slate500)),
                  ]),
                ),
                const SizedBox(width: 8),
                Text(money(p.price), style: display(size: 18, color: CaColors.brand)),
              ]),
            ),
      ]);
}
