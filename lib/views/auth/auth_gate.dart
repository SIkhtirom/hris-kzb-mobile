import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/auth_repository.dart';
import '../shell/main_shell.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

enum _AuthStatus { checking, unauthenticated, authenticated }

class _AuthGateState extends State<AuthGate> {
  _AuthStatus _status = _AuthStatus.checking;

  @override
  void initState() {
    super.initState();
    _resolveSession();
  }

  Future<void> _resolveSession() async {
    final authenticated = await context
        .read<AuthRepository>()
        .validateSession();
    if (!mounted) {
      return;
    }
    setState(() {
      _status = authenticated
          ? _AuthStatus.authenticated
          : _AuthStatus.unauthenticated;
    });
  }

  void _onAuthenticated() {
    setState(() => _status = _AuthStatus.authenticated);
  }

  void _onLoggedOut() {
    setState(() => _status = _AuthStatus.unauthenticated);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: switch (_status) {
        _AuthStatus.checking => const Scaffold(
          key: ValueKey('auth_checking'),
          body: SizedBox.expand(),
        ),
        _AuthStatus.unauthenticated => LoginScreen(
          key: const ValueKey('auth_login'),
          onAuthenticated: _onAuthenticated,
        ),
        _AuthStatus.authenticated => MainShell(
          key: const ValueKey('auth_shell'),
          onLoggedOut: _onLoggedOut,
        ),
      },
    );
  }
}
