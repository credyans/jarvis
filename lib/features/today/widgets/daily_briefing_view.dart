import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/core/utils/id_generator.dart';
import 'package:jarvis/core/utils/intent_detector.dart';
import 'package:jarvis/core/utils/currency_formatter.dart';
import 'package:jarvis/core/constants/emoji_map.dart';

import 'package:jarvis/features/tasks/data/models/task_model.dart';
import 'package:jarvis/features/money/data/models/transaction_model.dart';
import 'package:jarvis/features/money/data/models/debt_model.dart';
import 'package:jarvis/features/mood/data/models/mood_entry_model.dart';
import 'package:jarvis/features/habits/data/models/habit_model.dart';
import 'package:jarvis/features/money/data/models/financial_goal_model.dart';
import 'package:jarvis/data/models/person_model.dart';
import 'package:jarvis/data/models/long_term_memory_model.dart';

import 'package:jarvis/data/providers/task_provider.dart';
import 'package:jarvis/data/providers/money_provider.dart';
import 'package:jarvis/data/providers/mood_provider.dart';
import 'package:jarvis/data/providers/habit_provider.dart';
import 'package:jarvis/data/providers/user_provider.dart';
import 'package:jarvis/data/providers/person_provider.dart';
import 'package:jarvis/data/providers/long_term_memory_provider.dart';
import 'package:jarvis/shared/widgets/jarvis_button.dart';

final briefingCompletedProvider = StateProvider<bool>((ref) => false);

enum AssistantState { idle, listening, thinking, speaking }

class DailyBriefingView extends ConsumerStatefulWidget {
  final VoidCallback onDismiss;

  const DailyBriefingView({super.key, required this.onDismiss});

  @override
  ConsumerState<DailyBriefingView> createState() => _DailyBriefingViewState();
}

class _DailyBriefingViewState extends ConsumerState<DailyBriefingView> with TickerProviderStateMixin {
  AssistantState _state = AssistantState.idle;
  String _transcript = '';
  String _replyText = '';
  double _dragOffset = 0.0;
  double _soundLevel = 0.0; // Voice wave amplitude

  // Voice dependencies
  late stt.SpeechToText _speech;
  bool _speechInitialized = false;
  late FlutterTts _flutterTts;

  // Animation controllers
  late AnimationController _waveController;
  late AnimationController _orbPulseController;
  late AnimationController _orbRotateController;

  @override
  void initState() {
    super.initState();
    
    // Animation Controllers setup
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _orbPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _orbRotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _initVoice();
  }

