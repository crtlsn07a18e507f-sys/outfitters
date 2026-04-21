import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/app_theme.dart';
import '../config/api_config.dart';
import '../models/clothing.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

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
  String _searchQuery = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final authService = AuthService();
    _userId = authService.currentUser?.id;
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    
    // Simuliamo il caricamento
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      // DATI HARDCODED (Modificati per essere compatibili con il tuo modello)
      final uid = _userId ?? 'temp_user';
      final mockItems = [
        ClothingItem(
          id: '1',
          userId: uid, // Obbligatorio
          name: 'Giacca North Face Retro',
          category: 'jacket',
          color: 'Nero',
          material: 'Nylon/Piumino',
          tempMin: -5,
          tempMax: 10,
          imageFilename: 'https://img01.ztat.net/article/spp-media-p1/8f3eb685eb0f436ab4b183ce33c72f8e/db5f2b418ed247348788fee9556fb6f3.jpg',
          aiDescription: 'Giacca invernale pesante, ideale per climi rigidi.',
          suitableOccasions: ['Outdoor', 'Inverno'],
          createdAt: DateTime.now(),
        ),
        ClothingItem(
          id: '2',
          userId: uid,
          name: 'Jeans Levi\'s 501',
          category: 'bottom',
          color: 'Blu Denim',
          material: 'Cotone',
          tempMin: 10,
          tempMax: 25,
          imageFilename: 'https://img01.ztat.net/article/spp-media-p1/68ca23ee065c48b48c8d1878e53788e7/50c796b46b564d78a631cbb019b415b5.jpg',
          aiDescription: 'Jeans dal taglio classico, versatile per ogni occasione.',
          suitableOccasions: ['Casual', 'Lavoro'],
          createdAt: DateTime.now(),
        ),
        ClothingItem(
          id: '3',
          userId: uid,
          name: 'T-shirt Bianca Oversize',
          category: 'top',
          color: 'Bianco Ottico',
          material: 'Cotone Bio',
          tempMin: 18,
          tempMax: 30,
          imageFilename: 'https://img01.ztat.net/article/spp-media-p1/5a1138855a22486a89da87a6100946a2/1ad0d37ad355470081b122d81208f8b1.jpg',
          aiDescription: 'T-shirt a girocollo con vestibilità rilassata. Ideale come base layer o per un look minimalista estivo.',
          suitableOccasions: ['Tempo libero'],
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        ClothingItem(
          id: '4',
          userId: uid,
          name: 'Nike Air Force 1',
          category: 'shoes',
          color: 'Bianco',
          material: 'Pelle',
          tempMin: 0,
          tempMax: 25,
          imageFilename: 'https://img01.ztat.net/article/spp-media-p1/c2a84a8023d34976a197895b4eaacfb5/7f346d5d16d5404aa4963cdb628f0729.jpg?imwidth=1800',
          aiDescription: 'Sneakers high-top iconiche. L\'AI ha identificato i pannelli in pelle e la suola in gomma. Ottime per outfit urban.',
          suitableOccasions: ['Streetwear', 'Uscita'],
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),

        ClothingItem(
          id: '5',
          userId: uid,
          name: 'Colmar Piumino Leggero',
          category: 'jacket',
          color: 'Nero',
          material: 'Pelle',
          tempMin: 0,
          tempMax: 25,
          imageFilename: 'https://maxi.gumlet.io/media/catalog/product/cache/0545fe0dfa15ac1f18243c5c8f281222/c/o/colmar-originals-md22192yo-piumino-capp-tess-recycled-deluxe-donna-giacconi-donna-051404001-68_1.jpg',
          aiDescription: 'Sneakers high-top iconiche. L\'AI ha identificato i pannelli in pelle e la suola in gomma. Ottime per outfit urban.',
          suitableOccasions: ['Streetwear', 'Uscita'],
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
        ClothingItem(
          id: '6',
          userId: uid,
          name: 'Jeans Grigi',
          category: 'bottom',
          color: 'Grigio',
          material: 'Denim',
          tempMin: 0,
          tempMax: 25,
          imageFilename: 'https://maxi.gumlet.io/media/catalog/product/cache/0545fe0dfa15ac1f18243c5c8f281222/m/a/max-mara-weekend-palloress25-jeans-wide-tessuto-marmorizzato-donna-casual-donna-050735601-013_1.jpg',
          aiDescription: 'Sneakers high-top iconiche. L\'AI ha identificato i pannelli in pelle e la suola in gomma. Ottime per outfit urban.',
          suitableOccasions: ['Streetwear', 'Uscita'],
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
        ClothingItem(
          id: '7',
          userId: uid,
          name: 'Felpa Girocollo Bianca',
          category: 'top',
          color: 'Bianca',
          material: 'Cottone',
          tempMin: 0,
          tempMax: 25,
          imageFilename: 'https://maxi.gumlet.io/media/catalog/product/cache/0545fe0dfa15ac1f18243c5c8f281222/c/o/colmar-originals-mu6153r1xl-felpa-girocollo-in-ottoman-casual-uomo-052267301-06_1.jpg',
          aiDescription: 'Sneakers high-top iconiche. L\'AI ha identificato i pannelli in pelle e la suola in gomma. Ottime per outfit urban.',
          suitableOccasions: ['Streetwear', 'Uscita'],
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
        ClothingItem(
          id: '8',
          userId: uid,
          name: 'OffWhite Out of Office',
          category: 'shoes',
          color: 'Bianca',
          material: 'Cottone',
          tempMin: 0,
          tempMax: 25,
          imageFilename: 'https://img01.ztat.net/article/spp-media-p1/9be8990dbaa84135930bd66d03e0ffe0/260feb35891a4ea9b11eebc73d717156.jpg?imwidth=762',
          aiDescription: 'Sneakers high-top iconiche. L\'AI ha identificato i pannelli in pelle e la suola in gomma. Ottime per outfit urban.',
          suitableOccasions: ['Streetwear', 'Uscita'],
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
        ClothingItem(
          id: '9',
          userId: uid,
          name: 'Cardigan Costa Inglese',
          category: 'top',
          color: 'Blu',
          material: 'Cottone',
          tempMin: 0,
          tempMax: 25,
          imageFilename: 'https://maxi.gumlet.io/media/catalog/product/cache/0545fe0dfa15ac1f18243c5c8f281222/g/a/gant-8050255-cardigan-collo-sciallato-costa-inglese-casual-uomo-051644201-433_1.jpg',
          aiDescription: 'Sneakers high-top iconiche. L\'AI ha identificato i pannelli in pelle e la suola in gomma. Ottime per outfit urban.',
          suitableOccasions: ['Streetwear', 'Uscita'],
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
        ClothingItem(
          id: '11',
          userId: uid,
          name: 'Camicia Elia Loro Piana',
          category: 'top',
          color: 'Bianco',
          material: 'Cottone',
          tempMin: 0,
          tempMax: 25,
          imageFilename: 'https://media.loropiana.com/PRODUCTS/HYBRIS/FAR/FAR0338/1000/FR/AEBBBD83-A038-4EEF-AD8C-674FE8397E3A_FAR0338_1000_MEDIUM.jpg',
          aiDescription: 'Sneakers high-top iconiche. L\'AI ha identificato i pannelli in pelle e la suola in gomma. Ottime per outfit urban.',
          suitableOccasions: ['Streetwear', 'Uscita'],
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
      ];
      // https://www.thefashionisto.com/wp-content/uploads/2017/01/Burberry-Mens-Trench-Coat-Westminster-Long-Heritage-004.jpg

      setState(() {
        _clothes = mockItems;
        _stats = ClothingStats(
          total: mockItems.length,
          byCategory: {'jacket': 1, 'bottom': 1},
        );
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  // ... (Resto dei metodi _pickAndUpload, _showSourceDialog, _deleteItem rimangono identici)

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.accent,
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              _buildHeader(),
              _buildSearchBar(),
              SliverToBoxAdapter(
                child: _CategoryFilter(
                  selected: _filterCategory,
                  categories: _stats?.byCategory.keys.toList() ?? [],
                  onChanged: (cat) => setState(() => _filterCategory = cat),
                ),
              ),
              if (_stats != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: _StatsDashboard(stats: _stats!),
                  ),
                ),
              _buildGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Text('Armadio', style: TextStyle(color: AppTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(onPressed: () {}, icon: const Icon(Icons.add_circle_rounded, color: AppTheme.accent, size: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(12)),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(hintText: 'Cerca...', border: InputBorder.none, prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary)),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    if (_loading) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
    
    final filtered = _clothes.where((c) {
      if (_filterCategory != null && c.category != _filterCategory) return false;
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => _ClothingCard(
            item: filtered[i],
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClothingDetailPage(item: filtered[i]))),
            onDelete: () {},
          ),
          childCount: filtered.length,
        ),
      ),
    );
  }
}

// ── MODIFICA PER IMMAGINI WEB NELLA CARD ──────────────────────────────────────

class _ClothingCard extends StatelessWidget {
  final ClothingItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ClothingCard({required this.item, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        height: 100,
        decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: 100,
                child: item.imageFilename.startsWith('http') 
                    ? Image.network(item.imageFilename, fit: BoxFit.cover) // Se è un URL web
                    : Image.network('${ApiConfig.baseUrl}/clothes/image/${item.imageFilename}', fit: BoxFit.cover),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                    Text(item.categoryLabel, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// (Incolla qui sotto gli altri widget: ClothingDetailPage, _StatsDashboard, _CategoryFilter, ecc. dal tuo codice originale)

class ClothingDetailPage extends StatelessWidget {
  final ClothingItem item;
  const ClothingDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        // Rimuoviamo il padding globale per permettere all'immagine di espandersi
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Immagine a larghezza intera
            SizedBox(
              width: double.infinity, // Occupa tutto lo spazio orizzontale disponibile
              height: 300, // Imposta un'altezza fissa o dinamica
              child: item.imageFilename.startsWith('http') 
                  ? Image.network(item.imageFilename, fit: BoxFit.cover) 
                  : Image.network('${ApiConfig.baseUrl}/clothes/image/${item.imageFilename}', fit: BoxFit.cover),
            ),
            
            // 2. Contenuto testuale con padding
            Padding(
              padding: const EdgeInsets.all(20), // Applichiamo il padding solo ai testi
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    item.name, 
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '🌡 Temp: ${item.tempMin.toInt()}°C - ${item.tempMax.toInt()}°C', 
                    style: const TextStyle(color: AppTheme.accent)
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Analisi AI', 
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.aiDescription ?? '', 
                    style: const TextStyle(color: AppTheme.textSecondary, height: 1.5)
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsDashboard extends StatelessWidget {
  final ClothingStats stats;
  const _StatsDashboard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Text('${stats.total} capi totali', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: stats.byCategory.entries.map((e) => Chip(label: Text('${e.key}: ${e.value}'), backgroundColor: AppTheme.surface)).toList(),
          )
        ],
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  final String? selected;
  final List<String> categories;
  final ValueChanged<String?> onChanged;
  const _CategoryFilter({required this.selected, required this.categories, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          ChoiceChip(label: const Text('Tutti'), selected: selected == null, onSelected: (_) => onChanged(null)),
          const SizedBox(width: 8),
          ...categories.map((c) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(label: Text(c), selected: selected == c, onSelected: (_) => onChanged(c)),
          )),
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
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.card, padding: const EdgeInsets.symmetric(vertical: 20)),
      onPressed: onTap,
      child: Column(children: [Icon(icon, color: AppTheme.accent), Text(label, style: const TextStyle(color: AppTheme.textPrimary))]),
    );
  }
}

class _UploadingBanner extends StatelessWidget {
  const _UploadingBanner();
  @override
  Widget build(BuildContext context) {
    return const Padding(padding: EdgeInsets.all(20), child: LinearProgressIndicator(color: AppTheme.accent));
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
  }
}