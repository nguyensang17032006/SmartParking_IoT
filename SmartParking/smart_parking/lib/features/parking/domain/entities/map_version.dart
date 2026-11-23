class MapVersion {
  final String id;
  final String lotId;
  final int versionNumber;
  final DateTime? publishedAt;

  const MapVersion({
    required this.id,
    required this.lotId,
    required this.versionNumber,
    this.publishedAt,
  });
}