  Future<void> _initVoice() async {
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();

    try {
      _speechInitialized = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Startup Assistant Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            if (_state == AssistantState.listening) {
              _processTranscript();
            }
          }
        },
        onError: (errorNotification) {
          debugPrint('Startup Assistant Speech error: $errorNotification');
          if (_state == AssistantState.listening) {
            setState(() {
              _state = AssistantState.idle;
            });
          }
        },
      );
    } catch (e) {
      debugPrint('Error initializing speech_to_text: $e');
    }

    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      
      _flutterTts.setStartHandler(() {
        setState(() {
          _state = AssistantState.speaking;
        });
      });
      _flutterTts.setCompletionHandler(() {
        setState(() {
          _state = AssistantState.idle;
        });
      });
      _flutterTts.setErrorHandler((msg) {
        setState(() {
          _state = AssistantState.idle;
        });
      });
    } catch (e) {
      debugPrint('Error initializing flutter_tts: $e');
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _orbPulseController.dispose();
    _orbRotateController.dispose();
    try {
      _speech.stop();
      _flutterTts.stop();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _startListening() async {
    await _flutterTts.stop();
    setState(() {
      _transcript = '';
      _replyText = '';
    });

    bool hasPermission = true;
    if (!kIsWeb) {
      final status = await Permission.microphone.status;
      if (!status.isGranted) {
        final result = await Permission.microphone.request();
        hasPermission = result.isGranted;
      }
    }

    if (!hasPermission || !_speechInitialized) {
      debugPrint('Microphone not available on startup screen. Running simulation.');
      _startSimulatedListening();
      return;
    }

    setState(() {
      _state = AssistantState.listening;
    });

    try {
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _transcript = result.recognizedWords;
          });
        },
        onSoundLevelChange: (level) {
          setState(() {
            _soundLevel = level;
          });
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint('Error starting speech listen: $e');
      _startSimulatedListening();
    }
  }

  void _startSimulatedListening() {
    setState(() {
      _state = AssistantState.listening;
      _transcript = '';
    });

    final randomCommands = [
      'Spent 500 on dinner',
      'Create a reading habit',
      'Remind me to call mom tomorrow',
      'Aravind birthday is June 18',
      'Lent 1000 to Aravind',
    ];
    final command = (randomCommands..shuffle()).first;
    final words = command.split(' ');
    int wordIndex = 0;

    Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!mounted || _state != AssistantState.listening) {
        timer.cancel();
        return;
      }

      if (wordIndex < words.length) {
        setState(() {
          _transcript += (wordIndex == 0 ? '' : ' ') + words[wordIndex];
        });
        wordIndex++;
      } else {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            _processTranscript();
          }
        });
      }
    });
  }

  Future<void> _processTranscript() async {
    if (_transcript.trim().isEmpty) {
      setState(() {
        _state = AssistantState.idle;
      });
      return;
    }

    setState(() {
      _soundLevel = 0.0;
      _state = AssistantState.thinking;
    });

    await _speech.stop();

    // AI thinking delay
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    final intents = IntentDetector.detectMultiple(_transcript);
    
    String reply = '';
    if (intents.isEmpty) {
      reply = "I parsed that, but couldn't categorize it. Let's head to the dashboard.";
    } else {
      int count = 0;
      for (final result in intents) {
        final type = result.type;
        final originalText = result.originalText;
        final data = result.extractedData;

        if (type == IntentType.task || type == IntentType.reminder || type == IntentType.unknown) {
          final task = TaskModel(
            id: IdGenerator.generate(),
            title: originalText,
            description: 'Logged via living startup assistant.',
            dueDate: DateTime.now(),
            dueTime: data['time'] as String? ?? '09:00',
            priority: 0,
            completed: false,
            emoji: EmojiMap.getEmoji(originalText),
            createdAt: DateTime.now(),
          );
          await ref.read(taskProvider.notifier).addTask(task);
          count++;
        } else if (type == IntentType.expense || type == IntentType.income) {
          final amt = data['amount'] as double? ?? 100.0;
          final isIncome = type == IntentType.income;
          final tx = TransactionModel(
            id: IdGenerator.generate(),
            type: isIncome ? 'income' : 'expense',
            amount: amt,
            category: isIncome ? 'Salary' : 'Shopping',
            description: originalText,
            emoji: EmojiMap.getEmoji(originalText),
            date: DateTime.now(),
            createdAt: DateTime.now(),
          );
          await ref.read(transactionProvider.notifier).addTransaction(tx);
          count++;
        } else if (type == IntentType.mood) {
          final mood = data['mood'] as String? ?? 'good';
          final moodEntry = MoodEntryModel(
            id: IdGenerator.generate(),
            date: DateTime.now(),
            mood: mood,
            createdAt: DateTime.now(),
          );
          await ref.read(moodProvider.notifier).saveMood(moodEntry);
          count++;
        } else if (type == IntentType.habit) {
          final habit = HabitModel(
            id: IdGenerator.generate(),
            name: originalText,
            icon: EmojiMap.getEmoji(originalText),
            frequency: 'daily',
            startDate: DateTime.now(),
          );
          await ref.read(habitProvider.notifier).addHabit(habit);
          count++;
        } else if (type == IntentType.debtAdd || type == IntentType.debtPayment) {
          final person = data['person'] as String? ?? 'Friend';
          final amt = data['amount'] as double? ?? 500.0;
          final isOwedToMe = type == IntentType.debtAdd || originalText.contains('lent') || originalText.contains('owes') || originalText.contains('gave');
          
          if (type == IntentType.debtAdd) {
            final debt = DebtModel(
              id: IdGenerator.generate(),
              person: person,
              category: isOwedToMe ? 'Lent Cash' : 'Borrowed Cash',
              amount: amt,
              frequency: 'one-time',
              startDate: DateTime.now(),
              endDate: DateTime.now().add(const Duration(days: 30)),
              type: isOwedToMe ? 'owedToMe' : 'iOwe',
              payments: const [],
              createdAt: DateTime.now(),
            );
            await ref.read(debtProvider.notifier).addDebt(debt);
            count++;
          } else {
            final tx = TransactionModel(
              id: IdGenerator.generate(),
              type: isOwedToMe ? 'income' : 'expense',
              amount: amt,
              category: 'Debt Repayment',
              description: 'EMI Payment from $person',
              emoji: '🤝',
              date: DateTime.now(),
              createdAt: DateTime.now(),
            );
            await ref.read(transactionProvider.notifier).addTransaction(tx);
            count++;
          }
        } else if (type == IntentType.goal) {
          final amt = data['amount'] as double? ?? 10000.0;
          final goal = FinancialGoalModel(
            id: IdGenerator.generate(),
            name: originalText,
            icon: EmojiMap.getEmoji(originalText),
            targetAmount: amt,
            currentAmount: 0.0,
            deadline: DateTime.now().add(const Duration(days: 90)),
            createdAt: DateTime.now(),
          );
          await ref.read(goalProvider.notifier).addGoal(goal);
          count++;
        } else if (type == IntentType.journal) {
          final task = TaskModel(
            id: IdGenerator.generate(),
            title: originalText,
            description: 'Journal entry logged via living startup assistant.',
            dueDate: DateTime.now(),
            dueTime: data['time'] as String? ?? '09:00',
            priority: 0,
            completed: true,
            emoji: '📝',
            tagId: 'Journal',
            createdAt: DateTime.now(),
          );
          await ref.read(taskProvider.notifier).addTask(task);
          count++;
        } else if (type == IntentType.memory) {
          final memoryType = data['memoryType'] as String? ?? 'general';
          final memory = LongTermMemoryModel(
            id: IdGenerator.generate(),
            title: data['cleanTitle'] as String? ?? originalText,
            body: originalText,
            type: memoryType,
            date: DateTime.now(),
            createdAt: DateTime.now(),
          );
          await ref.read(longTermMemoryProvider.notifier).saveMemory(memory);
          count++;
        } else if (type == IntentType.people) {
          final name = data['name'] as String? ?? 'Friend';
          final eventType = data['eventType'] as String? ?? 'birthday';
          final dateText = data['dateText'] as String? ?? 'June 18';
          
          int month = 6;
          int day = 18;
          try {
            final lower = dateText.toLowerCase();
            final monthsList = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
            for (int i = 0; i < monthsList.length; i++) {
              if (lower.contains(monthsList[i])) {
                month = i + 1;
                break;
              }
            }
            final dayMatch = RegExp(r'\d+').firstMatch(lower);
            if (dayMatch != null) {
              day = int.tryParse(dayMatch.group(0)!) ?? 18;
            }
          } catch (_) {}

          final now = DateTime.now();
          DateTime eventDate = DateTime(now.year, month, day);
          if (eventDate.isBefore(DateTime(now.year, now.month, now.day))) {
            eventDate = DateTime(now.year + 1, month, day);
          }

          final person = PersonModel(
            id: IdGenerator.generate(),
            name: name,
            birthday: eventType == 'birthday' ? eventDate : null,
            anniversary: eventType == 'anniversary' ? eventDate : null,
            relationshipNotes: 'Automatically created via living startup assistant.',
            tags: const ['Friend'],
            createdAt: DateTime.now(),
          );
          await ref.read(personProvider.notifier).savePerson(person);

          final mainEvent = TaskModel(
            id: IdGenerator.generate(),
            title: "$name's Birthday: $dateText",
            description: "Annual recurring event for $name.",
            dueDate: eventDate,
            dueTime: '09:00',
            priority: 3,
            completed: false,
            emoji: '🎁',
            tagId: 'Relationship',
            createdAt: DateTime.now(),
          );
          await ref.read(taskProvider.notifier).addTask(mainEvent);
          count++;
        }
      }

      ref.invalidate(todayTasksProvider);
      debugPrint('Processed $count intents successfully');
      
      final firstType = intents[0].type;
      final firstText = intents[0].originalText;
      
      if (firstType == IntentType.expense) {
        reply = "Recorded expense of ${CurrencyFormatter.format(intents[0].extractedData['amount'] as double? ?? 100.0)}.";
      } else if (firstType == IntentType.task) {
        reply = "Created task to $firstText.";
      } else if (firstType == IntentType.habit) {
        reply = "Started tracking habit: $firstText.";
      } else if (firstType == IntentType.people) {
        reply = "Saved connection profile for ${intents[0].extractedData['name']}.";
      } else if (firstType == IntentType.memory) {
        reply = "Logged that memory to your vault.";
      } else {
        reply = "Saved successfully. Let's continue.";
      }
    }

    setState(() {
      _replyText = reply;
      _state = AssistantState.speaking;
    });

    await _speak(reply);
  }

  Future<void> _speak(String text) async {
    try {
      await _flutterTts.speak(text);
    } catch (_) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _state = AssistantState.idle;
        });
      }
    }
  }

  Widget _buildRipples() {
    if (_state != AssistantState.listening) return const SizedBox.shrink();
    
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _waveController,
          builder: (context, child) {
            return OrbRipples(
              progress: _waveController.value,
              color: AppColors.primary,
            );
          },
        ),
        AnimatedBuilder(
          animation: _waveController,
          builder: (context, child) {
            final val = (_waveController.value + 0.5) % 1.0;
            return OrbRipples(
              progress: val,
              color: AppColors.secondary,
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final name = userAsync.value?.name ?? 'Santhosh';

    // Siri Waveform amplitude calculations
    double amplitude = 0.0;
    if (_state == AssistantState.listening) {
      amplitude = 0.35 + 0.15 * math.sin(_waveController.value * 2 * math.pi);
    } else if (_state == AssistantState.speaking) {
      amplitude = 0.6 + 0.4 * math.sin(_waveController.value * 4 * math.pi);
    }

    // Dynamic 3D Moving AI Particle Sphere amplitude calculations
    double particleAmplitude = 0.0;
    if (_state == AssistantState.listening) {
      if (_soundLevel > 0.0) {
        particleAmplitude = 0.25 + (_soundLevel.clamp(0.0, 10.0) / 10.0) * 0.75;
      } else {
        particleAmplitude = 0.3 + 0.2 * math.sin(_waveController.value * 4 * math.pi);
      }
    } else if (_state == AssistantState.speaking) {
      particleAmplitude = 0.5 + 0.5 * math.sin(_waveController.value * 6 * math.pi);
    } else if (_state == AssistantState.thinking) {
      particleAmplitude = 0.45 + 0.25 * math.sin(_waveController.value * 8 * math.pi);
    } else {
      // Idle breathing state
      particleAmplitude = 0.1 + 0.08 * math.sin(_orbPulseController.value * math.pi);
    }

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _dragOffset += details.primaryDelta!;
          if (_dragOffset > 0.0) _dragOffset = 0.0;
        });
      },
      onVerticalDragEnd: (details) {
        if (_dragOffset < -120.0 || details.primaryVelocity! < -500.0) {
          widget.onDismiss();
        } else {
          setState(() {
            _dragOffset = 0.0;
          });
        }
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: const Color(0xFF070C18),
            body: Stack(
              children: [
                // Shifting Aura Background
                Positioned(
                  top: -80,
                  left: -60,
                  child: Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF6366FF).withOpacity(0.12),
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.2, 1.2), duration: 7.seconds),
                
                Positioned(
                  bottom: 150,
                  right: -80,
                  child: Container(
                    width: 380,
                    height: 380,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF4EDEA3).withOpacity(0.08),
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.15, 1.15), duration: 9.seconds),
                
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0),
                    child: Container(color: Colors.transparent),
                  ),
                ),

                // Main Interface
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Greeting & Heading (Large center text)
                        Column(
                          children: [
                            const SizedBox(height: 32.0),
                            Text(
                              "Hey $name,\nI'm here to remind you.",
                              style: AppTypography.display(color: Colors.white).copyWith(
                                fontSize: 34.0,
                                fontWeight: FontWeight.w900,
                                height: 1.35,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ).animate().fade().slideY(begin: -0.1, end: 0),
                            const SizedBox(height: 16.0),
                          ],
                        ),

                        const Spacer(),

                        // Center 3D Animated Orb
                        Center(
                          child: GestureDetector(
                            onTap: _state == AssistantState.idle ? _startListening : null,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Concentric Ripples (Listening State)
                                _buildRipples(),

                                // Dynamic 3D Moving AI Particle Sphere (Reacts to Voice/Vocal sound waves)
                                AnimatedBuilder(
                                  animation: _orbRotateController,
                                  builder: (context, child) {
                                    return SizedBox(
                                      width: 240.0,
                                      height: 240.0,
                                      child: CustomPaint(
                                        painter: OrbParticlePainter(
                                          angle: _orbRotateController.value * 2 * math.pi,
                                          color: _state == AssistantState.listening
                                              ? AppColors.secondary
                                              : _state == AssistantState.thinking
                                                  ? AppColors.warningLight
                                                  : AppColors.primaryLight,
                                          amplitude: particleAmplitude,
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                // Main 3D Glowing Orb Sphere
                                AnimatedBuilder(
                                  animation: _orbPulseController,
                                  builder: (context, child) {
                                    double scale = 1.0;
                                    if (_state == AssistantState.listening) {
                                      scale = 1.15;
                                    } else if (_state == AssistantState.thinking) {
                                      scale = 1.05 + 0.05 * math.sin(_waveController.value * 2 * math.pi);
                                    } else {
                                      scale = 1.0 + 0.06 * _orbPulseController.value;
                                    }

                                    return Transform.scale(
                                      scale: scale,
                                      child: Container(
                                        width: 160.0,
                                        height: 160.0,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: (_state == AssistantState.listening
                                                      ? AppColors.secondary
                                                      : _state == AssistantState.thinking
                                                          ? AppColors.warningLight
                                                          : AppColors.primary)
                                                  .withOpacity(0.35),
                                              blurRadius: 32.0,
                                              spreadRadius: 4.0,
                                            ),
                                          ],
                                          gradient: RadialGradient(
                                            colors: _state == AssistantState.thinking
                                                ? [
                                                    Colors.white,
                                                    AppColors.warningLight,
                                                    const Color(0xFF93000A),
                                                  ]
                                                : _state == AssistantState.listening
                                                    ? [
                                                        Colors.white,
                                                        AppColors.secondary,
                                                        const Color(0xFF005236),
                                                      ]
                                                    : [
                                                        Colors.white,
                                                        AppColors.primary,
                                                        AppColors.primaryDark,
                                                      ],
                                            center: const Alignment(-0.25, -0.25),
                                            radius: 0.85,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Live Speech Transcript Box
                        if (_transcript.isNotEmpty || _replyText.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16.0),
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(20.0),
                              border: Border.all(color: Colors.white.withOpacity(0.06)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_transcript.isNotEmpty) ...[
                                  Text(
                                    'YOU',
                                    style: AppTypography.micro(color: AppColors.textTertiary).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    _transcript,
                                    style: AppTypography.body(color: Colors.white),
                                  ),
                                ],
                                if (_replyText.isNotEmpty) ...[
                                  const SizedBox(height: 12.0),
                                  Divider(color: Colors.white.withOpacity(0.05)),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    'JARVIS',
                                    style: AppTypography.micro(color: AppColors.primary).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    _replyText,
                                    style: AppTypography.body(color: AppColors.primaryLight),
                                  ),
                                ],
                              ],
                            ),
                          ).animate().fade().slideY(begin: 0.1, end: 0),

                        // Voice Waveform Area (Listening / Speaking)
                        if (_state == AssistantState.listening || _state == AssistantState.speaking)
                          AnimatedBuilder(
                            animation: _waveController,
                            builder: (context, child) {
                              return SiriWaveform(
                                amplitude: amplitude,
                                phase: _waveController.value * 2 * math.pi,
                              );
                            },
                          ),

                        const SizedBox(height: 24.0),

                        // Microphone Button
                        Center(
                          child: GestureDetector(
                            onTap: _state == AssistantState.idle ? _startListening : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(18.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _state == AssistantState.listening
                                    ? AppColors.secondary.withOpacity(0.15)
                                    : Colors.white.withOpacity(0.03),
                                border: Border.all(
                                  color: _state == AssistantState.listening
                                      ? AppColors.secondary
                                      : Colors.white.withOpacity(0.08),
                                ),
                              ),
                              child: Icon(
                                _state == AssistantState.listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                                color: _state == AssistantState.listening ? AppColors.secondary : Colors.white70,
                                size: 28.0,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32.0),

                        // Continue & Swipe to Dashboard CTA
                        JarvisButton(
                          text: 'Continue to Dashboard',
                          isFullWidth: true,
                          onPressed: widget.onDismiss,
                        ),
                        
                        const SizedBox(height: 16.0),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white38, size: 20.0),
                              const SizedBox(width: 4.0),
                              Text(
                                'Swipe up to unlock dashboard',
                                style: AppTypography.caption(color: Colors.white38),
                              ),
                            ],
                          ),
                        ).animate(onPlay: (c) => c.repeat(reverse: true))
                          .moveY(begin: 0, end: -6, duration: 1.seconds),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (_dragOffset < 0)
            Positioned(
              left: 0,
              right: 0,
              top: MediaQuery.of(context).size.height + _dragOffset,
              height: MediaQuery.of(context).size.height,
              child: Container(
                color: Colors.transparent,
              ),
            ),
        ],
      ),
    );
  }
}

