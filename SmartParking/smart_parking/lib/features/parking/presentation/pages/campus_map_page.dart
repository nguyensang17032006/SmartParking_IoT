import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/parking_lot_remote_data_source.dart';
import '../../data/datasources/parking_map_remote_data_source.dart';
import '../../data/datasources/parking_slot_remote_data_source.dart';

import '../../data/repositories/parking_lot_repository_impl.dart';
import '../../data/repositories/parking_map_repository_impl.dart';
import '../../data/repositories/parking_slot_repository_impl.dart';

import '../../domain/entities/parking_lot.dart';
import '../../domain/entities/map_element.dart';
import '../../domain/entities/map_version.dart';
import '../../domain/entities/parking_slot.dart';

import '../../domain/usecases/get_parking_lots.dart';
import '../../domain/usecases/get_map_elements.dart';
import '../../domain/usecases/get_published_map_version.dart';
import '../../domain/usecases/watch_parking_slots.dart';

import '../widgets/parking_map_painter.dart';

class CampusMapPage extends StatefulWidget {
  final String campusId;

  const CampusMapPage({super.key, required this.campusId});

  @override
  State<CampusMapPage> createState() => _CampusMapPageState();
}

class _CampusMapPageState extends State<CampusMapPage> {
  static const double cellSize = 20;

  late final ParkingMapRemoteDataSourceImpl mapDataSource;

  late final GetParkingLots getParkingLots;
  late final GetPublishedMapVersion getPublishedMapVersion;
  late final GetMapElements getMapElements;
  late final WatchParkingSlots watchParkingSlots;

  List<ParkingLot> parkingLots = [];
  String? selectedLotId;

  MapVersion? mapVersion;

  List<Map<String, dynamic>> floors = [];
  String? selectedFloorId;

  late Future<void> initialFuture;
  Future<void>? lotFuture;
  Future<List<MapElement>>? elementsFuture;

  Stream<List<ParkingSlot>>? slotsStream;

  // Dùng để bỏ qua kết quả của request cũ.
  int _requestVersion = 0;

  @override
  void initState() {
    super.initState();

    final supabase = Supabase.instance.client;

    // 1. Parking Lot
    final lotDataSource = ParkingLotRemoteDataSourceImpl(supabase);

    final lotRepository = ParkingLotRepositoryImpl(lotDataSource);

    getParkingLots = GetParkingLots(lotRepository);

    // 2. Parking Map
    mapDataSource = ParkingMapRemoteDataSourceImpl(supabase);

    final mapRepository = ParkingMapRepositoryImpl(mapDataSource);

    getPublishedMapVersion = GetPublishedMapVersion(mapRepository);

    getMapElements = GetMapElements(mapRepository);

    // 3. Parking Slot Realtime
    final slotDataSource = ParkingSlotRemoteDataSourceImpl(supabase);

    final slotRepository = ParkingSlotRepositoryImpl(slotDataSource);

    watchParkingSlots = WatchParkingSlots(slotRepository);

    // Tạo stream một lần, không tạo lại trong build().
    slotsStream = watchParkingSlots();

    // 4. Tải dữ liệu ban đầu
    initialFuture = _loadInitialData();
  }

  // =====================================================
  // LOAD CAMPUS -> PARKING LOTS
  // =====================================================

  Future<void> _loadInitialData() async {
    final requestId = ++_requestVersion;

    final lots = await getParkingLots(widget.campusId);

    if (!mounted || requestId != _requestVersion) {
      return;
    }

    parkingLots = lots;

    // Giữ bãi xe đang chọn nếu vẫn còn trong danh sách.
    final currentLotExists = lots.any((lot) => lot.id == selectedLotId);

    selectedLotId = currentLotExists
        ? selectedLotId
        : (lots.isNotEmpty ? lots.first.id : null);

    if (selectedLotId == null) {
      _clearMapData();
      lotFuture = null;
      return;
    }

    final future = _loadSelectedLot(selectedLotId!, requestId);

    lotFuture = future;

    await future;
  }

  // =====================================================
  // LOAD SELECTED PARKING LOT
  // =====================================================

