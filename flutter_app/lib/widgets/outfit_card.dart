import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../models/outfit.dart';

class OutfitCard extends StatelessWidget {
  final Outfit outfit;
  final VoidCallback? onTap;
  final bool showActions;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;

  const OutfitCard({
    super.key,
    required this.outfit,
    this.onTap,
    this.showActions = false,
    this.onLike,
    this.onDislike,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Stacked outfit images
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: _OutfitStack(items: outfit.stackedItems),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (outfit.occasion != null) ...[
                        _OccasionChip(outfit.occasion!),
                        const SizedBox(width: 6),
                      ],
                      if (outfit.temperature != null)
                        _TempChip(outfit.temperature!),
                    ],
                  ),
                  if (showActions) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionBtn(
                            icon: Icons.thumb_up_rounded,
                            color: AppTheme.success,
                            onTap: onLike,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionBtn(
                            icon: Icons.thumb_down_rounded,
                            color: AppTheme.error,
                            onTap: onDislike,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutfitStack extends StatelessWidget {
  final List<OutfitItem> items;

  const _OutfitStack({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Icon(Icons.checkroom, size: 48, color: AppTheme.textSecondary),
      );
    }

    // Show items stacked vertically (each item takes a proportional space)
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemHeight = constraints.maxHeight / items.length;
        return Stack(
          children: [
            // Background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0F1B35), Color(0xFF1A2A4A)],
                ),
              ),
            ),
            // Vertically stacked items
            Column(
              children: items.map((item) {
                return SizedBox(
                  height: itemHeight,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: ApiConfig.imageUrl(item.clothing.imageFilename),
                    fit: BoxFit.contain,
                    placeholder: (ctx, url) => const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (ctx, url, err) => Center(
                      child: Text(
                        item.clothing.categoryIcon,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

class _OccasionChip extends StatelessWidget {
  final String occasion;
  const _OccasionChip(this.occasion);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        occasion,
        style: const TextStyle(
          fontSize: 10,
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _TempChip extends StatelessWidget {
  final double temperature;
  const _TempChip(this.temperature);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${temperature.round()}°C',
        style: const TextStyle(
          fontSize: 10,
          color: AppTheme.accent,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionBtn({required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

// ── Full-screen Outfit Viewer ─────────────────────────────────────────────

class OutfitDetailSheet extends StatelessWidget {
  final Outfit outfit;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;

  const OutfitDetailSheet({
    super.key,
    required this.outfit,
    this.onLike,
    this.onDislike,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.secondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textSecondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Il tuo Outfit',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),

          // Items
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: outfit.stackedItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final item = outfit.stackedItems[i];
                return _OutfitItemRow(item: item);
              },
            ),
          ),

          // AI Explanation
          if (outfit.aiExplanation != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      outfit.aiExplanation!,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Like / Dislike
          Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom + 20,
              top: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onDislike,
                    icon: const Icon(Icons.thumb_down_rounded),
                    label: const Text('Non mi piace'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error.withOpacity(0.15),
                      foregroundColor: AppTheme.error,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onLike,
                    icon: const Icon(Icons.thumb_up_rounded),
                    label: const Text('Mi piace!'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutfitItemRow extends StatelessWidget {
  final OutfitItem item;

  const _OutfitItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 70,
              height: 70,
              child: CachedNetworkImage(
                imageUrl: ApiConfig.imageUrl(item.clothing.imageFilename),
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Center(
                  child: Text(item.clothing.categoryIcon, style: const TextStyle(fontSize: 30)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.clothing.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.clothing.categoryLabel} • ${item.clothing.color}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                Text(
                  item.clothing.material,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            item.clothing.categoryIcon,
            style: const TextStyle(fontSize: 24),
          ),
        ],
      ),
    );
  }
}
