import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/parking_slot.dart';
import '../parking_bloc/parking_bloc.dart';
import '../parking_bloc/parking_state.dart';

/// Home content. MainLayout owns the Scaffold and navigation.
/// Requires an existing BlocProvider<ParkingBloc> above this widget.
class ParkingPage extends StatefulWidget {
  const ParkingPage({super.key});

  @override
  State<ParkingPage> createState() => _ParkingPageState();
}

class _ParkingPageState extends State<ParkingPage> {
  int _filter = 0;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _ParkingColors.background,
      child: BlocBuilder<ParkingBloc, ParkingState>(
        builder: (context, state) {
          final loaded = state is ParkingLoaded;
          final loading = state is ParkingLoading || state is ParkingInitial;
          final slots = state is ParkingLoaded
              ? state.slots
              : const <ParkingSlot>[];
          final total = slots.length;
          final occupied = slots.where((s) => s.occupied).length;
          final free = total - occupied;
          final query = _query.trim().toLowerCase();
          final visible = slots.where((slot) {
            final matchesState =
                _filter == 0 ||
                (_filter == 1 && !slot.occupied) ||
                (_filter == 2 && slot.occupied);
            return matchesState && slot.code.toLowerCase().contains(query);
          }).toList();

          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BÃI XE TRƯỜNG ĐẠI HỌC',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                          color: _ParkingColors.muted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tìm chỗ đỗ của bạn',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: _ParkingColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Theo dõi trạng thái các ô đỗ trong khuôn viên.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: _ParkingColors.muted,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (loaded && total > 0) ...[
                        _AvailabilityCard(free: free, total: total),
                        const SizedBox(height: 16),
                      ],
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 640 ? 4 : 2;
                          final width =
                              (constraints.maxWidth - (columns - 1) * 12) /
                              columns;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: width,
                                child: _StatCard(
                                  label: 'Trống',
                                  value: loaded ? '$free' : '—',
                                  icon: Icons.local_parking_rounded,
                                  color: _ParkingColors.green,
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: _StatCard(
                                  label: 'Có xe',
                                  value: loaded ? '$occupied' : '—',
                                  icon: Icons.directions_car_rounded,
                                  color: _ParkingColors.red,
                                ),
                              ),
                              // The current model only contains `occupied`.
                              SizedBox(
                                width: width,
                                child: const _StatCard(
                                  label: 'Đã đặt',
                                  value: '—',
                                  icon: Icons.bookmark_outline_rounded,
                                  color: _ParkingColors.amber,
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: const _StatCard(
                                  label: 'Mất kết nối',
                                  value: '—',
                                  icon: Icons.wifi_off_rounded,
                                  color: _ParkingColors.muted,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Vị trí đỗ xe',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: _ParkingColors.ink,
                              ),
                            ),
                          ),
                          if (loaded)
                            Text(
                              '${visible.length}/$total ô',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _ParkingColors.muted,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        onChanged: (value) => setState(() => _query = value),
                        decoration: InputDecoration(
                          hintText: 'Tìm mã ô, ví dụ A01',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: _ParkingColors.line,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: _ParkingColors.line,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: _ParkingColors.blue,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final (index, label) in [
                            (0, 'Tất cả'),
                            (1, 'Trống'),
                            (2, 'Có xe'),
                          ])
                            ChoiceChip(
                              label: Text(label),
                              selected: _filter == index,
                              onSelected: (_) =>
                                  setState(() => _filter = index),
                              showCheckmark: false,
                              backgroundColor: Colors.white,
                              selectedColor: _ParkingColors.blue,
                              labelStyle: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _filter == index
                                    ? Colors.white
                                    : _ParkingColors.muted,
                              ),
                              side: BorderSide(
                                color: _filter == index
                                    ? _ParkingColors.blue
                                    : _ParkingColors.line,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (loading)
                        const _StatusPanel(
                          loading: true,
                          title: 'Đang tải bãi xe',
                          description: 'Vui lòng chờ dữ liệu trạng thái ô đỗ.',
                        )
                      else if (state is ParkingError)
                        _StatusPanel(
                          icon: Icons.error_outline_rounded,
                          title: 'Không tải được dữ liệu',
                          description: state.message,
                        )
                      else if (!loaded || total == 0)
                        const _StatusPanel(
                          icon: Icons.local_parking_rounded,
                          title: 'Chưa có ô đỗ xe',
                          description: 'Các ô đỗ sẽ hiển thị khi có dữ liệu.',
                        )
                      else if (visible.isEmpty)
                        const _StatusPanel(
                          icon: Icons.search_off_rounded,
                          title: 'Không tìm thấy ô phù hợp',
                          description:
                              'Thử mã ô khác hoặc đổi bộ lọc trạng thái.',
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: visible.length,
                          gridDelegate:
                              SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 240,
                                mainAxisExtent:
                                    170 +
                                    MediaQuery.textScalerOf(context).scale(14),
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          itemBuilder: (context, index) {
                            final slot = visible[index];
                            return _SlotCard(
                              code: slot.code,
                              occupied: slot.occupied,
                            );
                          },
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ParkingColors {
  static const background = Color(0xFFF4F6FA);
  static const ink = Color(0xFF172A46);
  static const muted = Color(0xFF7B879B);
  static const line = Color(0xFFE4E9F1);
  static const blue = Color(0xFF356AE6);
  static const green = Color(0xFF168A65);
  static const red = Color(0xFFDC5A64);
  static const amber = Color(0xFFC28A28);
}

class _AvailabilityCard extends StatelessWidget {
  final int free;
  final int total;
  const _AvailabilityCard({required this.free, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _ParkingColors.ink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CHỖ ĐỖ HIỆN TẠI',
                      style: TextStyle(
                        color: Color(0xFFB5C4DD),
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      free > 0 ? '$free ô đang trống' : 'Bãi xe đã hết chỗ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                free > 0
                    ? Icons.local_parking_rounded
                    : Icons.directions_car_rounded,
                size: 42,
                color: const Color(0xFF96B5FF),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: free / total,
              minHeight: 7,
              backgroundColor: const Color(0xFF334766),
              color: const Color(0xFF65D6AC),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            '$free/$total ô còn trống · '
            '${(free / total * 100).round()}% số ô khả dụng',
            style: const TextStyle(color: Color(0xFFB5C4DD), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _ParkingColors.line),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _ParkingColors.muted,
          ),
        ),
      ],
    ),
  );
}

class _SlotCard extends StatelessWidget {
  final String code;
  final bool occupied;
  const _SlotCard({required this.code, required this.occupied});

  @override
  Widget build(BuildContext context) {
    final color = occupied ? _ParkingColors.red : _ParkingColors.green;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            code,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _ParkingColors.ink,
            ),
          ),
          Center(
            child: Icon(
              occupied
                  ? Icons.directions_car_rounded
                  : Icons.local_parking_rounded,
              size: 46,
              color: color,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              occupied ? 'Có xe' : 'Trống',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool loading;
  const _StatusPanel({
    required this.title,
    required this.description,
    this.icon = Icons.info_outline_rounded,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _ParkingColors.line),
    ),
    child: Column(
      children: [
        if (loading)
          const SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: _ParkingColors.blue,
            ),
          )
        else
          Icon(icon, size: 36, color: _ParkingColors.muted),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _ParkingColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            color: _ParkingColors.muted,
          ),
        ),
      ],
    ),
  );
}