  Future<void> _loadSelectedLot(String lotId, int requestId) async {
    _clearMapData();

    // Lấy Map Version published của bãi xe.
    final version = await getPublishedMapVersion(lotId);

    if (!mounted || requestId != _requestVersion) {
      return;
    }

    if (version == null) {
      return;
    }

    // Lấy các tầng thuộc bãi xe.
    final floorData = await mapDataSource.getFloors(lotId);

    if (!mounted || requestId != _requestVersion) {
      return;
    }

    mapVersion = version;
    floors = floorData;

    if (floorData.isEmpty) {
      selectedFloorId = null;
      elementsFuture = null;
      return;
    }

    // Mặc định chọn tầng đầu tiên.
    selectedFloorId = floorData.first['id'] as String;

    elementsFuture = getMapElements(version.id, selectedFloorId!);
  }

  void _clearMapData() {
    mapVersion = null;
    floors = [];
    selectedFloorId = null;
    elementsFuture = null;
  }

  // =====================================================
  // SELECT PARKING LOT
  // =====================================================

  void _selectLot(String? lotId) {
    if (lotId == null || lotId == selectedLotId) {
      return;
    }

    final requestId = ++_requestVersion;

    setState(() {
      selectedLotId = lotId;

      lotFuture = _loadSelectedLot(lotId, requestId);
    });
  }

  // =====================================================
  // SELECT FLOOR
  // =====================================================

  void _selectFloor(String floorId) {
    if (floorId == selectedFloorId || mapVersion == null) {
      return;
    }

    setState(() {
      selectedFloorId = floorId;

      // Chỉ tải lại cấu trúc bản đồ của tầng mới.
      elementsFuture = getMapElements(mapVersion!.id, floorId);
    });
  }

  // =====================================================
  // REFRESH
  // =====================================================

  void _refresh() {
    setState(() {
      initialFuture = _loadInitialData();
    });
  }

