import 'package:flutter/material.dart';
import 'package:tractian_mobile_challenge/views/menu_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tractian',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: false, appBarTheme: AppBarTheme(backgroundColor: Color(0xff17192d))),
      home: const MenuView(),
    );
  }
}
