import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';
import '../models/weather.dart';

class WeatherWidget extends StatelessWidget {
  final Weather weather;

  const WeatherWidget({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A3A6B), Color(0xFF0D2444)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: temp + city
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weather.city,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${weather.temperature.round()}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 64,
                        fontWeight: FontWeight.w300,
                        height: 1,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        '°C',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  weather.description,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                _WeatherDetail(
                  icon: Icons.thermostat,
                  label: 'Percepita ${weather.feelsLike.round()}°C',
                ),
                const SizedBox(height: 4),
                _WeatherDetail(
                  icon: Icons.water_drop_outlined,
                  label: 'Umidità ${weather.humidity}%',
                ),
                const SizedBox(height: 4),
                _WeatherDetail(
                  icon: Icons.air,
                  label: 'Vento ${weather.windSpeed.round()} km/h',
                ),
              ],
            ),
          ),

          // Right: icon + emoji
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CachedNetworkImage(
                  imageUrl: weather.iconUrl,
                  width: 90,
                  height: 90,
                  errorWidget: (_, __, ___) => Text(
                    weather.weatherEmoji,
                    style: const TextStyle(fontSize: 64),
                  ),
                ),
                Text(
                  weather.weatherEmoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherDetail extends StatelessWidget {
  final IconData icon;
  final String label;

  const _WeatherDetail({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

// Loading skeleton
class WeatherWidgetSkeleton extends StatefulWidget {
  const WeatherWidgetSkeleton({super.key});

  @override
  State<WeatherWidgetSkeleton> createState() => _WeatherWidgetSkeletonState();
}

class _WeatherWidgetSkeletonState extends State<WeatherWidgetSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (ctx, _) => Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppTheme.card.withOpacity(_animation.value + 0.3),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}
