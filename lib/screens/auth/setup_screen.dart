import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import 'auth_layout.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _company;
  late final TextEditingController _url;
  bool _busy = false;
  String? _error;
  bool _activated = false;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _company = TextEditingController(text: app.companyName);
    _url = TextEditingController(text: app.baseUrl);
  }

  @override
  void dispose() {
    _company.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final app = context.read<AppState>();
    final err = await app.checkServer(_url.text);
    if (!mounted) return;
    if (err == null) {
      setState(() {
        _busy = false;
        _activated = true;
      });
      return;
    }
    setState(() {
      _busy = false;
      _error = err;
    });
    if (err != AppState.invalidUrlMessage) {
      final demo = await attentionDialog(context, '$err\n\nContinue with demo data? The app switches to live data automatically once this store\'s API is active.');
      if (demo == true && mounted) await app.completeSetup(_company.text, _url.text, apiLive: false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthLayout(
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [BoxShadow(color: Color(0x33E11D48), blurRadius: 24, offset: Offset(0, 10))],
                ),
                child: const CaLogo(size: 96, radius: 24),
              ),
            ),
            const SizedBox(height: 18),
            Text('Company Setup', textAlign: TextAlign.center, style: display(size: 26)),
            const SizedBox(height: 4),
            const Text('Set your store and server to activate the API', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: CaColors.slate500, fontWeight: FontWeight.w600)),
            const SizedBox(height: 26),
            Row(children: [
              const _Step(n: 1, label: 'Setup', on: true),
              _StepLine(on: _activated),
              _Step(n: 2, label: 'Activate', on: _activated),
              const _StepLine(on: false),
              const _Step(n: 3, label: 'Login', on: false),
            ]),
            const SizedBox(height: 22),
            if (_error != null) FlashBox(_error!),
            AuthCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                CaField(
                  label: 'Company name',
                  controller: _company,
                  hint: 'e.g. JapsPos Wholesale',
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Company name is required' : null,
                ),
                const SizedBox(height: 14),
                CaField(
                  label: 'Base URL',
                  controller: _url,
                  hint: 'https://your-store.japspos.com',
                  keyboardType: TextInputType.url,
                  suffix: const Icon(Icons.link, color: CaColors.slate400),
                  onChanged: (_) {
                    if (_activated) setState(() => _activated = false);
                  },
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Base URL is required' : null,
                ),
                const SizedBox(height: 6),
                const Text('The address of your store\'s JapsPos.', style: TextStyle(fontSize: 12, color: CaColors.slate400)),
                const SizedBox(height: 18),
                CaButton(
                  label: _busy ? 'Checking server…' : (_activated ? 'API Active' : 'Activate'),
                  icon: _activated ? Icons.check_circle : Icons.power_settings_new,
                  busy: _busy,
                  onPressed: _activated ? null : _activate,
                ),
              ]),
            ),
            if (_activated) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: CaColors.emerald50, borderRadius: BorderRadius.circular(14), border: Border.all(color: CaColors.emerald200)),
                child: const Row(children: [
                  Icon(Icons.verified, color: Color(0xFF059669)),
                  SizedBox(width: 10),
                  Expanded(child: Text('Server is active. API enabled — continue to sign in.', style: TextStyle(color: CaColors.emerald800, fontWeight: FontWeight.w700))),
                ]),
              ),
              const SizedBox(height: 12),
              CaButton(label: 'Continue to Login', onPressed: () => context.read<AppState>().completeSetup(_company.text, _url.text, apiLive: true)),
            ],
            const SizedBox(height: 22),
            const Text(
              'When the store API is active your data loads live. Otherwise the app shows demo data.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: CaColors.slate400),
            ),
          ]),
        ),
      );
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.label, required this.on});
  final int n;
  final String label;
  final bool on;
  @override
  Widget build(BuildContext context) => Column(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 30,
          height: 30,
          decoration: BoxDecoration(gradient: on ? CaColors.brandGradient : null, color: on ? null : CaColors.slate100, shape: BoxShape.circle),
          child: Center(child: Text('$n', style: TextStyle(color: on ? Colors.white : CaColors.slate400, fontWeight: FontWeight.w800))),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: on ? CaColors.ink : CaColors.slate400)),
      ]);
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.on});
  final bool on;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(height: 2, margin: const EdgeInsets.only(bottom: 18, left: 4, right: 4), color: on ? CaColors.brand : CaColors.slate200),
      );
}
