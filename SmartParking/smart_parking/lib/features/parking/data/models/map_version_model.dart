import '../../domain/entities/map_version.dart';

class MapVersionModel extends MapVersion {
  const MapVersionModel({
    required super.id,
    required super.lotId,
    required super.versionNumber,
    super.publishedAt,
  });

  factory MapVersionModel.fromJson(Map<String, dynamic> json) {
    return MapVersionModel(
      id: json['id'] as String,
      lotId: json['lot_id'] as String,
      versionNumber: (json['version_number'] as num).toInt(),
      publishedAt: json['published_at'] == null
          ? null
          : DateTime.parse(json['published_at'] as String),
    );
  }
}