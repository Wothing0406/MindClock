import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/models/daily_todo_task.dart';
import '../../domain/services/schedule_widget_bridge.dart';

class MethodChannelScheduleWidgetBridge extends ScheduleWidgetBridge {
  const MethodChannelScheduleWidgetBridge({
    MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName = 'mindclock/schedule_widget';

  final MethodChannel _channel;

  @override
  bool get isPlatformConnected => true;

  @override
  Future<void> syncWidgetSnapshot(ScheduleWidgetSnapshot snapshot) async {
    try {
      await _channel.invokeMethod<void>(
        'syncWidgetSnapshot',
        <String, dynamic>{
          'snapshotJson': jsonEncode(snapshot.toJson()),
        },
      );
    } on PlatformException {
      // Không chặn luồng học nếu launcher/OS chưa cài widget.
    } on MissingPluginException {
      // An toàn trên môi trường không phải Android.
    }
  }

  @override
  Future<void> scheduleTaskReminder(DailyTodoTask task) async {
    try {
      await _channel.invokeMethod<void>(
        'scheduleTaskReminder',
        task.toJson(),
      );
    } on PlatformException {
      // Không làm kẹt tạo việc nếu thiếu quyền thông báo.
    } on MissingPluginException {
      // An toàn trên môi trường không phải Android.
    }
  }

  @override
  Future<void> cancelTaskReminder(String taskId) async {
    try {
      await _channel.invokeMethod<void>(
        'cancelTaskReminder',
        <String, dynamic>{'taskId': taskId},
      );
    } on PlatformException {
      // Không chặn thao tác Done/Xóa.
    } on MissingPluginException {
      // An toàn trên môi trường không phải Android.
    }
  }
}
