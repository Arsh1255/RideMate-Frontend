class UserModel {
  final String uid;
  final String email;
  final String name;
  final int ecoScore;
  final double co2Saved;
  final int ridesTaken;
  final int peopleSharedWith;
  final String? profilePic;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.profilePic,
    this.ecoScore = 0,
    this.co2Saved = 0.0,
    this.ridesTaken = 0,
    this.peopleSharedWith = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      email: json['email'],
      name: json['name'],
      profilePic: json['profilePic'],
      ecoScore: json['ecoScore'] ?? 0,
      co2Saved: (json['co2Saved'] ?? 0).toDouble(),
      ridesTaken: json['ridesTaken'] ?? 0,
      peopleSharedWith: json['peopleSharedWith'] ?? 0,
    );
  }
}