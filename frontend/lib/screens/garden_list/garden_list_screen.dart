import 'package:flutter/material.dart';
import '../../data/repository_provider.dart';
import '../../models/plant_instance.dart';
import '../../repositories/plant_repository.dart';
import '../../theme/app_colors.dart';
import '../plant_detail/plant_detail_screen.dart';

/// Temporary garden list screen that displays all plants as a grid of cards.
///
/// Serves as the entry point for testing until the real Home screen is built.
/// Each card shows the plant emoji, nickname, status label, and garden location.
/// Tapping a card navigates to [PlantDetailScreen].
class GardenListScreen extends StatefulWidget {
  const GardenListScreen({super.key});

  @override
  State<GardenListScreen> createState() => _GardenListScreenState();
}

class _GardenListScreenState extends State<GardenListScreen> {
  late Future<List<PlantInstance>> _plantsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = RepositoryProvider.of<PlantRepository>(context);
    _plantsFuture = repo.getAllPlants();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Garden'),
        backgroundColor: AppColors.darkGreen,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<PlantInstance>>(
        future: _plantsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final plants = snapshot.data ?? [];
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: plants.length,
            itemBuilder: (context, index) {
              return _PlantCard(plant: plants[index]);
            },
          );
        },
      ),
    );
  }
}

class _PlantCard extends StatelessWidget {
  const _PlantCard({required this.plant});

  final PlantInstance plant;

  Color _statusColor() {
    switch (plant.status) {
      case PlantStatus.thriving:
        return AppColors.statusGreen;
      case PlantStatus.needsAttention:
        return AppColors.statusAmber;
      case PlantStatus.alert:
        return AppColors.statusRed;
    }
  }

  Color _statusBg() {
    switch (plant.status) {
      case PlantStatus.thriving:
        return AppColors.lightGreen;
      case PlantStatus.needsAttention:
        return AppColors.amberBg;
      case PlantStatus.alert:
        return AppColors.redBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlantDetailScreen(
              plantInstanceId: plant.instanceId,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji
            Text(
              plant.emoji,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 10),
            // Nickname
            Text(
              plant.nickname,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.deepGreenText,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            // Status chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusBg(),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _statusColor().withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                plant.statusLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _statusColor(),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Garden location
            Text(
              plant.gardenLocation,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
