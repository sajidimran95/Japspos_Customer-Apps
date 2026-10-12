import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../state/cart_state.dart';
import '../../widgets/common.dart';
import '../shell/shell_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late Future<HomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AppState>().repo.home();
  }

  Future<void> _reload() async {
    setState(() => _future = context.read<AppState>().repo.home());
    await _future;
  }

  /// Home "+" opens Create Order with the product already in the cart.
  void _addToOrder(Product p) {
    context.read<CartState>().add(p);
    context.read<AppState>().goTab(CaTab.order);
    showAddedPill(context);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final c = app.customer;
    return AsyncView<HomeData>(
      future: _future,
      onRetry: _reload,
      builder: (_, d) => TabScroll(onRefresh: _reload, children: [
        const Text('WELCOME BACK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: CaColors.brand, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(app.businessName, style: display(size: 26, height: 1.15)),
        const SizedBox(height: 4),
        Text(c?.contactId ?? '', style: const TextStyle(color: CaColors.muted, fontSize: 14, fontWeight: FontWeight.w600)),
        if (d.location != null) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xCCFFFFFF),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: CaColors.slate200),
                boxShadow: const [BoxShadow(color: Color(0x0A0F172A), blurRadius: 4)],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.location_on, size: 14, color: CaColors.brand),
                const SizedBox(width: 5),
                Text(d.location!.city.isEmpty || d.location!.city == d.location!.label ? d.location!.label : '${d.location!.label} · ${d.location!.city}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CaColors.slate600)),
              ]),
            ),
          ),
        ],
        const SizedBox(height: 20),
        _balanceCards(d.balanceDue, c),
        const SizedBox(height: 24),
        SectionHeader(title: 'New Arrivals', action: 'SEE ALL', onAction: () => app.goTab(CaTab.order)),
        if (d.newArrivals.isEmpty) const EmptyCard('No products yet', padding: 32),
        for (final p in d.newArrivals) _arrivalRow(p),
        const SizedBox(height: 24),
        SectionHeader(title: 'Top Products', action: 'SEE ALL', onAction: () => app.goTab(CaTab.order)),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: .72,
          children: d.topProducts.map(_topTile).toList(),
        ),
      ]),
    );
  }

  Widget _balanceCards(double due, Customer? c) {
    final current = CaCard(
      clip: true,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(
          right: -40,
          top: -40,
          child: Container(width: 96, height: 96, decoration: const BoxDecoration(color: Color(0x1AE11D48), shape: BoxShape.circle)),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Current Balance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CaColors.slate500)),
          const SizedBox(height: 8),
          Text(money(due), style: display(size: 30)),
        ]),
      ]),
    );
    final due2 = CaCard(
      child: Column(children: [
        Row(children: [
          const Expanded(child: Text('Due Balance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CaColors.slate500))),
          Text(money(due), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: CaColors.brand)),
        ]),
        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: CaColors.slate100)),
        Row(children: [
          const Expanded(child: Text('Customer ID', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CaColors.slate500))),
          Text(c == null ? '' : (c.contactId.isEmpty ? '${c.id}' : c.contactId), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        ]),
      ]),
    );
    return LayoutBuilder(builder: (_, box) {
      if (box.maxWidth >= 600) {
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: current), const SizedBox(width: 12), Expanded(child: due2)]);
      }
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [current, const SizedBox(height: 12), due2]);
    });
  }

  Widget _arrivalRow(Product p) => CaCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          ProductImage(url: p.image, size: 64),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, height: 1.3)),
              const SizedBox(height: 2),
              Text('SKU: ${p.sku}', style: const TextStyle(fontSize: 12, color: CaColors.slate500, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(money(p.price), style: display(size: 15, color: CaColors.brand)),
            ]),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _addToOrder(p),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [CaColors.rose500, CaColors.brandDark]),
                boxShadow: [BoxShadow(color: Color(0x4DE11D48), blurRadius: 20, offset: Offset(0, 10))],
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ]),
      );

  Widget _topTile(Product p) => CaCard(
        padding: const EdgeInsets.all(10),
        onTap: () => _addToOrder(p),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AspectRatio(aspectRatio: 1, child: ProductImage(url: p.image)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, height: 1.3)),
          ),
          const Spacer(),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(money(p.price), style: display(size: 14, color: CaColors.brand))),
        ]),
      );
}
