import 'package:flutter/material.dart';
import '../../data/repository_provider.dart';
import '../../models/plant_instance.dart';
import '../../repositories/plant_repository.dart';
import '../../theme/app_colors.dart';
import 'tabs/history_tab.dart';
import 'tabs/overview_tab.dart';
import 'tabs/care_tab.dart';
import 'tabs/photos_tab.dart';
import 'widgets/log_action_sheet.dart';
import 'widgets/plant_header.dart';

/// The main Plant Detail screen.
///
/// Receives a [plantInstanceId] and displays plant information across four
/// tabs (Overview, History, Photos, Care) beneath a pinned header.
/// A floating action button provides quick access to log care actions.
class PlantDetailScreen extends StatefulWidget {
  const PlantDetailScreen({super.key, required this.plantInstanceId});

  /// The unique identifier of the plant instance to display.
  final String plantInstanceId;

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  late Future<PlantInstance> _plantFuture;

  static const _tabs = <String>['Overview', 'History', 'Photos', 'Care'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = RepositoryProvider.of<PlantRepository>(context);
    _plantFuture = repo.getPlantById(widget.plantInstanceId);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: FutureBuilder<PlantInstance>(
        future: _plantFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')),
            );
          }

          final plant = snapshot.data!;

          return Scaffold(
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 180,
                    backgroundColor: AppColors.darkGreen,
                    leading: const BackButton(color: Colors.white),
                    flexibleSpace: FlexibleSpaceBar(
                      background: PlantHeader(plant: plant),
                    ),
                    bottom: TabBar(
                      labelColor: AppColors.activeGreen,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: AppColors.activeGreen,
                      indicatorWeight: 2,
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: _tabs.map((t) => Tab(text: t)).toList(),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  OverviewTab(plant: plant),
                  HistoryTab(plant: plant),
                  PhotosTab(plant: plant),
                  CareTab(plant: plant),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () {
                LogActionSheet.show(context, plant: plant);
              },
              backgroundColor: AppColors.darkGreen,
              foregroundColor: Colors.white,
              label: const Text('+ Log action'),
            ),
          );
        },
      ),
    );
  }
}

