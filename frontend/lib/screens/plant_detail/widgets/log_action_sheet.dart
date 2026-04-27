import 'package:flutter/material.dart';
import '../../../data/repository_provider.dart';
import '../../../models/action_log_entry.dart';
import '../../../models/plant_instance.dart';
import '../../../repositories/action_log_repository.dart';
import '../../../theme/app_colors.dart';

/// Bottom sheet for logging a care action against a plant instance.
///
/// Provides a 2-column action type grid, optional severity picker (for issues),
/// notes field, photo attachment button, and submit/draft buttons.
class LogActionSheet extends StatefulWidget {
  const LogActionSheet({super.key, required this.plant});

  final PlantInstance plant;

  /// Shows the [LogActionSheet] as a modal bottom sheet.
  static Future<ActionLogEntry?> show(
    BuildContext context, {
    required PlantInstance plant,
  }) {
    return showModalBottomSheet<ActionLogEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LogActionSheet(plant: plant),
    );
  }

  @override
  State<LogActionSheet> createState() => _LogActionSheetState();
}

class _LogActionSheetState extends State<LogActionSheet> {
  ActionType? _selectedAction;
  Severity? _selectedSeverity;
  final _notesController = TextEditingController();
  final List<String> _attachedPhotos = [];
  bool _submitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // ── Action type display data ──────────────────────────────────────

  static const _actionTypes = <_ActionTypeData>[
    _ActionTypeData(ActionType.watered, 'Watered', Icons.water_drop_outlined, Color(0xFFE6F1FB)),
    _ActionTypeData(ActionType.pruned, 'Pruned', Icons.content_cut_outlined, Color(0xFFEAF3DE)),
    _ActionTypeData(ActionType.fertilised, 'Fertilised', Icons.eco_outlined, Color(0xFFFAEEDA)),
    _ActionTypeData(ActionType.issueFound, 'Issue found', Icons.warning_amber_rounded, Color(0xFFFCEBEB)),
    _ActionTypeData(ActionType.repotted, 'Repotted', Icons.yard_outlined, Color(0xFFEAF3DE)),
    _ActionTypeData(ActionType.other, 'Other', Icons.more_horiz, Color(0xFFF5F5F5)),
  ];

  String _notesPlaceholder() {
    switch (_selectedAction) {
      case ActionType.watered:
        return 'How much water? Any observations?';
      case ActionType.pruned:
        return 'What did you prune? How much?';
      case ActionType.fertilised:
        return 'What fertiliser? How much?';
      case ActionType.issueFound:
        return 'Describe the issue...';
      case ActionType.repotted:
        return 'New pot size? Soil mix used?';
      case ActionType.other:
        return 'Add any notes...';
      case null:
        return 'Add any notes...';
    }
  }

  String _submitLabel() {
    if (_selectedAction == null) return 'Log action';
    final data = _actionTypes.firstWhere((d) => d.type == _selectedAction);
    return 'Log ${data.label.toLowerCase()}';
  }

  String _actionTitle() {
    if (_selectedAction == null) return '';
    return _actionTypes.firstWhere((d) => d.type == _selectedAction).label;
  }

  // ── Submit logic ──────────────────────────────────────────────────

