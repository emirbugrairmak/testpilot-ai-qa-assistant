import "package:flutter/material.dart";

import "../utils/constants.dart";

class PlanBadge extends StatelessWidget {
  const PlanBadge({
    super.key,
    required this.plan,
  });

  final String plan;

  @override
  Widget build(BuildContext context) {
    final isPremium = plan.toLowerCase() == "premium";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPremium
            ? AppColors.accent.withOpacity(0.14)
            : AppColors.sky.withOpacity(0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isPremium ? "PREMIUM" : "FREE",
        style: TextStyle(
          color: isPremium ? AppColors.accent : AppColors.sky,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
