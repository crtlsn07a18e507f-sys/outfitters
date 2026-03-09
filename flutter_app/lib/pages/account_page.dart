import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';
import '../services/user_service.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final id = await UserService.getUserId();
    setState(() => _userId = id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // Avatar placeholder
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppTheme.accent, AppTheme.surface],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 20),

              const Text(
                'Account',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (_userId != null)
                Text(
                  'ID: ${_userId!.substring(0, 8)}...',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),

              const SizedBox(height: 60),

              // Coming soon card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
                ),
                child: const Column(
                  children: [
                    Text('🚀', style: TextStyle(fontSize: 48)),
                    SizedBox(height: 16),
                    Text(
                      'Prossimamente',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'La sezione Account è in sviluppo.\nPresto potrai:\n\n'
                      '• Creare un profilo personale\n'
                      '• Sincronizzare l\'armadio su più dispositivi\n'
                      '• Condividere outfit con gli amici\n'
                      '• Impostare le tue preferenze di stile\n'
                      '• Vedere statistiche dettagliate',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Reset local data option
              TextButton.icon(
                onPressed: () => _showResetDialog(),
                icon: const Icon(Icons.delete_sweep, color: AppTheme.error, size: 18),
                label: const Text(
                  'Reimposta dati locali',
                  style: TextStyle(color: AppTheme.error, fontSize: 13),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showResetDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Reimposta dati', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'Questo rimuoverà il tuo ID locale. I dati sul server rimarranno. Continuare?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Conferma', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dati locali rimossi. Riavvia l\'app.')),
        );
      }
    }
  }
}
