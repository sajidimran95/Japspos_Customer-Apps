import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../state/cart_state.dart';
import '../../widgets/common.dart';
import '../scan/scan_screen.dart';
import '../shell/shell_screen.dart';
import 'catalog_sheet.dart';
import 'order_detail_screen.dart';

class OrderCreateTab extends StatefulWidget {
  const OrderCreateTab({super.key});
  @override
  State<OrderCreateTab> createState() => _OrderCreateTabState();
}

class _OrderCreateTabState extends State<OrderCreateTab> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<Product>? _results;
  OrderCreateData? _data;
  bool _submitting = false;

  static const _fulfillment = ['Pickup', 'Delivery', 'Shipping'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final d = await context.read<AppState>().repo.orderCreateData();
      if (!mounted) return;
      final cart = context.read<CartState>();
      if (cart.locationId == null || !d.locations.any((l) => l.id == cart.locationId)) {
        cart.setLocation(d.defaultLocationId ?? (d.locations.isEmpty ? null : d.locations.first.id));
      }
      if (cart.isEmpty) cart.setFulfillment(_fulfillment.contains(d.defaultFulfillment) ? d.defaultFulfillment : 'Delivery');
      setState(() => _data = d);
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => _runSearch(q));
  }

  Future<void> _runSearch(String q) async {
    q = q.trim();
    if (q.isEmpty) {
      setState(() => _results = null);
      return;
    }
    try {
      final rows = await context.read<AppState>().repo.products(q: q, locationId: context.read<CartState>().locationId);
      if (!mounted || _search.text.trim() != q) return;
      // An exact SKU/barcode match goes straight into the cart, like the portal.
      if (rows.length == 1 && rows.first.sku.toLowerCase() == q.toLowerCase()) {
        _add(rows.first);
        _search.clear();
        setState(() => _results = null);
        return;
      }
      setState(() => _results = rows);
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  void _add(Product p) {
    context.read<CartState>().add(p);
    showAddedPill(context);
  }

  Future<void> _scan() async {
    final code = await scanBarcode(context);
    if (code == null || !mounted) return;
    _search.text = code;
    _runSearch(code);
  }

  Future<void> _submit() async {
    final cart = context.read<CartState>();
    final app = context.read<AppState>();
    final loc = cart.locationId ?? _data?.defaultLocationId;
    if (loc == null) {
      toast(context, 'Invalid location.', success: false);
      return;
    }
    setState(() => _submitting = true);
    try {
      final res = await app.repo.placeOrder(OrderInput(
        locationId: loc,
        shippingMethod: cart.fulfillment,
        shippingAddress: _data?.shippingAddress ?? '',
        lines: List.of(cart.lines),
      ));
      if (!mounted) return;
      cart.clear();
      app.goTab(CaTab.orders);
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: res.order.id, flash: res.message)));
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();
    final c = context.watch<AppState>().customer;
    final locs = _data?.locations ?? const <StoreLocation>[];
    return TabScroll(children: [
      PageTitle(
        title: 'Create Order',
        sub: c?.initials,
        trailing: GestureDetector(
          onTap: _scan,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [CaColors.rose500, Color(0xFFBE123C)]),
              boxShadow: const [BoxShadow(color: Color(0x4DF43F5E), blurRadius: 14, offset: Offset(0, 6))],
            ),
            child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
          ),
        ),
      ),
      Row(children: [
        for (final f in _fulfillment) ...[
          Expanded(child: FulfillButton(label: f.toUpperCase(), on: cart.fulfillment == f, onTap: () => cart.setFulfillment(f))),
          if (f != _fulfillment.last) const SizedBox(width: 8),
        ],
      ]),
      const SizedBox(height: 12),
      if (locs.isNotEmpty) ...[
        CaSelect<int>(value: cart.locationId, items: {for (final l in locs) l.id: l.label}, onChanged: (v) => cart.setLocation(v)),
        const SizedBox(height: 12),
      ],
      CaSearchField(controller: _search, hint: 'Enter Product Name / SKU', onChanged: _onSearch, onSubmitted: _runSearch),
      const SizedBox(height: 12),
      if (_results != null) ...[
        if (_results!.isEmpty) const EmptyCard('No products', padding: 16),
        for (final p in _results!)
          CaCard(
            margin: const EdgeInsets.only(bottom: 8),
            onTap: () {
              _add(p);
              _search.clear();
              setState(() => _results = null);
            },
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              Text('${money(p.price)} · SKU ${p.sku.isEmpty ? '-' : p.sku}', style: const TextStyle(fontSize: 12, color: CaColors.slate500)),
            ]),
          ),
        const SizedBox(height: 4),
      ],
      Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Added Items', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            Text.rich(TextSpan(text: 'Total : ', style: const TextStyle(fontSize: 14, color: CaColors.slate500), children: [
              TextSpan(text: money(cart.total), style: const TextStyle(fontWeight: FontWeight.w700, color: CaColors.slate800)),
            ])),
          ]),
        ),
        GestureDetector(
          onTap: () => showCatalogSheet(context),
          child: const Text('Product Catalog', style: TextStyle(color: CaColors.brand, fontWeight: FontWeight.w800, fontSize: 14)),
        ),
        const SizedBox(width: 12),
        IconButton(
          tooltip: 'Clear',
          onPressed: cart.isEmpty ? null : cart.clear,
          icon: const Icon(Icons.delete_outline, color: CaColors.slate400),
        ),
      ]),
      const SizedBox(height: 8),
      if (cart.isEmpty)
        CaCard(
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
          child: Column(children: [
            const Text('🛒', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            const Text('Ready to create your order?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 4),
            const Text('Search, scan, or open Product Catalog.', style: TextStyle(fontSize: 14, color: CaColors.slate500)),
            const SizedBox(height: 16),
            SizedBox(width: 200, child: CaButton(label: 'Browse Catalog', compact: true, onPressed: () => showCatalogSheet(context))),
          ]),
        )
      else
        for (final l in cart.lines)
          CaCard(
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.product.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(money(l.product.price), style: const TextStyle(fontSize: 12, color: CaColors.slate500)),
                ]),
              ),
              _qtyBtn('−', () => cart.change(l, -1)),
              SizedBox(width: 30, child: Text('${l.qty}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800))),
              _qtyBtn('+', () => cart.change(l, 1)),
            ]),
          ),
      const SizedBox(height: 16),
      CaButton(label: 'SUBMIT', busy: _submitting, onPressed: cart.isEmpty ? null : _submit),
    ]);
  }

  Widget _qtyBtn(String t, VoidCallback onTap) => Material(
        color: CaColors.slate100,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: SizedBox(width: 32, height: 32, child: Center(child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)))),
        ),
      );
}

/// `.fulfill-opt` toggle (PICKUP / DELIVERY / SHIPPING).
class FulfillButton extends StatelessWidget {
  const FulfillButton({super.key, required this.label, required this.on, this.onTap, this.icon, this.readOnly = false});
  final String label;
  final bool on;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool readOnly;
  @override
  Widget build(BuildContext context) => Opacity(
        opacity: readOnly && !on ? .55 : 1,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              gradient: on && !readOnly ? CaColors.brandGradient : null,
              color: on ? (readOnly ? CaColors.red600 : null) : const Color(0xF2FFFFFF),
              borderRadius: BorderRadius.circular(readOnly ? 12 : 16),
              border: Border.all(color: on ? Colors.transparent : (readOnly ? CaColors.slate200 : CaColors.line)),
              boxShadow: on && !readOnly ? const [BoxShadow(color: Color(0x40E11D48), blurRadius: 22, offset: Offset(0, 10))] : null,
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, size: 18, color: on ? Colors.white : CaColors.muted), const SizedBox(height: 4)],
              Text(label, style: display(size: 11, color: on ? Colors.white : CaColors.muted)),
            ]),
          ),
        ),
      );
}
