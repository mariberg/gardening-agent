import 'package:flutter/material.dart';
import '../../../data/repository_provider.dart';
import '../../../models/action_log_entry.dart';
import '../../../models/care_instruction.dart';
import '../../../models/plant_instance.dart';
import '../../../repositories/action_log_repository.dart';
import '../../../repositories/care_instruction_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/ai_insight_card.dart';
import '../../../widgets/care_instruction_card.dart';
import '../../../widgets/timeline_entry.dart';

/// The Overview tab content for the Plant Detail screen.
///
/// Displays an AI insight card, recent care history timeline, and care
/// instructions for the given [plant]. Data is loaded from repositories
/// via [RepositoryProvider].
class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key, required this.plant});

  /// The plant instance whose overview is displayed.
  final PlantInstance plant;

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  late Future<_OverviewData> _dataFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final logRepo = RepositoryProvider.of<ActionLogRepository>(context);
    final careRepo = RepositoryProvider.of<CareInstructionRepository>(context);
    _dataFuture = _loadData(logRepo, careRepo);
  }

  Future<_OverviewData> _loadData(
    ActionLogRepository logRepo,
    CareInstructionRepository careRepo,
  ) async {
    final results = await Future.wait([
      logRepo.getRecentLogs(widget.plant.instanceId, limit: 5),
      careRepo.getInstructionsForPlant(widget.plant.instanceId),
    ]);
    return _OverviewData(
      recentLogs: results[0] as List<ActionLogEntry>,
      careInstructions: results[1] as List<CareInstruction>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_OverviewData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final data = snapshot.data!;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // AI Insight Card
            if (widget.plant.aiInsightText != null) ...[
              AIInsightCard(insightText: widget.plant.aiInsightText!),
              const SizedBox(height: 20),
            ],

            // Care history section header
            _SectionHeader(
              title: 'Care history',
              actionLabel: '+ Log action',
              onActionTap: () {
                // Will open LogActionSheet in a later task.
              },
            ),
            const SizedBox(height: 12),

            // Recent timeline entries
            if (data.recentLogs.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'No care actions logged yet.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              )
            else
              ...List.generate(data.recentLogs.length, (i) {
                return TimelineEntry(
                  entry: data.recentLogs[i],
                  isLast: i == data.recentLogs.length - 1,
                );
              }),

            const SizedBox(height: 12),

            // Care instructions section header
            _SectionHeader(
              title: 'Care instructions',
              actionLabel: '+ Add yours',
              onActionTap: () {
                // Will open Add Care Instruction sheet in a later task.
              },
            ),
            const SizedBox(height: 12),

            // Care instruction cards
            if (data.careInstructions.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'No care instructions yet.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              )
            else
              ...data.careInstructions.map((instruction) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CareInstructionCard(instruction: instruction),
                );
              }),
          ],
        );
      },
    );
  }
}

/// Internal data holder for the overview tab's async data.
class _OverviewData {
  final List<ActionLogEntry> recentLogs;
  final List<CareInstruction> careInstructions;

  const _OverviewData({
    required this.recentLogs,
    required this.careInstructions,
  });
}

/// A section header row with a title and a tappable action label.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onActionTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.deepGreenText,
          ),
        ),
        GestureDetector(
          onTap: onActionTap,
          child: Text(
            actionLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.activeGreen,
            ),
          ),
        ),
      ],
    );
  }
}
