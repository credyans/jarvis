import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentTabProvider = StateProvider<int>((ref) => 1);

// Active sub-tab inside Planner screen (0 = Priorities, 1 = Habits, 2 = Planner)
final plannerSubTabProvider = StateProvider<int>((ref) => 0);

final commandBarVisibleProvider = StateProvider<bool>((ref) => false);
