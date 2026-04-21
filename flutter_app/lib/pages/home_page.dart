import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../config/app_theme.dart';
import '../models/outfit.dart';
import '../models/weather.dart';
import '../models/clothing.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';
import '../widgets/outfit_card.dart';
import '../widgets/weather_widget.dart';
import 'add_event_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  Weather? _weather;
  List<Outfit> _likedOutfits = [];
  Position? _position;
  bool _loadingWeather = true;
  bool _loadingOutfits = false;
  bool _generatingOutfit = false;
  String? _error;
  String? _userId;

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
    await _loadLocation();
    await Future.wait([_loadWeather()]);
  }

  Future<void> _loadLocation() async {
    try {
      _position = await LocationService.getCurrentPosition();
    } catch (e) {
      // Default to Rome if location unavailable
      _position = null;
    }
  }

  Future<void> _loadWeather() async {
    setState(() => _loadingWeather = true);
    try {
      final lat = _position?.latitude ?? 45.852691;
      final lon = _position?.longitude ?? 9.405476;
      final weather = await ApiService.getWeather(lat, lon);
      setState(() {
        _weather = weather;
        _loadingWeather = false;
      });
    } catch (e) {
      print(e);
      setState(() {
        _error = 'Impossibile caricare il meteo';
        _loadingWeather = false;
      });
    }
  }

  Future<void> _loadLikedOutfits() async {
    if (_userId == null) return;
    
    // Simuliamo un ritardo di caricamento
    await Future.delayed(const Duration(milliseconds: 600));

    try {
      final uid = _userId!;
      final DateTime now = DateTime.now();

      // DATI HARDCODED: Lista di Outfit di prova
      final mockOutfits = [
        // 1. OUTFIT CASUAL INVERNALE
        Outfit(
          id: 'outfit_1',
          userId: uid,
          liked: true,
          occasion: 'casual',
          temperature: 8.0,
          weatherCondition: 'Nuvoloso',
          aiExplanation: 'Un look perfetto per una passeggiata in città con temperature fresche.',
          createdAt: now,
          items: [
            _createMockItem('101', uid, 'Piumino Nero', 'jacket', 1, 'https://maxi.gumlet.io/media/catalog/product/cache/0545fe0dfa15ac1f18243c5c8f281222/c/o/colmar-originals-md22192yo-piumino-capp-tess-recycled-deluxe-donna-giacconi-donna-051404001-68_1.jpg'),
            _createMockItem('102', uid, 'Felpa Girocollo Bianca', 'top', 2, 'https://maxi.gumlet.io/media/catalog/product/cache/0545fe0dfa15ac1f18243c5c8f281222/c/o/colmar-originals-mu6153r1xl-felpa-girocollo-in-ottoman-casual-uomo-052267301-06_1.jpg'),
            _createMockItem('103', uid, 'Jeans Grigio', 'bottom', 3, 'https://maxi.gumlet.io/media/catalog/product/cache/0545fe0dfa15ac1f18243c5c8f281222/m/a/max-mara-weekend-palloress25-jeans-wide-tessuto-marmorizzato-donna-casual-donna-050735601-013_1.jpg'),
            _createMockItem('104', uid, 'Sneakers Alte', 'shoes', 4, 'https://img01.ztat.net/article/spp-media-p1/c2a84a8023d34976a197895b4eaacfb5/7f346d5d16d5404aa4963cdb628f0729.jpg?imwidth=1800'),
          ],
        ),

        Outfit(
          id: 'outfit_2',
          userId: uid,
          liked: true,
          occasion: 'casual/formale',
          temperature: 12.0,
          weatherCondition: 'Nuvoloso',
          aiExplanation: 'Un look sia casual che formale per temperature fresche.',
          createdAt: now,
          items: [
            _createMockItem('101', uid, 'Cardigan', 'jacket', 1, 'https://maxi.gumlet.io/media/catalog/product/cache/0545fe0dfa15ac1f18243c5c8f281222/g/a/gant-8050255-cardigan-collo-sciallato-costa-inglese-casual-uomo-051644201-433_1.jpg'),
            _createMockItem('102', uid, 'Camicia Bianca', 'top', 2, 'https://media.loropiana.com/PRODUCTS/HYBRIS/FAR/FAR0338/1000/FR/AEBBBD83-A038-4EEF-AD8C-674FE8397E3A_FAR0338_1000_MEDIUM.jpg'),
            _createMockItem('103', uid, 'Jeans Grigio', 'bottom', 3, 'https://maxi.gumlet.io/media/catalog/product/cache/0545fe0dfa15ac1f18243c5c8f281222/m/a/max-mara-weekend-palloress25-jeans-wide-tessuto-marmorizzato-donna-casual-donna-050735601-013_1.jpg'),
            _createMockItem('104', uid, 'Sneakers Alte', 'shoes', 4, 'https://img01.ztat.net/article/spp-media-p1/9be8990dbaa84135930bd66d03e0ffe0/260feb35891a4ea9b11eebc73d717156.jpg?imwidth=762'),
          ],
        ),
      ];

      setState(() {
        _likedOutfits = mockOutfits;
      });
    } catch (e) {
    }
  }

  // Funzione helper per creare rapidamente OutfitItem di test
  OutfitItem _createMockItem(String id, String uid, String name, String cat, int order, String link) {
    return OutfitItem(
      clothingId: id,
      layerOrder: order,
      clothing: ClothingItem(
        id: id,
        userId: uid,
        name: name,
        category: cat,
        color: 'Default',
        material: 'Cotone',
        tempMin: 0,
        tempMax: 30,
        suitableOccasions: [],
        imageFilename: link, // Immagine generica
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> _generateOutfit({String? occasion}) async {
    if (_userId == null) return;
    setState(() => _generatingOutfit = true);
    setState(() => _loadingOutfits = true);
    await Future.delayed(const Duration(seconds: 5));
    setState(() => _generatingOutfit = false);
    setState(() => _loadingOutfits = false);
    _loadLikedOutfits();
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

  Future<void> _showGenerateOptions() async {
    final occasions = ['casual', 'formal', 'sport', 'business', 'party'];
    String? selected;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.secondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Che occasione è?',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lascia vuoto per usare il calendario',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _OccasionChip(
                  label: 'Dal Calendario',
                  selected: selected == null,
                  onTap: () {
                    Navigator.pop(ctx);
                    _generateOutfit();
                  },
                ),
                ...occasions.map((o) => _OccasionChip(
                      label: _occasionEmoji(o),
                      selected: selected == o,
                      onTap: () {
                        Navigator.pop(ctx);
                        _generateOutfit(occasion: o);
                      },
                    )),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _occasionEmoji(String o) {
    const map = {
      'casual': 'Casual',
      'formal': 'Formale',
      'sport': 'Sport',
      'business': 'Business',
      'party': 'Party',
    };
    return map[o] ?? o;
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
          onRefresh: () async {
            await _loadLocation();
            await Future.wait([_loadWeather(), _loadLikedOutfits()]);
          },
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      const Text(
                        'Driply',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.calendar_month, color: AppTheme.textSecondary),
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => AddEventSheet(userId: _userId ?? ''),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
                        onPressed: () async {
                          await _loadLocation();
                          await Future.wait([_loadWeather(), _loadLikedOutfits()]);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Weather
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _loadingWeather
                      ? const WeatherWidgetSkeleton()
                      : _weather != null
                          ? WeatherWidget(weather: _weather!)
                          : _ErrorCard(message: _error ?? 'Errore meteo', onRetry: _loadWeather),
                ),
              ),

              // Generate button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _generatingOutfit
                      ? const _GeneratingIndicator()
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showGenerateOptions,
                            label: const Text('Genera Outfit del Giorno'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                ),
              ),

              // Liked outfits section
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Row(
                    children: [
                      Text(
                        'Outfit generati',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Outfits grid 2x2
              if (_generatingOutfit)
                const SliverToBoxAdapter(child: _OutfitGridSkeleton())
              else if (_likedOutfits.isEmpty && !_generatingOutfit)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          Text('👗', style: TextStyle(fontSize: 48)),
                          SizedBox(height: 12),
                          Text(
                            'Nessun outfit salvato ancora.\nGenera il tuo primo outfit!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.68,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final outfit = _likedOutfits[i];
                        return OutfitCard(
                          outfit: outfit,
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => OutfitDetailSheet(outfit: outfit),
                          ),
                        );
                      },
                      childCount: _likedOutfits.take(4).length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GeneratingIndicator extends StatelessWidget {
  const _GeneratingIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
          ),
          SizedBox(width: 14),
          Text(
            'L\'AI sta creando il tuo outfit...',
            style: TextStyle(color: AppTheme.accent, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: AppTheme.textSecondary, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: const TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onRetry,
                  child: const Text('Riprova'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutfitGridSkeleton extends StatelessWidget {
  const _OutfitGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.68,
        children: List.generate(
          4,
          (_) => Container(
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}

class _OccasionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OccasionChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent : AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.accent : AppTheme.surface,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
