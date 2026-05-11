// lib/core/constants.dart
class AppConstants {
  // Replace with YOUR_BACKEND_URL
  static const String baseUrl = "YOUR_BACKEND_URL/api";
  static const String socketUrl = "YOUR_BACKEND_URL";

  // Endpoints
  static const String verifyToken = "$baseUrl/auth/verify";
  static const String userProfile = "$baseUrl/user";
  static const String createRide = "$baseUrl/rides/create";
  static const String searchRides = "$baseUrl/rides/search";
  static const String createRequest = "$baseUrl/rides/requests/create";
  static const String homeRides = "$baseUrl/home";
}
