import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:iron_mind/core/utils/colors.dart';
import 'package:iron_mind/core/utils/responsive.dart';
import 'package:iron_mind/features/habit/presentation/providers/habit_provider.dart';
import 'package:iron_mind/features/habit/data/models/habit_model.dart';
import 'package:iron_mind/features/habit/presentation/widgets/custom_date_picker_dialog.dart';

class CreateHabitScreen extends HookConsumerWidget {
  final HabitModel? habitToEdit;

  const CreateHabitScreen({super.key, this.habitToEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final noteController = useTextEditingController();
    final selectedCategory = useState('Fitness');
    final selectedIcon = useState(0xe24a); // Icons.fitness_center
    final selectedFrequency = useState('DAILY');
    final targetValue = useState(1);
    final targetUnit = useState('TIMES');
    final startDate = useState(DateTime.now());
    final endDate = useState(DateTime.now().add(const Duration(days: 30)));
    final priority = useState('MEDIUM');
    final customDays = useState<List<int>>([]); // 1-7 for Mon-Sun
    final colors = Theme.of(context).appColors;

    final categories = useState([
      {'name': 'Fitness', 'icon': Icons.fitness_center},
      {'name': 'Study', 'icon': Icons.menu_book},
      {'name': 'Discipline', 'icon': Icons.verified_user},
      {'name': 'Sleep', 'icon': Icons.nights_stay},
    ]);

    void showCustomCategoryDialog() {
      showDialog(
        context: context,
        builder: (context) => _CustomCategoryDialog(
          onAdded: (name, icon) {
            categories.value = [
              ...categories.value,
              {'name': name, 'icon': icon},
            ];
            selectedCategory.value = name;
            selectedIcon.value = icon.codePoint;
          },
        ),
      );
    }

    useEffect(() {
      if (habitToEdit != null) {
        nameController.text = habitToEdit!.name;
        selectedCategory.value = habitToEdit!.category;
        selectedIcon.value = habitToEdit!.categoryIcon;
        selectedFrequency.value = habitToEdit!.frequency;
        targetValue.value = habitToEdit!.targetValue;
        targetUnit.value = habitToEdit!.targetUnit;
        endDate.value = habitToEdit!.endDate;
        priority.value = habitToEdit!.priority;
        noteController.text = habitToEdit!.motivationNote;
        startDate.value = habitToEdit!.createdAt;
        if (habitToEdit!.frequency.startsWith('CUSTOM:')) {
          selectedFrequency.value = 'CUSTOM';
          final daysStr = habitToEdit!.frequency.split(':')[1];
          customDays.value = daysStr.split(',').map(int.parse).toList();
        }
      }
      return null;
    }, []);

    String _formatFrequency() {
      if (selectedFrequency.value == 'CUSTOM') {
        return 'CUSTOM:${customDays.value.join(',')}';
      }
      return selectedFrequency.value;
    }

    void handleInternalSubmit() {
      if (nameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a habit name')),
        );
        return;
      }

      final frequencyStr = _formatFrequency();

      if (habitToEdit != null) {
        ref
            .read(habitProvider.notifier)
            .updateHabit(
              id: habitToEdit!.id,
              name: nameController.text,
              category: selectedCategory.value,
              categoryIcon: selectedIcon.value,
              frequency: frequencyStr,
              targetValue: targetValue.value,
              targetUnit: targetUnit.value,
              reminderTime: null,
              priority: priority.value,
              motivationNote: noteController.text,
              endDate: endDate.value,
              createdAt: startDate.value,
              completedDates: habitToEdit!.completedDates,
            );
      } else {
        ref
            .read(habitProvider.notifier)
            .addHabit(
              name: nameController.text,
              category: selectedCategory.value,
              categoryIcon: selectedIcon.value,
              frequency: frequencyStr,
              targetValue: targetValue.value,
              targetUnit: targetUnit.value,
              reminderTime: null,
              priority: priority.value,
              motivationNote: noteController.text,
              endDate: endDate.value,
              createdAt: startDate.value,
            );
      }

      Navigator.pop(context);
    }

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          habitToEdit != null ? 'Edit Habit' : 'Create New Habit',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _sectionHeader('HABIT IDENTITY', colors),
              _customTextField(
                controller: nameController,
                hintText: 'e.g. Morning Meditation',
                label: 'Habit Name',
                maxLength: 30,
                colors: colors,
              ),

              SizedBox(height: context.h(3)),

              _sectionHeader('FREQUENCY', colors),
              _frequencyToggle(
                context,
                selectedFrequency.value,
                (val) => selectedFrequency.value = val,
                colors,
              ),

              if (selectedFrequency.value == 'CUSTOM') ...[
                const SizedBox(height: 15),
                _customDaysSelector(
                  customDays.value,
                  (days) => customDays.value = days,
                  colors,
                ),
              ],

              SizedBox(height: context.h(3)),

              _sectionHeader('CATEGORY', colors),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...categories.value.map(
                      (cat) => _categoryChip(
                        context,
                        cat['name'] as String,
                        cat['icon'] as IconData,
                        selectedCategory.value == cat['name'],
                        () {
                          selectedCategory.value = cat['name'] as String;
                          selectedIcon.value =
                              (cat['icon'] as IconData).codePoint;
                        },
                        colors,
                      ),
                    ),
                    _categoryChip(
                      context,
                      'Custom',
                      Icons.add,
                      false,
                      showCustomCategoryDialog,
                      colors,
                    ),
                  ],
                ),
              ),

              _sectionHeader('HABIT DURATION', colors),
              Row(
                children: [
                  Expanded(
                    child: _dateButton(
                      context,
                      'Start Date',
                      startDate.value,
                      (date) => startDate.value = date,
                      colors,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _dateButton(
                      context,
                      'End Date',
                      endDate.value,
                      (date) => endDate.value = date,
                      colors,
                    ),
                  ),
                ],
              ),

              SizedBox(height: context.h(3)),

              _sectionHeader('PRIORITY LEVEL', colors),
              _prioritySelector(
                context,
                priority.value,
                (val) => priority.value = val,
                colors,
              ),

              SizedBox(height: context.h(3)),

              _sectionHeader('MOTIVATION NOTE', colors),
              _motivationField(noteController, colors),

              SizedBox(height: context.h(4)),

              SizedBox(height: context.h(4)),

              _createHabitButton(context, handleInternalSubmit, colors),

              SizedBox(height: context.h(5)),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // UI HELPER WIDGETS
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _sectionHeader(String title, AppColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          color: colors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _customTextField({
    required TextEditingController controller,
    required String hintText,
    required String label,
    required int maxLength,
    required AppColorScheme colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              Text(
                '0/$maxLength',
                style: TextStyle(color: colors.textMuted, fontSize: 10),
              ),
            ],
          ),
          TextField(
            controller: controller,
            style: TextStyle(color: colors.textPrimary, fontSize: 18),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: colors.textMuted.withOpacity(0.4),
                fontSize: 18,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.only(top: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(
    BuildContext context,
    String name,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
    AppColorScheme colors,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : colors.border.withOpacity(0.3),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.primary.withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : colors.textMuted,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? Colors.white : colors.textMuted,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _frequencyToggle(
    BuildContext context,
    String selected,
    Function(String) onSelect,
    AppColorScheme colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: ['DAILY', 'WEEKLY', 'CUSTOM'].map((freq) {
          bool isSel = selected == freq;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(freq),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSel ? colors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child: Text(
                  freq,
                  style: TextStyle(
                    color: isSel ? Colors.white : colors.textMuted,
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _dateButton(
    BuildContext context,
    String label,
    DateTime selectedDate,
    Function(DateTime) onDateChange,
    AppColorScheme colors,
  ) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => CustomDatePickerDialog(
            initialDate: selectedDate,
            title: 'SELECT ${label.toUpperCase()}',
            onSelected: onDateChange,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: colors.textMuted, fontSize: 10),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${selectedDate.day} ${_getMonth(selectedDate.month)} ${selectedDate.year}",
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Icon(Icons.calendar_today, color: colors.primary, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _customDaysSelector(
    List<int> selectedDays,
    Function(List<int>) onChange,
    AppColorScheme colors,
  ) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final dayNum = index + 1;
        final isSelected = selectedDays.contains(dayNum);
        return GestureDetector(
          onTap: () {
            final newList = List<int>.from(selectedDays);
            if (isSelected) {
              newList.remove(dayNum);
            } else {
              newList.add(dayNum);
            }
            onChange(newList);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? colors.primary : colors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : colors.border.withOpacity(0.3),
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: colors.primary.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
            alignment: Alignment.center,
            child: Text(
              days[index],
              style: TextStyle(
                color: isSelected ? Colors.white : colors.textMuted,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        );
      }),
    );
  }

  String _getMonth(int month) {
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

  Widget _prioritySelector(
    BuildContext context,
    String selected,
    Function(String) onSelect,
    AppColorScheme colors,
  ) {
    return Row(
      children: [
        Expanded(
          child: _priorityChip(
            'LOW',
            AppColors.lowPriorityColor,
            selected == 'LOW',
            () => onSelect('LOW'),
            colors,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _priorityChip(
            'MEDIUM',
            AppColors.mediumPriorityColor,
            selected == 'MEDIUM',
            () => onSelect('MEDIUM'),
            colors,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _priorityChip(
            'HIGH',
            AppColors.highPriorityColor,
            selected == 'HIGH',
            () => onSelect('HIGH'),
            colors,
          ),
        ),
      ],
    );
  }

  Widget _priorityChip(
    String label,
    Color color,
    bool isSelected,
    VoidCallback onTap,
    AppColorScheme colors,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? color : colors.border.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 3,
              width: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : colors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _motivationField(
    TextEditingController controller,
    AppColorScheme colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border.withOpacity(0.3)),
      ),
      child: TextField(
        controller: controller,
        maxLines: 4,
        style: TextStyle(color: colors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: "Define your 'Why'... Success is the only option.",
          hintStyle: TextStyle(
            color: colors.textMuted.withOpacity(0.4),
            fontSize: 14,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _createHabitButton(
    BuildContext context,
    VoidCallback onTap,
    AppColorScheme colors,
  ) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.rocket_launch, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(
              habitToEdit != null ? 'UPDATE HABIT' : 'CREATE HABIT',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM CATEGORY DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class _CustomCategoryDialog extends HookWidget {
  final Function(String, IconData) onAdded;

  const _CustomCategoryDialog({required this.onAdded});

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController();
    final selectedIcon = useState(Icons.category);
    final colors = Theme.of(context).appColors;

    final icons = [
      Icons.star,
      Icons.favorite,
      Icons.work,
      Icons.school,
      Icons.fitness_center,
      Icons.sports_basketball,
      Icons.music_note,
      Icons.brush,
      Icons.code,
      Icons.camera_alt,
      Icons.shopping_cart,
      Icons.restaurant,
      Icons.local_cafe,
      Icons.directions_run,
      Icons.directions_bike,
      Icons.flight,
      Icons.home,
      Icons.pets,
      Icons.book,
      Icons.event,
      Icons.access_time,
      Icons.lightbulb,
      Icons.money,
      Icons.account_balance,
      Icons.smartphone,
      Icons.tv,
      Icons.headset,
      Icons.videogame_asset,
      Icons.nature,
      Icons.pool,
    ];

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Custom Category',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Category Name',
                hintStyle: TextStyle(color: colors.textMuted.withOpacity(0.4)),
                filled: true,
                fillColor: colors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select Icon',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              width: double.maxFinite,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: icons.length,
                itemBuilder: (context, index) {
                  final icon = icons[index];
                  final isSelected = selectedIcon.value == icon;
                  return GestureDetector(
                    onTap: () => selectedIcon.value = icon,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? colors.primary : colors.bg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? Colors.white : colors.textMuted,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'CANCEL',
                    style: TextStyle(color: colors.textMuted),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      onAdded(nameController.text, selectedIcon.value);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'ADD',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
