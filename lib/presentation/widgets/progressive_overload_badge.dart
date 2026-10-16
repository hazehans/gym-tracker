import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ProgressiveOverloadBadge extends StatelessWidget {
  final double incrementKg;
  final VoidCallback? onTapApply;

  const ProgressiveOverloadBadge({
    super.key,
    this.incrementKg = 2.5,
    this.onTapApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryNeon.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryNeon, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.trending_up_rounded,
            color: AppColors.primaryNeon,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            '+$incrementKg kg Progressive Overload!',
            style: const TextStyle(
              color: AppColors.primaryNeon,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          if (onTapApply != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onTapApply,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryNeon,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'APPLY',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

