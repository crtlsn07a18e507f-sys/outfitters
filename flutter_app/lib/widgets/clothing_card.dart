import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../models/clothing.dart';

class ClothingCard extends StatelessWidget {
  final ClothingItem item;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const ClothingCard({
    super.key,
    required this.item,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Stack(
                  children: [
                    SizedBox.expand(
                      child: CachedNetworkImage(
                        imageUrl: ApiConfig.imageUrl(item.imageFilename),
                        fit: BoxFit.cover,
                        placeholder: (ctx, url) => Container(
                          color: AppTheme.surface,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (ctx, url, err) => Container(
                          color: AppTheme.surface,
                          child: Center(
                            child: Text(item.categoryIcon, style: const TextStyle(fontSize: 48)),
                          ),
                        ),
                      ),
                    ),
                    // Category badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _CategoryBadge(item.categoryLabel),
                    ),
                    // Delete button
                    if (onDelete != null)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () => _confirmDelete(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.color,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.thermostat, size: 12, color: AppTheme.accent),
                      const SizedBox(width: 2),
                      Text(
                        '${item.tempMin.round()}° – ${item.tempMax.round()}°',
                        style: const TextStyle(color: AppTheme.accent, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Elimina capo', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Vuoi eliminare "${item.name}"?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimina', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete?.call();
  }
}

class _CategoryBadge extends StatelessWidget {
  final String label;
  const _CategoryBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}
