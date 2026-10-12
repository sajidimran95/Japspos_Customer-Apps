import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF881337), CaColors.brandDark, CaColors.brand], stops: [0, .45, 1]),
          ),
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.85, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutBack,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withValues(alpha: .6), width: 2),
                    boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 40, offset: Offset(0, 16))],
                  ),
                  child: const CaLogo(size: 140, radius: 30),
                ),
                const SizedBox(height: 28),
                Text(AppConfig.appName, style: display(size: 26, color: Colors.white)),
                const SizedBox(height: 4),
                Text('${AppConfig.brandName} ${AppConfig.brandTagline}', style: TextStyle(color: Colors.white.withValues(alpha: .75), fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 36),
                const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white)),
              ]),
            ),
          ),
        ),
      );
}
