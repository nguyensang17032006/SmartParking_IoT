import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../parking/presentation/pages/campus_map_page.dart';
import 'package:smart_parking/core/theme/app_spacing.dart';
import 'package:smart_parking/core/theme/app_text_styles.dart';
import 'package:smart_parking/core/theme/app_colors.dart';

import '../../domain/entities/campus.dart';
import '../../domain/usecases/get_campuses.dart';
import '../../data/datasources/campus_remote_data_source.dart';
import '../../data/repositories/campus_repository_impl.dart';
import '../widgets/campus_card.dart';
import '../../../navigation/presentation/pages/navigation_page.dart';
import '../../../navigation/domain/entities/navigation_destination.dart' as nav;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController searchController = TextEditingController();

  late final GetCampuses getCampuses;
  late Future<List<Campus>> campusesFuture;

  @override
  void initState() {
    super.initState();

    final supabase = Supabase.instance.client;

    final remoteDataSource = CampusRemoteDataSourceImpl(supabase);

    final repository = CampusRepositoryImpl(remoteDataSource);

    getCampuses = GetCampuses(repository);

    campusesFuture = getCampuses();
  }

  Future<void> refreshCampuses() async {
    setState(() {
      campusesFuture = getCampuses();
    });

    try {
      await campusesFuture;
    } catch (_) {
      // FutureBuilder sẽ hiển thị trạng thái lỗi.
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature sẽ được phát triển sau',
          style: AppTextStyles.bodyMedium,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: refreshCampuses,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xin chào',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.navy,
                        ),
                      ),
                      Text(
                        'Khánh!',
                        style: AppTextStyles.headingLarge.copyWith(
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => showComingSoon('Thông báo'),
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      size: 28,
                    ),
                  ),
                ],
              ),

              AppSpacing.gapXL,

              // SEARCH
              TextField(
                controller: searchController,
                onChanged: (_) => setState(() {}),
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm cơ sở...',
                  hintStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondary,
                  ),
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFFF2F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              AppSpacing.gapXL,

              // SECTION TITLE
              Text(
                'Danh sách cơ sở',
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.navy,
                ),
              ),

              AppSpacing.gapLG,

              // CAMPUS LIST
              FutureBuilder<List<Campus>>(
                future: campusesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        children: [
                          Text(
                            'Không thể tải danh sách cơ sở',
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: refreshCampuses,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    );
                  }

                  final campuses = snapshot.data ?? [];

                  final query = searchController.text.trim().toLowerCase();

                  final filteredCampuses = campuses.where((campus) {
                    return campus.name.toLowerCase().contains(query) ||
                        campus.code.toLowerCase().contains(query) ||
                        campus.address.toLowerCase().contains(query);
                  }).toList();

                  if (filteredCampuses.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Center(
                        child: Text(
                          query.isEmpty
                              ? 'Chưa có cơ sở nào'
                              : 'Không tìm thấy cơ sở',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: filteredCampuses.map((campus) {
                      return CampusCard(
                        campus: campus,

                        // DIRECTIONS
                        onDirections: campus.hasCoordinates
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => NavigationPage(
                                      destination: nav.NavigationDestination(
                                        campusId: campus.id,
                                        name: campus.name,
                                        latitude: campus.latitude!,
                                        longitude: campus.longitude!,
                                      ),
                                    ),
                                  ),
                                );
                              }
                            : null,
                        // VIEW PARKING
                        onViewParking: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CampusMapPage(campusId: campus.id),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
