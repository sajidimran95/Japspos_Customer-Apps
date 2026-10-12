import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../shell/shell_screen.dart';
import 'invoice_screen.dart';

/// Documents (`/customer/documents`): Invoices and Tax Reports.
class DocumentsTab extends StatefulWidget {
  const DocumentsTab({super.key});
  @override
  State<DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends State<DocumentsTab> {
  bool _taxTab = false;
  DateTime? _from;
  DateTime? _to;
  final _q = TextEditingController();
  late Future<DocumentsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<DocumentsData> _fetch() => context.read<AppState>().repo.documents(start: _from, end: _to, q: _q.text.trim());

  Future<void> _apply() async {
    setState(() => _future = _fetch());
    await _future;
  }

  void _showAll() {
    _from = null;
    _to = null;
    _q.clear();
    _apply();
  }

  Future<void> _pick(bool from) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: (from ? _from : _to) ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (d != null) setState(() => from ? _from = d : _to = d);
  }

  @override
  Widget build(BuildContext context) => TabScroll(onRefresh: _apply, children: [
        const PageTitle(title: 'Documents'),
        _tabs(),
        const SizedBox(height: 16),
        CaCard(child: _taxTab ? _taxFilters() : _invoiceFilters()),
        const SizedBox(height: 16),
        FutureBuilder<DocumentsData>(
          future: _future,
          builder: (_, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: CaColors.brand)));
            }
            if (snap.hasError) return EmptyCard('${snap.error}', padding: 24);
            final d = snap.data!;
            return _taxTab ? _taxBody(d) : _invoiceBody(d);
          },
        ),
      ]);

  Widget _tabs() => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: CaColors.slate100, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          for (final t in const [(false, 'Invoices'), (true, 'Tax Reports')])
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _taxTab = t.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _taxTab == t.$1 ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: _taxTab == t.$1 ? const [BoxShadow(color: Color(0x140F172A), blurRadius: 6, offset: Offset(0, 2))] : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(t.$2, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _taxTab == t.$1 ? CaColors.brand : CaColors.slate500)),
                ),
              ),
            ),
        ]),
      );

  Widget _dateBox(String label, DateTime? v, bool from) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FieldLabel(label),
          InkWell(
            onTap: () => _pick(from),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: CaColors.slate200)),
              child: Row(children: [
                Expanded(
                  child: Text(v == null ? 'mm/dd/yyyy' : fmtMdY(v),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: v == null ? CaColors.slate400 : CaColors.ink)),
                ),
                const Icon(Icons.calendar_today_outlined, size: 16, color: CaColors.slate400),
              ]),
            ),
          ),
        ]),
      );

  Widget _invoiceFilters() => Column(children: [
        Row(children: [_dateBox('From', _from, true), const SizedBox(width: 10), _dateBox('To', _to, false)]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: CaButton(label: 'Apply', compact: true, onPressed: _apply)),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton(onPressed: _showAll, style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)), child: const Text('Show All'))),
        ]),
        const SizedBox(height: 12),
        CaSearchField(controller: _q, hint: 'Search invoice number', onSubmitted: (_) => _apply()),
      ]);

  Widget _taxFilters() => Column(children: [
        Row(children: [_dateBox('From', _from, true), const SizedBox(width: 10), _dateBox('To', _to, false)]),
        const SizedBox(height: 12),
        CaButton(label: 'Apply', compact: true, onPressed: _apply),
      ]);

  Widget _invoiceBody(DocumentsData d) {
    final ranged = _from != null || _to != null;
    final count = ranged
        ? 'Showing ${d.invoices.length} invoice(s) from ${_from == null ? '…' : fmtMdY(_from!)} to ${_to == null ? '…' : fmtMdY(_to!)}'
        : 'All invoices (${d.invoices.length})';
    final groups = <String, List<Invoice>>{};
    for (final i in d.invoices) {
      groups.putIfAbsent(fmtDayGroup(i.date), () => []).add(i);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(bottom: 10, left: 4), child: Text(count, style: const TextStyle(fontSize: 13, color: CaColors.slate500, fontWeight: FontWeight.w600))),
      if (d.invoices.isEmpty) const EmptyCard('No invoices found'),
      for (final g in groups.entries) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
          child: Text('📅 ${g.key} (${g.value.length})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: CaColors.slate700)),
        ),
        for (final i in g.value) _invoiceRow(i),
      ],
    ]);
  }

  void _openInvoice(Invoice i) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => InvoiceScreen(invoiceId: i.id, invoiceNo: i.invoiceNo)));

  Widget _invoiceRow(Invoice i) => CaCard(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        onTap: () => _openInvoice(i),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: CaColors.brandSoft, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: const Text('📄', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(i.invoiceNo, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 2),
              Text(fmtMonDY(i.date), style: const TextStyle(fontSize: 12, color: CaColors.red600, fontWeight: FontWeight.w600)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            StatusBadge(i.statusLabel),
            const SizedBox(height: 4),
            Text(money(i.total), style: display(size: 14)),
          ]),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _openInvoice(i),
            style: IconButton.styleFrom(backgroundColor: CaColors.slate100),
            icon: const Icon(Icons.visibility_outlined, size: 18, color: CaColors.slate600),
          ),
        ]),
      );

  Widget _taxBody(DocumentsData d) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.9,
          children: [
            _stat('Invoices', '${d.invoiceCount}'),
            _stat('Sales Total', money(d.salesTotal)),
            _stat('Tax Total', money(d.taxTotal), color: CaColors.red600),
            _stat('Paid Total', money(d.paidTotal)),
          ],
        ),
        const SizedBox(height: 18),
        const SectionHeader(title: 'Tax by Invoice'),
        if (d.invoices.isEmpty) const EmptyCard('No invoices found', padding: 24),
        for (final i in d.invoices)
          CaCard(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            onTap: () => _openInvoice(i),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(i.invoiceNo, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  Text(fmtMonDY(i.date), style: const TextStyle(fontSize: 12, color: CaColors.slate500)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('Tax ${money(i.tax)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: CaColors.red600)),
                Text('Total ${money(i.total)}', style: const TextStyle(fontSize: 12, color: CaColors.slate500)),
              ]),
            ]),
          ),
      ]);

  Widget _stat(String label, String value, {Color color = CaColors.ink}) => CaCard(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CaColors.slate500)),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: display(size: 20, color: color))),
        ]),
      );
}
