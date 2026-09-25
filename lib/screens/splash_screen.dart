import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'auth/login_screen.dart';
import 'root_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isInitializing) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: ShaderMask(
            shaderCallback: (bounds) => AppColors.gradientBrand.createShader(bounds),
            child: const Icon(Icons.candlestick_chart_rounded, size: 64, color: Colors.white),
          ),
        ),
      );
    }

    return auth.isLoggedIn ? const RootScreen() : const LoginScreen();
  }
}
