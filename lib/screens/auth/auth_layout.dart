import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';

/// Same split layout as `/customer/login`: rose brand panel on wide screens,
/// centered card on phones.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.child, this.footer});
  final Widget child;
  final String? footer;

  static const _features = [
    (Icons.shopping_cart_outlined, 'Create orders'),
    (Icons.description_outlined, 'View invoices'),
    (Icons.monetization_on_outlined, 'Price check'),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 1024;
    final form = SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: wide ? 64 : 18, vertical: 32),
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: child),
        ),
      ),
    );
    if (!wide) return Scaffold(body: CaBackground(child: form));
    return Scaffold(
      body: Row(children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.44,
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF881337), CaColors.brandDark, CaColors.brand], stops: [0, .42, 1]),
          ),
          padding: const EdgeInsets.all(48),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(AppConfig.brandName.toUpperCase(), style: display(size: 34, color: Colors.white)),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Text('Customer portal — check prices, place orders, and view your invoices anytime.',
                  style: TextStyle(color: Colors.white.withValues(alpha: .8), fontSize: 16, height: 1.5)),
            ),
            const SizedBox(height: 24),
            for (final f in _features)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [
                  Icon(f.$1, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text(f.$2, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                ]),
              ),
            const SizedBox(height: 24),
            Text(footer ?? '© ${DateTime.now().year} ${AppConfig.brandName}', style: TextStyle(color: Colors.white.withValues(alpha: .5), fontSize: 12)),
          ]),
        ),
        Expanded(child: CaBackground(child: form)),
      ]),
    );
  }
}

/// The white auth card (`.japs-auth-card`).
class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x14E11D48)),
          boxShadow: const [
            BoxShadow(color: Color(0x0F0F172A), blurRadius: 30, offset: Offset(0, 10)),
            BoxShadow(color: Color(0x1FE11D48), blurRadius: 50, offset: Offset(0, 20)),
          ],
        ),
        child: child,
      );
}
