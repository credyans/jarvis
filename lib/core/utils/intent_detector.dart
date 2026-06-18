enum IntentType {
  task,
  expense,
  income,
  reminder,
  habit,
  mood,
  debtPayment,
  debtAdd,
  goal,
  journal,
  memory,
  people,
  unknown,
}

class IntentResult {
  final IntentType type;
  final String originalText;
  final Map<String, dynamic> extractedData;

  const IntentResult({
    required this.type,
    required this.originalText,
    this.extractedData = const {},
  });

  @override
  String toString() =>
      'IntentResult(type: $type, text: "$originalText", data: $extractedData)';
}

class IntentDetector {
  // ── Amount patterns ──────────────────────────────────────────────────
  static final _amountPatterns = [
    RegExp(r'₹\s?([\d,]+\.?\d*)', caseSensitive: false),
    RegExp(r'(?:rs\.?|rupees?|inr)\s?([\d,]+\.?\d*)', caseSensitive: false),
    RegExp(r'([\d,]+\.?\d*)\s?(?:rs\.?|rupees?|inr)', caseSensitive: false),
    RegExp(r'\b(\d{2,}(?:,\d+)*(?:\.\d+)?)\b'), // standalone numbers ≥ 2 digits
  ];

  // ── Time patterns ────────────────────────────────────────────────────
  static final _timePattern = RegExp(
    r'\b(\d{1,2}(?::\d{2})?\s*(?:am|pm|AM|PM))\b',
  );
  static final _time24Pattern = RegExp(r'\b(\d{1,2}:\d{2})\b');

  // ── Relative date patterns ───────────────────────────────────────────
  static final _relativeDatePatterns = {
    'today': RegExp(r'\btoday\b', caseSensitive: false),
    'tomorrow': RegExp(r'\btomorrow\b', caseSensitive: false),
    'day_after': RegExp(r'\bday after tomorrow\b', caseSensitive: false),
    'tonight': RegExp(r'\btonight\b', caseSensitive: false),
    'this_evening': RegExp(r'\bthis evening\b', caseSensitive: false),
    'this_weekend': RegExp(r'\bthis weekend\b', caseSensitive: false),
    'next_week': RegExp(r'\bnext week\b', caseSensitive: false),
    'next_month': RegExp(r'\bnext month\b', caseSensitive: false),
  };

  // ── Keyword sets ─────────────────────────────────────────────────────
  static const _moodKeywords = [
    'feeling', 'mood', 'stressed', 'happy', 'anxious', 'great', 'tired',
    'sad', 'angry', 'calm', 'excited', 'bored', 'grateful', 'lonely',
    'overwhelmed', 'peaceful', 'frustrated', 'energetic', 'sleepy',
    'motivated', 'depressed', 'cheerful', 'nervous', 'relaxed',
    'irritated', 'content', 'worried', 'hopeful', 'exhausted',
    'santhosham', 'stress-a iruku', 'kavalai', 'sandhosha',
  ];

  static const _expenseKeywords = [
    'spent', 'paid', 'cost', 'bought', 'expense', 'charged',
    'billed', 'purchased', 'payment for', 'selavu', 'kuduthen', 'kasa kuduthen',
  ];

  static const _incomeKeywords = [
    'earned', 'salary', 'received', 'got paid', 'income',
    'credited', 'bonus', 'freelance', 'cashback', 'refund',
    'reimbursement', 'dividend', 'interest earned', 'vanthuchu', 'kasa kuduthanga', 'kasa kudutha',
  ];

  static const _taskKeywords = [
    'buy', 'get', 'do', 'call', 'book', 'send', 'submit',
    'finish', 'complete', 'pick up', 'drop off', 'schedule',
    'arrange', 'prepare', 'fix', 'clean', 'wash', 'cook',
    'check', 'visit', 'go to', 'return', 'cancel', 'renew',
    'apply', 'register', 'sign up', 'download', 'install',
    'update', 'review', 'write', 'print', 'order', 'need to',
    'have to', 'should', 'must', 'make', 'create', 'seiyanum', 'vaanganum', 'pannanum', 'panni',
  ];

