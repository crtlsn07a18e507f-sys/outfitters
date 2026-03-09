import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/app_theme.dart';
import '../models/clothing.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import '../widgets/clothing_card.dart';

class WardrobePage extends StatefulWidget {
  const WardrobePage({super.key});

  @override
  State<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> with AutomaticKeepAliveClientMixin {
  List<ClothingItem> _clothes = [];
  ClothingStats? _stats;
  bool _loading = true;
  bool _uploading = false;
  String? _userId;
  String? _filterCategory;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _userId = await UserService.getUserId();
    await _loadData();
  }

  Future<void> _loadData() async {
    if (_userId == null) return;
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getUserClothes(_userId!),
        ApiService.getClothingStats(_userId!),
      ]);
      setState(() {
        _clothes = results[0] as List<ClothingItem>;
        _stats = results[1] as ClothingStats;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final source = await _showSourceDialog();
    if (source == null) return;

    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (image == null || _userId == null) return;

    setState(() => _uploading = true);
    try {
      final item = await ApiService.uploadClothing(_userId!, File(image.path));
      await _loadData();
      if (mounted) {
        _showSnackbar('${item.name} aggiunto all\'armadio! 👗');
      }
    } on ApiException catch (e) {
      if (mounted) _showSnackbar(e.message);
    } catch (e) {
      if (mounted) _showSnackbar('Errore durante il caricamento');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<ImageSource?> _showSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.secondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Aggiungi capo',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "L'AI analizzerà la foto e creerà il profilo del capo automaticamente",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _SourceButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Fotocamera',
                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SourceButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Galleria',
                    onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteItem(ClothingItem item) async {
    if (_userId == null) return;
    try {
      await ApiService.deleteClothing(item.id, _userId!);
      await _loadData();
      if (mounted) _showSnackbar('${item.name} eliminato');
    } catch (e) {
      if (mounted) _showSnackbar('Errore durante l\'eliminazione');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  List<ClothingItem> get _filteredClothes {
    if (_filterCategory == null) return _clothes;
    return _clothes.where((c) => c.category == _filterCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.accent,
          backgroundColor: AppTheme.card,
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      const Text(
                        '👗 Armadio',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_uploading)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppTheme.accent,
                            ),
                          ),
                        )
                      else
                        IconButton(
                          onPressed: _pickAndUpload,
                          icon: const Icon(Icons.add_circle_rounded, color: AppTheme.accent, size: 32),
                        ),
                    ],
                  ),
                ),
              ),

              // Stats dashboard
              if (_stats != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _StatsDashboard(stats: _stats!),
                  ),
                ),

              // Category filter
              SliverToBoxAdapter(
                child: _CategoryFilter(
                  selected: _filterCategory,
                  categories: _stats?.byCategory.keys.toList() ?? [],
                  onChanged: (cat) => setState(() => _filterCategory = cat),
                ),
              ),

              // Upload in progress banner
              if (_uploading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _UploadingBanner(),
                  ),
                ),

              // Clothes count
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    _filterCategory != null
                        ? '${_filteredClothes.length} capi in questa categoria'
                        : '${_clothes.length} capi totali',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ),
              ),

              // Grid
              if (_loading)
                const SliverToBoxAdapter(child: _LoadingSkeleton())
              else if (_filteredClothes.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(60),
                    child: Center(
                      child: Column(
                        children: [
                          const Text('👔', style: TextStyle(fontSize: 60)),
                          const SizedBox(height: 16),
                          Text(
                            _filterCategory != null
                                ? 'Nessun capo in questa categoria'
                                : 'Il tuo armadio è vuoto!\nAggiungi il tuo primo capo.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                          if (_filterCategory == null) ...[
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _pickAndUpload,
                              icon: const Icon(Icons.add_a_photo),
                              label: const Text('Aggiungi Capo'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final item = _filteredClothes[i];
                        return ClothingCard(
                          item: item,
                          onDelete: () => _deleteItem(item),
                        );
                      },
                      childCount: _filteredClothes.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _StatsDashboard extends StatelessWidget {
  final ClothingStats stats;

  const _StatsDashboard({required this.stats});

  static const _categoryIcons = {
    'top': '👕',
    'bottom': '👖',
    'shoes': '👟',
    'jacket': '🧥',
    'accessory': '💍',
  };

  static const _categoryLabels = {
    'top': 'Top',
    'bottom': 'Pantaloni',
    'shoes': 'Scarpe',
    'jacket': 'Giacche',
    'accessory': 'Accessori',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2A5E), Color(0xFF0D1A3D)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${stats.total}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('capi nel', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  Text(
                    'tuo armadio',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: stats.byCategory.entries.map((entry) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _categoryIcons[entry.key] ?? '👔',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${entry.value} ${_categoryLabels[entry.key] ?? entry.key}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  final String? selected;
  final List<String> categories;
  final ValueChanged<String?> onChanged;

  const _CategoryFilter({
    required this.selected,
    required this.categories,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        children: [
          _FilterChip(
            label: 'Tutti',
            selected: selected == null,
            onTap: () => onChanged(null),
          ),
          ...categories.map((c) => _FilterChip(
                label: _label(c),
                selected: selected == c,
                onTap: () => onChanged(selected == c ? null : c),
              )),
        ],
      ),
    );
  }

  String _label(String c) {
    const map = {
      'top': '👕 Top',
      'bottom': '👖 Pantaloni',
      'shoes': '👟 Scarpe',
      'jacket': '🧥 Giacche',
      'accessory': '💍 Accessori',
    };
    return map[c] ?? c;
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent : AppTheme.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _UploadingBanner extends StatelessWidget {
  const _UploadingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
          ),
          SizedBox(width: 12),
          Text(
            'L\'AI sta analizzando il capo...',
            style: TextStyle(color: AppTheme.accent, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.accent, size: 36),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.72,
        children: List.generate(
          6,
          (_) => Container(
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}
