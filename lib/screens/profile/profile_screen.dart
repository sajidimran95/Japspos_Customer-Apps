import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';

/// Profile (`/customer/profile`): details, default location, password.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.scrollToLocation = false});
  final bool scrollToLocation;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<ProfileData> _future;
  final _locationKey = GlobalKey();
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  int? _locationId;
  bool _savingLoc = false;
  bool _savingPw = false;

  @override
  void initState() {
    super.initState();
    _future = context.read<AppState>().repo.profile().then((p) {
      _locationId = p.currentLocationId ?? (p.locations.isEmpty ? null : p.locations.first.id);
      if (widget.scrollToLocation) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = _locationKey.currentContext;
          if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300));
        });
      }
      return p;
    });
  }

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _saveLocation() async {
    final id = _locationId;
    if (id == null) return;
    setState(() => _savingLoc = true);
    try {
      final msg = await context.read<AppState>().setLocation(id);
      if (mounted) toast(context, msg);
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _savingLoc = false);
    }
  }

  Future<void> _savePassword() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _savingPw = true);
    try {
      final msg = await context.read<AppState>().repo.changePassword(_current.text, _new.text, _confirm.text);
      if (!mounted) return;
      _current.clear();
      _new.clear();
      _confirm.clear();
      toast(context, msg);
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _savingPw = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Profile'), backgroundColor: Colors.transparent),
        extendBodyBehindAppBar: false,
        body: CaBackground(
          child: AsyncView<ProfileData>(
            future: _future,
            builder: (_, p) => ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
              _details(p.customer),
              const SizedBox(height: 16),
              _location(p.locations),
              const SizedBox(height: 16),
              _password(),
            ]),
          ),
        ),
      );

  Widget _details(Customer c) => CaCard(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(gradient: CaColors.brandGradient, borderRadius: BorderRadius.circular(18)),
              alignment: Alignment.center,
              child: Text(c.initials, style: display(size: 20, color: Colors.white)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.displayName, style: display(size: 18)),
                Text(c.contactId, style: const TextStyle(color: CaColors.slate500, fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          _kv('Email', c.email.isEmpty ? '-' : c.email),
          _kv('Mobile', c.mobile.isEmpty ? '-' : c.mobile),
          _kv('Login ID', 'Email or mobile'),
        ]),
      );

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          SizedBox(width: 90, child: Text(k, style: const TextStyle(color: CaColors.slate500, fontSize: 13, fontWeight: FontWeight.w600))),
          Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
        ]),
      );

  Widget _location(List<StoreLocation> locs) => CaCard(
        key: _locationKey,
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('📍 Default Location', style: display(size: 16)),
          const SizedBox(height: 12),
          if (locs.isEmpty)
            const Text('No locations available.', style: TextStyle(color: CaColors.slate500))
          else
            CaSelect<int>(value: _locationId, items: {for (final l in locs) l.id: l.label}, onChanged: (v) => setState(() => _locationId = v)),
          const SizedBox(height: 12),
          CaButton(label: 'Save Location', compact: true, busy: _savingLoc, onPressed: locs.isEmpty ? null : _saveLocation),
          const SizedBox(height: 8),
          const Text('Used for Create Order and Price Check.', style: TextStyle(fontSize: 12, color: CaColors.slate500)),
        ]),
      );

  Widget _password() => CaCard(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Change Password', style: display(size: 16)),
            const SizedBox(height: 12),
            CaField(label: 'Current Password', controller: _current, obscure: true, validator: (v) => (v ?? '').isEmpty ? 'Required' : null),
            const SizedBox(height: 12),
            CaField(label: 'New Password', controller: _new, obscure: true, validator: (v) => (v ?? '').length < 4 ? 'Minimum 4 characters' : null),
            const SizedBox(height: 12),
            CaField(label: 'Confirm Password', controller: _confirm, obscure: true, validator: (v) => v != _new.text ? 'Passwords do not match' : null),
            const SizedBox(height: 16),
            CaButton(label: 'Update Password', compact: true, busy: _savingPw, onPressed: _savePassword),
          ]),
        ),
      );
}
