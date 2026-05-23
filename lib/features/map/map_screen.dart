import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../Models/location_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/bottom_nav.dart';

class MapScreen extends StatefulWidget {
  final String? highlightLocationId;
  final String? highlightLocationName;

  const MapScreen({
    super.key,
    this.highlightLocationId,
    this.highlightLocationName,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _firestoreService = FirestoreService();
  final _searchController = TextEditingController();
  final _mapController = MapController();

  List<LocationModel> _locations = [];
  List<LocationModel> _searchResults = [];
  LocationModel? _selectedLocation;
  bool _isLoading = true;
  bool _showSearch = false;
  String _selectedType = 'all';

  // ASTU campus center
  static const _center = LatLng(8.5644, 39.2921);
  static const double _defaultZoom = 17.5;

  final _types = [
    'all',
    'building',
    'lecture_hall',
    'lab',
    'office',
    'service',
  ];

  @override
  void initState() {
    super.initState();
    _loadLocations();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    setState(() => _isLoading = true);
    try {
      _locations = await _firestoreService.getLocations();
      if (_locations.isEmpty) _locations = _defaultLocations();
    } catch (e) {
      _locations = _defaultLocations();
    }

    // Highlight location passed from timetable/directory
    if (widget.highlightLocationId != null) {
      final match = _locations
          .where((l) => l.id == widget.highlightLocationId)
          .toList();
      if (match.isNotEmpty) {
        Future.delayed(
          const Duration(milliseconds: 600),
          () => _selectLocation(match.first),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _selectLocation(LocationModel loc) {
    setState(() => _selectedLocation = loc);
    _mapController.move(LatLng(loc.latitude, loc.longitude), 19);
  }

  void _clearSelection() => setState(() => _selectedLocation = null);

  void _onSearchChanged() {
    final q = _searchController.text.toLowerCase();
    if (q.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() {
      _searchResults = _locations
          .where(
            (l) =>
                l.name.toLowerCase().contains(q) ||
                l.buildingCode.toLowerCase().contains(q) ||
                (l.description?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    });
  }

  List<LocationModel> get _filteredLocations => _selectedType == 'all'
      ? _locations
      : _locations.where((l) => l.locationType == _selectedType).toList();

  Color _markerColor(String type) {
    switch (type) {
      case 'lecture_hall':
        return AppColors.primary;
      case 'lab':
        return AppColors.info;
      case 'office':
        return AppColors.warning;
      case 'service':
        return const Color(0xFF7F77DD);
      default:
        return const Color(0xFF0F6E56);
    }
  }

  IconData _markerIcon(String type) {
    switch (type) {
      case 'lecture_hall':
        return Icons.school_outlined;
      case 'lab':
        return Icons.science_outlined;
      case 'office':
        return Icons.badge_outlined;
      case 'service':
        return Icons.room_service_outlined;
      default:
        return Icons.apartment_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── MAP ──────────────────────────────────────
          if (!_isLoading)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: _defaultZoom,
                minZoom: 15,
                maxZoom: 21,
                onTap: (_, __) {
                  _clearSelection();
                  setState(() {
                    _showSearch = false;
                    _searchResults = [];
                  });
                },
              ),
              children: [
                // OpenStreetMap tile layer
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.campus_companion',
                  maxZoom: 21,
                ),
                // Markers layer
                MarkerLayer(
                  markers: _filteredLocations.map((loc) {
                    final isSelected = _selectedLocation?.id == loc.id;
                    final color = _markerColor(loc.locationType);
                    return Marker(
                      point: LatLng(loc.latitude, loc.longitude),
                      width: isSelected ? 48 : 36,
                      height: isSelected ? 48 : 36,
                      child: GestureDetector(
                        onTap: () => _selectLocation(loc),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected ? color : color.withOpacity(0.85),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: isSelected ? 3 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            _markerIcon(loc.locationType),
                            color: Colors.white,
                            size: isSelected ? 22 : 16,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),

          // ── OVERLAY UI ───────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Top controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Back
                          _floatingButton(
                            Icons.arrow_back,
                            () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          // Search bar
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _showSearch = true),
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _showSearch
                                        ? AppColors.primary
                                        : AppColors.border,
                                    width: _showSearch ? 1.5 : 0.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: _showSearch
                                    ? TextField(
                                        controller: _searchController,
                                        autofocus: true,
                                        decoration: InputDecoration(
                                          hintText:
                                              'Search buildings, rooms...',
                                          hintStyle: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.search,
                                            size: 18,
                                            color: AppColors.primary,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: const Icon(
                                              Icons.clear,
                                              size: 16,
                                            ),
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() {
                                                _showSearch = false;
                                                _searchResults = [];
                                              });
                                            },
                                          ),
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 12,
                                              ),
                                        ),
                                      )
                                    : Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.search,
                                              size: 18,
                                              color: AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              widget.highlightLocationName ??
                                                  'Search buildings, rooms, offices...',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color:
                                                    widget.highlightLocationName !=
                                                        null
                                                    ? AppColors.textPrimary
                                                    : AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Filter chips
                      if (!_showSearch)
                        SizedBox(
                          height: 32,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: _types.map((t) {
                              final isSelected = _selectedType == t;
                              final label = t == 'all'
                                  ? 'All'
                                  : t == 'lecture_hall'
                                  ? 'Halls'
                                  : _capitalize(t);
                              return GestureDetector(
                                onTap: () => setState(() => _selectedType = t),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? AppColors.white
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),

                // Search results
                if (_showSearch && _searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      children: _searchResults
                          .take(5)
                          .map(
                            (loc) => ListTile(
                              dense: true,
                              leading: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _markerColor(
                                    loc.locationType,
                                  ).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _markerIcon(loc.locationType),
                                  size: 16,
                                  color: _markerColor(loc.locationType),
                                ),
                              ),
                              title: Text(
                                loc.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                '${loc.buildingCode}${loc.floor != null ? ' · ${loc.floor}' : ''}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              onTap: () {
                                _selectLocation(loc);
                                _searchController.clear();
                                setState(() {
                                  _showSearch = false;
                                  _searchResults = [];
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),

                const Spacer(),

                // Map controls (right side)
                Padding(
                  padding: const EdgeInsets.only(right: 12, bottom: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      children: [
                        _floatingButton(
                          Icons.add,
                          () => _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom + 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _floatingButton(
                          Icons.remove,
                          () => _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom - 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _floatingButton(
                          Icons.my_location,
                          () => _mapController.move(_center, _defaultZoom),
                        ),
                      ],
                    ),
                  ),
                ),

                // Legend
                if (!_showSearch && _selectedLocation == null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _legendItem(AppColors.primary, 'Halls'),
                        _legendItem(AppColors.info, 'Labs'),
                        _legendItem(AppColors.warning, 'Offices'),
                        _legendItem(const Color(0xFF7F77DD), 'Services'),
                        _legendItem(const Color(0xFF0F6E56), 'Buildings'),
                      ],
                    ),
                  ),

                // Bottom sheet — selected location
                if (_selectedLocation != null)
                  _buildBottomSheet(_selectedLocation!),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: 3,
        onTap: (i) {
          if (i != 3) Navigator.pop(context);
        },
      ),
    );
  }

  Widget _floatingButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4),
          ],
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildBottomSheet(LocationModel loc) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _markerColor(loc.locationType).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _markerIcon(loc.locationType),
                    color: _markerColor(loc.locationType),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${loc.typeLabel}${loc.floor != null ? ' · ${loc.floor} floor' : ''}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _clearSelection,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            if (loc.description != null) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      loc.description!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.navigation_outlined, size: 16),
                    label: const Text('Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      minimumSize: const Size(0, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: const Text('Classes here'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      minimumSize: const Size(0, 40),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  List<LocationModel> _defaultLocations() => [
    LocationModel(
      id: 'main',
      name: 'Main Block',
      buildingCode: 'MAIN',
      locationType: 'building',
      latitude: 8.5648,
      longitude: 39.2921,
      description: 'Main administrative building',
    ),
    LocationModel(
      id: 'block_a',
      name: 'Block A',
      buildingCode: 'BLOCK-A',
      locationType: 'building',
      latitude: 8.5642,
      longitude: 39.2918,
      description: 'Engineering lectures',
    ),
    LocationModel(
      id: 'block_b',
      name: 'Block B',
      buildingCode: 'BLOCK-B',
      locationType: 'building',
      latitude: 8.5650,
      longitude: 39.2925,
      description: 'CSE department',
    ),
    LocationModel(
      id: 'block_c',
      name: 'Block C',
      buildingCode: 'BLOCK-C',
      locationType: 'building',
      latitude: 8.5638,
      longitude: 39.2924,
      description: 'Science labs',
    ),
    LocationModel(
      id: 'library',
      name: 'Library',
      buildingCode: 'LIB',
      locationType: 'service',
      latitude: 8.5644,
      longitude: 39.2915,
      description: 'Main university library',
    ),
    LocationModel(
      id: 'cafeteria',
      name: 'Cafeteria',
      buildingCode: 'CAF',
      locationType: 'service',
      latitude: 8.5640,
      longitude: 39.2928,
      description: 'Main cafeteria',
    ),
    LocationModel(
      id: 'admin',
      name: 'Admin Block',
      buildingCode: 'ADMIN',
      locationType: 'office',
      latitude: 8.5635,
      longitude: 39.2920,
      description: 'Administrative offices and registrar',
    ),
    LocationModel(
      id: 'lab1',
      name: 'Computer Lab 1',
      buildingCode: 'BLOCK-A',
      locationType: 'lab',
      floor: '1st',
      latitude: 8.5641,
      longitude: 39.2917,
      description: 'CSE computer laboratory',
    ),
    LocationModel(
      id: 'hall1',
      name: 'Auditorium A',
      buildingCode: 'MAIN',
      locationType: 'lecture_hall',
      floor: 'Ground',
      latitude: 8.5647,
      longitude: 39.2920,
      description: 'Main auditorium, capacity 300',
    ),
    LocationModel(
      id: 'registrar',
      name: 'Registrar Office',
      buildingCode: 'ADMIN',
      locationType: 'office',
      floor: 'Ground',
      latitude: 8.5634,
      longitude: 39.2919,
      description: 'Room 001, opposite main entrance',
    ),
  ];
}