  @override
  void didUpdateWidget(covariant CampusMapPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.campusId != widget.campusId) {
      setState(() {
        selectedLotId = null;
        initialFuture = _loadInitialData();
      });
    }
  }

  @override
  void dispose() {
    // Vô hiệu hóa kết quả của các request chưa hoàn thành.
    _requestVersion++;
    super.dispose();
  }

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sơ đồ bãi đỗ xe'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<void>(
        future: initialFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildError(snapshot.error);
          }

          if (parkingLots.isEmpty) {
            return const Center(
              child: Text('Campus chưa có bãi đỗ xe hoạt động'),
            );
          }

          return Column(
            children: [
              // Dropdown chọn bãi xe.
              _buildLotDropdown(),

              Expanded(
                child: FutureBuilder<void>(
                  future: lotFuture,
                  builder: (context, lotSnapshot) {
                    if (lotSnapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (lotSnapshot.hasError) {
                      return _buildError(lotSnapshot.error);
                    }

                    if (mapVersion == null) {
                      return const Center(
                        child: Text('Bãi xe chưa có bản đồ được xuất bản'),
                      );
                    }

                    if (floors.isEmpty) {
                      return const Center(
                        child: Text('Bãi xe chưa có tầng nào'),
                      );
                    }

                    return Column(
                      children: [
                        _buildFloorSelector(),

                        // Chú thích màu sắc.
                        _buildStatusLegend(),

                        Expanded(child: _buildMap()),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // =====================================================
  // DROPDOWN PARKING LOT
  // =====================================================

  Widget _buildLotDropdown() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: DropdownButtonFormField<String>(
        key: ValueKey(selectedLotId),
        initialValue: selectedLotId,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Chọn bãi xe',
          prefixIcon: Icon(Icons.local_parking),
          border: OutlineInputBorder(),
        ),
        items: parkingLots.map((lot) {
          return DropdownMenuItem<String>(
            value: lot.id,
            child: Text(lot.name, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: _selectLot,
      ),
    );
  }

  // =====================================================
  // FLOOR SELECTOR
  // =====================================================

  Widget _buildFloorSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: floors.map((floor) {
          final floorId = floor['id'] as String;
          final isSelected = selectedFloorId == floorId;

          return ChoiceChip(
            label: Text(floor['name'] as String),
            selected: isSelected,
            onSelected: (_) => _selectFloor(floorId),
          );
        }).toList(),
      ),
    );
  }

  // =====================================================
  // STATUS LEGEND
  // =====================================================

  Widget _buildStatusLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          _legendItem(const Color(0xFF16A34A), 'Trống'),
          _legendItem(const Color(0xFFDC2626), 'Có xe'),
          _legendItem(const Color(0xFFFACC15), 'Bảo trì'),
          _legendItem(Colors.grey, 'Không khả dụng'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // =====================================================
  // MAP + REALTIME PARKING SLOTS
  // =====================================================

  Widget _buildMap() {
    final future = elementsFuture;

    if (future == null) {
      return const Center(child: Text('Chưa chọn tầng'));
    }

    return FutureBuilder<List<MapElement>>(
      future: future,
      builder: (context, mapSnapshot) {
        if (mapSnapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (mapSnapshot.hasError) {
          return _buildError(mapSnapshot.error);
        }

        final elements = mapSnapshot.data ?? [];

        if (elements.isEmpty) {
          return const Center(child: Text('Tầng này chưa có dữ liệu bản đồ'));
        }

        // Danh sách slot_id thuộc tầng hiện tại.
        final slotIds = elements
            .where(
              (element) => element.type == 'slot' && element.slotId != null,
            )
            .map((element) => element.slotId!)
            .toSet();

        // Tính kích thước canvas.
        final maxColumn = elements
            .map((e) => e.x + e.width)
            .reduce((a, b) => a > b ? a : b);

        final maxRow = elements
            .map((e) => e.y + e.height)
            .reduce((a, b) => a > b ? a : b);

        final width = maxColumn * cellSize;
        final height = maxRow * cellSize;

        // Lắng nghe trạng thái parking_slots.
        return StreamBuilder<List<ParkingSlot>>(
          stream: slotsStream,
          builder: (context, slotSnapshot) {
            if (slotSnapshot.hasError) {
              return _buildError(slotSnapshot.error);
            }

            if (!slotSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // Liên kết slot_id với trạng thái thực tế.
            final slotsById = <String, ParkingSlot>{};

            for (final slot in slotSnapshot.data!) {
              if (slotIds.contains(slot.id)) {
                slotsById[slot.id] = slot;
              }
            }

            // DEBUG: kiểm tra liên kết giữa map_elements và parking_slots.
            debugPrint('========== PARKING DEBUG ==========');
            debugPrint('Selected lot: $selectedLotId');
            debugPrint('Selected floor: $selectedFloorId');
            debugPrint('Map version: ${mapVersion?.id}');
            debugPrint('Map elements: ${elements.length}');
            debugPrint('Slot IDs on map: ${slotIds.length}');
            debugPrint('Realtime slots: ${slotSnapshot.data!.length}');
            debugPrint('Matched slots: ${slotsById.length}');

            for (final code in ['A01', 'A04', 'A08', 'B02']) {
              final matches = elements.where(
                (element) => element.type == 'slot' && element.label == code,
              );
              for (final element in matches) {
                final slot = slotsById[element.slotId];
                debugPrint(
                  '$code | slotId=${element.slotId} '
                  '| status=${slot?.status} '
                  '| active=${slot?.isActive}',
                );
              }
            }
            debugPrint('===================================');

            return InteractiveViewer(
              key: ValueKey('$selectedLotId-$selectedFloorId'),
              minScale: 0.2,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(100),
              constrained: false,
              child: SizedBox(
                width: width,
                height: height,
                child: CustomPaint(
                  painter: ParkingMapPainter(
                    elements: elements,
                    slotsById: slotsById,
                    cellSize: cellSize,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =====================================================
  // ERROR UI
  // =====================================================

  Widget _buildError(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Không thể tải dữ liệu bản đồ'),
            const SizedBox(height: 8),
            Text('$error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: _refresh, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
