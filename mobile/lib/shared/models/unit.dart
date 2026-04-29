class ResidenceUnit {
  final String id;
  final String number;
  final int floor;
  final String type;
  final double areaSqm;
  final int bedrooms;
  final int bathrooms;
  final int parkingSpots;
  final String buildingName;

  const ResidenceUnit({
    required this.id,
    required this.number,
    required this.floor,
    required this.type,
    required this.areaSqm,
    required this.bedrooms,
    required this.bathrooms,
    required this.parkingSpots,
    required this.buildingName,
  });

  factory ResidenceUnit.fromJson(Map<String, dynamic> json) => ResidenceUnit(
        id: json['id'] as String,
        number: json['number'] as String,
        floor: (json['floor'] as num).toInt(),
        type: json['type'] as String? ?? 'Apartment',
        areaSqm: (json['areaSqm'] as num?)?.toDouble() ?? 0,
        bedrooms: (json['bedrooms'] as num?)?.toInt() ?? 0,
        bathrooms: (json['bathrooms'] as num?)?.toInt() ?? 0,
        parkingSpots: (json['parkingSpots'] as num?)?.toInt() ?? 0,
        buildingName: json['buildingName'] as String? ?? '',
      );

  String get label => 'Unit $number';
  String get fullAddress => '$buildingName — Unit $number (Floor $floor)';
}
