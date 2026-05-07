import '../../models/ride_model.dart';

enum RideUIState {
  ownerActive,
  ownerStarted,
  memberAccepted,
  memberPending,
  memberRemoved,
  memberRideCancelled,
}

class RideCardLogic {
  static String getVehicleName(VehicleType type) {
    switch (type) {
      case VehicleType.car: return "Car";
      case VehicleType.bike: return "Bike";
      case VehicleType.bmtcBus: return "BMTC Bus";
      case VehicleType.metro: return "Namma Metro";
      case VehicleType.none: return "Walking (Stride)";
    }
  }

  static String formatMode(RideMode mode) {
    switch (mode) {
      case RideMode.publicTransportation: return "Public Transport";
      case RideMode.carpool: return "Carpool";
      case RideMode.hasVehicle: return "Own Vehicle";
      case RideMode.stride: return "Stride";
    }
  }
}