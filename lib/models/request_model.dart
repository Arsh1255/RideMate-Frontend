class RequestModel {
  final String id;
  final String rideId;
  final String uid;
  final String userName;
  final String? profilePic; // Added: For the creator to verify the requester
  final String status; // Pending, Accepted, Rejected

  RequestModel({
    required this.id,
    required this.rideId,
    required this.uid,
    required this.userName,
    this.profilePic,
    required this.status,
  });
}