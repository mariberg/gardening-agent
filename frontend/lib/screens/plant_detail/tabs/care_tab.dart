import 'package:flutter/material.dart';
import '../../../data/repository_provider.dart';
import '../../../models/care_instruction.dart';
import '../../../models/plant_instance.dart';
import '../../../repositories/care_instruction_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_filter_chip.dart';
import '../../../widgets/care_instruction_card.dart';

/// The Care tab displays all care instructions for the plant's species,
/// filterable by source type via a row of [AppFilterChip] widgets.
class CareTab extends StatefulWidget {
  const CareTab({super.key, required this.plant});

  final PlantInstance plant;

  @override
  State<CareTab> createState() => _CareTabState();
}

class _CareTabState extends State<CareTab> {
  static const _filters = ['All', 'RHS', 'Forum', 'Book', 'Other'];

  /// Maps chip labels to [SourceType.name] values used by the repository.
  static const _filterToSourceType = {
    'RHS': 'rhs',
    'Forum': 'forum',
    'Book': 'book',
    'Other': 'other',
  };

  String _selectedFilter = 'All';
  late Future<List<CareInstruction>> _instructionsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadInstructions();
  }

  void _loadInstructions() {
    final repo =
        RepositoryProvider.of<CareInstructionRepository>(context);
    _instructionsFuture = repo.getInstructionsForSpecies(
      widget.plant.speciesId,
      sourceTypeFilter: _filterToSourceType[_selectedFilter],
    );
  }

  void _onFilterSelected(String filter) {
    setState(() {
      _selectedFilter = filter;
      _loadInstructions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Filter chip row ───────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final label = _filters[index];
                return AppFilterChip(
                  label: label,
                  isSelected: _selectedFilter == label,
                  onTap: () => _onFilterSelected(label),
                );
              },
            ),
          ),
        ),
        // ── Instruction list ──────────────────────────────────────
        Expanded(
          child: FutureBuilder<List<CareInstruction>>(
            future: _instructionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final instructions = snapshot.data ?? [];

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                // +1 for the "+ Add yours" link at the bottom
                itemCount: instructions.length + 1,
                itemBuilder: (context, index) {
                  if (index < instructions.length) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CareInstructionCard(
                        instruction: instructions[index],
                      ),
                    );
                  }
                  // "+ Add yours" link
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: GestureDetector(
                      onTap: () {
                        // Will open Add Care Instruction sheet in a later task.
                      },
                      child: const Text(
                        '+ Add yours',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.activeGreen,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
