import 'package:jarvis/features/memory/data/models/daily_memory_model.dart';

abstract class MemoryRepository {
  Future<DailyMemoryModel> getDailyMemory(DateTime date);
  Future<Map<String, dynamic>> getWeeklySummary(DateTime weekStart);
  Future<Map<String, dynamic>> getMonthlySummary(int year, int month);
}
