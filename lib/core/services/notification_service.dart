import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

  Timer? _localReminderTimer;
  final Set<String> _firedNotificationIds = {};

  Future<void> initialize() async {
    // Start local notification checker unconditionally
    startLocalReminderChecker();

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
                ToastNotification.show(
                  context,
                  "⏰ Task Reminder: \"$title\" is due now!",
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
                ToastNotification.show(
                  context,
                  "⏰ Habit Reminder: Time for \"$name\" $icon!",
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
