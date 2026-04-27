import 'package:flutter/material.dart';
import 'package:garden_app/data/mock/mock_action_log_repository.dart';
import 'package:garden_app/data/mock/mock_care_instruction_repository.dart';
import 'package:garden_app/data/mock/mock_photo_repository.dart';
import 'package:garden_app/data/mock/mock_plant_repository.dart';
import 'package:garden_app/data/repository_provider.dart';
import 'package:garden_app/screens/garden_list/garden_list_screen.dart';
import 'package:garden_app/screens/photo_detail/photo_detail_view.dart';
import 'package:garden_app/screens/plant_detail/plant_detail_screen.dart';
import 'package:garden_app/theme/app_colors.dart';

void main() {
  runApp(const GardenApp());
}

class GardenApp extends StatelessWidget {
  const GardenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      plantRepository: MockPlantRepository(),
      actionLogRepository: MockActionLogRepository(),
      careInstructionRepository: MockCareInstructionRepository(),
      photoRepository: MockPhotoRepository(),
      child: MaterialApp(
        title: 'Garden App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const GardenListScreen(),
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }

  static Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/plant-detail':
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(
          builder: (_) => PlantDetailScreen(
            plantInstanceId: args['plantInstanceId']!,
          ),
          settings: settings,
        );
      case '/photo-detail':
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(
          builder: (_) => PhotoDetailView(
            photoId: args['photoId']!,
            plantInstanceId: args['plantInstanceId']!,
          ),
          settings: settings,
        );
      default:
        return null;
    }
  }
}
