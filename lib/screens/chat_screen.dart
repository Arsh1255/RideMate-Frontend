import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/colors.dart';

class ChatScreen extends StatefulWidget {
  final String rideId;
  const ChatScreen({super.key, required this.rideId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [
    {
      "text": "Hey everyone! 👋\nI'll be at the pickup point in 5 mins.",
      "isMe": false,
      "time": "05:25 PM",
      "name": "Rahul Sharma",
    },
    {"text": "Okay, I'm on my way too!", "isMe": true, "time": "05:26 PM"},
    {
      "text": "Please share your live location when you reach.",
      "isMe": false,
      "time": "05:27 PM",
      "name": "Priya Nair",
    },
    {"type": "location", "isMe": true, "time": "05:28 PM"},
    {
      "text": "Reached the pickup point. See you all in a bit!",
      "isMe": false,
      "time": "05:29 PM",
      "name": "Arjun Mehta",
    },
  ];

  void sendMessage() {
    if (controller.text.trim().isEmpty) return;

    setState(() {
      messages.add({
        "text": controller.text.trim(),
        "isMe": true,
        "time": "Now",
      });
    });

    controller.clear();

    // 🔥 THIS IS THE IMPORTANT PART
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // 🔹 HEADER
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Row(
          children: [
            SizedBox(
              width: 40,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.grey.shade300,
                  ),
                  Positioned(
                    left: 14,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // 🔥 THIS PART FIXES IT
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Morning Office Ride",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),

                Text(
                  "Ride ID: ${widget.rideId}",
                  style: const TextStyle(
                    color: AppColors.infoText,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];

                if (msg["type"] == "location") {
                  return _locationBubble(msg);
                }

                return _chatBubble(msg);
              },
            ),
          ),

          _inputBar(),
        ],
      ),
    );
  }

  // ================= CHAT BUBBLE =================
  Widget _chatBubble(Map<String, dynamic> msg) {
    final isMe = msg["isMe"];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isMe) _avatar(),

        if (!isMe) const SizedBox(width: 8),

        Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                msg["name"] ?? "",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),

            Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(maxWidth: 260),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.primaryGreen.withOpacity(0.2)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  if (!isMe)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(msg["text"]),
                  const SizedBox(height: 4),
                  Text(
                    msg["time"],
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================= LOCATION BUBBLE =================
  Widget _locationBubble(Map<String, dynamic> msg) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        width: 260,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryBlue.withOpacity(0.2),
              AppColors.primaryGreen.withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey.shade300,
              ),
              child: const Center(child: Icon(LucideIcons.mapPin, size: 32)),
            ),
            const SizedBox(height: 8),
            const Text(
              "Live Location",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
            const Text("Basavanagudi, Bangalore"),
            const Text(
              "Tap to view on map",
              style: TextStyle(fontSize: 12, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 4),
            Text(
              msg["time"],
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= INPUT BAR =================
  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.add), onPressed: () {}),

          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.border.withOpacity(0.3),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: "Type a message...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),

          IconButton(
            icon: const Icon(LucideIcons.mapPin, color: AppColors.primaryGreen),
            onPressed: () {},
          ),

          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.primaryGreen],
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar() {
    return const CircleAvatar(radius: 16, backgroundColor: Colors.grey);
  }
}
