class PostRideModel {
  // ================= BASIC INFO =================

  final String rideName;

  final int totalSeats;

  // ================= SOURCE =================

  final String sourceName;

  final double sourceLat;

  final double sourceLng;

  // ================= DESTINATION =================

  final String destinationName;

  final double destinationLat;

  final double destinationLng;

  // ================= TIME =================

  final DateTime departureTime;

  // ================= TRANSPORT =================

  final String mode;

  final String vehicleType;

  // ================= OPTIONAL =================

  final String? notes;

  final int? pricePerPerson;

  // ================= CONSTRUCTOR =================

  PostRideModel({
    required this.rideName,

    required this.totalSeats,

    required this.sourceName,
    required this.sourceLat,
    required this.sourceLng,

    required this.destinationName,
    required this.destinationLat,
    required this.destinationLng,

    required this.departureTime,

    required this.mode,

    required this.vehicleType,

    this.notes,

    this.pricePerPerson,
  });

  // ================= TO JSON =================

  Map<String, dynamic> toJson() {
    return {
      "rideName": rideName,

      "totalSeats": totalSeats,

      "source": {"name": sourceName, "lat": sourceLat, "lng": sourceLng},

      "destination": {
        "name": destinationName,

        "lat": destinationLat,

        "lng": destinationLng,
      },

      "departureTime": departureTime.toIso8601String(),

      "mode": mode,

      "vehicleType": vehicleType,

      "notes": notes,

      "pricePerPerson": pricePerPerson,
    };
  }
}
