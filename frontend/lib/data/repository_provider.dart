import 'package:flutter/widgets.dart';

import '../repositories/action_log_repository.dart';
import '../repositories/care_instruction_repository.dart';
import '../repositories/photo_repository.dart';
import '../repositories/plant_repository.dart';

/// An [InheritedWidget] that holds all repository instances and makes them
/// available to descendant widgets via [RepositoryProvider.of<T>(context)].
///
/// Wrap this around [MaterialApp] so every screen can access repositories
/// without tight coupling to concrete implementations.
class RepositoryProvider extends InheritedWidget {
  final PlantRepository plantRepository;
  final ActionLogRepository actionLogRepository;
  final CareInstructionRepository careInstructionRepository;
  final PhotoRepository photoRepository;

  const RepositoryProvider({
    super.key,
    required this.plantRepository,
    required this.actionLogRepository,
    required this.careInstructionRepository,
    required this.photoRepository,
    required super.child,
  });

  /// Look up a repository by its abstract type from the nearest
  /// [RepositoryProvider] ancestor.
  ///
  /// Usage:
  /// ```dart
  /// final plantRepo = RepositoryProvider.of<PlantRepository>(context);
  /// ```
  static T of<T>(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<RepositoryProvider>();
    assert(provider != null, 'No RepositoryProvider found in context');

    if (T == PlantRepository) return provider!.plantRepository as T;
    if (T == ActionLogRepository) return provider!.actionLogRepository as T;
    if (T == CareInstructionRepository) {
      return provider!.careInstructionRepository as T;
    }
    if (T == PhotoRepository) return provider!.photoRepository as T;

    throw ArgumentError('Unknown repository type: $T');
  }

  @override
  bool updateShouldNotify(RepositoryProvider oldWidget) =>
      plantRepository != oldWidget.plantRepository ||
      actionLogRepository != oldWidget.actionLogRepository ||
      careInstructionRepository != oldWidget.careInstructionRepository ||
      photoRepository != oldWidget.photoRepository;
}
