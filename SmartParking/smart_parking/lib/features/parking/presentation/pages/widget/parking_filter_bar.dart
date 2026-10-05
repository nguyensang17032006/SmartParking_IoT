import 'package:flutter/material.dart';
import 'package:smart_parking/core/theme/app_theme.dart';

class ParkingFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final bool onlyFree;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<bool> onOnlyFreeChanged;
  final VoidCallback onClear;
  const ParkingFilterBar({
    super.key,
    required this.controller,
    required this.onlyFree,
    required this.onQueryChanged,
    required this.onOnlyFreeChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextField(
        controller: controller,
        onChanged: onQueryChanged,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(
          hintText: 'Tìm mã ô, ví dụ A01',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Xóa tìm kiếm',
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                ),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE6EBEF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE6EBEF)),
          ),
        ),
      ),
      const SizedBox(height: 10),
      FilterChip(
        selected: onlyFree,
        onSelected: onOnlyFreeChanged,
        avatar: const Icon(Icons.local_parking_rounded, size: 17),
        label: const Text('Chỉ hiện ô trống'),
        selectedColor: const Color(0xFFE8F7F0),
        checkmarkColor: AppColors.greenDark,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        side: const BorderSide(color: Color(0xFFE6EBEF)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ],
  );
}
