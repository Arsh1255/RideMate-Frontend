import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/colors.dart';
import '../models/ride_model.dart';
import '../models/user_model.dart';

import 'gradient_button.dart';
import 'ride_outline_button.dart';

import 'ride_card_helpers/ride_ui_state.dart';
import 'ride_card_helpers/ride_card_widgets.dart';
import 'ride_card_helpers/ride_card_overlay.dart';

class RideCard extends StatelessWidget {
  final Ride ride;
  final String currentUserId;
  final Map<String, UserModel> users;

  const RideCard({
    super.key,
    required this.ride,
    required this.currentUserId,
    required this.users,
  });

  RideUIState _getUIState() {
    final isOwner = ride.creatorId == currentUserId;
    final isAccepted = ride.participantIds.contains(currentUserId);
    final isPending = ride.pendingRequestIds.contains(currentUserId);

    if (ride.status == 'removed') {
      return RideUIState.memberRideCancelled;
    }

    if (isOwner) {
      if (ride.status == 'ownerStarted') {
        return RideUIState.ownerStarted;
      }

      return RideUIState.ownerActive;
    }

    if (isAccepted) {
      return RideUIState.memberAccepted;
    }

    if (isPending) {
      return RideUIState.memberPending;
    }

    return RideUIState.memberRemoved;
  }

  void _showMoreInfo(
    BuildContext context,
    RideUIState uiState,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RideCardOverlay(
        ride: ride,
        currentUserId: currentUserId,
        users: users,
        uiState: uiState,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uiState = _getUIState();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.borderBlue.withValues(alpha: 0.5),
          width: 0.5,
        ),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),

          const SizedBox(height: 16),

          _buildRouteSection(),

          const SizedBox(height: 16),

          _buildCompactInfoBox(),

          const SizedBox(height: 16),

          if (uiState == RideUIState.memberPending) ...[
            const StatusBanner(
              text: "Confirmation Pending",
              bg: AppColors.pendingBg,
              textColor: AppColors.pendingText,
              icon: LucideIcons.hourglass,
            ),

            const SizedBox(height: 12),

            RideOutlineButton(
              text: "More Info",
              isFullWidth: true,
              onTap: () => _showMoreInfo(context, uiState),
            ),
          ]

          else if (uiState == RideUIState.ownerActive) ...[
            Row(
              children: [
                Expanded(
                  child: GradientButton(
                    text: "Start Ride",
                    onTap: () {},
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: RideOutlineButton(
                    text: "More Info",
                    onTap: () => _showMoreInfo(context, uiState),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            RideOutlineButton(
              text: "Cancel Ride",
              isFullWidth: true,
              onTap: () {},
            ),
          ]

          else if (uiState == RideUIState.ownerStarted) ...[
            GradientButton(
              text: "Ride Ongoing",
              onTap: () {},
            ),

            const SizedBox(height: 12),

            RideOutlineButton(
              text: "End Ride",
              isFullWidth: true,
              onTap: () {},
            ),
          ]

          else if (uiState == RideUIState.memberAccepted) ...[
            GradientButton(
              text: "More Info",
              onTap: () => _showMoreInfo(context, uiState),
            ),

            const SizedBox(height: 12),

            RideOutlineButton(
              text: "Leave Ride",
              isFullWidth: true,
              onTap: () {},
            ),
          ]

          else if (uiState == RideUIState.memberRemoved) ...[
            StatusBanner(
              text: "Sorry, the creator has removed you from ride.",
              bg: AppColors.error.withValues(alpha: 0.1),
              textColor: AppColors.error,
              icon: LucideIcons.circleAlert,
            ),
          ]

          else if (uiState == RideUIState.memberRideCancelled) ...[
            StatusBanner(
              text: ride.creatorId == currentUserId
                  ? "You have cancelled this ride."
                  : "Sorry, the creator has cancelled the ride.",
              bg: AppColors.error.withValues(alpha: 0.1),
              textColor: AppColors.error,
              icon: LucideIcons.circleX,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ride.rideName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              "Ride ID : ${ride.rideId}",
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),

        const Icon(Icons.more_vert),
      ],
    );
  }

  Widget _buildRouteSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 36,
          child: Column(
            children: [
              Image.asset(
                "assets/icons/start.png",
                width: 24,
              ),

              VerticalDashedLine(
                height: 50,
                thickness: 4,
                color: Colors.grey.shade400,
              ),

              Image.asset(
                "assets/icons/stop.png",
                width: 24,
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ride.pickup,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const Text(
                "Pickup",
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 28),

              Text(
                ride.dropoff,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const Text(
                "Drop-off",
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactInfoBox() {
    final formattedTime =
        "${ride.departureTime.hour % 12 == 0 ? 12 : ride.departureTime.hour % 12}:${ride.departureTime.minute.toString().padLeft(2, '0')} ${ride.departureTime.hour >= 12 ? 'PM' : 'AM'}";

    final formattedDate =
        "${ride.departureTime.day}/${ride.departureTime.month}/${ride.departureTime.year}";

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(LucideIcons.clock, size: 16),

              const SizedBox(width: 6),

              Text(
                "$formattedDate • $formattedTime",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const Spacer(),

              const Icon(LucideIcons.users, size: 16),

              const SizedBox(width: 6),

              Text(
                "${ride.availableSeats} Seats",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const Divider(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  "Mode: ${RideCardLogic.formatMode(ride.mode)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "₹${ride.pricePerPerson.toInt()}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const Text(
                    "per person",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 6),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Vehicle: ${RideCardLogic.getVehicleName(ride.vehicleType)}",
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}