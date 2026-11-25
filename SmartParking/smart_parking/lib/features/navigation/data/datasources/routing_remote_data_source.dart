import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/navigation_route_model.dart';

abstract class RoutingRemoteDataSource {
  Future<NavigationRouteModel> getNavigationRoute({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  });
}

class RoutingRemoteDataSourceImpl
    implements RoutingRemoteDataSource {
  final http.Client client;

  final String baseUrl;

  const RoutingRemoteDataSourceImpl({
    required this.client,
    this.baseUrl = 'https://router.project-osrm.org',
  });

  @override
  Future<NavigationRouteModel> getNavigationRoute({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    final coordinates =
        '$originLongitude,$originLatitude;'
        '$destinationLongitude,$destinationLatitude';

    final uri = Uri.parse(
      '$baseUrl/route/v1/driving/$coordinates',
    ).replace(
      queryParameters: {
        'overview': 'full',
        'geometries': 'geojson',
        'steps': 'true',
        'alternatives': 'false',
      },
    );

    final response = await client.get(uri).timeout(
      const Duration(seconds: 20),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Không thể lấy tuyến đường: ${response.statusCode}',
      );
    }

    final json = jsonDecode(
      utf8.decode(response.bodyBytes),
    ) as Map<String, dynamic>;

    if (json['code'] != 'Ok') {
      throw Exception(
        json['message'] ?? 'Không tìm thấy tuyến đường.',
      );
    }

    final routes = json['routes'] as List<dynamic>?;

    if (routes == null || routes.isEmpty) {
      throw Exception('Không tìm thấy tuyến đường phù hợp.');
    }

    return NavigationRouteModel.fromJson(
      routes.first as Map<String, dynamic>,
    );
  }
}