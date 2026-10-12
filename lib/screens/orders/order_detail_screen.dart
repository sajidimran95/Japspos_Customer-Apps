import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../documents/invoice_screen.dart';
import 'order_create_tab.dart';

/// View Order (`/customer/orders/{id}`).
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId, this.flash});
  final int orderId;
  final String? flash;
  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Future<OrderDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AppState>().repo.order(widget.orderId);
  }

  void _reload() => setState(() => _future = context.read<AppState>().repo.order(widget.orderId));

  void _openInvoice(OrderDetail d) => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => InvoiceScreen(invoiceId: d.order.id, invoiceNo: d.order.invoiceNo),
      ));

  @override
  Widget build(BuildContext context) {
    final initials = context.watch<AppState>().customer?.initials ?? '';
    return Scaffold(
      body: CaBackground(
        child: SafeArea(
          child: AsyncView<OrderDetail>(
            future: _future,
            onRetry: _reload,
            builder: (_, d) => ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [
              if (widget.flash != null && widget.flash!.isNotEmpty) FlashBox(widget.flash!, ok: true),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(initials, style: display(size: 26, color: CaColors.red600)),
                    const SizedBox(height: 4),
                    Text('#${d.order.invoiceNo} · ${fmtMonDY(d.order.date)}', style: const TextStyle(fontSize: 14, color: CaColors.slate500)),
                  ]),
                ),
                if (d.order.isFinalInvoice) ...[
                  _headBtn(Icons.receipt_long_outlined, () => _openInvoice(d), tint: true),
                  const SizedBox(width: 8),
                ],
                _headBtn(Icons.arrow_back, () => Navigator.pop(context)),
              ]),
              const SizedBox(height: 18),
              Row(children: [
                for (final f in const [('pickup', 'PICKUP', Icons.storefront_outlined), ('delivery', 'DELIVERY', Icons.local_shipping_outlined), ('shipping', 'SHIPPING', Icons.inventory_2_outlined)]) ...[
                  Expanded(child: FulfillButton(label: f.$2, icon: f.$3, on: d.fulfillment == f.$1, readOnly: true)),
                  if (f.$1 != 'shipping') const SizedBox(width: 8),
                ],
              ]),
              const SizedBox(height: 18),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Added Items', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    Text.rich(TextSpan(text: 'Total : ', style: const TextStyle(fontSize: 14, color: CaColors.slate500), children: [
                      TextSpan(text: money(d.itemsTotal), style: const TextStyle(fontWeight: FontWeight.w700, color: CaColors.slate800)),
                    ])),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  const Text('Order total', style: TextStyle(fontSize: 12, color: CaColors.slate500)),
                  Text(money(d.order.total), style: display(size: 18, color: CaColors.red600)),
                ]),
              ]),
              const SizedBox(height: 12),
              if (d.lines.isEmpty) const EmptyCard('No line items on this order.', padding: 24),
              for (final l in d.lines) _line(l),
              const SizedBox(height: 8),
              if (d.order.isFinalInvoice) ...[
                CaButton(label: 'View Invoice', icon: Icons.receipt_long_outlined, onPressed: () => _openInvoice(d)),
                const SizedBox(height: 12),
              ],
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('← Back to My Orders', style: TextStyle(color: CaColors.slate600, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _headBtn(IconData icon, VoidCallback onTap, {bool tint = false}) => Material(
        color: tint ? CaColors.red50 : CaColors.slate100,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(width: 44, height: 44, child: Icon(icon, color: tint ? CaColors.red600 : CaColors.slate700, size: 22)),
        ),
      );

  Widget _line(OrderLineView l) => CaCard(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ProductImage(url: l.image, size: 80, radius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, height: 1.3)),
              if (l.hasDiscount && l.offAmount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('% ${money(l.offAmount)} Off', style: const TextStyle(color: CaColors.red600, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              const SizedBox(height: 4),
              _meta('SKU', l.sku.isEmpty ? '-' : l.sku),
              _meta('Size', l.size),
              _meta('Retail UPC', l.upc.isEmpty ? '-' : l.upc),
              const SizedBox(height: 8),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${qtyText(l.qty)} items', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    const Text('Quantity', style: TextStyle(fontSize: 11, color: CaColors.slate500)),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  if (l.hasDiscount && l.unitBefore > l.unitFinal)
                    Text('\$ ${l.unitBefore.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 11, color: CaColors.slate400, decoration: TextDecoration.lineThrough)),
                  Text('\$ ${l.unitFinal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: CaColors.slate600, fontWeight: FontWeight.w600)),
                  Text(money(l.lineTotal), style: display(size: 15)),
                ]),
              ]),
            ]),
          ),
        ]),
      );

  Widget _meta(String k, String v) => Text.rich(
        TextSpan(text: '$k: ', style: const TextStyle(color: CaColors.slate500, fontSize: 12), children: [
          TextSpan(text: v, style: const TextStyle(color: CaColors.slate700, fontWeight: FontWeight.w600)),
        ]),
      );
}
