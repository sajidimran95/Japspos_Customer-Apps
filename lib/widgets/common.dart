import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/repository.dart';

class CaLogo extends StatelessWidget {
  const CaLogo({super.key, this.size = 64, this.radius = 16});
  final double size;
  final double radius;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset('assets/images/logo.png', width: size, height: size, fit: BoxFit.cover),
      );
}

/// Business logo, or the rose letter tile (`.ca-logo-fb`) when there is none.
class BizLogo extends StatelessWidget {
  const BizLogo({super.key, required this.letter, this.logoUrl = '', this.size = 42});
  final String letter;
  final String logoUrl;
  final double size;
  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(gradient: CaColors.logoGradient, borderRadius: BorderRadius.circular(size / 3)),
      alignment: Alignment.center,
      child: Text(letter, style: display(size: size * .42, color: Colors.white)),
    );
    if (logoUrl.isEmpty) return fallback;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size / 3),
        border: Border.all(color: CaColors.line),
        boxShadow: const [BoxShadow(color: Color(0x0F0F172A), blurRadius: 12, offset: Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(logoUrl, fit: BoxFit.contain, errorBuilder: (_, _, _) => fallback),
    );
  }
}

/// Soft rose radial wash behind every screen (portal `body` background).
class CaBackground extends StatelessWidget {
  const CaBackground({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [CaColors.slate50, CaColors.slate100]),
        ),
        child: Stack(children: [
          Positioned(
            left: -160,
            top: -220,
            child: _glow(520, const Color(0x1FE11D48)),
          ),
          Positioned(
            right: -180,
            top: -160,
            child: _glow(460, const Color(0x24FB7185)),
          ),
          Positioned.fill(child: child),
        ]),
      );

  static Widget _glow(double size, Color c) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [c, c.withValues(alpha: 0)])),
        ),
      );
}

/// `.ca-card`: translucent white card, 20px radius, soft shadow.
class CaCard extends StatelessWidget {
  const CaCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.margin, this.clip = false});
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final bool clip;
  @override
  Widget build(BuildContext context) => Container(
        margin: margin,
        decoration: BoxDecoration(
          color: CaColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CaColors.line),
          boxShadow: const [BoxShadow(color: Color(0x0F0F172A), blurRadius: 30, offset: Offset(0, 10))],
        ),
        clipBehavior: clip ? Clip.antiAlias : Clip.none,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(borderRadius: BorderRadius.circular(20), onTap: onTap, child: Padding(padding: padding, child: child)),
        ),
      );
}

