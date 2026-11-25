
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/campus_model.dart';

abstract class CampusRemoteDataSource {
  Future<List<CampusModel>> getCampuses();
}

class CampusRemoteDataSourceImpl
    implements CampusRemoteDataSource {
  final SupabaseClient supabase;

  CampusRemoteDataSourceImpl(this.supabase);

  @override
  Future<List<CampusModel>> getCampuses() async {
    final response = await supabase
        .from('campuses')
        .select('id, code, name, address, latitude, longitude')
        .order('code', ascending: true);

    return response
        .map((json) => CampusModel.fromJson(json))
        .toList();
  }
}
