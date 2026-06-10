import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/data/providers/user_provider.dart';
import 'package:jarvis/features/auth/data/models/user_model.dart';
import 'package:jarvis/shared/widgets/jarvis_button.dart';
import 'package:jarvis/shared/widgets/jarvis_card.dart';
import 'package:jarvis/shared/widgets/jarvis_input.dart';
import 'package:jarvis/shared/widgets/toast_notification.dart';
import 'package:jarvis/shared/widgets/gradient_background.dart';
import 'package:jarvis/core/utils/date_helpers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  String _selectedCurrency = '₹';
  String _selectedWakeTime = '07:00 AM';
  List<String> _selectedFocusAreas = [];
  bool _isInitialized = false;

  final List<String> _currencies = ['₹', r'$', '€', '£', '¥'];
  
  final List<String> _wakeTimes = [
    '05:00 AM',
    '06:00 AM',
    '07:00 AM',
    '08:00 AM',
    '09:00 AM',
    '10:00 AM',
  ];

  final List<Map<String, String>> _focusAreasData = [
    {'id': 'tasks', 'name': 'Tasks', 'emoji': '✅'},
    {'id': 'habits', 'name': 'Habits', 'emoji': '🔄'},
    {'id': 'money', 'name': 'Money', 'emoji': '💰'},
    {'id': 'journaling', 'name': 'Journaling', 'emoji': '📝'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _initFields(UserModel user) {
    if (_isInitialized) return;
    _nameController.text = user.name;
    _selectedCurrency = user.currency;
    
    // Parse wake time if present
    if (user.wakeTime != null) {
      // Map 24h format from model to 12h format or fallback
      final parts = user.wakeTime!.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]) ?? 7;
        final minute = int.tryParse(parts[1]) ?? 0;
        final suffix = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        _selectedWakeTime = '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $suffix';
      }
    }
    
    _selectedFocusAreas = List<String>.from(user.focusAreas);
    _isInitialized = true;
  }

  void _toggleFocusArea(String id) {
    setState(() {
      if (_selectedFocusAreas.contains(id)) {
        _selectedFocusAreas.remove(id);
      } else {
        _selectedFocusAreas.add(id);
      }
    });
  }

  void _save(UserModel currentUser) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ToastNotification.show(context, 'Name cannot be empty', type: 'error');
      return;
    }

    // Convert selected wake time '07:00 AM' to 24h '07:00'
    String wakeTime24h = '07:00';
    final match = RegExp(r'(\d+):(\d+)\s+(AM|PM)').firstMatch(_selectedWakeTime);
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      final minute = match.group(2)!;
      final suffix = match.group(3)!;
      if (suffix == 'PM' && hour < 12) hour += 12;
      if (suffix == 'AM' && hour == 12) hour = 0;
      wakeTime24h = '${hour.toString().padLeft(2, '0')}:$minute';
    }

    final updated = currentUser.copyWith(
      name: name,
      currency: _selectedCurrency,
      focusAreas: _selectedFocusAreas,
      wakeTime: () => wakeTime24h,
    );

    try {
      await ref.read(userProvider.notifier).updateUser(updated);
      if (mounted) {
        ToastNotification.show(context, 'Profile updated successfully!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ToastNotification.show(context, 'Failed to save changes: $e', type: 'error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Profile & Preferences', style: AppTypography.h2(color: AppColors.textPrimary)),
          backgroundColor: Colors.transparent,
          elevation: 0.0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        body: userAsync.when(
          data: (user) {
            if (user == null) {
              return const Center(child: Text('No user profile found.'));
            }
            _initFields(user);

            // Init initials
            final initials = user.name.isNotEmpty
                ? user.name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                : 'U';

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Header Card
                    JarvisCard(
                      child: Column(
                        children: [
                          Container(
                            width: 80.0,
                            height: 80.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.jarvisButtonGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 16.0,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              initials,
                              style: AppTypography.display(color: Colors.white).copyWith(
                                fontSize: 28.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          Text(
                            user.name,
                            style: AppTypography.h3(color: AppColors.textPrimary).copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'Joined ${DateHelpers.formatDate(user.joinDate)}',
                            style: AppTypography.caption(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    // Basic Information Section
                    Text(
                      'BASIC INFORMATION',
                      style: AppTypography.micro(color: AppColors.textSecondary).copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    JarvisCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          JarvisInput(
                            label: 'Display Name',
                            hintText: 'Enter your name',
                            controller: _nameController,
                          ),
                          const SizedBox(height: 16.0),
                          Text(
                            'Preferred Currency',
                            style: AppTypography.caption(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: _currencies.map((currency) {
                              final isSelected = _selectedCurrency == currency;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: JarvisButton(
                                    text: currency,
                                    isOutline: !isSelected,
                                    onPressed: () => setState(() => _selectedCurrency = currency),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    // App Focus & Routine Section
                    Text(
                      'APP FOCUS & ROUTINE',
                      style: AppTypography.micro(color: AppColors.textSecondary).copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    JarvisCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Focus Areas',
                            style: AppTypography.caption(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8.0),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: _focusAreasData.map((area) {
                              final id = area['id']!;
                              final isSelected = _selectedFocusAreas.contains(id);
                              return FilterChip(
                                label: Text('${area['emoji']} ${area['name']}'),
                                selected: isSelected,
                                selectedColor: AppColors.primary.withOpacity(0.25),
                                checkmarkColor: AppColors.primary,
                                labelStyle: AppTypography.caption(
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                ),
                                onSelected: (_) => _toggleFocusArea(id),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16.0),
                          Text(
                            'Typical Wake Time',
                            style: AppTypography.caption(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8.0),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _wakeTimes.map((time) {
                                final isSelected = _selectedWakeTime == time;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: JarvisButton(
                                    text: time,
                                    isOutline: !isSelected,
                                    onPressed: () => setState(() => _selectedWakeTime = time),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    // Developer Simulator Actions Section
                    Text(
                      'DEVELOPER SIMULATOR ACTIONS',
                      style: AppTypography.micro(color: AppColors.textSecondary).copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    JarvisCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.alarm_off_rounded, color: AppColors.textSecondary),
                            title: Text(
                              'Simulate Session Expiry',
                              style: AppTypography.body(color: AppColors.textPrimary),
                            ),
                            onTap: () => context.go('/session-expired'),
                          ),
                          const Divider(color: AppColors.border),
                          ListTile(
                            leading: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary),
                            title: Text(
                              'Simulate Account Lockout',
                              style: AppTypography.body(color: AppColors.textPrimary),
                            ),
                            onTap: () => context.go('/locked'),
                          ),
                          const Divider(color: AppColors.border),
                          ListTile(
                            leading: const Icon(Icons.cloud_off_rounded, color: AppColors.textSecondary),
                            title: Text(
                              'Simulate Offline State',
                              style: AppTypography.body(color: AppColors.textPrimary),
                            ),
                            onTap: () => context.go('/network-error'),
                          ),
                          const Divider(color: AppColors.border),
                          ListTile(
                            leading: const Icon(Icons.error_outline_rounded, color: AppColors.textSecondary),
                            title: Text(
                              'Simulate Generic Error',
                              style: AppTypography.body(color: AppColors.textPrimary),
                            ),
                            onTap: () => context.go('/generic-error'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32.0),
                    // Save Changes Button
                    JarvisButton(
                      text: 'Save Changes',
                      isFullWidth: true,
                      onPressed: () => _save(user),
                    ),
                    const SizedBox(height: 12.0),
                    // Sign Out Button
                    JarvisButton(
                      text: 'Sign Out & Lock Session',
                      isFullWidth: true,
                      isOutline: true,
                      onPressed: () async {
                        await ref.read(userProvider.notifier).signOut();
                        if (mounted) {
                          context.go('/welcome');
                        }
                      },
                    ),
                    const SizedBox(height: 48.0),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}