/// `.ca-btn`: rose gradient button.
class CaButton extends StatelessWidget {
  const CaButton({super.key, required this.label, required this.onPressed, this.busy = false, this.icon, this.compact = false});
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    return Opacity(
      opacity: enabled || busy ? 1 : .45,
      child: Container(
        height: compact ? 44 : 52,
        decoration: BoxDecoration(
          gradient: CaColors.brandGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled ? const [BoxShadow(color: Color(0x47E11D48), blurRadius: 24, offset: Offset(0, 10))] : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: enabled ? onPressed : null,
            child: Center(
              child: busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      if (icon != null) ...[Icon(icon, color: Colors.white, size: 18), const SizedBox(width: 8)],
                      Text(label, style: display(size: compact ? 14 : 15, color: Colors.white)),
                    ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.ca-input` with the 🔍 prefix used by the search boxes.
class CaSearchField extends StatelessWidget {
  const CaSearchField({super.key, required this.controller, required this.hint, this.onChanged, this.onSubmitted});
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search, color: CaColors.slate400, size: 20),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: CaColors.line)),
        ),
      );
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CaColors.slate500)),
      );
}

class CaField extends StatelessWidget {
  const CaField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
    this.validator,
    this.onChanged,
    this.textInputAction,
  });
  final String label;
  final TextEditingController? controller;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FieldLabel(label),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          validator: validator,
          onChanged: onChanged,
          textInputAction: textInputAction,
          style: const TextStyle(fontWeight: FontWeight.w600),
          decoration: InputDecoration(hintText: hint, suffixIcon: suffix),
        ),
      ]);
}

/// Plain select box (`border-slate-200 rounded-xl`).
class CaSelect<T> extends StatelessWidget {
  const CaSelect({super.key, required this.value, required this.items, required this.onChanged});
  final T? value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: CaColors.slate200)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: items.containsKey(value) ? value : null,
            isExpanded: true,
            borderRadius: BorderRadius.circular(12),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CaColors.ink),
            items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: onChanged,
          ),
        ),
      );
}

class PageTitle extends StatelessWidget {
  const PageTitle({super.key, required this.title, this.sub, this.trailing});
  final String title;
  final String? sub;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: display(size: 26, height: 1.15)),
              if (sub != null && sub!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(sub!, style: const TextStyle(color: CaColors.muted, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ]),
          ),
          ?trailing,
        ]),
      );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Expanded(child: Text(title, style: display(size: 17))),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!, style: const TextStyle(color: CaColors.brand, fontWeight: FontWeight.w800, fontSize: 14)),
            ),
        ]),
      );
}

/// `.ca-badge--paid / --due / --partial`.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});
  final String status;
  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (status) {
      'PAID' => (CaColors.green600, CaColors.green50),
      'UNPAID' => (CaColors.brand, CaColors.brandSoft),
      _ => (CaColors.amber600, CaColors.amber50),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), border: Border.all(color: fg)),
      child: Text(status, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}

class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.url, this.size, this.radius = 16});
  final String url;
  final double? size;
  final double radius;
  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: CaColors.slate100,
      alignment: Alignment.center,
      child: Icon(Icons.inventory_2_outlined, color: CaColors.slate300, size: (size ?? 80) * .4),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url.isEmpty
          ? placeholder
          : Image.network(url, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, _, _) => placeholder),
    );
  }
}

class EmptyCard extends StatelessWidget {
  const EmptyCard(this.text, {super.key, this.padding = 40});
  final String text;
  final double padding;
  @override
  Widget build(BuildContext context) => CaCard(
        padding: EdgeInsets.symmetric(vertical: padding, horizontal: 16),
        child: Center(child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: CaColors.slate400, fontSize: 14, fontWeight: FontWeight.w600))),
      );
}

/// `.ca-flash--ok / --err`.
class FlashBox extends StatelessWidget {
  const FlashBox(this.text, {super.key, this.ok = false});
  final String text;
  final bool ok;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: ok ? CaColors.emerald50 : CaColors.brandSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ok ? CaColors.emerald200 : CaColors.rose200),
        ),
        child: Text(text, style: TextStyle(color: ok ? CaColors.emerald800 : CaColors.rose900, fontWeight: FontWeight.w700, fontSize: 13)),
      );
}

// -------------------------------------------------------------------- dialogs

void toast(BuildContext context, String msg, {bool success = true}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w700)),
      backgroundColor: success ? CaColors.ink : CaColors.brand,
      duration: const Duration(seconds: 2),
    ));
}

void toastError(BuildContext context, Object e) => toast(context, e is RepoException ? e.message : '$e', success: false);

/// The dark "Added" pill that pops above the bottom nav.
void showAddedPill(BuildContext context) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => Positioned(
      left: 0,
      right: 0,
      bottom: MediaQuery.of(ctx).padding.bottom + 104,
      child: IgnorePointer(
        child: Material(
          type: MaterialType.transparency,
          child: Center(
            child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: CaColors.ink,
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [BoxShadow(color: Color(0x470F172A), blurRadius: 28, offset: Offset(0, 12))],
            ),
            child: Text('Added', style: display(size: 13, color: Colors.white)),
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Future.delayed(const Duration(milliseconds: 1400), entry.remove);
}

Future<bool> confirmDialog(BuildContext context, String message, {String ok = 'OK', String title = 'Confirm'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: display(size: 18)),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: CaColors.brand), child: Text(ok)),
      ],
    ),
  );
  return r ?? false;
}

Future<bool?> attentionDialog(BuildContext context, String message) => showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(color: CaColors.amber50, shape: BoxShape.circle),
              child: const Center(child: Text('!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: CaColors.amber600))),
            ),
            const SizedBox(height: 12),
            Text('Attention!', style: display(size: 18)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: CaColors.slate600)),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('NO'))),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('YES'))),
            ]),
          ]),
        ),
      ),
    );

// ---------------------------------------------------------------- async view

class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.future, required this.builder, this.onRetry});
  final Future<T>? future;
  final Widget Function(BuildContext, T) builder;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
        future: future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: CaColors.brand)));
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.cloud_off, size: 40, color: CaColors.slate400),
                  const SizedBox(height: 8),
                  Text(snap.error is RepoException ? (snap.error as RepoException).message : '${snap.error}',
                      textAlign: TextAlign.center, style: const TextStyle(color: CaColors.slate500)),
                  if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('Retry')),
                ]),
              ),
            );
          }
          return builder(ctx, snap.data as T);
        },
      );
}
