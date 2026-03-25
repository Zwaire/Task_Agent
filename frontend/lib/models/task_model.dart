// frontend/lib/models/task_model.dart

class Task {
  final int id;
  final String taskName;
  final DateTime startTime;
  final DateTime endTime;
  final String priority;
  final String reason;
  String status;

  Task({
    required this.id,
    required this.taskName,
    required this.startTime,
    required this.endTime,
    required this.priority,
    required this.reason,
    required this.status,
  });

  // 从后端的 JSON 字典转换为 Dart 对象
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      taskName: json['task_name'],
      // 后端传过来的是 ISO 8601 字符串，直接 parse 解析成 DateTime 对象
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      priority: json['priority'],
      reason: json['reason'],
      status: json['status'],
    );
  }
}