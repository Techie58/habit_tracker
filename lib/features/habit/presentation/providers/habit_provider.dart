import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_mind/features/habit/data/models/habit_model.dart';
import 'package:iron_mind/core/services/hive_service.dart';
import 'package:uuid/uuid.dart';

final habitProvider = NotifierProvider<HabitNotifier, List<HabitModel>>(
  HabitNotifier.new,
);

class HabitNotifier extends Notifier<List<HabitModel>> {
  @override
  List<HabitModel> build() {
    return HiveService.getHabits();
  }

  Future<void> addHabit({
    required String name,
    required String category,
    required int categoryIcon,
    required String frequency,
    required int targetValue,
    required String targetUnit,
    required DateTime? reminderTime,
    required String priority,
    required String motivationNote,
    required DateTime endDate,
    DateTime? createdAt,
  }) async {
    final newHabit = HabitModel(
      id: const Uuid().v4(),
      name: name,
      category: category,
      categoryIcon: categoryIcon,
      frequency: frequency,
      targetValue: targetValue,
      targetUnit: targetUnit,
      reminderTime: reminderTime,
      priority: priority,
      motivationNote: motivationNote,
      createdAt: createdAt ?? DateTime.now(),
      endDate: endDate,
    );
    await HiveService.saveHabit(newHabit);
    ref.invalidateSelf();
  }

  Future<void> toggleCompletion(String habitId, DateTime date) async {
    await HiveService.toggleHabitCompletion(habitId, date);
    ref.invalidateSelf();
  }

  Future<void> deleteHabit(String id) async {
    await HiveService.deleteHabit(id);
    ref.invalidateSelf();
  }

  Future<void> updateHabit({
    required String id,
    required String name,
    required String category,
    required int categoryIcon,
    required String frequency,
    required int targetValue,
    required String targetUnit,
    required DateTime? reminderTime,
    required String priority,
    required String motivationNote,
    required DateTime endDate,
    required DateTime createdAt,
    required List<DateTime> completedDates,
  }) async {
    final updatedHabit = HabitModel(
      id: id,
      name: name,
      category: category,
      categoryIcon: categoryIcon,
      frequency: frequency,
      targetValue: targetValue,
      targetUnit: targetUnit,
      reminderTime: reminderTime,
      priority: priority,
      motivationNote: motivationNote,
      createdAt: createdAt,
      endDate: endDate,
      completedDates: completedDates,
    );
    await HiveService.updateHabit(updatedHabit);
    ref.invalidateSelf();
  }
}
