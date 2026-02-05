import 'package:flutter/material.dart';
import 'package:operation_brotherhood/core/utils/colors.dart';

class HabitCard extends StatelessWidget {
  final bool isCompleted;
  final ValueChanged<bool?>? onCompleteTap;
  final String title, subTitle;
  final IconData icon;

  const HabitCard({
    super.key,
    required this.isCompleted,
    this.onCompleteTap,
    required this.title,
    required this.subTitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border.all(
          color: isCompleted ? AppColors.selectedBorder : AppColors.border,
        ),
        borderRadius: BorderRadiusGeometry.circular(18),
      ),
      child: ListTile(
        leading: Transform.scale(
          scale: 1.2,
          child: Checkbox(
            value: isCompleted,
            onChanged: onCompleteTap,
            shape: CircleBorder(
              side: BorderSide(
                color: AppColors.selectedBorder ,
              ),
            ),
            fillColor: isCompleted
                ? WidgetStatePropertyAll(AppColors.selectedBorder)
                : null,
          ),
        ),
        title: Text(title),
        subtitle: Text(subTitle),
        trailing: Icon(icon),
      ),
    );
  }
}
