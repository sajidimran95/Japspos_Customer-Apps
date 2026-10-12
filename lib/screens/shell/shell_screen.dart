import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../documents/documents_tab.dart';
import '../home/home_tab.dart';
import '../orders/order_create_tab.dart';
import '../orders/orders_tab.dart';
import '../price/price_check_tab.dart';
import '../profile/profile_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});
  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AppState>().refreshLocation());
  }

  static const _tabs = [
    (CaTab.home, Icons.home_outlined, 'Home'),
    (CaTab.order, Icons.shopping_cart_outlined, 'Order'),
    (CaTab.docs, Icons.description_outlined, 'Docs'),
    (CaTab.price, Icons.credit_card_outlined, 'Price'),
    (CaTab.orders, Icons.shopping_bag_outlined, 'Orders'),
  ];

  @override
  Widget build(BuildContext context) {
    final tab = context.select<AppState, CaTab>((s) => s.tab);
    final body = switch (tab) {
      CaTab.home => const HomeTab(),
      CaTab.order => const OrderCreateTab(),
      CaTab.docs => const DocumentsTab(),
      CaTab.price => const PriceCheckTab(),
      CaTab.orders => const OrdersTab(),
    };
    return PopScope(
      canPop: tab == CaTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.read<AppState>().goTab(CaTab.home);
      },
      child: Scaffold(
        extendBody: true,
        body: CaBackground(
          child: Column(children: [
            const _TopBar(),
            Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: KeyedSubtree(key: ValueKey(tab), child: body))),
          ]),
        ),
        bottomNavigationBar: _BottomNav(current: tab, tabs: _tabs),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final c = app.customer;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 10, 16, 10),
          decoration: const BoxDecoration(color: Color(0xB8FFFFFF), border: Border(bottom: BorderSide(color: CaColors.line))),
          child: Row(children: [
            BizLogo(letter: app.business?.letter ?? 'C', logoUrl: app.business?.logo ?? ''),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(app.businessName, maxLines: 1, overflow: TextOverflow.ellipsis, style: display(size: 15, weight: FontWeight.w700)),
                Text(c?.displayName ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: CaColors.slate500, fontWeight: FontWeight.w600)),
              ]),
            ),
            const AccountMenuButton(),
          ]),
        ),
      ),
    );
  }
}

/// Avatar with the account dropdown (`.ca-avatar` + `.ca-drop`).
class AccountMenuButton extends StatelessWidget {
  const AccountMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final name = app.customer?.displayName ?? '';
    return PopupMenuButton<String>(
      offset: const Offset(0, 52),
      color: const Color(0xF5FFFFFF),
      elevation: 12,
      shadowColor: const Color(0x330F172A),
      constraints: const BoxConstraints(minWidth: 230),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: CaColors.line)),
      onSelected: (v) async {
        switch (v) {
          case 'profile':
          case 'location':
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfileScreen(scrollToLocation: v == 'location')));
          case 'logout':
            if (await confirmDialog(context, 'Do you want to logout?', ok: 'Logout', title: 'Logout')) {
              if (context.mounted) await context.read<AppState>().logout();
            }
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          height: 34,
          child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: CaColors.slate500, fontWeight: FontWeight.w600)),
        ),
        PopupMenuItem<String>(
          enabled: false,
          height: 34,
          child: Row(children: [
            const Icon(Icons.location_on, size: 15, color: CaColors.brand),
            const SizedBox(width: 6),
            Expanded(
              child: Text(app.locationLabel.isEmpty ? '…' : app.locationLabel,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: CaColors.slate600, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        const PopupMenuDivider(height: 6),
        _item('profile', 'Update Profile'),
        _item('location', 'Location'),
        _item('logout', 'Logout', danger: true),
      ],
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [CaColors.rose100, CaColors.rose200]),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [BoxShadow(color: Color(0x2EE11D48), blurRadius: 14, offset: Offset(0, 4))],
        ),
        alignment: Alignment.center,
        child: Text(app.customer?.letter ?? 'C', style: display(size: 15, color: CaColors.brand)),
      ),
    );
  }

  static PopupMenuItem<String> _item(String v, String label, {bool danger = false}) => PopupMenuItem<String>(
        value: v,
        height: 42,
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: danger ? CaColors.brand : CaColors.slate700)),
      );
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.current, required this.tabs});
  final CaTab current;
  final List<(CaTab, IconData, String)> tabs;
  @override
  Widget build(BuildContext context) => SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xE0FFFFFF),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: CaColors.line),
                boxShadow: const [BoxShadow(color: Color(0x1F0F172A), blurRadius: 40, offset: Offset(0, 12))],
              ),
              child: Row(children: [
                for (final t in tabs)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => context.read<AppState>().goTab(t.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(color: t.$1 == current ? CaColors.brandSoft : Colors.transparent, borderRadius: BorderRadius.circular(16)),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(t.$2, size: 22, color: t.$1 == current ? CaColors.brand : CaColors.slate400),
                          const SizedBox(height: 3),
                          Text(t.$3, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: t.$1 == current ? CaColors.brand : CaColors.slate400)),
                        ]),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ),
      );
}

/// Scrollable tab body with the portal's padding (room for the floating nav).
class TabScroll extends StatelessWidget {
  const TabScroll({super.key, required this.children, this.onRefresh});
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  @override
  Widget build(BuildContext context) {
    final list = ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 110 + MediaQuery.of(context).padding.bottom),
      physics: const AlwaysScrollableScrollPhysics(),
      children: children,
    );
    if (onRefresh == null) return list;
    return RefreshIndicator(color: CaColors.brand, onRefresh: onRefresh!, child: list);
  }
}
