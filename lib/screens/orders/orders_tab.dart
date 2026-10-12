import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../shell/shell_screen.dart';
import 'order_detail_screen.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});
  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  late Future<List<OrderRow>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AppState>().repo.orders();
  }

  Future<void> _reload() async {
    setState(() => _future = context.read<AppState>().repo.orders());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final initials = context.watch<AppState>().customer?.initials ?? '';
    return AsyncView<List<OrderRow>>(
      future: _future,
      onRetry: _reload,
      builder: (_, rows) => TabScroll(onRefresh: _reload, children: [
        const PageTitle(title: 'My Orders'),
        if (rows.isEmpty) const EmptyCard('No orders yet'),
        for (final o in rows) _card(o, initials),
      ]),
    );
  }

  void _open(OrderRow o) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id)));

  Widget _card(OrderRow o, String initials) => CaCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.zero,
        clip: true,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(initials, style: display(size: 20, color: CaColors.red600)),
                  const SizedBox(height: 4),
                  Text(fmtMdY(o.date), style: const TextStyle(fontSize: 14, color: CaColors.slate700)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('Order #${o.invoiceNo}', style: const TextStyle(fontSize: 14, color: CaColors.slate500, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(money(o.total), style: display(size: 20)),
              ]),
            ]),
          ),
          Container(
            decoration: const BoxDecoration(color: CaColors.slate50, border: Border(top: BorderSide(color: CaColors.slate200))),
            child: IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _open(o),
                    child: Container(
                      decoration: const BoxDecoration(gradient: CaColors.brandGradient),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      alignment: Alignment.center,
                      child: const Text('VIEW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: .5)),
                    ),
                  ),
                ),
                const Expanded(
                  child: Center(child: Text('—', style: TextStyle(color: CaColors.slate400, fontWeight: FontWeight.w600))),
                ),
                const VerticalDivider(width: 1, color: CaColors.slate200),
                Expanded(
                  child: InkWell(
                    onTap: () => _open(o),
                    child: const Center(child: Text('OPEN', style: TextStyle(color: CaColors.slate600, fontWeight: FontWeight.w700, fontSize: 14))),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      );
}
