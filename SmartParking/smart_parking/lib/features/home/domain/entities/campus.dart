
class Campus {
  final String id;
  final String code;
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;

  const Campus({
    required this.id,
    required this.code,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
  });

  bool get hasCoordinates =>
      latitude != null && longitude != null;
}
