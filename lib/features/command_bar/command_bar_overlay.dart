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
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/core/utils/intent_detector.dart';
import 'package:jarvis/core/utils/id_generator.dart';
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
import 'package:jarvis/data/providers/navigation_provider.dart';
import 'package:jarvis/data/providers/user_provider.dart';
import 'package:jarvis/data/providers/person_provider.dart';
import 'package:jarvis/data/providers/long_term_memory_provider.dart';
import 'package:jarvis/core/services/notification_service.dart';
import 'package:jarvis/shared/widgets/jarvis_button.dart';
import 'package:jarvis/shared/widgets/toast_notification.dart';

class CommandBarOverlay extends ConsumerStatefulWidget {
  const CommandBarOverlay({super.key});

  @override
  ConsumerState<CommandBarOverlay> createState() => _CommandBarOverlayState();
}

class _CommandBarOverlayState extends ConsumerState<CommandBarOverlay> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // State Management
  bool _isListening = false;
  bool _isProcessing = false;
  int _currentStep = 0; // 0: welcome/input, 1: draft cards sequence, 2: final summary, 3: conversational advice, 4: transcript review
  String _listeningText = '';
  List<IntentResult> _draftResults = [];
  int _currentDraftIndex = 0;
  String? _conversationalResponse;
  int _createdCount = 0;
  String _selectedLocale = 'en_IN';
  late TextEditingController _transcriptEditController;

  Timer? _typingTimer;

  // Real voice dependencies
  late stt.SpeechToText _speech;
  bool _speechInitialized = false;
  late FlutterTts _flutterTts;
  bool _isSpeaking = false;

  // LiveKit WebRTC state variables
  lk.Room? _lkRoom;
  lk.EventsListener<lk.RoomEvent>? _lkListener;
  bool _isLiveKitConnected = false;
  bool _isAgentSpeaking = false;
  String _livekitStatusText = '';

  final List<String> _simulatedCommands = [
    'Spent ₹350 on lunch and track morning walk habit',
    'Lent 500 to Saroo and do weekly presentation prep',
    'Meditation daily and buy fresh eggs',
    'Read a book daily and pay monthly electricity bill',
    'Call Dad at 8 PM and feeling stressed',
  ];

  @override
  void initState() {
    super.initState();
    _transcriptEditController = TextEditingController();
    _focusNode.requestFocus();
    _initVoiceChat();
  }

  Future<void> _initVoiceChat() async {
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();

    try {
      _speechInitialized = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            if (_isListening) {
              setState(() {
                _isListening = false;
              });
              if (_listeningText.isNotEmpty) {
                _transcriptEditController.text = _listeningText;
                setState(() {
                  _currentStep = 4;
                });
              }
            }
          }
        },
        onError: (errorNotification) {
          debugPrint('Speech error: $errorNotification');
          setState(() {
            _isListening = false;
          });
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
        setState(() => _isSpeaking = true);
      });
      _flutterTts.setCompletionHandler(() {
        setState(() => _isSpeaking = false);
      });
      _flutterTts.setErrorHandler((msg) {
        setState(() => _isSpeaking = false);
      });
    } catch (e) {
      debugPrint('Error initializing flutter_tts: $e');
    }
  }

  Future<void> _speakText(String text) async {
    await _flutterTts.stop();
    final cleanText = text.replaceAll(RegExp(r'[\u2600-\u27BF]|[\uE000-\uF8FF]|\uD83C[\uDC00-\uDFFF]|\uD83D[\uDC00-\uDFFF]|[\u2011-\u26FF]|\uD83E[\uDC00-\uDFFF]'), '');
    if (cleanText.trim().isEmpty) return;
    await _flutterTts.speak(cleanText);
  }

  Future<void> _startVoiceChat() async {
    await _flutterTts.stop();
    
    bool hasPermission = true;
    if (!kIsWeb) {
      final status = await Permission.microphone.status;
      if (!status.isGranted) {
        final result = await Permission.microphone.request();
        hasPermission = result.isGranted;
      }
    }

    if (!hasPermission || !_speechInitialized) {
      debugPrint('Microphone not available. Falling back to simulator.');
      if (mounted) {
        ToastNotification.show(
          context,
          'Microphone not available. Running simulated voice assistant.',
          type: 'info',
        );
      }
      _startSimulatedVoice();
      return;
    }

    setState(() {
      _isListening = true;
      _listeningText = '';
      _currentStep = 0;
      _draftResults = [];
    });

    try {
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _listeningText = result.recognizedWords;
          });
        },
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 4),
        localeId: _selectedLocale,
      );
    } catch (e) {
      debugPrint('Error starting speech listen: $e');
      _startSimulatedVoice();
    }
  }

  String _generateLiveKitToken({
    required String apiKey,
    required String apiSecret,
    required String roomName,
    required String participantName,
  }) {
    final jwt = JWT(
      {
        'video': {
          'roomJoin': true,
          'room': roomName,
          'canPublish': true,
          'canSubscribe': true,
          'canPublishData': true,
        },
        'metadata': participantName,
      },
      issuer: apiKey,
      subject: participantName,
    );

    final token = jwt.sign(
      SecretKey(apiSecret),
      expiresIn: const Duration(hours: 2),
    );
    
    return token;
  }

  Future<void> _connectToLiveKit() async {
    setState(() {
      _isListening = true;
      _isLiveKitConnected = false;
      _isAgentSpeaking = false;
      _livekitStatusText = 'Connecting to Jarvis Live...';
      _listeningText = '';
    });

    try {
      final token = _generateLiveKitToken(
        apiKey: 'APIers9jc8sXZdo',
        apiSecret: 'dl6ksSE8F1v6VNUNO94yGheGlFadYHhJ6yk53LpcxmS',
        roomName: 'jarvis_voice_room',
        participantName: 'User_${math.Random().nextInt(1000)}',
      );

      _lkRoom = lk.Room(
        roomOptions: const lk.RoomOptions(
          adaptiveStream: true,
          dynacast: true,
        ),
      );
      _lkListener = _lkRoom!.createListener();
      
      _lkListener!.on<lk.ActiveSpeakersChangedEvent>((event) {
        bool remoteSpeaking = false;
        for (final speaker in event.speakers) {
          if (speaker is lk.RemoteParticipant) {
            remoteSpeaking = true;
            break;
          }
        }
        if (mounted) {
          setState(() {
            _isAgentSpeaking = remoteSpeaking;
            _livekitStatusText = remoteSpeaking ? 'Jarvis is speaking...' : 'Listening to you...';
          });
        }
      });

      _lkListener!.on<lk.DataReceivedEvent>((event) {
        final text = String.fromCharCodes(event.data);
        debugPrint('LiveKit Data: $text');
        if (mounted) {
          setState(() {
            _listeningText = text;
          });
        }
      });

      _lkListener!.on<lk.RoomDisconnectedEvent>((event) {
        debugPrint('Room disconnected: ${event.reason}');
        if (mounted) {
          _disconnectLiveKit();
        }
      });

      // Connect to the LiveKit room
      await _lkRoom!.connect(
        'wss://jarvis-vr2hvf0d.livekit.cloud',
        token,
      );

      // Request mic permission
      bool hasPermission = true;
      if (!kIsWeb) {
        final status = await Permission.microphone.status;
        if (!status.isGranted) {
          final result = await Permission.microphone.request();
          hasPermission = result.isGranted;
        }
      }

      if (hasPermission) {
        await _lkRoom!.localParticipant?.setMicrophoneEnabled(true);
        if (mounted) {
          setState(() {
            _isLiveKitConnected = true;
            _livekitStatusText = 'Connected. Speak now!';
          });
        }
      } else {
        throw Exception('Microphone permission denied.');
      }

    } catch (e) {
      debugPrint('LiveKit connection failed: $e');
      if (mounted) {
        setState(() {
          _isLiveKitConnected = false;
          _livekitStatusText = 'LiveKit failed. Falling back to local AI.';
        });
        ToastNotification.show(
          context,
          'LiveKit error: ${e.toString().split('\n').first}. Running offline assistant.',
          type: 'error',
        );
      }
      _disconnectLiveKit();
      // Fallback
      _startVoiceChat();
    }
  }

  void _disconnectLiveKit() {
    try {
      _lkListener?.dispose();
      _lkListener = null;
      _lkRoom?.disconnect();
      _lkRoom = null;
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isLiveKitConnected = false;
        _isAgentSpeaking = false;
      });
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _inputController.dispose();
    _transcriptEditController.dispose();
    _focusNode.dispose();
    try {
      _speech.stop();
      _flutterTts.stop();
    } catch (_) {}
    _disconnectLiveKit();
    super.dispose();
  }

  void _closeCommandBar() {
    _disconnectLiveKit();
    ref.read(commandBarVisibleProvider.notifier).state = false;
  }

  // Voice Input Simulation
  void _startSimulatedVoice() {
    setState(() {
      _isListening = true;
      _listeningText = '';
      _currentStep = 0;
      _draftResults = [];
    });

    final randomCommand = (_simulatedCommands..shuffle()).first;
    final words = randomCommand.split(' ');
    int wordIndex = 0;
    
    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (wordIndex < words.length) {
        setState(() {
          _listeningText += (wordIndex == 0 ? '' : ' ') + words[wordIndex];
        });
        wordIndex++;
      } else {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            setState(() {
              _isListening = false;
              _transcriptEditController.text = randomCommand;
              _currentStep = 4;
            });
          }
        });
      }
    });
  }

  // Parses raw command
  void _processCommand(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
      _draftResults = [];
      _currentStep = 0;
      _conversationalResponse = null;
    });

    // Simulate AI parsing delay
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;

      final isIrrelevant = IntentDetector.isIrrelevant(text);

      setState(() {
        _isProcessing = false;
        
        if (isIrrelevant) {
          _currentStep = 3; // Conversational / Irrelevant advice state
          _conversationalResponse = _generateConversationalAdvice(text);
          _speakText(_conversationalResponse!);
        } else {
          _draftResults = IntentDetector.detectMultiple(text);
          if (_draftResults.isNotEmpty) {
            _currentStep = 1; // Start draft card slides
            _currentDraftIndex = 0;
            _speakText("I've parsed your command. Let's review: ${_draftResults[0].originalText}");
          } else {
            _currentStep = 3;
            _conversationalResponse = 'I could not parse any action from that command. Try stating a direct task, habit, transaction, or debt.';
            _speakText(_conversationalResponse!);
          }
        }
      });
    });
  }

  String _generateConversationalAdvice(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('money') || lower.contains('save') || lower.contains('budget') || lower.contains('finance')) {
      return 'To build savings, start by tracking every expense. Small daily limits can help you save up to 20% more each month. I can help you record this in your Money dashboard!';
    } else if (lower.contains('habit') || lower.contains('routine') || lower.contains('consistency')) {
      return 'For habits, consistency is key. Keep your targets small (e.g. "Read 5 pages") and stack them directly after an existing routine. Ask me to: "Track reading daily".';
    } else if (lower.contains('task') || lower.contains('productivity') || lower.contains('focus')) {
      return 'To stay productive, focus on your top 3 priorities today. Group similar tasks together to maintain focus. Tell me: "Buy fresh eggs and call boss at 4 PM".';
    } else if (lower.contains('mood') || lower.contains('feeling') || lower.contains('stress') || lower.contains('stressed')) {
      return 'When feeling stressed, take 5 slow deep breaths and log your mood. Self-reflection helps regulate stress. Ask me: "Feeling stressed" or "Feeling happy".';
    }
    return 'I specialize in personal productivity, wellness, habits, and finance tracking. Try telling me: "Spent ₹500 on lunch", "Read daily", or "Lent 500 to Saroo".';
  }

  // Transitions from active draft card to next slide
  void _nextDraftCard() {
    if (_currentDraftIndex < _draftResults.length - 1) {
      setState(() {
        _isProcessing = true;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _currentDraftIndex++;
          });
          _speakText("Next item: ${_draftResults[_currentDraftIndex].originalText}");
        }
      });
    } else {
      // Transition to final summary confirmation screen
      setState(() {
        _isProcessing = true;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _currentStep = 2; // Summary screen
          });
          _speakText("Please review and confirm all parsed items.");
        }
      });
    }
  }

  // Save all draft action items
  Future<void> _confirmAndCreateAll() async {
    setState(() {
      _isProcessing = true;
    });

    int count = 0;
    try {
      for (final result in _draftResults) {
        final type = result.type;
        final originalText = result.originalText;
        final data = result.extractedData;

        if (type == IntentType.task || type == IntentType.reminder || type == IntentType.unknown) {
          final task = TaskModel(
            id: IdGenerator.generate(),
            title: originalText,
            description: 'Quick logged via Jarvis AI command bar.',
            dueDate: DateTime.now(),
            dueTime: data['time'] as String? ?? '09:00',
            priority: 0,
            completed: false,
            emoji: EmojiMap.getEmoji(originalText),
            createdAt: DateTime.now(),
          );
          await ref.read(taskProvider.notifier).addTask(task);
          ref.invalidate(todayTasksProvider);
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
          ref.invalidate(monthlyExpensesProvider);
          ref.invalidate(monthlyIncomeProvider);
          ref.invalidate(todaySpentProvider);
          ref.invalidate(recentTransactionsProvider);
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
          ref.invalidate(todayMoodProvider);
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
            // Debt repayment / collection log as transaction
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
            description: 'Journal entry logged via Jarvis AI command bar.',
            dueDate: DateTime.now(),
            dueTime: data['time'] as String? ?? '09:00',
            priority: 0,
            completed: true,
            emoji: '📝',
            tagId: 'Journal',
            createdAt: DateTime.now(),
          );
          await ref.read(taskProvider.notifier).addTask(task);
          ref.invalidate(todayTasksProvider);
          count++;
        } else if (type == IntentType.memory) {
          // 1. Save as Task for daily timeline vault log
          final task = TaskModel(
            id: IdGenerator.generate(),
            title: originalText,
            description: 'Memory log logged via Jarvis AI command bar.',
            dueDate: DateTime.now(),
            dueTime: data['time'] as String? ?? '09:00',
            priority: 0,
            completed: true,
            emoji: '🧠',
            tagId: 'Memory',
            createdAt: DateTime.now(),
          );
          await ref.read(taskProvider.notifier).addTask(task);
          ref.invalidate(todayTasksProvider);

          // 2. Save as LongTermMemoryModel record
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
            relationshipNotes: 'Automatically created via Jarvis voice/command assistant.',
            tags: const ['Friend'],
            createdAt: DateTime.now(),
          );
          await ref.read(personProvider.notifier).savePerson(person);

          final mainEvent = TaskModel(
            id: IdGenerator.generate(),
            title: "$name's ${eventType[0].toUpperCase()}${eventType.substring(1)}: $dateText",
            description: "Annual recurring event for $name.",
            dueDate: eventDate,
            dueTime: '09:00',
            priority: 3,
            completed: false,
            emoji: eventType == 'birthday' ? '🎁' : '💍',
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
                title: "$name's ${eventType[0].toUpperCase()}${eventType.substring(1)} (${alert['label']})",
                description: "Reminder alert for $name's upcoming birthday/anniversary.",
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
              eventType,
              eventDate,
            );
          } catch (e) {
            debugPrint("Notification schedule failed: $e");
          }

          ref.invalidate(todayTasksProvider);
          count++;
        }
      }

      setState(() {
        _isProcessing = false;
        _createdCount = count;
        _inputController.clear();
      });

      _speakText("Created $count items successfully!");

      if (mounted) {
        ToastNotification.show(context, 'Successfully created $count items!');
      }

      // Reset overlay screen
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _currentStep = 0;
            _draftResults = [];
          });
        }
      });

    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _speakText("Failed to save items.");
      if (mounted) {
        ToastNotification.show(context, 'Failed to save items: $e', type: 'error');
      }
    }
  }

  void _resetInput() {
    setState(() {
      _inputController.clear();
      _draftResults = [];
      _currentStep = 0;
      _conversationalResponse = null;
    });
  }

  // Background Glowing Circle Painter Helper
  Widget _buildGlowCircle({
    required Color color,
    required double size,
    required double top,
    required double left,
    required Duration duration,
  }) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.12),
        ),
      )
      .animate(onPlay: (controller) => controller.repeat(reverse: true))
      .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.25, 1.25), duration: duration, curve: Curves.easeInOut)
      .move(begin: const Offset(-20, -20), end: const Offset(20, 20), duration: duration, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final userName = userAsync.value?.name ?? 'Santhosh';

    return Scaffold(
      backgroundColor: const Color(0xFF0B1326), // Deep Space AI background
      body: Stack(
        children: [
          // ── Pulsing Background Glows ──
          _buildGlowCircle(
            color: const Color(0xFFFFA297), // Pink coral
            size: 260.0,
            top: -40.0,
            left: -30.0,
            duration: 5.seconds,
          ),
          _buildGlowCircle(
            color: const Color(0xFF6BE5E5), // Teal cyan
            size: 320.0,
            top: MediaQuery.of(context).size.height * 0.5 - 160.0,
            left: MediaQuery.of(context).size.width - 240.0,
            duration: 7.seconds,
          ),
          _buildGlowCircle(
            color: const Color(0xFFB68FEB), // Indigo lavender
            size: 280.0,
            top: MediaQuery.of(context).size.height - 240.0,
            left: -50.0,
            duration: 6.seconds,
          ),
          
          // Heavy glass blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 85.0, sigmaY: 85.0),
              child: Container(color: Colors.transparent),
            ),
          ),

          // ── Main UI Layout ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Close Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 20.0),
                        ),
                        onPressed: _closeCommandBar,
                      ),
                    ],
                  ),

                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: _buildCenterContent(userName),
                        ),
                      ),
                    ),
                  ),

                  // Bottom Input Field (Only in step 0 or step 3)
                  if (_currentStep == 0 || _currentStep == 3) ...[
                    const SizedBox(height: 16.0),
                    _buildBottomInputBar(),
                    const SizedBox(height: 12.0),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterContent(String userName) {
    if (_isListening) {
      return _buildVoiceListeningView();
    }
    
    if (_isProcessing) {
      return _buildAIProcessingView();
    }

    switch (_currentStep) {
      case 1:
        return _buildDraftCardSequence();
      case 2:
        return _buildFinalSummaryView();
      case 3:
        return _buildConversationalAdviceView();
      case 4:
        return _buildTranscriptReviewView();
      case 0:
      default:
        return _buildWelcomeView(userName);
    }
  }

  // ── step 0: Welcoming Screen ──
  Widget _buildWelcomeView(String userName) {
    return Column(
      key: const ValueKey('welcome'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Hi, $userName',
          style: AppTypography.display(color: Colors.white).copyWith(
            fontSize: 34.0,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ).animate().fade(duration: 400.ms).slideY(begin: -0.05, end: 0.0),
        const SizedBox(height: 8.0),
        Text(
          'Jarvis will remind you.',
          style: AppTypography.body(color: Colors.white.withOpacity(0.5)).copyWith(
            fontSize: 16.0,
          ),
          textAlign: TextAlign.center,
        ).animate().fade(delay: 200.ms, duration: 400.ms),
        const SizedBox(height: 56.0),

        // Animated Jarvis AI Sprite Bubble
        JarvisAiSpriteBubble(
          state: _isLiveKitConnected
              ? (_isAgentSpeaking ? JarvisBubbleState.speaking : JarvisBubbleState.listening)
              : (_isSpeaking ? JarvisBubbleState.speaking : JarvisBubbleState.idle),
          onTap: _connectToLiveKit,
        ).animate().scale(delay: 300.ms, duration: 450.ms, curve: Curves.easeOutBack),
        
        const SizedBox(height: 24.0),
        Text(
          _isLiveKitConnected
              ? (_isAgentSpeaking ? 'Jarvis is speaking...' : 'Listening to you...')
              : (_isSpeaking ? 'Jarvis is speaking...' : 'Tap to talk to Jarvis'),
          style: AppTypography.caption(color: Colors.white.withOpacity(0.4)),
        ),
        const SizedBox(height: 16.0),
        _buildLocaleSelector(),

        if (_createdCount > 0) ...[
          const SizedBox(height: 48.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: AppColors.success.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.done_all_rounded, color: AppColors.success, size: 18.0),
                const SizedBox(width: 8.0),
                Text(
                  'Created $_createdCount action items successfully!',
                  style: AppTypography.micro(color: AppColors.success).copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ).animate().fade().scale(),
        ],
      ],
    );
  }

  Widget _buildLocaleSelector() {
    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLocaleTab('en_IN', 'English 🇮🇳'),
          _buildLocaleTab('ta_IN', 'Tamil 🇮🇳'),
        ],
      ),
    );
  }

  Widget _buildLocaleTab(String locale, String label) {
    final isSelected = _selectedLocale == locale;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLocale = locale;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Text(
          label,
          style: AppTypography.caption(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
          ).copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }

  // ── voice state: transcribing simulation ──
  Widget _buildVoiceListeningView() {
    return Column(
      key: const ValueKey('listening'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Concentric animated pulsing waves / active listening bubble
        JarvisAiSpriteBubble(
          state: _isLiveKitConnected
              ? (_isAgentSpeaking ? JarvisBubbleState.speaking : JarvisBubbleState.listening)
              : JarvisBubbleState.listening,
          onTap: () {
            if (_isLiveKitConnected) {
              final finalSpeech = _listeningText;
              _disconnectLiveKit();
              setState(() {
                _isListening = false;
              });
              if (finalSpeech.isNotEmpty) {
                _transcriptEditController.text = finalSpeech;
                setState(() {
                  _currentStep = 4;
                });
              }
            } else {
              _speech.stop();
              setState(() {
                _isListening = false;
              });
              if (_listeningText.isNotEmpty) {
                _transcriptEditController.text = _listeningText;
                setState(() {
                  _currentStep = 4;
                });
              }
            }
          },
        ),
        const SizedBox(height: 48.0),
        Text(
          _isLiveKitConnected ? _livekitStatusText : 'Listening...',
          style: AppTypography.h3(
            color: _isAgentSpeaking ? const Color(0xFFFFA297) : const Color(0xFF6BE5E5)
          ).copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32.0),
        
        // Animated Transcript Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 100.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Text(
            _listeningText.isEmpty ? 'Say something...' : '"$_listeningText"',
            style: AppTypography.display(color: Colors.white).copyWith(
              fontSize: 20.0,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // ── processing state: AI thinking ──
  Widget _buildAIProcessingView() {
    return Column(
      key: const ValueKey('processing'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // AI processing ring
        SizedBox(
          width: 72.0,
          height: 72.0,
          child: Stack(
            children: [
              CircularProgressIndicator(
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFA297)),
                strokeWidth: 4.5,
                backgroundColor: Colors.white.withOpacity(0.04),
              ),
              Positioned.fill(
                child: RotationTransition(
                  turns: const AlwaysStoppedAnimation(0.25),
                  child: CircularProgressIndicator(
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFB68FEB)),
                    strokeWidth: 4.5,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
            ],
          )
          .animate(onPlay: (controller) => controller.repeat())
          .rotate(duration: 1.4.seconds),
        ),
        const SizedBox(height: 32.0),
        Text(
          'Thinking...',
          style: AppTypography.bodyMedium(color: Colors.white).copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          'Jarvis is interpreting your requests',
          style: AppTypography.caption(color: Colors.white.withOpacity(0.4)),
        ),
      ],
    );
  }

  // ── step 1: Draft cards sequential slideshow ──
  Widget _buildDraftCardSequence() {
    if (_draftResults.isEmpty || _currentDraftIndex >= _draftResults.length) {
      return const SizedBox.shrink();
    }

    final result = _draftResults[_currentDraftIndex];
    final total = _draftResults.length;
    final progress = (_currentDraftIndex + 1) / total;

    String typeLabel = 'Draft Element';
    String emoji = '🎯';
    Color themeColor = AppColors.primary;

    switch (result.type) {
      case IntentType.task:
      case IntentType.reminder:
        typeLabel = 'Task Schedule';
        emoji = '🎯';
        themeColor = AppColors.primary;
        break;
      case IntentType.expense:
        typeLabel = 'Expense Record';
        emoji = '💸';
        themeColor = AppColors.error;
        break;
      case IntentType.income:
        typeLabel = 'Income Registry';
        emoji = '💰';
        themeColor = AppColors.success;
        break;
      case IntentType.habit:
        typeLabel = 'Habit Initiation';
        emoji = '🔄';
        themeColor = AppColors.secondary;
        break;
      case IntentType.mood:
        typeLabel = 'Vibe Check-in';
        emoji = '🎭';
        themeColor = const Color(0xFFFFA297);
        break;
      case IntentType.debtAdd:
        typeLabel = 'Debt Agreement';
        emoji = '🤝';
        themeColor = const Color(0xFF6BE5E5);
        break;
      case IntentType.debtPayment:
        typeLabel = 'EMI Collection';
        emoji = '🪙';
        themeColor = const Color(0xFFFFA297);
        break;
      case IntentType.goal:
        typeLabel = 'Financial Goal';
        emoji = '🎯';
        themeColor = AppColors.success;
        break;
      case IntentType.journal:
        typeLabel = 'Journal Entry';
        emoji = '📝';
        themeColor = AppColors.secondary;
        break;
      case IntentType.memory:
        typeLabel = 'Memory Record';
        emoji = '🧠';
        themeColor = const Color(0xFFFFA297);
        break;
      case IntentType.people:
        typeLabel = 'Relationship Event';
        emoji = '🎁';
        themeColor = const Color(0xFF6BE5E5);
        break;
      default:
        typeLabel = 'Productivity Item';
        emoji = '✨';
        themeColor = AppColors.primary;
    }

    return Column(
      key: ValueKey('draft_$_currentDraftIndex'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Slide Count Indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Draft ${_currentDraftIndex + 1} of $total',
                style: AppTypography.micro(color: Colors.white.withOpacity(0.5)).copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(
                width: 60.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2.0),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4.0,
                    color: themeColor,
                    backgroundColor: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),

        // Translucent Draft Card
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(28.0),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 24.0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo/Emoji with a neon pulsing halo
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 76.0,
                      height: 76.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: themeColor.withOpacity(0.12),
                        border: Border.all(color: themeColor.withOpacity(0.2), width: 1.5),
                      ),
                    )
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.15, 1.15), duration: 1.2.seconds),
                    
                    Text(emoji, style: const TextStyle(fontSize: 32.0)),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),

              // Title / Tag
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: themeColor.withOpacity(0.2)),
                  ),
                  child: Text(
                    typeLabel.toUpperCase(),
                    style: AppTypography.micro(color: themeColor).copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),

              // Primary Extracted Action Name
              Text(
                result.originalText,
                style: AppTypography.h2(color: Colors.white).copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              if (result.extractedData.isNotEmpty) ...[
                const SizedBox(height: 16.0),
                const Divider(color: Colors.white10),
                const SizedBox(height: 12.0),
                
                // Extracted Details Layout
                Wrap(
                  spacing: 12.0,
                  runSpacing: 8.0,
                  alignment: WrapAlignment.center,
                  children: result.extractedData.entries.map((entry) {
                    final key = entry.key;
                    var val = entry.value.toString();
                    if (key == 'amount') {
                      val = CurrencyFormatter.format(entry.value as double);
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        '${key[0].toUpperCase()}${key.substring(1)}: $val',
                        style: AppTypography.micro(color: Colors.white.withOpacity(0.6)),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 32.0),

              // Next Arrow Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back / Cancel button
                  TextButton(
                    onPressed: () {
                      if (_currentDraftIndex > 0) {
                        setState(() {
                          _currentDraftIndex--;
                        });
                      } else {
                        _resetInput();
                      }
                    },
                    child: Text(
                      _currentDraftIndex > 0 ? 'Back' : 'Cancel',
                      style: TextStyle(color: Colors.white.withOpacity(0.5)),
                    ),
                  ),

                  // Next Action Arrow
                  GestureDetector(
                    onTap: _nextDraftCard,
                    child: Container(
                      width: 52.0,
                      height: 52.0,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Icon(
                        _currentDraftIndex < total - 1 ? Icons.arrow_forward_rounded : Icons.check_rounded,
                        color: Colors.white,
                      ),
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 1.seconds),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── step 2: Final confirmation summary of all elements ──
  Widget _buildFinalSummaryView() {
    return Container(
      key: const ValueKey('summary'),
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(28.0),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Confirm Actions',
            style: AppTypography.h2(color: Colors.white).copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6.0),
          Text(
            'Jarvis will add these items to your boards:',
            style: AppTypography.caption(color: Colors.white.withOpacity(0.5)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24.0),

          // Items list
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220.0),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _draftResults.length,
              itemBuilder: (context, index) {
                final result = _draftResults[index];
                String emoji = '🎯';
                Color color = AppColors.primary;
                String typeLabel = 'Task';

                if (result.type == IntentType.expense) {
                  emoji = '💸'; color = AppColors.error; typeLabel = 'Expense';
                } else if (result.type == IntentType.income) {
                  emoji = '💰'; color = AppColors.success; typeLabel = 'Income';
                } else if (result.type == IntentType.habit) {
                  emoji = '🔄'; color = AppColors.secondary; typeLabel = 'Habit';
                } else if (result.type == IntentType.mood) {
                  emoji = '🎭'; color = const Color(0xFFFFA297); typeLabel = 'Mood';
                } else if (result.type == IntentType.debtAdd) {
                  emoji = '🤝'; color = const Color(0xFF6BE5E5); typeLabel = 'Debt';
                } else if (result.type == IntentType.goal) {
                  emoji = '🎯'; color = AppColors.success; typeLabel = 'Goal';
                } else if (result.type == IntentType.journal) {
                  emoji = '📝'; color = AppColors.secondary; typeLabel = 'Journal';
                } else if (result.type == IntentType.memory) {
                  emoji = '🧠'; color = const Color(0xFFFFA297); typeLabel = 'Memory';
                } else if (result.type == IntentType.people) {
                  emoji = '🎁'; color = const Color(0xFF6BE5E5); typeLabel = 'Relationship';
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 10.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 18.0)),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.originalText,
                              style: AppTypography.bodyMedium(color: Colors.white).copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              typeLabel,
                              style: AppTypography.micro(color: color).copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24.0),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: JarvisButton(
                  text: 'Reset',
                  isOutline: true,
                  onPressed: _resetInput,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: JarvisButton(
                  text: 'Confirm',
                  onPressed: _confirmAndCreateAll,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── step 3: Conversational Advice View (for irrelevant/chit-chat queries) ──
  Widget _buildConversationalAdviceView() {
    return Container(
      key: const ValueKey('advice'),
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(28.0),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('🤖', style: TextStyle(fontSize: 24.0)),
              const SizedBox(width: 10.0),
              Text(
                'Jarvis AI Assistant',
                style: AppTypography.bodyMedium(color: Colors.white).copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Text(
            _conversationalResponse ?? '',
            style: AppTypography.body(color: Colors.white.withOpacity(0.85)).copyWith(
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24.0),
          JarvisButton(
            text: 'Got it',
            isOutline: true,
            isFullWidth: true,
            onPressed: _resetInput,
          ),
        ],
      ),
    );
  }

  // ── step 4: Transcript Review View ──
  Widget _buildTranscriptReviewView() {
    return Container(
      key: const ValueKey('review'),
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(28.0),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('📝', style: TextStyle(fontSize: 24.0)),
              const SizedBox(width: 10.0),
              Text(
                'Review Transcript',
                style: AppTypography.bodyMedium(color: Colors.white).copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Text(
            'Edit what you said or tap analyze to proceed:',
            style: AppTypography.caption(color: Colors.white.withOpacity(0.5)),
          ),
          const SizedBox(height: 12.0),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _transcriptEditController,
              maxLines: 4,
              style: AppTypography.body(color: Colors.white),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Edit transcript...',
                hintStyle: TextStyle(color: Colors.white30),
              ),
            ),
          ),
          const SizedBox(height: 24.0),
          Row(
            children: [
              Expanded(
                child: JarvisButton(
                  text: 'Cancel',
                  isOutline: true,
                  onPressed: _resetInput,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: JarvisButton(
                  text: 'Analyze with Jarvis',
                  onPressed: () {
                    _processCommand(_transcriptEditController.text);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bottom Glassmorphic Input Bar ──
  Widget _buildBottomInputBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            children: [
              // Voice Icon (Gemini Spark)
              GestureDetector(
                onTap: _connectToLiveKit,
                child: SizedBox(
                  width: 22.0,
                  height: 22.0,
                  child: CustomPaint(
                    painter: GeminiSparkPainter(
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              // Tiny locale selector button next to mic
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedLocale = _selectedLocale == 'en_IN' ? 'ta_IN' : 'en_IN';
                  });
                  ToastNotification.show(
                    context,
                    'Language switched to ${_selectedLocale == 'en_IN' ? 'English (India)' : 'Tamil'}',
                    type: 'info',
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    _selectedLocale == 'en_IN' ? 'EN' : 'TA',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12.0),

              // Text Field Input
              Expanded(
                child: TextField(
                  controller: _inputController,
                  focusNode: _focusNode,
                  style: AppTypography.body(color: Colors.white),
                  onSubmitted: _processCommand,
                  decoration: InputDecoration(
                    hintText: '✨ Type command or tap mic...',
                    hintStyle: AppTypography.body(color: Colors.white.withOpacity(0.35)),
                    border: InputBorder.none,
                  ),
                ),
              ),
              
              const SizedBox(width: 8.0),

              // Submit Action
              GestureDetector(
                onTap: () => _processCommand(_inputController.text),
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: const BoxDecoration(
                    color: Colors.white10,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_upward_rounded,
                    color: Colors.white,
                    size: 18.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum JarvisBubbleState { idle, listening, speaking }

class JarvisAiSpriteBubble extends StatelessWidget {
  final JarvisBubbleState state;
  final VoidCallback? onTap;

  const JarvisAiSpriteBubble({
    super.key,
    required this.state,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isListening = state == JarvisBubbleState.listening;
    final isSpeaking = state == JarvisBubbleState.speaking;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Concentric pulsing/rotating outer halos
          if (isListening || isSpeaking) ...[
            for (int i = 0; i < 3; i++)
              Container(
                width: 120.0 + (i * 35.0),
                height: 120.0 + (i * 35.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (isListening ? const Color(0xFF6BE5E5) : const Color(0xFFFFA297)).withOpacity(0.06 - (i * 0.018)),
                      Colors.transparent,
                    ],
                  ),
                  border: Border.all(
                    color: (isListening ? const Color(0xFF6BE5E5) : const Color(0xFFB68FEB))
                        .withOpacity(0.04 - (i * 0.012)),
                    width: 1.0,
                  ),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                begin: const Offset(0.85, 0.85),
                end: const Offset(1.35, 1.35),
                duration: isSpeaking ? 1.2.seconds : 1.8.seconds,
                delay: (i * 400).ms,
                curve: Curves.easeOut,
              )
              .fade(
                begin: 1.0,
                end: 0.0,
                duration: isSpeaking ? 1.2.seconds : 1.8.seconds,
                delay: (i * 400).ms,
                curve: Curves.easeOut,
              ),
          ] else ...[
            // Idle pulses
            Container(
              width: 150.0,
              height: 150.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFA297).withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.2, 1.2), duration: 2.5.seconds, curve: Curves.easeInOut),
          ],

          // 2. Middle liquid morphing aura bubble
          Container(
            width: 96.0,
            height: 96.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isListening ? const Color(0xFF6BE5E5) : const Color(0xFFB68FEB)).withOpacity(0.35),
                  blurRadius: 28.0,
                  spreadRadius: 2.0,
                ),
              ],
              gradient: LinearGradient(
                colors: isListening
                    ? [const Color(0xFF6BE5E5), const Color(0xFFB68FEB), const Color(0xFF6366FF)]
                    : isSpeaking
                        ? [const Color(0xFFFFA297), const Color(0xFFB68FEB), const Color(0xFF6BE5E5)]
                        : [const Color(0xFFFFA297), const Color(0xFFB68FEB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          )
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scale(
            begin: const Offset(0.96, 0.96),
            end: const Offset(1.06, 1.06),
            duration: isSpeaking ? 0.7.seconds : isListening ? 1.2.seconds : 2.seconds,
            curve: Curves.easeInOut,
          ),

          // 3. Inner solid gradient core containing rotating Gemini Spark
          Container(
            width: 76.0,
            height: 76.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0F172A).withOpacity(0.9),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 1.5,
              ),
            ),
            child: Center(
              child: SizedBox(
                width: 38.0,
                height: 38.0,
                child: CustomPaint(
                  painter: GeminiSparkPainter(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          )
          .animate(onPlay: (controller) => controller.repeat())
          .rotate(
            begin: 0.0,
            end: 2.0 * math.pi,
            duration: isSpeaking ? 3.seconds : isListening ? 6.seconds : 14.seconds,
          ),
        ],
      ),
    );
  }
}

class GeminiSparkPainter extends CustomPainter {
  final Color color;
  GeminiSparkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 2;

    final path = Path();
    path.moveTo(centerX, centerY - radius); // Top
    path.quadraticBezierTo(centerX, centerY, centerX + radius, centerY); // to Right
    path.quadraticBezierTo(centerX, centerY, centerX, centerY + radius); // to Bottom
    path.quadraticBezierTo(centerX, centerY, centerX - radius, centerY); // to Left
    path.quadraticBezierTo(centerX, centerY, centerX, centerY - radius); // back to Top
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