  static const _reminderKeywords = [
    'remind', 'reminder', 'remind me', 'don\'t forget',
    'remember to', 'alert me', 'notify me', 'gyabagam', 'gyabaga paduthu', 'gyabaga paduthavum',
  ];

  static const _habitKeywords = [
    'habit', 'track', 'start tracking', 'daily', 'every day',
    'routine', 'streak', 'practice',
  ];

  static const _goalKeywords = [
    'goal', 'save', 'budget', 'financial goal', 'saving target', 'save target',
    'save pannanum', 'சேமிக்க', 'target', 'kanavu',
  ];

  static const _journalKeywords = [
    'journal', 'diary', 'thought', 'notes', 'write diary', 'write journal', 'thoughts',
    'diary ezhuthu', 'diary ezhuthunum', 'ezhuthunum kurippu', 'kurippu ezhuthu',
  ];

  static const _memoryKeywords = [
    'memory', 'highlight', 'log memory', 'moment', 'special moment', 'keep memory', 'memories',
    'gyabagam vechuko', 'nalla moment', 'gyabagam', 'milestone', 'career', 'promotion', 'promoted',
    'trip', 'travel', 'vacation', 'purchased', 'bought', 'health', 'achievement', 'achieved',
  ];

  static const _peopleKeywords = [
    'birthday', 'anniversary', 'born', 'relationship', 'relation',
  ];

  // ── Debt patterns ────────────────────────────────────────────────────
  static final _debtPaymentPatterns = [
    RegExp(r'(\w+)\s+paid', caseSensitive: false),
    RegExp(r'collected\s+from\s+(\w+)', caseSensitive: false),
    RegExp(r'received\s+from\s+(\w+)', caseSensitive: false),
    RegExp(r'(\w+)\s+returned', caseSensitive: false),
    RegExp(r'(\w+)\s+gave\s+back', caseSensitive: false),
    RegExp(r'got\s+back\s+from\s+(\w+)', caseSensitive: false),
    RegExp(r'(\w+)\s+settled', caseSensitive: false),
    RegExp(r'(\w+)\s+cleared', caseSensitive: false),
  ];

  static final _debtAddPatterns = [
    RegExp(r'(\w+)\s+owes', caseSensitive: false),
    RegExp(r'lent\s+(?:to\s+)?(\w+)', caseSensitive: false),
    RegExp(r'(\w+)\s+borrowed', caseSensitive: false),
    RegExp(r'gave\s+(?:to\s+)?(\w+)', caseSensitive: false),
    RegExp(r'(\w+)\s+took', caseSensitive: false),
    RegExp(r'loan\s+to\s+(\w+)', caseSensitive: false),
  ];

  // ── Excluded names (common false positives) ──────────────────────────
  static const _excludedNames = {
    'i', 'me', 'my', 'he', 'she', 'it', 'we', 'they', 'the', 'a', 'an',
    'this', 'that', 'who', 'what', 'which', 'some', 'all', 'just',
  };

  /// Splits input text by logical separators and detects all intents.
  static List<IntentResult> detectMultiple(String input) {
    if (input.trim().isEmpty) return [];

    // Split on "and", "then", or commas
    final separator = RegExp(r'\band\b|\bthen\b|,', caseSensitive: false);
    final parts = input.split(separator);

    final results = <IntentResult>[];
    for (var part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      results.add(detect(trimmed));
    }
    return results;
  }

