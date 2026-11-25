
import '../../domain/entities/campus.dart';

class CampusModel extends Campus {
  const CampusModel({
    required super.id,
    required super.code,
    required super.name,
    required super.address,
    super.latitude,
    super.longitude,
  });

  factory CampusModel.fromJson(Map<String, dynamic> json) {
    return CampusModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
