enum RideMode { publicTransportation, carpool, hasVehicle, stride }
enum VehicleType { car, bike, bmtcBus, metro, none }

class Ride {
  final String rideId;
  final String rideName; // Added as per requirement
  final String pickup;
  final String dropoff;
  final DateTime departureTime; // Original time set by creator
  final VehicleType vehicleType;
  final RideMode mode;
  final double pricePerPerson;
  final int availableSeats;
  final String creatorId; // To identify if current user is owner
  final List<RideParticipant> participants;
  final List<String> pendingRequestIds; // Requested but not accepted
  final String status; // 'pending', 'active', 'started', 'removed' , 

  Ride({
    required this.rideId,
    required this.rideName,
    required this.pickup,
    required this.dropoff,
    required this.departureTime,
    required this.vehicleType,
    required this.mode,
    required this.pricePerPerson,
    required this.availableSeats,
    required this.creatorId,
    this.participantIds = const [],
    this.pendingRequestIds = const [],
    required this.status,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
  return Ride(
    rideId: json['rideId'],
    rideName: json['rideName'],
    pickup: json['pickup'],
    dropoff: json['dropoff'],
    departureTime: DateTime.parse(json['departureTime']),
    vehicleType: VehicleType.values.firstWhere(
      (e) => e.name == json['vehicleType'],
    ),
    mode: RideMode.values.firstWhere(
      (e) => e.name == json['mode'],
    ),
    pricePerPerson: json['pricePerPerson'],
    availableSeats: json['availableSeats'],
    creatorId: json['creatorId'],
    status: json['status'],
    participantIds: List<String>.from(json['participantIds'] ?? []),
    pendingRequestIds:
        List<String>.from(json['pendingRequestIds'] ?? []),
  );
}
}

class RideParticipant {
  final String id;
  final String name;
  final String profilePic;

  RideParticipant({
    required this.id,
    required this.name,
    required this.profilePic,
  });

  factory RideParticipant.fromJson(
    Map<String, dynamic> json,
  ) {
    return RideParticipant(
      id: json['_id'],
      name: json['name'],
      profilePic: json['profilePic'],
    );
  }
}