  Future<void> _onSubmit({required bool isDraft}) async {
    if (_selectedAction == null) return;

    setState(() => _submitting = true);

    final entry = ActionLogEntry(
      actionId: 'log-${DateTime.now().millisecondsSinceEpoch}',
      instanceId: widget.plant.instanceId,
      actionType: _selectedAction!,
      title: _actionTitle(),
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      severity: _selectedAction == ActionType.issueFound ? _selectedSeverity : null,
      loggedBy: LoggedBy.user,
      imageRefs: List.unmodifiable(_attachedPhotos),
      occurredAt: DateTime.now(),
      isDraft: isDraft,
    );

    try {
      final repo = RepositoryProvider.of<ActionLogRepository>(context);
      final created = await repo.createLog(entry);
      if (mounted) {
        Navigator.of(context).pop(created);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHandleBar(),
              _buildHeader(),
              const SizedBox(height: 20),
              _buildActionGrid(),
              if (_selectedAction == ActionType.issueFound) ...[
                const SizedBox(height: 16),
                _buildSeverityPicker(),
              ],
              const SizedBox(height: 16),
              _buildNotesField(),
              const SizedBox(height: 12),
              _buildPhotoAttachment(),
              const SizedBox(height: 20),
              _buildSubmitRow(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Handle bar ────────────────────────────────────────────────────

  Widget _buildHandleBar() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ── Sheet header ──────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        // Plant icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.lightGreen,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.plant.emoji,
            style: const TextStyle(fontSize: 22),
          ),
        ),
        const SizedBox(width: 12),
        // Nickname, location, date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.plant.nickname,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepGreenText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.plant.gardenLocation} · ${_formatDate(DateTime.now())}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        // Close button
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, size: 22),
          color: Colors.grey[600],
        ),
      ],
    );
  }

  // ── Action type grid ──────────────────────────────────────────────

  Widget _buildActionGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.6,
      children: _actionTypes.map((data) {
        final isSelected = _selectedAction == data.type;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedAction = data.type;
              // Reset severity when switching away from issue
              if (data.type != ActionType.issueFound) {
                _selectedSeverity = null;
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.lightGreen : data.bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.activeGreen : Colors.transparent,
                width: isSelected ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  data.icon,
                  size: 20,
                  color: isSelected
                      ? AppColors.activeGreen
                      : Colors.grey[700],
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    data.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.activeGreen
                          : Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Severity picker ───────────────────────────────────────────────

  Widget _buildSeverityPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Severity',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _severityChip(Severity.mild, 'Mild', AppColors.statusGreen),
            const SizedBox(width: 8),
            _severityChip(Severity.moderate, 'Moderate', AppColors.statusAmber),
            const SizedBox(width: 8),
            _severityChip(Severity.severe, 'Severe', AppColors.statusRed),
          ],
        ),
      ],
    );
  }

  Widget _severityChip(Severity severity, String label, Color color) {
    final isSelected = _selectedSeverity == severity;
    return GestureDetector(
      onTap: () => setState(() => _selectedSeverity = severity),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? color : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  // ── Notes field ───────────────────────────────────────────────────

  Widget _buildNotesField() {
    return TextField(
      controller: _notesController,
      maxLines: 3,
      minLines: 2,
      decoration: InputDecoration(
        hintText: _notesPlaceholder(),
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.activeGreen),
        ),
      ),
    );
  }

  // ── Photo attachment ──────────────────────────────────────────────

  Widget _buildPhotoAttachment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                // Mock: add a placeholder photo reference
                setState(() {
                  _attachedPhotos.add(
                    'assets/photos/attached_${_attachedPhotos.length + 1}.jpg',
                  );
                });
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.grey[500],
                  size: 22,
                ),
              ),
            ),
            if (_attachedPhotos.isNotEmpty) ...[
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _attachedPhotos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.lightGreen,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.image,
                              color: AppColors.activeGreen,
                              size: 22,
                            ),
                          ),
                          Positioned(
                            top: -2,
                            right: -2,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _attachedPhotos.removeAt(index);
                                });
                              },
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ── Submit row ────────────────────────────────────────────────────

  Widget _buildSubmitRow() {
    final hasAction = _selectedAction != null;

    return Row(
      children: [
        // Draft button
        Expanded(
          flex: 2,
          child: OutlinedButton(
            onPressed: hasAction && !_submitting
                ? () => _onSubmit(isDraft: true)
                : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.deepGreenText,
              side: BorderSide(
                color: hasAction ? AppColors.greenBorder : Colors.grey[300]!,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Draft',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Primary submit button
        Expanded(
          flex: 3,
          child: ElevatedButton(
            onPressed: hasAction && !_submitting
                ? () => _onSubmit(isDraft: false)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              disabledForegroundColor: Colors.grey[500],
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _submitLabel(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────

  static String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

/// Internal data class for action type button configuration.
class _ActionTypeData {
  const _ActionTypeData(this.type, this.label, this.icon, this.bgColor);

  final ActionType type;
  final String label;
  final IconData icon;
  final Color bgColor;
}
