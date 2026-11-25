class NavigationLocation {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double speed;
  final double heading;

  const NavigationLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy = 0,
    this.speed = 0,
    this.heading = 0,
  });
}