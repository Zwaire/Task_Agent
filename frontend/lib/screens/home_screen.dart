// frontend/lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http; // 引入 http 包
import 'dart:convert'; // 用于 JSON 编解码
import '../models/task_model.dart'; // 引入任务模型
import '../services/notification_service.dart'; 
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 当前选中的日期，默认是今天
  DateTime _selectedDay = DateTime.now();
  // 日历当前聚焦的日期
  DateTime _focusedDay = DateTime.now();
  final String backendUrl = 'http://192.168.43.80:8000'; 

  // 向后端发送自然语言进行排期
  Future<void> _submitScheduleText(String text, BuildContext context) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_input': text}),
      );

      if (response.statusCode == 200) {
        // 请求成功
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 智能排期成功！数据已入库。')),
        );
        _fetchTasks();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('排期失败：${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('网络请求异常，请检查后端是否启动: $e')),
      );
    }
  }

  // 唤起底部的 AI 输入弹窗
  void _showAiInputDialog() {
    final TextEditingController _textController = TextEditingController();
    bool _isLoading = false; 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "告诉 Agent 你的安排",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _textController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: "例如：明天下午2点有个会，大概一小时。晚上抽空写代码模块分析报告...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          onPressed: () async {
                            final text = _textController.text.trim();
                            if (text.isEmpty) return;

                            setModalState(() {
                              _isLoading = true;
                            });

                            await _submitScheduleText(text, context);

                            setModalState(() {
                              _isLoading = false;
                            });
                            if (mounted) Navigator.pop(context);
                          },
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text("让 AI 帮我排期"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Task> _allTasks = []; // 存放从后端拉取的所有任务
  List<Task> _selectedDayTasks = []; // 存放当前日历选中天的任务

  @override
  void initState() {
    super.initState();
    _fetchTasks(); // 页面刚加载时，主动去拉取一次数据
  }

  // 从后端拉取所有日程
  Future<void> _fetchTasks() async {
    try {
      final response = await http.get(Uri.parse('$backendUrl/api/schedule'));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _allTasks = data.map((json) => Task.fromJson(json)).toList();
        });
        _updateSelectedDayTasks();
        
        for (var task in _allTasks) {
          NotificationService().scheduleTaskNotification(task);
        }
      }
    } catch (e) {
      print("拉取数据失败: $e");
    }
  }

  // 切换任务状态 (打勾/取消打勾)
  Future<void> _toggleTaskStatus(Task task) async {
    final newStatus = task.status == 'completed' ? 'pending' : 'completed';
    try {
      final response = await http.put(
        Uri.parse('$backendUrl/api/schedule/${task.id}/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        setState(() {
          task.status = newStatus; // 仅在本地刷新状态，不用重新拉取整个列表
        });

        if (newStatus == 'completed') {
          NotificationService().cancelNotification(task.id);
        } else {
          NotificationService().scheduleTaskNotification(task);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('状态更新失败: $e')));
    }
  }

  // 删除任务 (左滑删除)
  Future<void> _deleteTask(int taskId) async {
    try {
      final response = await http.delete(
        Uri.parse('$backendUrl/api/schedule/$taskId'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _allTasks.removeWhere((t) => t.id == taskId); // 从总列表中移除
          _updateSelectedDayTasks(); // 重新过滤当前显示的列表
        });
        NotificationService().cancelNotification(taskId);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🗑️ 日程已删除')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败: $e')));
    }
  }

  // 根据当前选中的日期，过滤任务列表
  void _updateSelectedDayTasks() {
    setState(() {
      _selectedDayTasks = _allTasks.where((task) {
        return isSameDay(task.startTime, _selectedDay);
      }).toList();

      _selectedDayTasks.sort((a, b) => a.startTime.compareTo(b.startTime));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('智能日程 Agent'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay; 
              });
              _updateSelectedDayTasks(); // 每次选中日期变化时，更新任务列表
            },
            calendarFormat: CalendarFormat.week, 
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: HeaderStyle(
              formatButtonVisible: false, 
              titleCentered: true,
            ),
          ),
          
          const Divider(),

          // 任务列表组件
          Expanded(
            child: _selectedDayTasks.isEmpty
                ? const Center(
                    child: Text('今天没有安排任务哦，快去右下角找 Agent 安排吧！', 
                                style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: _selectedDayTasks.length,
                    itemBuilder: (context, index) {
                      final task = _selectedDayTasks[index];
                      // 格式化时间，比如只显示 14:00
                      final startTimeStr = "${task.startTime.hour.toString().padLeft(2, '0')}:${task.startTime.minute.toString().padLeft(2, '0')}";
                      final endTimeStr = "${task.endTime.hour.toString().padLeft(2, '0')}:${task.endTime.minute.toString().padLeft(2, '0')}";

                      // 根据优先级显示不同颜色
                      Color priorityColor = Colors.green;
                      if (task.priority.toLowerCase() == 'high') priorityColor = Colors.red;
                      if (task.priority.toLowerCase() == 'medium') priorityColor = Colors.orange;

                      // 使用 Dismissible 包裹 Card 实现滑动删除
                      return Dismissible(
                        // 每个 Dismissible 必须有一个全局唯一的 Key
                        key: Key(task.id.toString()),
                        direction: DismissDirection.endToStart, // 仅允许从右向左滑动
                        // 滑动时露出的红色背景和垃圾桶图标
                        background: Container(
                          color: Colors.red.shade400,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: const Icon(Icons.delete_outline, color: Colors.white, size: 30),
                        ),
                        // 确认滑动完成后的回调
                        onDismissed: (direction) {
                          _deleteTask(task.id);
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          elevation: 2,
                          child: ListTile(
                            // 👈 把原来的 Icon 改成 IconButton
                            leading: IconButton(
                              icon: Icon(
                                task.status == 'completed' ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: task.status == 'completed' ? Colors.green : Colors.grey,
                                size: 28,
                              ),
                              onPressed: () => _toggleTaskStatus(task), // 点击触发状态切换
                            ),
                            title: Text(
                              task.taskName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: task.status == 'completed' ? TextDecoration.lineThrough : null,
                                color: task.status == 'completed' ? Colors.grey : Colors.black87,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('🕒 $startTimeStr - $endTimeStr', style: const TextStyle(color: Colors.blueGrey)),
                                  const SizedBox(height: 4),
                                  Text('💡 ${task.reason}', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                            trailing: Text(task.priority.toUpperCase(), style: TextStyle(color: priorityColor, fontWeight: FontWeight.bold)),
                            isThreeLine: true,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      
      // 核心交互按钮：召唤 AI 助理
      floatingActionButton: FloatingActionButton(
        onPressed: _showAiInputDialog, // 替换这里，绑定唤起弹窗的方法
        child: const Icon(Icons.mic), 
        tooltip: '智能安排任务',
      ),
    );
  }
}