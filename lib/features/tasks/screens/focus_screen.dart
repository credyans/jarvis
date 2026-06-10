import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_spacing.dart';

import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/core/utils/date_helpers.dart';
import 'package:jarvis/core/utils/id_generator.dart';
import 'package:jarvis/core/constants/emoji_map.dart';
import 'package:jarvis/features/tasks/data/models/task_model.dart';
import 'package:jarvis/features/tasks/data/models/tag_model.dart';
import 'package:jarvis/features/habits/data/models/habit_model.dart';
import 'package:jarvis/data/providers/task_provider.dart';
import 'package:jarvis/data/providers/habit_provider.dart';
import 'package:jarvis/data/providers/navigation_provider.dart';
import 'package:jarvis/shared/widgets/jarvis_card.dart';
import 'package:jarvis/shared/widgets/jarvis_button.dart';
import 'package:jarvis/shared/widgets/jarvis_chip.dart';
import 'package:jarvis/shared/widgets/jarvis_input.dart';
import 'package:jarvis/shared/widgets/empty_state.dart';
import 'package:jarvis/shared/widgets/toast_notification.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  int _plannerPeriod = 0; // 0 = Daily, 1 = Weekly, 2 = Monthly
  String? _selectedTagId; // null means 'All'
  bool _showCompleted = false;

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddTaskSheet(),
    );
  }

  void _showAddHabitSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddHabitSheet(),
    );
  }

  void _showManageTagsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ManageTagsSheet(),
    );
  }

  Widget _buildSubTabButton(int index, String label, IconData icon) {
    final activeTab = ref.watch(plannerSubTabProvider);
    final isActive = activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(plannerSubTabProvider.notifier).state = index,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20.0),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15.0,
                color: isActive ? AppColors.background : AppColors.textSecondary,
              ),
              const SizedBox(width: 4.0),
              Text(
                label,
                style: AppTypography.micro(
                  color: isActive ? AppColors.background : AppColors.textSecondary,
                ).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlannerTab(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final isWidescreen = size.width > 800;

    final timelineContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPlannerPeriodToggle(),
        const SizedBox(height: 20.0),
        _buildTimelineHeader(),
        const SizedBox(height: 16.0),
        _buildTimelineBlocks(),
      ],
    );

    final sidebarContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _PomodoroTimerCard(),
        const SizedBox(height: 20.0),
        const _GoalTargetsCard(),
        const SizedBox(height: 20.0),
        const _PlannerJarvisInsightCard(),
      ],
    );

    if (isWidescreen) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 24.0),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: timelineContent,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: sidebarContent,
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sidebarContent,
          const SizedBox(height: 24.0),
          timelineContent,
        ],
      );
    }
  }

  Widget _buildPlannerPeriodToggle() {
    return Container(
      height: 40.0,
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(3.0),
      child: Row(
        children: [
          _buildPlannerPeriodButton(0, 'Daily'),
          _buildPlannerPeriodButton(1, 'Weekly'),
          _buildPlannerPeriodButton(2, 'Monthly'),
        ],
      ),
    );
  }

  Widget _buildPlannerPeriodButton(int index, String label) {
    final isActive = _plannerPeriod == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _plannerPeriod = index),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Text(
            label,
            style: AppTypography.caption(
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ).copyWith(
              fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Today\'s Timeline',
          style: AppTypography.h3(color: AppColors.textPrimary).copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          DateHelpers.formatDate(DateTime.now()),
          style: AppTypography.caption(color: AppColors.textTertiary),
        ),
      ],
    );
  }

  Widget _buildTimelineBlocks() {
    if (_plannerPeriod != 0) {
      // Weekly and Monthly mock state to match premium UX
      return JarvisCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0),
          child: EmptyState(
            emoji: '📅',
            title: _plannerPeriod == 1 ? 'Weekly Timeline Ready' : 'Monthly Planner Loaded',
            subtitle: _plannerPeriod == 1
                ? 'Your collaborative team workspace and milestone blocks are aggregated for this week.'
                : 'Strategic priority reviews and financial velocity targets logged for this month.',
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Morning Block
        _buildTimelinePeriodBlock(
          periodName: 'Morning',
          icon: Icons.light_mode_outlined,
          children: [
            _buildPlannerEventCard(
              title: 'Deep Focus Session',
              time: '08:00 AM — 10:30 AM',
              emoji: '☕',
              initials: ['SK', 'AM'],
            ),
          ],
        ),
        const SizedBox(height: 16.0),

        // Afternoon Block
        _buildTimelinePeriodBlock(
          periodName: 'Afternoon',
          icon: Icons.wb_sunny_outlined,
          children: [
            // Interactive Smart Suggestion Card
            const _SmartSuggestionCard(),
            const SizedBox(height: 12.0),
            _buildPlannerEventCard(
              title: 'Product Sync',
              time: '03:00 PM — 04:00 PM',
              emoji: '👥',
              initials: ['JD', 'EM', 'LH'],
            ),
          ],
        ),
        const SizedBox(height: 16.0),

        // Evening Block
        _buildTimelinePeriodBlock(
          periodName: 'Evening',
          icon: Icons.nights_stay_outlined,
          children: [
            _buildPlannerEventCard(
              title: 'Gym Session',
              time: '06:30 PM — 07:30 PM',
              emoji: '💪',
              initials: [],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelinePeriodBlock({
    required String periodName,
    required IconData icon,
    required List<Widget> children,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicator Line
          Column(
            children: [
              Icon(icon, size: 20.0, color: AppColors.primary.withOpacity(0.6)),
              Expanded(
                child: Container(
                  width: 2.0,
                  color: AppColors.primary.withOpacity(0.15),
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  periodName.toUpperCase(),
                  style: AppTypography.micro(color: AppColors.textTertiary).copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8.0),
                ...children,
                const SizedBox(height: 8.0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlannerEventCard({
    required String title,
    required String time,
    required String emoji,
    required List<String> initials,
  }) {
    return JarvisCard(
      padding: 16.0,
      child: Row(
        children: [
          Container(
            width: 44.0,
            height: 44.0,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.0),
            ),
            alignment: Alignment.center,
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 20.0),
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  time,
                  style: AppTypography.caption(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (initials.isNotEmpty) _AvatarStack(initials: initials),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(unifiedTasksProvider);
    final tagsAsync = ref.watch(tagProvider);
    final habitsAsync = ref.watch(habitProvider);
    final activeTab = ref.watch(plannerSubTabProvider);

    if (activeTab == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(plannerSubTabProvider.notifier).state = 0;
      });
    }

    final tasks = tasksAsync.value ?? [];
    final habits = habitsAsync.value ?? [];
    final isTabEmpty = (activeTab == 0 && tasks.isEmpty) || (activeTab == 1 && habits.isEmpty);
    final scrollPhysics = isTabEmpty ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(taskProvider);
            ref.invalidate(tagProvider);
            ref.invalidate(habitProvider);
            ref.invalidate(todayTasksProvider);
          },
          child: CustomScrollView(
            physics: scrollPhysics,
            slivers: [
              // 1. Unified Header (Title + Segmented Tabs)
              SliverPadding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20.0,
                  left: 20.0,
                  right: 20.0,
                  bottom: 12.0,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Jarvis Planner',
                                style: AppTypography.h1(color: AppColors.textPrimary).copyWith(
                                  fontSize: 26.0,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2.0),
                              Text(
                                activeTab == 0
                                    ? 'Organize, track, and complete priorities.'
                                    : activeTab == 1
                                        ? 'Build atomic habits and secure daily wins.'
                                        : 'Map your schedule and protect cognitive bandwidth.',
                                style: AppTypography.caption(color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                          if (activeTab == 0)
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
                      const SizedBox(height: 16.0),
                      
                      // Segmented Tab Toggle (Priorities, Habits)
                      Container(
                        height: 48.0,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24.0),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        padding: const EdgeInsets.all(4.0),
                        child: Row(
                          children: [
                            _buildSubTabButton(0, 'Priorities', Icons.star_rounded),
                            _buildSubTabButton(1, 'Habits', Icons.loop_rounded),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── TAB CONTENT: PLANNER ──
              if (activeTab == 2)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  sliver: SliverToBoxAdapter(
                    child: _buildPlannerTab(context, ref),
                  ),
                ),

              // ── TAB CONTENT: PRIORITIES ──
              if (activeTab == 0) ...[
                // Tag Filter Row with trailing Settings Icon
                SliverToBoxAdapter(
                  child: tasksAsync.when(
                    data: (tasks) {
                      if (tasks.isEmpty) return const SizedBox.shrink();
                      return tagsAsync.when(
                        data: (tags) => _TagFilterBar(
                          tags: tags,
                          selectedTagId: _selectedTagId,
                          onTagSelected: (tagId) {
                            setState(() {
                              _selectedTagId = tagId;
                            });
                          },
                          onManageTagsPressed: () => _showManageTagsSheet(context),
                        ),
                        loading: () => const SizedBox(height: 50.0),
                        error: (_, __) => const SizedBox.shrink(),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),

                // Tasks checklist list
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  sliver: tasksAsync.when(
                    data: (tasks) {
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
                          child: Center(
                            child: EmptyState(
                              emoji: '🎯',
                              title: 'All priorities cleared!',
                              subtitle: 'No active priorities found. Tap below to map your next focus.',
                              actionLabel: 'Create priority',
                              onActionPressed: () => _showAddTaskSheet(context),
                            ),
                          ),
                        );
                      }

                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final task = filtered[index];
                            final tag = task.tagId == 'money_tag'
                                ? const TagModel(id: 'money_tag', name: 'Money', color: '#4EDEA3')
                                : (tagsAsync.value == null
                                    ? const TagModel(id: '', name: '', color: '#CCCCCC')
                                    : tagsAsync.value!.firstWhere(
                                        (t) => t.id == task.tagId,
                                        orElse: () => const TagModel(id: '', name: '', color: '#CCCCCC'),
                                      ));

                            return _TaskCard(
                              task: task,
                              tagName: tag.name,
                              tagColor: tag.color.isNotEmpty
                                  ? Color(int.parse(tag.color.replaceFirst('#', '0xFF')))
                                  : AppColors.textTertiary,
                              onToggleComplete: () async {
                                await ref.read(completeUnifiedTaskProvider)(task.id);
                                ref.invalidate(todayTasksProvider);
                              },
                              onDelete: () async {
                                final notifier = ref.read(taskProvider.notifier);
                                
                                // Show Undo Toast for 7 seconds
                                if (context.mounted) {
                                  ToastNotification.show(
                                    context,
                                    'Deleted: "${task.title}"',
                                    type: 'info',
                                    onUndo: () async {
                                      // Re-insert task
                                      await notifier.addTask(task);
                                      ref.invalidate(todayTasksProvider);
                                    },
                                  );
                                }
                                
                                await notifier.deleteTask(task.id);
                                ref.invalidate(todayTasksProvider);
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
                      child: Center(child: Text('Error loading priorities: $err')),
                    ),
                  ),
                ),
              ],

              // ── TAB CONTENT: HABITS ──
              if (activeTab == 1) ...[
                // Aggregated Habits Dashboard stats
                habitsAsync.when(
                  data: (habits) {
                    if (habits.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

                    final notifier = ref.read(habitProvider.notifier);
                    int totalStreak = 0;
                    for (final h in habits) {
                      final str = notifier.getCurrentStreak(h);
                      if (str > totalStreak) totalStreak = str;
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _StreakCard(totalStreak: totalStreak),
                          const SizedBox(height: 16.0),
                          const _HabitInsightBox(),
                          const SizedBox(height: 24.0),
                        ]),
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                  error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                ),

                // Habit dot-grids and completions checklist
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  sliver: habitsAsync.when(
                    data: (habits) {
                      if (habits.isEmpty) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: EmptyState(
                              emoji: '🔄',
                              title: 'No habits logged yet',
                              subtitle: 'Take small steps. Build atomic habits by setting daily checkpoints.',
                              actionLabel: 'Create habit',
                              onActionPressed: () => _showAddHabitSheet(context),
                            ),
                          ),
                        );
                      }

                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final habit = habits[index];
                            final notifier = ref.read(habitProvider.notifier);
                            final isCompletedToday = notifier.isCompletedToday(habit);
                            final currentStreak = notifier.getCurrentStreak(habit);

                            return _HabitCard(
                              habit: habit,
                              isCompletedToday: isCompletedToday,
                              currentStreak: currentStreak,
                              onToggleComplete: () async {
                                await notifier.toggleCompletion(habit.id, DateTime.now());
                                if (context.mounted && !isCompletedToday) {
                                  ToastNotification.show(
                                    context,
                                    'Atomic victory! Streak increased! 🚀',
                                  );
                                }
                              },
                              onDelete: () async {
                                await notifier.deleteHabit(habit.id);
                                if (context.mounted) {
                                  ToastNotification.show(context, 'Habit deleted successfully.');
                                }
                              },
                            );
                          },
                          childCount: habits.length,
                        ),
                      );
                    },
                    loading: () => const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, _) => SliverFillRemaining(
                      child: Center(child: Text('Error loading habits: $err')),
                    ),
                  ),
                ),
              ],

              // Bottom Buffer
              const SliverToBoxAdapter(
                child: SizedBox(height: 180.0),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: (() {
        if (activeTab == 2) return null;
        final tasks = tasksAsync.value ?? [];
        final habits = habitsAsync.value ?? [];
        if (activeTab == 0 && tasks.isEmpty) return null;
        if (activeTab == 1 && habits.isEmpty) return null;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 96.0, right: 8.0),
          child: FloatingActionButton(
            backgroundColor: activeTab == 0 ? AppColors.primary : AppColors.success,
            foregroundColor: Colors.white,
            elevation: 4.0,
            shape: const CircleBorder(),
            onPressed: () {
              if (activeTab == 0) {
                _showAddTaskSheet(context);
              } else {
                _showAddHabitSheet(context);
              }
            },
            child: const Icon(Icons.add_rounded, size: 28.0),
          ),
        );
      })(),
    );
  }
}

// ── TASK WIDGETS & SUB-VIEWS ──

class _TagFilterBar extends StatelessWidget {
  final List<TagModel> tags;
  final String? selectedTagId;
  final ValueChanged<String?> onTagSelected;
  final VoidCallback onManageTagsPressed;

  const _TagFilterBar({
    required this.tags,
    required this.selectedTagId,
    required this.onTagSelected,
    required this.onManageTagsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48.0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: tags.length + 2, // All, custom tags, Edit button
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
          if (index == tags.length + 1) {
            // Trailing tag management edit button
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: GestureDetector(
                onTap: onManageTagsPressed,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppSpacing.chipRadius,
                    border: Border.all(color: AppColors.border, width: 1.0),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.settings_rounded, size: 16.0, color: AppColors.primary),
                      SizedBox(width: 4.0),
                      Text('Manage', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ),
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

class _TaskCard extends StatefulWidget {
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

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  bool _isExpanded = false;

  Color _getPriorityColor() {
    switch (widget.task.priority) {
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

  String _getPriorityLabel() {
    switch (widget.task.priority) {
      case 3:
        return '🔥 High Priority';
      case 2:
        return '⚡ Medium Priority';
      case 1:
        return '💤 Low Priority';
      default:
        return '📝 Normal Priority';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
      child: Dismissible(
        key: Key(widget.task.id),
        direction: widget.task.id.startsWith('bill_') || widget.task.id.startsWith('debt_')
            ? DismissDirection.startToEnd
            : DismissDirection.horizontal,
        
        // Swipe Right to Complete (Green Check)
        background: Container(
          padding: const EdgeInsets.only(left: 20.0),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: AppSpacing.cardRadius,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 28.0,
          ),
        ),
        
        // Swipe Left to Delete (Red Trash)
        secondaryBackground: Container(
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
        
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            // Swipe right: Mark as completed and snap back!
            widget.onToggleComplete();
            if (context.mounted) {
              ToastNotification.show(
                context,
                widget.task.completed ? 'Vibe Priority Reset!' : 'Priority Completed! 🎯',
              );
            }
            return false; // Snap card back in place!
          } else {
            // Swipe left: Delete
            return true; // Dismiss the card
          }
        },
        
        onDismissed: (direction) {
          if (direction == DismissDirection.endToStart) {
            widget.onDelete();
          }
        },
        
        child: JarvisCard(
          padding: 16.0,
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  // Completion Indicator Check Bubble
                  GestureDetector(
                    onTap: widget.onToggleComplete,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28.0,
                      height: 28.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.task.completed ? AppColors.success : Colors.transparent,
                        border: Border.all(
                          color: widget.task.completed ? AppColors.success : AppColors.border,
                          width: 2.0,
                        ),
                      ),
                      child: widget.task.completed
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 16.0,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14.0),

                  // Emoji Map Icon
                  Text(
                    widget.task.emoji,
                    style: const TextStyle(fontSize: 22.0),
                  ),
                  const SizedBox(width: 12.0),

                  // Title and Tag Badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.task.title,
                          style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(
                            decoration: widget.task.completed ? TextDecoration.lineThrough : null,
                            fontWeight: widget.task.completed ? FontWeight.normal : FontWeight.w800,
                            color: widget.task.completed ? AppColors.textSecondary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Row(
                          children: [
                            // Tag Chip
                            if (widget.task.tagId != null && widget.tagName.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                decoration: BoxDecoration(
                                  color: widget.tagColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: Text(
                                  widget.tagName,
                                  style: AppTypography.micro(color: widget.tagColor),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                            ],
                            
                            // Due date
                            if (widget.task.dueDate != null) ...[
                              const Icon(Icons.calendar_today_rounded, size: 10.0, color: AppColors.textSecondary),
                              const SizedBox(width: 4.0),
                              Text(
                                DateHelpers.formatDate(widget.task.dueDate!),
                                style: AppTypography.micro(color: AppColors.textSecondary),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Right Border Priority Line
                  if (widget.task.priority > 0)
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
              
              // EXPANDED CARD LAYOUT SECTION
              if (_isExpanded) ...[
                const Divider(color: AppColors.border, height: 24.0),
                Text(
                  'Task Details',
                  style: AppTypography.micro(color: AppColors.textTertiary),
                ),
                const SizedBox(height: 6.0),
                
                // Description (Fallback text if empty)
                Text(
                  widget.task.description != null && widget.task.description!.isNotEmpty
                      ? widget.task.description!
                      : 'No detailed description mapped.',
                  style: AppTypography.body(color: AppColors.textSecondary).copyWith(
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12.0),
                
                // Priority details
                Row(
                  children: [
                    const Icon(Icons.bolt_rounded, size: 16.0, color: AppColors.primary),
                    const SizedBox(width: 6.0),
                    Text(
                      _getPriorityLabel(),
                      style: AppTypography.caption(color: AppColors.textPrimary).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                
                // LARGE ACTION BUTTON FOR COMPLETION
                JarvisButton(
                  text: widget.task.completed ? 'Mark Incomplete' : 'Complete priority',
                  onPressed: widget.onToggleComplete,
                  isFullWidth: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── TAG CRUD MANAGER PANEL ──

class _ManageTagsSheet extends ConsumerStatefulWidget {
  const _ManageTagsSheet();
  @override
  ConsumerState<_ManageTagsSheet> createState() => _ManageTagsSheetState();
}

class _ManageTagsSheetState extends ConsumerState<_ManageTagsSheet> {
  final TextEditingController _nameController = TextEditingController();
  final List<String> _hexColors = ['#E8847C', '#C4A0E8', '#7BC47F', '#E8B44C', '#E07070', '#3AA5F0'];
  String _selectedHex = '#E8847C';
  String _selectedEmoji = '🏷️';
  final List<String> _tagEmojis = ['🏷️', '💼', '🏡', '🏋️', '📚', '💰', '🎯', '💡', '🎨', '🚀'];
  
  TagModel? _editingTag;

  void _saveTag() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final tag = TagModel(
      id: _editingTag?.id ?? IdGenerator.generate(),
      name: name,
      color: _selectedHex,
      emoji: _selectedEmoji,
      sortOrder: _editingTag?.sortOrder ?? 99,
    );

    await ref.read(tagProvider.notifier).addTag(tag);
    _resetEditor();
  }

  void _resetEditor() {
    setState(() {
      _editingTag = null;
      _nameController.clear();
      _selectedHex = '#E8847C';
      _selectedEmoji = '🏷️';
    });
  }

  void _loadEditingTag(TagModel tag) {
    setState(() {
      _editingTag = tag;
      _nameController.text = tag.name;
      _selectedHex = tag.color;
      _selectedEmoji = tag.emoji ?? '🏷️';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(tagProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32.0)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32.0)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.08),
                width: 1.0,
              ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _editingTag != null ? 'Edit Tag' : 'Manage Focus Tags',
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
                const SizedBox(height: 16.0),

                // Add/Edit Tag Input Field
                JarvisInput(
                  hintText: 'Work, Personal, Health...',
                  controller: _nameController,
                  label: 'Tag Name',
                ),
                const SizedBox(height: 12.0),

                // Emoji & Color Row Selection
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tag Color', style: AppTypography.micro(color: AppColors.textSecondary)),
                          const SizedBox(height: 6.0),
                          Row(
                            children: _hexColors.map((hex) {
                              final isSelected = _selectedHex == hex;
                              final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                              return GestureDetector(
                                onTap: () => setState(() => _selectedHex = hex),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8.0),
                                  width: 24.0,
                                  height: 24.0,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: color,
                                    border: isSelected ? Border.all(color: AppColors.textPrimary, width: 2.0) : null,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tag Icon', style: AppTypography.micro(color: AppColors.textSecondary)),
                          const SizedBox(height: 6.0),
                          DropdownButton<String>(
                            value: _selectedEmoji,
                            underline: const SizedBox.shrink(),
                            items: _tagEmojis.map((e) {
                              return DropdownMenuItem<String>(
                                value: e,
                                child: Text(e, style: const TextStyle(fontSize: 18.0)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedEmoji = val;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),

                // Save / Cancel Button Row
                Row(
                  children: [
                    if (_editingTag != null) ...[
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                          ),
                          onPressed: _resetEditor,
                          child: Text('Cancel', style: AppTypography.caption(color: AppColors.textPrimary)),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                    ],
                    Expanded(
                      child: JarvisButton(
                        text: _editingTag != null ? 'Update Tag' : 'Add New Tag',
                        onPressed: _saveTag,
                      ),
                    ),
                  ],
                ),
                const Divider(color: AppColors.border, height: 32.0),

                // Tag list
                Text(
                  'Active Tags',
                  style: AppTypography.caption(color: AppColors.textSecondary).copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8.0),
                
                tagsAsync.when(
                  data: (tags) {
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tags.length,
                      itemBuilder: (context, index) {
                        final tag = tags[index];
                        final color = Color(int.parse(tag.color.replaceFirst('#', '0xFF')));
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: color.withOpacity(0.12),
                            child: Text(tag.emoji ?? '🏷️', style: const TextStyle(fontSize: 16.0)),
                          ),
                          title: Text(tag.name, style: AppTypography.body(color: AppColors.textPrimary)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, size: 18.0, color: AppColors.textSecondary),
                                onPressed: () => _loadEditingTag(tag),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_forever_rounded, size: 18.0, color: AppColors.error),
                                onPressed: () async {
                                  await ref.read(tagProvider.notifier).deleteTag(tag.id);
                                  ref.invalidate(taskProvider);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── TASK CREATION FORM SHEET ──

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

  void _saveTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    try {
      final task = TaskModel(
        id: IdGenerator.generate(),
        title: title,
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        tagId: _selectedTagId,
        dueDate: _dueDate,
        dueTime: _dueTime,
        priority: _priority,
        completed: false,
        emoji: _emoji,
        createdAt: DateTime.now(),
      );

      await ref.read(taskProvider.notifier).addTask(task);
      ref.invalidate(todayTasksProvider);

      if (mounted) {
        Navigator.pop(context);
        ToastNotification.show(context, 'Priority added: $title');
      }
    } catch (e) {
      if (mounted) {
        ToastNotification.show(
          context,
          'Failed to save priority: $e',
          type: 'error',
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _showCreateTagDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    String selectedColor = '#C0C1FF';
    String selectedEmoji = '🏷️';
    final colors = ['#C0C1FF', '#4EDEA3', '#E8B44C', '#FFB4AB', '#C4A0E8', '#3AA5F0'];
    final emojis = ['🏷️', '💼', '🏡', '🏋️', '📚', '💰', '🎯', '💡', '🎨', '🚀'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('New Tag', style: AppTypography.h3(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Tag Name',
                  hintText: 'e.g. Work, Health',
                ),
              ),
              const SizedBox(height: 16.0),
              // Emojis Selection
              SizedBox(
                height: 36.0,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: emojis.map((e) {
                    final isSelected = selectedEmoji == e;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedEmoji = e),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8.0),
                        padding: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withOpacity(0.12) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 20.0)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12.0),
              // Colors Selection
              SizedBox(
                height: 36.0,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: colors.map((c) {
                    final isSelected = selectedColor == c;
                    final colorVal = Color(int.parse(c.replaceFirst('#', '0xFF')));
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = c),
                      child: Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.only(right: 8.0),
                        decoration: BoxDecoration(
                          color: colorVal,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 2.0)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                try {
                  final tag = TagModel(
                    id: IdGenerator.generate(),
                    name: name,
                    color: selectedColor,
                    emoji: selectedEmoji,
                    sortOrder: 0,
                  );
                  await ref.read(tagProvider.notifier).addTag(tag);
                  setState(() {
                    _selectedTagId = tag.id;
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ToastNotification.show(context, 'Failed to add tag: $e', type: 'error');
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(tagProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32.0)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32.0)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.08),
                width: 1.0,
              ),
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
                      'Create Priority',
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
                const SizedBox(height: 20.0),

                // Emoji / Icon Preview Block
                Center(
                  child: Container(
                    width: 64.0,
                    height: 64.0,
                    decoration: BoxDecoration(
                      color: AppColors.border.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _emoji,
                      style: const TextStyle(fontSize: 32.0),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),

                // Inputs
                JarvisInput(
                  hintText: 'What should we accomplish?',
                  controller: _titleController,
                  autofocus: true,
                  label: 'Priority Title',
                ),
                const SizedBox(height: 16.0),
                JarvisInput(
                  hintText: 'Brief description details...',
                  controller: _descController,
                  label: 'Description (Optional)',
                ),
                const SizedBox(height: 20.0),

                // Tag Picker
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Tag',
                      style: AppTypography.caption(color: AppColors.textSecondary).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showCreateTagDialog(context),
                      child: Text(
                        '+ New Tag',
                        style: AppTypography.micro(color: AppColors.primary).copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                tagsAsync.when(
                  data: (tags) {
                    if (tags.isEmpty) {
                      return Text(
                        'No tags mapped. Manage tags to create categories.',
                        style: AppTypography.micro(color: AppColors.textTertiary),
                      );
                    }
                    return SizedBox(
                      height: 40.0,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: tags.length,
                        itemBuilder: (context, index) {
                          final tag = tags[index];
                          final isSelected = _selectedTagId == tag.id;
                          final color = Color(int.parse(tag.color.replaceFirst('#', '0xFF')));
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTagId = isSelected ? null : tag.id;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8.0),
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                              decoration: BoxDecoration(
                                color: isSelected ? color : color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                children: [
                                  Text(tag.emoji ?? '🏷️', style: const TextStyle(fontSize: 14.0)),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    tag.name,
                                    style: AppTypography.micro(
                                      color: isSelected ? Colors.white : color,
                                    ).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const SizedBox(height: 40.0),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 20.0),

                // Priority Level Selection
                Text(
                  'Priority Level',
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

                // Date picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                  title: Text(
                    _dueDate == null ? 'Set Due Date' : 'Due: ${DateHelpers.formatDate(_dueDate!)}',
                    style: AppTypography.body(color: AppColors.textPrimary).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (selected != null) {
                      setState(() {
                        _dueDate = selected;
                      });
                    }
                  },
                ),

                const SizedBox(height: 24.0),

                // Save Button
                JarvisButton(
                  text: 'Save Priority',
                  isFullWidth: true,
                  onPressed: _titleController.text.trim().isEmpty ? null : _saveTask,
                ),
              ],
            ),
          ),
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
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Text(
            label,
            style: AppTypography.micro(
              color: isSelected ? Colors.white : color,
            ).copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// ── HABIT WIDGETS & SUB-VIEWS ──

class _StreakCard extends StatelessWidget {
  final int totalStreak;
  const _StreakCard({required this.totalStreak});

  @override
  Widget build(BuildContext context) {
    return JarvisCard(
      color: AppColors.primaryLight.withOpacity(0.5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Text('🔥', style: TextStyle(fontSize: 28.0)),
          )
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scaleXY(begin: 1.0, end: 1.08, duration: 1.seconds, curve: Curves.easeInOut),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Best Vibe Streak',
                  style: AppTypography.caption(color: AppColors.primaryDark).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  totalStreak > 0 ? '$totalStreak Days Strong' : 'Starting Fresh Today',
                  style: AppTypography.h2(color: AppColors.textPrimary).copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitInsightBox extends StatelessWidget {
  const _HabitInsightBox();

  @override
  Widget build(BuildContext context) {
    return JarvisCard(
      color: AppColors.secondaryLight.withOpacity(0.5),
      padding: 16.0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🧠', style: TextStyle(fontSize: 20.0)),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jarvis Insight',
                  style: AppTypography.caption(color: AppColors.primaryDark).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'You tend to complete your habits 40% more often on weekdays compared to weekends. Suggest snoozing weekend notifications?',
                  style: AppTypography.caption(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  final HabitModel habit;
  final bool isCompletedToday;
  final int currentStreak;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;

  const _HabitCard({
    required this.habit,
    required this.isCompletedToday,
    required this.currentStreak,
    required this.onToggleComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
      child: Dismissible(
        key: Key(habit.id),
        direction: DismissDirection.endToStart,
        background: Container(
          padding: const EdgeInsets.only(right: 20.0),
          alignment: Alignment.centerRight,
          decoration: BoxDecoration(
            color: AppColors.errorLight,
            borderRadius: AppSpacing.cardRadius,
          ),
          child: const Icon(
            Icons.delete_forever_rounded,
            color: AppColors.error,
            size: 28.0,
          ),
        ),
        onDismissed: (_) => onDelete(),
        child: JarvisCard(
          padding: 16.0,
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44.0,
                    height: 44.0,
                    decoration: BoxDecoration(
                      color: AppColors.border.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      habit.icon,
                      style: const TextStyle(fontSize: 22.0),
                    ),
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Row(
                          children: [
                            Text(
                              '🔥 $currentStreak Day Streak',
                              style: AppTypography.caption(color: AppColors.primary).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Text(
                              '• ${habit.frequency}',
                              style: AppTypography.caption(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  GestureDetector(
                    onTap: onToggleComplete,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 32.0,
                      height: 32.0,
                      decoration: BoxDecoration(
                        color: isCompletedToday ? AppColors.success : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCompletedToday ? AppColors.success : AppColors.border,
                          width: 2.0,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: isCompletedToday
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 18.0,
                            )
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              _WeeklyDotGrid(completions: habit.completions, startDate: habit.startDate),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyDotGrid extends StatelessWidget {
  final List<String> completions;
  final DateTime startDate;

  const _WeeklyDotGrid({required this.completions, required this.startDate});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final weekDays = DateHelpers.daysInWeek(today);
    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final day = weekDays[index];
        final dayStr = DateHelpers.dateKey(day);
        final isCompleted = completions.contains(dayStr);
        final isFuture = day.isAfter(today);
        final isToday = DateHelpers.isToday(day);
        final isBeforeStart = day.isBefore(startDate);

        Color dotColor;
        Border? border;

        if (isFuture || isBeforeStart) {
          dotColor = Colors.transparent;
          border = Border.all(color: AppColors.border.withOpacity(0.5), width: 1.0);
        } else if (isCompleted) {
          dotColor = AppColors.success;
        } else {
          dotColor = Colors.transparent;
          border = Border.all(
            color: isToday ? AppColors.primary : AppColors.border,
            width: isToday ? 2.0 : 1.0,
          );
        }

        return Column(
          children: [
            Text(
              dayLabels[index],
              style: AppTypography.micro(
                color: isToday ? AppColors.primary : AppColors.textTertiary,
              ).copyWith(
                fontWeight: isToday ? FontWeight.w800 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 6.0),
            Container(
              width: 24.0,
              height: 24.0,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: border,
              ),
              alignment: Alignment.center,
              child: isCompleted
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 12.0)
                  : null,
            ),
          ],
        );
      }),
    );
  }
}

class _AddHabitSheet extends ConsumerStatefulWidget {
  const _AddHabitSheet();
  @override
  ConsumerState<_AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends ConsumerState<_AddHabitSheet> {
  final TextEditingController _nameController = TextEditingController();
  String _emoji = '🔄';
  String _frequency = 'daily';
  final int _target = 1;
  String? _reminderTime = '07:30';
  final List<String> _emojis = ['🔄', '🏋️', '🧘', '📚', '💧', '🥗', '🚶', '😴', '🧠', '✏️'];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      setState(() {});
    });
  }

  void _saveHabit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    try {
      final habit = HabitModel(
        id: IdGenerator.generate(),
        name: name,
        icon: _emoji,
        frequency: _frequency,
        target: _target,
        reminderTime: _reminderTime,
        startDate: DateTime.now(),
        completions: [],
      );

      await ref.read(habitProvider.notifier).addHabit(habit);

      if (mounted) {
        Navigator.pop(context);
        ToastNotification.show(context, 'Habit added: $name');
      }
    } catch (e) {
      if (mounted) {
        ToastNotification.show(
          context,
          'Failed to save habit: $e',
          type: 'error',
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32.0)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32.0)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.08),
                width: 1.0,
              ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Start New Habit',
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
                const SizedBox(height: 20.0),

                Center(
                  child: DropdownButton<String>(
                    value: _emoji,
                    dropdownColor: AppColors.surface,
                    underline: const SizedBox.shrink(),
                    items: _emojis.map((e) {
                      return DropdownMenuItem<String>(
                        value: e,
                        child: Text(e, style: const TextStyle(fontSize: 28.0)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _emoji = val);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16.0),

                JarvisInput(
                  hintText: 'e.g. Read 15 pages, Drink Water...',
                  controller: _nameController,
                  autofocus: true,
                  label: 'Habit Name',
                ),
                const SizedBox(height: 20.0),

                // Frequency Toggle
                Text(
                  'Frequency',
                  style: AppTypography.caption(color: AppColors.textSecondary).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    _buildFreqChip('daily', 'Daily'),
                    const SizedBox(width: 12.0),
                    _buildFreqChip('weekdays', 'Weekdays'),
                    const SizedBox(width: 12.0),
                    _buildFreqChip('custom', 'Custom'),
                  ],
                ),
                const SizedBox(height: 24.0),

                // Reminder Time picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.alarm_rounded, color: AppColors.success),
                  title: Text(
                    _reminderTime == null
                        ? 'Set Daily Reminder'
                        : 'Reminder: ${DateHelpers.formatTime(_reminderTime!)}',
                    style: AppTypography.body(color: AppColors.textPrimary).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 7, minute: 30),
                    );
                    if (time != null) {
                      final hr = time.hour.toString().padLeft(2, '0');
                      final mn = time.minute.toString().padLeft(2, '0');
                      setState(() {
                        _reminderTime = '$hr:$mn';
                      });
                    }
                  },
                ),
                const SizedBox(height: 32.0),

                JarvisButton(
                  text: 'Save Habit',
                  isFullWidth: true,
                  onPressed: _nameController.text.trim().isEmpty ? null : _saveHabit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFreqChip(String freq, String label) {
    final isSelected = _frequency == freq;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _frequency = freq),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.success : AppColors.surface,
            borderRadius: AppSpacing.buttonRadius,
            border: Border.all(
              color: isSelected ? AppColors.success : Colors.white.withOpacity(0.08),
              width: 1.0,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.caption(
              color: isSelected ? AppColors.background : AppColors.textPrimary,
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

class _AvatarStack extends StatelessWidget {
  final List<String> initials;
  const _AvatarStack({required this.initials});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32.0,
      width: 32.0 + (initials.length - 1) * 20.0,
      child: Stack(
        children: List.generate(initials.length, (index) {
          return Positioned(
            left: index * 20.0,
            child: Container(
              width: 32.0,
              height: 32.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: [
                  AppColors.primaryDark,
                  AppColors.surfaceContainerHighest,
                  AppColors.primary,
                ][index % 3],
                border: Border.all(color: AppColors.background, width: 2.0),
              ),
              alignment: Alignment.center,
              child: Text(
                initials[index],
                style: const TextStyle(
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _PomodoroTimerCard extends StatefulWidget {
  const _PomodoroTimerCard();

  @override
  State<_PomodoroTimerCard> createState() => _PomodoroTimerCardState();
}

class _PomodoroTimerCardState extends State<_PomodoroTimerCard> {
  Timer? _timer;
  int _secondsRemaining = 25 * 60;
  bool _isRunning = false;

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() {
        _isRunning = false;
      });
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() {
            _secondsRemaining--;
          });
        } else {
          _timer?.cancel();
          setState(() {
            _isRunning = false;
            _secondsRemaining = 25 * 60;
          });
          if (context.mounted) {
            ToastNotification.show(context, 'Focus interval completed! Take a break. 🧘');
          }
        }
      });
      setState(() {
        _isRunning = true;
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 25 * 60;
      _isRunning = false;
    });
  }

  String _formatTime() {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return JarvisCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Focus Flow',
                style: AppTypography.bodyMedium(color: AppColors.primary).copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const Icon(Icons.timer_outlined, color: AppColors.primary, size: 20.0),
            ],
          ),
          const SizedBox(height: 16.0),
          Center(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.white, Color(0x99C0C1FF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds),
              child: Text(
                _formatTime(),
                style: const TextStyle(
                  fontSize: 54.0,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4.0),
          Center(
            child: Text(
              'CURRENT: DEEP WORK',
              style: AppTypography.micro(color: AppColors.textSecondary).copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: JarvisButton(
                  text: _isRunning ? 'Pause' : 'Start Focus',
                  onPressed: _toggleTimer,
                ),
              ),
              const SizedBox(width: 12.0),
              GestureDetector(
                onTap: _resetTimer,
                child: Container(
                  width: 48.0,
                  height: 48.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary, size: 20.0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalTargetsCard extends StatelessWidget {
  const _GoalTargetsCard();

  Widget _buildGoalProgress({
    required String title,
    required double progress,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTypography.caption(color: AppColors.textSecondary),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: AppTypography.caption(color: color).copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6.0),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            color: color,
            backgroundColor: AppColors.surfaceContainerHighest,
            minHeight: 6.0,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return JarvisCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Goal Targets',
            style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16.0),
          _buildGoalProgress(
            title: 'Project Phoenix',
            progress: 0.82,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 14.0),
          _buildGoalProgress(
            title: 'Knowledge Base',
            progress: 0.45,
            color: const Color(0xFFDDB7FF),
          ),
        ],
      ),
    );
  }
}

class _PlannerJarvisInsightCard extends StatelessWidget {
  const _PlannerJarvisInsightCard();

  @override
  Widget build(BuildContext context) {
    return JarvisCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_outlined, color: AppColors.primary, size: 20.0),
              const SizedBox(width: 8.0),
              Text(
                'JARVIS INSIGHT',
                style: AppTypography.micro(color: AppColors.primary).copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Text(
            '"Your peak cognitive performance is typically between 9 AM and 11 AM. I\'ve blocked out this time tomorrow for your most complex coding tasks."',
            style: AppTypography.body(color: AppColors.textPrimary).copyWith(
              fontStyle: FontStyle.italic,
              fontSize: 14.0,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              const Spacer(),
              GestureDetector(
                onTap: () {
                  ToastNotification.show(context, 'Analyzing performance patterns...');
                },
                child: Text(
                  'View Patterns',
                  style: AppTypography.caption(color: AppColors.primary).copyWith(
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
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

class _SmartSuggestionCard extends StatefulWidget {
  const _SmartSuggestionCard();

  @override
  State<_SmartSuggestionCard> createState() => _SmartSuggestionCardState();
}

class _SmartSuggestionCardState extends State<_SmartSuggestionCard> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    if (_accepted) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppColors.secondary, size: 16.0),
                  const SizedBox(width: 6.0),
                  Text(
                    'Smart Suggestion',
                    style: AppTypography.micro(color: AppColors.secondary).copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  'AI OPTIMIZED',
                  style: AppTypography.micro(color: AppColors.secondary).copyWith(
                    fontSize: 8.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Text(
            'Schedule "Executive Review" for 02:30 PM?',
            style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _accepted = true;
                  });
                  ToastNotification.show(context, 'Suggestion dismissed');
                },
                child: const Text(
                  'Dismiss',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 12.0),
                ),
              ),
              const SizedBox(width: 8.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  minimumSize: Size.zero,
                  elevation: 0,
                ),
                onPressed: () {
                  setState(() {
                    _accepted = true;
                  });
                  ToastNotification.show(context, 'Executive Review added to Afternoon!');
                },
                child: const Text(
                  'Accept',
                  style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
