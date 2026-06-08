import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mes recettes',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('mes recettes faciles'),
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container( 
            padding: const EdgeInsets.only(bottom: 20),
            child: Text('Pizza faciles!', style: TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
          ),
          Text("par Andy.CEO", style: TextStyle(fontSize: 12))
        ],
      ),
    );
  }
}
