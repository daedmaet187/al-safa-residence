class Amenity {
  final String id;
  final String name;
  final String? description;
  final String? location;
  final int capacity;
  final String? imageUrl;
  final bool isActive;
  final Map<String, String>? operatingHours;

  const Amenity({
    required this.id,
    required this.name,
    this.description,
    this.location,
    required this.capacity,
    this.imageUrl,
    required this.isActive,
    this.operatingHours,
  });

  factory Amenity.fromJson(Map<String, dynamic> json) => Amenity(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        location: json['location'] as String?,
        capacity: json['capacity'] as int? ?? 10,
        imageUrl: json['imageUrl'] as String?,
        isActive: json['isActive'] as bool? ?? true,
        operatingHours:
            (json['operatingHours'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, v.toString()),
        ),
      );
}

class AmenityBooking {
  final String id;
  final String amenityId;
  final String? amenityName;
  final String date;
  final String startTime;
  final String endTime;
  final String status;
  final String? notes;
  final String createdAt;

  const AmenityBooking({
    required this.id,
    required this.amenityId,
    this.amenityName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory AmenityBooking.fromJson(Map<String, dynamic> json) => AmenityBooking(
        id: json['id'] as String,
        amenityId: json['amenityId'] as String? ?? '',
        amenityName:
            (json['amenity'] as Map<String, dynamic>?)?['name'] as String?,
        date: json['date'] as String? ?? '',
        startTime: json['startTime'] as String? ?? '',
        endTime: json['endTime'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        notes: json['notes'] as String?,
        createdAt: json['createdAt'] as String? ?? '',
      );
}
