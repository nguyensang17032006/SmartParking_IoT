import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/parking_slot.dart';

/// A schematic indoor map. Row order must match the physical parking bays.
/// Sensor state comes from [slots]; this widget only selects and draws a route.
class ParkingMap extends StatefulWidget {
  final List<ParkingSlot> slots;
  final List<String> topRowCodes;
  final List<String> bottomRowCodes;

  /// Search/filter can dim bays without moving their physical locations.
  final Set<String>? highlightedCodes;

  const ParkingMap({
    super.key,
    required this.slots,
    this.topRowCodes = const ['A01', 'A02', 'A03'],
    this.bottomRowCodes = const ['B01', 'B02', 'B03'],
    this.highlightedCodes,
  });

  @override
  State<ParkingMap> createState() => _ParkingMapState();
}

class _ParkingMapState extends State<ParkingMap> {
  String? _selectedId;

  bool _highlighted(String code) =>
      widget.highlightedCodes == null ||
      widget.highlightedCodes!.contains(code);

  ParkingSlot? get _selected {
    final displayed = {...widget.topRowCodes, ...widget.bottomRowCodes};
    for (final slot in widget.slots) {
      if (slot.id == _selectedId &&
          !slot.occupied &&
          displayed.contains(slot.code) &&
          _highlighted(slot.code)) {
        return slot;
      }
    }
    return null;
  }

  @override
  void didUpdateWidget(covariant ParkingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A selected bay may become occupied after a sensor update.
    if (_selected == null) _selectedId = null;
  }

  @override
  Widget build(BuildContext context) {
    final byCode = {for (final slot in widget.slots) slot.code: slot};
    final rows = [widget.topRowCodes, widget.bottomRowCodes];
    final columns = math.max(1, math.max(rows[0].length, rows[1].length));
    final designSize = Size(152 + columns * 108.0, 420);
    final selected = _selected;
    Offset? destination;

    for (var row = 0; row < rows.length; row++) {
      final column = rows[row].indexOf(selected?.code ?? '');
      if (column >= 0) {
        // Stop at the entrance to the selected bay, outside the bay itself.
        destination = Offset(128 + column * 108.0 + 44, row == 0 ? 145 : 255);
      }
    }
    final placedCodes = {...rows[0], ...rows[1]};
    final unplaced =
        widget.slots
            .where((slot) => !placedCodes.contains(slot.code))
            .map((slot) => slot.code)
            .toList()
          ..sort();

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE4E9F1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sơ đồ bãi xe',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF172A46),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Chạm ô trống để xem đường từ cổng vào.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6F7C90)),
            ),
            const SizedBox(height: 16),
            const Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _MapLegend(label: 'Trống', color: _MapColors.green),
                _MapLegend(label: 'Có xe', color: _MapColors.red),
                _MapLegend(label: 'Đã chọn', color: _MapColors.blue),
              ],
            ),
            const SizedBox(height: 14),
            AspectRatio(
              aspectRatio: designSize.width / designSize.height,
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 3,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: designSize.width,
                    height: designSize.height,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _ParkingRoadPainter(destination),
                          ),
                        ),
                        for (var row = 0; row < rows.length; row++)
                          for (
                            var column = 0;
                            column < rows[row].length;
                            column++
                          )
                            Positioned(
                              left: 128 + column * 108.0,
                              top: row == 0 ? 38 : 260,
                              width: 88,
                              height: 102,
                              child: _MapBay(
                                code: rows[row][column],
                                slot: byCode[rows[row][column]],
                                selected: selected?.code == rows[row][column],
                                highlighted: _highlighted(rows[row][column]),
                                onTap: () {
                                  final slot = byCode[rows[row][column]];
                                  if (slot != null &&
                                      !slot.occupied &&
                                      _highlighted(slot.code)) {
                                    setState(() => _selectedId = slot.id);
                                  }
                                },
                              ),
                            ),
                        const Positioned(
                          left: 24,
                          top: 382,
                          width: 80,
                          child: Column(
                            children: [
                              Icon(
                                Icons.login_rounded,
                                size: 18,
                                color: Color(0xFF172A46),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'CỔNG VÀO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF172A46),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (selected != null)
              Container(
                padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF3FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.alt_route_rounded,
                      size: 20,
                      color: _MapColors.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cổng vào → ${selected.code}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _MapColors.blue,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _selectedId = null),
                      child: const Text(
                        'Bỏ chọn',
                        style: TextStyle(color: _MapColors.blue),
                      ),
                    ),
                  ],
                ),
              )
            else
              const Text(
                'Đường màu xanh dẫn đến ô bạn chọn.',
                style: TextStyle(fontSize: 12, color: Color(0xFF6F7C90)),
              ),
            if (unplaced.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Ô chưa có vị trí trên sơ đồ: ${unplaced.join(', ')}.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6F7C90)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MapColors {
  static const green = Color(0xFF168A65);
  static const red = Color(0xFFDC5A64);
  static const blue = Color(0xFF356AE6);
  static const muted = Color(0xFF7B879B);
}

