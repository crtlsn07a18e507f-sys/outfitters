import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/login_page.dart';

/// Inserisci [AuthGate] come home del tuo MaterialApp.
/// Mostra il LoginPage se l'utente non è loggato,
/// altrimenti mostra la [child] (es. la tua BottomNavBar / HomePage).
///
/// Esempio in main.dart:
///
///   home: AuthGate(child: MainPage()),
///
class AuthGate extends StatefulWidget {
  final Widget child;

  const AuthGate({super.key, required this.child});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoggedIn = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      _loading = false;
    });
  }

  void _onLoginSuccess() {
    setState(() => _isLoggedIn = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      // Splash minimale mentre legge SharedPreferences
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D0D), // AppTheme.primary
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6C63FF)), // AppTheme.accent
        ),
      );
    }

    if (!_isLoggedIn) {
      return LoginPage(onLoginSuccess: _onLoginSuccess);
    }

    return widget.child;
  }
}