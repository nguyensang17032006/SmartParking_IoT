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

import '../widgets/interactive_parking_map.dart';
import '../../../indoor_navigation/domain/services/a_star_pathfinder.dart';
import '../../../indoor_navigation/data/indoor_route_loader.dart';

class CampusMapPage extends StatefulWidget {
  final String campusId;
  final String? campusName;

  const CampusMapPage({super.key, required this.campusId, this.campusName});

  @override
  State<CampusMapPage> createState() => _CampusMapPageState();
}

class _CampusMapPageState extends State<CampusMapPage> {
  static const double cellSize = 20;
  String? _selectedSlotId;
  List<GridNode> _route = [];
  String? _routeSlotId;
  bool _routing = false;
  int _routeRequest = 0;
  void _clearRoute() {
    _routeRequest++;
    _route = [];
    _routeSlotId = null;
    _routing = false;
  }

  bool _canGuide(ParkingSlot? slot) =>
      slot != null &&
      slot.isActive &&
      slot.status == 'available' &&
      _matches(slot);
  Future<void> _guide(ParkingSlot slot) async {
    final version = mapVersion?.id;
    if (version == null || _routing || !_canGuide(slot)) return;
    final ids = floors.map((f) => f['id'] as String).toList();
    _clearRoute();
    final request = _routeRequest;
    setState(() {
      _routing = true;
    });
    try {
      final path = await IndoorRouteLoader(Supabase.instance.client).find(
        floorIds: ids,
        loadFloor: (id) => getMapElements(version, id),
        slotId: slot.id,
      );
      if (!mounted || request != _routeRequest) return;
      if (path.isEmpty) {
        _info(
          'Chỉ đường',
          'Không tìm thấy đường hợp lệ đến cạnh tiếp cận của ô.',
        );
        return;
      }
      setState(() {
        _route = path;
        _routeSlotId = slot.id;

        final startFloorId = path.first.floor;

        // Chỉ tải bản đồ nếu thực sự chuyển tầng.
        if (selectedFloorId != startFloorId) {
          selectedFloorId = startFloorId;

          elementsFuture = getMapElements(version, startFloorId);
        }
      });
    } catch (e) {
      if (mounted && request == _routeRequest)
        _info('Không thể chỉ đường', '$e');
    } finally {
      if (mounted && request == _routeRequest)
        setState(() {
          _routing = false;
        });
    }
  }

  List<List<Offset>> _segments() {
    final result = <List<Offset>>[];
    List<Offset>? current;
    for (final n in _route) {
      if (n.floor != selectedFloorId) {
        current = null;
        continue;
      }
      if (current == null) {
        current = <Offset>[];
        result.add(current);
      }
      current.add(Offset(n.x + .5, n.y + .5));
    }
    return result;
  }

  String _vehicle = 'car';
  static const navy = Color(0xFF111A31);
  static const red = Color(0xFFF0194B);
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

  void _onSlotSelected(String? slotId) {
    setState(() {
      _clearRoute();
      _selectedSlotId = _selectedSlotId == slotId ? null : slotId;
    });
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
    _clearRoute();
    _selectedSlotId = null;
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
      if (_route.isEmpty) {
        _clearRoute();
        _selectedSlotId = null;
      }

      selectedFloorId = floorId;

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
      backgroundColor: const Color(0xFFE9EEF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE9EEF9),
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              'Sơ đồ bãi xe',
              style: TextStyle(fontWeight: FontWeight.w800, color: navy),
            ),
            Text(
              widget.campusName ?? 'Smart Parking',
              style: const TextStyle(fontSize: 12, color: navy),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _info(
              'Thông tin bãi xe',
              'Chọn bãi xe và tầng để xem trạng thái trực tiếp.',
            ),
            icon: const Icon(Icons.info_outline),
          ),
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

                    return Column(children: [Expanded(child: _buildMap())]);
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

