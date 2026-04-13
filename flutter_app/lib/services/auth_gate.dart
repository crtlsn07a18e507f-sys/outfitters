import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Splash minimale durante il caricamento
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D0D0D), // AppTheme.primary
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)), // AppTheme.accent
            ),
          );
        }

        final session = _supabase.auth.currentSession;
        if (session == null) {
          return const LoginPage();
        }

        return widget.child;
      },
    );
  }
}
