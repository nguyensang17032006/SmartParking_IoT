import 'package:flutter/material.dart';

/// Home content displayed inside the Scaffold owned by MainLayout.
/// Uses local sample data; does not initialize app navigation or services.
class ParkingHome extends StatefulWidget {
  const ParkingHome({super.key});

  @override
  State<ParkingHome> createState() => _ParkingHomeState();
}

class _HomeColors {
  static const background = Color(0xFFF5F7FA);
  static const ink = Color(0xFF162238);
  static const muted = Color(0xFF738095);
  static const red = Color(0xFFE21E49);
  static const line = Color(0xFFE6EBF1);
  static const green = Color(0xFF16845B);
  static const amber = Color(0xFFB47B13);
  static const blue = Color(0xFF4C6589);
}

enum _SpotState { free, occupied, reserved, unknown }

extension _SpotAppearance on _SpotState {
  String get label => switch (this) {
    _SpotState.free => 'Trống',
    _SpotState.occupied => 'Có xe',
    _SpotState.reserved => 'Đã đặt',
    _SpotState.unknown => 'Mất kết nối',
  };

  Color get color => switch (this) {
    _SpotState.free => _HomeColors.green,
    _SpotState.occupied => _HomeColors.blue,
    _SpotState.reserved => _HomeColors.amber,
    _SpotState.unknown => _HomeColors.muted,
  };

  Color get surface => switch (this) {
    _SpotState.free => const Color(0xFFEBF7F0),
    _SpotState.occupied => const Color(0xFFEEF2F7),
    _SpotState.reserved => const Color(0xFFFFF6E5),
    _SpotState.unknown => const Color(0xFFF0F2F5),
  };

  IconData get icon => switch (this) {
    _SpotState.free => Icons.local_parking_rounded,
    _SpotState.occupied => Icons.directions_car_rounded,
    _SpotState.reserved => Icons.schedule_rounded,
    _SpotState.unknown => Icons.wifi_off_rounded,
  };
}

class _DemoSpot {
  final String code;
  final _SpotState state;
  final String? parkedFor;
  const _DemoSpot(this.code, this.state, {this.parkedFor});

  _DemoSpot withState(_SpotState value) => _DemoSpot(code, value);
}

class _ParkingHomeState extends State<ParkingHome> {
  final _search = TextEditingController();
  final _mapKey = GlobalKey();
  List<_DemoSpot> _spots = const [
    _DemoSpot('A01', _SpotState.free),
    _DemoSpot('A02', _SpotState.occupied, parkedFor: '45 phút'),
    _DemoSpot('A03', _SpotState.free),
    _DemoSpot('B01', _SpotState.occupied, parkedFor: '1 giờ 15 phút'),
    _DemoSpot('B02', _SpotState.reserved),
    _DemoSpot('B03', _SpotState.free),
  ];
  _SpotState? _filter;
  String _query = '';
  String? _selectedCode;
  String? _reservedCode = 'B02';
  String? _savedCode;
  DateTime _arrival = DateTime.now().add(const Duration(minutes: 15));

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  int _count(_SpotState state) => _spots.where((s) => s.state == state).length;

