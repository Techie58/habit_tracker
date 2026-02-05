import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:operation_brotherhood/features/home/presentation/widgets/daily_summary_card.dart';
import 'package:operation_brotherhood/features/home/presentation/widgets/habit_list_view.dart';
import 'package:operation_brotherhood/features/home/presentation/widgets/time_line_widget.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = useState(DateTime.now());
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          shrinkWrap: true,

          // crossAxisAlignment: CrossAxisAlignment.start,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.symmetric(vertical: 20),
              sliver: SliverToBoxAdapter(
                child: TimeLineWidget(
                  selectedDate: selectedDate.value,
                  onDateChange: (date) => selectedDate.value = date,
                ),
              ),
            ),

            SliverPadding(
              padding: EdgeInsetsGeometry.only(
                top: 0,
                left: 20,
                right: 20,
                bottom: 15,
              ),
              sliver: SliverToBoxAdapter(
                child: DailySummaryCard(
                  completedTask: 10,
                  totalTask: 20,
                  date: '06-02-2026',
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsetsGeometry.only(
                top: 0,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              sliver: HabitListView(),
            ),
          ],
        ),
      ),
    );
  }
}
