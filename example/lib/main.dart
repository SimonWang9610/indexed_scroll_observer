import 'package:flutter/material.dart';

import 'example/examples.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Indexed Scroll Observer Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            OutlinedButton(
              onPressed: () {
                context.push(
                  const OfficialListExample(),
                );
              },
              child: const Text("List view Usage"),
            ),
            OutlinedButton(
              onPressed: () {
                context.push(
                  const OfficialReorderableListExample(),
                );
              },
              child: const Text("Reorderable List Usage"),
            ),
            OutlinedButton(
              onPressed: () {
                context.push(
                  const OfficialSeparatedListExample(),
                );
              },
              child: const Text("Separated List Usage"),
            ),
            OutlinedButton(
              onPressed: () {
                context.push(const PositionedGridExample());
              },
              child: const Text("Encapsulated Grid Usage"),
            ),
            OutlinedButton(
              onPressed: () {
                context.push(const CustomViewExample());
              },
              child: const Text("Encapsulated CustomScrollView Usage"),
            ),
          ],
        ),
      ),
    );
  }
}

extension Navigation on BuildContext {
  void push(Widget page) {
    Navigator.of(this).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }
}