  String _clock(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
      );
  }

  void _setSpot(String code, _SpotState state) {
    _spots = _spots
        .map((s) => s.code == code ? s.withState(state) : s)
        .toList();
  }

  void _showRoute(String code) {
    setState(() => _selectedCode = code);
    final mapContext = _mapKey.currentContext;
    if (mapContext != null) {
      Scrollable.ensureVisible(
        mapContext,
        duration: const Duration(milliseconds: 350),
        alignment: 0.12,
      );
    }
  }

  Future<void> _reserve(_DemoSpot spot) async {
    var duration = 15;
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => _SheetContent(
          children: [
            _SheetHeading(
              icon: Icons.local_parking_rounded,
              title: 'Đặt ô ${spot.code}',
              subtitle: 'Chọn thời gian dự kiến đến bãi xe.',
            ),
            const SizedBox(height: 20),
            const Text(
              'Giữ chỗ trong',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final minutes in [5, 15, 30, 60])
                  ChoiceChip(
                    label: Text('$minutes phút'),
                    selected: duration == minutes,
                    onSelected: (_) => update(() => duration = minutes),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoLine(
              icon: Icons.schedule_rounded,
              text:
                  'Đến trước ${_clock(DateTime.now().add(Duration(minutes: duration)))}',
            ),
            if (_reservedCode != null) ...[
              const SizedBox(height: 12),
              Text(
                'Bạn đang giữ $_reservedCode. Xác nhận để chuyển chỗ sang ${spot.code}.',
                style: const TextStyle(color: _HomeColors.muted),
              ),
            ],
            const SizedBox(height: 22),
            _HomeButton(
              label: _reservedCode == null
                  ? 'Xác nhận đặt chỗ'
                  : 'Chuyển sang ${spot.code}',
              icon: Icons.check_rounded,
              onPressed: () => Navigator.pop(context, duration),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (_reservedCode != null) _setSpot(_reservedCode!, _SpotState.free);
      _setSpot(spot.code, _SpotState.reserved);
      _reservedCode = spot.code;
      _selectedCode = spot.code;
      _arrival = DateTime.now().add(Duration(minutes: result));
    });
    _message('Đã giữ ô ${spot.code} đến ${_clock(_arrival)}.');
  }

  Future<void> _cancelReservation() async {
    final code = _reservedCode;
    if (code == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy chỗ đặt?'),
        content: Text('Ô $code sẽ được trả lại để người khác sử dụng.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Giữ chỗ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Hủy đặt chỗ',
              style: TextStyle(color: _HomeColors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _setSpot(code, _SpotState.free);
      _reservedCode = null;
      if (_selectedCode == code) _selectedCode = null;
    });
    _message('Đã hủy chỗ đặt $code.');
  }

  void _showSpot(_DemoSpot spot) {
    setState(() => _selectedCode = spot.code);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => _SheetContent(
        children: [
          _SheetHeading(
            icon: spot.state.icon,
            title: 'Ô đỗ ${spot.code}',
            subtitle: 'Dãy ${spot.code.substring(0, 1)} · Bãi ô tô trung tâm',
          ),
          const SizedBox(height: 18),
          _StatusTag(state: spot.state),
          const SizedBox(height: 14),
          Text(switch (spot.state) {
            _SpotState.free =>
              'Ô đang trống. Bạn có thể đặt chỗ trước khi đến bãi.',
            _SpotState.occupied =>
              'Ô đang có xe${spot.parkedFor == null ? '.' : ' · Đã đỗ ${spot.parkedFor}.'}',
            _SpotState.reserved => 'Bạn đã giữ ô này đến ${_clock(_arrival)}.',
            _SpotState.unknown => 'Chưa xác định được trạng thái của ô đỗ.',
          }, style: const TextStyle(color: _HomeColors.muted, height: 1.5)),
          const SizedBox(height: 22),
          if (spot.state == _SpotState.free)
            _HomeButton(
              label: 'Đặt chỗ này',
              icon: Icons.bookmark_add_outlined,
              onPressed: () {
                Navigator.pop(sheetContext);
                _reserve(spot);
              },
            ),
          if (spot.state == _SpotState.reserved)
            _HomeButton(
              label: 'Xem đường đến ô đỗ',
              icon: Icons.route_rounded,
              onPressed: () {
                Navigator.pop(sheetContext);
                _showRoute(spot.code);
              },
            ),
          if (spot.state == _SpotState.occupied)
            _HomeButton(
              label: 'Lưu vị trí xe của tôi',
              icon: Icons.location_on_outlined,
              onPressed: () {
                Navigator.pop(sheetContext);
                setState(() => _savedCode = spot.code);
                _message('Đã lưu vị trí xe tại ${spot.code}.');
              },
            ),
          if (spot.state != _SpotState.reserved) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                _showRoute(spot.code);
              },
              icon: const Icon(Icons.route_rounded),
              label: const Text('Xem vị trí trên sơ đồ'),
            ),
          ],
          if (spot.state == _SpotState.reserved)
            TextButton(
              onPressed: () {
                Navigator.pop(sheetContext);
                _cancelReservation();
              },
              child: const Text(
                'Hủy đặt chỗ',
                style: TextStyle(color: _HomeColors.red),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _spots
        .where(
          (s) =>
              (_filter == null || s.state == _filter) &&
              s.code.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    return ColoredBox(
      color: _HomeColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  constraints.maxWidth > 700 ? 28 : 20,
                  20,
                  constraints.maxWidth > 700 ? 28 : 20,
                  28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _welcome(),
                    const SizedBox(height: 20),
                    if (_reservedCode != null) ...[
                      _reservationCard(),
                      const SizedBox(height: 20),
                    ],
                    _overview(),
                    const SizedBox(height: 24),
                    if (constraints.maxWidth >= 900)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 6, child: _mapSection()),
                          const SizedBox(width: 24),
                          Expanded(flex: 5, child: _slotSection(visible)),
                        ],
                      )
                    else ...[
                      _mapSection(),
                      const SizedBox(height: 24),
                      _slotSection(visible),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _welcome() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Xin chào, Sáng',
        style: TextStyle(color: _HomeColors.muted, fontSize: 13),
      ),
      const SizedBox(height: 7),
      const Text(
        'Hôm nay bạn đỗ ở đâu?',
        style: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w800,
          color: _HomeColors.ink,
          letterSpacing: -.5,
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 17,
                color: _HomeColors.red,
              ),
              SizedBox(width: 4),
              Text(
                'Bãi ô tô trung tâm',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _HomeColors.ink,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE9EDF3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Dữ liệu mẫu',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _HomeColors.muted,
              ),
            ),
          ),
        ],
      ),
    ],
  );

  Widget _reservationCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _HomeColors.ink,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.bookmark_rounded,
              size: 15,
              color: Color(0xFFF1CC82),
            ),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'CHỖ BẠN ĐÃ ĐẶT',
                style: TextStyle(
                  color: Color(0xFFF1CC82),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            InkWell(
              onTap: _cancelReservation,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: Text(
                  'Hủy',
                  style: TextStyle(color: Color(0xFFAEB8CA), fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _reservedCode!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            Container(
              width: 1,
              height: 36,
              margin: const EdgeInsets.symmetric(horizontal: 18),
              color: Colors.white24,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thời gian dự kiến đến',
                    style: TextStyle(color: Color(0xFFAEB8CA), fontSize: 11),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Trước ${_clock(_arrival)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.directions_car_rounded,
              color: Color(0xFF8190AB),
              size: 38,
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: FilledButton.icon(
            onPressed: () => _showRoute(_reservedCode!),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _HomeColors.ink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.near_me_outlined, size: 18),
            label: const Text(
              'Xem đường đến ô đỗ',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _overview() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Tổng quan bãi xe',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _HomeColors.ink,
              ),
            ),
          ),
          Text(
            '${_spots.length} ô đỗ',
            style: const TextStyle(fontSize: 12, color: _HomeColors.muted),
          ),
        ],
      ),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, constraints) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final state in _SpotState.values)
              SizedBox(
                width: (constraints.maxWidth - 24) / 4,
                child: _Surface(
                  padding: const EdgeInsets.symmetric(
                    vertical: 13,
                    horizontal: 6,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: state.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${_count(state)}',
                            style: const TextStyle(
                              fontSize: 23,
                              color: _HomeColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          color: _HomeColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  );

  Widget _mapSection() => _Surface(
    key: _mapKey,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Sơ đồ bãi xe',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: _HomeColors.ink,
                ),
              ),
            ),
            if (_selectedCode != null)
              IconButton(
                onPressed: () => setState(() => _selectedCode = null),
                tooltip: 'Ẩn tuyến đường',
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
          ],
        ),
        const SizedBox(height: 5),
        const Text(
          'Chạm vào một ô để xem chi tiết',
          style: TextStyle(fontSize: 11, color: _HomeColors.muted),
        ),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 1.25,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ParkingLanePainter(_selectedCode),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      top: height * .5 - 24,
                      child: const Column(
                        children: [
                          Icon(
                            Icons.login_rounded,
                            size: 16,
                            color: _HomeColors.muted,
                          ),
                          SizedBox(height: 3),
                          Text(
                            'CỔNG',
                            style: TextStyle(
                              fontSize: 8,
                              color: _HomeColors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (var i = 0; i < _spots.length; i++)
                      Positioned(
                        left: width * (.23 + (i % 3) * .30) - width * .105,
                        top: height * (i < 3 ? .08 : .62),
                        width: width * .21,
                        height: height * .30,
                        child: _MapSpot(
                          spot: _spots[i],
                          selected: _selectedCode == _spots[i].code,
                          isMine: _reservedCode == _spots[i].code,
                          onTap: () => _showSpot(_spots[i]),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        if (_selectedCode != null) ...[
          Row(
            children: [
              const Icon(Icons.route_rounded, size: 16, color: _HomeColors.red),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Cổng vào → $_selectedCode',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _HomeColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 14,
          runSpacing: 8,
          children: [
            for (final state in [
              _SpotState.free,
              _SpotState.occupied,
              _SpotState.reserved,
            ])
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: state.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    state.label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: _HomeColors.muted,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    ),
  );

  Widget _slotSection(List<_DemoSpot> visible) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Chọn chỗ đỗ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _HomeColors.ink,
              ),
            ),
          ),
          Text(
            '${visible.length} ô',
            style: const TextStyle(fontSize: 12, color: _HomeColors.muted),
          ),
        ],
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _search,
        onChanged: (value) => setState(() => _query = value.trim()),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Tìm ô đỗ, ví dụ A01',
          hintStyle: const TextStyle(color: _HomeColors.muted),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: _HomeColors.muted,
          ),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Xóa tìm kiếm',
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _search.clear();
                    setState(() => _query = '');
                  },
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _HomeColors.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _HomeColors.line),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          _FilterPill(
            label: 'Tất cả',
            selected: _filter == null,
            onTap: () => setState(() => _filter = null),
          ),
          for (final state in [
            _SpotState.free,
            _SpotState.reserved,
            _SpotState.occupied,
          ])
            _FilterPill(
              label: state.label,
              selected: _filter == state,
              onTap: () => setState(() => _filter = state),
            ),
        ],
      ),
      const SizedBox(height: 16),
      if (visible.isEmpty)
        _Surface(
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: Text(
                'Không tìm thấy ô đỗ phù hợp.',
                style: TextStyle(color: _HomeColors.muted),
              ),
            ),
          ),
        )
      else
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 12,
            runSpacing: 12,
            children: visible
                .map(
                  (spot) => SizedBox(
                    width: (constraints.maxWidth - 12) / 2,
                    child: _SpotCard(
                      spot: spot,
                      isMine: _reservedCode == spot.code,
                      saved: _savedCode == spot.code,
                      onTap: () => _showSpot(spot),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      const SizedBox(height: 16),
      const _InfoLine(
        icon: Icons.info_outline_rounded,
        text: 'Ưu tiên các ô trống gần cổng để vào bãi thuận tiện hơn.',
      ),
    ],
  );
}

