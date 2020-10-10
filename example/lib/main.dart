import 'package:flutter/material.dart';
import 'package:nodirectionview_example/demopage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('No Direction View example app'),
        ),
        body: Center(
          child: DemoPage(),
        ),
      ),
    );
  }
}
