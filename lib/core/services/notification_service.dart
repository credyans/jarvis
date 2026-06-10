import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:jarvis/core/config.dart';
import 'package:jarvis/core/router/app_router.dart';
import 'package:jarvis/shared/widgets/toast_notification.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Timer? _localReminderTimer;
  final Set<String> _firedNotificationIds = {};

  Future<void> initialize() async {
    // 1. Initialize timezone database
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (_) {
      // Fallback if location lookup fails on certain host platforms
    }

    // 2. Initialize Flutter Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    try {
      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint("Notification tapped: ${details.payload}");
        },
      );
    } catch (e) {
      debugPrint("Error initializing flutter_local_notifications: $e");
    }

    // 3. Start local notification checker unconditionally (for foreground toasts)
    startLocalReminderChecker();

    // 4. Configure Firebase Messaging if enabled
    if (!AppConfig.useFirebase) return;

    try {
      // Request permission (especially for iOS / Android 13+)
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (kDebugMode) {
          print('User granted notification permission');
        }
        
        // Get device FCM token
        String? token = await _fcm.getToken();
        if (token != null) {
          await _saveTokenToUserDocument(token);
        }

        // Any time token refreshes, save it
        _fcm.onTokenRefresh.listen((newToken) async {
          await _saveTokenToUserDocument(newToken);
        });

        // Foreground message stream
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          if (kDebugMode) {
            print('Foreground message received: ${message.notification?.title}');
          }
        });

        // Handling app opened from notification in background state
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          if (kDebugMode) {
            print('Notification clicked, app opened: ${message.notification?.title}');
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing NotificationService: $e');
      }
    }
  }

  Future<void> requestPermissions() async {
    // Request permission for Android (Android 13+)
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    // Request permission for iOS
    final IOSFlutterLocalNotificationsPlugin? iosImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> showInstantTestNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'jarvis_test_channel',
      'Test Notifications',
      channelDescription: 'Used for testing instant alerts',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const DarwinNotificationDetails darwinPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      999,
      'Jarvis Core Active 🤖',
      'This is an instant test notification. Your mobile alerts are working properly!',
      platformChannelSpecifics,
      payload: 'test_payload',
    );
  }

  Future<void> scheduleDailyWakeUpReminder(String wakeTime) async {
    await _notificationsPlugin.cancel(100);

    final parts = wakeTime.split(':');
    if (parts.length != 2) return;
    final hour = int.tryParse(parts[0]) ?? 7;
    final minute = int.tryParse(parts[1]) ?? 0;

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'jarvis_routine_channel',
      'Morning Routine',
      channelDescription: 'Reminders to start your day',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _notificationsPlugin.zonedSchedule(
      100,
      'Good morning! 🌅',
      'Time to check your daily priorities and log your morning habits with Jarvis.',
      scheduledDate,
      const NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleDailyTaskReminder() async {
    await _notificationsPlugin.cancel(200);

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      20,
      0,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'jarvis_tasks_channel',
      'Evening Review',
      channelDescription: 'Reminders to review remaining tasks',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _notificationsPlugin.zonedSchedule(
      200,
      'Evening Check-in 📋',
      'You still have pending priorities for today. Review them to stay on track!',
      scheduledDate,
      const NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  void startLocalReminderChecker() {
    _localReminderTimer?.cancel();
    _localReminderTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final now = DateTime.now();
      final dateKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final timeKey = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      // Get root navigator context
      final context = rootNavigatorKey.currentContext;
      if (context == null) return;

      try {
        // 1. Check local Hive tasks due today
        final tasksBox = Hive.isBoxOpen('tasks') ? Hive.box('tasks') : await Hive.openBox('tasks');
        final tasks = tasksBox.values.toList();
        for (final t in tasks) {
          final taskMap = Map<String, dynamic>.from(t);
          final dueDate = taskMap['dueDate'] as DateTime?;
          final dueTime = taskMap['dueTime'] as String?;
          final completed = taskMap['completed'] as bool? ?? false;
          final title = taskMap['title'] as String? ?? '';
          final id = taskMap['id'] as String? ?? '';

          if (dueDate != null && dueTime != null && !completed) {
            final taskDateKey = "${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}";
            if (taskDateKey == dateKey && dueTime == timeKey) {
              final notificationId = "task_${id}_$timeKey";
              if (!_firedNotificationIds.contains(notificationId)) {
                _firedNotificationIds.add(notificationId);
                
                // Show in-app Toast
                ToastNotification.show(
                  context,
                  "⏰ Task Reminder: \"$title\" is due now!",
                );

                // Also trigger a system local notification (sound and alert)
                const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
                  'jarvis_tasks_immediate',
                  'Task Reminders',
                  importance: Importance.max,
                  priority: Priority.high,
                );
                await _notificationsPlugin.show(
                  id.hashCode,
                  'Task Due Now! ⏰',
                  'Your priority "$title" is scheduled for this time.',
                  const NotificationDetails(
                    android: androidDetails,
                    iOS: DarwinNotificationDetails(
                      presentAlert: true,
                      presentBadge: true,
                      presentSound: true,
                    ),
                  ),
                );
              }
            }
          }
        }

        // 2. Check local Hive habits due today
        final habitsBox = Hive.isBoxOpen('habits') ? Hive.box('habits') : await Hive.openBox('habits');
        final habits = habitsBox.values.toList();
        for (final h in habits) {
          final habitMap = Map<String, dynamic>.from(h);
          final name = habitMap['name'] as String? ?? '';
          final icon = habitMap['icon'] as String? ?? '🔄';
          final reminderTime = habitMap['reminderTime'] as String?;
          final frequency = habitMap['frequency'] as String? ?? 'daily';
          final completions = List<String>.from(habitMap['completions'] ?? []);
          final id = habitMap['id'] as String? ?? '';

          // Check if completed today
          final isDone = completions.contains(dateKey);
          if (reminderTime != null && !isDone) {
            // Check frequency
            bool isDueToday = false;
            if (frequency == 'daily') {
              isDueToday = true;
            } else if (frequency == 'weekdays') {
              isDueToday = now.weekday >= 1 && now.weekday <= 5;
            } else {
              isDueToday = true;
            }

            if (isDueToday && reminderTime == timeKey) {
              final notificationId = "habit_${id}_$timeKey";
              if (!_firedNotificationIds.contains(notificationId)) {
                _firedNotificationIds.add(notificationId);
                
                // Show in-app Toast
                ToastNotification.show(
                  context,
                  "⏰ Habit Reminder: Time for \"$name\" $icon!",
                );

                // Also trigger system local notification
                const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
                  'jarvis_habits_immediate',
                  'Habit Reminders',
                  importance: Importance.max,
                  priority: Priority.high,
                );
                await _notificationsPlugin.show(
                  id.hashCode,
                  'Habit Alert! 🔄',
                  'Time to complete your habit: "$name" $icon',
                  const NotificationDetails(
                    android: androidDetails,
                    iOS: DarwinNotificationDetails(
                      presentAlert: true,
                      presentBadge: true,
                      presentSound: true,
                    ),
                  ),
                );
              }
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print("Error checking reminders: $e");
        }
      }
    });
  }

  Future<void> saveCurrentToken() async {
    if (!AppConfig.useFirebase) return;

    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToUserDocument(token);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving current FCM token: $e');
      }
    }
  }

  Future<void> _saveTokenToUserDocument(String token) async {
    if (!AppConfig.useFirebase) return;

    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await _firestore.collection('users').doc(uid).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        if (kDebugMode) {
          print('Error saving FCM token: $e');
        }
      }
    }
  }
}
