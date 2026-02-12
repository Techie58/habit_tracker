import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:iron_mind/core/utils/colors.dart';
import 'package:iron_mind/features/habit/data/models/habit_model.dart';
import 'package:iron_mind/features/habit/presentation/providers/habit_provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class HabitDetailScreen extends HookConsumerWidget {
  final HabitModel habit;

  const HabitDetailScreen({super.key, required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allHabits = ref.watch(habitProvider);
    final freshHabit = allHabits.firstWhere(
      (h) => h.id == habit.id,
      orElse: () => habit,
    );
    final colors = Theme.of(context).appColors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          freshHabit.name.toUpperCase(),
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildOverviewCard(freshHabit, colors),
              const SizedBox(height: 20),
              _HabitCalendar(habit: freshHabit, colors: colors, ref: ref),
              const SizedBox(height: 20),
              _buildCompletionChart(freshHabit, colors),
              const SizedBox(height: 20),
              _buildHabitInfo(freshHabit, colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(HabitModel habit, AppColorScheme colors) {
    Color priorityColor;
    switch (habit.priority) {
      case 'HIGH':
        priorityColor = AppColors.highPriorityColor;
        break;
      case 'MEDIUM':
        priorityColor = AppColors.mediumPriorityColor;
        break;
      default:
        priorityColor = AppColors.lowPriorityColor;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoColumn(
                'CURRENT\nSTREAK',
                '${habit.currentStreak} Days',
                colors,
              ),
              _infoColumn(
                'LONGEST\nSTREAK',
                '${habit.longestStreak} Days',
                colors,
              ),
              _infoColumn('REMAINING', '${habit.daysRemaining} Days', colors),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  border: Border.all(color: priorityColor.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  habit.priority,
                  style: TextStyle(
                    color: priorityColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.chipBg,
                  border: Border.all(color: colors.chipBorder),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      IconData(habit.categoryIcon, fontFamily: 'MaterialIcons'),
                      color: colors.textSecondary,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      habit.category,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                habit.frequency,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: habit.progress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: colors.progressBarBg,
              valueColor: AlwaysStoppedAnimation(colors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(habit.progress * 100).toInt().clamp(0, 100)}% COMPLETED',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoColumn(String label, String value, AppColorScheme colors) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionChart(HabitModel habit, AppColorScheme colors) {
    // Build last 4 weeks data
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<_ChartData> data = [];

    for (int i = 3; i >= 0; i--) {
      final weekStart = today.subtract(
        Duration(days: today.weekday - 1 + (i * 7)),
      );
      int completedInWeek = 0;
      int totalInWeek = 0;

      for (int d = 0; d < 7; d++) {
        final date = weekStart.add(Duration(days: d));
        if (date.isAfter(today)) continue;

        final startDate = DateTime(
          habit.createdAt.year,
          habit.createdAt.month,
          habit.createdAt.day,
        );
        final endDate = DateTime(
          habit.endDate.year,
          habit.endDate.month,
          habit.endDate.day,
        );

        if ((date.isAtSameMomentAs(startDate) || date.isAfter(startDate)) &&
            (date.isAtSameMomentAs(endDate) || date.isBefore(endDate))) {
          totalInWeek++;
          if (habit.isCompletedOn(date)) completedInWeek++;
        }
      }

      final weekLabel = 'W${4 - i}';
      data.add(_ChartData(weekLabel, completedInWeek, totalInWeek));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WEEKLY COMPLETION',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              primaryXAxis: CategoryAxis(
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: AxisLine(color: colors.border),
                labelStyle: TextStyle(
                  color: colors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              primaryYAxis: NumericAxis(
                majorGridLines: MajorGridLines(
                  color: colors.border.withOpacity(0.3),
                  dashArray: const [4, 4],
                ),
                axisLine: const AxisLine(width: 0),
                labelStyle: TextStyle(color: colors.textMuted, fontSize: 10),
              ),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: <CartesianSeries<_ChartData, String>>[
                ColumnSeries<_ChartData, String>(
                  dataSource: data,
                  xValueMapper: (_ChartData d, _) => d.week,
                  yValueMapper: (_ChartData d, _) => d.completed,
                  name: 'Completed',
                  color: colors.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                  width: 0.5,
                ),
                ColumnSeries<_ChartData, String>(
                  dataSource: data,
                  xValueMapper: (_ChartData d, _) => d.week,
                  yValueMapper: (_ChartData d, _) => d.total,
                  name: 'Total',
                  color: colors.progressBarBg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                  width: 0.5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitInfo(HabitModel habit, AppColorScheme colors) {
    if (habit.motivationNote.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MOTIVATION',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.rocket_launch, color: colors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  habit.motivationNote,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pageable monthly calendar widget for habit tracking
class _HabitCalendar extends StatefulWidget {
  final HabitModel habit;
  final AppColorScheme colors;
  final WidgetRef ref;

  const _HabitCalendar({
    required this.habit,
    required this.colors,
    required this.ref,
  });

  @override
  State<_HabitCalendar> createState() => _HabitCalendarState();
}

class _HabitCalendarState extends State<_HabitCalendar> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
        1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final habit = widget.habit;

    final daysInMonth = DateUtils.getDaysInMonth(
      _displayedMonth.year,
      _displayedMonth.month,
    );
    final firstWeekday = _displayedMonth.weekday; // 1=Mon, 7=Sun
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'HABIT LOG',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Row(
                children: [
                  _navButton(Icons.chevron_left, _previousMonth, colors),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      DateFormat(
                        'MMM yyyy',
                      ).format(_displayedMonth).toUpperCase(),
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  _navButton(Icons.chevron_right, _nextMonth, colors),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Day-of-week headers
          Row(
            children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          // Calendar grid
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1.0,
            ),
            itemCount: daysInMonth + firstWeekday - 1,
            itemBuilder: (context, index) {
              if (index < firstWeekday - 1) {
                return const SizedBox();
              }
              final day = index - (firstWeekday - 1) + 1;
              final date = DateTime(
                _displayedMonth.year,
                _displayedMonth.month,
                day,
              );
              final isCompleted = habit.isCompletedOn(date);
              final isToday =
                  date.year == todayDate.year &&
                  date.month == todayDate.month &&
                  date.day == todayDate.day;
              final isPast = date.isBefore(todayDate) && !isToday;
              final isFuture = date.isAfter(todayDate) && !isToday;

              Color bgColor = colors.chipBg;
              Color textColor = colors.textMuted;
              Border? border;

              if (isCompleted) {
                bgColor = colors.primary;
                textColor = Colors.white;
              } else if (isPast && !isCompleted) {
                bgColor = AppColors.highPriorityColor.withOpacity(0.15);
                textColor = AppColors.highPriorityColor.withOpacity(0.7);
              } else if (isToday) {
                border = Border.all(color: colors.primary, width: 1.5);
                textColor = colors.textPrimary;
              } else if (isFuture) {
                bgColor = colors.chipBg.withOpacity(0.5);
                textColor = colors.textMuted.withOpacity(0.4);
              }

              // Check if date is within habit range
              final habitStart = DateTime(
                habit.createdAt.year,
                habit.createdAt.month,
                habit.createdAt.day,
              );
              final habitEnd = DateTime(
                habit.endDate.year,
                habit.endDate.month,
                habit.endDate.day,
              );
              final inRange =
                  (date.isAtSameMomentAs(habitStart) ||
                      date.isAfter(habitStart)) &&
                  (date.isAtSameMomentAs(habitEnd) || date.isBefore(habitEnd));

              if (!inRange) {
                bgColor = colors.chipBg.withOpacity(0.3);
                textColor = colors.textMuted.withOpacity(0.3);
              }

              return InkWell(
                onTap: (isFuture || !inRange)
                    ? null
                    : () {
                        widget.ref
                            .read(habitProvider.notifier)
                            .toggleCompletion(habit.id, date);
                      },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: border,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap, AppColorScheme colors) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colors.chipBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: colors.textSecondary, size: 18),
      ),
    );
  }
}

class _ChartData {
  final String week;
  final int completed;
  final int total;

  _ChartData(this.week, this.completed, this.total);
}
