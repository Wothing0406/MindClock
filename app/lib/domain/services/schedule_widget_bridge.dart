import '../models/daily_todo_task.dart';

/// Hợp đồng đồng bộ lịch trình hôm nay ra Android Home Screen Widget & nhắc việc cục bộ.
abstract class ScheduleWidgetBridge {
  const ScheduleWidgetBridge();

  bool get isPlatformConnected;

  Future<void> syncWidgetSnapshot(ScheduleWidgetSnapshot snapshot);

  Future<void> scheduleTaskReminder(DailyTodoTask task);

  Future<void> cancelTaskReminder(String taskId);
}

class UnboundScheduleWidgetBridge extends ScheduleWidgetBridge {
  const UnboundScheduleWidgetBridge();

  @override
  bool get isPlatformConnected => false;

  @override
  Future<void> syncWidgetSnapshot(ScheduleWidgetSnapshot snapshot) async {}

  @override
  Future<void> scheduleTaskReminder(DailyTodoTask task) async {}

  @override
  Future<void> cancelTaskReminder(String taskId) async {}
}
