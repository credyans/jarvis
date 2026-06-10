import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jarvis/firebase_options.dart';
import 'package:jarvis/core/services/notification_service.dart';
import 'package:jarvis/core/config.dart';
import 'package:jarvis/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize local databases (Hive)
  await Hive.initFlutter();

  // 2. Initialize Cloud Backends
  if (AppConfig.useFirebase) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
    }
  } else {
    if (AppConfig.useSupabase && AppConfig.supabaseAnonKey != 'PASTE_YOUR_SUPABASE_ANON_KEY_HERE') {
      try {
        await Supabase.initialize(
          url: AppConfig.supabaseUrl,
          publishableKey: AppConfig.supabaseAnonKey,
        );
      } catch (e) {
        debugPrint('Error initializing Supabase: $e');
      }
    }
  }

  // 3. Initialize local and scheduled notification services
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Error initializing notifications: $e');
  }

  runApp(
    const ProviderScope(
      child: JarvisApp(),
    ),
  );
}
