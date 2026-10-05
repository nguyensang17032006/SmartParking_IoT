import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_parking/core/theme/app_theme.dart';

import '../../domain/entities/parking_overview.dart';
import '../../domain/entities/parking_slot.dart';
import '../parking_bloc/parking_bloc.dart';
import '../parking_bloc/parking_event.dart';
import '../parking_bloc/parking_state.dart';
import 'widget/parking_availability_card.dart';
import 'widget/parking_feedback_panel.dart';
import 'widget/parking_filter_bar.dart';
import 'widget/parking_home_header.dart';
import 'widget/parking_map.dart';
import 'widget/parking_stat_card.dart';

/// Content only. MainLayout owns the Scaffold, AppBar and navigation.
class ParkingPage extends StatefulWidget {
  final bool mapOnly;
  final VoidCallback? onOpenMap;
  final List<String> topRowCodes;
  final List<String> bottomRowCodes;

  const ParkingPage({
    super.key,
    this.mapOnly = false,
    this.onOpenMap,
    this.topRowCodes = const ['A01', 'A02', 'A03'],
    this.bottomRowCodes = const ['B01', 'B02', 'B03'],
  });

  @override
  State<ParkingPage> createState() => _ParkingPageState();
}

class _ParkingPageState extends State<ParkingPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _mapAnchor = GlobalKey();
  bool _onlyFree = false;

  @override
  void didUpdateWidget(covariant ParkingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mapOnly != widget.mapOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _viewMap() {
    FocusScope.of(context).unfocus();
    if (widget.onOpenMap != null) {
      widget.onOpenMap!();
      return;
    }
    final target = _mapAnchor.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _mapContent(ParkingState state, Set<String>? highlightedCodes) {
    if (state is ParkingInitial || state is ParkingLoading) {
      return const ParkingFeedbackPanel(
        title: 'Đang tải bãi xe',
        message: 'Đang cập nhật trạng thái các ô đỗ.',
        loading: true,
      );
    }
    if (state is ParkingError) {
      return ParkingFeedbackPanel(
        title: 'Chưa tải được dữ liệu',
        message: 'Kiểm tra kết nối mạng rồi thử lại.',
        icon: Icons.wifi_off_rounded,
        onRetry: () =>
            context.read<ParkingBloc>().add(const ParkingWatchStarted()),
      );
    }
    if (state is ParkingLoaded) {
      if (state.slots.isEmpty) {
        return const ParkingFeedbackPanel(
          title: 'Chưa có ô đỗ',
          message: 'Sơ đồ sẽ xuất hiện khi bãi xe có dữ liệu.',
          icon: Icons.local_parking_rounded,
        );
      }
      return ParkingMap(
        key: const ValueKey('campus-parking-map'),
        slots: state.slots,
        topRowCodes: widget.topRowCodes,
        bottomRowCodes: widget.bottomRowCodes,
        highlightedCodes: highlightedCodes,
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<ParkingBloc, ParkingState>(
    builder: (context, state) {
      final slots = state is ParkingLoaded
          ? state.slots
          : const <ParkingSlot>[];
      final overview = state is ParkingLoaded
          ? ParkingOverview.fromOccupancy(slots.map((slot) => slot.occupied))
          : null;
      final query = _searchController.text.trim().toUpperCase();
      final filtering = query.isNotEmpty || _onlyFree;
      final placed = {...widget.topRowCodes, ...widget.bottomRowCodes};
      final matches = slots
          .where(
            (slot) =>
                placed.contains(slot.code) &&
                slot.code.toUpperCase().contains(query) &&
                (!_onlyFree || !slot.occupied),
          )
          .map((slot) => slot.code)
          .toSet();
      final highlighted = filtering ? matches : null;

      return SingleChildScrollView(
        controller: _scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ParkingHomeHeader(
                    key: const ValueKey('parking-heading'),
                    mapOnly: widget.mapOnly,
                  ),
                  if (!widget.mapOnly)
                    Padding(
                      key: const ValueKey('parking-overview'),
                      padding: const EdgeInsets.only(top: 24, bottom: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (overview != null && overview.totalCount > 0) ...[
                            ParkingAvailabilityCard(
                              overview: overview,
                              onViewMap: _viewMap,
                            ),
                            const SizedBox(height: 20),
                          ],
                          ParkingStatsGrid(overview: overview),
                        ],
                      ),
                    ),
                  // Stable key keeps map selection/zoom when switching tabs.
                  Padding(
                    key: const ValueKey('parking-map-section'),
                    padding: EdgeInsets.only(top: widget.mapOnly ? 24 : 0),
                    child: Column(
                      key: _mapAnchor,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!widget.mapOnly) ...[
                          const Text(
                            'Khám phá bãi xe',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tìm ô trống ngay trên sơ đồ.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        ParkingFilterBar(
                          key: const ValueKey('parking-filters'),
                          controller: _searchController,
                          onlyFree: _onlyFree,
                          onQueryChanged: (_) => setState(() {}),
                          onOnlyFreeChanged: (value) =>
                              setState(() => _onlyFree = value),
                          onClear: () => setState(_searchController.clear),
                        ),
                        const SizedBox(height: 14),
                        if (state is ParkingLoaded &&
                            slots.isNotEmpty &&
                            filtering &&
                            matches.isEmpty) ...[
                          const Text(
                            'Không có ô trên sơ đồ phù hợp với bộ lọc.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        KeyedSubtree(
                          key: const ValueKey('parking-map-content'),
                          child: _mapContent(state, highlighted),
                        ),
                        const SizedBox(height: 18),
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 17,
                              color: AppColors.textMuted,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Đi từ cổng vào bên trái theo chiều mũi tên. '
                                'Chạm ô trống để xem tuyến đến vị trí đỗ.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.5,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
