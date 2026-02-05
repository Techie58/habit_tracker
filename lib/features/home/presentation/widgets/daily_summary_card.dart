import 'package:flutter/material.dart';
import 'package:operation_brotherhood/core/utils/colors.dart';

class DailySummaryCard extends StatelessWidget {
  final int completedTask, totalTask;
  final String date;

  const DailySummaryCard({
    super.key,
    required this.completedTask,
    required this.totalTask,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final efficiencPersentage = (completedTask/totalTask) * 100;
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground, // Dark forest green background
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "TODAY'S PLAN",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.selectedBorder),
                ),
                child: const Text(
                  "IN PROGRESS",
                  style: TextStyle(
                    color: AppColors.glowingGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Efficiency Percentage
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "$efficiencPersentage%",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "Efficiency",
                style: TextStyle(color: AppColors.textColorGrey, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: completedTask / totalTask,
              minHeight: 12,
              backgroundColor: AppColors.cardBgUpColor,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.glowingGreen),
            ),
          ),
          const SizedBox(height: 30),

          // Footer Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                icon: Icons.check_outlined,
                iconColor: AppColors.glowingGreen,
                value: '$completedTask / $totalTask',
                label: "COMPLETED",
              ),
              _buildStatItem(
                icon: Icons.hourglass_empty,
                iconColor:AppColors.glowingGreen,
                value: '${totalTask- completedTask} ',
                label: "REMAINING",
              ),
            ],
          ),
        ],
      ),
    );

  }

  // Helper widget for the bottom items
  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: iconColor.withValues(alpha: 0.1),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 10,fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

}
