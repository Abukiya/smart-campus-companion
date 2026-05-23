class LocationModel {
  final String id;
  final String name;
  final String buildingCode;
  final String locationType; // 'building' | 'office' | 'lab' | 'lecture_hall' | 'service'
  final String? floor;
  final double latitude;
  final double longitude;
  final String? description;

  LocationModel({
    required this.id,
    required this.name,
    required this.buildingCode,
    required this.locationType,
    this.floor,
    required this.latitude,
    required this.longitude,
    this.description,
  });

  factory LocationModel.fromMap(Map<String, dynamic> map, String id) {
    return LocationModel(
      id: id,
      name: map['name'] ?? '',
      buildingCode: map['building_code'] ?? '',
      locationType: map['location_type'] ?? 'building',
      floor: map['floor'],
      latitude: (map['latitude'] ?? 8.5644).toDouble(),
      longitude: (map['longitude'] ?? 39.2921).toDouble(),
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'building_code': buildingCode,
      'location_type': locationType,
      'floor': floor,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
    };
  }

  String get typeLabel {
    switch (locationType) {
      case 'lecture_hall': return 'Lecture Hall';
      case 'lab': return 'Laboratory';
      case 'office': return 'Office';
      case 'service': return 'Service';
      default: return 'Building';
    }
  }
}
