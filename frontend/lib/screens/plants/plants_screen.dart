import 'package:flutter/material.dart';

import '../../data/repository_provider.dart';
import '../../models/plant_instance.dart';
import '../../repositories/plant_repository.dart';
import '../../widgets/app_filter_chip.dart';
import 'widgets/plant_card.dart';
import 'widgets/plants_empty_state.dart';
import 'widgets/plants_header.dart';

/// Filter enum for the plants screen
enum PlantStatusFilter { all, thriving, needsAttention, alert }

/// Filters and sorts plants by status filter and search text.
/// This is a pure function for easy testing.
List<PlantInstance> filterPlants(
  List<PlantInstance> plants,
  PlantStatusFilter filter,
  String searchText,
) {
  var result = plants.toList();

  // Apply status filter
  if (filter != PlantStatusFilter.all) {
    final status = switch (filter) {
      PlantStatusFilter.thriving => PlantStatus.thriving,
      PlantStatusFilter.needsAttention => PlantStatus.needsAttention,
      PlantStatusFilter.alert => PlantStatus.alert,
      PlantStatusFilter.all => throw StateError('unreachable'),
    };
    result = result.where((p) => p.status == status).toList();
  }

  // Apply search filter
  if (searchText.isNotEmpty) {
    final query = searchText.toLowerCase();
    result = result.where((p) =>
      p.nickname.toLowerCase().contains(query) ||
      p.speciesCommonName.toLowerCase().contains(query)
    ).toList();
  }

  // Sort alphabetically by nickname
  result.sort((a, b) => a.nickname.toLowerCase().compareTo(b.nickname.toLowerCase()));

  return result;
}

/// The main Plants screen that displays all plants in a grid,
/// supports filtering by status and searching by name.
class PlantsScreen extends StatefulWidget {
  const PlantsScreen({super.key});

  @override
  State<PlantsScreen> createState() => _PlantsScreenState();
}

class _PlantsScreenState extends State<PlantsScreen> {
  List<PlantInstance> _allPlants = [];
  PlantStatusFilter _selectedFilter = PlantStatusFilter.all;
  String _searchText = '';
  bool _isLoading = true;
  bool _hasError = false;
  bool _hasLoadedData = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedData) {
      _hasLoadedData = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final plantRepo = RepositoryProvider.of<PlantRepository>(context);
      final plants = await plantRepo.getAllPlants();
      setState(() {
        _allPlants = plants;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  /// Pure filtering logic: applies status filter and search text
  List<PlantInstance> get _filteredPlants {
    return filterPlants(_allPlants, _selectedFilter, _searchText);
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search plants...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchText.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchText = '';
                  });
                },
              )
            : null,
      ),
      onChanged: (value) {
        setState(() {
          _searchText = value;
        });
      },
    );
  }

  Widget _buildFilterBar() {
    const filterLabels = {
      PlantStatusFilter.all: 'All',
      PlantStatusFilter.thriving: 'Thriving',
      PlantStatusFilter.needsAttention: 'Needs Attention',
      PlantStatusFilter.alert: 'Alert',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: PlantStatusFilter.values.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AppFilterChip(
              label: filterLabels[filter]!,
              isSelected: _selectedFilter == filter,
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PlantsHeader(totalPlantCount: _allPlants.length),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _buildSearchBar(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildFilterBar(),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_hasError)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Something went wrong',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_filteredPlants.isEmpty)
              PlantsEmptyState(hasSearchText: _searchText.isNotEmpty)
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                  children: _filteredPlants.map((plant) {
                    return PlantCard(
                      plant: plant,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/plant-detail',
                          arguments: plant.instanceId,
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
