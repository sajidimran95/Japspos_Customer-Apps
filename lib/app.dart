import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config.dart';
import 'core/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/setup_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/shell/shell_screen.dart';
import 'state/app_state.dart';

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: buildCaTheme(),
        home: const _Gate(),
      );
}

class _Gate extends StatefulWidget {
  const _Gate();
  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _splashDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) return const SplashScreen();
    final stage = context.select<AppState, AppStage>((s) => s.stage);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: switch (stage) {
        AppStage.setup => const SetupScreen(key: ValueKey('setup')),
        AppStage.login => const LoginScreen(key: ValueKey('login')),
        AppStage.home => const ShellScreen(key: ValueKey('home')),
      },
    );
  }
}
