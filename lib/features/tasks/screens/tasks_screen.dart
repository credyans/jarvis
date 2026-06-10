import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_spacing.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/core/utils/date_helpers.dart';
import 'package:jarvis/core/utils/id_generator.dart';
import 'package:jarvis/core/constants/emoji_map.dart';
import 'package:jarvis/features/tasks/data/models/task_model.dart';
import 'package:jarvis/features/tasks/data/models/tag_model.dart';
import 'package:jarvis/data/providers/task_provider.dart';
import 'package:jarvis/shared/widgets/jarvis_card.dart';
import 'package:jarvis/shared/widgets/jarvis_button.dart';
import 'package:jarvis/shared/widgets/jarvis_chip.dart';
import 'package:jarvis/shared/widgets/jarvis_input.dart';
import 'package:jarvis/shared/widgets/empty_state.dart';
import 'package:jarvis/shared/widgets/toast_notification.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String? _selectedTagId; // null means 'All'
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(taskProvider);
    final tagsAsync = ref.watch(tagProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(taskProvider);
            ref.invalidate(todayTasksProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Header (Static)
              SliverPadding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20.0,
                  left: 20.0,
                  right: 20.0,
                  bottom: 12.0,
                ),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Focus',
                            style: AppTypography.h1(color: AppColors.textPrimary).copyWith(
                              fontSize: 26.0,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            'Organize, track, and complete your priorities.',
                            style: AppTypography.caption(color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                      
                      // Filter toggle (Completed vs Incomplete)
                      IconButton(
                        icon: Icon(
                          _showCompleted ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                          color: AppColors.primary,
                        ),
                        onPressed: () {
                          setState(() {
                            _showCompleted = !_showCompleted;
                          });
                        },
                        tooltip: 'Show Completed',
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Tag Horizontal Filter Bar
              SliverToBoxAdapter(
                child: tagsAsync.when(
                  data: (tags) => _TagFilterBar(
                    tags: tags,
                    selectedTagId: _selectedTagId,
                    onTagSelected: (tagId) {
                      setState(() {
                        _selectedTagId = tagId;
                      });
                    },
                  ),
                  loading: () => const SizedBox(height: 50.0),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

              // 3. Tasks List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                sliver: tasksAsync.when(
                  data: (tasks) {
                    // Filter tasks
                    var filtered = tasks;
                    if (_selectedTagId != null) {
                      filtered = filtered.where((t) => t.tagId == _selectedTagId).toList();
                    }
                    if (!_showCompleted) {
                      filtered = filtered.where((t) => !t.completed).toList();
                    }

                    if (filtered.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 48.0),
                            EmptyState(
                              emoji: '🎯',
                              title: 'All caught up!',
                              subtitle: 'No tasks found here. Tap below to create your next commitment.',
                              actionLabel: 'Create Task',
                              onActionPressed: () => _showAddTaskSheet(context),
                            ),
                          ],
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final task = filtered[index];
                          final tag = tagsAsync.value?.firstWhere(
                            (t) => t.id == task.tagId,
                            orElse: () => const TagModel(id: '', name: '', color: '#CCCCCC'),
                          );

                          return _TaskCard(
                            task: task,
                            tagName: tag?.name ?? 'General',
                            tagColor: tag != null ? Color(int.parse(tag.color.replaceFirst('#', '0xFF'))) : AppColors.textTertiary,
                            onToggleComplete: () async {
                              await ref.read(taskProvider.notifier).toggleCompletion(task.id);
                              ref.invalidate(todayTasksProvider);
                            },
                            onDelete: () async {
                              await ref.read(taskProvider.notifier).deleteTask(task.id);
                              ref.invalidate(todayTasksProvider);
                              if (context.mounted) {
                                ToastNotification.show(context, 'Task deleted successfully.');
                              }
                            },
                          );
                        },
                        childCount: filtered.length,
                      ),
                    );
                  },
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => SliverFillRemaining(
                    child: Center(child: Text('Error loading tasks: $err')),
                  ),
                ),
              ),

              // Bottom offset
              const SliverToBoxAdapter(
                child: SizedBox(height: 180.0),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 96.0, right: 8.0), // clear navigation
        child: FloatingActionButton(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4.0,
          shape: const CircleBorder(),
          onPressed: () => _showAddTaskSheet(context),
          child: const Icon(Icons.add_rounded, size: 28.0),
        ),
      ),
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddTaskSheet(),
    );
  }
}

