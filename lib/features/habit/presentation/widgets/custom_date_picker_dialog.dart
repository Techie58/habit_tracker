import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iron_mind/core/utils/colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM DATE SLIDER DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class CustomDatePickerDialog extends HookWidget {
  final DateTime initialDate;
  final String title;
  final Function(DateTime) onSelected;

  const CustomDatePickerDialog({
    super.key,
    required this.initialDate,
    required this.title,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final tempDate = useState(initialDate);
    final scrollController = useFixedExtentScrollController(
      initialItem: tempDate.value.difference(DateTime(2000)).inDays,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primary.withValues(alpha: 0.15),
                      colors.surface.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: colors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),

              // Date Slider Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Selection Indicator (Glass effect)
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colors.primary.withValues(alpha: 0.1),
                            colors.primary.withValues(alpha: 0.05),
                            colors.primary.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.symmetric(
                          horizontal: BorderSide(
                            color: colors.primary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                      ),
                    ),

                    // The Slider
                    SizedBox(
                      height: 220,
                      child: ShaderMask(
                        shaderCallback: (rect) {
                          return LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              colors.surface,
                              Colors.transparent,
                              Colors.transparent,
                              colors.surface,
                            ],
                            stops: const [0.0, 0.15, 0.85, 1.0],
                          ).createShader(rect);
                        },
                        blendMode: BlendMode.dstOut,
                        child: ListWheelScrollView.useDelegate(
                          controller: scrollController,
                          itemExtent: 60,
                          physics: const FixedExtentScrollPhysics(),
                          perspective: 0.005,
                          diameterRatio: 1.5,
                          onSelectedItemChanged: (index) {
                            tempDate.value = DateTime(
                              2000,
                            ).add(Duration(days: index));
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              final date = DateTime(
                                2000,
                              ).add(Duration(days: index));
                              final isSelected =
                                  date.year == tempDate.value.year &&
                                  date.month == tempDate.value.month &&
                                  date.day == tempDate.value.day;

                              return AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  color: isSelected
                                      ? colors.primary
                                      : colors.textMuted.withValues(alpha: 0.4),
                                  fontSize: isSelected ? 24 : 18,
                                  fontWeight: isSelected
                                      ? FontWeight.w900
                                      : FontWeight.w500,
                                ),
                                child: Center(
                                  child: Text(
                                    "${date.day} ${_getMonthName(date.month)} ${date.year}",
                                  ),
                                ),
                              );
                            },
                            childCount: 36500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'CANCEL',
                          style: TextStyle(
                            color: colors.textMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            onSelected(tempDate.value);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'CONFIRM DATE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
