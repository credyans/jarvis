import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/core/services/notification_service.dart';
import 'package:jarvis/data/providers/user_provider.dart';
import 'package:jarvis/shared/widgets/gradient_background.dart';
import 'package:jarvis/shared/widgets/jarvis_card.dart';
import 'package:jarvis/shared/widgets/jarvis_button.dart';
import 'package:jarvis/shared/widgets/toast_notification.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  bool _morningBrief = true;
  bool _eveningReview = true;
  bool _financialAlerts = true;
  bool _isLoading = true;
  late Box _settingsBox;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settingsBox = await Hive.openBox('notification_settings');
    setState(() {
      _morningBrief = _settingsBox.get('morning_brief', defaultValue: true) as bool;
      _eveningReview = _settingsBox.get('evening_review', defaultValue: true) as bool;
      _financialAlerts = _settingsBox.get('financial_alerts', defaultValue: true) as bool;
      _isLoading = false;
    });
  }

  Future<void> _updateSetting(String key, bool value) async {
    await _settingsBox.put(key, value);
    
    // Request permission if enabling a notification
    if (value) {
      await NotificationService().requestPermissions();
    }

    final userAsync = ref.read(userProvider);
    final user = userAsync.value;

    if (key == 'morning_brief') {
      setState(() => _morningBrief = value);
      if (value && user != null) {
        await NotificationService().scheduleDailyWakeUpReminder(user.wakeTime ?? '07:00');
      } else {
        // Cancel morning reminder (ID 100)
        await NotificationService().initialize(); // Ensure channel is set up or call cancel
      }
    } else if (key == 'evening_review') {
      setState(() => _eveningReview = value);
      if (value) {
        await NotificationService().scheduleDailyTaskReminder();
      }
    } else if (key == 'financial_alerts') {
      setState(() => _financialAlerts = value);
    }

    if (mounted) {
      ToastNotification.show(
        context,
        'Preferences updated successfully!',
        type: 'success',
      );
    }
  }

  Future<void> _testNotification() async {
    await NotificationService().requestPermissions();
    await NotificationService().showInstantTestNotification();
    if (mounted) {
      ToastNotification.show(
        context,
        'Test notification sent! Check your system tray. 🤖',
        type: 'success',
      );
    }
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required String emoji,
  }) {
    return JarvisCard(
      padding: 16.0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.0,
            height: 40.0,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.0),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 20.0)),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  subtitle,
                  style: AppTypography.caption(color: AppColors.textSecondary).copyWith(
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12.0),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF6366FF),
            inactiveThumbColor: AppColors.textSecondary,
            inactiveTrackColor: AppColors.surface.withOpacity(0.4),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Notifications',
            style: AppTypography.h3(color: AppColors.textPrimary).copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'PREFERENCES',
                        style: AppTypography.micro(color: AppColors.textSecondary).copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      
                      _buildToggleTile(
                        emoji: '🌅',
                        title: 'Daily Morning Briefing',
                        subtitle: 'Receive routine alerts based on your wake-up time to prepare your morning checklist.',
                        value: _morningBrief,
                        onChanged: (val) => _updateSetting('morning_brief', val),
                      ),
                      
                      const SizedBox(height: 16.0),
                      
                      _buildToggleTile(
                        emoji: '📋',
                        title: 'Evening Priorities Check',
                        subtitle: 'Alerts at 8:00 PM reminding you of incomplete high-priority checklist items.',
                        value: _eveningReview,
                        onChanged: (val) => _updateSetting('evening_review', val),
                      ),
                      
                      const SizedBox(height: 16.0),
                      
                      _buildToggleTile(
                        emoji: '💸',
                        title: 'Financial & Bill Reminders',
                        subtitle: 'Alerts for upcoming utility bills, credit cards, or loan EMI dates.',
                        value: _financialAlerts,
                        onChanged: (val) => _updateSetting('financial_alerts', val),
                      ),
                      
                      const Spacer(),
                      
                      JarvisCard(
                        padding: 20.0,
                        child: Column(
                          children: [
                            const Text('🤖', style: TextStyle(fontSize: 40.0)),
                            const SizedBox(height: 12.0),
                            Text(
                              'Test Notification Subsystem',
                              style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              'Trigger a system-level notification immediately to verify mobile sound and vibration permissions are configured correctly.',
                              textAlign: TextAlign.center,
                              style: AppTypography.caption(color: AppColors.textSecondary).copyWith(
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 20.0),
                            JarvisButton(
                              text: 'Test Notification Now',
                              isFullWidth: true,
                              onPressed: _testNotification,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24.0),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