class SiriWaveform extends StatelessWidget {
  final double amplitude;
  final double phase;
  
  const SiriWaveform({super.key, required this.amplitude, required this.phase});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 80.0),
      painter: _SiriWaveformPainter(amplitude: amplitude, phase: phase),
    );
  }
}

class _SiriWaveformPainter extends CustomPainter {
  final double amplitude;
  final double phase;

  _SiriWaveformPainter({required this.amplitude, required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    
    final waves = [
      {'color': const Color(0xFF6366FF), 'speed': 1.0, 'freq': 0.012, 'ampScale': 1.0},
      {'color': const Color(0xFF4EDEA3), 'speed': -0.8, 'freq': 0.016, 'ampScale': 0.7},
      {'color': const Color(0xFFC0C1FF), 'speed': 1.4, 'freq': 0.02, 'ampScale': 0.5},
      {'color': const Color(0xFFFFB4AB), 'speed': -1.2, 'freq': 0.008, 'ampScale': 0.4},
    ];

    for (final wave in waves) {
      final paint = Paint()
        ..color = wave['color'] as Color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);

      final path = Path();
      path.moveTo(0, midY);

      final speed = wave['speed'] as double;
      final freq = wave['freq'] as double;
      final ampScale = wave['ampScale'] as double;

      for (double x = 0; x <= size.width; x += 4) {
        final envelope = math.sin((x / size.width) * math.pi);
        final y = midY + math.sin(x * freq + phase * speed) * amplitude * ampScale * envelope * (size.height / 2.2);
        path.lineTo(x, y);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SiriWaveformPainter oldDelegate) =>
      oldDelegate.amplitude != amplitude || oldDelegate.phase != phase;
}

class OrbRipples extends StatelessWidget {
  final double progress;
  final Color color;

  const OrbRipples({super.key, required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(200, 200),
      painter: _OrbRipplesPainter(progress: progress, color: color),
    );
  }
}

class _OrbRipplesPainter extends CustomPainter {
  final double progress;
  final Color color;

  _OrbRipplesPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width;

    final paint = Paint()
      ..color = color.withOpacity((1.0 - progress).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final radius = (size.width / 2) + (maxRadius - (size.width / 2)) * progress;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _OrbRipplesPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class OrbParticlePainter extends CustomPainter {
  final double angle;
  final Color color;
  final double amplitude;

  OrbParticlePainter({
    required this.angle,
    required this.color,
    required this.amplitude,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = (size.width / 2) - 10.0;

    final paint = Paint()..style = PaintingStyle.fill;

    // We will draw 3 orbits (rings) tilted in 3D space to form a particle sphere.
    // Each orbit has 8 particles, so 24 particles in total.
    
    // Orbit 1: Horizontal orbit with a slight tilt
    _drawOrbit(canvas, center, baseRadius, angle, 0.0, 0.2, paint);
    
    // Orbit 2: Vertical-ish orbit tilted left
    _drawOrbit(canvas, center, baseRadius, angle + (2 * math.pi / 3), 1.0, 0.8, paint);
    
    // Orbit 3: Vertical-ish orbit tilted right
    _drawOrbit(canvas, center, baseRadius, angle + (4 * math.pi / 3), -1.0, 0.8, paint);
  }

  void _drawOrbit(
    Canvas canvas,
    Offset center,
    double baseRadius,
    double orbitAngle,
    double tiltX,
    double tiltY,
    Paint paint,
  ) {
    const int particleCount = 8;
    for (int i = 0; i < particleCount; i++) {
      final double pAngle = orbitAngle + (i * 2 * math.pi / particleCount);
      
      // Calculate 3D sphere coordinate projections
      // Jitter creates the active vocal wave sound reaction
      final jitter = math.sin(pAngle * 4 + angle * 8) * amplitude * 18.0;
      final radius = baseRadius + amplitude * 32.0 + jitter;

      final double x3d = math.cos(pAngle);
      final double y3d = math.sin(pAngle);
      
      // Rotate coordinates in space to simulate 3D projection
      final double xProj = x3d;
      final double yProj = y3d * tiltY + x3d * tiltX * 0.3;
      final double zProj = y3d * (1.0 - tiltY.abs()) + x3d * (1.0 - tiltX.abs()) * 0.5; // Depth factor

      final offset = Offset(
        center.dx + xProj * radius,
        center.dy + yProj * radius,
      );

      // Particle size scales with depth and sound amplitude
      final double pSize = (3.5 + amplitude * 4.5) * (1.0 + zProj * 0.4);
      
      // Fade particles at the back to enhance 3D depth perception
      final double opacity = (0.2 + 0.8 * (zProj + 1.0) / 2.0).clamp(0.1, 1.0);
      paint.color = color.withOpacity(opacity);

      canvas.drawCircle(offset, pSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant OrbParticlePainter oldDelegate) =>
      oldDelegate.angle != angle ||
      oldDelegate.color != color ||
      oldDelegate.amplitude != amplitude;
}
