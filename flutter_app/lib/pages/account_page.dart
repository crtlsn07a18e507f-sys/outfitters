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
  final _nameController = TextEditingController();
  String _selectedGender = 'non specificato';
  String _selectedStyle = 'casual';
  bool _savingProfile = false;

  final _genders = ['uomo', 'donna', 'non specificato'];
  final _styles = ['casual', 'formal', 'sport', 'business', 'streetwear', 'minimal'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final id = await UserService.getUserId();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = id;
      _nameController.text = prefs.getString('profile_name') ?? '';
      _selectedGender = prefs.getString('profile_gender') ?? 'non specificato';
      _selectedStyle = prefs.getString('profile_style') ?? 'casual';
    });
  }

  Future<void> _saveProfile() async {
    setState(() => _savingProfile = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', _nameController.text.trim());
    await prefs.setString('profile_gender', _selectedGender);
    await prefs.setString('profile_style', _selectedStyle);
    setState(() => _savingProfile = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profilo salvato!')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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

              const SizedBox(height: 40),

              // Profile form card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Il tuo profilo',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nome
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Il tuo nome',
                        prefixIcon: Icon(Icons.person_outline, color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Genere
                    const Text(
                      'Genere',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _genders.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (ctx, i) {
                          final g = _genders[i];
                          final selected = _selectedGender == g;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedGender = g),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? AppTheme.accent : AppTheme.secondary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                g[0].toUpperCase() + g.substring(1),
                                style: TextStyle(
                                  color: selected ? Colors.white : AppTheme.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stile preferito
                    const Text(
                      'Stile preferito',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _styles.map((s) {
                        final selected = _selectedStyle == s;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedStyle = s),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? AppTheme.accent : AppTheme.secondary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              s[0].toUpperCase() + s.substring(1),
                              style: TextStyle(
                                color: selected ? Colors.white : AppTheme.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Salva
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _savingProfile ? null : _saveProfile,
                        child: _savingProfile
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Salva profilo'),
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
          'Questo rimuoverà il tuo profilo e tutti i dati salvati localmente. Continuare?',
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