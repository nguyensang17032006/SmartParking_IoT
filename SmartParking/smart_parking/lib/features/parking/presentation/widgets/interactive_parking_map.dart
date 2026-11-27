import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/map_element.dart';
import '../../domain/entities/parking_slot.dart';

import '../utils/parking_map_layout.dart';
import '../utils/parking_slot_hit_tester.dart';
import 'parking_map_painter.dart';
import 'isometric_parking_painter.dart';

class InteractiveParkingMap extends StatefulWidget {
  final List<MapElement> elements;
  final List<List<Offset>> routeSegments;
  final ValueChanged<String?>? onSlotSelected;
  final Map<String, ParkingSlot> slotsById;

  final double cellSize;

  final String? selectedSlotId;

  const InteractiveParkingMap({
    super.key,
    required this.elements,
    required this.slotsById,
    this.cellSize = 20,
    this.selectedSlotId,
    this.onSlotSelected,
    this.routeSegments = const [],
  });

  @override
  State<InteractiveParkingMap> createState() => _InteractiveParkingMapState();
}

class _InteractiveParkingMapState extends State<InteractiveParkingMap> {
  static const double _minScale = 0.05;

  static const double _maxScale = 8.0;

  final TransformationController _transformationController =
      TransformationController();
  final ParkingSlotHitTester _hitTester = const ParkingSlotHitTester();
  bool _isIsometric = true;

  bool _needsFit = true;

  bool _fitScheduled = false;

  Size? _viewportSize;

  late ParkingMapLayout _isometricLayout;

  late Size _flatCanvasSize;

  @override
  void initState() {
    super.initState();

    _calculateLayouts();
  }

  @override
  void didUpdateWidget(covariant InteractiveParkingMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Chỉ tính lại layout khi cấu trúc bản đồ thay đổi.
    // Không reset camera khi trạng thái slot thay đổi.
    if (oldWidget.elements != widget.elements ||
        oldWidget.cellSize != widget.cellSize) {
      _calculateLayouts();

      _needsFit = true;
    }
  }

  // =====================================================
  // LAYOUT
  // =====================================================
  void _handleMapTap(TapUpDetails details) {
    final scenePoint = _transformationController.toScene(details.localPosition);

    final slotId = _hitTester.hitTest(
      scenePoint: scenePoint,
      elements: widget.elements,
      isIsometric: _isIsometric,
      projection: _isometricLayout.projection,
      cellSize: widget.cellSize,
    );

    widget.onSlotSelected?.call(slotId);
  }

  void _calculateLayouts() {
    _isometricLayout = ParkingMapLayout.calculate(
      elements: widget.elements,
      cellSize: widget.cellSize,
    );

    double maxX = 1;
    double maxY = 1;

    for (final element in widget.elements) {
      maxX = math.max(maxX, (element.x + element.width).toDouble());

      maxY = math.max(maxY, (element.y + element.height).toDouble());
    }

    _flatCanvasSize = Size(maxX * widget.cellSize, maxY * widget.cellSize);
  }

  Size get _canvasSize {
    return _isIsometric ? _isometricLayout.canvasSize : _flatCanvasSize;
  }

  // =====================================================
  // FIT MAP
  // =====================================================

