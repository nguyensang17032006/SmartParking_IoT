
import 'package:flutter/material.dart';

class MainBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MainBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const primary = Color(0xFFF0194B);
  static const inactive = Color(0xFF8791A4);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 72,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            navItem(
              0,
              Icons.home_rounded,
              'Trang chủ',
            ),
            navItem(
              1,
              Icons.history_rounded,
              'Lịch sử',
            ),
            GestureDetector(
              onTap: () => onTap(2),
              child: Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 29,
                ),
              ),
            ),
            navItem(
              3,
              Icons.notifications_none_rounded,
              'Thông báo',
            ),
            navItem(
              4,
              Icons.person_outline_rounded,
              'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }

  Widget navItem(
    int index,
    IconData icon,
    String label,
  ) {
    final selected = currentIndex == index;

    return InkWell(
      onTap: () => onTap(index),
      child: SizedBox(
        width: 62,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: selected ? primary : inactive,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: selected ? primary : inactive,
                fontWeight: selected
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
