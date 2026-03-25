// frontend/lib/main.dart
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart'; // 引入服务

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Scheduler',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // 使用 Material 3 设计规范，UI 更现代
        useMaterial3: true, 
      ),
      home: HomeScreen(),
      // 隐藏右上角的 Debug 标签
      debugShowCheckedModeBanner: false,
    );
  }
}