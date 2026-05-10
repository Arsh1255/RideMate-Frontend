// lib/core/constants.dart
class AppConstants {
  // Replace with your current laptop IPv4
  static const String baseUrl = "http://10.210.25.173:3000/api";
  static const String socketUrl = "http://10.210.25.173:3000";

  // Endpoints
  static const String verifyToken = "$baseUrl/auth/verify";
  static const String userProfile = "$baseUrl/user";
  static const String createRide = "$baseUrl/rides/create";
  static const String searchRides = "$baseUrl/rides/search";
  static const String createRequest = "$baseUrl/rides/requests/create";
  static const String homeRides = "$baseUrl/home";
}
