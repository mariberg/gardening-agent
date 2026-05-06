import 'package:flutter/material.dart';

/// Empty state view displayed when no plants match the current filter/search.
///
/// Shows a centred plant icon and "No plants found" message. When [hasSearchText]
/// is true, an additional hint suggests clearing the search.
class PlantsEmptyState extends StatelessWidget {
  const PlantsEmptyState({super.key, required this.hasSearchText});

  final bool hasSearchText;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.eco_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No plants found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            if (hasSearchText) ...[
              const SizedBox(height: 8),
              Text(
                'Try clearing your search',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
