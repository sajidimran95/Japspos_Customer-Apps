import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../state/cart_state.dart';
import '../../widgets/common.dart';

/// Product Catalog bottom sheet: Categories › Sub-categories › Products.
Future<void> showCatalogSheet(BuildContext context) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x730F172A),
      builder: (_) => const _CatalogSheet(),
    );

class _Level {
  _Level.cats() : title = 'Categories', kind = 'cats', category = null, subId = 0;
  _Level.subs(Category c) : title = c.name, kind = 'subs', category = c, subId = 0;
  _Level.products(this.title, this.category, this.subId) : kind = 'products';
  final String title;
  final String kind;
  final Category? category;
  final int subId;
}

class _CatalogSheet extends StatefulWidget {
  const _CatalogSheet();
  @override
  State<_CatalogSheet> createState() => _CatalogSheetState();
}

class _CatalogSheetState extends State<_CatalogSheet> {
  final List<_Level> _stack = [_Level.cats()];
  late final Future<List<Category>> _tree = context.read<AppState>().repo.categories();
  Future<List<Product>>? _products;

  void _push(_Level l) {
    setState(() {
      _stack.add(l);
      if (l.kind == 'products') _loadProducts(l);
    });
  }

  void _loadProducts(_Level l) {
    _products = context.read<AppState>().repo.products(
          locationId: context.read<CartState>().locationId,
          limit: 80,
          categoryId: l.subId == 0 ? (l.category?.id ?? 0) : 0,
          subCategoryId: l.subId,
        );
  }

  void _back() => setState(() {
        _stack.removeLast();
        if (_stack.last.kind == 'products') _loadProducts(_stack.last);
      });

  @override
  Widget build(BuildContext context) {
    final state = _stack.last;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .88),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Color(0x2E0F172A), blurRadius: 40, offset: Offset(0, -12))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: CaColors.line))),
          child: Row(children: [
            Visibility(
              visible: _stack.length > 1,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: _headBtn(Icons.chevron_left, _back),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(state.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: display(size: 16))),
            _headBtn(Icons.close, () => Navigator.pop(context)),
          ]),
        ),
        Flexible(child: _body(state)),
      ]),
    );
  }

  Widget _headBtn(IconData icon, VoidCallback onTap) => Material(
        color: CaColors.slate100,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(borderRadius: BorderRadius.circular(12), onTap: onTap, child: SizedBox(width: 36, height: 36, child: Icon(icon, size: 20, color: CaColors.ink))),
      );

  Widget _list(List<Widget> rows) => ListView(
        shrinkWrap: true,
        padding: EdgeInsets.only(top: 4, bottom: 24 + MediaQuery.of(context).padding.bottom),
        children: rows,
      );

  Widget _msg(String t) => Padding(padding: const EdgeInsets.all(16), child: Text(t, style: const TextStyle(color: CaColors.slate400, fontSize: 14)));

  Widget _row(String label, VoidCallback onTap, {bool all = false}) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: CaColors.slate100))),
          child: Row(children: [
            Expanded(child: Text(label, style: display(size: 15, weight: all ? FontWeight.w800 : FontWeight.w700, color: all ? CaColors.brand : CaColors.ink))),
            const Icon(Icons.chevron_right, color: CaColors.slate400),
          ]),
        ),
      );

  Widget _body(_Level state) {
    if (state.kind == 'subs') {
      final c = state.category!;
      return _list([
        _row('All in ${c.name}', () => _push(_Level.products(c.name, c, 0)), all: true),
        for (final s in c.subs) _row(s.name, () => _push(_Level.products(s.name, c, s.id))),
      ]);
    }
    if (state.kind == 'products') {
      return FutureBuilder<List<Product>>(
        future: _products,
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) return _msg('Loading…');
          final rows = snap.data ?? const <Product>[];
          if (rows.isEmpty) return _msg(snap.hasError ? '${snap.error}' : 'No products');
          return Consumer<CartState>(
            builder: (_, cart, _) => _list(rows.map((p) => _productRow(p, cart)).toList()),
          );
        },
      );
    }
    return FutureBuilder<List<Category>>(
      future: _tree,
      builder: (_, snap) {
        if (snap.connectionState != ConnectionState.done) return _msg('Loading…');
        final tree = snap.data ?? const <Category>[];
        if (tree.isEmpty) return _msg(snap.hasError ? '${snap.error}' : 'No categories');
        return _list([
          for (final c in tree) _row(c.name, () => _push(c.subs.isEmpty ? _Level.products(c.name, c, 0) : _Level.subs(c))),
        ]);
      },
    );
  }

  Widget _productRow(Product p, CartState cart) {
    final qty = cart.qtyOf(p.variationId);
    return InkWell(
      onTap: () {
        cart.add(p);
        showAddedPill(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: CaColors.slate100))),
        child: Row(children: [
          ProductImage(url: p.image, size: 48, radius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              Text('${money(p.price)}${p.sku.isEmpty ? '' : ' · ${p.sku}'}', style: const TextStyle(fontSize: 12, color: CaColors.slate500)),
            ]),
          ),
          const SizedBox(width: 12),
          Container(
            constraints: const BoxConstraints(minWidth: 36),
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              gradient: CaColors.brandGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Color(0x40E11D48), blurRadius: 16, offset: Offset(0, 8))],
            ),
            alignment: Alignment.center,
            child: Text(qty == 0 ? '+' : '$qty', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
          ),
        ]),
      ),
    );
  }
}
