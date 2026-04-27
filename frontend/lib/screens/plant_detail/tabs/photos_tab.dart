import 'package:flutter/material.dart';
import '../../../data/repository_provider.dart';
import '../../../models/plant_instance.dart';
import '../../../models/plant_photo.dart';
import '../../../repositories/photo_repository.dart';
import '../../../screens/photo_detail/photo_detail_view.dart';
import '../../../widgets/app_filter_chip.dart';
import '../../../widgets/timeline_entry.dart';

/// The Photos tab displays a filterable 3-column photo grid grouped by month.
///
/// Each cell shows a coloured placeholder, an action tag overlay, and an
/// optional AI indicator dot. The last cell is an "+ Add photo" placeholder.
class PhotosTab extends StatefulWidget {
  const PhotosTab({super.key, required this.plant});

  final PlantInstance plant;

  @override
  State<PhotosTab> createState() => _PhotosTabState();
}

class _PhotosTabState extends State<PhotosTab> {
  static const _filters = ['All', 'Issues', 'Healthy', 'After care'];
  String _selectedFilter = 'All';
  late Future<List<PlantPhoto>> _photosFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPhotos();
  }

  void _loadPhotos() {
    final repo = RepositoryProvider.of<PhotoRepository>(context);
    _photosFuture = repo.getPhotosForPlant(
      widget.plant.instanceId,
      tagFilter: _selectedFilter == 'All' ? null : _selectedFilter,
    );
  }

  void _onFilterSelected(String filter) {
    setState(() {
      _selectedFilter = filter;
      _loadPhotos();
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
        // ── Photo grid ─────────────────────────────────────────
        Expanded(
          child: FutureBuilder<List<PlantPhoto>>(
            future: _photosFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final photos = snapshot.data ?? [];
              final sections = _groupByMonth(photos);

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: sections.length,
                itemBuilder: (context, index) {
                  final section = sections[index];
                  return _MonthSection(
                    header: section.header,
                    photos: section.photos,
                    plantInstanceId: widget.plant.instanceId,
                    isLastSection: index == sections.length - 1,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Groups photos by month-year and returns sections in reverse
  /// chronological order. An "+ Add photo" placeholder is appended to the
  /// last section.
  List<_PhotoSection> _groupByMonth(List<PlantPhoto> photos) {
    if (photos.isEmpty) {
      return [
        _PhotoSection(header: '', photos: const []),
      ];
    }

    final Map<String, List<PlantPhoto>> grouped = {};
    for (final photo in photos) {
      final key = _monthYearKey(photo.takenAt);
      grouped.putIfAbsent(key, () => []).add(photo);
    }

    // Sort keys in reverse chronological order
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return sortedKeys
        .map((key) => _PhotoSection(
              header: _formatMonthYear(grouped[key]!.first.takenAt),
              photos: grouped[key]!,
            ))
        .toList();
  }

  static String _monthYearKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}';

  static String _formatMonthYear(DateTime dt) {
    const months = [
      'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}

/// Simple data holder for a month group.
class _PhotoSection {
  const _PhotoSection({required this.header, required this.photos});
  final String header;
  final List<PlantPhoto> photos;
}

/// A single month section: header label + 3-column grid of photo cells.
class _MonthSection extends StatelessWidget {
  const _MonthSection({
    required this.header,
    required this.photos,
    required this.plantInstanceId,
    this.isLastSection = false,
  });

  final String header;
  final List<PlantPhoto> photos;
  final String plantInstanceId;
  final bool isLastSection;

  @override
  Widget build(BuildContext context) {
    // Build cell list: photos + optional add-photo placeholder
    final List<Widget> cells = photos.map<Widget>((photo) {
      return _PhotoCell(photo: photo, plantInstanceId: plantInstanceId);
    }).toList();

    if (isLastSection) {
      cells.add(const _AddPhotoCell());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              header,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
                letterSpacing: 1.2,
              ),
            ),
          ),
        GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cells,
        ),
      ],
    );
  }
}

/// A single photo cell: coloured placeholder with action tag overlay and
/// optional AI indicator dot.
class _PhotoCell extends StatelessWidget {
  const _PhotoCell({required this.photo, required this.plantInstanceId});

  final PlantPhoto photo;
  final String plantInstanceId;

  /// AI indicator dot colour from the design spec.
  static const Color _aiDotColor = Color(0xFF7FB86A);

  @override
  Widget build(BuildContext context) {
    final bgColor = TimelineEntry.dotColor(photo.actionTag).withValues(alpha: 0.3);
    final (chipBg, chipText) = TimelineEntry.tagChipColors(photo.actionTag);
    final label = TimelineEntry.actionLabel(photo.actionTag);

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.of(context).push<Map<String, String>>(
          MaterialPageRoute(
            builder: (_) => PhotoDetailView(
              photoId: photo.photoId,
              plantInstanceId: plantInstanceId,
            ),
          ),
        );
        if (result != null &&
            result['navigateTo'] == 'care' &&
            context.mounted) {
          // Switch to Care tab (index 3)
          DefaultTabController.of(context).animateTo(3);
        }
      },
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              // ── Action tag overlay (bottom-left) ──────────────
              Positioned(
                left: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: 6,
                  ),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: chipText,
                    ),
                  ),
                ),
              ),
              // ── AI indicator dot (top-right) ──────────────────
              if (photo.hasAIAnalysis)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _aiDotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The "+ Add photo" placeholder cell shown as the last item in the grid.
class _AddPhotoCell extends StatelessWidget {
  const _AddPhotoCell();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade500, size: 24),
            const SizedBox(height: 4),
            Text(
              '+ Add photo',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
