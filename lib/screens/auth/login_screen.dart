import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import 'auth_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _login;
  final _pass = TextEditingController();
  bool _show = false;
  bool _remember = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final remembered = context.read<AppState>().store.rememberedLogin;
    _login = TextEditingController(text: remembered ?? '');
    _remember = remembered != null;
  }

  @override
  void dispose() {
    _login.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AppState>().login(_login.text, _pass.text, remember: _remember);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final company = app.companyName.isEmpty ? AppConfig.brandName : app.companyName;
    return AuthLayout(
      footer: 'Customer portal for $company',
      child: Form(
        key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Color(0x33E11D48), blurRadius: 18, offset: Offset(0, 8))],
              ),
              child: const CaLogo(size: 80, radius: 20),
            ),
          ),
          const SizedBox(height: 16),
          Text('Welcome back', textAlign: TextAlign.center, style: display(size: 26)),
          const SizedBox(height: 4),
          Text('Sign in to the Customer App — $company', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: CaColors.slate500, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () async {
                if (await confirmDialog(context, 'Change store or server URL? You will need to activate again.', ok: 'Change', title: 'Company setup')) {
                  if (context.mounted) await context.read<AppState>().resetSetup();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: CaColors.brandSoft, borderRadius: BorderRadius.circular(999)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.storefront, size: 15, color: CaColors.brandDark),
                  const SizedBox(width: 6),
                  Flexible(child: Text(company, overflow: TextOverflow.ellipsis, style: const TextStyle(color: CaColors.brandDark, fontWeight: FontWeight.w700, fontSize: 13))),
                  const SizedBox(width: 6),
                  Icon(Icons.circle, size: 8, color: app.isStatic ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
                  const SizedBox(width: 4),
                  Text(app.isStatic ? 'Demo data' : 'API active',
                      style: TextStyle(color: app.isStatic ? const Color(0xFFB45309) : const Color(0xFF047857), fontSize: 11, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 22),
          if (_error != null) FlashBox(_error!),
          AuthCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              CaField(
                label: 'Email or Mobile',
                controller: _login,
                hint: 'email@example.com or mobile number',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) => (v ?? '').trim().isEmpty ? 'Email or mobile is required' : null,
              ),
              const SizedBox(height: 14),
              CaField(
                label: 'Password',
                controller: _pass,
                hint: 'Password',
                obscure: !_show,
                textInputAction: TextInputAction.done,
                validator: (v) => (v ?? '').isEmpty ? 'Password is required' : null,
                suffix: IconButton(
                  onPressed: () => setState(() => _show = !_show),
                  icon: Icon(_show ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: CaColors.slate500),
                  tooltip: _show ? 'Hide password' : 'Show password',
                ),
              ),
              const SizedBox(height: 6),
              Row(children: [
                Checkbox(value: _remember, onChanged: (v) => setState(() => _remember = v ?? false)),
                const Text('Remember me', style: TextStyle(fontSize: 14, color: CaColors.slate600, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 8),
              CaButton(label: 'Login', busy: _busy, onPressed: _submit),
            ]),
          ),
          const SizedBox(height: 22),
          Text('Customer portal for $company', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: CaColors.slate500)),
        ]),
      ),
    );
  }
}
