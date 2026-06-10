import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarvis/core/constants/quotes.dart';

final quoteOfTheDayProvider = Provider<Map<String, String>>((ref) {
  return Quotes.ofTheDay();
});
