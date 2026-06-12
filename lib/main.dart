import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

Widget buildButton(String text, VoidCallback onPressed) {
  return ElevatedButton(
    onPressed: onPressed,
    child: Text(
      text,
      style: const TextStyle(fontSize: 24),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculatrice by andy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
       
        colorScheme: ColorScheme.fromSeed(
  seedColor: Colors.deepPurple,
),
      ),
      home: const MyHomePage(title: 'Calculatrice'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String display = "";

  void clearAll() {
  setState(() {
    display = "";
  });
}
  void appendNumber(String number) {
    setState(() {
      display += number;
    });

  }

void calculer() {
  if (display.contains("+")) {
    List<String> parties = display.split("+");

    double resultat = 0;

    for (String nombre in parties) {
      resultat += double.parse(nombre);
    }

    setState(() {
      display = resultat.toString();
    });

     if (display.contains("-")) {
    List<String> parties = display.split("-");

    double resultat = double.parse(parties[0]);

    for (int i = 1; i < parties.length; i++) {
      resultat -= double.parse(parties[i]);
    }

    setState(() {
      display = resultat.toString();
    });
  }
  }
}

  void supp() {
    setState(() {
      if (display.isNotEmpty) {
        display = display.substring(0, display.length - 1);
        }

    if (display.isEmpty) {
      display = "";
    }
  });
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
            body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              display,
              style: const TextStyle(fontSize: 40),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildButton("1", () => appendNumber("1")),
                buildButton("2", () => appendNumber("2")),
                buildButton("3", () => appendNumber("3")),
                 buildButton("del", supp),
              ],
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildButton("4", () => appendNumber("4")),
                buildButton("5", () => appendNumber("5")),
                buildButton("6", () => appendNumber("6")),
                buildButton("+", () => appendNumber("+")),
                
              ],
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildButton("7", () => appendNumber("7")),
                buildButton("8", () => appendNumber("8")),
                buildButton("9", () => appendNumber("9")),
                buildButton("-", () => appendNumber("-")),
              ],
            ),
            Row (mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildButton("0", () => appendNumber("0")),
              buildButton(",", () => appendNumber(".")),
              buildButton("AC",clearAll) ,
              buildButton("=", calculer),
              ],),
          ],
        ),
      ),
    );
  }
}
