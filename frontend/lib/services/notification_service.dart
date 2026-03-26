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
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

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

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );

    // 👇 👇 👇 新增以下代码：主动向 Android 系统请求权限 👇 👇 👇
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      // 1. 请求发送系统通知的权限 (Android 13+ 必须)
      await androidImplementation.requestNotificationsPermission();
      // 2. 请求设置精准闹钟的权限 (Android 12+ 必须，否则定时器不生效)
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  // 核心方法：为特定任务安排定时通知
  Future<void> scheduleTaskNotification(Task task) async {
    final now = DateTime.now();
    
    // 如果任务已经完成，或者开始时间已经是过去式，就不再安排提醒
    if (task.status == 'completed' || task.startTime.isBefore(now)) {
      return;
    }

    // 计划提醒时间：任务开始前 10 分钟
    final scheduledTime = task.startTime.subtract(const Duration(minutes: 10));
    
    tz.TZDateTime tzScheduledTime;
    String bodyText;

    // 判断：现在距离任务开始，是否已经不足 10 分钟了？
    if (scheduledTime.isBefore(now)) {
      // 补偿机制：5秒后立刻提醒
      tzScheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));
      
      // 动态计算还剩几分钟
      int minutesLeft = task.startTime.difference(now).inMinutes;
      if (minutesLeft > 0) {
        bodyText = '即将开始！(还剩约 $minutesLeft 分钟) ${task.reason}';
      } else {
        bodyText = '任务时间已到！请尽快处理。${task.reason}';
      }
    } else {
      // 正常机制：未来的任务，严格在提前 10 分钟时触发
      tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
      bodyText = '将于 10 分钟后开始。${task.reason}';
    }

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

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: task.id, 
      title: '⏰ 日程提醒: ${task.taskName}',
      body: bodyText, // 👇 这里使用了动态生成的文本
      scheduledDate: tzScheduledTime,
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, 
    );
    
    print("✅ 已成功注册定时通知：[${task.taskName}]，提醒时间：$tzScheduledTime，文案：$bodyText");
  }

  // 取消通知
  Future<void> cancelNotification(int taskId) async {
    // 🚨 修正 4：V20 强制要求使用命名参数 id:
    await flutterLocalNotificationsPlugin.cancel(id: taskId);
    print("❌ 已取消通知：ID $taskId");
  }
}