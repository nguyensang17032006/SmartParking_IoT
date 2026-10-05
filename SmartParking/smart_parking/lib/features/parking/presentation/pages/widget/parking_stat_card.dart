import 'package:flutter/material.dart';
import 'package:smart_parking/core/theme/app_theme.dart';

import '../../../domain/entities/parking_overview.dart';

class ParkingStatsGrid extends StatelessWidget {
  final ParkingOverview? overview;
  const ParkingStatsGrid({super.key, this.overview});

  @override
  Widget build(BuildContext context) {
    final summary = overview;
    final percent = summary == null
        ? '—'
        : '${(summary.occupancyRate * 100).round()}%';
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 680 ? 4 : 2;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        final cards = [
          ParkingStatCard(
            label: 'Còn trống',
            value: summary?.availableCount.toString() ?? '—',
            icon: Icons.local_parking_rounded,
            foreground: AppColors.greenDark,
            background: const Color(0xFFE8F7F0),
          ),
          ParkingStatCard(
            label: 'Đang có xe',
            value: summary?.occupiedCount.toString() ?? '—',
            icon: Icons.directions_car_outlined,
            foreground: AppColors.secondaryDark,
            background: const Color(0xFFFDEDF0),
          ),
          ParkingStatCard(
            label: 'Tổng số ô',
            value: summary?.totalCount.toString() ?? '—',
            icon: Icons.grid_view_rounded,
            foreground: const Color(0xFF356AE6),
            background: const Color(0xFFEDF3FF),
          ),
          ParkingStatCard(
            label: 'Tỷ lệ lấp đầy',
            value: percent,
            icon: Icons.pie_chart_outline_rounded,
            foreground: const Color(0xFF9B6B16),
            background: const Color(0xFFFFF5DF),
          ),
        ];
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }
}

class ParkingStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color foreground;
  final Color background;
  const ParkingStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE6EBEF)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 21, color: foreground),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            height: 1.1,
            fontWeight: FontWeight.w800,
            color: foreground,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ],
    ),
  );
}
