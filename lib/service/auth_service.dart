import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Communicate with your Laptop Backend[cite: 13, 14]
  Future<http.Response> verifyWithBackend(String profilePic) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("No user logged in");
    }

    final token = await user.getIdToken(true);

    return await http.post(
      Uri.parse(AppConstants.verifyToken),

      headers: {"Content-Type": "application/json"},

      body: jsonEncode({"idToken": token, "profilePic": profilePic}),
    );
  }

  Future<Map<String, dynamic>> fetchUserProfile(String userId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("No user logged in");
    }

    final token = await user.getIdToken();

    final response = await http.get(
      Uri.parse("${AppConstants.userProfile}/$userId"),

      headers: {
        "Content-Type": "application/json",

        "Authorization": "Bearer $token",
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch profile");
    }
  }

  Future<Map<String, dynamic>> createRide(Map<String, dynamic> rideData) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user logged in");
    
    final token = await user.getIdToken();
    
    final response = await http.post(
      Uri.parse(AppConstants.createRide),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(rideData),
    );
    
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to create ride: ${response.body}");
    }
  }
  Future<Map<String, dynamic>> searchRides(Map<String, dynamic> searchParams) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user logged in");
    
    final token = await user.getIdToken();
    
    final response = await http.post(
      Uri.parse(AppConstants.searchRides),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(searchParams),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to search rides: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> createRequest(Map<String, dynamic> requestData) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user logged in");
    
    final token = await user.getIdToken();
    
    final response = await http.post(
      Uri.parse(AppConstants.createRequest),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(requestData),
    );
    
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to create request: ${response.body}");
    }
  }
  Future<Map<String, dynamic>> getRideDetails(String rideId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    
    final token = await user.getIdToken();
    
    final response = await http.get(
      Uri.parse("${AppConstants.baseUrl}/rides/$rideId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch ride details: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> acceptRequest(String requestId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    
    final token = await user.getIdToken();
    
    final response = await http.post(
      Uri.parse("${AppConstants.baseUrl}/rides/requests/$requestId/accept"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to accept request: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> rejectRequest(String requestId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    
    final token = await user.getIdToken();
    
    final response = await http.post(
      Uri.parse("${AppConstants.baseUrl}/rides/requests/$requestId/reject"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to reject request: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> fetchHomeRides() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user logged in");
    
    final token = await user.getIdToken();
    
    final response = await http.get(
      Uri.parse(AppConstants.homeRides),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch home rides: ${response.body}");
    }
  }
  Future<Map<String, dynamic>> startRide(String rideId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    final token = await user.getIdToken();
    final response = await http.post(
      Uri.parse("${AppConstants.baseUrl}/rides/$rideId/start"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception("Failed to start ride: ${response.body}");
  }

  Future<Map<String, dynamic>> completeRide(String rideId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    final token = await user.getIdToken();
    final response = await http.post(
      Uri.parse("${AppConstants.baseUrl}/rides/$rideId/complete"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception("Failed to complete ride: ${response.body}");
  }

  Future<Map<String, dynamic>> cancelRide(String rideId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    final token = await user.getIdToken();
    final response = await http.post(
      Uri.parse("${AppConstants.baseUrl}/rides/$rideId/cancel"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception("Failed to cancel ride: ${response.body}");
  }

  Future<Map<String, dynamic>> leaveRide(String rideId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    final token = await user.getIdToken();
    final response = await http.post(
      Uri.parse("${AppConstants.baseUrl}/rides/$rideId/leave"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception("Failed to leave ride: ${response.body}");
  }

  Future<Map<String, dynamic>> removeParticipant(String rideId, String participantId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    final token = await user.getIdToken();
    final response = await http.post(
      Uri.parse("${AppConstants.baseUrl}/rides/$rideId/remove-participant"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"participantId": participantId}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception("Failed to remove participant: ${response.body}");
  }
}


