import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_spacing.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/core/utils/currency_formatter.dart';
import 'package:jarvis/core/utils/date_helpers.dart';
import 'package:jarvis/features/memory/data/models/daily_memory_model.dart';
import 'package:jarvis/features/mood/domain/repositories/mood_repository.dart';
import 'package:jarvis/data/providers/memory_provider.dart';
import 'package:jarvis/shared/widgets/jarvis_card.dart';
import 'package:jarvis/shared/widgets/jarvis_button.dart';
import 'package:jarvis/shared/widgets/jarvis_input.dart';
import 'package:jarvis/shared/widgets/toast_notification.dart';

class MemoryScreen extends ConsumerStatefulWidget {
  const MemoryScreen({super.key});

  @override
  ConsumerState<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends ConsumerState<MemoryScreen> {
  int _activeTab = 0; // 0 = Review, 1 = Vault
  int _activePeriod = 0; // 0=Daily, 1=Weekly, 2=Monthly
  DateTime _selectedDate = DateTime.now();
  bool _showAiInsight = true;

  // Local list of memory stream items to make adding interactive
  final List<Map<String, dynamic>> _memories = [
    {
      'date': 'YESTERDAY · 11:42 PM',
      'title': 'Neural Link Interface Hypothesis',
      'body': "The latency in current BCI technology isn't a hardware limitation, but a parsing error in neural-to-digital translation. Needs more investigation into adaptive wave-forms.",
      'icon': Icons.edit_note_rounded,
      'iconColor': AppColors.primary,
      'tags': ['Neuroscience', 'Idea'],
    },
    {
      'date': 'JUNE 12 · 02:15 PM',
      'title': 'Neo-Kyoto Concept Finalized',
      'body': 'Submission for the 2025 Biennale is complete. Total design hours: 142. Emotional state: Exhausted but fulfilled.',
      'icon': Icons.auto_awesome_rounded,
      'iconColor': AppColors.secondary,
      'tags': ['Architecture', 'Project'],
    },
    {
      'date': 'JUNE 05 · MORNING WALK',
      'title': 'Morning Walk Reflection',
      'body': '"Found a peculiar symmetry in the old oak today. Reminds me of the dendritic growth patterns in our silicon prototypes."',
      'icon': Icons.photo_library_outlined,
      'iconColor': const Color(0xFFDDB7FF),
      'tags': ['Nature', 'Symmetry'],
    },
  ];

  Widget _buildSubTabButton(int index, String label, IconData icon) {
    final isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16.0,
                color: isActive ? AppColors.background : AppColors.textSecondary,
              ),
              const SizedBox(width: 6.0),
              Text(
                label,
                style: AppTypography.caption(
                  color: isActive ? AppColors.background : AppColors.textSecondary,
                ).copyWith(
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddMemorySheet(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final tagsController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24.0), topRight: Radius.circular(24.0)),
        ),
        padding: EdgeInsets.only(
          left: 24.0,
          right: 24.0,
          top: 24.0,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32.0,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Capture Snippet', style: AppTypography.h2(color: AppColors.textPrimary)),
              const SizedBox(height: 20.0),
              JarvisInput(
                hintText: 'Title (e.g. Quantum Computing notes)',
                controller: titleController,
                autofocus: true,
              ),
              const SizedBox(height: 16.0),
              JarvisInput(
                hintText: 'Body / Thought content...',
                controller: bodyController,
                maxLines: 4,
              ),
              const SizedBox(height: 16.0),
              JarvisInput(
                hintText: 'Tags separated by comma (e.g. physics, research)',
                controller: tagsController,
              ),
              const SizedBox(height: 24.0),
              JarvisButton(
                text: 'Save Snippet',
                isFullWidth: true,
                onPressed: () {
                  if (titleController.text.trim().isEmpty || bodyController.text.trim().isEmpty) {
                    return;
                  }
                  final tagsList = tagsController.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
                  setState(() {
                    _memories.insert(0, {
                      'date': 'JUST NOW',
                      'title': titleController.text.trim(),
                      'body': bodyController.text.trim(),
                      'icon': Icons.edit_note_rounded,
                      'iconColor': AppColors.primary,
                      'tags': tagsList.isEmpty ? ['Idea'] : tagsList,
                    });
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVaultTab(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // AI Monthly Intelligence Card
        if (_showAiInsight) ...[
          JarvisCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.psychology_rounded, color: AppColors.primary, size: 20.0),
                        const SizedBox(width: 8.0),
                        Text(
                          'AI ANALYZING LIVE',
                          style: AppTypography.micro(color: AppColors.primary).copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _showAiInsight = false),
                      child: const Icon(Icons.close_rounded, color: AppColors.textTertiary, size: 18.0),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                Text(
                  'Your creative output increased by 42% this June. Most of your focus gravitated toward sustainable architecture and generative design. You captured 84 new snippets, primarily during late-night sessions.',
                  style: AppTypography.body(color: AppColors.textPrimary).copyWith(
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        minimumSize: Size.zero,
                        elevation: 0,
                      ),
                      onPressed: () {
                        ToastNotification.show(context, 'Generating vault intelligence report...');
                      },
                      child: const Text('View Report', style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12.0),
                    TextButton(
                      onPressed: () => setState(() => _showAiInsight = false),
                      child: const Text('Dismiss', style: TextStyle(color: AppColors.textTertiary, fontSize: 12.0)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),
        ],

        // Connections & Milestones Row
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 500;
            final cards = [
              // Card 1: Connection
              Expanded(
                flex: isWide ? 1 : 0,
                child: JarvisCard(
                  padding: 16.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 18.0),
                          const SizedBox(width: 8.0),
                          Text(
                            'Top Connection',
                            style: AppTypography.micro(color: AppColors.primary).copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'The idea "Fractal Cities" is now strongly linked to your "Urban Planning" vault.',
                        style: AppTypography.caption(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isWide) const SizedBox(height: 16.0),
              if (isWide) const SizedBox(width: 16.0),
              // Card 2: Milestone
              Expanded(
                flex: isWide ? 1 : 0,
                child: JarvisCard(
                  padding: 16.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.trending_up_rounded, color: AppColors.secondary, size: 18.0),
                          const SizedBox(width: 8.0),
                          Text(
                            'Skill Milestone',
                            style: AppTypography.micro(color: AppColors.secondary).copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        "You've mastered the 'Recursive Thinking' mental model after 12 related entries.",
                        style: AppTypography.caption(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ];

            return isWide
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: cards)
                : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: cards);
          },
        ),
        const SizedBox(height: 24.0),

        // Memory Stream Timeline
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Memory Stream',
              style: AppTypography.h3(color: AppColors.textPrimary).copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search_rounded, color: AppColors.primary),
              onPressed: () {
                ToastNotification.show(context, 'Search index syncing...');
              },
            ),
          ],
        ),
        const SizedBox(height: 12.0),

        ..._memories.map((m) => _buildStreamCard(context, m)),
      ],
    );
  }

  Widget _buildStreamCard(BuildContext context, Map<String, dynamic> memory) {
    final title = memory['title'] as String;
    final body = memory['body'] as String;
    final date = memory['date'] as String;
    final icon = memory['icon'] as IconData;
    final iconColor = memory['iconColor'] as Color;
    final tags = memory['tags'] as List<String>;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: JarvisCard(
        padding: 16.0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40.0,
              height: 40.0,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.0),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 20.0),
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        date,
                        style: AppTypography.micro(color: AppColors.textTertiary).copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    title,
                    style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    body,
                    style: AppTypography.caption(color: AppColors.textSecondary).copyWith(
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: tags.map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Text(
                        '#${t}',
                        style: AppTypography.micro(color: AppColors.primary).copyWith(
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // 1. Header
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
                              'Memory Vault',
                              style: AppTypography.h1(color: AppColors.textPrimary).copyWith(
                                fontSize: 26.0,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              _activeTab == 0
                                  ? 'AI connections and memory stream.'
                                  : 'Reflect on metrics and historical trends.',
                              style: AppTypography.caption(color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    
                    // Tab Selector: Review vs Vault
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
                          _buildSubTabButton(0, 'Review', Icons.psychology_rounded),
                          _buildSubTabButton(1, 'Vault', Icons.inventory_2_rounded),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Tab Content: Review (Existing stats view)
            if (_activeTab == 0) ...[
              // Period Toggle
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                sliver: SliverToBoxAdapter(
                  child: _PeriodToggle(
                    activePeriod: _activePeriod,
                    onChanged: (val) {
                      setState(() {
                        _activePeriod = val;
                      });
                    },
                  ),
                ),
              ),

              // Dynamic Period Content
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                sliver: SliverToBoxAdapter(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildActiveContent(),
                  ),
                ),
              ),
            ],

            // 3. Tab Content: Vault
            if (_activeTab == 1)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                sliver: SliverToBoxAdapter(
                  child: _buildVaultTab(context),
                ),
              ),

            // Bottom Spacer
            const SliverToBoxAdapter(
              child: SizedBox(height: 180.0),
            ),
          ],
        ),
      ),
      floatingActionButton: _activeTab != 1
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 96.0, right: 8.0),
              child: FloatingActionButton(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                elevation: 4.0,
                shape: const CircleBorder(),
                onPressed: () => _showAddMemorySheet(context),
                child: const Icon(Icons.edit_note_rounded, size: 28.0),
              ),
            ),
    );
  }

  Widget _buildActiveContent() {
    switch (_activePeriod) {
      case 1:
        return _buildWeeklyView();
      case 2:
        return _buildMonthlyView();
      case 0:
      default:
        return _buildDailyView();
    }
  }

  Widget _buildDailyView() {
    final dailyMemoryAsync = ref.watch(dailyMemoryProvider(_selectedDate));

    return Column(
      key: const ValueKey<String>('daily'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Calendar Grid Navigator
        _CalendarNavigator(
          selectedDate: _selectedDate,
          onDateSelected: (date) {
            setState(() {
              _selectedDate = date;
            });
          },
        ),
        const SizedBox(height: 20.0),

        // Date Display
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            DateHelpers.formatDate(_selectedDate),
            style: AppTypography.h3(color: AppColors.textPrimary).copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 12.0),

        // Memory Card
        dailyMemoryAsync.when(
          data: (memory) => _DailyMemoryDetailCard(memory: memory),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error loading memory: $err')),
        ),
      ],
    );
  }

  Widget _buildWeeklyView() {
    final weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    final weeklyMemoryAsync = ref.watch(weeklyMemoryProvider(weekStart));

    return Column(
      key: const ValueKey<String>('weekly'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            'Week of ${DateHelpers.formatDate(weekStart)}',
            style: AppTypography.h3(color: AppColors.textPrimary).copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 12.0),

        weeklyMemoryAsync.when(
          data: (data) => _WeeklyMemoryCard(data: data),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error loading weekly report: $err')),
        ),
      ],
    );
  }

  Widget _buildMonthlyView() {
    final monthlyMemoryAsync = ref.watch(monthlyMemoryProvider(_selectedDate));

    return Column(
      key: const ValueKey<String>('monthly'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            'Monthly Summary — ${DateHelpers.monthKey(_selectedDate)}',
            style: AppTypography.h3(color: AppColors.textPrimary).copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 12.0),

        monthlyMemoryAsync.when(
          data: (data) => _MonthlyMemoryCard(data: data),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error loading monthly report: $err')),
        ),
      ],
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  final int activePeriod;
  final ValueChanged<int> onChanged;

  const _PeriodToggle({required this.activePeriod, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.0,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          _buildSegment(0, 'Daily'),
          _buildSegment(1, 'Weekly'),
          _buildSegment(2, 'Monthly'),
        ],
      ),
    );
  }

  Widget _buildSegment(int index, String label) {
    final isActive = activePeriod == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Text(
            label,
            style: AppTypography.bodyMedium(
              color: isActive ? AppColors.background : AppColors.textSecondary,
            ).copyWith(
              fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarNavigator extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _CalendarNavigator({required this.selectedDate, required this.onDateSelected});

  @override
  Widget build(BuildContext context) {
    final weekDays = DateHelpers.daysInWeek(selectedDate);
    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return JarvisCard(
      padding: 12.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (index) {
          final day = weekDays[index];
          final isSelected = DateHelpers.isSameDay(selectedDate, day);
          final isToday = DateHelpers.isToday(day);

          return GestureDetector(
            onTap: () => onDateSelected(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: AppSpacing.buttonRadius,
                border: isToday && !isSelected
                    ? Border.all(color: AppColors.primary, width: 1.5)
                    : null,
              ),
              child: Column(
                children: [
                  Text(
                    dayLabels[index],
                    style: AppTypography.micro(
                      color: isSelected ? Colors.white : AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    '${day.day}',
                    style: AppTypography.bodyMedium(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DailyMemoryDetailCard extends StatelessWidget {
  final DailyMemoryModel memory;

  const _DailyMemoryDetailCard({required this.memory});

  @override
  Widget build(BuildContext context) {
    final hasMood = memory.mood != null;
    final moodEmoji = hasMood ? MoodRepository.moodEmoji(memory.mood!) : '—';
    final moodLabel = hasMood ? MoodRepository.moodLabel(memory.mood!) : 'Vibe unchecked';

    return JarvisCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mood Section
          Row(
            children: [
              Text(moodEmoji, style: const TextStyle(fontSize: 32.0)),
              const SizedBox(width: 14.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    moodLabel,
                    style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Today\'s general frequency',
                    style: AppTypography.caption(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20.0),
          
          Divider(color: AppColors.border.withOpacity(0.5)),
          const SizedBox(height: 16.0),

          // Completion Ratios
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildRatioGrid('Tasks done', '${memory.tasksCompleted}/${memory.tasksTotal}', '✅', AppColors.primary),
              _buildRatioGrid('Habits logged', '${memory.habitsCompleted}/${memory.habitsTotal}', '🔄', AppColors.success),
              _buildRatioGrid('Expenses log', CurrencyFormatter.format(memory.moneySpent), '💸', AppColors.error),
            ],
          ),
          
          // Highlights Section
          if (memory.highlights.isNotEmpty) ...[
            const SizedBox(height: 24.0),
            Divider(color: AppColors.border.withOpacity(0.5)),
            const SizedBox(height: 12.0),
            Text(
              'Daily Reflections',
              style: AppTypography.caption(color: AppColors.textSecondary).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8.0),
            ...memory.highlights.map((h) => Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✨', style: TextStyle(fontSize: 14.0)),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      h,
                      style: AppTypography.caption(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildRatioGrid(String label, String value, String icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(icon, style: const TextStyle(fontSize: 16.0)),
        ),
        const SizedBox(height: 8.0),
        Text(
          value,
          style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: AppTypography.micro(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _WeeklyMemoryCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _WeeklyMemoryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final completedTasks = data['tasksCompleted'] as int? ?? 0;
    final totalTasks = data['tasksTotal'] as int? ?? 0;
    final completedHabits = data['habitsCompleted'] as int? ?? 0;
    final totalHabits = data['habitsTotal'] as int? ?? 0;
    final totalSpent = data['totalSpent'] as double? ?? 0.0;
    final totalEarned = data['totalEarned'] as double? ?? 0.0;

    final habitConsistency = totalHabits > 0 ? ((completedHabits / totalHabits) * 100).toInt() : 0;

    return JarvisCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Weekly Performance Overview',
            style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20.0),

          Row(
            children: [
              Expanded(
                child: _buildMetricBlock(
                  'Tasks Success',
                  '$completedTasks/$totalTasks Done',
                  '🎯',
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: _buildMetricBlock(
                  'Habits Grid',
                  '$habitConsistency% Consistent',
                  '🔥',
                  AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20.0),

          Divider(color: AppColors.border.withOpacity(0.5)),
          const SizedBox(height: 16.0),

          // Custom Painter Sparkline Visualisation
          Text(
            'Weekly Habits consistency trend',
            style: AppTypography.caption(color: AppColors.textSecondary).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16.0),
          SizedBox(
            height: 60.0,
            child: CustomPaint(
              size: const Size(double.infinity, 60.0),
              painter: _SparklinePainter(),
            ),
          ),
          const SizedBox(height: 20.0),

          Divider(color: AppColors.border.withOpacity(0.5)),
          const SizedBox(height: 16.0),

          // Financial Net
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Total Savings:',
                style: AppTypography.body(color: AppColors.textSecondary),
              ),
              Text(
                CurrencyFormatter.format(totalEarned - totalSpent),
                style: AppTypography.bodyMedium(color: AppColors.success).copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBlock(String label, String value, String icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: AppSpacing.buttonRadius,
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16.0)),
              const SizedBox(width: 6.0),
              Text(label, style: AppTypography.micro(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 6.0),
          Text(
            value,
            style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyMemoryCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _MonthlyMemoryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final completedTasks = data['tasksCompleted'] as int? ?? 0;
    final totalTasks = data['tasksTotal'] as int? ?? 0;
    final completedHabits = data['habitsCompleted'] as int? ?? 0;
    final totalSpent = data['totalSpent'] as double? ?? 0.0;
    final totalEarned = data['totalEarned'] as double? ?? 0.0;

    return JarvisCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Monthly Narrative Review',
            style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16.0),

          // Rich summary text
          Text(
            'This month, your productivity remained consistent. You checked off $completedTasks out of $totalTasks pending items, and logged a total of $completedHabits atomic habit checkpoints.',
            style: AppTypography.body(color: AppColors.textPrimary).copyWith(
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20.0),

          Divider(color: AppColors.border.withOpacity(0.5)),
          const SizedBox(height: 16.0),

          _buildStatRow('Best Habit consistency', '📚 Reading book (92%)', '🏆'),
          _buildStatRow('Most productive day', 'Wednesday', '⚡'),
          _buildStatRow('Total Net Savings', CurrencyFormatter.format(totalEarned - totalSpent), '💰'),
          _buildStatRow('Vibe Vigor average', 'Good (😊)', '🎭'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, String icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16.0)),
          const SizedBox(width: 10.0),
          Text(label, style: AppTypography.caption(color: AppColors.textSecondary)),
          const Spacer(),
          Text(
            value,
            style: AppTypography.caption(color: AppColors.textPrimary).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    // Hardcode some simple mock points showing a lovely weekly consistency trend
    final points = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.16, size.height * 0.5),
      Offset(size.width * 0.32, size.height * 0.8),
      Offset(size.width * 0.48, size.height * 0.3),
      Offset(size.width * 0.64, size.height * 0.4),
      Offset(size.width * 0.8, size.height * 0.1),
      Offset(size.width, size.height * 0.2),
    ];

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // Draw lines
    canvas.drawPath(path, paint);

    // Draw dots at each peak
    final dotPaint = Paint()
      ..color = AppColors.primaryDark
      ..style = PaintingStyle.fill;

    for (final p in points) {
      canvas.drawCircle(p, 4.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