  /// Checks if the input text contains no domain keywords or relevant metadata.
  static bool isIrrelevant(String text) {
    final lower = text.toLowerCase().trim();
    if (lower.isEmpty) return true;

    final hasAmount = _extractAmount(lower) != null;
    final hasTime = _extractTime(lower) != null;
    final hasRelativeDate = _extractRelativeDate(lower) != null;
    final hasMood = _matchesAny(lower, _moodKeywords);
    final hasExpense = _matchesAny(lower, _expenseKeywords);
    final hasIncome = _matchesAny(lower, _incomeKeywords);
    final hasTask = _matchesAny(lower, _taskKeywords);
    final hasReminder = _matchesAny(lower, _reminderKeywords);
    final hasHabit = _matchesAny(lower, _habitKeywords);
    final hasGoal = _matchesAny(lower, _goalKeywords);
    final hasJournal = _matchesAny(lower, _journalKeywords);
    final hasMemory = _matchesAny(lower, _memoryKeywords);
    final hasPeople = _matchesAny(lower, _peopleKeywords) || _isBirthdayPattern(lower);
    final hasDebtPayment = _extractPerson(lower, _debtPaymentPatterns) != null;
    final hasDebtAdd = _extractPerson(lower, _debtAddPatterns) != null;

    final otherDomainWords = [
      'money', 'savings', 'save', 'priority', 'debt', 'loan', 'lent',
      'owes', 'owe', 'spend', 'buy', 'do', 'task', 'habit', 'mood',
      'journal', 'note', 'feeling', 'vibe', 'birthday', 'anniversary'
    ];
    final hasOtherDomain = otherDomainWords.any((word) =>
        RegExp('\\b$word\\b', caseSensitive: false).hasMatch(lower));

    return !(hasAmount ||
        hasTime ||
        hasRelativeDate ||
        hasMood ||
        hasExpense ||
        hasIncome ||
        hasTask ||
        hasReminder ||
        hasHabit ||
        hasGoal ||
        hasJournal ||
        hasMemory ||
        hasPeople ||
        hasDebtPayment ||
        hasDebtAdd ||
        hasOtherDomain);
  }

  /// Detects the intent from natural language input.
  static IntentResult detect(String input) {
    if (input.trim().isEmpty) {
      return IntentResult(
        type: IntentType.unknown,
        originalText: input,
      );
    }

    final lower = input.toLowerCase().trim();
    final data = <String, dynamic>{};

    // Extract amount
    final amount = _extractAmount(lower);
    if (amount != null) {
      data['amount'] = amount;
    }

    // Extract time
    final time = _extractTime(lower);
    if (time != null) {
      data['time'] = time;
    }

    // Extract relative date
    final relativeDate = _extractRelativeDate(lower);
    if (relativeDate != null) {
      data['relativeDate'] = relativeDate;
    }

    // ── Priority-ordered classification ────────────────────────────────

    // 1. Mood – check first because mood phrases are distinct
    if (_matchesAny(lower, _moodKeywords)) {
      final moodWord = _findMatchingKeyword(lower, _moodKeywords);
      if (moodWord != null) data['mood'] = moodWord;
      return IntentResult(
        type: IntentType.mood,
        originalText: input,
        extractedData: data,
      );
    }

    // 2. Debt payment – person-based patterns
    final debtPaymentPerson = _extractPerson(lower, _debtPaymentPatterns);
    if (debtPaymentPerson != null) {
      data['person'] = debtPaymentPerson;
      return IntentResult(
        type: IntentType.debtPayment,
        originalText: input,
        extractedData: data,
      );
    }

    // 3. Debt add – person-based patterns
    final debtAddPerson = _extractPerson(lower, _debtAddPatterns);
    if (debtAddPerson != null) {
      data['person'] = debtAddPerson;
      return IntentResult(
        type: IntentType.debtAdd,
        originalText: input,
        extractedData: data,
      );
    }

    // 3.5. People - birthdays / anniversaries
    if (_matchesAny(lower, _peopleKeywords) || _isBirthdayPattern(lower)) {
      _extractPeopleData(input, data);
      return IntentResult(
        type: IntentType.people,
        originalText: input,
        extractedData: data,
      );
    }

    // 4. Goals
    if (_matchesAny(lower, _goalKeywords)) {
      return IntentResult(
        type: IntentType.goal,
        originalText: input,
        extractedData: data,
      );
    }

    // 5. Journal Entries
    if (_matchesAny(lower, _journalKeywords)) {
      return IntentResult(
        type: IntentType.journal,
        originalText: input,
        extractedData: data,
      );
    }

    // 6. Memory Records
    if (_matchesAny(lower, _memoryKeywords)) {
      data['memoryType'] = _detectMemoryType(lower);
      return IntentResult(
        type: IntentType.memory,
        originalText: input,
        extractedData: data,
      );
    }

    // 7. Income
    if (_matchesAny(lower, _incomeKeywords)) {
      return IntentResult(
        type: IntentType.income,
        originalText: input,
        extractedData: data,
      );
    }

    // 8. Expense
    if (_matchesAny(lower, _expenseKeywords)) {
      return IntentResult(
        type: IntentType.expense,
        originalText: input,
        extractedData: data,
      );
    }

    // 9. Reminder (task + time)
    if (_matchesAny(lower, _reminderKeywords)) {
      _extractCleanTitleAndTag(input, data);
      return IntentResult(
        type: IntentType.reminder,
        originalText: input,
        extractedData: data,
      );
    }

    // 10. Habit
    if (_matchesAny(lower, _habitKeywords)) {
      return IntentResult(
        type: IntentType.habit,
        originalText: input,
        extractedData: data,
      );
    }

    // 11. Task (broadest match – checked last among known intents)
    if (_matchesAny(lower, _taskKeywords)) {
      _extractCleanTitleAndTag(input, data);
      // If it has a time component, treat as reminder
      if (time != null || relativeDate != null) {
        return IntentResult(
          type: IntentType.reminder,
          originalText: input,
          extractedData: data,
        );
      }
      return IntentResult(
        type: IntentType.task,
        originalText: input,
        extractedData: data,
      );
    }

    // 12. If there's an amount but no other match, default to expense
    if (amount != null) {
      return IntentResult(
        type: IntentType.expense,
        originalText: input,
        extractedData: data,
      );
    }

    // 13. Unknown – still return the text, may be treated as a quick task
    _extractCleanTitleAndTag(input, data);
    return IntentResult(
      type: IntentType.unknown,
      originalText: input,
      extractedData: data,
    );
  }

