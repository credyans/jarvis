import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TodoCountdownNotifier extends StateNotifier<Map<String, int>> {
  TodoCountdownNotifier() : super({});

  final Map<String, VoidCallback> _callbacks = {};
  Timer? _timer;

  void startCountdown(String id, VoidCallback onCompleted) {
    _callbacks[id] = onCompleted;
    state = {...state, id: 5};
    _startTimer();
  }

  void undoCountdown(String id) {
    _callbacks.remove(id);
    final newState = Map<String, int>.from(state)..remove(id);
    state = newState;
    if (state.isEmpty) {
      _stopTimer();
    }
  }

  bool isInCountdown(String id) => state.containsKey(id);

  int getSecondsLeft(String id) => state[id] ?? 0;

  void _startTimer() {
    _timer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isEmpty) {
        _stopTimer();
        return;
      }

      final newState = <String, int>{};
      final expiredIds = <String>[];

      state.forEach((key, value) {
        if (value > 1) {
          newState[key] = value - 1;
        } else {
          expiredIds.add(key);
        }
      });

      // Update state first so UI updates correctly
      state = newState;

      // Run callbacks for expired countdowns
      for (final id in expiredIds) {
        final callback = _callbacks.remove(id);
        if (callback != null) {
          callback();
        }
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

final todoCountdownProvider =
    StateNotifierProvider<TodoCountdownNotifier, Map<String, int>>((ref) {
  return TodoCountdownNotifier();
});
