import 'package:flutter/material.dart';
import '../../data/repository_provider.dart';
import '../../models/action_log_entry.dart';
import '../../models/ai_analysis.dart';
import '../../models/plant_instance.dart';
import '../../models/plant_photo.dart';
import '../../repositories/photo_repository.dart';
import '../../repositories/plant_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/timeline_entry.dart';
import '../plant_detail/widgets/log_action_sheet.dart';

/// Full-screen photo detail view.
///
/// Displays a single photo at full width with gradient overlays, a top bar
/// with back / add-note buttons, bottom overlays showing the date,
/// action context, photo counter, and a horizontal thumbnail strip for
/// navigating between photos.
class PhotoDetailView extends StatefulWidget {
  const PhotoDetailView({
    super.key,
    required this.photoId,
    required this.plantInstanceId,
  });

  final String photoId;
  final String plantInstanceId;

  @override
  State<PhotoDetailView> createState() => _PhotoDetailViewState();
}

class _PhotoDetailViewState extends State<PhotoDetailView> {
  late Future<_PhotoDetailData> _dataFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dataFuture = _loadData();
  }

  Future<_PhotoDetailData> _loadData() async {
    final photoRepo = RepositoryProvider.of<PhotoRepository>(context);
    final plantRepo = RepositoryProvider.of<PlantRepository>(context);
    final allPhotos = await photoRepo.getPhotosForPlant(widget.plantInstanceId);
    final photo = await photoRepo.getPhotoById(widget.photoId);
    final plant = await plantRepo.getPlantById(widget.plantInstanceId);
    final currentIndex = allPhotos.indexWhere((p) => p.photoId == widget.photoId);
    return _PhotoDetailData(
      photo: photo,
      allPhotos: allPhotos,
      plant: plant,
      currentIndex: currentIndex == -1 ? 0 : currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<_PhotoDetailData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white)),
            );
          }
          final data = snapshot.data!;
          return _PhotoDetailBody(data: data);
        },
      ),
    );
  }
}

/// Internal data holder for the loaded photo detail state.
class _PhotoDetailData {
  const _PhotoDetailData({
    required this.photo,
    required this.allPhotos,
    required this.plant,
    required this.currentIndex,
  });

  final PlantPhoto photo;
  final List<PlantPhoto> allPhotos;
  final PlantInstance plant;
  final int currentIndex;
}

/// The main body of the photo detail view, rendered once data is loaded.
class _PhotoDetailBody extends StatefulWidget {
  const _PhotoDetailBody({required this.data});

  final _PhotoDetailData data;

  @override
  State<_PhotoDetailBody> createState() => _PhotoDetailBodyState();
}