class _TagFilterBar extends StatelessWidget {
  final List<TagModel> tags;
  final String? selectedTagId;
  final ValueChanged<String?> onTagSelected;

  const _TagFilterBar({
    required this.tags,
    required this.selectedTagId,
    required this.onTagSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48.0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: tags.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: JarvisChip(
                label: 'All Focus',
                isSelected: selectedTagId == null,
                emoji: '✨',
                onTap: () => onTagSelected(null),
              ),
            );
          }
          final tag = tags[index - 1];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: JarvisChip(
              label: tag.name,
              isSelected: selectedTagId == tag.id,
              emoji: tag.emoji,
              onTap: () => onTagSelected(tag.id),
            ),
          );
        },
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final String tagName;
  final Color tagColor;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.tagName,
    required this.tagColor,
    required this.onToggleComplete,
    required this.onDelete,
  });

  Color _getPriorityColor() {
    switch (task.priority) {
      case 3:
        return AppColors.error;
      case 2:
        return AppColors.warning;
      case 1:
        return AppColors.secondary;
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Dismissible(
        key: Key(task.id),
        direction: DismissDirection.endToStart,
        background: Container(
          padding: const EdgeInsets.only(right: 20.0),
          alignment: Alignment.centerRight,
          decoration: BoxDecoration(
            color: AppColors.errorLight,
            borderRadius: AppSpacing.cardRadius,
          ),
          child: const Icon(
            Icons.delete_sweep_rounded,
            color: AppColors.error,
            size: 28.0,
          ),
        ),
        onDismissed: (_) => onDelete(),
        child: JarvisCard(
          padding: 16.0,
          onTap: onToggleComplete,
          child: Row(
            children: [
              // Swipe/Tap check mark
              GestureDetector(
                onTap: onToggleComplete,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26.0,
                  height: 26.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: task.completed ? AppColors.success : Colors.transparent,
                    border: Border.all(
                      color: task.completed ? AppColors.success : AppColors.border,
                      width: 2.0,
                    ),
                  ),
                  child: task.completed
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16.0,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 14.0),

              // Emoji Preview
              Text(
                task.emoji,
                style: const TextStyle(fontSize: 22.0),
              ),
              const SizedBox(width: 12.0),

              // Title and Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(
                        decoration: task.completed ? TextDecoration.lineThrough : null,
                        fontWeight: task.completed ? FontWeight.normal : FontWeight.w700,
                        color: task.completed ? AppColors.textSecondary : AppColors.textPrimary,
                      ),
                    ),
                    if (task.description != null && task.description!.isNotEmpty) ...[
                      const SizedBox(height: 2.0),
                      Text(
                        task.description!,
                        style: AppTypography.caption(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6.0),
                    Row(
                      children: [
                        // Tag Chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            color: tagColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            tagName,
                            style: AppTypography.micro(color: tagColor),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        
                        // Due date indicator
                        if (task.dueDate != null) ...[
                          const Icon(Icons.calendar_today_rounded, size: 10.0, color: AppColors.textSecondary),
                          const SizedBox(width: 4.0),
                          Text(
                            DateHelpers.formatDate(task.dueDate!),
                            style: AppTypography.micro(color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Right Border/Indicator for Priority
              if (task.priority > 0)
                Container(
                  width: 4.0,
                  height: 36.0,
                  decoration: BoxDecoration(
                    color: _getPriorityColor(),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddTaskSheet extends ConsumerStatefulWidget {
  const _AddTaskSheet();

  @override
  ConsumerState<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<_AddTaskSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _emoji = '📝';
  String? _selectedTagId;
  int _priority = 0;
  DateTime? _dueDate;
  String? _dueTime;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() {
      setState(() {});
      final text = _titleController.text;
      if (text.isNotEmpty) {
        _emoji = EmojiMap.getEmoji(text);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _saveTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    try {
      final task = TaskModel(
        id: IdGenerator.generate(),
        title: title,
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        tagId: _selectedTagId,
        dueDate: _dueDate ?? DateTime.now(),
        dueTime: _dueTime ?? '09:00',
        priority: _priority,
        completed: false,
        emoji: _emoji,
        createdAt: DateTime.now(),
      );

      await ref.read(taskProvider.notifier).addTask(task);
      ref.invalidate(todayTasksProvider);

      if (mounted) {
        Navigator.pop(context);
        ToastNotification.show(context, 'Task created: $title');
      }
    } catch (e) {
      if (mounted) {
        ToastNotification.show(
          context,
          'Failed to save task: $e',
          type: 'error',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(tagProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32.0),
          topRight: Radius.circular(32.0),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: 24.0,
        bottom: bottomInset + 32.0,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add New Task',
                  style: AppTypography.h2(color: AppColors.textPrimary),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: AppColors.border.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 20.0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),

            // Title + Auto-Emoji Preview
            Row(
              children: [
                // Live Emoji Display
                Container(
                  width: 50.0,
                  height: 50.0,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: AppSpacing.buttonRadius,
                  ),
                  child: Center(
                    child: Text(
                      _emoji,
                      style: const TextStyle(fontSize: 24.0),
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: JarvisInput(
                    hintText: 'What needs to be done?',
                    controller: _titleController,
                    autofocus: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // Description
            JarvisInput(
              hintText: 'Add description (optional)',
              controller: _descController,
              maxLines: 2,
            ),
            const SizedBox(height: 20.0),

            // Tag Selection
            Text(
              'Select Tag',
              style: AppTypography.caption(color: AppColors.textSecondary).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8.0),
            tagsAsync.when(
              data: (tags) => Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: tags.map((tag) {
                  final isSelected = _selectedTagId == tag.id;
                  return JarvisChip(
                    label: tag.name,
                    isSelected: isSelected,
                    emoji: tag.emoji,
                    onTap: () {
                      setState(() {
                        _selectedTagId = isSelected ? null : tag.id;
                      });
                    },
                  );
                }).toList(),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20.0),

            // Priority Selection
            Text(
              'Priority',
              style: AppTypography.caption(color: AppColors.textSecondary).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                _buildPriorityChip(0, 'None', Colors.grey),
                const SizedBox(width: 8.0),
                _buildPriorityChip(1, 'Low', AppColors.secondary),
                const SizedBox(width: 8.0),
                _buildPriorityChip(2, 'Medium', AppColors.warning),
                const SizedBox(width: 8.0),
                _buildPriorityChip(3, 'High', AppColors.error),
              ],
            ),
            const SizedBox(height: 24.0),

            // Date & Time Picker Row
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.today_rounded, color: AppColors.primary),
                    title: Text(
                      _dueDate == null ? 'Today' : DateHelpers.formatDate(_dueDate!),
                      style: AppTypography.body(color: AppColors.textPrimary),
                    ),
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (selected != null) {
                        setState(() {
                          _dueDate = selected;
                        });
                      }
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time_rounded, color: AppColors.primary),
                    title: Text(
                      _dueTime == null ? '09:00 AM' : DateHelpers.formatTime(_dueTime!),
                      style: AppTypography.body(color: AppColors.textPrimary),
                    ),
                    onTap: () async {
                      final selected = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 9, minute: 0),
                      );
                      if (selected != null) {
                        setState(() {
                          _dueTime = '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),

            // Save Button
            JarvisButton(
              text: 'Save Task',
              isFullWidth: true,
              onPressed: _titleController.text.trim().isEmpty ? null : _saveTask,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip(int level, String label, Color color) {
    final isSelected = _priority == level;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _priority = level;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: AppSpacing.buttonRadius,
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: 1.0,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.caption(
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ).copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