  void _scheduleFit() {
    if (_fitScheduled) return;

    _fitScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitScheduled = false;

      if (!mounted || !_needsFit) return;

      _fitMap();
    });
  }

  void _fitMap() {
    final viewport = _viewportSize;

    if (viewport == null || viewport.width <= 0 || viewport.height <= 0) {
      return;
    }

    final canvas = _canvasSize;

    const padding = 8.0;

    final availableWidth = math.max(1.0, viewport.width - padding * 2);

    final availableHeight = math.max(1.0, viewport.height - padding * 2);

    final scale = math
        .min(availableWidth / canvas.width, availableHeight / canvas.height)
        .clamp(_minScale, _maxScale)
        .toDouble();

    final translateX = (viewport.width - canvas.width * scale) / 2;

    final translateY = (viewport.height - canvas.height * scale) / 2;

    final matrix = Matrix4.identity();

    matrix.setEntry(0, 0, scale);
    matrix.setEntry(1, 1, scale);
    matrix.setEntry(2, 2, scale);

    matrix.setEntry(0, 3, translateX);
    matrix.setEntry(1, 3, translateY);

    _transformationController.value = matrix;

    _needsFit = false;
  }

  // =====================================================
  // ZOOM
  // =====================================================

  void _zoom(double factor) {
    final viewport = _viewportSize;

    if (viewport == null) return;

    final currentMatrix = _transformationController.value;

    final currentScale = currentMatrix.getMaxScaleOnAxis();

    final newScale = (currentScale * factor)
        .clamp(_minScale, _maxScale)
        .toDouble();

    if (currentScale == newScale) return;

    // Giữ nguyên điểm nằm ở giữa màn hình khi zoom.
    final viewportCenter = Offset(viewport.width / 2, viewport.height / 2);

    final sceneCenter = _transformationController.toScene(viewportCenter);

    final translateX = viewportCenter.dx - sceneCenter.dx * newScale;

    final translateY = viewportCenter.dy - sceneCenter.dy * newScale;

    final matrix = Matrix4.identity();

    matrix.setEntry(0, 0, newScale);
    matrix.setEntry(1, 1, newScale);
    matrix.setEntry(2, 2, newScale);

    matrix.setEntry(0, 3, translateX);
    matrix.setEntry(1, 3, translateY);

    _transformationController.value = matrix;
  }

  void _zoomIn() {
    _zoom(1.25);
  }

  void _zoomOut() {
    _zoom(0.8);
  }

  // =====================================================
  // VIEW MODE
  // =====================================================

  void _toggleViewMode() {
    setState(() {
      _isIsometric = !_isIsometric;

      _needsFit = true;
    });
  }

  // =====================================================
  // MAP CANVAS
  // =====================================================

  Widget _buildCanvas() {
    final size = _canvasSize;

    return SizedBox(
      width: size.width,
      height: size.height,
      child: RepaintBoundary(
        child: CustomPaint(
          foregroundPainter: _RouteOverlay(widget.routeSegments, (p) => _isIsometric ? _isometricLayout.projection.project(p.dx, p.dy) : p * widget.cellSize),
          painter: _isIsometric
              ? IsometricParkingPainter(
                  elements: widget.elements,
                  slotsById: widget.slotsById,
                  projection: _isometricLayout.projection,
                  selectedSlotId: widget.selectedSlotId,
                )
              : ParkingMapPainter(
                  elements: widget.elements,
                  slotsById: widget.slotsById,
                  cellSize: widget.cellSize,
                  selectedSlotId: widget.selectedSlotId,
                ),
        ),
      ),
    );
  }

  // =====================================================
  // MAP CONTROL BUTTON
  // =====================================================

  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    String? label,
    bool highlighted = false,
  }) {
    const primaryColor = Color(0xFFF0194B);
    const navyColor = Color(0xFF111A31);

    final color = highlighted ? primaryColor : navyColor;

    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 48,
            height: label == null ? 48 : 58,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                if (label != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // ZOOM CONTROLS
  // =====================================================

  Widget _buildZoomControls() {
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _zoomIn,
            tooltip: 'Phóng to',
            icon: const Icon(Icons.add),
            color: const Color(0xFF111A31),
          ),
          const SizedBox(width: 32, child: Divider(height: 1)),
          IconButton(
            onPressed: _zoomOut,
            tooltip: 'Thu nhỏ',
            icon: const Icon(Icons.remove),
            color: const Color(0xFF111A31),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);

        if (_viewportSize != viewport) {
          _viewportSize = viewport;
          _needsFit = true;
        }

        if (_needsFit) {
          _scheduleFit();
        }

        return ClipRect(
          child: ColoredBox(
            color: const Color(0xFFEEF2F7),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Sơ đồ tương tác.
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: _handleMapTap,
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    alignment: Alignment.topLeft,
                    constrained: false,
                    minScale: _minScale,
                    maxScale: _maxScale,
                    panEnabled: true,
                    scaleEnabled: true,
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    child: _buildCanvas(),
                  ),
                ),
                // Chuyển chế độ và đặt lại góc nhìn.
                Positioned(
                  top: 16,
                  right: 12,
                  child: Column(
                    children: [
                      _buildControlButton(
                        icon: Icons.layers_outlined,
                        tooltip: 'Chuyển chế độ bản đồ',
                        label: _isIsometric ? '2.5D' : '2D',
                        highlighted: true,
                        onPressed: _toggleViewMode,
                      ),
                      const SizedBox(height: 10),
                      _buildControlButton(
                        icon: Icons.refresh,
                        tooltip: 'Đặt lại góc nhìn',
                        onPressed: _fitMap,
                      ),
                    ],
                  ),
                ),

                // Phóng to, thu nhỏ.
                Positioned(right: 12, bottom: 20, child: _buildZoomControls()),

                // Gợi ý thao tác.
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.pan_tool_alt_outlined,
                            size: 15,
                            color: Color(0xFF64748B),
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Kéo và chụm để thu phóng',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();

    super.dispose();
  }
}

class _RouteOverlay extends CustomPainter {
  final List<List<Offset>> segments;
  final Offset Function(Offset) project;
  _RouteOverlay(this.segments, this.project);
  @override
  void paint(Canvas canvas, Size size) {
    for (final segment in segments) {
      if (segment.isEmpty) continue;
      final points = segment.map(project).toList();
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) { path.lineTo(p.dx, p.dy); }
      final paint = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, paint..color = Colors.white..strokeWidth = 7);
      canvas.drawPath(path, paint..color = const Color(0xFF168AFF)..strokeWidth = 4);
      canvas.drawCircle(points.last, 4, Paint()..color = const Color(0xFF168AFF));
    }
  }
  @override
  bool shouldRepaint(covariant _RouteOverlay oldDelegate) => true;
}
