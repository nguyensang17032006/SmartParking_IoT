import 'package:flutter/material.dart';
import 'package:smart_parking/features/parking/presentation/pages/parking_page.dart';

import '../theme/app_theme.dart';

/// App shell. Both destinations share one ParkingPage and its map state.
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  void _selectDestination(int index) {
    FocusScope.of(context).unfocus();
    setState(() => _selectedIndex = index);
  }

  void _showGuide() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Đỗ xe trong khuôn viên',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 18),
              _GuideStep(
                number: '1',
                title: 'Tìm chỗ trống',
                description: 'Ô màu xanh lá đang trống; ô màu đỏ đã có xe.',
              ),
              SizedBox(height: 16),
              _GuideStep(
                number: '2',
                title: 'Chọn vị trí',
                description: 'Chạm ô trống để xem đường từ cổng vào bên trái.',
              ),
              SizedBox(height: 16),
              _GuideStep(
                number: '3',
                title: 'Di chuyển theo sơ đồ',
                description:
                    'Đi theo lối ngang và rẽ vào ô đã chọn. '
                    'Chọn ô trên bản đồ chưa phải là đặt chỗ.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 76,
      titleSpacing: 20,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.local_parking_rounded,
              size: 28,
              color: AppColors.green,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Parking',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Bãi xe đại học',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Hướng dẫn đỗ xe',
          onPressed: _showGuide,
          icon: const Icon(Icons.help_outline_rounded),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: SafeArea(
      top: false,
      bottom: false,
      child: ParkingPage(
        key: const PageStorageKey('parking-home'),
        mapOnly: _selectedIndex == 1,
        onOpenMap: () => _selectDestination(1),
      ),
    ),
    bottomNavigationBar: DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE6EBEF))),
      ),
      child: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectDestination,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0xFFE0F4EA),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.greenDark),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded, color: AppColors.greenDark),
            label: 'Sơ đồ',
          ),
        ],
      ),
    ),
  );
}

class _GuideStep extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  const _GuideStep({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CircleAvatar(
        radius: 16,
        backgroundColor: const Color(0xFFE0F4EA),
        child: Text(
          number,
          style: const TextStyle(
            color: AppColors.greenDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
