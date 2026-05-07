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
}
