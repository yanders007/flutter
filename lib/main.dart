import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
  }
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'convertisseur demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
      ),
      home: const MyHomePage(title: 'By Andy'), 
    );
  }}
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();}
class _MyHomePageState extends State<MyHomePage> {
  String monnaieChoisie = 'USD'; 
  List<String> listeMonnaies = ['USD', 'EUR', 'XOF', 'JPY',"coups"]; 
  final TextEditingController _controllerMontant = TextEditingController();
  String resultat = ''; 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0), 
        children: [
          const Text(
            'Ceci est un convertisseur de monnaie. De base le montant que vous entrez est en USD',
            textAlign: TextAlign.center,
          ),         
          const SizedBox(height: 20),    
          TextField( 
            
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Montant à entrer ici',
              prefixText: "\$"
            ),
            controller: _controllerMontant,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),          
          DropdownButton<String>(
            value: monnaieChoisie,
            icon: const Icon(Icons.arrow_left), 
            isExpanded: true,
            items: listeMonnaies.map<DropdownMenuItem<String>>((String monnaie) {
              return DropdownMenuItem<String>(
                value: monnaie,
                child: Text(monnaie),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                monnaieChoisie = newValue!;
              });
            },
          ),
          const SizedBox(height: 20),
          Text( 
            resultat,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ), 
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              double? montantSaisi = double.tryParse(_controllerMontant.text);
              if (montantSaisi == null) {
                setState(() {
                  resultat = "Veuillez entrer un nombre valide !";
                });
                return;
              }
              double taux = 1.0;
              if (monnaieChoisie == 'USD') {
                taux = 1.0;    
              } else if (monnaieChoisie == 'EUR') {
                taux = 0.866;   
              } else if (monnaieChoisie == 'XOF') {
                taux = 568.1939; 
              } else if (monnaieChoisie == 'JPY') {
                taux = 160.5208; 
              }else { taux = 0.2442; }
              double conversion = montantSaisi * taux;
              setState(() {
                resultat = "$montantSaisi USD = ${conversion.toStringAsFixed(5)} $monnaieChoisie";
              });
            },
            child: const Text('Convertir'),
          ),
        ],
      ),
    );
  }
}