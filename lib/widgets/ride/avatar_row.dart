import 'package:flutter/material.dart';

class AvatarRow extends StatelessWidget {
  final List<String?> profilePics;
  final double radius;
  final double overlap;

  const AvatarRow({
    super.key,
    required this.profilePics,
    this.radius = 16,
    this.overlap = 10,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    
    for (int i = 0; i < profilePics.length; i++) {
      final pic = profilePics[i];
      children.add(
        Positioned(
          left: i * (radius * 2 - overlap),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: radius - 1,
              backgroundImage: pic != null 
                ? AssetImage("assets/avatars/$pic") 
                : const AssetImage("assets/avatars/earth.png") as ImageProvider,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: radius * 2,
      width: profilePics.isEmpty ? 0 : (profilePics.length * (radius * 2 - overlap) + overlap),
      child: Stack(
        children: children,
      ),
    );
  }
}
