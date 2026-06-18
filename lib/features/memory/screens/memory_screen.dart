import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_spacing.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/core/utils/currency_formatter.dart';
import 'package:jarvis/core/utils/date_helpers.dart';
import 'package:jarvis/core/utils/id_generator.dart';
import 'package:jarvis/features/memory/data/models/daily_memory_model.dart';
import 'package:jarvis/features/mood/domain/repositories/mood_repository.dart';
import 'package:jarvis/data/providers/memory_provider.dart';
import 'package:jarvis/data/providers/person_provider.dart';
import 'package:jarvis/data/providers/long_term_memory_provider.dart';
import 'package:jarvis/data/models/person_model.dart';
import 'package:jarvis/data/models/long_term_memory_model.dart';
import 'package:jarvis/shared/widgets/jarvis_card.dart';
import 'package:jarvis/shared/widgets/jarvis_button.dart';
import 'package:jarvis/shared/widgets/jarvis_input.dart';
import 'package:jarvis/shared/widgets/jarvis_chip.dart';
import 'package:jarvis/shared/widgets/toast_notification.dart';
import 'package:jarvis/features/tasks/data/models/task_model.dart';
import 'package:jarvis/data/providers/task_provider.dart';
import 'package:jarvis/core/services/notification_service.dart';

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

  // Vault Sub-tab variables
  int _vaultSubTab = 0; // 0 = Memories, 1 = People
  String _searchQuery = '';
  String _selectedTypeFilter = 'all';

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

  Widget _buildVaultSubTabButton(int index, String label, IconData icon) {
    final isActive = _vaultSubTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _vaultSubTab = index),
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

  IconData _getMemoryTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'milestone':
        return Icons.emoji_events_rounded;
      case 'travel':
        return Icons.flight_takeoff_rounded;
      case 'career':
        return Icons.work_rounded;
      case 'purchase':
        return Icons.shopping_bag_rounded;
      case 'health':
        return Icons.local_hospital_rounded;
      case 'financial':
        return Icons.monetization_on_rounded;
      case 'people_shared':
        return Icons.people_rounded;
      default:
        return Icons.edit_note_rounded;
    }
  }

  Color _getMemoryTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'milestone':
        return AppColors.warningLight;
      case 'travel':
        return AppColors.secondary;
      case 'career':
        return const Color(0xFFC0C1FF);
      case 'purchase':
        return const Color(0xFFFFB4AB);
      case 'health':
        return const Color(0xFF7BC47F);
      case 'financial':
        return const Color(0xFFE8B44C);
      case 'people_shared':
        return const Color(0xFFC4A0E8);
      default:
        return AppColors.primary;
    }
  }

  String _getBirthdayCountdownText(DateTime? birthday) {
    if (birthday == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var nextBday = DateTime(today.year, birthday.month, birthday.day);
    if (nextBday.isBefore(today)) {
      nextBday = DateTime(today.year + 1, birthday.month, birthday.day);
    }
    final difference = nextBday.difference(today).inDays;
    if (difference == 0) {
      return 'Today! 🎂';
    } else if (difference == 1) {
      return 'Tomorrow! 🎈';
    } else {
      return 'in $difference days';
    }
  }

  String _getAnniversaryCountdownText(DateTime? anniversary) {
    if (anniversary == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var nextAnniv = DateTime(today.year, anniversary.month, anniversary.day);
    if (nextAnniv.isBefore(today)) {
      nextAnniv = DateTime(today.year + 1, anniversary.month, anniversary.day);
    }
    final difference = nextAnniv.difference(today).inDays;
    if (difference == 0) {
      return 'Today! 💍';
    } else if (difference == 1) {
      return 'Tomorrow! ✨';
    } else {
      return 'in $difference days';
    }
  }

  void _showAddMemorySheet(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final placeController = TextEditingController();
    final tagsController = TextEditingController();
    String selectedType = 'milestone';
    DateTime selectedDate = DateTime.now();
    List<String> selectedPeopleIds = [];

    final peopleState = ref.read(personProvider);
    final List<PersonModel> allPeople = peopleState.maybeWhen(
      data: (list) => list,
      orElse: () => [],
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
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
                Text('Log New Memory', style: AppTypography.h2(color: AppColors.textPrimary)),
                const SizedBox(height: 20.0),
                
                JarvisInput(
                  hintText: 'Memory Title (e.g. Neo-Kyoto Design)',
                  controller: titleController,
                  autofocus: true,
                ),
                const SizedBox(height: 16.0),
                
                JarvisInput(
                  hintText: 'Describe the memory...',
                  controller: bodyController,
                  maxLines: 3,
                ),
                const SizedBox(height: 16.0),

                Text('Memory Type', style: AppTypography.caption(color: AppColors.textSecondary).copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8.0),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'milestone', 'travel', 'career', 'purchase', 'health', 'financial', 'people_shared'
                    ].map((type) {
                      final isSelected = selectedType == type;
                      final label = type == 'people_shared'
                          ? 'People'
                          : '${type[0].toUpperCase()}${type.substring(1)}';
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: JarvisChip(
                          label: label,
                          isSelected: isSelected,
                          onTap: () {
                            setSheetState(() {
                              selectedType = type;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16.0),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Date of Event', style: AppTypography.body(color: AppColors.textPrimary)),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today_rounded, size: 16.0, color: AppColors.primary),
                      label: Text(DateHelpers.formatDate(selectedDate), style: const TextStyle(color: AppColors.primary)),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppColors.primary,
                                  onPrimary: AppColors.background,
                                  surface: AppColors.surface,
                                  onSurface: AppColors.textPrimary,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setSheetState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),

                JarvisInput(
                  hintText: 'Place / Location (Optional)',
                  controller: placeController,
                ),
                const SizedBox(height: 16.0),

                JarvisInput(
                  hintText: 'Tags (e.g. travel, custom - Optional)',
                  controller: tagsController,
                ),
                const SizedBox(height: 16.0),

                if (allPeople.isNotEmpty) ...[
                  Text('Connect People', style: AppTypography.caption(color: AppColors.textSecondary).copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: allPeople.map((person) {
                      final isSelected = selectedPeopleIds.contains(person.id);
                      return JarvisChip(
                        label: person.name,
                        isSelected: isSelected,
                        onTap: () {
                          setSheetState(() {
                            if (isSelected) {
                              selectedPeopleIds.remove(person.id);
                            } else {
                              selectedPeopleIds.add(person.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20.0),
                ],

                JarvisButton(
                  text: 'Save Memory Log',
                  isFullWidth: true,
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty || bodyController.text.trim().isEmpty) {
                      ToastNotification.show(context, 'Title and description are required', type: 'error');
                      return;
                    }
                    final tagsList = tagsController.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
                    
                    final newMemory = LongTermMemoryModel(
                      id: IdGenerator.generate(),
                      title: titleController.text.trim(),
                      body: bodyController.text.trim(),
                      type: selectedType,
                      date: selectedDate,
                      place: placeController.text.trim().isEmpty ? null : placeController.text.trim(),
                      tags: tagsList,
                      connectedPeopleIds: selectedPeopleIds,
                      createdAt: DateTime.now(),
                    );

                    final task = TaskModel(
                      id: IdGenerator.generate(),
                      title: "Memory: ${titleController.text.trim()}",
                      description: 'Quick logged via Memory Screen.',
                      dueDate: selectedDate,
                      dueTime: '09:00',
                      priority: 0,
                      completed: true,
                      emoji: '🧠',
                      tagId: 'Memory',
                      createdAt: DateTime.now(),
                    );
                    await ref.read(taskProvider.notifier).addTask(task);
                    ref.invalidate(todayTasksProvider);

                    await ref.read(longTermMemoryProvider.notifier).saveMemory(newMemory);
                    Navigator.pop(context);
                    ToastNotification.show(context, 'Memory log saved successfully!');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddPersonSheet(BuildContext context) {
    final nameController = TextEditingController();
    final tagsController = TextEditingController();
    final notesController = TextEditingController();
    DateTime? birthdayDate;
    DateTime? anniversaryDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
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
                Text('Add New Contact', style: AppTypography.h2(color: AppColors.textPrimary)),
                const SizedBox(height: 20.0),
                
                JarvisInput(
                  hintText: 'Contact Name (e.g. Aravind)',
                  controller: nameController,
                  autofocus: true,
                ),
                const SizedBox(height: 16.0),
                
                JarvisInput(
                  hintText: 'Relationship Tags (e.g. Family, Friend)',
                  controller: tagsController,
                ),
                const SizedBox(height: 16.0),

                JarvisInput(
                  hintText: 'Relationship Notes...',
                  controller: notesController,
                  maxLines: 2,
                ),
                const SizedBox(height: 16.0),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cake_rounded, size: 16.0, color: AppColors.warningLight),
                        const SizedBox(width: 8.0),
                        Text('Birthday (Optional)', style: AppTypography.body(color: AppColors.textPrimary)),
                      ],
                    ),
                    TextButton(
                      child: Text(
                        birthdayDate == null ? 'Select Date' : DateHelpers.formatDate(birthdayDate!),
                        style: const TextStyle(color: AppColors.primary),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2100),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppColors.primary,
                                  onPrimary: AppColors.background,
                                  surface: AppColors.surface,
                                  onSurface: AppColors.textPrimary,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setSheetState(() {
                            birthdayDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.favorite_rounded, size: 16.0, color: AppColors.error),
                        const SizedBox(width: 8.0),
                        Text('Anniversary (Optional)', style: AppTypography.body(color: AppColors.textPrimary)),
                      ],
                    ),
                    TextButton(
                      child: Text(
                        anniversaryDate == null ? 'Select Date' : DateHelpers.formatDate(anniversaryDate!),
                        style: const TextStyle(color: AppColors.primary),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2100),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppColors.primary,
                                  onPrimary: AppColors.background,
                                  surface: AppColors.surface,
                                  onSurface: AppColors.textPrimary,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setSheetState(() {
                            anniversaryDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24.0),

                JarvisButton(
                  text: 'Save Contact Profile',
                  isFullWidth: true,
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ToastNotification.show(context, 'Contact Name is required', type: 'error');
                      return;
                    }
                    final tagsList = tagsController.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
                    
                    final newPerson = PersonModel(
                      id: IdGenerator.generate(),
                      name: name,
                      birthday: birthdayDate,
                      anniversary: anniversaryDate,
                      relationshipNotes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                      tags: tagsList,
                      createdAt: DateTime.now(),
                    );

                    await ref.read(personProvider.notifier).savePerson(newPerson);

                    if (birthdayDate != null) {
                      final now = DateTime.now();
                      DateTime eventDate = DateTime(now.year, birthdayDate!.month, birthdayDate!.day);
                      if (eventDate.isBefore(DateTime(now.year, now.month, now.day))) {
                        eventDate = DateTime(now.year + 1, birthdayDate!.month, birthdayDate!.day);
                      }

                      final mainEvent = TaskModel(
                        id: IdGenerator.generate(),
                        title: "$name's Birthday: ${DateHelpers.formatDate(birthdayDate!)}",
                        description: "Annual recurring birthday event for $name.",
                        dueDate: eventDate,
                        dueTime: '09:00',
                        priority: 3,
                        completed: false,
                        emoji: '🎁',
                        tagId: 'Relationship',
                        createdAt: DateTime.now(),
                      );
                      await ref.read(taskProvider.notifier).addTask(mainEvent);

                      final alertOffsets = [
                        {'offset': const Duration(days: 7), 'label': '7-Day Alert', 'emoji': '🔔'},
                        {'offset': const Duration(days: 1), 'label': '1-Day Alert', 'emoji': '🔔'},
                        {'offset': Duration.zero, 'label': 'Morning Alert', 'emoji': '⏰'},
                      ];

                      for (final alert in alertOffsets) {
                        final alertDate = eventDate.subtract(alert['offset'] as Duration);
                        if (alertDate.isAfter(DateTime.now())) {
                          final alertTask = TaskModel(
                            id: IdGenerator.generate(),
                            title: "$name's Birthday (${alert['label']})",
                            description: "Reminder alert for $name's upcoming birthday.",
                            dueDate: alertDate,
                            dueTime: '09:00',
                            priority: 2,
                            completed: false,
                            emoji: alert['emoji'] as String,
                            tagId: 'Relationship',
                            createdAt: DateTime.now(),
                          );
                          await ref.read(taskProvider.notifier).addTask(alertTask);
                        }
                      }

                      try {
                        await NotificationService().scheduleBirthdayNotification(
                          name,
                          'birthday',
                          eventDate,
                        );
                      } catch (e) {
                        debugPrint("Notification schedule failed: $e");
                      }
                    }

                    if (anniversaryDate != null) {
                      final now = DateTime.now();
                      DateTime eventDate = DateTime(now.year, anniversaryDate!.month, anniversaryDate!.day);
                      if (eventDate.isBefore(DateTime(now.year, now.month, now.day))) {
                        eventDate = DateTime(now.year + 1, anniversaryDate!.month, anniversaryDate!.day);
                      }

                      final mainEvent = TaskModel(
                        id: IdGenerator.generate(),
                        title: "$name's Anniversary: ${DateHelpers.formatDate(anniversaryDate!)}",
                        description: "Annual recurring anniversary event for $name.",
                        dueDate: eventDate,
                        dueTime: '09:00',
                        priority: 3,
                        completed: false,
                        emoji: '💍',
                        tagId: 'Relationship',
                        createdAt: DateTime.now(),
                      );
                      await ref.read(taskProvider.notifier).addTask(mainEvent);

                      final alertOffsets = [
                        {'offset': const Duration(days: 7), 'label': '7-Day Alert', 'emoji': '🔔'},
                        {'offset': const Duration(days: 1), 'label': '1-Day Alert', 'emoji': '🔔'},
                        {'offset': Duration.zero, 'label': 'Morning Alert', 'emoji': '⏰'},
                      ];

                      for (final alert in alertOffsets) {
                        final alertDate = eventDate.subtract(alert['offset'] as Duration);
                        if (alertDate.isAfter(DateTime.now())) {
                          final alertTask = TaskModel(
                            id: IdGenerator.generate(),
                            title: "$name's Anniversary (${alert['label']})",
                            description: "Reminder alert for $name's upcoming anniversary.",
                            dueDate: alertDate,
                            dueTime: '09:00',
                            priority: 2,
                            completed: false,
                            emoji: alert['emoji'] as String,
                            tagId: 'Relationship',
                            createdAt: DateTime.now(),
                          );
                          await ref.read(taskProvider.notifier).addTask(alertTask);
                        }
                      }

                      try {
                        await NotificationService().scheduleBirthdayNotification(
                          name,
                          'anniversary',
                          eventDate,
                        );
                      } catch (e) {
                        debugPrint("Notification schedule failed: $e");
                      }
                    }

                    ref.invalidate(todayTasksProvider);
                    Navigator.pop(context);
                    ToastNotification.show(context, 'Contact profile saved successfully!');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInspectMemorySheet(BuildContext context, LongTermMemoryModel memory, List<String> connectedNames) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24.0), topRight: Radius.circular(24.0)),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: _getMemoryTypeColor(memory.type).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    memory.type.toUpperCase(),
                    style: AppTypography.micro(color: _getMemoryTypeColor(memory.type)).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: Text('Delete Memory?', style: AppTypography.h3(color: AppColors.textPrimary)),
                        content: Text('Are you sure you want to delete this memory record?', style: AppTypography.body(color: AppColors.textSecondary)),
                        actions: [
                          TextButton(
                            child: const Text('Cancel', style: TextStyle(color: AppColors.textTertiary)),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                          TextButton(
                            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                            onPressed: () {
                              ref.read(longTermMemoryProvider.notifier).deleteMemory(memory.id);
                              Navigator.pop(ctx); // Close Dialog
                              Navigator.pop(context); // Close BottomSheet
                              ToastNotification.show(context, 'Memory deleted');
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Text(memory.title, style: AppTypography.h2(color: AppColors.textPrimary)),
            const SizedBox(height: 8.0),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 14.0, color: AppColors.textTertiary),
                const SizedBox(width: 6.0),
                Text(
                  DateHelpers.formatDate(memory.date),
                  style: AppTypography.caption(color: AppColors.textTertiary),
                ),
                if (memory.place != null && memory.place!.isNotEmpty) ...[
                  const SizedBox(width: 16.0),
                  const Icon(Icons.location_on_outlined, size: 14.0, color: AppColors.textTertiary),
                  const SizedBox(width: 6.0),
                  Text(
                    memory.place!,
                    style: AppTypography.caption(color: AppColors.textTertiary),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20.0),
            Text(
              memory.body,
              style: AppTypography.body(color: AppColors.textSecondary).copyWith(height: 1.5),
            ),
            if (connectedNames.isNotEmpty) ...[
              const SizedBox(height: 20.0),
              Text('Connected People', style: AppTypography.caption(color: AppColors.textTertiary).copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: connectedNames.map((name) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 12.0, color: AppColors.primary),
                      const SizedBox(width: 4.0),
                      Text(name, style: AppTypography.caption(color: AppColors.primary)),
                    ],
                  ),
                )).toList(),
              ),
            ],
            if (memory.tags.isNotEmpty) ...[
              const SizedBox(height: 20.0),
              Text('Tags', style: AppTypography.caption(color: AppColors.textTertiary).copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: memory.tags.map((t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text('#$t', style: AppTypography.caption(color: AppColors.textSecondary)),
                )).toList(),
              ),
            ],
            const SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }

  void _showInspectPersonSheet(BuildContext context, PersonModel person) {
    final memoriesState = ref.watch(longTermMemoryProvider);
    final connectedMemories = memoriesState.maybeWhen(
      data: (list) => list.where((m) => m.connectedPeopleIds.contains(person.id)).toList(),
      orElse: () => <LongTermMemoryModel>[],
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24.0), topRight: Radius.circular(24.0)),
        ),
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Contact Profile',
                    style: AppTypography.caption(color: AppColors.textTertiary).copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppColors.surface,
                          title: Text('Delete Contact?', style: AppTypography.h3(color: AppColors.textPrimary)),
                          content: Text('Are you sure you want to delete this contact and all their schedule alerts?', style: AppTypography.body(color: AppColors.textSecondary)),
                          actions: [
                            TextButton(
                              child: const Text('Cancel', style: TextStyle(color: AppColors.textTertiary)),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                            TextButton(
                              child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                              onPressed: () {
                                ref.read(personProvider.notifier).deletePerson(person.id);
                                Navigator.pop(ctx); // Close Dialog
                                Navigator.pop(context); // Close BottomSheet
                                ToastNotification.show(context, 'Contact deleted');
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              Text(person.name, style: AppTypography.h1(color: AppColors.textPrimary)),
              if (person.tags.isNotEmpty) ...[
                const SizedBox(height: 8.0),
                Wrap(
                  spacing: 6.0,
                  children: person.tags.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(t, style: AppTypography.caption(color: AppColors.primary).copyWith(fontWeight: FontWeight.bold)),
                  )).toList(),
                ),
              ],
              const SizedBox(height: 20.0),
              if (person.birthday != null) ...[
                _buildInfoRow(
                  Icons.cake_rounded,
                  'Birthday',
                  '${DateHelpers.formatDate(person.birthday!)} (${_getBirthdayCountdownText(person.birthday)})',
                  AppColors.warningLight,
                ),
                const SizedBox(height: 12.0),
              ],
              if (person.anniversary != null) ...[
                _buildInfoRow(
                  Icons.favorite_rounded,
                  'Anniversary',
                  '${DateHelpers.formatDate(person.anniversary!)} (${_getAnniversaryCountdownText(person.anniversary)})',
                  AppColors.error,
                ),
                const SizedBox(height: 12.0),
              ],
              if (person.relationshipNotes != null && person.relationshipNotes!.isNotEmpty) ...[
                const SizedBox(height: 8.0),
                Text(
                  'Notes',
                  style: AppTypography.caption(color: AppColors.textTertiary).copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6.0),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    person.relationshipNotes!,
                    style: AppTypography.body(color: AppColors.textSecondary).copyWith(height: 1.4),
                  ),
                ),
              ],
              const SizedBox(height: 24.0),
              Text(
                'Shared Memories',
                style: AppTypography.caption(color: AppColors.textTertiary).copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10.0),
              if (connectedMemories.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  alignment: Alignment.center,
                  child: Text(
                    'No memories connected with ${person.name} yet.',
                    style: AppTypography.caption(color: AppColors.textTertiary),
                  ),
                )
              else
                ...connectedMemories.map((m) {
                  final icon = _getMemoryTypeIcon(m.type);
                  final color = _getMemoryTypeColor(m.type);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: color, size: 18.0),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.title,
                                style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                DateHelpers.formatDate(m.date),
                                style: AppTypography.micro(color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 18.0, color: iconColor),
        const SizedBox(width: 10.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.micro(color: AppColors.textTertiary)),
            const SizedBox(height: 2.0),
            Text(value, style: AppTypography.body(color: AppColors.textPrimary).copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildMemoryCard(BuildContext context, LongTermMemoryModel memory, List<PersonModel> people) {
    final icon = _getMemoryTypeIcon(memory.type);
    final iconColor = _getMemoryTypeColor(memory.type);

    final connectedNames = people
        .where((p) => memory.connectedPeopleIds.contains(p.id))
        .map((p) => p.name)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: () => _showInspectMemorySheet(context, memory, connectedNames),
        child: JarvisCard(
          padding: 16.0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44.0,
                height: 44.0,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 22.0),
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
                          DateHelpers.formatDate(memory.date).toUpperCase(),
                          style: AppTypography.micro(color: AppColors.textTertiary).copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        if (memory.place != null && memory.place!.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 12.0, color: AppColors.textTertiary),
                              const SizedBox(width: 2.0),
                              Text(
                                memory.place!,
                                style: AppTypography.micro(color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      memory.title,
                      style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      memory.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption(color: AppColors.textSecondary).copyWith(
                        height: 1.4,
                      ),
                    ),
                    if (connectedNames.isNotEmpty || memory.tags.isNotEmpty) ...[
                      const SizedBox(height: 10.0),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: [
                          ...connectedNames.map((name) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_outline_rounded, size: 10.0, color: AppColors.primary),
                                const SizedBox(width: 4.0),
                                Text(
                                  name,
                                  style: AppTypography.micro(color: AppColors.primary).copyWith(
                                    fontSize: 10.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )),
                          ...memory.tags.map((t) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            child: Text(
                              '#$t',
                              style: AppTypography.micro(color: AppColors.textTertiary).copyWith(
                                fontSize: 10.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonCard(BuildContext context, PersonModel person) {
    final initials = person.name.trim().isNotEmpty
        ? person.name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : '?';

    final bdayCountdown = _getBirthdayCountdownText(person.birthday);
    final annivCountdown = _getAnniversaryCountdownText(person.anniversary);

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: () => _showInspectPersonSheet(context, person),
        child: JarvisCard(
          padding: 16.0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48.0,
                height: 48.0,
                decoration: BoxDecoration(
                  gradient: AppColors.moodArcGradient,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: AppTypography.bodyMedium(color: Colors.white).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                          person.name,
                          style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (person.tags.isNotEmpty)
                          Wrap(
                            spacing: 4.0,
                            children: person.tags.map((t) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                t,
                                style: AppTypography.micro(color: AppColors.primary).copyWith(
                                  fontSize: 9.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )).toList(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    if (person.relationshipNotes != null && person.relationshipNotes!.isNotEmpty)
                      Text(
                        person.relationshipNotes!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption(color: AppColors.textSecondary),
                      ),
                    if (person.birthday != null || person.anniversary != null) ...[
                      const SizedBox(height: 10.0),
                      Row(
                        children: [
                          if (person.birthday != null) ...[
                            const Icon(Icons.cake_rounded, size: 13.0, color: AppColors.warningLight),
                            const SizedBox(width: 4.0),
                            Expanded(
                              child: Text(
                                '${DateHelpers.formatDate(person.birthday!)} ($bdayCountdown)',
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.micro(color: AppColors.textTertiary),
                              ),
                            ),
                          ],
                          if (person.birthday != null && person.anniversary != null)
                            const SizedBox(width: 16.0),
                          if (person.anniversary != null) ...[
                            const Icon(Icons.favorite_rounded, size: 13.0, color: AppColors.error),
                            const SizedBox(width: 4.0),
                            Expanded(
                              child: Text(
                                '${DateHelpers.formatDate(person.anniversary!)} ($annivCountdown)',
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.micro(color: AppColors.textTertiary),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemoriesSubTab() {
    final memoriesState = ref.watch(longTermMemoryProvider);
    final peopleState = ref.watch(personProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        JarvisInput(
          hintText: 'Search memories by title, text, or tags...',
          prefix: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Icon(Icons.search_rounded, color: AppColors.textTertiary),
          ),
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
        ),
        const SizedBox(height: 16.0),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              'all', 'milestone', 'travel', 'career', 'purchase', 'health', 'financial', 'people_shared'
            ].map((type) {
              final isSelected = _selectedTypeFilter == type;
              final label = type == 'all'
                  ? 'All'
                  : type == 'people_shared'
                      ? 'People'
                      : '${type[0].toUpperCase()}${type.substring(1)}';
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: JarvisChip(
                  label: label,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedTypeFilter = type;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20.0),

        Text(
          'Memory Stream',
          style: AppTypography.h3(color: AppColors.textPrimary).copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12.0),

        memoriesState.when(
          data: (memories) {
            final filtered = memories.where((m) {
              final matchesType = _selectedTypeFilter == 'all' || m.type == _selectedTypeFilter;
              final matchesQuery = _searchQuery.isEmpty ||
                  m.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  m.body.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  m.tags.any((t) => t.toLowerCase().contains(_searchQuery.toLowerCase()));
              return matchesType && matchesQuery;
            }).toList();

            filtered.sort((a, b) => b.date.compareTo(a.date));

            if (filtered.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const Text('🧠', style: TextStyle(fontSize: 40.0)),
                    const SizedBox(height: 12.0),
                    Text(
                      'No matching memories found.',
                      style: AppTypography.body(color: AppColors.textTertiary),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Try typing "Visited Kyoto temple" in the command bar.',
                      style: AppTypography.caption(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              );
            }

            final List<PersonModel> people = peopleState.maybeWhen(
              data: (list) => list,
              orElse: () => [],
            );

            return Column(
              children: filtered.map((m) => _buildMemoryCard(context, m, people)).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0),
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
            ),
          ),
          error: (err, _) => Center(child: Text('Error loading memories: $err', style: const TextStyle(color: AppColors.error))),
        ),
      ],
    );
  }

  Widget _buildPeopleSubTab() {
    final peopleState = ref.watch(personProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Relationship Circles',
              style: AppTypography.h3(color: AppColors.textPrimary).copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),

        peopleState.when(
          data: (people) {
            if (people.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const Text('👥', style: TextStyle(fontSize: 40.0)),
                    const SizedBox(height: 12.0),
                    Text(
                      'Your network is empty.',
                      style: AppTypography.body(color: AppColors.textTertiary),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Try typing "Aravind birthday is June 18" in the command bar.',
                      style: AppTypography.caption(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: people.map((p) => _buildPersonCard(context, p)).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0),
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
            ),
          ),
          error: (err, _) => Center(child: Text('Error loading contacts: $err', style: const TextStyle(color: AppColors.error))),
        ),
      ],
    );
  }

  Widget _buildVaultTab(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                      child: const Text('Dismiss', style: const TextStyle(color: AppColors.textTertiary, fontSize: 12.0)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),
        ],

        Container(
          height: 44.0,
          margin: const EdgeInsets.only(bottom: 20.0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22.0),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          padding: const EdgeInsets.all(4.0),
          child: Row(
            children: [
              _buildVaultSubTabButton(0, 'Memories', Icons.bubble_chart_rounded),
              _buildVaultSubTabButton(1, 'People', Icons.people_alt_rounded),
            ],
          ),
        ),

        _vaultSubTab == 0 ? _buildMemoriesSubTab() : _buildPeopleSubTab(),
      ],
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

            if (_activeTab == 0) ...[
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

            if (_activeTab == 1)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                sliver: SliverToBoxAdapter(
                  child: _buildVaultTab(context),
                ),
              ),

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
                onPressed: () {
                  if (_vaultSubTab == 0) {
                    _showAddMemorySheet(context);
                  } else {
                    _showAddPersonSheet(context);
                  }
                },
                child: Icon(
                  _vaultSubTab == 0 ? Icons.edit_note_rounded : Icons.person_add_rounded,
                  size: 28.0,
                ),
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
        _CalendarNavigator(
          selectedDate: _selectedDate,
          onDateSelected: (date) {
            setState(() {
              _selectedDate = date;
            });
          },
        ),
        const SizedBox(height: 20.0),

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

        dailyMemoryAsync.when(
          data: (memory) => _DailyMemoryDetailCard(memory: memory),
          loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary))),
          error: (err, _) => Center(child: Text('Error loading memory: $err', style: const TextStyle(color: AppColors.error))),
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
          loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary))),
          error: (err, _) => Center(child: Text('Error loading weekly report: $err', style: const TextStyle(color: AppColors.error))),
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
          loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary))),
          error: (err, _) => Center(child: Text('Error loading monthly report: $err', style: const TextStyle(color: AppColors.error))),
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

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildRatioGrid('Tasks done', '${memory.tasksCompleted}/${memory.tasksTotal}', '✅', AppColors.primary),
              _buildRatioGrid('Habits logged', '${memory.habitsCompleted}/${memory.habitsTotal}', '🔄', AppColors.success),
              _buildRatioGrid('Expenses log', CurrencyFormatter.format(memory.moneySpent), '💸', AppColors.error),
            ],
          ),
          
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

    canvas.drawPath(path, paint);

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