class _PhotoDetailBodyState extends State<_PhotoDetailBody> {
  late int _currentIndex;
  AIAnalysis? _analysis;
  bool _analysisLoading = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.data.currentIndex;
    _loadAnalysis();
  }

  PlantPhoto get _currentPhoto => widget.data.allPhotos[_currentIndex];

  void _loadAnalysis() {
    setState(() => _analysisLoading = true);
    final repo = RepositoryProvider.of<PhotoRepository>(context);
    repo.getAnalysisForPhoto(_currentPhoto.photoId).then((analysis) {
      if (mounted) {
        setState(() {
          _analysis = analysis;
          _analysisLoading = false;
        });
      }
    });
  }

  void _onThumbnailTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    _loadAnalysis();
  }

  /// Opens the LogActionSheet for the current plant.
  void _onLogTreatment() {
    LogActionSheet.show(context, plant: widget.data.plant);
  }

  /// Navigates back to the Care tab by popping with a navigation hint.
  void _onViewCarePlan() {
    Navigator.of(context).pop({'navigateTo': 'care'});
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return Column(
      children: [
        // ── Full-width photo area with gradient overlays ──────────
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Coloured placeholder using the action type colour
              Container(
                color: TimelineEntry.dotColor(_currentPhoto.actionTag)
                    .withValues(alpha: 0.4),
                child: Center(
                  child: Icon(
                    Icons.local_florist,
                    size: 80,
                    color: TimelineEntry.dotColor(_currentPhoto.actionTag)
                        .withValues(alpha: 0.6),
                  ),
                ),
              ),

              // ── Top gradient overlay ────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: topPadding + 80,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xCC000000),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Bottom gradient overlay ─────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 120,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color(0xCC000000),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Top bar: back button + add note ─────────────────
              Positioned(
                top: topPadding + 8,
                left: 8,
                right: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      label: const Text(
                        'Photos',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // Add note action — wired in a later task
                      },
                      icon: const Icon(Icons.note_add_outlined,
                          color: Colors.white, size: 24),
                    ),
                  ],
                ),
              ),

              // ── Bottom-left: date + action context ──────────────
              Positioned(
                bottom: 16,
                left: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatDate(_currentPhoto.takenAt),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _actionContextLabel(_currentPhoto),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Bottom-right: photo counter ─────────────────────
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.data.allPhotos.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Thumbnail strip + AI analysis + action pills (scrollable) ─
        SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ThumbnailStrip(
                photos: widget.data.allPhotos,
                activeIndex: _currentIndex,
                onThumbnailTap: _onThumbnailTap,
              ),
              if (!_analysisLoading && _analysis != null)
                _AIAnalysisCard(analysis: _analysis!),
              _ActionPills(
                onLogTreatment: _onLogTreatment,
                onViewCarePlan: _onViewCarePlan,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds a human-readable action context label for the photo.
  String _actionContextLabel(PlantPhoto photo) {
    final label = TimelineEntry.actionLabel(photo.actionTag);
    if (photo.actionTag == ActionType.issueFound) {
      return '$label logged';
    }
    return label;
  }

  /// Formats a [DateTime] as "d MMM yyyy" (e.g. "5 Jun 2025").
  static String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

/// Horizontal scrollable thumbnail strip for navigating between photos.
///
/// Each thumbnail is a 56×56 coloured square with an action-type dot at
/// bottom-right. The active thumbnail has a green [AppColors.activeGreen]
/// border.
class _ThumbnailStrip extends StatelessWidget {
  const _ThumbnailStrip({
    required this.photos,
    required this.activeIndex,
    required this.onThumbnailTap,
  });

  final List<PlantPhoto> photos;
  final int activeIndex;
  final ValueChanged<int> onThumbnailTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 12),
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final photo = photos[index];
          final isActive = index == activeIndex;
          final dotColor = TimelineEntry.dotColor(photo.actionTag);

          return GestureDetector(
            onTap: () => onThumbnailTap(index),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive ? AppColors.activeGreen : Colors.transparent,
                  width: isActive ? 2.5 : 0,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isActive ? 5.5 : 8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Coloured placeholder matching action type
                    Container(
                      color: dotColor.withValues(alpha: 0.3),
                      child: Center(
                        child: Icon(
                          Icons.local_florist,
                          size: 24,
                          color: dotColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ),

                    // Action-type dot at bottom-right
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// AI analysis card shown below the thumbnail strip when analysis data exists.
///
/// Uses the issue variant styling: red background, red border, red text.
/// Includes condition name header, analysis body text, and an optional
/// progression comparison section with side-by-side thumbnails.
class _AIAnalysisCard extends StatelessWidget {
  const _AIAnalysisCard({required this.analysis});

  final AIAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.redBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.redBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header: condition name + AI analysis label ───────────
          Row(
            children: [
              Expanded(
                child: Text(
                  analysis.conditionName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.redText,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.redBorder.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 12, color: AppColors.redText),
                    SizedBox(width: 4),
                    Text(
                      'AI analysis',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.redText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Body: analysis text ─────────────────────────────────
          Text(
            analysis.analysisText,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.redText,
              height: 1.4,
            ),
          ),

          // ── Progression comparison (conditional) ────────────────
          if (analysis.progression != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Side-by-side thumbnails with dates
                  Row(
                    children: [
                      _ProgressionThumbnail(
                        label: _formatDate(analysis.progression!.previousDate),
                        color: AppColors.statusRed.withValues(alpha: 0.25),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward,
                          size: 16, color: AppColors.redText),
                      const SizedBox(width: 8),
                      _ProgressionThumbnail(
                        label: _formatDate(analysis.progression!.currentDate),
                        color: AppColors.statusRed.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Progression description
                  Text(
                    analysis.progression!.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.redText,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

/// Small coloured placeholder thumbnail used in the progression comparison.
class _ProgressionThumbnail extends StatelessWidget {
  const _ProgressionThumbnail({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Icon(
              Icons.local_florist,
              size: 24,
              color: AppColors.redText.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.redText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Action pills row displayed below the AI analysis card (or thumbnail strip).
///
/// Contains a primary "Log treatment done" pill (dark green) and a secondary
/// outlined "View care plan" pill.
class _ActionPills extends StatelessWidget {
  const _ActionPills({
    required this.onLogTreatment,
    required this.onViewCarePlan,
  });

  final VoidCallback onLogTreatment;
  final VoidCallback onViewCarePlan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(
        children: [
          // ── Primary pill: Log treatment done ─────────────────
          Expanded(
            child: ElevatedButton(
              onPressed: onLogTreatment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Log treatment done',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // ── Secondary pill: View care plan ───────────────────
          Expanded(
            child: OutlinedButton(
              onPressed: onViewCarePlan,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'View care plan',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
