import 'package:flutter/material.dart';

void main() {
  runApp(const PayasunApp());
}

class PayasunApp extends StatelessWidget {
  const PayasunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Payasun',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFE94560),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Payasun Mobile App — Coming Soon'),
        ),
      ),
    );
  }
}
