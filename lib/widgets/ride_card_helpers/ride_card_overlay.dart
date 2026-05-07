import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/colors.dart';
import '../../models/ride_model.dart';
import '../../models/user_model.dart';
import 'ride_ui_state.dart';
import 'ride_card_widgets.dart';
import '../gradient_button.dart';
import '../ride_outline_button.dart';
import '../../widgets/icons_gradient_button.dart';

class RideCardOverlay extends StatelessWidget {
  final Ride ride;
  final String currentUserId;
  final Map<String, UserModel> users;
  final RideUIState uiState;

  const RideCardOverlay({
    super.key,
    required this.ride,
    required this.currentUserId,
    required this.users,
    required this.uiState,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: ListView(
          controller: controller,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildFullHeader(),
            const SizedBox(height: 24),
            const Text(
              "Participants",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildParticipantList(context),
            const SizedBox(height: 24),
            _buildOverlayActions(),
            if (ride.creatorId == currentUserId &&
                ride.pendingRequestIds.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                "Requests",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildRequestList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFullHeader() {
    final showChat =
        (uiState == RideUIState.memberAccepted ||
        uiState == RideUIState.ownerActive ||
        uiState == RideUIState.ownerStarted);
    return Row(
      children: [
        Expanded(
          child: Text(
            ride.rideName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (showChat)
          IconGradientButton(
            text: "Chat",
            icon: LucideIcons.messageSquare,
            onTap: () {},
            height: 36,
          ),
      ],
    );
  }



  Widget _buildParticipantList(BuildContext context) {
    final allParticipants = {ride.creatorId, ...ride.participantIds};

    final otherParticipants = allParticipants
        .where((id) => id != currentUserId)
        .toList();

    final participants = [currentUserId, ...otherParticipants];

    final isViewerTheOwner = ride.creatorId == currentUserId;

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: participants.length,
        itemBuilder: (context, index) {
          final uid = participants[index];
          final user = users[uid];

          if (user == null) return const SizedBox();

          final isMe = uid == currentUserId;
          final isCreator = uid == ride.creatorId;

          String displayName;

          if (isMe) {
            displayName = isCreator ? "You (Creator)" : "You";
          } else {
            displayName = isCreator ? "${user.name} (Creator)" : user.name;
          }

          return GestureDetector(
            onTap: () => _showParticipantOptions(
              context,
              user,
              isViewerTheOwner,
              isCreator,
            ),
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundImage:
                        (user.profilePic != null &&
                            user.profilePic!.startsWith('http'))
                        ? NetworkImage(user.profilePic!) as ImageProvider
                        : AssetImage(user.profilePic ?? "assets/profile.jpg"),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 70,
                    child: Text(
                      displayName,
                      style: const TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showParticipantOptions(
    BuildContext context,
    UserModel user,
    bool isOwner,
    bool isTargetCreator,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage:
                      (user.profilePic != null &&
                          user.profilePic!.startsWith('http'))
                      ? NetworkImage(user.profilePic!) as ImageProvider
                      : AssetImage(user.profilePic ?? "assets/profile.jpg"),
                ),

                const SizedBox(width: 16),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Text(
                      "Eco Score: ${user.ecoScore} 🌱",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),

            ListTile(
              leading: const Icon(LucideIcons.user),
              title: const Text("View Full Profile"),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            if (isOwner && !isTargetCreator)
              ListTile(
                leading: const Icon(
                  LucideIcons.userMinus,
                  color: AppColors.error,
                ),
                title: const Text(
                  "Remove Participant",
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestList() {
    return Column(
      children: ride.pendingRequestIds.map((uid) {
        final user = users[uid];
        if (user == null) return const SizedBox();
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundImage:
                    (user.profilePic != null &&
                        user.profilePic!.startsWith('http'))
                    ? NetworkImage(user.profilePic!) as ImageProvider
                    : AssetImage(user.profilePic ?? "assets/profile.jpg"),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  user.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, color: Colors.red),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(LucideIcons.check, color: Colors.green),
                onPressed: () {},
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOverlayActions() {
    if (uiState == RideUIState.memberPending)
      return const StatusBanner(
        text: "Confirmation Pending",
        bg: AppColors.pendingBg,
        textColor: AppColors.pendingText,
        icon: LucideIcons.hourglass,
      );
    if (uiState == RideUIState.memberRemoved)
      return StatusBanner(
        text: "You were removed from the ride",
        bg: AppColors.error.withValues(alpha: 0.1),
        textColor: AppColors.error,
        icon: LucideIcons.circleAlert,
      );
    return Column(
      children: [
        if (uiState == RideUIState.ownerActive)
          GradientButton(text: "Start Ride", onTap: () {}),
        if (uiState == RideUIState.ownerStarted)
          GradientButton(text: "End Ride", onTap: () {}),
        const SizedBox(height: 12),
        RideOutlineButton(
          text:
              (uiState == RideUIState.ownerActive ||
                  uiState == RideUIState.ownerStarted)
              ? "Cancel Ride"
              : "Leave Ride",
          isFullWidth: true,
          onTap: () {},
        ),
      ],
    );
  }
}
