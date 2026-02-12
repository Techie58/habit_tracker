import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:iron_mind/core/utils/colors.dart';
import 'package:iron_mind/features/challenge/presentation/providers/challenge_provider.dart';
import 'package:iron_mind/features/habit/presentation/widgets/custom_date_picker_dialog.dart';
import 'package:iron_mind/features/challenge/data/models/challenge_model.dart';
import 'package:uuid/uuid.dart';

class CreateChallengeScreen extends HookConsumerWidget {
  final ChallengeModel? challengeToEdit;

  const CreateChallengeScreen({super.key, this.challengeToEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final durationController = useTextEditingController(text: '30');
    final threatLevel = useState('HARD');
    final consequenceType = useState('PHYSICAL');
    final specificConsequence = useState('COLD SHOWER');
    final roadmap = useState<List<ChallengeMilestone>>([]);
    final startDate = useState<DateTime>(DateTime.now());
    final colors = Theme.of(context).appColors;

    useEffect(() {
      if (challengeToEdit != null) {
        nameController.text = challengeToEdit!.name;
        durationController.text = challengeToEdit!.duration.toString();
        threatLevel.value = challengeToEdit!.threatLevel;
        consequenceType.value = challengeToEdit!.consequenceType;
        specificConsequence.value = challengeToEdit!.specificConsequence;
        roadmap.value = challengeToEdit!.roadmap;
        startDate.value = challengeToEdit!.startDate;
      }
      return null;
    }, []);

    void handleAccept() {
      if (nameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a mission identification name'),
          ),
        );
        return;
      }

      final duration = int.tryParse(durationController.text) ?? 30;

      if (challengeToEdit != null) {
        final updatedChallenge = challengeToEdit!.copyWith(
          name: nameController.text.toUpperCase(),
          duration: duration,
          threatLevel: threatLevel.value,
          consequenceType: consequenceType.value,
          specificConsequence: specificConsequence.value,
          roadmap: roadmap.value,
          startDate: startDate.value,
        );
        ref.read(challengeProvider.notifier).updateChallenge(updatedChallenge);
      } else {
        ref
            .read(challengeProvider.notifier)
            .addChallenge(
              name: nameController.text.toUpperCase(),
              duration: duration,
              threatLevel: threatLevel.value,
              consequenceType: consequenceType.value,
              specificConsequence: specificConsequence.value,
              startDate: startDate.value,
              roadmap: roadmap.value,
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
          challengeToEdit != null ? 'Edit Mission' : 'New Mission',
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
              _buildSectionHeader('MISSION IDENTIFICATION', colors),
              _buildLabel('CHALLENGE NAME', colors),
              _buildTextField(
                nameController,
                'E.G. NO-SURRENDER-MARCH',
                colors,
              ),
              const SizedBox(height: 20),
              _buildLabel('DURATION (DAYS)', colors),
              _buildTextField(
                durationController,
                '30',
                colors,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 20),
              _buildLabel('START DATE', colors),
              _buildDatePicker(
                context,
                startDate.value,
                (date) => startDate.value = date,
                colors,
              ),

              const SizedBox(height: 30),
              _buildSectionHeader('MISSION ROADMAP', colors),
              ...roadmap.value.map(
                (m) => _buildMilestoneTile(m, () {
                  roadmap.value = roadmap.value
                      .where((item) => item.id != m.id)
                      .toList();
                }, colors),
              ),
              _buildAddMilestoneButton(() {
                _showAddMilestoneDialog(context, (m) {
                  roadmap.value = [...roadmap.value, m];
                });
              }, colors),

              // const SizedBox(height: 40),
              // _buildWarningCard(colors),
              const SizedBox(height: 20),
              _buildAcceptButton(handleAccept, colors),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // UI HELPER WIDGETS
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, AppColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: colors.primary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, AppColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          color: colors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    AppColorScheme colors, {
    TextInputType? keyboardType,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: colors.textMuted.withValues(alpha: 0.2)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  // Widget _buildWarningCard(AppColorScheme colors) {
  //   return Container(
  //     padding: const EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       color: AppColors.highPriorityColor.withOpacity(0.05),
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: AppColors.highPriorityColor.withOpacity(0.2)),
  //     ),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Icon(
  //           Icons.warning_amber_rounded,
  //           color: AppColors.highPriorityColor,
  //           size: 28,
  //         ),
  //         const SizedBox(width: 15),
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               const Text(
  //                 'BROTHERHOOD WARNING',
  //                 style: TextStyle(
  //                   color: AppColors.highPriorityColor,
  //                   fontWeight: FontWeight.bold,
  //                   fontSize: 12,
  //                   letterSpacing: 1.1,
  //                 ),
  //               ),
  //               const SizedBox(height: 8),
  //               Text(
  //                 'Once started, backing out has consequences. Your progress will be monitored by the brotherhood.',
  //                 style: TextStyle(
  //                   color: colors.textSecondary,
  //                   fontSize: 12,
  //                   height: 1.4,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildAcceptButton(VoidCallback onTap, AppColorScheme colors) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 10,
          shadowColor: colors.primary.withValues(alpha: 0.5),
        ),
        child: Text(
          challengeToEdit != null ? 'UPDATE MISSION' : 'ACCEPT THE CHALLENGE',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildMilestoneTile(
    ChallengeMilestone milestone,
    VoidCallback onRemove,
    AppColorScheme colors,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.flag, color: colors.primary, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${milestone.durationDays} Days • ${milestone.subtasks.length} Subtasks',
                  style: TextStyle(color: colors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.remove_circle_outline,
              color: Colors.redAccent,
              size: 20,
            ),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }

  Widget _buildAddMilestoneButton(VoidCallback onTap, AppColorScheme colors) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: colors.primary, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: colors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'ADD MILESTONE',
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMilestoneDialog(
    BuildContext context,
    Function(ChallengeMilestone) onAdded,
  ) {
    showDialog(
      context: context,
      builder: (context) => _MilestoneAddDialog(onAdded: onAdded),
    );
  }

  Widget _buildDatePicker(
    BuildContext context,
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
            title: 'SELECT START DATE',
            onSelected: onDateChange,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('yyyy-MM-dd').format(selectedDate),
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(Icons.calendar_today, color: colors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MILESTONE ADD DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class _MilestoneAddDialog extends HookWidget {
  final Function(ChallengeMilestone) onAdded;
  const _MilestoneAddDialog({required this.onAdded});

  @override
  Widget build(BuildContext context) {
    final titleController = useTextEditingController();
    final descController = useTextEditingController();
    final durationController = useTextEditingController(text: '7');
    final subtaskController = useTextEditingController();
    final subtasks = useState<List<String>>([]);
    final editingIndex = useState<int?>(-1);
    final colors = Theme.of(context).appColors;

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Milestone',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _dialogTextField(
              titleController,
              'Milestone Title (e.g. Phase 1)',
              colors,
            ),
            const SizedBox(height: 15),
            _dialogTextField(
              descController,
              'Description',
              colors,
              maxLines: 3,
            ),
            const SizedBox(height: 15),
            _dialogTextField(
              durationController,
              'Duration (Days)',
              colors,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 25),
            Text(
              'SUBTASKS',
              style: TextStyle(
                color: colors.primary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _dialogTextField(
                    subtaskController,
                    'Add subtask...',
                    colors,
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(
                    editingIndex.value != null && editingIndex.value! >= 0
                        ? Icons.check_circle
                        : Icons.add_circle,
                    color: colors.primary,
                  ),
                  onPressed: () {
                    if (subtaskController.text.isNotEmpty) {
                      if (editingIndex.value != null &&
                          editingIndex.value! >= 0) {
                        final newList = List<String>.from(subtasks.value);
                        newList[editingIndex.value!] = subtaskController.text;
                        subtasks.value = newList;
                        editingIndex.value = -1;
                      } else {
                        subtasks.value = [
                          ...subtasks.value,
                          subtaskController.text,
                        ];
                      }
                      subtaskController.clear();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...subtasks.value.asMap().entries.map((entry) {
              final index = entry.key;
              final s = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.subdirectory_arrow_right,
                      color: colors.textMuted,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: editingIndex.value == index
                            ? colors.primary
                            : Colors.blueAccent,
                        size: 14,
                      ),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      onPressed: () {
                        subtaskController.text = s;
                        editingIndex.value = index;
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.redAccent,
                        size: 14,
                      ),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      onPressed: () {
                        final newList = List<String>.from(subtasks.value);
                        newList.removeAt(index);
                        subtasks.value = newList;
                      },
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 30),
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
                    if (titleController.text.isNotEmpty) {
                      onAdded(
                        ChallengeMilestone(
                          id: const Uuid().v4(),
                          title: titleController.text,
                          description: descController.text,
                          durationDays:
                              int.tryParse(durationController.text) ?? 7,
                          subtasks: subtasks.value
                              .map(
                                (s) => ChallengeSubtask(
                                  id: const Uuid().v4(),
                                  title: s,
                                ),
                              )
                              .toList(),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
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

  Widget _dialogTextField(
    TextEditingController controller,
    String hint,
    AppColorScheme colors, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: colors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: colors.textMuted.withOpacity(0.4),
          fontSize: 13,
        ),
        filled: true,
        fillColor: colors.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
