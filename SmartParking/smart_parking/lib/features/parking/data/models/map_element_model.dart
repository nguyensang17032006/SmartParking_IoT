
import '../../domain/entities/map_element.dart';

class MapElementModel extends MapElement {
  const MapElementModel({
    required super.id,
    required super.type,
    super.label,
    super.slotId,
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    required super.rotation,
    super.direction,
    super.accessSide,
  });

  factory MapElementModel.fromJson(Map<String, dynamic> json) {
    return MapElementModel(
      id: json['id'] as String,
      type: json['element_type'] as String,
      label: json['label'] as String?,
      slotId: json['slot_id'] as String?,
      x: (json['grid_x'] as num).toInt(),
      y: (json['grid_y'] as num).toInt(),
      width: (json['grid_width'] as num).toInt(),
      height: (json['grid_height'] as num).toInt(),
      rotation: (json['rotation'] as num?)?.toInt() ?? 0,
      direction: json['direction'] as String? ?? 'two_way',
      accessSide: json['access_side'] as String?,
    );
  }
}