  static void _extractCleanTitleAndTag(String input, Map<String, dynamic> data) {
    String cleanTitle = input;
    // Remove relative date keywords
    for (final pattern in _relativeDatePatterns.values) {
      cleanTitle = cleanTitle.replaceAll(pattern, '');
    }
    // Remove time patterns
    cleanTitle = cleanTitle.replaceAll(_timePattern, '');
    cleanTitle = cleanTitle.replaceAll(_time24Pattern, '');

    // Extract tag ID if it contains office terms (e.g. after office, from office)
    final tagMatch = RegExp(r'\b(?:after|at|before|from)\s+office\b', caseSensitive: false).firstMatch(cleanTitle);
    if (tagMatch != null) {
      data['tag'] = 'After Office';
      cleanTitle = cleanTitle.replaceAll(tagMatch.group(0)!, '');
    }

    // Strip out common task verb prefixes to get clean titles
    final verbClean = RegExp(r'^\s*\b(?:buy|get|do|call|book|send|submit|finish|complete|remind me to|gyabagam|gyabaga paduthu)\b\s*', caseSensitive: false);
    cleanTitle = cleanTitle.replaceAll(verbClean, '');

    // Clean prepositions and dates near ends
    cleanTitle = cleanTitle.replaceAll(RegExp(r'\b(?:at|on|by|today|tomorrow|today morning|tonight)\b\s*$', caseSensitive: false), '');
    cleanTitle = cleanTitle.replaceAll(RegExp(r'^\s*\b(?:at|on|by)\b', caseSensitive: false), '');

    cleanTitle = cleanTitle.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (cleanTitle.isNotEmpty) {
      data['cleanTitle'] = cleanTitle[0].toUpperCase() + cleanTitle.substring(1);
    } else {
      data['cleanTitle'] = input;
    }
  }

  // ── Private helpers ──────────────────────────────────────────────────

  static bool _matchesAny(String text, List<String> keywords) {
    return keywords.any((kw) {
      if (kw.contains(' ')) {
        return text.contains(kw);
      }
      return RegExp('\\b${RegExp.escape(kw)}\\b').hasMatch(text);
    });
  }

