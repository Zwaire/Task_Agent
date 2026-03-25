// frontend/lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task_model.dart';

class NotificationService {
  // 单例模式
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 初始化时区，定时推送必须依赖时区
    tz.initializeTimeZones();

    // Android 初始化配置
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS/macOS 初始化配置
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    // 🚨 修正 1：V20 开始强制要求使用命名参数 initializationSettings:
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  // 核心方法：为特定任务安排定时通知
  Future<void> scheduleTaskNotification(Task task) async {
    // 如果任务已经完成，或者开始时间已经是过去式，就不再安排提醒
    if (task.status == 'completed' || task.startTime.isBefore(DateTime.now())) {
      return;
    }

    // 设定提醒时间：比如在任务开始前 10 分钟提醒
    final scheduledTime = task.startTime.subtract(const Duration(minutes: 10));
    
    // 如果提前 10 分钟的时间也已经过去了，就立刻提醒 (5秒后)
    final tz.TZDateTime tzScheduledTime = scheduledTime.isBefore(DateTime.now())
        ? tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)) 
        : tz.TZDateTime.from(scheduledTime, tz.local);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'task_reminder_channel', 
      '日程提醒',               
      channelDescription: '用于智能日程Agent的任务开始前提醒',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // 🚨 修正 2 & 3：V20 强制使用全命名参数，删除了旧的 iOS 兼容代码，使用了新的 AndroidScheduleMode
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: task.id, 
      title: '⏰ 日程提醒: ${task.taskName}',
      body: '将于 10 分钟后开始。${task.reason}',
      scheduledDate: tzScheduledTime,
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, 
    );
    
    print("✅ 已成功注册定时通知：[${task.taskName}]，提醒时间：$tzScheduledTime");
  }

  // 取消通知
  Future<void> cancelNotification(int taskId) async {
    // 🚨 修正 4：V20 强制要求使用命名参数 id:
    await flutterLocalNotificationsPlugin.cancel(id: taskId);
    print("❌ 已取消通知：ID $taskId");
  }
}