class _MapLegend extends StatelessWidget {
  final String label;
  final Color color;
  const _MapLegend({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: Color(0xFF6F7C90)),
      ),
    ],
  );
}

class _MapBay extends StatelessWidget {
  final String code;
  final ParkingSlot? slot;
  final bool selected;
  final bool highlighted;
  final VoidCallback onTap;
  const _MapBay({
    required this.code,
    required this.slot,
    required this.selected,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final available = slot != null && !slot!.occupied;
    final color = selected
        ? _MapColors.blue
        : slot == null
        ? _MapColors.muted
        : slot!.occupied
        ? _MapColors.red
        : _MapColors.green;
    final label = slot == null
        ? 'Chưa có dữ liệu'
        : slot!.occupied
        ? 'Có xe'
        : 'Trống';
    return Opacity(
      opacity: highlighted ? 1 : 0.3,
      child: Semantics(
        label: '$code, $label${selected ? ', đã chọn' : ''}',
        button: available && highlighted,
        selected: selected,
        child: Material(
          color: color.withAlpha(18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
            side: BorderSide(
              color: color.withAlpha(selected ? 255 : 110),
              width: selected ? 3 : 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: available && highlighted ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF172A46),
                    ),
                  ),
                  Icon(
                    slot == null
                        ? Icons.help_outline_rounded
                        : slot!.occupied
                        ? Icons.directions_car_rounded
                        : Icons.local_parking_rounded,
                    color: color,
                    size: 28,
                  ),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ParkingRoadPainter extends CustomPainter {
  final Offset? destination;
  const _ParkingRoadPainter(this.destination);

  @override
  void paint(Canvas canvas, Size size) {
    final horizontal = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(24, 158, size.width - 20, 242),
          const Radius.circular(12),
        ),
      );
    final entrance = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(24, 158, 104, 376),
          const Radius.circular(12),
        ),
      );
    final road = Path.combine(PathOperation.union, horizontal, entrance);
    canvas.drawPath(road, Paint()..color = const Color(0xFFEDF1F6));
    canvas.drawPath(
      road,
      Paint()
        ..color = const Color(0xFFDDE4ED)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final lane = Paint()
      ..color = const Color(0xFFB9C5D5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var x = 124.0; x < size.width - 32; x += 24) {
      canvas.drawLine(
        Offset(x, 200),
        Offset(math.min(x + 12, size.width - 24), 200),
        lane,
      );
    }
    for (var y = 260.0; y < 360; y += 24) {
      canvas.drawLine(Offset(64, y), Offset(64, y + 12), lane);
    }
    _arrow(canvas, const Offset(64, 296), const Offset(64, 272), lane);
    _arrow(canvas, const Offset(138, 180), const Offset(162, 180), lane);
    _arrow(
      canvas,
      Offset(size.width - 46, 220),
      Offset(size.width - 70, 220),
      lane,
    );

    // Gate spans the entrance lane.
    canvas.drawLine(
      const Offset(24, 374),
      const Offset(104, 374),
      Paint()
        ..color = const Color(0xFF172A46)
        ..strokeWidth = 3,
    );
    for (final x in [24.0, 104.0]) {
      canvas.drawCircle(
        Offset(x, 374),
        4,
        Paint()..color = const Color(0xFF172A46),
      );
    }

    final end = destination;
    if (end == null) return;
    final path = Path()
      ..moveTo(64, 366)
      ..lineTo(64, 200)
      ..lineTo(end.dx, 200)
      ..lineTo(end.dx, end.dy);
    final route = Paint()
      ..color = _MapColors.blue
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, route);
    canvas.drawCircle(
      const Offset(64, 366),
      6,
      Paint()..color = _MapColors.blue,
    );
    _arrow(
      canvas,
      Offset(end.dx, end.dy < 200 ? end.dy + 16 : end.dy - 16),
      end,
      route,
    );
  }

  void _arrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);
    final direction = (end - start).direction;
    for (final angle in [-0.65, 0.65]) {
      canvas.drawLine(
        end,
        end -
            Offset(
              math.cos(direction + angle) * 8,
              math.sin(direction + angle) * 8,
            ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParkingRoadPainter oldDelegate) =>
      oldDelegate.destination != destination;
}
