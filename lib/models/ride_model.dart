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
  final List<String> participantIds; // Already accepted members
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
}