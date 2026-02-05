import 'package:flutter/material.dart';
import 'package:operation_brotherhood/features/home/presentation/widgets/habit_card.dart';

class HabitListView extends StatelessWidget {
  const HabitListView({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverList(delegate: SliverChildBuilderDelegate( (BuildContext context, int index) {
      return HabitCard(
        isCompleted: index % 2 == 0 ? true : false,
        title: titles[index],
        subTitle: 'This is sub titles',
        icon: icons[index],
      );;
    },
      childCount: 10,));

  }
}

final titles = [
  'DSA Practice',
  'Freelancing',
  'Read Book',
  'Gym',
  'DSA Practice',
  'Read Book',
  'Gym',
  'DSA Practice',
  'Read Book',
  'Gym',
];
final icons = [
  Icons.terminal,
  Icons.menu_book_rounded,
  Icons.fitness_center,
  Icons.terminal,
  Icons.menu_book_rounded,
  Icons.fitness_center,
  Icons.terminal,
  Icons.menu_book_rounded,
  Icons.fitness_center,
  Icons.money,
];
