import 'package:flutter/cupertino.dart';

import '../core/app_theme.dart';
import '../core/user_info.dart';

/// Round avatar with the user's initials on the orange gradient.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, this.size = 44});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.orangeGradient,
      ),
      child: Text(
        initialsOf(name),
        style: TextStyle(
          color: CupertinoColors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}