  static String? _findMatchingKeyword(String text, List<String> keywords) {
    for (final kw in keywords) {
      if (kw.contains(' ')) {
        if (text.contains(kw)) return kw;
      } else {
        if (RegExp('\\b${RegExp.escape(kw)}\\b').hasMatch(text)) return kw;
      }
    }
    return null;
  }

  static double? _extractAmount(String text) {
    for (final pattern in _amountPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.group(1) != null) {
        final cleaned = match.group(1)!.replaceAll(',', '');
        final value = double.tryParse(cleaned);
        if (value != null && value > 0) return value;
      }
    }
    return null;
  }

  static String? _extractTime(String text) {
    final match12 = _timePattern.firstMatch(text);
    if (match12 != null) return match12.group(1)!.trim();

    final match24 = _time24Pattern.firstMatch(text);
    if (match24 != null) return match24.group(1)!.trim();

    return null;
  }

  static String? _extractRelativeDate(String text) {
    for (final entry in _relativeDatePatterns.entries) {
      if (entry.value.hasMatch(text)) return entry.key;
    }
    return null;
  }

  static String? _extractPerson(String text, List<RegExp> patterns) {
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final name = match.group(1)?.trim();
        if (name != null &&
            name.isNotEmpty &&
            !_excludedNames.contains(name.toLowerCase())) {
          // Capitalize the name
          return name[0].toUpperCase() + name.substring(1).toLowerCase();
        }
      }
    }
    return null;
  }

  static bool _isBirthdayPattern(String text) {
    return text.contains('birthday') || text.contains('anniversary');
  }

  static void _extractPeopleData(String input, Map<String, dynamic> data) {
    final lower = input.toLowerCase();
    final birthdayMatch = RegExp(r'(\w+)\s+(?:s\s+)?birthday', caseSensitive: false).firstMatch(input);
    final anniversaryMatch = RegExp(r'(\w+)\s+(?:s\s+)?anniversary', caseSensitive: false).firstMatch(input);
    
    String? name;
    String type = 'birthday';
    
    if (birthdayMatch != null) {
      name = birthdayMatch.group(1);
    } else if (anniversaryMatch != null) {
      name = anniversaryMatch.group(1);
      type = 'anniversary';
    }
    
    if (name != null && name.toLowerCase() != 'my') {
      data['name'] = name[0].toUpperCase() + name.substring(1).toLowerCase();
    } else {
      data['name'] = 'Friend';
    }
    
    data['eventType'] = type;
    
    final datePattern = RegExp(
      r'\b(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|jun|jul|aug|sep|oct|nov|dec)\s+\d{1,2}(?:st|nd|rd|th)?\b|\b\d{1,2}(?:st|nd|rd|th)?\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|jun|jul|aug|sep|oct|nov|dec)\b',
      caseSensitive: false,
    );
    
    final match = datePattern.firstMatch(lower);
    if (match != null) {
      data['dateText'] = match.group(0);
    } else {
      data['dateText'] = 'June 18'; // Fallback
    }
  }

  static String _detectMemoryType(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('travel') || lower.contains('trip') || lower.contains('vacation') || lower.contains('visited')) {
      return 'travel';
    }
    if (lower.contains('milestone') || lower.contains('achievement') || lower.contains('achieved') || lower.contains('won')) {
      return 'milestone';
    }
    if (lower.contains('career') || lower.contains('promotion') || lower.contains('promoted') || lower.contains('job') || lower.contains('office')) {
      return 'career';
    }
    if (lower.contains('purchase') || lower.contains('bought') || lower.contains('spent') || lower.contains('cost')) {
      return 'purchase';
    }
    if (lower.contains('health') || lower.contains('doctor') || lower.contains('hospital') || lower.contains('sick') || lower.contains('workout')) {
      return 'health';
    }
    if (lower.contains('financial') || lower.contains('earned') || lower.contains('saved') || lower.contains('budget') || lower.contains('invest')) {
      return 'financial';
    }
    return 'general';
  }
}
