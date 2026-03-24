// frontend/lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http; // 引入 http 包
import 'dart:convert'; // 用于 JSON 编解码

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 当前选中的日期，默认是今天
  DateTime _selectedDay = DateTime.now();
  // 日历当前聚焦的日期
  DateTime _focusedDay = DateTime.now();
  final String backendUrl = 'http://127.0.0.1:8000'; 

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
        // TODO: 下一步我们在这里调用获取当日任务的接口，刷新列表
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
            },
            calendarFormat: CalendarFormat.week, 
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: HeaderStyle(
              formatButtonVisible: false, 
              titleCentered: true,
            ),
          ),
          
          const Divider(),

          // 任务列表组件 (占据剩余所有空间)
          Expanded(
            child: ListView.builder(
              itemCount: 3, // 目前写死 3 个假数据占位
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline, color: Colors.grey),
                    title: Text('测试任务 ${index + 1}'),
                    subtitle: Text('14:00 - 15:00\n原因: 这是一个测试占位符'),
                    trailing: Text('High', style: TextStyle(color: Colors.red)),
                    isThreeLine: true,
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