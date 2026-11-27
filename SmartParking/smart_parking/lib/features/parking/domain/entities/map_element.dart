
class MapElement {
  final String id;
  final String type;
  final String? label;
  final String? slotId;

  final int x;
  final int y;
  final int width;
  final int height;
  final int rotation;
  final String direction;
  final String? accessSide;

  const MapElement({
    required this.id,
    required this.type,
    this.label,
    this.slotId,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rotation,
    this.direction = 'two_way',
    this.accessSide,
  });
}