  Widget _surface(
    Widget child, {
    EdgeInsets padding = const EdgeInsets.all(10),
  }) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: const Color(0xFFF7F9FF),
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x182D416D),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );

  void _info(String title, String message) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLotDropdown() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0F5FF), Color(0xFFCCD9F4)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_parking_rounded,
            size: 40,
            color: Color(0xFF326CF2),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    isDense: true,
                    value: selectedLotId,
                    items: parkingLots
                        .map(
                          (lot) => DropdownMenuItem(
                            value: lot.id,
                            child: Text(
                              lot.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: navy,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _selectLot,
                  ),
                ),
                Text(
                  floors.isEmpty ? 'Bãi đỗ xe' : '${floors.length} tầng',
                  style: const TextStyle(color: navy, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            '● Hoạt động',
            style: TextStyle(
              color: Color(0xFF087B36),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildFloorSelector() => _surface(
    Row(
      children: floors.map((floor) {
        final id = floor['id'] as String;
        final selected = id == selectedFloorId;
        return Expanded(
          child: InkWell(
            onTap: () => _selectFloor(id),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: selected
                    ? const LinearGradient(
                        colors: [Color(0xFFF43F46), Color(0xFFB91C32)],
                      )
                    : null,
              ),
              child: Text(
                floor['name'] as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? Colors.white : navy,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    ),
    padding: const EdgeInsets.all(4),
  );

  bool _matches(ParkingSlot slot) {
    final type = slot.vehicleType.toLowerCase().trim();
    return _vehicle == 'car'
        ? type == 'car'
        : [
            'motorbike',
            'motorcycle',
            'bike',
            'motor_cycle',
            'motor_bike',
          ].contains(type);
  }

  String _status(ParkingSlot slot) {
    if (!slot.isActive) return 'Không khả dụng';
    return switch (slot.status) {
      'available' => 'Còn trống',
      'occupied' => 'Đã có xe',
      'reserved' => 'Đã đặt',
      'maintenance' => 'Bảo trì',
      _ => 'Không khả dụng',
    };
  }

  Widget _stats(List<ParkingSlot> slots) {
    Widget item(String label, int count, IconData icon, Color color) =>
        Expanded(
          child: _surface(
            Row(
              children: [
                Icon(icon, color: color, size: 19),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          style: const TextStyle(fontSize: 11, color: navy),
                        ),
                      ),
                      Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: navy,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            padding: const EdgeInsets.all(7),
          ),
        );
    int count(String status) =>
        slots.where((s) => s.isActive && s.status == status).length;
    return Row(
      children: [
        item('Tổng chỗ', slots.length, Icons.local_parking, Colors.blue),
        const SizedBox(width: 5),
        item(
          'Còn trống',
          count('available'),
          Icons.directions_car,
          Colors.green,
        ),
        const SizedBox(width: 5),
        item('Đã có xe', count('occupied'), Icons.directions_car, red),
        const SizedBox(width: 5),
        item('Đã đặt', count('reserved'), Icons.event_available, red),
      ],
    );
  }

  Widget _vehicleButton(String value, String label, IconData icon) => Expanded(
    child: InkWell(
      onTap: () => setState(() {
        _clearRoute();
        _vehicle = value;
        _selectedSlotId = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: _vehicle == value ? red : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: _vehicle == value ? Colors.white : navy,
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: _vehicle == value ? Colors.white : navy,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _details(ParkingSlot? slot) => _surface(
    Row(
      children: [
        const Icon(Icons.local_parking_rounded, color: Colors.blue, size: 28),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slot?.code ?? 'Chọn ô đỗ',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: navy,
                ),
              ),
              Text(
                slot == null ? 'Nhấn trên sơ đồ' : _status(slot),
                style: TextStyle(
                  fontSize: 11,
                  color: slot?.status == 'available' && slot!.isActive
                      ? Colors.green
                      : navy,
                ),
              ),
              Text(
                floors
                    .where((f) => f['id'] == selectedFloorId)
                    .map((f) => f['name'])
                    .join(),
                style: const TextStyle(fontSize: 11, color: navy),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Loại chỗ',
                style: TextStyle(fontSize: 11, color: navy),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _vehicleButton('car', 'Ô tô', Icons.directions_car),
                  _vehicleButton('motorbike', 'Xe máy', Icons.two_wheeler),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _quickActions(List<ParkingSlot> slots) {
    Widget action(String title, IconData icon, VoidCallback callback) =>
        Expanded(
          child: InkWell(
            onTap: callback,
            child: _surface(
              Column(
                children: [
                  Icon(icon, color: navy, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: navy),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
            ),
          ),
        );
    void list(String title, String status) {
      final items = slots
          .where((s) => s.isActive && s.status == status)
          .toList();
      showModalBottomSheet<void>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('Không có vị trí'))
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, i) => ListTile(
                          title: Text(items[i].code),
                          subtitle: Text(_status(items[i])),
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              _clearRoute();
                              _selectedSlotId = items[i].id;
                            });
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        action(
          'Thông tin\nbãi xe',
          Icons.info_outline,
          () => _info(
            'Thông tin bãi xe',
            '${parkingLots.firstWhere((l) => l.id == selectedLotId).name} • ${floors.length} tầng',
          ),
        ),
        const SizedBox(width: 6),
        action(
          'Danh sách\nchỗ trống',
          Icons.location_on_outlined,
          () => list('Chỗ trống', 'available'),
        ),
        const SizedBox(width: 6),
        action(
          'Chỗ đã\nđặt',
          Icons.bookmark_border,
          () => list('Ô có trạng thái đã đặt (loại xe đang chọn)', 'reserved'),
        ),
        const SizedBox(width: 6),
        action(
          'Quy định\nbãi xe',
          Icons.settings_outlined,
          () =>
              _info('Quy định bãi xe', 'Chưa có dữ liệu quy định chính thức.'),
        ),
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

        // Danh sách slot thuộc tầng đang chọn.
        final slotIds = elements
            .where(
              (element) => element.type == 'slot' && element.slotId != null,
            )
            .map((element) => element.slotId!)
            .toSet();

        return StreamBuilder<List<ParkingSlot>>(
          stream: slotsStream,
          builder: (context, slotSnapshot) {
            if (slotSnapshot.hasError) {
              return _buildError(slotSnapshot.error);
            }

            if (!slotSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final slotsById = <String, ParkingSlot>{};

            for (final slot in slotSnapshot.data!) {
              if (slotIds.contains(slot.id)) {
                slotsById[slot.id] = slot;
              }
            }

            final filtered = slotsById.values.where(_matches).toList();
            final selected = slotsById[_selectedSlotId];
            final routeTarget = slotSnapshot.data!
                .where((s) => s.id == _routeSlotId)
                .firstOrNull;
            final routeValid = _route.isNotEmpty && _canGuide(routeTarget);
            if (_route.isNotEmpty && !routeValid) {
              final request = _routeRequest;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && request == _routeRequest) setState(_clearRoute);
              });
            }
            final visibleSlots = {for (final slot in filtered) slot.id: slot};
            return LayoutBuilder(
              builder: (context, constraints) {
                final mapHeight = (constraints.maxHeight - 300)
                    .clamp(240.0, 700.0)
                    .toDouble();
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    children: [
                      _stats(filtered),
                      const SizedBox(height: 8),
                      _buildFloorSelector(),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: mapHeight,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: InteractiveParkingMap(
                            key: ValueKey(
                              '$selectedLotId-$selectedFloorId-${mapVersion?.id}',
                            ),
                            elements: elements,
                            slotsById: visibleSlots,
                            cellSize: cellSize,
                            routeSegments: routeValid ? _segments() : const [],
                            selectedSlotId:
                                visibleSlots.containsKey(_selectedSlotId)
                                ? _selectedSlotId
                                : null,
                            onSlotSelected: (id) => _onSlotSelected(
                              visibleSlots.containsKey(id) ? id : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      const SizedBox(height: 8),
                      _details(selected),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.event_available),
                              label: const Text(
                                'Đặt chỗ trước',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: red,
                              ),
                              onPressed: routeValid
                                  ? () => setState(_clearRoute)
                                  : !_routing && _canGuide(selected)
                                  ? () => _guide(selected!)
                                  : null,
                              icon: const Icon(Icons.navigation),
                              label: Text(
                                _routing
                                    ? 'Đang tìm...'
                                    : routeValid
                                    ? 'Dừng chỉ đường'
                                    : 'Chỉ đường',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      _quickActions(filtered),
                    ],
                  ),
                );
              },
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