class _Surface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _HomeColors.line),
    ),
    child: child,
  );
}

class _IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconTile({required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: color.withAlpha(20),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: color, size: 21),
  );
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: selected ? _HomeColors.ink : Colors.white,
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _HomeColors.muted,
          ),
        ),
      ),
    ),
  );
}

class _StatusTag extends StatelessWidget {
  final _SpotState state;
  const _StatusTag({required this.state});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: state.surface,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      state.label.toUpperCase(),
      style: TextStyle(
        color: state.color,
        fontWeight: FontWeight.w800,
        fontSize: 9,
        letterSpacing: .3,
      ),
    ),
  );
}

class _SpotCard extends StatelessWidget {
  final _DemoSpot spot;
  final bool isMine;
  final bool saved;
  final VoidCallback onTap;
  const _SpotCard({
    required this.spot,
    required this.isMine,
    required this.saved,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: isMine ? const Color(0xFFE7C47D) : _HomeColors.line,
      ),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    spot.code,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _HomeColors.ink,
                    ),
                  ),
                ),
                Icon(spot.state.icon, color: spot.state.color, size: 22),
              ],
            ),
            const SizedBox(height: 10),
            _StatusTag(state: spot.state),
            const SizedBox(height: 12),
            Text(
              isMine
                  ? 'Chỗ bạn đã đặt'
                  : saved
                  ? 'Vị trí xe của bạn'
                  : switch (spot.state) {
                      _SpotState.free => 'Sẵn sàng đón xe',
                      _SpotState.occupied =>
                        'Đã đỗ ${spot.parkedFor ?? 'tại đây'}',
                      _SpotState.reserved => 'Đang được giữ chỗ',
                      _SpotState.unknown => 'Chưa có tín hiệu',
                    },
              style: const TextStyle(
                color: _HomeColors.muted,
                fontSize: 10,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    spot.state == _SpotState.free
                        ? 'Chạm để đặt'
                        : 'Xem chi tiết',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: spot.state == _SpotState.free
                          ? _HomeColors.green
                          : _HomeColors.ink,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 15,
                  color: spot.state == _SpotState.free
                      ? _HomeColors.green
                      : _HomeColors.muted,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _MapSpot extends StatelessWidget {
  final _DemoSpot spot;
  final bool selected;
  final bool isMine;
  final VoidCallback onTap;
  const _MapSpot({
    required this.spot,
    required this.selected,
    required this.isMine,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    label: '${spot.code}, ${spot.state.label}${isMine ? ', bạn đã đặt' : ''}',
    button: true,
    child: Material(
      color: spot.state.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected ? _HomeColors.red : spot.state.color.withAlpha(80),
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (spot.state == _SpotState.occupied)
              SizedBox(
                width: 24,
                height: 35,
                child: CustomPaint(painter: _TopViewCarPainter()),
              )
            else
              Icon(spot.state.icon, color: spot.state.color, size: 23),
            const SizedBox(height: 5),
            Text(
              spot.code,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                color: _HomeColors.ink,
              ),
            ),
            if (isMine)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  'CỦA BẠN',
                  style: TextStyle(
                    fontSize: 7,
                    color: _HomeColors.amber,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _ParkingLanePainter extends CustomPainter {
  final String? selected;
  _ParkingLanePainter(this.selected);
  @override
  void paint(Canvas canvas, Size size) {
    final lane = Paint()
      ..color = const Color(0xFFE9EEF5)
      ..strokeWidth = size.height * .17;
    canvas.drawLine(
      Offset(0, size.height * .5),
      Offset(size.width, size.height * .5),
      lane,
    );
    final dash = Paint()
      ..color = const Color(0xFFBCC7D6)
      ..strokeWidth = 1.4;
    for (double x = size.width * .18; x < size.width * .96; x += 16) {
      canvas.drawLine(
        Offset(x, size.height * .5),
        Offset(x + 7, size.height * .5),
        dash,
      );
    }
    if (selected == null) return;
    final index = int.tryParse(selected!.substring(1));
    if (index == null || index < 1 || index > 3) return;
    final x = size.width * (.23 + (index - 1) * .30);
    final y = size.height * (selected!.startsWith('A') ? .38 : .62);
    final path = Path()
      ..moveTo(size.width * .13, size.height * .5)
      ..lineTo(x, size.height * .5)
      ..lineTo(x, y);
    canvas.drawPath(
      path,
      Paint()
        ..color = _HomeColors.red
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(
      Offset(size.width * .13, size.height * .5),
      4,
      Paint()..color = _HomeColors.red,
    );
    canvas.drawCircle(Offset(x, y), 4, Paint()..color = _HomeColors.red);
  }

  @override
  bool shouldRepaint(covariant _ParkingLanePainter oldDelegate) =>
      oldDelegate.selected != selected;
}

class _TopViewCarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * .14, 0, size.width * .72, size.height),
      const Radius.circular(6),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFF637C9F));
    final glass = Paint()..color = const Color(0xFFC5D4E7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .24,
          size.height * .18,
          size.width * .52,
          size.height * .20,
        ),
        const Radius.circular(2),
      ),
      glass,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .24,
          size.height * .65,
          size.width * .52,
          size.height * .13,
        ),
        const Radius.circular(2),
      ),
      glass,
    );
    final wheel = Paint()..color = const Color(0xFF364A65);
    for (final x in [0.0, .82]) {
      for (final y in [.18, .66]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * x,
              size.height * y,
              size.width * .18,
              size.height * .16,
            ),
            const Radius.circular(2),
          ),
          wheel,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TopViewCarPainter oldDelegate) => false;
}

class _HomeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  const _HomeButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 50,
    child: FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: _HomeColors.red,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 19),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    ),
  );
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoLine({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: _HomeColors.muted),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            color: _HomeColors.muted,
            height: 1.5,
          ),
        ),
      ),
    ],
  );
}

class _SheetHeading extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SheetHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  @override
  Widget build(BuildContext context) => Row(
    children: [
      _IconTile(icon: icon, color: _HomeColors.red),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 21,
                color: _HomeColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: _HomeColors.muted),
            ),
          ],
        ),
      ),
    ],
  );
}

class _SheetContent extends StatelessWidget {
  final List<Widget> children;
  const _SheetContent({required this.children});
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    ),
  );
}
