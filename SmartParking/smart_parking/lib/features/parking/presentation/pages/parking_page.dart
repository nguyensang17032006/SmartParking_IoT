import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/parking_slot.dart';
import '../../domain/entities/parking_details.dart';
import '../../domain/repository/parking_repository.dart';
import '../../domain/usecases/indoor_route.dart';
import '../parking_controller.dart';

String statusLabel(SlotStatus status) => switch (status) {
  SlotStatus.free => 'Trống',
  SlotStatus.occupied => 'Có xe',
  SlotStatus.reserved => 'Đã đặt',
  SlotStatus.unknown => 'Mất kết nối',
};
Color statusColor(SlotStatus status) => switch (status) {
  SlotStatus.free => const Color(0xFF16835B),
  SlotStatus.occupied => AppColors.secondary,
  SlotStatus.reserved => const Color(0xFFB77900),
  SlotStatus.unknown => const Color(0xFF667085),
};
String clock(DateTime time) {
  final local = time.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

class ParkingPage extends StatefulWidget {
  final ParkingRepository repository;
  final Future<void> Function() onSignOut;
  const ParkingPage({
    super.key,
    required this.repository,
    required this.onSignOut,
  });
  @override
  State<ParkingPage> createState() => _ParkingPageState();
}

class _ParkingPageState extends State<ParkingPage> {
  late final ParkingController controller;
  int tab = 0;
  bool onlyFree = false;
  String? targetCode;
  Future<ParkingReport>? report;

  @override
  void initState() {
    super.initState();
    controller = ParkingController(widget.repository);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> act(Future<void> Function() action, String success) async {
    try {
      await controller.run(action);
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(success)));
    } catch (e) {
      final message = e is PostgrestException
          ? e.message
          : 'Thao tác chưa thành công. Kiểm tra kết nối.';
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  ParkingSlot? findSlot(String? code) {
    for (final slot in controller.slots) {
      if (slot.code == code) return slot;
    }
    return null;
  }

  void showNotices() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.65,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Thông báo',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Thông báo xuất hiện khi ứng dụng đang mở.'),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: controller.notices.isEmpty
                      ? const Center(child: Text('Chưa có thông báo mới.'))
                      : ListView.builder(
                          itemCount: controller.notices.length,
                          itemBuilder: (context, i) => ListTile(
                            leading: const Icon(Icons.notifications_outlined),
                            title: Text(controller.notices[i].message),
                            subtitle: Text(clock(controller.notices[i].time)),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> reserve(ParkingSlot slot) async {
    var minutes = 15;
    final confirmed = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, change) => AlertDialog(
          title: Text('Giữ chỗ ${slot.code}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chọn thời gian để đến bãi. Chỗ sẽ tự hết hạn nếu bạn chưa xác nhận đã đỗ.',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: minutes,
                items: [5, 10, 15, 30, 60, 120]
                    .map(
                      (m) => DropdownMenuItem(value: m, child: Text('$m phút')),
                    )
                    .toList(),
                onChanged: (m) => change(() => minutes = m ?? 15),
                decoration: const InputDecoration(
                  labelText: 'Thời gian giữ chỗ',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Dự kiến đến trước ${clock(DateTime.now().add(Duration(minutes: minutes)))}',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, minutes),
              child: const Text('Đặt chỗ'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != null && mounted) {
      await act(
        () => widget.repository.reserve(slot.code, confirmed),
        'Đã đặt chỗ ${slot.code}.',
      );
    }
  }

  Future<void> savePosition(ParkingSlot slot) async {
    final note = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Lưu vị trí ${slot.code}'),
        content: TextField(
          controller: note,
          maxLength: 200,
          decoration: const InputDecoration(
            labelText: 'Ghi chú',
            hintText: 'Gần cầu thang, cạnh cột…',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, note.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    // Wait until the dialog's exit animation no longer owns the text field.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    note.dispose();
    if (result != null && mounted) {
      await act(
        () => widget.repository.savePosition(slot.code, result),
        'Đã lưu vị trí xe.',
      );
    }
  }

  void detail(ParkingSlot slot) {
    final status = slot.statusAt(controller.now);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ô đỗ ${slot.code}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                statusLabel(status),
                style: TextStyle(color: statusColor(status)),
              ),
              if (slot.lastSeenAt != null)
                Text('Tín hiệu gần nhất: ${clock(slot.lastSeenAt!)}'),
              if (slot.reservedUntil?.isAfter(controller.now) ?? false)
                Text('Giữ chỗ đến ${clock(slot.reservedUntil!)}'),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  setState(() {
                    targetCode = slot.code;
                    tab = 0;
                  });
                },
                icon: const Icon(Icons.route),
                label: const Text('Đường từ cổng đến ô đỗ'),
              ),
              if (status == SlotStatus.free)
                FilledButton(
                  onPressed: controller.busy
                      ? null
                      : () {
                          Navigator.pop(sheetContext);
                          reserve(slot);
                        },
                  child: const Text('Đặt chỗ'),
                ),
              if (status == SlotStatus.occupied)
                FilledButton(
                  onPressed: controller.busy
                      ? null
                      : () {
                          Navigator.pop(sheetContext);
                          act(
                            () => widget.repository.confirmParked(slot.code),
                            'Đã xác nhận đỗ và tự lưu vị trí xe.',
                          );
                        },
                  child: const Text('Tôi đã đỗ tại đây'),
                ),
              TextButton(
                onPressed: controller.busy
                    ? null
                    : () {
                        Navigator.pop(sheetContext);
                        savePosition(slot);
                      },
                child: const Text('Lưu vị trí đỗ xe thủ công'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text('Bãi xe đại học'),
        actions: [
          IconButton(
            onPressed: showNotices,
            tooltip: 'Thông báo',
            icon: Badge(
              isLabelVisible: controller.notices.isNotEmpty,
              label: Text('${controller.notices.length}'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () async {
              try {
                await widget.onSignOut();
              } catch (_) {
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chưa đăng xuất được. Vui lòng thử lại.'),
                    ),
                  );
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: tab,
          children: [parkingBody(), myParkingBody(), statisticsBody()],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) {
          setState(() {
            tab = value;
            if (value == 2 && report == null)
              report = widget.repository.getReport();
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_parking),
            label: 'Bãi xe',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car),
            label: 'Xe của tôi',
          ),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Thống kê'),
        ],
      ),
    ),
  );

  Widget parkingBody() {
    if (controller.loading)
      return const Center(child: CircularProgressIndicator());
    if (controller.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(controller.error!),
            ),
            FilledButton(
              onPressed: controller.watch,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    if (controller.slots.isEmpty)
      return const Center(child: Text('Bãi xe chưa có ô đỗ.'));
    final counts = <SlotStatus, int>{
      for (final status in SlotStatus.values)
        status: controller.slots
            .where((s) => s.statusAt(controller.now) == status)
            .length,
    };
    final available =
        controller.slots
            .where((s) => s.statusAt(controller.now) == SlotStatus.free)
            .toList()
          ..sort(
            (a, b) =>
                routeLength(routeFromEntrance(a))
                    .compareTo(routeLength(routeFromEntrance(b))),
          );
    final displayed = onlyFree ? available : controller.slots;
    final target = findSlot(targetCode);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in counts.entries)
              Chip(
                avatar: Icon(
                  Icons.circle,
                  size: 12,
                  color: statusColor(entry.key),
                ),
                label: Text('${statusLabel(entry.key)}: ${entry.value}'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Sơ đồ khu đỗ ô tô',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        UniversityMap(
          slots: controller.slots,
          now: controller.now,
          target: target,
          onTap: detail,
        ),
        if (target != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.route, color: AppColors.secondary),
              title: Text('Cổng → ${target.code}'),
              subtitle: const Text(
                'Đi theo tuyến trên sơ đồ. Điểm bắt đầu là cổng bãi xe.',
              ),
              trailing: IconButton(
                onPressed: () => setState(() => targetCode = null),
                icon: const Icon(Icons.close),
                tooltip: 'Ẩn tuyến đường',
              ),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                'Gợi ý ô trống',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            FilterChip(
              label: const Text('Chỉ ô trống'),
              selected: onlyFree,
              onSelected: (v) => setState(() => onlyFree = v),
            ),
          ],
        ),
        Text(
          available.isNotEmpty
              ? 'Ưu tiên ô gần cổng theo tuyến đường trên sơ đồ.'
              : counts[SlotStatus.unknown]! > 0
              ? 'Chưa thấy ô trống. Một số cảm biến đang mất kết nối.'
              : 'Bãi xe hiện hết chỗ khả dụng.',
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: available
              .take(3)
              .map(
                (s) => ActionChip(
                  label: Text(s.code),
                  avatar: const Icon(Icons.near_me, size: 16),
                  onPressed: () => setState(() => targetCode = s.code),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) => GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayed.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: max(2, (constraints.maxWidth / 200).floor()),
              mainAxisExtent: 130,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final slot = displayed[index];
              final status = slot.statusAt(controller.now);
              return Card(
                child: InkWell(
                  onTap: () => detail(slot),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                slot.code,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.directions_car,
                              color: statusColor(status),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          statusLabel(status),
                          style: TextStyle(color: statusColor(status)),
                        ),
                        if (controller.activeBooking?.code == slot.code)
                          const Text(
                            'Bạn đã đặt',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget myParkingBody() {
    final booking = controller.activeBooking;
    final position = controller.mine.position;
    final visit = controller.mine.visit;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Chỗ đặt của tôi', style: Theme.of(context).textTheme.titleLarge),
        if (controller.personalError != null)
          Card(
            child: ListTile(
              title: Text(controller.personalError!),
              trailing: IconButton(
                onPressed: controller.refreshPersonal,
                icon: const Icon(Icons.refresh),
              ),
            ),
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: booking == null
                ? const Text('Bạn chưa có lượt đặt chỗ còn hiệu lực.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        booking.code,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        'Đến trước ${clock(booking.expiresAt)} · còn ${max(0, booking.expiresAt.difference(controller.now).inSeconds)} giây',
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => setState(() {
                          targetCode = booking.code;
                          tab = 0;
                        }),
                        child: const Text('Xem đường từ cổng'),
                      ),
                      TextButton(
                        onPressed: controller.busy
                            ? null
                            : () => act(
                                () => widget.repository.cancel(booking.id),
                                'Đã hủy đặt chỗ.',
                              ),
                        child: const Text('Hủy đặt chỗ'),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Vị trí xe đã lưu', style: Theme.of(context).textTheme.titleLarge),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: position == null
                ? const Text(
                    'Chạm một ô đỗ để lưu thủ công, hoặc xác nhận đã đỗ để tự lưu.',
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        position.code,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        position.source == 'confirmed'
                            ? 'Lưu khi bạn xác nhận đã đỗ'
                            : 'Bạn đã lưu thủ công',
                      ),
                      if (position.note.isNotEmpty) Text(position.note),
                      Text('Lưu lúc ${clock(position.savedAt)}'),
                      if (visit != null)
                        Text(
                          'Phiên đỗ: ${visit.code} từ ${clock(visit.startedAt)}',
                        ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: findSlot(position.code) == null
                            ? null
                            : () => setState(() {
                                targetCode = position.code;
                                tab = 0;
                              }),
                        child: const Text('Tìm xe trên sơ đồ'),
                      ),
                    ],
                  ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            'Vị trí lưu là thông tin ghi nhớ. Cảm biến IR chưa xác định danh tính xe.',
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Lịch sử đặt chỗ gần đây',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        for (final item in controller.mine.bookings)
          ListTile(
            title: Text(item.code),
            subtitle: Text('Hạn đến ${clock(item.expiresAt)}'),
            trailing: Text(
              item.activeAt(controller.now)
                  ? 'Đang giữ'
                  : switch (item.status) {
                      'cancelled' => 'Đã hủy',
                      'checked_in' => 'Đã đỗ',
                      _ => 'Hết hạn',
                    },
            ),
          ),
      ],
    );
  }

  Widget statisticsBody() {
    if (report == null) return const SizedBox.shrink();
    return FutureBuilder<ParkingReport>(
      future: report,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Chưa tải được thống kê.'),
                FilledButton(
                  onPressed: () =>
                      setState(() => report = widget.repository.getReport()),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        final data = snapshot.data!;
        final peaks = [...data.peaks]
          ..sort((a, b) => b.minutes.compareTo(a.minutes));
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Thống kê 7 ngày',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      setState(() => report = widget.repository.getReport()),
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Tải lại thống kê',
                ),
              ],
            ),
            metric(
              'Tỷ lệ có xe trong thời gian có tín hiệu',
              data.utilization == null
                  ? 'Chưa có dữ liệu'
                  : '${data.utilization!.toStringAsFixed(1)}%',
            ),
            metric(
              'Thời gian đỗ trung bình',
              data.averageMinutes == null
                  ? 'Chưa có phiên hoàn tất'
                  : '${data.averageMinutes!.toStringAsFixed(1)} phút',
            ),
            metric(
              'Mức bao phủ dữ liệu cảm biến',
              '${data.coverage.toStringAsFixed(2)}%',
            ),
            const Text(
              'Tỷ lệ sử dụng chỉ tính thời gian cảm biến có tín hiệu. '
              'Thời gian đỗ tính từ lúc người dùng xác nhận đến lúc cảm biến báo xe rời đi; '
              'không tính các phiên mất tín hiệu.',
            ),
            const SizedBox(height: 20),
            Text('Giờ cao điểm', style: Theme.of(context).textTheme.titleLarge),
            if (peaks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Chưa có dữ liệu xe đỗ.'),
              ),
            for (final peak in peaks.take(5))
              ListTile(
                title: Text(
                  '${peak.hour.toString().padLeft(2, '0')}:00 – ${((peak.hour + 1) % 24).toString().padLeft(2, '0')}:00',
                ),
                subtitle: LinearProgressIndicator(
                  value: peaks.first.minutes == 0
                      ? 0
                      : peak.minutes / peaks.first.minutes,
                ),
                trailing: Text('${peak.minutes.toStringAsFixed(0)} phút-ô'),
              ),
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Giờ cao điểm tính theo múi giờ Việt Nam và tổng phút có xe trên các ô.',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget metric(String label, String value) => Card(
    child: ListTile(
      title: Text(label),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ),
  );
}

class UniversityMap extends StatelessWidget {
  final List<ParkingSlot> slots;
  final DateTime now;
  final ParkingSlot? target;
  final ValueChanged<ParkingSlot> onTap;
  const UniversityMap({
    super.key,
    required this.slots,
    required this.now,
    this.target,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1.65,
    child: LayoutBuilder(
      builder: (context, constraints) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE9EDF2),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _LanePainter(
                  target == null ? [] : routeFromEntrance(target!),
                ),
              ),
            ),
            Positioned(
              left: 4,
              top: constraints.maxHeight * 0.5 - 10,
              child: const Text('Cổng', style: TextStyle(fontSize: 11)),
            ),
            for (final slot in slots)
              Positioned(
                left: slot.mapX.clamp(0.15, 0.85) * constraints.maxWidth - 34,
                top: slot.mapY.clamp(0.2, 0.8) * constraints.maxHeight - 26,
                width: 68,
                height: 52,
                child: Material(
                  color: statusColor(slot.statusAt(now)),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () => onTap(slot),
                    borderRadius: BorderRadius.circular(10),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            slot.code,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            statusLabel(slot.statusAt(now)),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _LanePainter extends CustomPainter {
  final List<MapPoint> route;
  _LanePainter(this.route);
  @override
  void paint(Canvas canvas, Size size) {
    final lane = Paint()
      ..color = const Color(0xFFCED5DF)
      ..strokeWidth = 28;
    canvas.drawLine(
      Offset(size.width * .04, size.height * .5),
      Offset(size.width * .92, size.height * .5),
      lane,
    );
    if (route.length > 1) {
      final path = Path()
        ..moveTo(route.first.x * size.width, route.first.y * size.height);
      for (final point in route.skip(1)) {
        path.lineTo(point.x * size.width, point.y * size.height);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LanePainter oldDelegate) => true;
}
