import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:flutter/material.dart';
import 'package:operation_brotherhood/core/utils/colors.dart';

class TimeLineWidget extends StatelessWidget {
  final DateTime selectedDate;
  final void Function(DateTime) onDateChange;

  const TimeLineWidget({
    super.key,
    required this.onDateChange,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // This week's Monday (start of week)
    final startWeek = now.subtract(Duration(days: now.weekday - 1));

    // This week's Sunday (end of week) - ADD days, not subtract!
    final endWeek = now.add(Duration(days: 7 - now.weekday));

    return EasyTheme(
      data: EasyTheme.of(context).copyWithState(
        unselectedDayTheme: const DayThemeData(
          foregroundColor: AppColors.textPrimaryWhite,
          border: BorderSide(color: AppColors.border,),

          backgroundColor: AppColors.cardBackground,
        ),
        selectedDayTheme: const DayThemeData(
          foregroundColor: AppColors.primary,
          border: BorderSide(color: AppColors.border),
          backgroundColor: AppColors.glowingGreen,
        ),
        unselectedCurrentDayTheme: const DayThemeData(
          foregroundColor: AppColors.textPrimaryWhite,
          border: BorderSide(color: AppColors.selectedBorder),
          backgroundColor: AppColors.cardBackground,
        ),
      ),
      child: EasyDateTimeLinePicker(
        firstDate: startWeek,  // Monday first
        lastDate: endWeek,     // Sunday last
        focusedDate: selectedDate,
        onDateChange: onDateChange,
        headerOptions: HeaderOptions(
          headerBuilder: (context, date, onTap){
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  // padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black .withValues(alpha: 0.2)
                  ),
                    child: IconButton(onPressed: (){}, icon: Icon(Icons.arrow_back_ios_new_outlined),)),
                IconButton(onPressed: (){}, icon: Icon(Icons.arrow_forward_ios))
              ],
            );
          }
        ),



      ),
    );
  }
}